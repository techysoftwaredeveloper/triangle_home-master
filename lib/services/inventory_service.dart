import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/room_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a room and its child beds atomically, updating property counters in flat structure
  Future<void> createRoomWithBeds({
    required String propertyId,
    required RoomModel room,
    required List<Map<String, dynamic>> bedData,
  }) async {
    final roomRef = _firestore.collection('rooms').doc();
    final statsRef = _firestore.collection('propertyStats').doc(propertyId);

    await _firestore.runTransaction((transaction) async {
      // 1. Create Room
      transaction.set(roomRef, {
        ...room.toFirestore(),
        'id': roomRef.id,
        'propertyId': propertyId,
        'totalBeds': bedData.length,
        'availableBeds': bedData.length,
        'occupiedBeds': 0,
      });

      // 2. Create Beds in top-level collection
      for (final bed in bedData) {
        final bedRef = _firestore.collection('beds').doc();
        transaction.set(bedRef, {
          ...bed,
          'id': bedRef.id,
          'propertyId': propertyId,
          'roomId': roomRef.id,
          'status': BedStatus.available.name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Update Property Stats Aggregates
      transaction.set(statsRef, {
        'availableBeds': FieldValue.increment(bedData.length),
        'availableRooms': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. Log Inventory Event
      transaction.set(_firestore.collection('inventory_events').doc(), {
        'type': InventoryEventType.bedCreated.name,
        'propertyId': propertyId,
        'roomId': roomRef.id,
        'count': bedData.length,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Locks a bed for a user with a 15-minute expiry window in flat structure
  Future<void> lockBedForUser({
    required String propertyId,
    required String roomId,
    required String bedId,
    required String userId,
  }) async {
    if (propertyId.isEmpty || roomId.isEmpty || bedId.isEmpty) {
      throw 'Invalid identifiers provided for bed locking';
    }

    final roomRef = _firestore.collection('rooms').doc(roomId);
    final bedRef = _firestore.collection('beds').doc(bedId);
    final statsRef = _firestore.collection('propertyStats').doc(propertyId);
    final reservationRef = _firestore.collection('bed_reservations').doc();

    await _firestore.runTransaction((transaction) async {
      // 1. Verify Bed Existence & Status
      final bedDoc = await transaction.get(bedRef);
      if (!bedDoc.exists) throw 'Bed document not found';

      final bedData = bedDoc.data()!;
      if (bedData['status'] != BedStatus.available.name) {
        throw 'Bed is no longer available';
      }

      // 2. Verify Room Existence
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) throw 'Room document not found';

      final expiry = DateTime.now().add(const Duration(minutes: 15));

      // 3. Update Bed Status
      transaction.update(bedRef, {
        'status': BedStatus.reserved.name,
        'reservedBy': userId,
        'reservationExpiresAt': Timestamp.fromDate(expiry),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Create Reservation Audit
      transaction.set(reservationRef, {
        'propertyId': propertyId,
        'roomId': roomId,
        'bedId': bedId,
        'userId': userId,
        'status': 'active',
        'expiresAt': Timestamp.fromDate(expiry),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Update Counters (Room)
      transaction.update(roomRef, {'availableBeds': FieldValue.increment(-1)});
      
      // 6. Update Counters (Property Stats) - Use set with merge to be resilient to missing docs
      transaction.set(statsRef, {
        'availableBeds': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 7. Log Event
      transaction.set(_firestore.collection('inventory_events').doc(), {
        'type': InventoryEventType.bedReserved.name,
        'propertyId': propertyId,
        'roomId': roomId,
        'bedId': bedId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Permanently assigns a resident to a bed in flat structure
  Future<void> assignResident({
    required String propertyId,
    required String roomId,
    required String bedId,
    required String residentId,
  }) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final bedRef = _firestore.collection('beds').doc(bedId);
    final statsRef = _firestore.collection('propertyStats').doc(propertyId);

    await _firestore.runTransaction((transaction) async {
      // 1. Update Bed
      transaction.update(bedRef, {
        'status': BedStatus.occupied.name,
        'currentResidentId': residentId,
        'reservedBy': null,
        'reservationExpiresAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Counters
      transaction.update(roomRef, {'occupiedBeds': FieldValue.increment(1)});
      transaction.update(statsRef, {
        'occupiedBeds': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Log Event
      transaction.set(_firestore.collection('inventory_events').doc(), {
        'type': InventoryEventType.bedOccupied.name,
        'propertyId': propertyId,
        'roomId': roomId,
        'bedId': bedId,
        'residentId': residentId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Get all rooms for a property ordered by floor
  Stream<List<RoomModel>> getPropertyRooms(String propertyId) {
    return _firestore
        .collection('rooms')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('floor')
        .orderBy('roomNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList());
  }

  /// Get all beds for a specific room
  Stream<List<Map<String, dynamic>>> getRoomBeds(String roomId) {
    return _firestore
        .collection('beds')
        .where('roomId', isEqualTo: roomId)
        .orderBy('bedNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Update bed status (e.g., Maintenance, Blocked)
  Future<void> updateBedStatus({
    required String propertyId,
    required String roomId,
    required String bedId,
    required BedStatus newStatus,
  }) async {
    final bedRef = _firestore.collection('beds').doc(bedId);
    await bedRef.update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log Event
    await _firestore.collection('inventory_events').add({
      'type': InventoryEventType.statusChanged.name,
      'propertyId': propertyId,
      'roomId': roomId,
      'bedId': bedId,
      'newStatus': newStatus.name,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get floors as a list of distinct numbers from rooms
  Stream<List<int>> getPropertyFloors(String propertyId) {
    return _firestore
        .collection('rooms')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) {
          final floors = snapshot.docs.map((doc) => (doc.data()['floor'] as num?)?.toInt() ?? 0).toSet().toList();
          floors.sort();
          return floors;
        });
  }

  /// Releases a bed, setting its status back to available in both flat and nested structures
  Future<void> releaseBed({
    required String propertyId,
    required String roomId,
    required String bedId,
  }) async {
    final flatBedRef = _firestore.collection('beds').doc(bedId);
    final flatRoomRef = _firestore.collection('rooms').doc(roomId);
    final statsRef = _firestore.collection('propertyStats').doc(propertyId);

    final nestedBedRef = _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .doc(roomId)
        .collection('beds')
        .doc(bedId);
    final nestedRoomRef = _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .doc(roomId);
    final nestedPropRef = _firestore.collection('properties').doc(propertyId);

    await _firestore.runTransaction((transaction) async {
      // 1. Get flat and nested beds to check current status for decrementing occupied counts
      final flatBedDoc = await transaction.get(flatBedRef);
      String? status;
      if (flatBedDoc.exists) {
        status = flatBedDoc.data()?['status'] as String?;
      } else {
        final nestedBedDoc = await transaction.get(nestedBedRef);
        if (nestedBedDoc.exists) {
          status = nestedBedDoc.data()?['status'] as String?;
        }
      }

      final isOccupied = status == BedStatus.occupied.name;

      // 2. Update Flat Bed Document
      transaction.update(flatBedRef, {
        'status': BedStatus.available.name,
        'currentResidentId': null,
        'reservedBy': null,
        'reservationExpiresAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Nested Bed Document
      transaction.update(nestedBedRef, {
        'status': BedStatus.available.name,
        'currentResidentId': null,
        'reservedBy': null,
        'reservationExpiresAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Update Counters if Bed was Occupied
      if (isOccupied) {
        transaction.update(flatRoomRef, {
          'occupiedBeds': FieldValue.increment(-1),
          'availableBeds': FieldValue.increment(1),
        });
        transaction.update(statsRef, {
          'occupiedBeds': FieldValue.increment(-1),
          'availableBeds': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(nestedRoomRef, {
          'occupiedBeds': FieldValue.increment(-1),
          'availableBeds': FieldValue.increment(1),
        });
        transaction.update(nestedPropRef, {
          'occupiedBeds': FieldValue.increment(-1),
          'availableBeds': FieldValue.increment(1),
        });
      } else {
        // Just increment availability if it wasn't occupied (e.g. was reserved/maintenance/blocked)
        if (status == BedStatus.reserved.name ||
            status == BedStatus.maintenance.name ||
            status == BedStatus.blocked.name) {
          transaction.update(flatRoomRef, {
            'availableBeds': FieldValue.increment(1),
          });
          transaction.update(statsRef, {
            'availableBeds': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          transaction.update(nestedRoomRef, {
            'availableBeds': FieldValue.increment(1),
          });
          transaction.update(nestedPropRef, {
            'availableBeds': FieldValue.increment(1),
          });
        }
      }

      // 5. Log Inventory Event
      transaction.set(_firestore.collection('inventory_events').doc(), {
        'type': InventoryEventType.bedReleased.name,
        'propertyId': propertyId,
        'roomId': roomId,
        'bedId': bedId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
