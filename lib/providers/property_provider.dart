import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/core/constants/enums.dart';

final propertyServiceProvider = Provider((ref) => PropertyService());

final paginatedPropertiesProvider = StateNotifierProvider.family<
    PropertyPaginationNotifier,
    AsyncValue<List<Map<String, dynamic>>>,
    String?>((ref, city) {
  return PropertyPaginationNotifier(ref.watch(propertyServiceProvider), city);
});

class PropertyPaginationNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final PropertyService _propertyService;
  final String? _city;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  PropertyPaginationNotifier(this._propertyService, this._city)
      : super(const AsyncValue.loading()) {
    fetchNextBatch();
  }

  Future<void> fetchNextBatch() async {
    if (!_hasMore) return;

    try {
      final snapshot = await _propertyService.getProperties(
        limit: 10,
        startAfter: _lastDocument,
        city: _city,
        status:
            PropertyStatus.approved, // Only show approved properties to users
      );

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        if (state is AsyncLoading) {
          state = const AsyncValue.data([]);
        }
        return;
      }

      _lastDocument = snapshot.docs.last;

      final newProperties =
          snapshot.docs.map((doc) {
            final data = doc.data();
            // ... transformation logic remains same for now to avoid breaking UI
            // In the future, we should return PropertyListing models
            final basicInfo = data['basicInfo'] ?? {};
            final propertyInfo = data['propertyInfo'] ?? {};
            final pricingInfo = data['pricingInfo'] ?? {};
            final imagesRaw = data['images'] ?? propertyInfo['images'] ?? [];
            final images =
                imagesRaw is List
                    ? List<String>.from(imagesRaw.take(10))
                    : <String>[];

            return {
              'id': doc.id,
              'title': basicInfo['collegeName'] ?? 'Unnamed Property',
              'city': pricingInfo['city'] ?? data['city'] ?? 'N/A',
              'state': pricingInfo['state'] ?? 'N/A',
              'location':
                  "${pricingInfo['addressLine1'] ?? data['locality'] ?? 'N/A'}, ${pricingInfo['city'] ?? data['city'] ?? 'N/A'}",
              'type': basicInfo['type'] ?? 'N/A',
              'sharing': propertyInfo['sharing'] ?? 'N/A',
              'price':
                  int.tryParse(
                    (pricingInfo['monthlyRent'] ?? '0').toString().replaceAll(
                      ',',
                      '',
                    ),
                  ) ??
                  0,
              'image':
                  images.isNotEmpty
                      ? images[0]
                      : 'https://via.placeholder.com/150',
              'images': images,
              'wardenName': basicInfo['wardenName'] ?? 'N/A',
              'phone': basicInfo['phone'] ?? 'N/A',
              'availability': propertyInfo['availability'],
              'features': propertyInfo['features'] ?? [],
            };
          }).toList();

      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, ...newProperties]);

      if (snapshot.docs.length < 10) {
        _hasMore = false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  bool get hasMore => _hasMore;
}
