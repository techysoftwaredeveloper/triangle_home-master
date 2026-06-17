import 'package:cloud_firestore/cloud_firestore.dart';

class InventorySummary {
  final int totalBeds;
  final int availableBeds;
  final int occupiedBeds;
  final int maintenanceBeds;
  final int blockedBeds;
  final int bookedBeds;

  InventorySummary({
    required this.totalBeds,
    required this.availableBeds,
    required this.occupiedBeds,
    required this.maintenanceBeds,
    required this.blockedBeds,
    required this.bookedBeds,
  });

  double get occupancyRate =>
      totalBeds == 0 ? 0 : (occupiedBeds / totalBeds * 100);
}

class PropertyStructureService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== FLOORS ====================

  /// Returns true if another floor with [floorNumber] already exists on this property.
  /// Pass [excludeFloorId] when editing to exclude the floor being updated.
  Future<bool> isDuplicateFloorNumber(
    String propertyId,
    int floorNumber, {
    String? excludeFloorId,
  }) async {
    final query = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('floors')
        .where('floorNumber', isEqualTo: floorNumber)
        .limit(5)
        .get();

    for (final doc in query.docs) {
      if (excludeFloorId == null || doc.id != excludeFloorId) {
        return true; // Found a duplicate
      }
    }
    return false;
  }

  /// Returns true if another room with [roomNumber] already exists on this property.
  Future<bool> isDuplicateRoomNumber(
    String propertyId,
    String roomNumber, {
    String? excludeRoomId,
  }) async {
    final query = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .where('roomNumber', isEqualTo: roomNumber.trim())
        .limit(5)
        .get();

    for (final doc in query.docs) {
      if (excludeRoomId == null || doc.id != excludeRoomId) {
        return true; // Found a duplicate
      }
    }
    return false;
  }

  Future<void> createFloor(String propertyId, Map<String, dynamic> data) async {
    final floorId =
        data['id'] ??
        _db
            .collection('properties')
            .doc(propertyId)
            .collection('floors')
            .doc()
            .id;
    await _db
        .collection('properties')
        .doc(propertyId)
        .collection('floors')
        .doc(floorId)
        .set({
          ...data,
          'id': floorId,
          'propertyId': propertyId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Suggests the next room number based on strategy and existing rooms.
  Future<String> getNextRoomNumber(String propertyId, int floor, String numberingSystem) async {
    final roomsSnap = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .where('floor', isEqualTo: floor)
        .get();
    
    if (numberingSystem == 'Numeric (101)') {
      // Suggest (Floor + 1) * 100 + Count + 1
      final int base = (floor + 1) * 100;
      int maxNum = base;
      for (var doc in roomsSnap.docs) {
        final rNum = int.tryParse(doc.data()['roomNumber']?.toString() ?? '');
        if (rNum != null && rNum > maxNum) maxNum = rNum;
      }
      return '${maxNum + 1}';
    } else if (numberingSystem == 'Floor Based') {
      // Expects F{Floor}-R{N}
      int maxR = 0;
      final regex = RegExp(r'R(\d+)');
      for (var doc in roomsSnap.docs) {
        final rStr = doc.data()['roomNumber']?.toString() ?? '';
        final match = regex.firstMatch(rStr);
        if (match != null) {
          final n = int.tryParse(match.group(1)!);
          if (n != null && n > maxR) maxR = n;
        }
      }
      return 'F${floor + 1}-R${maxR + 1}';
    } else if (numberingSystem == 'Alpha-Numeric') {
      // Expects A{N}
      int maxA = 0;
      final regex = RegExp(r'A(\d+)');
      for (var doc in roomsSnap.docs) {
        final rStr = doc.data()['roomNumber']?.toString() ?? '';
        final match = regex.firstMatch(rStr);
        if (match != null) {
          final n = int.tryParse(match.group(1)!);
          if (n != null && n > maxA) maxA = n;
        }
      }
      return 'A${maxA + 1}';
    }
    
    return '';
  }

  Future<void> addBedsToRoom({
    required String propertyId,
    required String roomId,
    required String floorId,
    required int floor,
    required int count,
    required String roomNumber,
    required double rent,
    required String numberingSystem,
  }) async {
    final roomRef = _db.collection('properties').doc(propertyId).collection('rooms').doc(roomId);
    final flatRoomRef = _db.collection('rooms').doc(roomId);
    final statsRef = _db.collection('propertyStats').doc(propertyId);

    await _db.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) throw 'Room not found';
      
      // Find max existing bed index in this room
      final bedsSnap = await roomRef.collection('beds').get();
      int maxBedIndex = 0;
      final regex = RegExp(r'B(\d+)');
      
      for (var doc in bedsSnap.docs) {
        final bNum = doc.data()['bedNumber']?.toString() ?? '';
        final match = regex.firstMatch(bNum);
        if (match != null) {
          final n = int.tryParse(match.group(1)!);
          if (n != null && n > maxBedIndex) maxBedIndex = n;
        }
      }

      for (int i = 1; i <= count; i++) {
        final nextIndex = maxBedIndex + i;
        final bedId = _db.collection('beds').doc().id;
        final bedRef = _db.collection('properties').doc(propertyId).collection('beds').doc(bedId);
        final nestedBedRef = roomRef.collection('beds').doc(bedId);
        final flatBedRef = _db.collection('beds').doc(bedId);

        final bedLabel = (numberingSystem == 'Alpha-Numeric' || numberingSystem == 'Custom')
            ? 'B$nextIndex'
            : '$roomNumber-B$nextIndex';

        final bedPayload = {
          'id': bedId,
          'bedId': bedId,
          'bedNumber': bedLabel,
          'roomId': roomId,
          'floorId': floorId,
          'propertyId': propertyId,
          'status': 'available',
          'currentResidentId': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'monthlyRent': rent,
        };

        transaction.set(bedRef, bedPayload);
        transaction.set(nestedBedRef, bedPayload);
        transaction.set(flatBedRef, bedPayload);
      }

      final updates = {
        'totalBeds': FieldValue.increment(count),
        'availableBeds': FieldValue.increment(count),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      transaction.update(roomRef, updates);
      transaction.update(flatRoomRef, updates);
      transaction.update(statsRef, {
        'totalBeds': FieldValue.increment(count),
        'availableBeds': FieldValue.increment(count),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateFloor(
    String propertyId,
    String floorId,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('properties')
        .doc(propertyId)
        .collection('floors')
        .doc(floorId)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<bool> canDeleteFloor(String propertyId, String floorId) async {
    final occupiedBeds = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('beds')
        .where('floorId', isEqualTo: floorId)
        .where('status', isEqualTo: 'occupied')
        .limit(1)
        .get();
    return occupiedBeds.docs.isEmpty;
  }

  Future<void> deleteFloor(String propertyId, String floorId) async {
    final batch = _db.batch();

    final roomsSnap = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .where('floorId', isEqualTo: floorId)
        .get();

    for (final roomDoc in roomsSnap.docs) {
      final roomId = roomDoc.id;
      final bedsSnap = await _db
          .collection('properties')
          .doc(propertyId)
          .collection('beds')
          .where('roomId', isEqualTo: roomId)
          .get();

      for (final bedDoc in bedsSnap.docs) {
        final bedId = bedDoc.id;
        batch.delete(
          _db
              .collection('properties')
              .doc(propertyId)
              .collection('beds')
              .doc(bedId),
        );
        batch.delete(
          _db
              .collection('properties')
              .doc(propertyId)
              .collection('rooms')
              .doc(roomId)
              .collection('beds')
              .doc(bedId),
        );
        batch.delete(_db.collection('beds').doc(bedId));
      }

      batch.delete(
        _db
            .collection('properties')
            .doc(propertyId)
            .collection('rooms')
            .doc(roomId),
      );
      batch.delete(_db.collection('rooms').doc(roomId));
    }

    batch.delete(
      _db
          .collection('properties')
          .doc(propertyId)
          .collection('floors')
          .doc(floorId),
    );

    await batch.commit();
  }

  /// Suggests the next floor number.
  Future<int> getNextFloorNumber(String propertyId) async {
    final floorsSnap = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('floors')
        .orderBy('floorNumber', descending: true)
        .limit(1)
        .get();
    
    if (floorsSnap.docs.isEmpty) return 0;
    return (floorsSnap.docs.first.data()['floorNumber'] as int? ?? 0) + 1;
  }

  // ==================== ROOMS & BEDS ====================

  Future<void> createRoomWithBeds({
    required String propertyId,
    required String floorId,
    required Map<String, dynamic> roomData,
    required int bedCount,
    required String numberingSystem,
  }) async {
    final roomId =
        roomData['id'] ??
        _db
            .collection('properties')
            .doc(propertyId)
            .collection('rooms')
            .doc()
            .id;

    final roomRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .doc(roomId);
    final flatRoomRef = _db.collection('rooms').doc(roomId);
    final statsRef = _db.collection('propertyStats').doc(propertyId);
    final floorRef = _db.collection('properties').doc(propertyId).collection('floors').doc(floorId);

    final roomPayload = {
      ...roomData,
      'id': roomId,
      'propertyId': propertyId,
      'floorId': floorId,
      'totalBeds': bedCount,
      'availableBeds': bedCount,
      'occupiedBeds': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db.runTransaction((transaction) async {
      // 1. Ensure Floor document exists (handles cases where floor is created on-the-fly)
      final floorDoc = await transaction.get(floorRef);
      if (!floorDoc.exists) {
        final floorNum = roomData['floor'] as int? ?? 0;
        transaction.set(floorRef, {
          'id': floorId,
          'propertyId': propertyId,
          'name': floorNum == 0 ? 'Ground Floor' : 'Floor $floorNum',
          'floorNumber': floorNum,
          'status': 'Active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Set Room in both nested and flat locations
      transaction.set(roomRef, roomPayload, SetOptions(merge: true));
      transaction.set(flatRoomRef, roomPayload, SetOptions(merge: true));

      // 3. Generate and set Beds
      final roomNumber = roomData['roomNumber'] ?? 'Room';
      for (int i = 1; i <= bedCount; i++) {
        final bedId = _db.collection('beds').doc().id;
        final bedRef = _db.collection('properties').doc(propertyId).collection('beds').doc(bedId);
        final nestedBedRef = roomRef.collection('beds').doc(bedId);
        final flatBedRef = _db.collection('beds').doc(bedId);

        final bedLabel = (numberingSystem == 'Alpha-Numeric' || numberingSystem == 'Custom')
            ? 'B$i'
            : '$roomNumber-B$i';

        final bedPayload = {
          'id': bedId,
          'bedId': bedId,
          'bedNumber': bedLabel,
          'roomId': roomId,
          'floorId': floorId,
          'propertyId': propertyId,
          'status': 'available',
          'currentResidentId': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        transaction.set(bedRef, bedPayload, SetOptions(merge: true));
        transaction.set(nestedBedRef, bedPayload, SetOptions(merge: true));
        transaction.set(flatBedRef, bedPayload, SetOptions(merge: true));
      }

      // 4. Atomic Stat Update
      transaction.set(statsRef, {
        'totalBeds': FieldValue.increment(bedCount),
        'availableBeds': FieldValue.increment(bedCount),
        'availableRooms': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Updates room details (type, amenities, area, status) and syncs to both
  /// the subcollection and the flat /rooms collection.
  Future<void> updateRoomDetails(
    String propertyId,
    String roomId,
    Map<String, dynamic> roomData,
  ) async {
    final roomRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .doc(roomId);
    final flatRoomRef = _db.collection('rooms').doc(roomId);

    final updates = {
      ...roomData,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Batch both writes atomically
    final batch = _db.batch();
    batch.update(roomRef, updates);
    batch.update(flatRoomRef, updates);
    await batch.commit();
  }

  Future<void> updateRoom(
    String propertyId,
    String roomId,
    Map<String, dynamic> roomData,
  ) async {
    await updateRoomDetails(propertyId, roomId, roomData);
  }

  Future<bool> canDeleteRoom(String propertyId, String roomId) async {
    final occupiedBeds = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('beds')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'occupied')
        .limit(1)
        .get();
    return occupiedBeds.docs.isEmpty;
  }

  Future<void> deleteRoom(String propertyId, String roomId) async {
    final batch = _db.batch();

    final bedsSnap = await _db
        .collection('properties')
        .doc(propertyId)
        .collection('beds')
        .where('roomId', isEqualTo: roomId)
        .get();

    for (final doc in bedsSnap.docs) {
      final bedId = doc.id;
      batch.delete(
        _db
            .collection('properties')
            .doc(propertyId)
            .collection('beds')
            .doc(bedId),
      );
      batch.delete(
        _db
            .collection('properties')
            .doc(propertyId)
            .collection('rooms')
            .doc(roomId)
            .collection('beds')
            .doc(bedId),
      );
      batch.delete(_db.collection('beds').doc(bedId));
    }

    batch.delete(
      _db
          .collection('properties')
          .doc(propertyId)
          .collection('rooms')
          .doc(roomId),
    );
    batch.delete(_db.collection('rooms').doc(roomId));

    await batch.commit();
  }

  Future<void> updateBedStatus({
    required String propertyId,
    required String roomId,
    required String bedId,
    required String newStatus,
  }) async {
    final batch = _db.batch();

    final bedRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('beds')
        .doc(bedId);
    final nestedBedRef = _db
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .doc(roomId)
        .collection('beds')
        .doc(bedId);
    final flatBedRef = _db.collection('beds').doc(bedId);

    final updates = {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.update(bedRef, updates);
    batch.update(nestedBedRef, updates);
    batch.update(flatBedRef, updates);

    await batch.commit();
  }

  // ==================== ANALYTICS ====================

  /// Returns a live stream of [InventorySummary] for the given property.
  Stream<InventorySummary> getInventorySummary(String propertyId) {
    return _db
        .collection('properties')
        .doc(propertyId)
        .collection('beds')
        .snapshots()
        .map((snapshot) {
      int total = 0;
      int available = 0;
      int occupied = 0;
      int maintenance = 0;
      int blocked = 0;
      int booked = 0;

      for (final doc in snapshot.docs) {
        final status = (doc.data()['status'] ?? 'available').toString().toLowerCase();
        total++;
        if (status == 'available') { available++; }
        else if (status == 'occupied') { occupied++; }
        else if (status == 'maintenance') { maintenance++; }
        else if (status == 'blocked') { blocked++; }
        else if (status == 'reserved' || status == 'booked') { booked++; }
      }

      return InventorySummary(
        totalBeds: total,
        availableBeds: available,
        occupiedBeds: occupied,
        maintenanceBeds: maintenance,
        blockedBeds: blocked,
        bookedBeds: booked,
      );
    });
  }

  /// Returns live occupancy data per-floor as a map: { floorId -> InventorySummary }
  Stream<Map<String, InventorySummary>> getFloorOccupancy(String propertyId) {
    return _db
        .collection('properties')
        .doc(propertyId)
        .collection('beds')
        .snapshots()
        .map((snapshot) {
      final Map<String, Map<String, int>> floorData = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final floorId = data['floorId']?.toString() ?? 'unknown';
        final status = (data['status'] ?? 'available').toString().toLowerCase();

        floorData.putIfAbsent(
          floorId,
          () => {
            'total': 0,
            'available': 0,
            'occupied': 0,
            'maintenance': 0,
            'blocked': 0,
            'booked': 0,
          },
        );

        floorData[floorId]!['total'] = (floorData[floorId]!['total'] ?? 0) + 1;
        if (status == 'available') {
          floorData[floorId]!['available'] = (floorData[floorId]!['available'] ?? 0) + 1;
        } else if (status == 'occupied') {
          floorData[floorId]!['occupied'] = (floorData[floorId]!['occupied'] ?? 0) + 1;
        } else if (status == 'maintenance') {
          floorData[floorId]!['maintenance'] = (floorData[floorId]!['maintenance'] ?? 0) + 1;
        } else if (status == 'blocked') {
          floorData[floorId]!['blocked'] = (floorData[floorId]!['blocked'] ?? 0) + 1;
        } else if (status == 'reserved' || status == 'booked') {
          floorData[floorId]!['booked'] = (floorData[floorId]!['booked'] ?? 0) + 1;
        }
      }

      return floorData.map(
        (floorId, counts) => MapEntry(
          floorId,
          InventorySummary(
            totalBeds: counts['total'] ?? 0,
            availableBeds: counts['available'] ?? 0,
            occupiedBeds: counts['occupied'] ?? 0,
            maintenanceBeds: counts['maintenance'] ?? 0,
            blockedBeds: counts['blocked'] ?? 0,
            bookedBeds: counts['booked'] ?? 0,
          ),
        ),
      );
    });
  }
}
