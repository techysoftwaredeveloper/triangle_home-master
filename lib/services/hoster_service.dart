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
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is List) return value.map(_sanitize).toList();
    return value;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _mergeSnapshots(
    QuerySnapshot<Map<String, dynamic>> a,
    QuerySnapshot<Map<String, dynamic>> b,
  ) {
    final seen = <String>{};
    final merged = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in [...a.docs, ...b.docs]) {
      if (seen.add(doc.id)) {
        merged.add(doc);
      }
    }
    return merged;
  }

  Future<Map<String, dynamic>> getHosterStats(String hosterId) async {
    final propertiesSnake = await _firestore
        .collection('properties')
        .where('hoster_id', isEqualTo: hosterId)
        .get();
    final propertiesCamel = await _firestore
        .collection('properties')
        .where('hosterId', isEqualTo: hosterId)
        .get();
    final properties = _mergeSnapshots(propertiesSnake, propertiesCamel);

    final bookingsSnake = await _firestore
        .collection('bookings')
        .where('hoster_id', isEqualTo: hosterId)
        .get();
    final bookingsCamel = await _firestore
        .collection('bookings')
        .where('hosterId', isEqualTo: hosterId)
        .get();
    final bookings = _mergeSnapshots(bookingsSnake, bookingsCamel);

    final paymentsSnake = await _firestore
        .collection('payments')
        .where('hoster_id', isEqualTo: hosterId)
        .get();
    final paymentsCamel = await _firestore
        .collection('payments')
        .where('hosterId', isEqualTo: hosterId)
        .get();
    final payments = _mergeSnapshots(paymentsSnake, paymentsCamel);

    double totalEarnings = 0;
    for (var doc in payments) {
      totalEarnings += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalProperties': properties.length,
      'totalBookings': bookings.length,
      'totalEarnings': totalEarnings,
      'pendingBookings': bookings
          .where(
            (doc) => doc.data()['status'] == BookingStatus.inquiryCreated.name,
          )
          .length,
    };
  }

  num _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  Stream<Map<String, dynamic>> getDetailedHosterStatsStream(String hosterId) {
    // 1. Initial cached emission
    final cachedStream =
        Stream.fromFuture(_isarService.getCachedData('hoster_stats_$hosterId'))
            .where((c) => c != null)
            .map((c) => json.decode(c!) as Map<String, dynamic>);

    // 2. Real-time Firestore aggregation queries for both hosterId and hoster_id
    final propertiesStream = Rx.combineLatest2(
      _firestore
          .collection('properties')
          .where('hoster_id', isEqualTo: hosterId)
          .snapshots(),
      _firestore
          .collection('properties')
          .where('hosterId', isEqualTo: hosterId)
          .snapshots(),
      _mergeSnapshots,
    ).asBroadcastStream();

    final bookingsStream = Rx.combineLatest2(
      _firestore
          .collection('bookings')
          .where('hoster_id', isEqualTo: hosterId)
          .snapshots(),
      _firestore
          .collection('bookings')
          .where('hosterId', isEqualTo: hosterId)
          .snapshots(),
      _mergeSnapshots,
    );

    final paymentsStream = Rx.combineLatest2(
      _firestore
          .collection('payments')
          .where('hoster_id', isEqualTo: hosterId)
          .snapshots(),
      _firestore
          .collection('payments')
          .where('hosterId', isEqualTo: hosterId)
          .snapshots(),
      _mergeSnapshots,
    );

    final userStream = _firestore.collection('users').doc(hosterId).snapshots();

    final remoteStream = Rx.combineLatest4(
      propertiesStream,
      bookingsStream,
      paymentsStream,
      userStream,
      (properties, bookings, payments, userDoc) {
        int totalBeds = 0;
        int occupiedBeds = 0;
        int activeProperties = 0;
        int totalRooms = 0;

        for (var doc in properties) {
          final data = doc.data();
          final status = (data['status'] ?? '').toString().toLowerCase();
          if (status == 'active' || status == 'approved') {
            activeProperties++;
          }
          totalBeds += _parseNum(data['totalBeds'] ?? data['capacity']).toInt();
          occupiedBeds += _parseNum(data['occupiedBeds']).toInt();
          totalRooms += _parseNum(data['rooms'] ?? data['totalRooms']).toInt();
        }

        double earnings = 0;
        for (var doc in payments) {
          earnings += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        }

        final userData = userDoc.data() ?? {};
        final info = userData['info'] as Map? ?? {};
        final verif = userData['verification'] as Map? ?? {};
        final onboardingStatus = (userData['onboardingStatus'] ?? '').toString();
        final status = (userData['status'] ?? '').toString();
        final accountStatus = (userData['accountStatus'] ?? '').toString();

        final Map<String, dynamic> stats = {
          'totalProperties': properties.length,
          'properties': properties.map((p) => {'id': p.id, ...p.data()}).toList(),
          'activeProperties': activeProperties,
          'totalBookings': bookings.length,
          'totalEarnings': earnings,
          'totalBeds': totalBeds,
          'occupiedBeds': occupiedBeds,
          'totalRooms': totalRooms,
          'activeListings': activeProperties,
          'vacantBeds': totalBeds - occupiedBeds,
          'occupancy': totalBeds > 0 ? (occupiedBeds / totalBeds * 100).round() : 0,
          'occupancyRate': totalBeds > 0 ? (occupiedBeds / totalBeds * 100).round() : 0,
          'pendingBookings': bookings
              .where((doc) => doc.data()['status'] == 'pending')
              .length,
          
          // Profile Fields
          'hosterName': info['name'] ?? 'Host',
          'profileImage': info['profileImage'],
          'hosterRole': _formatRole(userData['role'] ?? ''),
          'rating': _parseNum(userData['rating']).toDouble() == 0 ? 4.5 : _parseNum(userData['rating']).toDouble(),
          'reviewCount': _parseNum(userData['reviewCount']).toInt(),
          'hosterVerified': onboardingStatus == 'approved' || status == 'approved' || accountStatus == 'active',
          'emailVerified': userData['emailVerified'] == true,
          'phoneVerified': verif['phoneVerified'] == true,
          'identityVerified': verif['roleIdVerified'] == true || verif['govIdVerified'] == true,
          'accountStatus': accountStatus.isNotEmpty ? accountStatus : (status.isNotEmpty ? status : 'pending'),
          'onboardingStatus': onboardingStatus,
          'profileCompletion': _calculateCompletion(userData),
          'email': info['email'] ?? '',
          'phone': info['phone'] ?? info['phoneNumber'] ?? '',
          'trustScore': _parseNum(userData['trustScore']).toInt() == 0 ? 85 : _parseNum(userData['trustScore']).toInt(),
        };

        // Background cache update
        _isarService.cacheData(
          'hoster_stats_$hosterId',
          json.encode(_sanitize(stats)),
          ttl: const Duration(hours: 4),
        );

        return stats;
      },
    );

    return Rx.concat([cachedStream, remoteStream]);
  }

  String _formatRole(dynamic role) {
    final r = role?.toString().toLowerCase() ?? 'hoster';
    if (r == 'owner') return 'Property Owner';
    if (r == 'manager') return 'Property Manager';
    if (r == 'agency') return 'Agency Partner';
    return 'Individual Owner';
  }

  double _calculateCompletion(Map<String, dynamic> userData) {
    int score = 0;
    final info = userData['info'] as Map? ?? {};
    final verif = userData['verification'] as Map? ?? {};
    
    if (info['name'] != null) score += 10;
    if (info['profileImage'] != null) score += 10;
    if (userData['emailVerified'] == true) score += 15;
    if (verif['phoneVerified'] == true) score += 15;
    if (verif['roleIdVerified'] == true) score += 20;
    if (verif['govIdVerified'] == true) score += 20;
    if (userData['bankName'] != null) score += 10;
    
    return (score / 100).clamp(0.0, 1.0);
  }

  Stream<Map<String, dynamic>> getUserProfileStream(String userId) {
    // 1. Immediate cache
    final cached = Stream.fromFuture(_isarService.getCachedData('user_profile_$userId'))
        .where((c) => c != null)
        .map((c) => json.decode(c!) as Map<String, dynamic>);

    final remote = _firestore.collection('users').doc(userId).snapshots().map((snap) {
      final data = snap.data() ?? {};
      _isarService.cacheData(
        'user_profile_$userId',
        json.encode(_sanitize(data)),
        ttl: const Duration(days: 1),
      );
      return data;
    });

    return Rx.concat([cached, remote]);
  }

  /// Alias for backward compatibility with newer code using the "New" suffix
  Stream<Map<String, dynamic>> getUserProfileStreamNew(String userId) => 
      getUserProfileStream(userId);

  /// Alias for profile-specific stats stream
  Stream<Map<String, dynamic>> getHosterProfileStatsStream(String hosterId) =>
      getDetailedHosterStatsStream(hosterId);
}
