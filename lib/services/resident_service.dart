import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class ResidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Derive active residents from bookings and assigned beds
  Stream<QuerySnapshot<Map<String, dynamic>>> getPropertyResidents(String propertyId) {
    return _firestore
        .collection('bookings')
        .where('property_id', isEqualTo: propertyId)
        .where('status', whereIn: ['confirmed', 'active', 'checkedin'])
        .snapshots();
  }

  /// Get summary metrics for residents tab
  Stream<Map<String, int>> getResidentSummary(String propertyId) {
    return getPropertyResidents(propertyId).map((snapshot) {
      final docs = snapshot.docs;
      final now = DateTime.now();
      
      int active = docs.where((d) => d.data()['status'] == 'active' || d.data()['status'] == 'checkedin').length;
      
      int upcomingCheckins = docs.where((d) {
        final checkIn = (d.data()['checkinDate'] as Timestamp?)?.toDate();
        return d.data()['status'] == 'confirmed' && checkIn != null && checkIn.isAfter(now);
      }).length;

      int upcomingCheckouts = docs.where((d) {
        final checkOut = (d.data()['expectedCheckout'] as Timestamp?)?.toDate();
        return checkOut != null && checkOut.isAfter(now) && checkOut.difference(now).inDays < 7;
      }).length;

      return {
        'active': active,
        'upcomingCheckins': upcomingCheckins,
        'upcomingCheckouts': upcomingCheckouts,
        'pendingKyc': docs.where((d) => (d.data()['kycStatus'] ?? 'pending').toString().toLowerCase() != 'approved').length,
        'duePayments': docs.where((d) => (d.data()['paymentStatus'] ?? 'paid').toString().toLowerCase() == 'overdue').length,
      };
    });
  }

  /// Transfer resident to a new bed
  Future<void> transferResident({
    required String bookingId,
    required String oldBedId,
    required String newBedId,
    required String propertyId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // 1. Update Booking
      transaction.update(_firestore.collection('bookings').doc(bookingId), {
        'bed_id': newBedId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Mark old bed as vacant
      transaction.update(_firestore.collection('beds').doc(oldBedId), {
        'status': BedStatus.available.name,
        'currentResidentId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Mark new bed as occupied
      transaction.update(_firestore.collection('beds').doc(newBedId), {
        'status': BedStatus.occupied.name,
        'currentResidentId': bookingId, // Linking to booking as resident proxy
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Log audit
      transaction.set(_firestore.collection('audit_logs').doc(), {
        'action': 'bed_transfer',
        'bookingId': bookingId,
        'oldBedId': oldBedId,
        'newBedId': newBedId,
        'propertyId': propertyId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Check out a resident
  Future<void> checkoutResident({
    required String bookingId,
    required String bedId,
    required String propertyId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // 1. Update Booking
      transaction.update(_firestore.collection('bookings').doc(bookingId), {
        'status': 'checkedOut',
        'checkOutDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Free up the bed
      transaction.update(_firestore.collection('beds').doc(bedId), {
        'status': BedStatus.available.name,
        'currentResidentId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Log audit
      transaction.set(_firestore.collection('audit_logs').doc(), {
        'action': 'checkout',
        'bookingId': bookingId,
        'bedId': bedId,
        'propertyId': propertyId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
