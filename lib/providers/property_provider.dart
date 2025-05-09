import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/services/firebase_service.dart';

final propertyProvider = Provider((ref) => PropertyProvider());

class PropertyProvider {
  final _firebaseService = FirebaseService();

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
