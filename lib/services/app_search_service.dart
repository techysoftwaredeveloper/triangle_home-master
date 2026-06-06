import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

abstract class AppSearchService {
  Future<List<Map<String, dynamic>>> searchProperties({
    String? city,
    List<String>? localities,
    String? college,
    String? accommodationType,
    String? tenantType,
    String? roomType,
    int limit = 20,
    DocumentSnapshot? startAfter,
  });
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
    final collegeName = basicInfo['collegeName'] as String? ?? '';

    if (college != null &&
        college.isNotEmpty &&
        !collegeName.toLowerCase().contains(college.toLowerCase())) {
      return false;
    }
    if (localities != null &&
        localities.isNotEmpty &&
        !localities.any(
          (loc) => locality.toLowerCase().contains(loc.toLowerCase()),
        )) {
      return false;
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
