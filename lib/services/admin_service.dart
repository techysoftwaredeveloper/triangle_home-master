import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/audit_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();

  Future<Map<String, dynamic>> getStats() async {
    final properties = await _firestore.collection('properties').get();
    final bookings = await _firestore.collection('bookings').get();
    final students = await _firestore.collection('student').get();
    final hosters = await _firestore.collection('hoster').get();
    final payments = await _firestore.collection('payments').get();

    double totalRevenue = 0;
    for (var doc in payments.docs) {
      totalRevenue += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalProperties': properties.docs.length,
      'totalBookings': bookings.docs.length,
      'totalStudents': students.docs.length,
      'totalHosters': hosters.docs.length,
      'totalRevenue': totalRevenue,
      'pendingProperties': properties.docs
          .where((doc) => doc.data()['status'] == PropertyStatus.pending.name)
          .length,
      'pendingHosters': hosters.docs
          .where((doc) => doc.data()['status'] == HosterStatus.pending.name)
          .length,
    };
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    final students = await _firestore.collection('student').get();
    final hosters = await _firestore.collection('hoster').get();

    return {
      'students': students.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      'hosters': hosters.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
    };
  }

  Future<List<Map<String, dynamic>>> getAllProperties() async {
    final snapshot = await _firestore.collection('properties').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getAllBookings() async {
    final snapshot = await _firestore.collection('bookings').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> updatePropertyStatus(String propertyId, PropertyStatus status, {String? reason}) async {
    await _firestore.collection('properties').doc(propertyId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'property_status_update',
      targetId: propertyId,
      targetType: 'property',
      reason: reason ?? 'Updated to ${status.name}',
      extraData: {'newStatus': status.name},
    );
  }

  Future<void> approveHoster(String hosterId, {String? reason}) async {
    await _firestore.collection('hoster').doc(hosterId).update({
      'status': HosterStatus.approved.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'hoster_approval',
      targetId: hosterId,
      targetType: 'hoster',
      reason: reason ?? 'Approved by admin',
    );
  }

  Future<void> toggleUserStatus(String userId, String collection, String status, {String? reason}) async {
    await _firestore.collection(collection).doc(userId).update({
      'accountStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'user_status_toggle',
      targetId: userId,
      targetType: collection,
      reason: reason ?? 'Changed account status to $status',
      extraData: {'newAccountStatus': status},
    );
  }

  // ==================== RECONCILIATION & INTEGRITY ====================

  /// Verifies that the property's occupancy count matches the actual number of confirmed bookings
  Future<Map<String, int>> runOccupancyReconciliation(String propertyId) async {
    try {
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
      if (!propertyDoc.exists) throw Exception('Property not found');

      final reportedOccupancy = propertyDoc.data()?['currentOccupancy'] as int? ?? 0;

      // Count actual confirmed/checked-in bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('propertyId', isEqualTo: propertyId)
          .where('status', whereIn: [BookingStatus.confirmed.name, BookingStatus.checkedIn.name])
          .get();

      final actualOccupancy = bookingsSnapshot.docs.length;

      if (reportedOccupancy != actualOccupancy) {
        // Auto-repair
        await _firestore.collection('properties').doc(propertyId).update({
          'currentOccupancy': actualOccupancy,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _auditService.logAction(
          action: 'occupancy_reconciliation_repair',
          targetId: propertyId,
          targetType: 'property',
          reason: 'Mismatch detected: Reported $reportedOccupancy, Actual $actualOccupancy',
          extraData: {'oldValue': reportedOccupancy, 'newValue': actualOccupancy},
        );
      }

      return {'reported': reportedOccupancy, 'actual': actualOccupancy};
    } catch (e) {
      rethrow;
    }
  }
}
