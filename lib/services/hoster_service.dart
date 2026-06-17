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
        Stream.fromFuture(_isarService.getAdminCache('hoster_stats_$hosterId'))
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

    final leadsStream = Rx.combineLatest2(
      _firestore
          .collection('leads')
          .where('hoster_id', isEqualTo: hosterId)
          .snapshots(),
      _firestore
          .collection('leads')
          .where('hosterId', isEqualTo: hosterId)
          .snapshots(),
      _mergeSnapshots,
    );

    final notificationsStream = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: hosterId)
        .where('isRead', isEqualTo: false)
        .snapshots();

    final userDocStream = _firestore
        .collection('users')
        .doc(hosterId)
        .snapshots();

    final reviewsStream = propertiesStream.switchMap((properties) {
      final propertyIds = properties.map((p) => p.id).toList();
      if (propertyIds.isEmpty) {
        return Stream.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);
      }
      return _firestore
          .collection('reviews')
          .where('property_id', whereIn: propertyIds.take(10).toList())
          .snapshots()
          .map((snap) => snap.docs);
    });

    final firestoreStream = Rx.combineLatest7(
      propertiesStream,
      bookingsStream,
      paymentsStream,
      leadsStream,
      notificationsStream,
      userDocStream,
      reviewsStream,
      (
        List<QueryDocumentSnapshot<Map<String, dynamic>>> properties,
        List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings,
        List<QueryDocumentSnapshot<Map<String, dynamic>>> payments,
        List<QueryDocumentSnapshot<Map<String, dynamic>>> leads,
        QuerySnapshot<Map<String, dynamic>> notifications,
        DocumentSnapshot<Map<String, dynamic>> userDoc,
        List<QueryDocumentSnapshot<Map<String, dynamic>>> reviews,
      ) {
        final userData = userDoc.data() ?? {};
        final hostInfo = userData['info'] as Map<String, dynamic>? ?? {};
        final verif = userData['verification'] as Map? ?? {};

        // Calculate Overview Stats
        int totalCapacity = 0;
        int totalRooms = 0;
        int activeListings = 0;

        for (var doc in properties) {
          final data = doc.data();
          final details = data['propertyDetails'] as Map? ?? {};
          totalCapacity += _parseNum(details['totalCapacity']).toInt();
          totalRooms += _parseNum(details['totalRooms']).toInt();
          if (data['status'] == 'approved' || data['status'] == 'active') {
            activeListings++;
          }
        }

        final activeResidents = bookings.where((doc) {
          final s = doc.data()['status']?.toString().toLowerCase();
          return s == 'confirmed' || s == 'active' || s == 'checkedin';
        }).length;

        final vacantBeds = totalCapacity - activeResidents;
        final occupancy = totalCapacity > 0
            ? (activeResidents / totalCapacity * 100).round()
            : 0;

        // Lead counts
        final newLeadsCount = leads.where((doc) {
          final s = doc.data()['status']?.toString();
          return s == 'newLead' || s == 'pending';
        }).length;

        // Revenue calculations
        double monthlyRevenue = 0;
        final now = DateTime.now();
        for (var doc in payments) {
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
        final pendingCheckins = bookings.where((doc) {
          final data = doc.data();
          final checkinDate = (data['checkinDate'] as Timestamp?)?.toDate();
          return checkinDate != null &&
              checkinDate.year == today.year &&
              checkinDate.month == today.month &&
              checkinDate.day == today.day &&
              data['status'] == 'confirmed';
        }).length;

        final paymentsDue = bookings.where((doc) {
          final data = doc.data();
          return data['paymentStatus'] == 'pending' &&
              data['status'] == 'confirmed';
        }).length;

        final bookingsConfirmedToday = bookings.where((doc) {
          final data = doc.data();
          final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
          return updatedAt != null &&
              updatedAt.year == today.year &&
              updatedAt.month == today.month &&
              updatedAt.day == today.day &&
              data['status'] == 'confirmed';
        }).length;

        // Inquiries
        final newInquiries = bookings
            .where((doc) => doc.data()['status'] == 'pending')
            .length;

        // Calculate profile completion — 12 meaningful fields
        const int totalFields = 12;
        int filledFields = 0;

        final onb = userData['onboardingData'] as Map? ?? {};

        // 1. Name
        if ((hostInfo['name'] ?? onb['name'] ?? '').toString().isNotEmpty) {
          filledFields++;
        }
        // 2. Email present
        if ((hostInfo['email'] ?? userData['email'] ?? onb['email'] ?? '')
            .toString()
            .isNotEmpty) {
          filledFields++;
        }
        // 3. Phone present
        if ((hostInfo['phone'] ?? userData['phone'] ?? onb['phone'] ?? '')
            .toString()
            .isNotEmpty) {
          filledFields++;
        }
        // 4. Profile photo
        if (hostInfo['profileImage'] != null || onb['profileImage'] != null) {
          filledFields++;
        }

        // 5. Email verified (Firebase Auth OR Firestore flag)
        if (userData['emailVerified'] == true ||
            verif['emailVerified'] == true) {
          filledFields++;
        }
        // 6. Phone verified
        if (verif['phoneVerified'] == true) filledFields++;

        // 7. Gov ID uploaded or verified
        if (verif['govIdVerified'] == true ||
            verif['aadhaarVerified'] == true ||
            (verif['govIdFrontUrl'] ?? verif['aadhaarFrontUrl']) != null ||
            (onb['aadhaarFront'] != null)) {
          filledFields++;
        }
        // 8. PAN uploaded or verified
        if (verif['panVerified'] == true ||
            (verif['panFrontUrl'] ?? verif['panUrl']) != null ||
            (onb['panUrl'] != null)) {
          filledFields++;
        }
        // 9. Host preferences set
        if (userData['host_preferences'] != null ||
            (onb['preferredTenants'] != null &&
                (onb['preferredTenants'] as List).isNotEmpty)) {
          filledFields++;
        }

        // 10. Bank info linked
        if (userData['bank_info'] != null || onb['bankAccNo'] != null) {
          filledFields++;
        }

        // 11. Aadhaar/PAN number text present
        if ((verif['aadhaarNumber'] ??
                verif['panNumber'] ??
                onb['aadhaarNumber'] ??
                onb['panNumber']) !=
            null) {
          filledFields++;
        }

        // 12. Emergency contact set
        final emergency = userData['emergency_contact'] as Map?;
        if ((emergency != null &&
                (emergency['name'] ?? emergency['phone']) != null) ||
            (onb['emergencyName'] ?? onb['emergencyPhone']) != null) {
          filledFields++;
        }

        final completion = filledFields / totalFields;

        // Calculate trust score dynamically
        final isHosterVerified =
            (userData['role'] == 'hoster') ||
            (userData['onboardingStatus'] == 'approved') ||
            (userData['accountStatus'] == 'active') ||
            (userData['status'] == 'approved') ||
            (userData['permissions'] is Map &&
                userData['permissions']['status'] == 'approved');
        final isEmailVerified =
            userData['emailVerified'] == true || verif['emailVerified'] == true;
        final isPhoneVerified = verif['phoneVerified'] == true;
        final isIdentityVerified = verif['govIdVerified'] == true;
        final isBankLinked =
            userData['bank_info'] != null || onb['bankAccNo'] != null;

        int trustScore = 0;
        if (isHosterVerified) trustScore += 30;
        if (isIdentityVerified) trustScore += 25;
        if (isBankLinked) trustScore += 20;
        if (isPhoneVerified) trustScore += 15;
        if (isEmailVerified) trustScore += 10;

        // Calculate Rating & Reviews dynamically
        int reviewCount = reviews.length;
        double averageRating = 0.0;
        if (reviewCount > 0) {
          double totalRating = 0.0;
          for (var doc in reviews) {
            final data = doc.data();
            totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
          }
          averageRating = totalRating / reviewCount;
        } else {
          averageRating = (userData['rating'] as num?)?.toDouble() ?? 0.0;
          reviewCount = (userData['reviewCount'] as num?)?.toInt() ?? 0;
        }

        // Revenue Chart Data
        final chartData = _generateRevenueChartData(payments);

        final stats = {
          'hosterName': hostInfo['name'] ?? onb['name'] ?? 'Host',
          'hosterRole':
              userData['hosterRole'] ?? onb['role'] ?? 'Partner Hoster',
          'experience':
              userData['experience'] ??
              onb['experience'] ??
              hostInfo['experience'] ??
              '3-5 Years',
          'profileImage': hostInfo['profileImage'] ?? onb['profileImage'],
          'totalCapacity': totalCapacity,
          'totalRooms': totalRooms,
          'activeListings': activeListings,
          'profileCompletion': completion,
          'trustScore': trustScore,
          'emailVerified': userData['emailVerified'] == true,
          'phoneVerified': verif['phoneVerified'] == true,
          'identityVerified': verif['govIdVerified'] == true,
          'hosterVerified': isHosterVerified,
          'rating': averageRating,
          'reviewCount': reviewCount,
          'reviews': reviews.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['userName'] ?? data['user_name'] ?? 'Guest',
              'comment': data['comment'] ?? data['review'] ?? '',
              'rating': (data['rating'] as num?)?.toDouble() ?? 5.0,
              'time': _formatTimestamp(data['createdAt']),
              'type': 'review',
            };
          }).toList(),
          'occupancy': occupancy,
          'vacantBeds': vacantBeds,
          'activeResidents': activeResidents,
          'monthlyRevenue': monthlyRevenue,
          'newInquiries': newInquiries,
          'newLeadsCount': newLeadsCount,
          'unreadNotificationsCount': notifications.docs.length,
          'pendingCheckins': pendingCheckins,
          'paymentsDue': paymentsDue,
          'bookingsConfirmed': bookingsConfirmedToday,
          'chartData': chartData,
          'totalProperties': properties.length,
          'properties': properties
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
          'recentActivity': _generateRecentActivity(bookings, payments),

          // ── Extra profile fields for menu subtitles ──────────────
          'email': hostInfo['email'] ?? userData['email'] ?? onb['email'] ?? '',
          'phone': hostInfo['phone'] ?? userData['phone'] ?? onb['phone'] ?? '',
          'gender': hostInfo['gender'] ?? onb['gender'] ?? '',
          'dob': hostInfo['dob'] ?? onb['dob'] ?? '',

          // Contact verification (strict)
          'emailVerifiedFlag':
              userData['emailVerified'] == true ||
              verif['emailVerified'] == true,
          'phoneVerifiedFlag': verif['phoneVerified'] == true,

          // KYC / Identity — separate verified vs uploaded
          'aadhaarVerified':
              verif['govIdVerified'] == true ||
              verif['aadhaarVerified'] == true,
          'panVerified': verif['panVerified'] == true,
          'aadhaarUrl':
              verif['govIdFrontUrl'] ??
              verif['aadhaarFrontUrl'] ??
              onb['aadhaarFront'],
          'panUrl': verif['panFrontUrl'] ?? verif['panUrl'] ?? onb['panUrl'],

          // Business & Property proof
          'businessProofVerified': verif['businessProofVerified'] == true,
          'businessProofUrl':
              verif['businessProofFrontUrl'] ?? verif['businessProofUrl'],
          'propertyProofVerified': verif['propertyProofVerified'] == true,
          'propertyProofUrl':
              verif['propertyProofFrontUrl'] ?? verif['propertyProofUrl'],

          // Bank / Payout
          'bankName':
              (userData['bank_info'] as Map?)?['bankName'] ??
              onb['bankName'] ??
              '',
          'bankAccountNo':
              (userData['bank_info'] as Map?)?['accountNumber'] ??
              onb['bankAccNo'] ??
              '',
          'bankIfsc':
              (userData['bank_info'] as Map?)?['ifsc'] ?? onb['bankIfsc'] ?? '',
          'bankVerified': (userData['bank_info'] as Map?)?['verified'] == true,
          'upiVerified':
              (userData['bank_info'] as Map?)?['upiVerified'] == true,
          'hasBankInfo':
              userData['bank_info'] != null || (onb['bankAccNo'] != null),

          // Host preferences
          'prefBookingType':
              (userData['host_preferences'] as Map?)?['bookingType'] ?? '',
          'prefTenants':
              (userData['host_preferences'] as Map?)?['preferredTenants'] ??
              onb['preferredTenants'] ??
              [],
          'prefGender':
              (userData['host_preferences'] as Map?)?['preferredGender'] ??
              onb['preferredGender'] ??
              '',
          'prefDuration':
              (userData['host_preferences'] as Map?)?['preferredDuration'] ??
              '',

          // Emergency contact
          'emergencyContactName':
              (userData['emergency_contact'] as Map?)?['name'] ??
              onb['emergencyName'] ??
              '',
          'emergencyContactPhone':
              (userData['emergency_contact'] as Map?)?['phone'] ??
              onb['emergencyPhone'] ??
              '',

          // Address
          'address': hostInfo['address'] ?? onb['address1'] ?? '',
          'city': hostInfo['city'] ?? onb['city'] ?? '',
          'state': onb['state'] ?? '',

          // Rejection info
          'accountStatus':
              userData['accountStatus'] ??
              userData['status'] ??
              (userData['permissions'] as Map?)?['status'] ??
              'pending',
          'adminReviewNote': userData['adminReviewNote'] ?? '',
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
    if (payments.isEmpty) return [0, 0, 0, 0, 0, 0, 0];
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

  Stream<Map<String, dynamic>> getUserProfileStream(String? userId) {
    return getUserProfileStreamNew(userId);
  }

  Stream<Map<String, dynamic>> getUserProfileStreamNew(String? userId) {
    if (userId == null || userId.trim().isEmpty) {
      return Stream.value({});
    }

    // 1. Initial cached emission
    final cachedStream =
        Stream.fromFuture(_isarService.getAdminCache('user_profile_$userId'))
            .where((c) => c != null)
            .map((c) => json.decode(c!) as Map<String, dynamic>);

    // 2. Real-time Firestore stream
    final firestoreStream = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data != null) {
            final sanitized = _sanitize(data);
            _isarService.saveAdminCache(
              'user_profile_$userId',
              json.encode(sanitized),
            );
            return sanitized as Map<String, dynamic>;
          }
          return <String, dynamic>{};
        });

    return Rx.concat([cachedStream, firestoreStream]).asBroadcastStream();
  }
}
