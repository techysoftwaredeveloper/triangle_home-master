import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/core/errors/failures.dart';
import 'package:triangle_home/models/property_private_details.dart';
import 'package:uuid/uuid.dart';
import 'package:triangle_home/services/admin_api_service.dart';

class PropertyService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final AdminApiService _apiService = AdminApiService();

  PropertyService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  // ==================== IMAGE HANDLING ====================

  Future<String> uploadImage(File image) async {
    try {
      final String uid = _auth.currentUser?.uid ?? 'unknown';
      final String fileName = '${const Uuid().v4()}.jpg';
      final Reference ref = _storage.ref().child(
        'property_images/$uid/$fileName',
      );
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
      final List<String> searchTerms =
          {
            ...title.split(' '),
            ...city.split(' '),
            data['type']?.toString().toLowerCase() ?? '',
          }.where((t) => t.length > 2).toList();

      // 2. Add Geo-Aware identifiers for multi-city scale
      final String cityName = (data['city'] ?? '').toString().trim();
      final String localityName = (data['locality'] ?? '').toString().trim();

      final String cityId = cityName.toLowerCase().replaceAll(' ', '_');
      final String stateId =
          data['state']?.toString().toLowerCase().replaceAll(' ', '_') ??
          'unknown';

      final docRef = await _firestore.collection('properties').add({
        ...data,
        'search_terms': searchTerms,
        'city_id': cityId,
        'state_id': stateId,
        'city_normalized': cityName.toLowerCase(),
        'locality_normalized': localityName.toLowerCase(),
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

  /// Request a specific management action for a property
  Future<void> requestPropertyAction(String propertyId, PropertyStatus status) async {
    try {
      final result = await _apiService.performRequest(
        method: 'PATCH',
        endpoint: '/properties/$propertyId/status',
        body: {'status': status.name},
      );

      if (result == null || result['success'] != true) {
        throw PropertyFailure(result?['error'] ?? 'Failed to update property status');
      }
    } catch (e) {
      debugPrint('Error updating property status: $e');
      throw PropertyFailure('Failed to request property action: $e');
    }
  }

  // ==================== PRIVATE VAULT ====================

  Future<PropertyPrivateDetails?> getPrivateDetails(String propertyId) async {
    try {
      final doc =
          await _firestore
              .collection('properties')
              .doc(propertyId)
              .collection('private')
              .doc('details')
              .get();

      if (!doc.exists) return null;
      return PropertyPrivateDetails.fromFirestore(propertyId, doc.data()!);
    } catch (e) {
      throw PropertyFailure(
        'Access Denied: Confirmed booking required to view private details.',
      );
    }
  }

  Future<void> savePrivateDetails(
    String propertyId,
    PropertyPrivateDetails details,
  ) async {
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

  /// Get property stats
  Stream<Map<String, dynamic>> getPropertyStats(String propertyId) {
    return _firestore
        .collection('propertyStats')
        .doc(propertyId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  /// Get rooms for a property
  Stream<List<Map<String, dynamic>>> getPropertyRooms(String propertyId) {
    return _firestore
        .collection('rooms')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  /// Get beds for a property
  Stream<List<Map<String, dynamic>>> getPropertyBeds(String propertyId) {
    return _firestore
        .collection('beds')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  /// Get reviews for a property
  Stream<List<Map<String, dynamic>>> getPropertyReviews(String propertyId) {
    return _firestore
        .collection('reviews')
        .where('property_id', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  Future<bool> _isHosterApproved(String? hosterId) async {
    if (hosterId == null || hosterId.trim().isEmpty) return false;
    try {
      final userDoc = await _firestore.collection('users').doc(hosterId.trim()).get();
      if (!userDoc.exists) return false;
      final userData = userDoc.data();
      if (userData == null) return false;
      
      final status = userData['status']?.toString();
      final onboardingStatus = userData['onboardingStatus']?.toString();
      final accountStatus = userData['accountStatus']?.toString();
      final permissions = userData['permissions'];
      final permissionsStatus = (permissions is Map) ? permissions['status']?.toString() : null;

      return status == 'approved' || 
             onboardingStatus == 'approved' || 
             accountStatus == 'active' || 
             permissionsStatus == 'approved';
    } catch (e) {
      debugPrint('Error checking hoster approval for $hosterId: $e');
      return false;
    }
  }

  /// Real-time stream for properties with city and status filters
  Stream<List<Map<String, dynamic>>> getPropertiesStream({
    String? city,
    PropertyStatus status = PropertyStatus.approved,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('properties')
        .where('status', isEqualTo: status.name);

    if (city != null && city.isNotEmpty && city != 'Global') {
      query = query.where(
        'city_normalized',
        isEqualTo: city.toLowerCase().trim(),
      );
    }

    return query.orderBy('createdAt', descending: true).snapshots().asyncMap((
      snapshot,
    ) async {
      final results = <Map<String, dynamic>>[];
      final hosterApprovedCache = <String, bool>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final hosterId = (data['hoster_id'] ?? data['hosterId'] ?? '').toString().trim();

        bool approved = false;
        if (hosterId.isNotEmpty) {
          if (hosterApprovedCache.containsKey(hosterId)) {
            approved = hosterApprovedCache[hosterId]!;
          } else {
            approved = await _isHosterApproved(hosterId);
            hosterApprovedCache[hosterId] = approved;
          }
        }

        if (!approved) continue;

        final basicInfo = data['basicInfo'] as Map<String, dynamic>? ?? {};
        final propertyCity = data['city'] as String? ?? '';
        final locality = data['locality'] as String? ?? '';

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
    });
  }

  /// Real-time stream for filtered properties
  Stream<List<Map<String, dynamic>>> getFilteredPropertiesStream({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
    double? minPrice,
    double? maxPrice,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('properties')
        .where('status', isEqualTo: PropertyStatus.approved.name);

    if (city != null && city.isNotEmpty && city != 'Global') {
      query = query.where(
        'city_normalized',
        isEqualTo: city.toLowerCase().trim(),
      );
    }

    return query.orderBy('createdAt', descending: true).snapshots().asyncMap((
      snapshot,
    ) async {
      final results = <Map<String, dynamic>>[];
      final hosterApprovedCache = <String, bool>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final hosterId = (data['hoster_id'] ?? data['hosterId'] ?? '').toString().trim();

        bool approved = false;
        if (hosterId.isNotEmpty) {
          if (hosterApprovedCache.containsKey(hosterId)) {
            approved = hosterApprovedCache[hosterId]!;
          } else {
            approved = await _isHosterApproved(hosterId);
            hosterApprovedCache[hosterId] = approved;
          }
        }

        if (!approved) continue;

        final basicInfo = data['basicInfo'] as Map<String, dynamic>? ?? {};

        // 1. Price filter
        final price =
            int.tryParse(
              data['monthlyRent']?.toString().replaceAll(',', '') ?? '0',
            ) ??
            0;
        if (minPrice != null && price < minPrice) continue;
        if (maxPrice != null && price > maxPrice) continue;

        final propertyCity = data['city'] as String? ?? '';
        final locality = data['locality'] as String? ?? '';
        final collegeName = basicInfo['collegeName'] as String? ?? 
                            basicInfo['name'] as String? ?? 
                            data['name'] as String? ?? 
                            data['title'] as String? ?? '';
        final propertyTenantType = basicInfo['tenantType'] as String? ?? '';
        final sharing = basicInfo['sharing'] as String? ?? '';

        // 2. College filter
        if (college != null && college.isNotEmpty) {
          if (!collegeName.toLowerCase().contains(college.toLowerCase())) {
            continue;
          }
        }

        // 3. Locality filter (OR condition)
        if (localities != null && localities.isNotEmpty) {
          final localityMatch = localities.any(
            (loc) => locality.toLowerCase().contains(loc.toLowerCase()),
          );
          if (!localityMatch) continue;
        }

        // 4. Accommodation type filter
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

        // 5. Tenant type filter
        if (tenantType != null &&
            tenantType.isNotEmpty &&
            tenantType != 'Anyone') {
          final propertyGender = (data['gender'] as String? ?? 
                                  data['propertyDetails']?['gender'] as String? ?? 
                                  propertyTenantType).toLowerCase().trim();
          
          bool isMatch = false;
          if (propertyGender.isEmpty || propertyGender == 'anyone' || propertyGender == 'unisex') {
            isMatch = true;
          } else {
            final q = tenantType.toLowerCase().trim();
            if (q == 'man' || q == 'men' || q == 'boys' || q == 'boy') {
              isMatch = propertyGender == 'men' || 
                        propertyGender == 'boys' || 
                        propertyGender.contains('man') || 
                        propertyGender.contains('men') || 
                        propertyGender.contains('boy');
            } else if (q == 'woman' || q == 'women' || q == 'girls' || q == 'girl') {
              isMatch = propertyGender == 'women' || 
                        propertyGender == 'girls' || 
                        propertyGender.contains('woman') || 
                        propertyGender.contains('women') || 
                        propertyGender.contains('girl');
            } else {
              isMatch = propertyGender.contains(q) || q.contains(propertyGender);
            }
          }
          if (!isMatch) continue;
        }

        // 6. Room type filter
        if (roomType != null && roomType.isNotEmpty && roomType != 'Any') {
          final propType = data['propertyType'] as String? ?? '';
          final isApartment = (accommodationType == 'Apartments') ||
                              propType.toLowerCase().contains('apartment') ||
                              propType.toLowerCase().contains('flat');
          if (isApartment) {
            final bhkDetails = data['bhkDetails'] as Map<String, dynamic>?;
            final pricingInfo = data['pricingInfo'] as Map<String, dynamic>?;
            final areaInfo = data['areaInfo'] as Map<String, dynamic>?;

            final normalizedRoomType = roomType.trim().toLowerCase();
            final is4Plus = normalizedRoomType.contains('4+') || normalizedRoomType.contains('4+ bhk');

            bool matchKey(String k) {
              final keyNorm = k.toLowerCase().trim();
              if (is4Plus) {
                final match = RegExp(r'(\d+)\s*bhk').firstMatch(keyNorm);
                if (match != null) {
                  final numVal = int.tryParse(match.group(1) ?? '');
                  if (numVal != null && numVal >= 4) return true;
                }
                return keyNorm.contains('4+') || keyNorm.contains('5') || keyNorm.contains('6');
              }
              return keyNorm == normalizedRoomType;
            }

            bool hasBhk = false;
            if (bhkDetails != null) {
              hasBhk = bhkDetails.keys.any(matchKey);
            }
            if (!hasBhk && pricingInfo != null) {
              hasBhk = pricingInfo.keys.any(matchKey);
            }
            if (!hasBhk && areaInfo != null) {
              hasBhk = areaInfo.keys.any(matchKey);
            }

            if (!hasBhk) continue;
          } else {
            if (!sharing.toLowerCase().contains(roomType.toLowerCase())) {
              continue;
            }
          }
        }

        // Add formatted data
        results.add({
          'id': doc.id,
          ...data,
          'title': basicInfo['collegeName'] ?? data['name'] ?? 'Property',
          'location': '$locality, $propertyCity',
          'price': price,
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
    });
  }

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
        query = query.where(
          'city_normalized',
          isEqualTo: city.toLowerCase().trim(),
        );
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

  /// Fetches personalized property recommendations from the Node.js backend
  Future<List<Map<String, dynamic>>> getRecommendedProperties() async {
    try {
      final result = await _apiService.performRequest(
        method: 'GET',
        endpoint: '/recommendations',
      );

      if (result != null && result['success'] == true) {
        return List<Map<String, dynamic>>.from(result['results']);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Recommendations API Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredProperties({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        if (city != null) 'city': city,
        if (localities != null && localities.isNotEmpty)
          'localities': localities.join(','),
        if (college != null) 'college': college,
        if (accommodationType != null) 'accommodationType': accommodationType,
        if (tenantType != null) 'tenantType': tenantType,
        if (roomType != null) 'roomType': roomType,
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final queryString = Uri(queryParameters: queryParams).query;
      final finalEndpoint = '/search/properties?$queryString';

      final result = await _apiService.performRequest(
        method: 'GET',
        endpoint: finalEndpoint,
      );

      if (result != null && result['success'] == true) {
        return List<Map<String, dynamic>>.from(result['results']);
      } else {
        throw PropertyFailure(result?['error'] ?? 'Search failed');
      }
    } catch (e) {
      debugPrint('Search API Error: $e');
      throw PropertyFailure('Failed to search properties: $e');
    }
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getHosterProperties(
    String hosterId,
  ) {
    final snake =
        _firestore
            .collection('properties')
            .where('hoster_id', isEqualTo: hosterId)
            .snapshots();
    final camel =
        _firestore
            .collection('properties')
            .where('hosterId', isEqualTo: hosterId)
            .snapshots();

    return Rx.combineLatest2(snake, camel, (a, b) {
      final seen = <String>{};
      final merged = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in [...a.docs, ...b.docs]) {
        if (seen.add(doc.id)) {
          merged.add(doc);
        }
      }
      merged.sort((x, y) {
        final xTime = x.data()['createdAt'] as Timestamp?;
        final yTime = y.data()['createdAt'] as Timestamp?;
        if (xTime == null || yTime == null) return 0;
        return yTime.compareTo(xTime);
      });
      return merged;
    });
  }

  // ==================== CONFIG & METADATA ====================

  /// Fetches a centralized list of major cities from the Node.js server
  Future<List<String>> getCities() async {
    try {
      final response = await _apiService.performRequest(
        method: 'GET',
        endpoint: '/locations/major-cities',
      );

      if (response != null && response['success'] == true) {
        return List<String>.from(response['cities'])..sort();
      }
    } catch (e) {
      debugPrint(
        'Error fetching cities from API, falling back to Firestore: $e',
      );
    }

    try {
      final snapshot = await _firestore.collection('cities').get();
      final cities = snapshot.docs.map((doc) => doc.id).toList();
      if (cities.isNotEmpty) {
        return cities..sort();
      }
    } catch (e) {
      debugPrint('Error fetching cities from Firestore: $e');
    }

    // Ultimate Fallback
    return [
      "Kozhikode",
      "Malappuram",
      "Kochi",
      "Bangalore",
      "Chennai",
      "Mumbai",
      "Hyderabad",
      "Delhi",
    ]..sort();
  }

  /// Fetches sharing types from a cached config document instead of scanning properties
  Future<List<String>> getSharingTypes() async {
    final doc =
        await _firestore.collection('config').doc('sharing_types').get();
    if (!doc.exists) return ['Single', 'Double', 'Triple', 'Common'];
    final data = doc.data();
    return (data?['list'] as List?)?.map((e) => e.toString()).toList() ?? [];
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

    final existing =
        await _firestore
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

  /// Fetches localities for a specific city from the Node.js server
  /// Improved: Now returns enriched data with Hub info (Colleges/Industries)
  Future<List<Map<String, dynamic>>> getLocalities(String city) async {
    try {
      final response = await _apiService.performRequest(
        method: 'GET',
        endpoint: '/locations/$city/localities',
      );

      if (response != null && response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['localities']);
      }
    } catch (e) {
      debugPrint('Error fetching localities from API, falling back to Firestore: $e');
    }

    try {
      final snapshot =
          await _firestore
              .collection('cities')
              .doc(city.toLowerCase())
              .collection('localities')
              .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => {
          'name': doc.id,
          ...doc.data(),
        }).toList();
      }

      // Legacy fallback for old collection name
      final legacySnapshot = await _firestore
          .collection('cities')
          .doc(city)
          .collection('areas')
          .get();
          
      if (legacySnapshot.docs.isNotEmpty) {
        return legacySnapshot.docs.map((doc) => {
          'name': doc.id,
        }).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching localities: $e');
      return [];
    }
  }

  /// Fetches unique college names from properties
  Future<List<String>> getColleges() async {
    try {
      final snapshot = await _firestore.collection('properties').get();
      final colleges = <String>{};
      for (final doc in snapshot.docs) {
        final basicInfo = doc.data()['basicInfo'] as Map<String, dynamic>?;
        final college = basicInfo?['collegeName'] as String?;
        if (college != null && college.isNotEmpty) {
          colleges.add(college);
        }
      }
      if (colleges.isNotEmpty) {
        return colleges.toList()..sort();
      }
    } catch (e) {
      debugPrint('Error fetching colleges: $e');
    }

    // Default Fallback
    return [
      "Yenepoya University",
      "Anna University",
      "St. Aloysius College",
      "Madras Christian College",
      "Cochin University (CUSAT)",
      "Amrita Vishwa Vidyapeetham",
    ]..sort();
  }
}
