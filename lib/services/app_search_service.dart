import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

import 'package:triangle_home/services/admin_api_service.dart';

abstract class AppSearchService {
  Future<List<Map<String, dynamic>>> searchProperties({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
    int limit = 20,
    int offset = 0,
  });

  Stream<List<Map<String, dynamic>>> searchPropertiesStream({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
  });
}

class ApiSearchService implements AppSearchService {
  final AdminApiService _apiService = AdminApiService();

  @override
  Future<List<Map<String, dynamic>>> searchProperties({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      if (city != null) 'city': city,
      if (localities != null && localities.isNotEmpty) 'localities': localities.join(','),
      if (college != null) 'college': college,
      if (accommodationType != null) 'accommodationType': accommodationType,
      if (tenantType != null) 'tenantType': tenantType,
      if (roomType != null) 'roomType': roomType,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = '/search/properties?$queryString';

    try {
      final result = await _apiService.performRequest(
        method: 'GET',
        endpoint: endpoint,
      );

      if (result['success'] == true) {
        return List<Map<String, dynamic>>.from(result['results']);
      } else {
        throw Exception(result['error'] ?? 'Search failed');
      }
    } catch (e) {
      debugPrint('API Search Service Error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> searchPropertiesStream({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
  }) {
    // API doesn't support streams, fallback to periodic polling if absolutely needed,
    // or just return an empty stream/single value stream.
    // For now, we'll suggest using FirestoreSearchService for real-time.
    return Stream.fromFuture(searchProperties(
      city: city,
      localities: localities,
      college: college,
      accommodationType: accommodationType,
      tenantType: tenantType,
      roomType: roomType,
    ));
  }
}

class FirestoreSearchService implements AppSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Map<String, dynamic>>> searchProperties({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
    int limit = 20,
    int offset = 0,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('properties');

    if (city != null && city.isNotEmpty) {
      query = query.where('city_normalized', isEqualTo: city.toLowerCase().trim());
    }

    query = query.where('status', isEqualTo: PropertyStatus.approved.name);
    query = query.orderBy('createdAt', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    try {
      final snapshot = await query.get();
      final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final basicInfo = data['basicInfo'] as Map<String, dynamic>? ?? {};

        if (_matchesFilters(
          data,
          localities,
          college,
          accommodationType,
          tenantType,
          roomType,
        )) {
          results.add(_formatResult(doc, data, basicInfo));
        }
      }

      return results;
    } catch (e) {
      // ✅ Fallback logic: if the complex query fails (e.g. missing index),
      // log a detailed error and throw a PropertyFailure.
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('PERMISSION_DENIED')) {
        debugPrint(
          'CRITICAL: Search query failed. This usually means a Firestore Index is missing or Rules are too restrictive.',
        );
        debugPrint('Required Index: properties (status: ASC, createdAt: DESC)');
      }
      rethrow;
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> searchPropertiesStream({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('properties');

    if (city != null && city.isNotEmpty && city != 'Global') {
      query = query.where('city_normalized', isEqualTo: city.toLowerCase().trim());
    }

    query = query.where('status', isEqualTo: PropertyStatus.approved.name);
    
    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
       final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final basicInfo = data['basicInfo'] as Map<String, dynamic>? ?? {};

        if (_matchesFilters(
          data,
          localities,
          college,
          accommodationType,
          tenantType,
          roomType,
        )) {
          results.add(_formatResult(doc, data, basicInfo));
        }
      }

      return results;
    });
  }

  bool _matchesFilters(
    Map<String, dynamic> data,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
  ) {
    final basicInfo = data['basicInfo'] as Map<String, dynamic>? ?? {};
    final locality = data['locality'] as String? ?? '';
    final collegeName = basicInfo['collegeName'] as String? ?? 
                        basicInfo['name'] as String? ?? 
                        data['name'] as String? ?? 
                        data['title'] as String? ?? '';
    final propertyTenantType = basicInfo['tenantType'] as String? ?? '';
    final sharing = basicInfo['sharing'] as String? ?? '';

    // 1. College filter
    if (college != null &&
        college.isNotEmpty &&
        !collegeName.toLowerCase().contains(college.toLowerCase())) {
      return false;
    }

    // 2. Locality filter
    if (localities != null &&
        localities.isNotEmpty &&
        !localities.any(
          (loc) => locality.toLowerCase().contains(loc.toLowerCase()),
        )) {
      return false;
    }

    // 3. Accommodation type filter
    if (accommodationType != null && accommodationType.isNotEmpty) {
      final propType = data['propertyType'] as String? ?? '';
      if (accommodationType == 'Paying Guest Hostels') {
        if (!propType.toLowerCase().contains('pg') &&
            !propType.toLowerCase().contains('hostel')) {
          return false;
        }
      } else if (accommodationType == 'Apartments') {
        if (!propType.toLowerCase().contains('apartment') &&
            !propType.toLowerCase().contains('flat')) {
          return false;
        }
      }
    }

    // 4. Tenant type filter
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
      if (!isMatch) return false;
    }

    // 5. Room type filter
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

        if (!hasBhk) return false;
      } else {
        if (!sharing.toLowerCase().contains(roomType.toLowerCase())) {
          return false;
        }
      }
    }

    return true;
  }

  Map<String, dynamic> _formatResult(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    Map<String, dynamic> basicInfo,
  ) {
    return {
      'id': doc.id,
      'doc': doc,
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
      'image':
          (data['images'] as List?)?.isNotEmpty == true
              ? (data['images'] as List).first
              : 'https://via.placeholder.com/150',
    };
  }
}
