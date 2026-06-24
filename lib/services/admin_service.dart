import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/audit_service.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/services/admin_api_service.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();
  final IsarService _isarService = IsarService();
  final AdminApiService _apiService = AdminApiService();

  // Helper to recursively sanitize data for JSON encoding
  dynamic _sanitize(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is List) return value.map(_sanitize).toList();
    return value;
  }


  Stream<Map<String, dynamic>> getGlobalStatsStream() {
    return _firestore
        .collection('adminStats')
        .doc('global')
        .snapshots()
        .map((doc) => doc.exists ? doc.data()! : {});
  }

  Stream<Map<String, dynamic>> getPropertyStatsStream(String propertyId) {
    return _firestore
        .collection('propertyStats')
        .doc(propertyId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data()! : {});
  }

  Stream<Map<String, dynamic>> getOccupancyStatsStream(String propertyId) {
    return _firestore
        .collection('occupancyStats')
        .doc(propertyId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data()! : {});
  }

  Stream<Map<String, dynamic>> getRevenueStatsStream(String propertyId) {
    return _firestore
        .collection('revenueStats')
        .doc(propertyId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data()! : {});
  }

  Stream<Map<String, dynamic>> getComplianceStatsStream(String propertyId) {
    return _firestore
        .collection('complianceStats')
        .doc(propertyId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data()! : {});
  }

  Stream<List<Map<String, dynamic>>> getActivityLogsStream() {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
          final data = doc.data();
          // Map audit_logs to what ActivityFeedWidget expects
          return {
            'id': doc.id,
            'timestamp': data['timestamp'],
            'type': data['targetType'] == 'users' ? 'hoster' : data['targetType'], // Map users to hoster icon
            'action': data['action']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'ACTION',
            'property': data['reason'] ?? data['targetId'], // Use reason or targetId as detail
            ...data,
          };
        }).toList());
  }

  Stream<List<Map<String, dynamic>>> getAuditLogsStream() {
    return _firestore
        .collection('auditLogs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<Map<String, dynamic>> getSystemHealthStream() {
    return _firestore
        .collection('systemHealth')
        .doc('current')
        .snapshots()
        .map((doc) => doc.exists ? doc.data()! : {'status': 'operational'});
  }

  Stream<int> getApprovedTodayCountStream() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection('auditLogs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .snapshots()
        .map((snap) {
          return snap.docs.where((doc) {
            final action = (doc.data()['action'] ?? '').toString().toLowerCase();
            return action.contains('approve') || action.contains('verified');
          }).length;
        });
  }

  // ==================== REAL-TIME STREAMS WITH CACHE ====================

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return 'now';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      dt = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Stream<Map<String, dynamic>> getStatsStream() {
    final statsSubject = BehaviorSubject<Map<String, dynamic>>.seeded({});

    // 1. Load from cache immediately
    _isarService.getAdminCache('dashboard_stats').then((cached) {
      if (cached != null && statsSubject.isClosed == false) {
        statsSubject.add(json.decode(cached) as Map<String, dynamic>);
      }
    });

    // 2. Multi-stream non-blocking listeners
    void updateStats(String key, dynamic value) {
      if (!statsSubject.isClosed) {
        final current = Map<String, dynamic>.from(statsSubject.value);
        current[key] = value;
        statsSubject.add(current);
        
        // Background cache update (debounce in real production)
        _isarService.saveAdminCache('dashboard_stats', json.encode(_sanitize(current)));
      }
    }

    // Listen to components independently to prevent blocking
    _firestore.collection('users').snapshots().listen((snap) {
      final docs = snap.docs;
      updateStats('totalUsers', docs.length);
      updateStats('totalStudents', docs.where((d) => ['student', 'user', ''].contains(d.data()['role']?.toString().toLowerCase())).length);
      updateStats('totalProfessionals', docs.where((d) => d.data()['role']?.toString().toLowerCase() == 'professional').length);
      updateStats('totalHosters', docs.where((d) => ['hoster', 'owner', 'manager', 'agency'].contains(d.data()['role']?.toString().toLowerCase())).length);
      updateStats('pendingHosters', docs.where((d) => d.data()['onboardingStatus'] == 'submitted').length);
      updateStats('reportedUsers', docs.where((d) => d.data()['reportCount'] != null && (d.data()['reportCount'] as num) > 0).length);
      updateStats('blockedUsers', docs.where((d) => d.data()['is_active'] == false).length);
      updateStats('pendingApprovals', docs.where((d) => d.data()['verification']?['roleIdStatus'] == 'pending').length);
    });

    _firestore.collection('properties').snapshots().listen((snap) {
      updateStats('totalProperties', snap.size);
      updateStats('activeProperties', snap.docs.where((d) => d.data()['status'] == 'active').length);
      updateStats('pendingProperties', snap.docs.where((d) => d.data()['status'] == 'pending').length);
      
      // Top Cities Logic
      final Map<String, int> cityCounts = {};
      for (var doc in snap.docs) {
        final city = (doc.data()['info']?['city'] ?? 'Other').toString();
        cityCounts[city] = (cityCounts[city] ?? 0) + 1;
      }
      final sortedCities = cityCounts.entries
          .map((e) => {'name': e.key, 'count': e.value})
          .toList();
      sortedCities.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      updateStats('topCities', sortedCities.take(5).toList());
    });

    _firestore.collection('beds').snapshots().listen((snap) {
      final total = snap.size;
      final occupied = snap.docs.where((d) => d.data()['status']?.toString().toLowerCase() == 'occupied').length;
      final rate = total > 0 ? (occupied / total * 100).toStringAsFixed(1) : '0.0';
      updateStats('totalBeds', total);
      updateStats('occupiedBeds', occupied);
      updateStats('occupancyRate', rate);
    });

    _firestore.collection('bookings').snapshots().listen((snap) {
      updateStats('totalBookings', snap.size);
      
      // Booking history for chart (last 7 data points)
      final now = DateTime.now();
      final Map<String, int> dailyBookings = {};
      for (var i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        dailyBookings[DateFormat('dd MMM').format(date)] = 0;
      }
      
      for (var doc in snap.docs) {
        final created = doc.data()['createdAt'];
        if (created is Timestamp) {
          final dateStr = DateFormat('dd MMM').format(created.toDate());
          if (dailyBookings.containsKey(dateStr)) {
            dailyBookings[dateStr] = dailyBookings[dateStr]! + 1;
          }
        }
      }
      
      final history = dailyBookings.entries.map((e) => {'date': e.key, 'value': e.value}).toList().reversed.toList();
      updateStats('bookingHistory', history);
    });

    _firestore.collection('payments').snapshots().listen((snap) {
      double total = 0;
      double paid = 0;
      double pending = 0;
      double refunded = 0;
      
      final Map<String, double> revenueHistoryMap = {};
      final now = DateTime.now();
      for (var i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        revenueHistoryMap[DateFormat('dd MMM').format(date)] = 0;
      }

      for (var doc in snap.docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        final status = doc.data()['status']?.toString().toLowerCase();
        
        if (status == 'completed' || status == 'success') {
          paid += amount;
          total += amount;
        } else if (status == 'pending') {
          pending += amount;
        } else if (status == 'refunded') {
          refunded += amount;
        }

        final created = doc.data()['createdAt'];
        if (created is Timestamp && (status == 'completed' || status == 'success')) {
          final dateStr = DateFormat('dd MMM').format(created.toDate());
          if (revenueHistoryMap.containsKey(dateStr)) {
            revenueHistoryMap[dateStr] = revenueHistoryMap[dateStr]! + amount;
          }
        }
      }
      
      updateStats('totalRevenue', total);
      updateStats('paidRevenue', paid);
      updateStats('pendingRevenue', pending);
      updateStats('refundedRevenue', refunded);
      
      final history = revenueHistoryMap.entries.map((e) => {'date': e.key, 'value': e.value}).toList().reversed.toList();
      updateStats('revenueHistory', history);
    });

    _firestore.collection('property_suggestions').snapshots().listen((snap) {
      final docs = snap.docs;
      updateStats('newSuggestions', docs.where((d) => d.data()['status'] == 'pending' || d.data()['status'] == 'new').length);
      updateStats('reviewSuggestions', docs.where((d) => d.data()['status'] == 'under_review').length);
      updateStats('contactedSuggestions', docs.where((d) => d.data()['status'] == 'contacted').length);
      updateStats('approvedSuggestions', docs.where((d) => d.data()['status'] == 'approved').length);
      updateStats('rejectedSuggestions', docs.where((d) => d.data()['status'] == 'rejected').length);
    });

    _firestore.collection('reports').snapshots().listen((snap) {
      updateStats('reportedListings', snap.docs.where((d) => d.data()['status'] == 'pending').length);
    });

    _firestore.collection('audit_logs').orderBy('timestamp', descending: true).limit(10).snapshots().listen((snap) {
      final activities = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'title': data['action']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'ACTION',
          'subtitle': data['reason'] ?? data['targetId'] ?? 'Platform update',
          'time': _timeAgo(data['timestamp']),
        };
      }).toList();
      updateStats('recentActivities', activities);
    });

    return statsSubject.stream;
  }

  Stream<List<Map<String, dynamic>>> getPendingApprovalsStream() {
    // We use BehaviorSubject to manage the combined state manually and ensure immediate emissions
    final subject = BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> latestDocs = {
      'submittedHosters': [],
      'pendingStatusUsers': [],
      'pendingAccountUsers': [],
      'pendingVerifUsers': [],
      'pendingProperties': [],
    };

    void emit() {
      if (subject.isClosed) return;
      
      final Map<String, Map<String, dynamic>> approvalMap = {};

      void addUsers(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String type) {
        for (var doc in docs) {
          final data = doc.data();
          final info = data['info'] as Map? ?? {};
          final role = (data['role'] ?? '').toString().toLowerCase();

          approvalMap[doc.id] = {
            ...data,
            'id': doc.id,
            'uid': doc.id,
            'userId': doc.id,
            'type': type,
            'name': info['name'] ?? 'User Applicant',
            'email': info['email'],
            'createdAt': data['updatedAt'] ?? 
                        data['createdAt'] ?? 
                        (type == 'user_verification' ? (data['verification']?['roleIdTimestamp'] ?? data['verification']?['selfieTimestamp']) : null),
          };
          
          if (type == 'user_verification') {
             approvalMap[doc.id]!['verificationType'] = role == 'student' ? 'Student ID' : 'Professional ID';
          } else if (type == 'hoster') {
             approvalMap[doc.id]!['hosterName'] = info['name'];
             approvalMap[doc.id]!['location'] = '${info['city'] ?? ""}, ${info['state'] ?? ""}';
          }
        }
      }

      addUsers(latestDocs['pendingVerifUsers']!, 'user_verification');
      addUsers(latestDocs['submittedHosters']!, 'hoster');
      addUsers(latestDocs['pendingStatusUsers']!, 'hoster');
      addUsers(latestDocs['pendingAccountUsers']!, 'hoster');

      final List<Map<String, dynamic>> approvals = approvalMap.values.toList();

      for (var doc in latestDocs['pendingProperties']!) {
        final data = doc.data();
        final verification = data['verification'] as Map? ?? {};
        final documents = data['documents'] as Map? ?? {};

        int uploaded = 0;
        if (verification['aadhaarUrl'] != null) uploaded++;
        if (verification['panUrl'] != null) uploaded++;
        if (documents['ownershipUrl'] != null) uploaded++;
        if (documents['utilityUrl'] != null) uploaded++;
        if (documents['additionalUrl'] != null) uploaded++;

        approvals.add({
          ...data,
          'id': doc.id,
          'type': 'property',
          'docsCount': '$uploaded/5',
        });
      }

      approvals.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      subject.add(approvals);
      
      // Cache the result
      _isarService.saveAdminCache(
        'admin_pending_approvals',
        json.encode(_sanitize(approvals)),
      );
    }

    // Individual listeners
    final subscriptions = [
      _firestore.collection('users').where('onboardingStatus', isEqualTo: 'submitted').snapshots().listen((snap) {
        latestDocs['submittedHosters'] = snap.docs;
        emit();
      }),
      _firestore.collection('users').where('status', isEqualTo: 'pending').snapshots().listen((snap) {
        latestDocs['pendingStatusUsers'] = snap.docs;
        emit();
      }),
      _firestore.collection('users').where('accountStatus', isEqualTo: 'pending').snapshots().listen((snap) {
        latestDocs['pendingAccountUsers'] = snap.docs;
        emit();
      }),
      _firestore.collection('users').where('verification.roleIdStatus', isEqualTo: 'pending').snapshots().listen((snap) {
        latestDocs['pendingVerifUsers'] = snap.docs;
        emit();
      }),
      _firestore.collection('properties').where('status', isEqualTo: 'pending').snapshots().listen((snap) {
        latestDocs['pendingProperties'] = snap.docs;
        emit();
      }),
    ];

    // Ensure subscriptions are closed when stream is canceled
    subject.onCancel = () {
      for (var sub in subscriptions) {
        sub.cancel();
      }
    };

    return subject.stream;
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() async* {
    final cachedUsers = await _isarService.getAdminCache('admin_users_list');
    if (cachedUsers != null) {
      try {
        final List<dynamic> list = json.decode(cachedUsers);
        yield list.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    yield* _firestore
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) async {
          final users =
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();

          users.sort((a, b) {
            final aTime = a['createdAt'] ?? a['updatedAt'];
            final bTime = b['createdAt'] ?? b['updatedAt'];
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            final aDT = (aTime is Timestamp) ? aTime.toDate() : DateTime.tryParse(aTime.toString());
            final bDT = (bTime is Timestamp) ? bTime.toDate() : DateTime.tryParse(bTime.toString());
            if (aDT == null || bDT == null) return 0;
            return bDT.compareTo(aDT);
          });

          await _isarService.saveAdminCache(
            'admin_users_list',
            json.encode(_sanitize(users)),
          );
          return users;
        });
  }

  Stream<List<Map<String, dynamic>>> getPropertiesStream() async* {
    final cached = await _isarService.getAdminCache('admin_properties_list');
    if (cached != null) {
      yield (json.decode(cached) as List).cast<Map<String, dynamic>>();
    }

    yield* _firestore
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final properties =
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();

          await _isarService.saveAdminCache(
            'admin_properties_list',
            json.encode(_sanitize(properties)),
          );
          return properties;
        });
  }

  Stream<List<Map<String, dynamic>>> getBookingsStream() async* {
    final cached = await _isarService.getAdminCache('admin_bookings_list');
    if (cached != null) {
      yield (json.decode(cached) as List).cast<Map<String, dynamic>>();
    }

    yield* _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bookings =
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();

          await _isarService.saveAdminCache(
            'admin_bookings_list',
            json.encode(_sanitize(bookings)),
          );
          return bookings;
        });
  }

  Stream<List<Map<String, dynamic>>> getPaymentsStream() async* {
    final cached = await _isarService.getAdminCache('admin_payments_list');
    if (cached != null) {
      yield (json.decode(cached) as List).cast<Map<String, dynamic>>();
    }

    yield* _firestore
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final payments =
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();

          await _isarService.saveAdminCache(
            'admin_payments_list',
            json.encode(_sanitize(payments)),
          );
          return payments;
        });
  }

  Stream<List<Map<String, dynamic>>> getSuggestionsStream() async* {
    final cached = await _isarService.getAdminCache('admin_suggestions_list');
    if (cached != null) {
      yield (json.decode(cached) as List).cast<Map<String, dynamic>>();
    }

    yield* _firestore
        .collection('property_suggestions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final suggestions =
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();

          await _isarService.saveAdminCache(
            'admin_suggestions_list',
            json.encode(_sanitize(suggestions)),
          );
          return suggestions;
        });
  }

  Stream<List<Map<String, dynamic>>> getReportsStream() async* {
    final cached = await _isarService.getAdminCache('admin_reports_list');
    if (cached != null) {
      yield (json.decode(cached) as List).cast<Map<String, dynamic>>();
    }

    yield* _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reports =
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();

          await _isarService.saveAdminCache(
            'admin_reports_list',
            json.encode(_sanitize(reports)),
          );
          return reports;
        });
  }

  Stream<List<Map<String, dynamic>>> getUserSuggestionsStream(String userId) {
    return _firestore
        .collection('property_suggestions')
        .where('suggester_id', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getUserPropertiesStream(String userId) {
    final snake = _firestore
        .collection('properties')
        .where('hoster_id', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

    final camel = _firestore
        .collection('properties')
        .where('hosterId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

    return Rx.combineLatest2(snake, camel, (a, b) {
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final p in [...a, ...b]) {
        final id = p['id']?.toString() ?? '';
        if (id.isNotEmpty && seen.add(id)) merged.add(p);
      }
      return merged;
    });
  }

  Stream<List<Map<String, dynamic>>> getUserBookingsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<Map<String, dynamic>?> getUserHosterRequestStream(String userId) {
    return _firestore
        .collection('hoster_requests')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    });
  }

  Stream<List<Map<String, dynamic>>> getHosterReceivedBookingsStream(
      String userId) {
    return _firestore
        .collection('bookings')
        .where('hosterId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getUserAuditLogStream(String userId) {
    return _firestore
        .collection('audit_logs')
        .where('targetId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<Map<String, dynamic>?> getSuggestionStream(String id) {
    return _firestore
        .collection('property_suggestions')
        .doc(id)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return {'id': doc.id, ...doc.data()!};
        });
  }

  Future<bool> checkServerConnection() async {
    try {
      final response = await _apiService.getStats();
      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> updatePropertyStatus(
    String propertyId,
    PropertyStatus status, {
    String? reason,
  }) async {
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
    await _apiService.approveHoster(hosterId);

    await _firestore.collection('users').doc(hosterId).set({
      'status': 'approved',
      'accountStatus': 'active',
      'onboardingStatus': 'approved',
      'permissions': {'status': 'approved'},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _auditService.logAction(
      action: 'hoster_approval',
      targetId: hosterId,
      targetType: 'hoster',
      reason: 'Approved via Backend',
    );
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    await _apiService.toggleUserStatus(
      userId,
      isActive: isActive,
      status: isActive ? 'active' : 'banned',
    );

    await _auditService.logAction(
      action: 'user_status_toggle',
      targetId: userId,
      targetType: 'users',
      reason:
          'Account status changed to ${isActive ? "Active" : "Inactive"} via Backend',
      extraData: {'isActive': isActive},
    );
  }

  Future<void> updateUserRole(String userId, String role) async {
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
      await _apiService.toggleUserStatus(
        id,
        status: 'rejected',
        isActive: false,
      );
      
      // Save rejection reason to user document for their feedback
      await _firestore.collection('users').doc(id).update({
        'status': 'rejected',
        'rejectionReason': reason ?? 'Application requirements not met.',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } else if (type == 'user_verification') {
      await _firestore.collection('users').doc(id).set({
        'verification': {
          'roleIdVerified': false,
          'roleIdStatus': 'rejected',
          'roleIdRejectReason': reason ?? 'Document unclear or incorrect.',
          'roleIdRejectedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } else {
      await _apiService.updatePropertyStatus(id, 'rejected');

      try {
        final propertyDoc =
            await _firestore.collection('properties').doc(id).get();
        if (propertyDoc.exists) {
          final hosterId = propertyDoc.data()?['hoster_id'];
          final propertyName = propertyDoc.data()?['name'] ?? 'Property';

          if (hosterId != null) {
            await _firestore.collection('notifications').add({
              'user_id': hosterId,
              'title': 'Listing Rejected',
              'body':
                  'Your listing for "$propertyName" was rejected. Reason: ${reason ?? 'Insufficient details'}',
              'type': 'property_rejection',
              'data': {'propertyId': id, 'reason': reason},
              'is_read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

            await _firestore.collection('properties').doc(id).update({
              'rejectionReason': reason,
              'rejectedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (_) {}
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
    } else if (type == 'user_verification') {
      await _firestore.collection('users').doc(id).set({
        'verification': {
          'roleIdVerified': true,
          'roleIdStatus': 'approved',
          'roleIdApprovedAt': FieldValue.serverTimestamp(),
        },
        'status': 'approved',
      }, SetOptions(merge: true));
    } else {
      await updatePropertyStatus(id, PropertyStatus.approved);
    }
  }

  Future<void> updateSuggestionStatus(String id, String status) async {
    await _apiService.updateSuggestionStatus(id, status);

    await _auditService.logAction(
      action: 'suggestion_status_update',
      targetId: id,
      targetType: 'suggestions',
      reason: 'Status changed to $status',
      extraData: {'newStatus': status},
    );
  }

  Future<void> convertSuggestionToApprovals(String id) async {
    await _apiService.convertSuggestion(id);

    await _auditService.logAction(
      action: 'suggestion_conversion',
      targetId: id,
      targetType: 'suggestions',
      reason: 'Converted to Approvals',
    );
  }

  Future<void> updateReportStatus(
    String id,
    String status, {
    String? resolution,
  }) async {
    await _apiService.updateReportStatus(id, status, resolution: resolution);

    await _auditService.logAction(
      action: 'report_status_update',
      targetId: id,
      targetType: 'reports',
      reason: 'Status changed to $status via Backend',
      extraData: {'newStatus': status, 'resolution': resolution},
    );
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'booking_status_update',
      targetId: bookingId,
      targetType: 'bookings',
      reason: 'Status changed to $status',
      extraData: {'newStatus': status},
    );
  }

  Future<Map<String, dynamic>> getHosterDashboardSummary(
    String hosterId,
  ) async {
    final HosterService hosterService = HosterService();
    final stats =
        await hosterService.getDetailedHosterStatsStream(hosterId).first;
    return stats;
  }

  Future<void> deleteListing(String propertyId) async {
    await _firestore.collection('properties').doc(propertyId).delete();
  }

  Future<void> deleteBooking(String bookingId) async {
    await _apiService.deleteBooking(bookingId);

    await _auditService.logAction(
      action: 'booking_deletion',
      targetId: bookingId,
      targetType: 'bookings',
      reason: 'Permanently deleted by admin',
    );
  }

  Future<void> cleanupApprovals() async {
    final result = await _apiService.cleanupApprovals();
    
    await _auditService.logAction(
      action: 'approvals_cleanup',
      targetId: 'system',
      targetType: 'system',
      reason: 'Automated cleanup of incomplete requests',
      extraData: {'count': result['message']},
    );
  }

  Future<void> promoteToAdmin(String userId) async {
    await updateUserRole(userId, 'admin');
  }

  Future<void> deleteUser(String userId) async {
    await _apiService.deleteUser(userId);

    await _auditService.logAction(
      action: 'user_deletion',
      targetId: userId,
      targetType: 'users',
      reason: 'Permanently deleted by admin',
    );
  }

  Future<void> deleteApprovalRequest(String id, String type) async {
    if (type == 'property') {
      await _firestore.collection('properties').doc(id).delete();
    } else if (type == 'hoster') {
      // Deleting a hoster request usually means deleting the draft info
      // But we should be careful not to delete the actual user unless specified
      await _firestore.collection('hoster_requests').doc(id).delete();
      // Reset onboarding status so they can start over if they want
      await _firestore.collection('users').doc(id).update({
        'onboardingStatus': 'pending',
        'status': 'pending'
      });
    } else if (type == 'user_verification') {
      await _firestore.collection('users').doc(id).update({
        'verification.roleIdStatus': FieldValue.delete(),
        'verification.roleIdUrl': FieldValue.delete(),
      });
    }
    
    await _auditService.logAction(
      action: 'item_deletion',
      targetId: id,
      targetType: type,
      reason: 'Permanently deleted by admin',
    );
  }

  /// Migrates existing properties to the new room-wise security deposit logic.
  /// Sets default 2 months rent if no deposit is found.
  Future<void> migratePropertySecurityDeposits() async {
    final snap = await _firestore.collection('properties').get();
    final batch = _firestore.batch();
    int migratedCount = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final pricing = data['pricing'] as Map? ?? {};
      
      bool needsUpdate = false;
      final Map<String, dynamic> updates = {};

      // 1. Check for missing room-wise deposits
      final singleRent = double.tryParse(pricing['singleRent']?.toString() ?? '0') ?? 0;
      final doubleRent = double.tryParse(pricing['doubleRent']?.toString() ?? '0') ?? 0;
      final tripleRent = double.tryParse(pricing['tripleRent']?.toString() ?? '0') ?? 0;

      if (singleRent > 0 && pricing['singleDeposit'] == null) {
        updates['pricing.singleDeposit'] = (singleRent * 2).toInt().toString();
        needsUpdate = true;
      }
      if (doubleRent > 0 && pricing['doubleDeposit'] == null) {
        updates['pricing.doubleDeposit'] = (doubleRent * 2).toInt().toString();
        needsUpdate = true;
      }
      if (tripleRent > 0 && pricing['tripleDeposit'] == null) {
        updates['pricing.tripleDeposit'] = (tripleRent * 2).toInt().toString();
        needsUpdate = true;
      }

      // 2. Fallback for main securityDeposit field if missing
      if (data['securityDeposit'] == null || data['securityDeposit'].toString().isEmpty) {
        final mainRent = double.tryParse(data['monthlyRent']?.toString() ?? '0') ?? singleRent;
        if (mainRent > 0) {
          updates['securityDeposit'] = (mainRent * 2).toInt().toString();
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        batch.update(doc.reference, updates);
        migratedCount++;
      }
    }

    if (migratedCount > 0) {
      await batch.commit();
      await _auditService.logAction(
        action: 'security_deposit_migration',
        targetId: 'system',
        targetType: 'system',
        reason: 'Migrated $migratedCount properties to 2-month rent default standard',
      );
    }
  }
}
