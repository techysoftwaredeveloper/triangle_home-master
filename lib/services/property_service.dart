import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/core/errors/failures.dart';
import 'package:triangle_home/models/property_private_details.dart';
import 'package:uuid/uuid.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== IMAGE HANDLING ====================

  Future<String> uploadImage(File image) async {
    try {
      final String fileName = '${const Uuid().v4()}.jpg';
      final Reference ref = _storage.ref().child('property_images/$fileName');
      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw PropertyFailure('Failed to upload image: $e');
    }
  }

  Future<List<String>> uploadImages(List<File> images) async {
    final List<String> imageUrls = [];
    for (final image in images) {
      imageUrls.add(await uploadImage(image));
    }
    return imageUrls;
  }

  // ==================== PROPERTY CRUD ====================

  Future<String> createProperty(Map<String, dynamic> data) async {
    try {
      // 1. Generate Search Terms for efficient Firestore filtering
      final String title = (data['title'] ?? '').toString().toLowerCase();
      final String city = (data['city'] ?? '').toString().toLowerCase();
      final List<String> searchTerms = {
        ...title.split(' '),
        ...city.split(' '),
        data['type']?.toString().toLowerCase() ?? '',
      }.where((t) => t.length > 2).toList();

      // 2. Add Geo-Aware identifiers for multi-city scale
      final String cityId = data['city']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'unknown';
      final String stateId = data['state']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'unknown';

      final docRef = await _firestore.collection('properties').add({
        ...data,
        'search_terms': searchTerms,
        'city_id': cityId,
        'state_id': stateId,
        'status': PropertyStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw PropertyFailure('Failed to create property: $e');
    }
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('properties').doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw PropertyFailure('Failed to update property: $e');
    }
  }

  Future<void> updateStatus(String id, PropertyStatus status) async {
    await updateProperty(id, {'status': status.name});
  }

  // ==================== PRIVATE VAULT ====================

  Future<PropertyPrivateDetails?> getPrivateDetails(String propertyId) async {
    try {
      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('private')
          .doc('details')
          .get();
      
      if (!doc.exists) return null;
      return PropertyPrivateDetails.fromFirestore(propertyId, doc.data()!);
    } catch (e) {
      throw PropertyFailure('Access Denied: Confirmed booking required to view private details.');
    }
  }

  Future<void> savePrivateDetails(String propertyId, PropertyPrivateDetails details) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('private')
          .doc('details')
          .set(details.toFirestore());
    } catch (e) {
      throw PropertyFailure('Failed to save private details: $e');
    }
  }

  // ==================== SEARCH & PAGINATION ====================

  Future<QuerySnapshot<Map<String, dynamic>>> getProperties({
    int limit = 10,
    DocumentSnapshot? startAfter,
    PropertyStatus? status,
    String? city,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('properties')
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }

      query = query.limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      return await query.get();
    } catch (e) {
      throw PropertyFailure('Failed to fetch properties: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredProperties({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('properties');

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      // Add status filter for security
      query = query.where('status', isEqualTo: PropertyStatus.approved.name);

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
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
          'doc': doc, // Store doc for pagination cursor
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
    } catch (e) {
      throw PropertyFailure('Failed to search properties: $e');
    }
  }

  // Real-time stream for hosters
  Stream<QuerySnapshot<Map<String, dynamic>>> getHosterProperties(String hosterId) {
    return _firestore
        .collection('properties')
        .where('hoster_id', isEqualTo: hosterId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== CONFIG & METADATA ====================

  Future<List<String>> getCities() async {
    final snapshot = await _firestore.collection('cities').get();
    return snapshot.docs.map((doc) => doc.id).toList()..sort();
  }

  Future<List<String>> getAmenities() async {
    final doc = await _firestore.collection('config').doc('amenities').get();
    if (!doc.exists) return [];
    final data = doc.data();
    return (data?['list'] as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  // ==================== WISHLIST ====================

  Future<void> addToWishlist({
    required String propertyId,
    required Map<String, dynamic> propertyData,
  }) async {
    final phone = _auth.currentUser?.phoneNumber;
    if (phone == null) throw const PropertyFailure('User not authenticated');

    final existing = await _firestore
        .collection('wishlists')
        .where('userPhone', isEqualTo: phone)
        .where('propertyId', isEqualTo: propertyId)
        .get();

    if (existing.docs.isNotEmpty) return;

    await _firestore.collection('wishlists').add({
      'userPhone': phone,
      'propertyId': propertyId,
      'propertyData': propertyData,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }
}
