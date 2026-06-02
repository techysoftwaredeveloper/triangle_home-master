import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/room_model.dart';
import 'package:triangle_home/models/bed_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a room and its child beds atomically, updating property counters
  Future<void> createRoomWithBeds({
    required String propertyId,
    required RoomModel room,
    required List<String> bedNumbers,
  }) async {
    final propertyRef = _firestore.collection('properties').doc(propertyId);
    final roomRef = propertyRef.collection('rooms').doc();
    
    await _firestore.runTransaction((transaction) async {
      // 1. Create Room
      transaction.set(roomRef, {
        ...room.toFirestore(),
        'totalBeds': bedNumbers.length,
        'availableBeds': bedNumbers.length,
        'occupiedBeds': 0,
      });

      // 2. Create Beds
      for (final bedNum in bedNumbers) {
        final bedRef = roomRef.collection('beds').doc();
        transaction.set(bedRef, {
          'propertyId': propertyId,
          'roomId': roomRef.id,
          'bedNumber': bedNum,
          'status': BedStatus.available.name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Update Property Counters
      transaction.update(propertyRef, {
        'totalBeds': FieldValue.increment(bedNumbers.length),
        'availableBeds': FieldValue.increment(bedNumbers.length),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Log Inventory Event
      transaction.set(_firestore.collection('inventory_events').doc(), {
        'type': InventoryEventType.bedCreated.name,
        'propertyId': propertyId,
        'roomId': roomRef.id,
        'count': bedNumbers.length,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Locks a bed for a user with a 15-minute expiry window
  Future<void> lockBedForUser({
    required String propertyId,
    required String roomId,
    required String bedId,
    required String userId,
  }) async {
    final propertyRef = _firestore.collection('properties').doc(propertyId);
    final roomRef = propertyRef.collection('rooms').doc(roomId);
    final bedRef = roomRef.collection('beds').doc(bedId);
    final reservationRef = _firestore.collection('bed_reservations').doc();

    await _firestore.runTransaction((transaction) async {
      final bedDoc = await transaction.get(bedRef);
      if (!bedDoc.exists) throw 'Bed not found';

      final bedData = bedDoc.data()!;
      if (bedData['status'] != BedStatus.available.name) {
        throw 'Bed is no longer available';
      }

      final expiry = DateTime.now().add(const Duration(minutes: 15));

      // 1. Update Bed Status
      transaction.update(bedRef, {
        'status': BedStatus.reserved.name,
        'reservedBy': userId,
        'reservationExpiresAt': Timestamp.fromDate(expiry),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Create Reservation Audit
      transaction.set(reservationRef, {
        'propertyId': propertyId,
        'roomId': roomId,
        'bedId': bedId,
        'userId': userId,
        'status': 'active',
        'expiresAt': Timestamp.fromDate(expiry),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Counters
      transaction.update(roomRef, {
        'availableBeds': FieldValue.increment(-1),
      });
      transaction.update(propertyRef, {
        'availableBeds': FieldValue.increment(-1),
      });

      // 4. Log Event
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

  /// Permanently assigns a resident to a bed upon successful check-in
  Future<void> assignResident({
    required String propertyId,
    required String roomId,
    required String bedId,
    required String residentId,
  }) async {
    final propertyRef = _firestore.collection('properties').doc(propertyId);
    final roomRef = propertyRef.collection('rooms').doc(roomId);
    final bedRef = roomRef.collection('beds').doc(bedId);

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
      transaction.update(roomRef, {
        'occupiedBeds': FieldValue.increment(1),
      });
      transaction.update(propertyRef, {
        'occupiedBeds': FieldValue.increment(1),
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

  /// Releases a bed back to 'available' status
  Future<void> releaseBed({
    required String propertyId,
    required String roomId,
    required String bedId,
  }) async {
    final propertyRef = _firestore.collection('properties').doc(propertyId);
    final roomRef = propertyRef.collection('rooms').doc(roomId);
    final bedRef = roomRef.collection('beds').doc(bedId);

    await _firestore.runTransaction((transaction) async {
      final bedDoc = await transaction.get(bedRef);
      final currentStatus = bedDoc.data()?['status'];

      // 1. Update Bed
      transaction.update(bedRef, {
        'status': BedStatus.available.name,
        'currentResidentId': null,
        'reservedBy': null,
        'reservationExpiresAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Adjust Counters based on what we are releasing
      if (currentStatus == BedStatus.occupied.name) {
        transaction.update(roomRef, {
          'occupiedBeds': FieldValue.increment(-1),
          'availableBeds': FieldValue.increment(1),
        });
        transaction.update(propertyRef, {
          'occupiedBeds': FieldValue.increment(-1),
          'availableBeds': FieldValue.increment(1),
        });
      } else if (currentStatus == BedStatus.reserved.name || currentStatus == BedStatus.booked.name) {
        transaction.update(roomRef, {
          'availableBeds': FieldValue.increment(1),
        });
        transaction.update(propertyRef, {
          'availableBeds': FieldValue.increment(1),
        });
      }

      // 3. Log Event
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
