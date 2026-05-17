import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/audit_service.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();
  final IsarService _isarService = IsarService();

  // ==================== REAL-TIME STREAMS WITH CACHE ====================

  Stream<List<Map<String, dynamic>>> getPendingApprovalsStream() async* {
    // 1. Emit cached approvals immediately
    final cached = await _isarService.getAdminCache('admin_pending_approvals');
    if (cached != null) {
      final List<dynamic> list = json.decode(cached);
      yield list.cast<Map<String, dynamic>>();
    }

    // 2. Fetch from Firestore (Users & Properties)
    final hostersStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'hoster')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    // We merge these streams
    yield* hostersStream.asyncMap((hosterSnap) async {
      final propertiesSnap = await _firestore
          .collection('properties')
          .where('status', isEqualTo: 'pending')
          .get();

      final List<Map<String, dynamic>> approvals = [];

      // Add Hosters
      for (var doc in hosterSnap.docs) {
        approvals.add({
          'id': doc.id,
          'type': 'hoster',
          ...doc.data(),
        });
      }

      // Add Properties
      for (var doc in propertiesSnap.docs) {
        approvals.add({
          'id': doc.id,
          'type': 'property',
          ...doc.data(),
        });
      }

      // Sort by createdAt if available
      approvals.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      // Save to cache
      final serializable = approvals.map((a) {
        final map = Map<String, dynamic>.from(a);
        map.forEach((k, v) {
          if (v is Timestamp) map[k] = v.toDate().toIso8601String();
        });
        return map;
      }).toList();

      await _isarService.saveAdminCache('admin_pending_approvals', json.encode(serializable));

      return approvals;
    });
  }

  Stream<Map<String, dynamic>> getStatsStream() async* {
    // 1. Emit cached data immediately if available
    final cachedData = await _isarService.getAdminCache('dashboard_stats');
    if (cachedData != null) {
      yield json.decode(cachedData);
    }

    // 2. Listen to Firestore and update cache on every change
    yield* _firestore.collection('users').snapshots().asyncMap((usersSnapshot) async {
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

        final stats = {
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
              .where((doc) => doc.data()['role'] == 'hoster' && (doc.data()['status'] == 'pending' || doc.data()['accountStatus'] == 'pending'))
              .length,
        };

        // Save to Local Cache
        await _isarService.saveAdminCache('dashboard_stats', json.encode(stats));

        return stats;
      } catch (e) {
        debugPrint('Error in getStatsStream: $e');
        return {
          'totalProperties': 0, 'totalBookings': 0, 'totalUsers': 0,
          'totalStudents': 0, 'totalHosters': 0, 'totalRevenue': 0,
          'pendingProperties': 0, 'pendingHosters': 0,
        };
      }
    });
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() async* {
    // 1. Emit cached users immediately
    final cachedUsers = await _isarService.getAdminCache('admin_users_list');
    if (cachedUsers != null) {
      final List<dynamic> list = json.decode(cachedUsers);
      yield list.cast<Map<String, dynamic>>();
    }

    // 2. Sync with Firestore
    yield* _firestore.collection('users').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final users = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Save to Local Cache (We filter out any objects that can't be JSON serialized like Timestamps)
      final serializableUsers = users.map((u) {
        final map = Map<String, dynamic>.from(u);
        map.forEach((key, value) {
          if (value is Timestamp) map[key] = value.toDate().toIso8601String();
        });
        return map;
      }).toList();

      await _isarService.saveAdminCache('admin_users_list', json.encode(serializableUsers));
      return users;
    });
  }

  Stream<List<Map<String, dynamic>>> getPropertiesStream() async* {
    final cached = await _isarService.getAdminCache('admin_properties_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('properties').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final properties = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      final serializable = properties.map((p) {
        final map = Map<String, dynamic>.from(p);
        map.forEach((k, v) { if (v is Timestamp) map[k] = v.toDate().toIso8601String(); });
        return map;
      }).toList();

      await _isarService.saveAdminCache('admin_properties_list', json.encode(serializable));
      return properties;
    });
  }

  Stream<List<Map<String, dynamic>>> getBookingsStream() async* {
    final cached = await _isarService.getAdminCache('admin_bookings_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('bookings').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final bookings = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      final serializable = bookings.map((b) {
        final map = Map<String, dynamic>.from(b);
        map.forEach((k, v) { if (v is Timestamp) map[k] = v.toDate().toIso8601String(); });
        return map;
      }).toList();

      await _isarService.saveAdminCache('admin_bookings_list', json.encode(serializable));
      return bookings;
    });
  }

  Stream<List<Map<String, dynamic>>> getPaymentsStream() async* {
    final cached = await _isarService.getAdminCache('admin_payments_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('payments').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final payments = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      final serializable = payments.map((p) {
        final map = Map<String, dynamic>.from(p);
        map.forEach((k, v) { if (v is Timestamp) map[k] = v.toDate().toIso8601String(); });
        return map;
      }).toList();

      await _isarService.saveAdminCache('admin_payments_list', json.encode(serializable));
      return payments;
    });
  }

  Stream<List<Map<String, dynamic>>> getSuggestionsStream() async* {
    final cached = await _isarService.getAdminCache('admin_suggestions_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('suggestions').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final suggestions = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      final serializable = suggestions.map((s) {
        final map = Map<String, dynamic>.from(s);
        map.forEach((k, v) { if (v is Timestamp) map[k] = v.toDate().toIso8601String(); });
        return map;
      }).toList();

      await _isarService.saveAdminCache('admin_suggestions_list', json.encode(serializable));
      return suggestions;
    });
  }

  Stream<List<Map<String, dynamic>>> getReportsStream() async* {
    final cached = await _isarService.getAdminCache('admin_reports_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('reports').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final reports = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      final serializable = reports.map((r) {
        final map = Map<String, dynamic>.from(r);
        map.forEach((k, v) { if (v is Timestamp) map[k] = v.toDate().toIso8601String(); });
        return map;
      }).toList();

      await _isarService.saveAdminCache('admin_reports_list', json.encode(serializable));
      return reports;
    });
  }

  Stream<List<Map<String, dynamic>>> getAuditLogsStream() async* {
    final cached = await _isarService.getAdminCache('admin_audit_logs');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('audit_logs').orderBy('timestamp', descending: true).snapshots().asyncMap((snapshot) async {
      final logs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      final serializable = logs.map((l) {
        final map = Map<String, dynamic>.from(l);
        map.forEach((k, v) { if (v is Timestamp) map[k] = v.toDate().toIso8601String(); });
        return map;
      }).toList();

      await _isarService.saveAdminCache('admin_audit_logs', json.encode(serializable));
      return logs;
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
      reason: reason ?? 'Updated to \${status.name}',
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
      reason: 'Account status changed to \$status',
      extraData: {'newAccountStatus': status},
    );
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection('users').doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'user_role_update',
      targetId: userId,
      targetType: 'users',
      reason: 'Role updated to \$role',
      extraData: {'newRole': role},
    );
  }

  Future<void> rejectItem(String id, String type, {String? reason}) async {
    final collection = type == 'hoster' ? 'users' : 'properties';
    await _firestore.collection(collection).doc(id).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'item_rejection',
      targetId: id,
      targetType: type,
      reason: reason ?? 'Rejected by superadmin',
    );
  }

  Future<void> approveItem(String id, String type) async {
    if (type == 'hoster') {
      await approveHoster(id);
    } else {
      await updatePropertyStatus(id, PropertyStatus.active);
    }
  }

  Future<void> updateSuggestionStatus(String id, String status) async {
    await _firestore.collection('suggestions').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'suggestion_status_update',
      targetId: id,
      targetType: 'suggestions',
      reason: 'Status changed to $status',
      extraData: {'newStatus': status},
    );
  }

  Future<void> updateReportStatus(String id, String status, {String? resolution}) async {
    await _firestore.collection('reports').doc(id).update({
      'status': status,
      if (resolution != null) 'resolution': resolution,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'report_status_update',
      targetId: id,
      targetType: 'reports',
      reason: 'Status changed to $status',
      extraData: {'newStatus': status, 'resolution': resolution},
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
