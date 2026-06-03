import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:rxdart/rxdart.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:intl/intl.dart';

class HosterService {
  final FirebaseFirestore _firestore;
  final IsarService _isarService;

  HosterService({FirebaseFirestore? firestore, IsarService? isarService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _isarService = isarService ?? IsarService();

  // Helper to recursively sanitize data for JSON encoding
  dynamic _sanitize(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    if (value is List) return value.map(_sanitize).toList();
    return value;
  }

  Future<Map<String, dynamic>> getHosterStats(String hosterId) async {
    final properties =
        await _firestore
            .collection('properties')
            .where('hoster_id', isEqualTo: hosterId)
            .get();

    final bookings =
        await _firestore
            .collection('bookings')
            .where('hoster_id', isEqualTo: hosterId)
            .get();

    final payments =
        await _firestore
            .collection('payments')
            .where('hoster_id', isEqualTo: hosterId)
            .get();

    double totalEarnings = 0;
    for (var doc in payments.docs) {
      totalEarnings += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalProperties': properties.docs.length,
      'totalBookings': bookings.docs.length,
      'totalEarnings': totalEarnings,
      'pendingBookings':
          bookings.docs
              .where(
                (doc) =>
                    doc.data()['status'] == BookingStatus.inquiryCreated.name,
              )
              .length,
    };
  }

  Stream<Map<String, dynamic>> getDetailedHosterStatsStream(String hosterId) {
    // 1. Initial cached emission
    final cachedStream = Stream.fromFuture(
          _isarService.getAdminCache('hoster_stats_$hosterId'),
        )
        .where((c) => c != null)
        .map((c) => json.decode(c!) as Map<String, dynamic>);

    // 2. Real-time Firestore aggregation
    final firestoreStream = Rx.combineLatest4(
      _firestore
          .collection('properties')
          .where('hoster_id', isEqualTo: hosterId)
          .snapshots(),
      _firestore
          .collection('bookings')
          .where('hoster_id', isEqualTo: hosterId)
          .snapshots(),
      _firestore
          .collection('payments')
          .where('hoster_id', isEqualTo: hosterId)
          .snapshots(),
      _firestore.collection('users').doc(hosterId).snapshots(),
      (properties, bookings, payments, userDoc) {
        final userData = userDoc.data() ?? {};
        final hostInfo = userData['info'] as Map<String, dynamic>? ?? {};
        final verif = userData['verification'] as Map? ?? {};

        // Calculate Overview Stats
        int totalCapacity = 0;
        int totalRooms = 0;
        int activeListings = 0;

        for (var doc in properties.docs) {
          final data = doc.data();
          final details = data['propertyDetails'] as Map? ?? {};
          totalCapacity += (details['totalCapacity'] as num?)?.toInt() ?? 0;
          totalRooms += (details['totalRooms'] as num?)?.toInt() ?? 0;
          if (data['status'] == 'approved' || data['status'] == 'active') {
            activeListings++;
          }
        }

        final activeResidents =
            bookings.docs.where((doc) {
              final s = doc.data()['status']?.toString().toLowerCase();
              return s == 'confirmed' || s == 'active' || s == 'checkedin';
            }).length;

        final vacantBeds = totalCapacity - activeResidents;
        final occupancy =
            totalCapacity > 0
                ? (activeResidents / totalCapacity * 100).round()
                : 0;

        // Revenue calculations
        double monthlyRevenue = 0;
        final now = DateTime.now();
        for (var doc in payments.docs) {
          final data = doc.data();
          final timestamp = data['createdAt'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            if (date.month == now.month && date.year == now.year) {
              monthlyRevenue += (data['amount'] as num?)?.toDouble() ?? 0;
            }
          }
        }

        // Today's Actions
        final today = DateTime(now.year, now.month, now.day);
        final pendingCheckins =
            bookings.docs.where((doc) {
              final data = doc.data();
              final checkinDate = (data['checkinDate'] as Timestamp?)?.toDate();
              return checkinDate != null &&
                  checkinDate.year == today.year &&
                  checkinDate.month == today.month &&
                  checkinDate.day == today.day &&
                  data['status'] == 'confirmed';
            }).length;

        final paymentsDue =
            bookings.docs.where((doc) {
              final data = doc.data();
              return data['paymentStatus'] == 'pending' &&
                  data['status'] == 'confirmed';
            }).length;

        final bookingsConfirmedToday =
            bookings.docs.where((doc) {
              final data = doc.data();
              final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
              return updatedAt != null &&
                  updatedAt.year == today.year &&
                  updatedAt.month == today.month &&
                  updatedAt.day == today.day &&
                  data['status'] == 'confirmed';
            }).length;

        // Inquiries
        final newInquiries =
            bookings.docs
                .where((doc) => doc.data()['status'] == 'pending')
                .length;

        // Calculate profile completion
        int totalFields = 8;
        int filledFields = 0;
        if (hostInfo['name'] != null && hostInfo['name'].toString().isNotEmpty)
          filledFields++;
        if (hostInfo['email'] != null &&
            hostInfo['email'].toString().isNotEmpty)
          filledFields++;
        if (hostInfo['phone'] != null &&
            hostInfo['phone'].toString().isNotEmpty)
          filledFields++;
        if (hostInfo['profileImage'] != null) filledFields++;
        if (userData['host_preferences'] != null) filledFields++;
        if (verif['govIdVerified'] == true) filledFields++;
        if (verif['panVerified'] == true) filledFields++;
        if (userData['bank_info'] != null) filledFields++;

        final completion = totalFields > 0 ? (filledFields / totalFields) : 0.0;

        // Revenue Chart Data
        final chartData = _generateRevenueChartData(payments.docs);

        final stats = {
          'hosterName': hostInfo['name'] ?? 'Jibin',
          'hosterRole': userData['hosterRole'] ?? 'Host & Property Manager',
          'profileImage': hostInfo['profileImage'],
          'totalCapacity': totalCapacity,
          'totalRooms': totalRooms,
          'activeListings': activeListings,
          'profileCompletion': completion,
          'emailVerified': userData['emailVerified'] == true,
          'phoneVerified': verif['phoneVerified'] == true,
          'identityVerified': verif['govIdVerified'] == true,
          'hosterVerified':
              (userData['permissions'] is Map &&
                  userData['permissions']['status'] == 'approved') ||
              (userData['status'] == 'approved'),
          'rating': userData['rating'] ?? 4.7,
          'reviewCount': userData['reviewCount'] ?? 128,
          'occupancy': occupancy,
          'vacantBeds': vacantBeds,
          'activeResidents': activeResidents,
          'monthlyRevenue': monthlyRevenue,
          'newInquiries': newInquiries,
          'pendingCheckins': pendingCheckins,
          'paymentsDue': paymentsDue,
          'bookingsConfirmed': bookingsConfirmedToday,
          'chartData': chartData,
          'totalProperties': properties.docs.length,
          'properties':
              properties.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
          'recentActivity': _generateRecentActivity(
            bookings.docs,
            payments.docs,
          ),
        };

        // Cache the sanitized result
        _isarService.saveAdminCache(
          'hoster_stats_$hosterId',
          json.encode(_sanitize(stats)),
        );

        return stats;
      },
    );

    return Rx.concat([cachedStream, firestoreStream]).asBroadcastStream();
  }

  List<double> _generateRevenueChartData(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> payments,
  ) {
    return [40, 60, 45, 80, 50, 70, 95];
  }

  List<Map<String, dynamic>> _generateRecentActivity(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> payments,
  ) {
    final List<Map<String, dynamic>> activities = [];

    for (var doc in bookings.take(5)) {
      final data = doc.data();
      activities.add({
        'title':
            '${data['studentName'] ?? "Guest"} booked ${data['roomType'] ?? "Room"} in ${data['propertyName'] ?? "Property"}',
        'time': _formatTimestamp(data['createdAt']),
        'type': 'booking',
      });
    }

    for (var doc in payments.take(5)) {
      final data = doc.data();
      activities.add({
        'title':
            'Payment received ₹${data['amount']} from ${data['userName'] ?? "User"}',
        'time': _formatTimestamp(data['createdAt']),
        'type': 'payment',
      });
    }

    activities.sort((a, b) => b['time'].compareTo(a['time']));
    return activities.take(5).toList();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('hh:mm a').format(timestamp.toDate());
    }
    return 'Just now';
  }

  Stream<Map<String, dynamic>> getHosterProfileStatsStream(String hosterId) {
    return getDetailedHosterStatsStream(hosterId);
  }

  Stream<Map<String, dynamic>> getUserProfileStream(String userId) {
    // 1. Initial cached emission
    final cachedStream = Stream.fromFuture(
          _isarService.getAdminCache('user_profile_$userId'),
        )
        .where((c) => c != null)
        .map((c) => json.decode(c!) as Map<String, dynamic>);

    // 2. Real-time Firestore stream
    final firestoreStream = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          final data = doc.data() ?? {};
          final sanitized = _sanitize(data);
          _isarService.saveAdminCache(
            'user_profile_$userId',
            json.encode(sanitized),
          );
          return sanitized as Map<String, dynamic>;
        });

    return Rx.concat([cachedStream, firestoreStream]).asBroadcastStream();
  }
}
