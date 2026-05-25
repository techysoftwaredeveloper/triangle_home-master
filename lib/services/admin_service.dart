import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/audit_service.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/services/admin_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();
  final IsarService _isarService = IsarService();
  final AdminApiService _apiService = AdminApiService();

  // Helper to recursively sanitize data for JSON encoding
  dynamic _sanitize(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    if (value is List) return value.map(_sanitize).toList();
    return value;
  }

  // ==================== REAL-TIME STREAMS WITH CACHE ====================

  Stream<Map<String, dynamic>> getStatsStream() {
    // 1. Initial cached emission
    final cachedStream = Stream.fromFuture(_isarService.getAdminCache('dashboard_stats'))
        .where((c) => c != null)
        .map((c) => json.decode(c!) as Map<String, dynamic>);

    // 2. Real-time Firestore aggregation
    final firestoreStream = Rx.combineLatest7(
      _firestore.collection('users').snapshots(),
      _firestore.collection('properties').snapshots(),
      _firestore.collection('bookings').snapshots(),
      _firestore.collection('payments').snapshots(),
      _firestore.collection('property_suggestions').snapshots(),
      _firestore.collection('reports').snapshots(),
      _firestore.collection('audit_logs').snapshots(),
      (users, properties, bookings, payments, suggestions, reports, auditLogs) {
        double totalRevenue = 0;
        for (var doc in payments.docs) {
          totalRevenue += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        }

        final students = users.docs.where((doc) {
          final data = doc.data();
          return data['role'] == 'student' || data['role'] == 'user';
        }).length;

        final hosters = users.docs.where((doc) {
          final data = doc.data();
          return data['role'] == 'hoster';
        }).length;

        final pendingProperties = properties.docs
              .where((doc) => doc.data()['status'] == 'pending')
              .length;

        final pendingHosters = users.docs
              .where((doc) => doc.data()['role'] == 'hoster' && (doc.data()['status'] == 'pending' || doc.data()['accountStatus'] == 'pending'))
              .length;

        final unresolvedReports = reports.docs
              .where((doc) => (doc.data()['status'] ?? '').toString().toLowerCase() == 'pending')
              .length;

        final pendingSuggestions = suggestions.docs
              .where((doc) => (doc.data()['status'] ?? '').toString().toLowerCase() == 'pending' || (doc.data()['status'] ?? '').toString().toLowerCase() == 'under review')
              .length;

        final pendingModeration = auditLogs.docs
              .where((doc) => (doc.data()['status'] ?? '').toString().toLowerCase() == 'pending')
              .length;

        final stats = {
          'totalProperties': properties.docs.length,
          'totalBookings': bookings.docs.length,
          'totalUsers': users.docs.length,
          'totalStudents': students,
          'totalHosters': hosters,
          'totalRevenue': totalRevenue,
          'pendingProperties': pendingProperties,
          'pendingHosters': pendingHosters,
          'pendingApprovals': pendingProperties + pendingHosters,
          'pendingReports': unresolvedReports,
          'pendingSuggestions': pendingSuggestions,
          'pendingModeration': pendingModeration,
          'totalNotifications': pendingProperties + pendingHosters + unresolvedReports + pendingModeration,
        };

        // Cache the sanitized result
        _isarService.saveAdminCache('dashboard_stats', json.encode(_sanitize(stats)));

        return stats;
      },
    );

    return Rx.concat([cachedStream, firestoreStream]).asBroadcastStream();
  }

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

      // Save to cache (Sanitized)
      await _isarService.saveAdminCache('admin_pending_approvals', json.encode(_sanitize(approvals)));

      return approvals;
    });
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() async* {
    // 1. Emit cached users immediately
    final cachedUsers = await _isarService.getAdminCache('admin_users_list');
    if (cachedUsers != null) {
      try {
        final List<dynamic> list = json.decode(cachedUsers);
        yield list.cast<Map<String, dynamic>>();
      } catch (e) {
        debugPrint('Error decoding cached users: $e');
      }
    }

    // 2. Sync with Firestore
    yield* _firestore.collection('users').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final users = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Save to Local Cache (Sanitized)
      await _isarService.saveAdminCache('admin_users_list', json.encode(_sanitize(users)));
      return users;
    });
  }

  Stream<List<Map<String, dynamic>>> getPropertiesStream() async* {
    final cached = await _isarService.getAdminCache('admin_properties_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('properties').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final properties = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      await _isarService.saveAdminCache('admin_properties_list', json.encode(_sanitize(properties)));
      return properties;
    });
  }

  Stream<List<Map<String, dynamic>>> getBookingsStream() async* {
    final cached = await _isarService.getAdminCache('admin_bookings_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('bookings').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final bookings = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      await _isarService.saveAdminCache('admin_bookings_list', json.encode(_sanitize(bookings)));
      return bookings;
    });
  }

  Stream<List<Map<String, dynamic>>> getPaymentsStream() async* {
    final cached = await _isarService.getAdminCache('admin_payments_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('payments').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final payments = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      await _isarService.saveAdminCache('admin_payments_list', json.encode(_sanitize(payments)));
      return payments;
    });
  }

  Stream<List<Map<String, dynamic>>> getSuggestionsStream() async* {
    final cached = await _isarService.getAdminCache('admin_suggestions_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('property_suggestions').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final suggestions = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      await _isarService.saveAdminCache('admin_suggestions_list', json.encode(_sanitize(suggestions)));
      return suggestions;
    });
  }

  Stream<List<Map<String, dynamic>>> getReportsStream() async* {
    final cached = await _isarService.getAdminCache('admin_reports_list');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('reports').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      final reports = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      await _isarService.saveAdminCache('admin_reports_list', json.encode(_sanitize(reports)));
      return reports;
    });
  }

  Stream<List<Map<String, dynamic>>> getUserSuggestionsStream(String userId) {
    return _firestore
        .collection('property_suggestions')
        .where('suggester_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getAuditLogsStream() async* {
    final cached = await _isarService.getAdminCache('admin_audit_logs');
    if (cached != null) yield (json.decode(cached) as List).cast<Map<String, dynamic>>();

    yield* _firestore.collection('audit_logs').orderBy('timestamp', descending: true).snapshots().asyncMap((snapshot) async {
      final logs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      await _isarService.saveAdminCache('admin_audit_logs', json.encode(_sanitize(logs)));
      return logs;
    });
  }

  Stream<Map<String, dynamic>?> getSuggestionStream(String id) {
    return _firestore.collection('property_suggestions').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    });
  }

  Future<bool> checkServerConnection() async {
    try {
      final response = await _apiService.getStats();
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== MODERATION ACTIONS (VIA BACKEND) ====================

  Future<void> updatePropertyStatus(String propertyId, PropertyStatus status, {String? reason}) async {
    // Route through Backend API for secure state change and custom claims
    await _apiService.updatePropertyStatus(propertyId, status.name);

    await _auditService.logAction(
      action: 'property_status_update',
      targetId: propertyId,
      targetType: 'property',
      reason: reason ?? 'Updated to ${status.name} via Backend',
      extraData: {'newStatus': status.name},
    );
  }

  Future<void> approveHoster(String hosterId) async {
    // Route through Backend API for role elevation and custom claims
    await _apiService.approveHoster(hosterId);

    await _auditService.logAction(
      action: 'hoster_approval',
      targetId: hosterId,
      targetType: 'hoster',
      reason: 'Approved via Backend',
    );
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    // Route through Backend API for banning/unbanning and claim updates
    await _apiService.toggleUserStatus(userId, isActive: isActive, status: isActive ? 'active' : 'banned');

    await _auditService.logAction(
      action: 'user_status_toggle',
      targetId: userId,
      targetType: 'users',
      reason: 'Account status changed to ${isActive ? "Active" : "Inactive"} via Backend',
      extraData: {'isActive': isActive},
    );
  }

  Future<void> updateUserRole(String userId, String role) async {
    // Route through Backend API for role change and custom claims
    await _apiService.updateUserRole(userId, role);

    await _auditService.logAction(
      action: 'user_role_update',
      targetId: userId,
      targetType: 'users',
      reason: 'Role updated to $role via Backend',
      extraData: {'newRole': role},
    );
  }

  Future<void> rejectItem(String id, String type, {String? reason}) async {
    if (type == 'hoster') {
      // Use User Status toggle to mark as banned/inactive if rejected
      await _apiService.toggleUserStatus(id, status: 'rejected', isActive: false);
    } else {
      await _apiService.updatePropertyStatus(id, 'rejected');
    }

    await _auditService.logAction(
      action: 'item_rejection',
      targetId: id,
      targetType: type,
      reason: reason ?? 'Rejected via Backend',
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
    // Reverted fallback: All requests must go through backend
    await _apiService.updateSuggestionStatus(id, status).timeout(const Duration(seconds: 30));

    // Log action locally for audit trail consistency
    await _auditService.logAction(
      action: 'suggestion_status_update',
      targetId: id,
      targetType: 'suggestions',
      reason: 'Status changed to $status',
      extraData: {'newStatus': status},
    );
  }

  Future<void> convertSuggestionToApprovals(String id) async {
    // Removed manual timeout to prevent premature 'Future not completed' errors
    // The http client has its own internal timeout
    await _apiService.convertSuggestion(id);

    // Log action
    await _auditService.logAction(
      action: 'suggestion_conversion',
      targetId: id,
      targetType: 'suggestions',
      reason: 'Converted to Approvals',
    );
  }

  Future<void> updateReportStatus(String id, String status, {String? resolution}) async {
    await _apiService.updateReportStatus(id, status, resolution: resolution);

    await _auditService.logAction(
      action: 'report_status_update',
      targetId: id,
      targetType: 'reports',
      reason: 'Status changed to $status via Backend',
      extraData: {'newStatus': status, 'resolution': resolution},
    );
  }

  // ==================== SUPERADMIN OPS ====================

  Future<void> deleteListing(String propertyId) async {
    await _firestore.collection('properties').doc(propertyId).delete();
  }

  Future<void> promoteToAdmin(String userId) async {
    await updateUserRole(userId, 'admin');
  }
}
