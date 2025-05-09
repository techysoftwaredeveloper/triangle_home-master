import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

      // Upload images first
      final List<String> imageUrls = await uploadImages(images);

      // Create property document
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
}
