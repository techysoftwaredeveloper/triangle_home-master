import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/services/firebase_service.dart';

final propertyProvider = Provider((ref) => PropertyProvider());

final paginatedPropertiesProvider = StateNotifierProvider<
  PropertyPaginationNotifier,
  AsyncValue<List<Map<String, dynamic>>>
>((ref) {
  return PropertyPaginationNotifier(ref.watch(propertyProvider));
});

class PropertyPaginationNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final PropertyProvider _propertyProvider;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  PropertyPaginationNotifier(this._propertyProvider)
    : super(const AsyncValue.loading()) {
    fetchNextBatch();
  }

  Future<void> fetchNextBatch() async {
    if (!_hasMore) return;

    try {
      if (state is! AsyncLoading) {
        // Only set loading if it's the first fetch
        // For subsequent fetches, we might want a different UX but keep it simple for now
      }

      final snapshot = await _propertyProvider.getPaginatedProperties(
        limit: 10,
        startAfter: _lastDocument,
      );

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        if (state is AsyncLoading) {
          state = const AsyncValue.data([]);
        }
        return;
      }

      _lastDocument = snapshot.docs.last;

      final newProperties = snapshot.docs.map((doc) {
        final data = doc.data();
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
          'title':
              basicInfo['collegeName'] ??
              'Unnamed Property',
          'city': pricingInfo['city'] ?? 'N/A',
          'state': pricingInfo['state'] ?? 'N/A',
          'location':
              "${pricingInfo['addressLine1'] ?? 'N/A'}, ${pricingInfo['city'] ?? 'N/A'}",
          'type': basicInfo['type'] ?? 'N/A',
          'sharing': propertyInfo['sharing'] ?? 'N/A',
          'price':
              int.tryParse(
                (pricingInfo['monthlyRent'] ?? '0').toString().replaceAll(',', ''),
              ) ??
              0,
          'image':
              images.isNotEmpty
                  ? images[0]
                  : 'https://via.placeholder.com/150',
          'images': images,
          'wardenName':
              basicInfo['wardenName'] ?? 'N/A',
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

class PropertyProvider {
  final _firebaseService = FirebaseService();

  Future<QuerySnapshot<Map<String, dynamic>>> getPaginatedProperties({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) {
    return _firebaseService.getPaginatedProperties(
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<void> createProperty({
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
      await _firebaseService.createPropertyListing(
        title: title,
        description: description,
        type: type,
        price: price,
        images: images,
        address: address,
        latitude: latitude,
        longitude: longitude,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        amenities: amenities,
        availableFrom: availableFrom,
      );
    } catch (e) {
      rethrow;
    }
  }
}
