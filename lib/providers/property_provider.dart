import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/core/constants/enums.dart';

final propertyServiceProvider = Provider((ref) => PropertyService());

// ── Real-time stream provider (replaces paginated future) ───────────────────
//
// Uses PropertyService.getPropertiesStream which runs:
//   .where('status', isEqualTo: 'approved')
//   .orderBy('createdAt', descending: true)
//
// City filtering is done client-side to avoid needing a composite Firestore
// index for (status + city + createdAt). Works fine for reasonable dataset sizes.

final propertiesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, city) {
  final service = ref.watch(propertyServiceProvider);

  // For major cities, we can use server filtering
  // For detected localities (like "Chingavanam"), we fetch all and broad match
  return service
      .getPropertiesStream(
        status: PropertyStatus.approved,
        city: null, // Fetch all and filter client-side for "broad match" support
      )
      .map((all) {
    final normalized = _normalize(all);
    
    if (city == null ||
        city.isEmpty ||
        city.toLowerCase() == 'global' ||
        city.toLowerCase() == 'all' ||
        city.toLowerCase() == 'near me' ||
        city.toLowerCase() == 'detecting...') {
      return normalized;
    }

    final query = city.toLowerCase().trim();
    
    // Broad Matching Logic:
    // 1. Matches City
    // 2. Matches Locality
    // 3. Any search term starts with/contains the query
    final results = normalized.where((p) {
      final pCity = p['city']?.toString().toLowerCase() ?? '';
      final pLocality = (p['locality'] ?? p['basicInfo']?['locality'] ?? '').toString().toLowerCase();
      final pTitle = p['title']?.toString().toLowerCase() ?? '';
      
      return pCity.contains(query) || 
             pLocality.contains(query) || 
             pTitle.contains(query);
    }).toList();

    // Fallback: If no results for a specific locality, show all properties
    // (Better to show something than an empty screen for "Near Me")
    if (results.isEmpty && (city.toLowerCase() == 'unknown' || query.length > 3)) {
       return normalized;
    }

    return results;
  });
});

/// Normalize a raw Firestore property map into the shape NearbyAccommodations expects.
List<Map<String, dynamic>> _normalize(List<Map<String, dynamic>> raw) {
  return raw.map((data) {
    final basicInfo =
        (data['basicInfo'] as Map?)?.cast<String, dynamic>() ?? {};
    final propertyInfo =
        (data['propertyInfo'] as Map?)?.cast<String, dynamic>() ?? {};
    final pricingInfo =
        (data['pricingInfo'] as Map?)?.cast<String, dynamic>() ?? {};

    // Title: basicInfo.collegeName > basicInfo.name > data.title > data.name
    final title = (basicInfo['collegeName'] ?? basicInfo['name'] ??
            data['title'] ?? data['name'] ?? 'Unnamed Property')
        .toString();

    // City: top-level > pricingInfo > basicInfo
    final city = (data['city'] ?? pricingInfo['city'] ?? basicInfo['city'] ?? '')
        .toString();

    // Locality
    final locality =
        (data['locality'] ?? pricingInfo['addressLine1'] ?? '').toString();

    final location =
        (locality.isNotEmpty && city.isNotEmpty)
            ? '$locality, $city'
            : city.isNotEmpty
                ? city
                : locality.isNotEmpty
                    ? locality
                    : 'N/A';

    // Type / sharing
    final type = (basicInfo['type'] ?? data['type'] ?? '').toString();
    final sharing =
        (propertyInfo['sharing'] ?? data['sharing'] ?? 'N/A').toString();

    // Price: pricingInfo.monthlyRent > data.monthlyRent > data.price
    final rawRent =
        (pricingInfo['monthlyRent'] ?? data['monthlyRent'] ?? data['price'] ??
                '0')
            .toString()
            .replaceAll(',', '');
    final price = int.tryParse(rawRent) ?? 0;

    // Images: data.images > propertyInfo.images
    final imagesRaw = (data['images'] ?? propertyInfo['images'] ?? []);
    final images = imagesRaw is List
        ? List<String>.from(imagesRaw.take(10).map((e) => e.toString()))
        : <String>[];

    final image = images.isNotEmpty ? images[0] : null;

    // Rating / reviews
    final rating =
        (data['rating'] as num?)?.toDouble() ??
        (data['averageRating'] as num?)?.toDouble() ??
        4.0;
    final reviewCount =
        (data['reviewCount'] as num?)?.toInt() ??
        (data['totalReviews'] as num?)?.toInt() ??
        0;

    return {
      'id': data['id'] ?? '',
      'title': title,
      'city': city,
      'state': (data['state'] ?? pricingInfo['state'] ?? '').toString(),
      'location': location,
      'type': type,
      'sharing': sharing,
      'price': price,
      'image': image,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'wardenName': (basicInfo['wardenName'] ?? data['wardenName'] ?? 'N/A')
          .toString(),
      'phone': (basicInfo['phone'] ?? data['phone'] ?? 'N/A').toString(),
      'availability': propertyInfo['availability'] ?? data['availability'],
      'features': (propertyInfo['features'] ?? data['features'] ?? []),
      'status': data['status'] ?? '',
      // Pass through raw data for detail screen
      'basicInfo': basicInfo,
      'propertyInfo': propertyInfo,
      'pricingInfo': pricingInfo,
    };
  }).toList();
}

// ── Legacy alias so existing call sites keep compiling ──────────────────────
//
// The old paginatedPropertiesProvider was a StateNotifierProvider.family
// that returned AsyncValue<List>. The new propertiesStreamProvider is a
// StreamProvider.family which also exposes AsyncValue<List>, so we just
// re-export it under the old name.

final paginatedPropertiesProvider = propertiesStreamProvider;
