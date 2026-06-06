import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/audit_service.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/services/admin_api_service.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:flutter/foundation.dart';
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

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    return DateFormat('hh:mm a').format(date);
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
        .collection('activityLogs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
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

  // ==================== REAL-TIME STREAMS WITH CACHE ====================

  Stream<Map<String, dynamic>> getStatsStream() {
    // 1. Initial cached emission
    final cachedStream = Stream.fromFuture(
          _isarService.getAdminCache('dashboard_stats'),
        )
        .where((c) => c != null)
        .map((c) => json.decode(c!) as Map<String, dynamic>);

    // 2. Real-time Firestore aggregation
    final firestoreStream = Rx.combineLatest9(
      _firestore.collection('users').snapshots(),
      _firestore.collection('properties').snapshots(),
      _firestore.collection('bookings').snapshots(),
      _firestore.collection('payments').snapshots(),
      _firestore.collection('property_suggestions').snapshots(),
      _firestore.collection('reports').snapshots(),
      _firestore.collection('audit_logs').snapshots(),
      _firestore.collection('disputes').snapshots(),
      _firestore.collection('escrow').snapshots(),
      (
        users,
        properties,
        bookings,
        payments,
        suggestions,
        reports,
        auditLogs,
        disputes,
        escrow,
      ) {
        double totalRevenue = 0;
        // ... (existing loops for payments)
        double paidRevenue = 0;
        double pendingRevenue = 0;
        double refundedRevenue = 0;

        for (var doc in payments.docs) {
          final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
          final status = (doc.data()['status'] ?? '').toString().toLowerCase();

          if (status == 'paid' || status == 'success' || status == 'captured') {
            paidRevenue += amount;
            totalRevenue += amount;
          } else if (status == 'pending') {
            pendingRevenue += amount;
          } else if (status == 'refunded') {
            refundedRevenue += amount;
          }
        }

        final students =
            users.docs.where((doc) {
              final data = doc.data();
              final r = data['role']?.toString().toLowerCase() ?? '';
              return r == 'student' || r == 'user' || r.isEmpty;
            }).length;

        final professionals =
            users.docs.where((doc) {
              final data = doc.data();
              final r = data['role']?.toString().toLowerCase() ?? '';
              return r == 'professional';
            }).length;

        final hosters =
            users.docs.where((doc) {
              final data = doc.data();
              final r = data['role']?.toString().toLowerCase() ?? '';
              return r == 'hoster' || r == 'owner' || r == 'manager' || r == 'agency';
            }).length;

        final owners =
            users.docs.where((doc) {
              final data = doc.data();
              final r = data['role']?.toString().toLowerCase() ?? '';
              return r == 'owner';
            }).length;

        final pendingProperties =
            properties.docs
                .where((doc) => doc.data()['status'] == 'pending')
                .length;

        final pendingHosters =
            users.docs
                .where(
                  (doc) {
                    final d = doc.data();
                    final permissions = d['permissions'] as Map? ?? {};
                    final r = (d['role'] ?? permissions['role'] ?? '').toString().toLowerCase();
                    final isHosterType = r == 'hoster' || r == 'owner' || r == 'manager' || r == 'agency';
                    final status = (d['status'] ?? d['accountStatus'] ?? permissions['status'] ?? '').toString().toLowerCase();
                    return isHosterType && status == 'pending';
                  },
                )
                .length;

        final activeAgents =
            users.docs.where((doc) {
              final data = doc.data();
              final r = data['role']?.toString().toLowerCase() ?? '';
              return r == 'admin' || r == 'superadmin';
            }).length;

        final unresolvedReports =
            reports.docs
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                      'pending',
                )
                .length;

        final pendingSuggestions =
            suggestions.docs
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                          'pending' ||
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                          'under review',
                )
                .length;

        final newSuggestions =
            suggestions.docs
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                      'pending',
                )
                .length;

        final reviewSuggestions =
            suggestions.docs
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                          'under review' ||
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                          'underreview',
                )
                .length;

        final contactedSuggestions =
            suggestions.docs
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                      'contacted',
                )
                .length;

        final approvedSuggestions =
            suggestions.docs
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                      'approved',
                )
                .length;

        final rejectedSuggestions =
            suggestions.docs
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                      'rejected',
                )
                .length;

        final failedPayments =
            payments.docs
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                      'failed',
                )
                .length;

        final blockedUsers =
            users.docs
                .where(
                  (doc) =>
                      (doc.data()['accountStatus'] ?? '')
                              .toString()
                              .toLowerCase() ==
                          'banned' ||
                      (doc.data()['accountStatus'] ?? '')
                              .toString()
                              .toLowerCase() ==
                          'blocked',
                )
                .length;

        final reportedListings =
            reports.docs
                .where(
                  (doc) =>
                      (doc.data()['type'] ?? '').toString().toLowerCase() ==
                          'property' ||
                      (doc.data()['type'] ?? '').toString().toLowerCase() ==
                          'listing',
                )
                .length;

        final reportedUsers =
            reports.docs
                .where(
                  (doc) =>
                      (doc.data()['type'] ?? '').toString().toLowerCase() ==
                      'user',
                )
                .length;

        final pendingModeration =
            auditLogs.docs
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '').toString().toLowerCase() ==
                      'pending',
                )
                .length;

        final openDisputes =
            disputes.docs
                .where(
                  (doc) =>
                      doc.data()['status'] == DisputeStatus.open.name ||
                      doc.data()['status'] == DisputeStatus.underReview.name,
                )
                .length;

        final readyPayouts =
            escrow.docs
                .where(
                  (doc) =>
                      doc.data()['escrowStatus'] ==
                      EscrowStatus.readyForPayout.name,
                )
                .length;

        final expiringReservations =
            bookings.docs.where((doc) {
              final status = doc.data()['status'];
              final expiryStr = doc.data()['expiryTime'];
              if (status != BookingStatus.reserved.name || expiryStr == null) {
                return false;
              }
              final expiry =
                  (expiryStr is Timestamp)
                      ? expiryStr.toDate()
                      : DateTime.tryParse(expiryStr.toString());
              if (expiry == null) return false;
              final diff = expiry.difference(DateTime.now()).inHours;
              return diff >= 0 && diff <= 12;
            }).length;

        // Top Cities calculation
        Map<String, int> cityCounts = {};
        for (var doc in properties.docs) {
          final address = (doc.data()['address'] ?? '').toString();
          // Extract city - this is a simplification, assumes "City, State" format or just "City"
          final parts = address.split(',');
          final city =
              parts.length > 1
                  ? parts[parts.length - 2].trim()
                  : (parts.isNotEmpty ? parts[0].trim() : 'Unknown');
          if (city.isNotEmpty) {
            cityCounts[city] = (cityCounts[city] ?? 0) + 1;
          }
        }
        final sortedCities =
            cityCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
        final topCities =
            sortedCities
                .take(5)
                .map((e) => {'name': e.key, 'count': e.value})
                .toList();

        // Recent Activity from audit logs
        final sortedAuditLogs =
            auditLogs.docs.toList()..sort((a, b) {
              final aTime =
                  (a.data()['createdAt'] as Timestamp?)
                      ?.millisecondsSinceEpoch ??
                  0;
              final bTime =
                  (b.data()['createdAt'] as Timestamp?)
                      ?.millisecondsSinceEpoch ??
                  0;
              return bTime.compareTo(aTime);
            });

        final recentActivities =
            sortedAuditLogs.take(5).map((doc) {
              final d = doc.data();
              return {
                'title': d['action'] ?? d['title'] ?? 'System Action',
                'subtitle': d['description'] ?? d['subtitle'] ?? '',
                'time': _formatTime(d['createdAt']),
                'type': d['type'] ?? 'info',
              };
            }).toList();

        final stats = {
          'totalProperties': properties.docs.length,
          'activeProperties':
              properties.docs
                  .where((doc) => doc.data()['status'] == 'approved' || doc.data()['status'] == 'active')
                  .length,
          'totalBookings': bookings.docs.length,
          'totalUsers': users.docs.length,
          'totalStudents': students,
          'totalProfessionals': professionals,
          'totalHosters': hosters,
          'totalOwners': owners,
          'totalRevenue': totalRevenue,
          'paidRevenue': paidRevenue,
          'pendingRevenue': pendingRevenue,
          'refundedRevenue': refundedRevenue,
          'pendingProperties': pendingProperties,
          'pendingHosters': pendingHosters,
          'pendingApprovals': pendingProperties + pendingHosters,
          'pendingReports': unresolvedReports,
          'pendingSuggestions': pendingSuggestions,
          'pendingModeration': pendingModeration,
          'openDisputes': openDisputes,
          'readyPayouts': readyPayouts,
          'expiringReservations': expiringReservations,
          'totalNotifications':
              pendingProperties +
              pendingHosters +
              unresolvedReports +
              pendingModeration +
              openDisputes,
          'newSuggestions': newSuggestions,
          'reviewSuggestions': reviewSuggestions,
          'contactedSuggestions': contactedSuggestions,
          'approvedSuggestions': approvedSuggestions,
          'rejectedSuggestions': rejectedSuggestions,
          'failedPayments': failedPayments,
          'blockedUsers': blockedUsers,
          'reportedListings': reportedListings,
          'reportedUsers': reportedUsers,
          'topCities': topCities,
          'recentActivities': recentActivities,
          'activeNow':
              users.docs.where((doc) => doc.data()['isOnline'] == true).length +
              2, // +2 for fallback/admin
          'activeAgents': activeAgents,
          'occupancyRate':
              properties.docs.isEmpty
                  ? 0
                  : ((bookings.docs.length / properties.docs.length) * 100)
                      .toStringAsFixed(1),
        };

        // Cache the sanitized result
        _isarService.saveAdminCache(
          'dashboard_stats',
          json.encode(_sanitize(stats)),
        );

        return stats;
      },
    );

    return Rx.concat([cachedStream, firestoreStream]).asBroadcastStream();
  }

  Stream<List<Map<String, dynamic>>> getPendingApprovalsStream() {
    // 1. Fetch from Firestore (Users & Properties) - Both in REAL-TIME
    final usersStream = _firestore.collection('users').snapshots();

    final propertiesStream =
        _firestore
            .collection('properties')
            .where('status', isEqualTo: 'pending')
            .snapshots();

    return Rx.combineLatest2(
      usersStream,
      propertiesStream,
      (userSnap, propertySnap) {
        final List<Map<String, dynamic>> approvals = [];

        // Add User Verifications (Students/Professionals)
        for (var doc in userSnap.docs) {
          final data = doc.data();
          final info = data['info'] as Map? ?? {};
          final verif = data['verification'] as Map? ?? {};
          final role = (data['role'] ?? '').toString().toLowerCase();

          final isUserType = role == 'student' || role == 'professional' || role == 'user';
          final isVerifPending = verif['roleIdStatus'] == 'pending';

          if (isUserType && isVerifPending) {
            approvals.add({
              'id': doc.id,
              'uid': doc.id,
              'type': 'user_verification',
              'name': info['name'] ?? 'User Applicant',
              'email': info['email'],
              'verificationType':
                  role == 'student' ? 'Student ID' : 'Professional ID',
              'createdAt': data['updatedAt'] ?? data['createdAt'],
              ...data,
            });
          }
        }

        // Add Hosters from users collection
        for (var doc in userSnap.docs) {
          final data = doc.data();
          final info = data['info'] as Map? ?? {};
          final permissions = data['permissions'] as Map? ?? {};
          
          final r = (data['role'] ?? permissions['role'] ?? '').toString().toLowerCase();
          final isHosterType = r == 'hoster' || r == 'owner' || r == 'manager' || r == 'agency';
          final status = (data['status'] ?? data['accountStatus'] ?? permissions['status'] ?? '').toString().toLowerCase();

          if (isHosterType && status == 'pending') {
            approvals.add({
              'id': doc.id,
              'uid': doc.id,
              'type': 'hoster',
              'name': info['name'] ?? 'Hoster Applicant',
              'hosterName': info['name'],
              'email': info['email'],
              'location': '${info['city'] ?? ""}, ${info['state'] ?? ""}',
              'createdAt': data['createdAt'] ?? data['updatedAt'],
              'permissions': permissions,
              ...data,
            });
          }
        }

        // Add Properties
        for (var doc in propertySnap.docs) {
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
            'id': doc.id,
            'type': 'property',
            'docsCount': '$uploaded/5',
            ...data,
          });
        }

        // Sort by createdAt if available
        approvals.sort((a, b) {
          final aDate = a['createdAt'] as Timestamp?;
          final bDate = b['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        // Save to cache (Sanitized)
        _isarService.saveAdminCache(
          'admin_pending_approvals',
          json.encode(_sanitize(approvals)),
        );

        return approvals;
      },
    ).asBroadcastStream();
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
    yield* _firestore
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) async {
          final users =
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();

          // Sort in-memory descending safely
          users.sort((a, b) {
            final aTime = a['createdAt'] ?? a['updatedAt'];
            final bTime = b['createdAt'] ?? b['updatedAt'];
            if (aTime == null && bTime == null) return b['id'].toString().compareTo(a['id'].toString());
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            final aDateTime = (aTime is Timestamp) ? aTime.toDate() : DateTime.tryParse(aTime.toString());
            final bDateTime = (bTime is Timestamp) ? bTime.toDate() : DateTime.tryParse(bTime.toString());
            if (aDateTime == null || bDateTime == null) return 0;
            return bDateTime.compareTo(aDateTime);
          });

          // Save to Local Cache (Sanitized)
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

  /// Fetches all properties listed by a specific hoster/owner.
  /// Queries both `hoster_id` (primary) and `hosterId` (legacy) field names.
  Stream<List<Map<String, dynamic>>> getUserPropertiesStream(String userId) {
    // hoster_id is the canonical field used by property_service and hoster_service
    final snake = _firestore
        .collection('properties')
        .where('hoster_id', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

    // hosterId is the legacy camelCase field used by pricing_info_screen
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

  /// Fetches all bookings made by a specific user (as tenant).
  Stream<List<Map<String, dynamic>>> getUserBookingsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Fetches the hoster onboarding request document for a user.
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

  /// Fetches all bookings received on a hoster's properties (as host).
  Stream<List<Map<String, dynamic>>> getHosterReceivedBookingsStream(
      String userId) {
    return _firestore
        .collection('bookings')
        .where('hosterId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Fetches recent audit log entries for a specific user (actions ON this user).
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
    } catch (e) {
      return false;
    }
  }

  // ==================== MODERATION ACTIONS (VIA BACKEND) ====================

  Future<void> updatePropertyStatus(
    String propertyId,
    PropertyStatus status, {
    String? reason,
  }) async {
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
      await _apiService.toggleUserStatus(
        id,
        status: 'rejected',
        isActive: false,
      );
    } else {
      await _apiService.updatePropertyStatus(id, 'rejected');

      // Create notification for hoster in real-time
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

            // Also update property document with rejection reason for hoster to see
            await _firestore.collection('properties').doc(id).update({
              'rejectionReason': reason,
              'rejectedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (e) {
        debugPrint('Error creating rejection notification: $e');
      }
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
      await updatePropertyStatus(id, PropertyStatus.approved);
    }
  }

  Future<void> updateSuggestionStatus(String id, String status) async {
    // Reverted fallback: All requests must go through backend
    await _apiService
        .updateSuggestionStatus(id, status)
        .timeout(const Duration(seconds: 30));

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

  // ==================== HOSTER DETAIL FETCH ====================

  Future<Map<String, dynamic>> getHosterDashboardSummary(
    String hosterId,
  ) async {
    final HosterService hosterService = HosterService();
    // Re-use the hoster's own logic to get a summary for the admin
    // This ensures consistency between what the hoster sees and what the admin sees
    final stats =
        await hosterService.getDetailedHosterStatsStream(hosterId).first;
    return stats;
  }

  Future<void> deleteListing(String propertyId) async {
    await _firestore.collection('properties').doc(propertyId).delete();
  }

  Future<void> promoteToAdmin(String userId) async {
    await updateUserRole(userId, 'admin');
  }
}
