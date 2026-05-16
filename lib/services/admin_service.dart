import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/audit_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();

  // ==================== REAL-TIME STREAMS ====================

  Stream<Map<String, dynamic>> getStatsStream() {
    // We listen to multiple collections and merge them for a real-time dashboard
    return _firestore.collection('users').snapshots().asyncMap((usersSnapshot) async {
      try {
        final propertiesSnapshot = await _firestore.collection('properties').get();
        final bookingsSnapshot = await _firestore.collection('bookings').get();
        final paymentsSnapshot = await _firestore.collection('payments').get();

        double totalRevenue = 0;
        for (var doc in paymentsSnapshot.docs) {
          totalRevenue += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        }

        final students = usersSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['role'] == 'student' || data['role'] == 'user';
        }).length;

        final hosters = usersSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['role'] == 'hoster';
        }).length;

        return {
          'totalProperties': propertiesSnapshot.docs.length,
          'totalBookings': bookingsSnapshot.docs.length,
          'totalUsers': usersSnapshot.docs.length,
          'totalStudents': students,
          'totalHosters': hosters,
          'totalRevenue': totalRevenue,
          'pendingProperties': propertiesSnapshot.docs
              .where((doc) => doc.data()['status'] == 'pending')
              .length,
          'pendingHosters': usersSnapshot.docs
              .where((doc) => doc.data()['role'] == 'hoster' && doc.data()['status'] == 'pending')
              .length,
        };
      } catch (e) {
        print('Error in getStatsStream: $e');
        return {
          'error': e.toString(),
          'totalProperties': 0,
          'totalBookings': 0,
          'totalUsers': 0,
          'totalStudents': 0,
          'totalHosters': 0,
          'totalRevenue': 0,
          'pendingProperties': 0,
          'pendingHosters': 0,
        };
      }
    });
  }

  Stream<Map<String, List<Map<String, dynamic>>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      return {
        'students': users.where((u) => u['role'] == 'student' || u['role'] == 'user').toList(),
        'hosters': users.where((u) => u['role'] == 'hoster').toList(),
      };
    });
  }

  Stream<List<Map<String, dynamic>>> getPropertiesStream() {
    return _firestore.collection('properties').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getBookingsStream() {
    return _firestore.collection('bookings').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  // ==================== MODERATION ACTIONS ====================

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

  Future<void> approveHoster(String hosterId) async {
    await _firestore.collection('users').doc(hosterId).update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'hoster_approval',
      targetId: hosterId,
      targetType: 'hoster',
      reason: 'Approved by superadmin',
    );
  }

  Future<void> toggleUserStatus(String userId, String status) async {
    await _firestore.collection('users').doc(userId).update({
      'accountStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'user_status_toggle',
      targetId: userId,
      targetType: 'users',
      reason: 'Account status changed to $status',
      extraData: {'newAccountStatus': status},
    );
  }

  // ==================== SUPERADMIN OPS ====================

  Future<void> deleteListing(String propertyId) async {
    await _firestore.collection('properties').doc(propertyId).delete();
  }

  Future<void> promoteToAdmin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'role': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
