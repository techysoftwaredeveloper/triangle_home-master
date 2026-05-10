import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== IMAGE UPLOAD ====================

  Future<String> uploadImage(File image) async {
    final String fileName = '${const Uuid().v4()}.jpg';
    final Reference ref = _storage.ref().child('property_images/$fileName');
    final UploadTask uploadTask = ref.putFile(image);
    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<List<String>> uploadImages(List<File> images) async {
    final List<String> imageUrls = [];
    for (final image in images) {
      final url = await uploadImage(image);
      imageUrls.add(url);
    }
    return imageUrls;
  }

  // ==================== PROPERTIES ====================

  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedProperties({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.get();
  }

  Future<void> createPropertyListing({
    required String title,
    required String description,
    required String type,
    required double price,
    required List<File> images,
    required String address,
    required double latitude,
    required double longitude,
    required int bedrooms,
    required int bathrooms,
    required List<String> amenities,
    required DateTime availableFrom,
  }) async {
    try {
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) throw 'User not authenticated';

      final List<String> imageUrls = await uploadImages(images);

      await _firestore.collection('properties').add({
        'ownerId': userId,
        'title': title,
        'description': description,
        'type': type,
        'price': price,
        'images': imageUrls,
        'address': address,
        'location': GeoPoint(latitude, longitude),
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'amenities': amenities,
        'availableFrom': Timestamp.fromDate(availableFrom),
        'rating': 0.0,
        'reviewCount': 0,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== WISHLIST ====================

  String? get _userPhone => _auth.currentUser?.phoneNumber;

  /// Get user's wishlist
  Stream<QuerySnapshot<Map<String, dynamic>>> getWishlist() {
    if (_userPhone == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('wishlists')
        .where('userPhone', isEqualTo: _userPhone)
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  /// Add property to wishlist
  Future<void> addToWishlist({
    required String propertyId,
    required Map<String, dynamic> propertyData,
  }) async {
    if (_userPhone == null) throw 'User not authenticated';

    // Check if already in wishlist
    final existing =
        await _firestore
            .collection('wishlists')
            .where('userPhone', isEqualTo: _userPhone)
            .where('propertyId', isEqualTo: propertyId)
            .get();

    if (existing.docs.isNotEmpty) return; // Already in wishlist

    await _firestore.collection('wishlists').add({
      'userPhone': _userPhone,
      'propertyId': propertyId,
      'propertyData': propertyData,
      'addedAt': Timestamp.now(),
    });
  }

  /// Remove from wishlist
  Future<void> removeFromWishlist(String wishlistId) async {
    await _firestore.collection('wishlists').doc(wishlistId).delete();
  }

  /// Remove from wishlist by property ID
  Future<void> removeFromWishlistByPropertyId(String propertyId) async {
    if (_userPhone == null) return;

    final snapshot =
        await _firestore
            .collection('wishlists')
            .where('userPhone', isEqualTo: _userPhone)
            .where('propertyId', isEqualTo: propertyId)
            .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Check if property is in wishlist
  Future<bool> isInWishlist(String propertyId) async {
    if (_userPhone == null) return false;

    final snapshot =
        await _firestore
            .collection('wishlists')
            .where('userPhone', isEqualTo: _userPhone)
            .where('propertyId', isEqualTo: propertyId)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  // ==================== BOOKINGS ====================

  /// Get user's bookings stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getBookings() {
    if (_userPhone == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('bookings')
        .where('userPhone', isEqualTo: _userPhone)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get bookings by status
  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingsByStatus(
    String status,
  ) {
    if (_userPhone == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('bookings')
        .where('userPhone', isEqualTo: _userPhone)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Create a new booking
  Future<String> createBooking({
    required String propertyId,
    required Map<String, dynamic> propertyData,
    required double price,
    required String type,
    required List<Map<String, String>> tenantDetails,
  }) async {
    if (_userPhone == null) throw 'User not authenticated';

    final docRef = await _firestore.collection('bookings').add({
      'userPhone': _userPhone,
      'propertyId': propertyId,
      'propertyData': propertyData,
      'price': price,
      'type': type,
      'tenantDetails': tenantDetails,
      'status': 'pending',
      'paymentStatus': 'pending',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    return docRef.id;
  }

  /// Update booking status
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? paymentStatus,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': Timestamp.now(),
    };

    if (paymentStatus != null) {
      data['paymentStatus'] = paymentStatus;
    }

    await _firestore.collection('bookings').doc(bookingId).update(data);
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(
      bookingId: bookingId,
      status: 'cancelled',
      paymentStatus: 'refunded',
    );
  }

  // ==================== SEARCH ====================

  /// Get all unique cities from properties
  Future<List<String>> getCities() async {
    final snapshot = await _firestore.collection('properties').get();
    final cities = <String>{};
    for (final doc in snapshot.docs) {
      final city = doc.data()['city'] as String?;
      if (city != null && city.isNotEmpty) {
        cities.add(city);
      }
    }
    return cities.toList()..sort();
  }

  /// Get localities for a city
  Future<List<String>> getLocalities(String city) async {
    final snapshot =
        await _firestore
            .collection('properties')
            .where('city', isEqualTo: city)
            .get();
    final localities = <String>{};
    for (final doc in snapshot.docs) {
      final locality = doc.data()['locality'] as String?;
      if (locality != null && locality.isNotEmpty) {
        localities.add(locality);
      }
    }
    return localities.toList()..sort();
  }

  /// Get all unique colleges from properties
  Future<List<String>> getColleges() async {
    final snapshot = await _firestore.collection('properties').get();
    final colleges = <String>{};
    for (final doc in snapshot.docs) {
      final basicInfo = doc.data()['basicInfo'] as Map<String, dynamic>?;
      final college = basicInfo?['collegeName'] as String?;
      if (college != null && college.isNotEmpty) {
        colleges.add(college);
      }
    }
    return colleges.toList()..sort();
  }

  /// Search properties with filters - returns stream for real-time updates
  Stream<QuerySnapshot<Map<String, dynamic>>> searchProperties({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('properties');

    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    return query.snapshots();
  }

  /// Get properties filtered (client-side filtering for complex queries)
  Future<List<Map<String, dynamic>>> getFilteredProperties({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('properties');

    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    final snapshot = await query.get();
    final results = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final basicInfo = data['basicInfo'] as Map<String, dynamic>? ?? {};
      final propertyCity = data['city'] as String? ?? '';
      final locality = data['locality'] as String? ?? '';
      final collegeName = basicInfo['collegeName'] as String? ?? '';
      final propertyTenantType = basicInfo['tenantType'] as String? ?? '';
      final sharing = basicInfo['sharing'] as String? ?? '';

      // College filter
      if (college != null && college.isNotEmpty) {
        if (!collegeName.toLowerCase().contains(college.toLowerCase())) {
          continue;
        }
      }

      // Locality filter (OR condition)
      if (localities != null && localities.isNotEmpty) {
        final localityMatch = localities.any(
          (loc) => locality.toLowerCase().contains(loc.toLowerCase()),
        );
        if (!localityMatch) continue;
      }

      // Accommodation type filter
      if (accommodationType != null && accommodationType.isNotEmpty) {
        final propType = data['propertyType'] as String? ?? '';
        if (accommodationType == 'Paying Guest Hostels') {
          if (!propType.toLowerCase().contains('pg') &&
              !propType.toLowerCase().contains('hostel')) {
            continue;
          }
        } else if (accommodationType == 'Apartments') {
          if (!propType.toLowerCase().contains('apartment') &&
              !propType.toLowerCase().contains('flat')) {
            continue;
          }
        }
      }

      // Tenant type filter
      if (tenantType != null &&
          tenantType.isNotEmpty &&
          tenantType != 'Anyone') {
        if (!propertyTenantType.toLowerCase().contains(
          tenantType.toLowerCase(),
        )) {
          continue;
        }
      }

      // Room type filter
      if (roomType != null && roomType.isNotEmpty && roomType != 'Any') {
        if (!sharing.toLowerCase().contains(roomType.toLowerCase())) {
          continue;
        }
      }

      // Add formatted data
      results.add({
        'id': doc.id,
        ...data,
        'title': basicInfo['collegeName'] ?? data['name'] ?? 'Property',
        'location': '$locality, $propertyCity',
        'price':
            int.tryParse(
              data['monthlyRent']?.toString().replaceAll(',', '') ?? '0',
            ) ??
            0,
        'rating': (data['rating'] as num?)?.toDouble() ?? 4.0,
        'reviewCount': (data['reviewCount'] as num?)?.toInt() ?? 0,
        'image':
            (data['images'] as List?)?.isNotEmpty == true
                ? (data['images'] as List).first
                : 'https://via.placeholder.com/150',
        'amenities':
            (data['features'] as List?)?.map((e) => e.toString()).toList() ??
            [],
        'distance': '2.5 km',
      });
    }

    return results;
  }

  // ==================== TOP HOSTELS ====================

  /// Get top-rated properties/colleges for home screen
  Stream<List<Map<String, dynamic>>> getTopHostels({int limit = 5}) {
    return _firestore
        .collection('properties')
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final basicInfo = data['basicInfo'] as Map<String, dynamic>? ?? {};
            final images = data['images'] as List? ?? [];

            return {
              'id': doc.id,
              'name': basicInfo['collegeName'] ?? data['name'] ?? 'Property',
              'location': '${data['locality'] ?? ''}, ${data['city'] ?? ''}',
              'image': images.isNotEmpty ? images.first : '',
              'rating': (data['rating'] as num?)?.toDouble() ?? 4.0,
              'reviewCount': (data['reviewCount'] as num?)?.toInt() ?? 0,
              ...data,
            };
          }).toList();
        });
  }

  // ==================== PROPERTY DETAILS ====================

  /// Get single property by ID
  Future<Map<String, dynamic>?> getPropertyById(String propertyId) async {
    final doc = await _firestore.collection('properties').doc(propertyId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final basicInfo = data['basicInfo'] as Map<String, dynamic>? ?? {};
    final images = data['images'] as List? ?? [];

    return {
      'id': doc.id,
      ...data,
      'title': basicInfo['collegeName'] ?? data['name'] ?? 'Property',
      'location': '${data['locality'] ?? ''}, ${data['city'] ?? ''}',
      'price':
          int.tryParse(
            data['monthlyRent']?.toString().replaceAll(',', '') ?? '0',
          ) ??
          0,
      'rating': (data['rating'] as num?)?.toDouble() ?? 4.0,
      'reviewCount': (data['reviewCount'] as num?)?.toInt() ?? 0,
      'image': images.isNotEmpty ? images.first : '',
      'images': images.map((e) => e.toString()).toList(),
      'amenities':
          (data['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
      'wardenName': basicInfo['wardenName'] ?? basicInfo['ownerName'] ?? 'N/A',
      'phone': basicInfo['phone'] ?? data['hosterPhoneNumber'] ?? 'N/A',
      'type': basicInfo['sharing'] ?? data['propertyType'] ?? '',
    };
  }

  /// Get property stream for real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> getPropertyStream(
    String propertyId,
  ) {
    return _firestore.collection('properties').doc(propertyId).snapshots();
  }

  // ==================== PAYMENTS ====================

  /// Get user's payment history
  Stream<QuerySnapshot<Map<String, dynamic>>> getPayments() {
    if (_userPhone == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('payments')
        .where('userPhone', isEqualTo: _userPhone)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Create payment record
  Future<String> createPayment({
    required String bookingId,
    required String propertyId,
    required double amount,
    required String paymentMethod,
    required String paymentType,
    String? transactionId,
    String? razorpayPaymentId,
    String? razorpayOrderId,
  }) async {
    if (_userPhone == null) throw 'User not authenticated';

    final docRef = await _firestore.collection('payments').add({
      'userPhone': _userPhone,
      'bookingId': bookingId,
      'propertyId': propertyId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentType': paymentType, // 'rent' or 'deposit'
      'transactionId': transactionId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'status': 'completed',
      'createdAt': Timestamp.now(),
    });

    return docRef.id;
  }

  /// Get payments for a property (for hosters)
  Stream<QuerySnapshot<Map<String, dynamic>>> getPropertyPayments(
    String propertyId,
  ) {
    return _firestore
        .collection('payments')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== RATINGS ====================

  /// Update property rating
  Future<void> updatePropertyRating({
    required String propertyId,
    required double rating,
    String? review,
  }) async {
    if (_userPhone == null) throw 'User not authenticated';

    // Add review
    await _firestore.collection('reviews').add({
      'propertyId': propertyId,
      'userPhone': _userPhone,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.now(),
    });

    // Update property's average rating
    final reviewsSnapshot =
        await _firestore
            .collection('reviews')
            .where('propertyId', isEqualTo: propertyId)
            .get();

    if (reviewsSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      for (final doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      }
      final avgRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore.collection('properties').doc(propertyId).update({
        'rating': double.parse(avgRating.toStringAsFixed(1)),
        'reviewCount': reviewsSnapshot.docs.length,
      });
    }
  }

  // ==================== AMENITIES ====================

  /// Get master list of amenities
  Future<List<String>> getAmenities() async {
    final doc = await _firestore.collection('config').doc('amenities').get();
    if (!doc.exists) {
      return [
        'WiFi',
        'AC',
        'Food',
        'Laundry',
        'Parking',
        'TV',
        'Refrigerator',
        'Washing Machine',
        'Gym',
        'Swimming Pool',
        'Security',
        'CCTV',
        'Power Backup',
        'Water Purifier',
        'Housekeeping',
      ];
    }
    final data = doc.data();
    if (data == null) return [];
    return (data['list'] as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  // ==================== NOTIFICATIONS ====================

  /// Get user's notifications
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications() {
    if (_userPhone == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('notifications')
        .where('userPhone', isEqualTo: _userPhone)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Create notification
  Future<void> createNotification({
    required String userPhone,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    await _firestore.collection('notifications').add({
      'userPhone': userPhone,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  // ==================== USER PROFILE ====================

  /// Get user profile from any collection
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_userPhone == null) return null;

    final collections = ['student', 'hoster', 'guest'];
    for (final collection in collections) {
      final doc = await _firestore.collection(collection).doc(_userPhone).get();
      if (doc.exists) {
        return {'id': doc.id, 'collection': collection, ...?doc.data()};
      }
    }
    return null;
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    if (_userPhone == null) throw 'User not authenticated';

    await _firestore
        .collection(collection)
        .doc(_userPhone)
        .set(data, SetOptions(merge: true));
  }

  /// Upload profile image
  Future<String> uploadProfileImage(File image) async {
    if (_userPhone == null) throw 'User not authenticated';

    final fileName = '$_userPhone.jpg';
    final ref = _storage.ref().child('profile_images/$fileName');
    final uploadTask = ref.putFile(image);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // ==================== ADMIN OPERATIONS ====================

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    if (_userPhone == null) return false;
    final doc = await _firestore.collection('admins').doc(_userPhone).get();
    return doc.exists;
  }

  /// Get stats for admin dashboard
  Future<Map<String, dynamic>> getAdminStats() async {
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
      'totalUsers': students.docs.length + hosters.docs.length,
      'totalRevenue': totalRevenue,
      'pendingProperties': properties.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length,
    };
  }

  /// Get all properties with optional status filter
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPropertiesAdmin({
    String? status,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('properties');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  /// Update property status (Approve/Reject)
  Future<void> updatePropertyStatus(String propertyId, String status) async {
    await _firestore.collection('properties').doc(propertyId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get all users from all roles
  Future<List<Map<String, dynamic>>> getAllUsersAdmin() async {
    final List<Map<String, dynamic>> users = [];

    final students = await _firestore.collection('student').get();
    for (var doc in students.docs) {
      users.add({...doc.data(), 'role': 'student', 'id': doc.id});
    }

    final hosters = await _firestore.collection('hoster').get();
    for (var doc in hosters.docs) {
      users.add({...doc.data(), 'role': 'hoster', 'id': doc.id});
    }

    return users;
  }

  /// Get all bookings for admin
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllBookingsAdmin() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
