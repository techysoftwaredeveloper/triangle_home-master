import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyListing {
  final String id;
  final String title;
  final String description;
  final String type;
  final double price;
  final List<String> images;
  final String address;
  final GeoPoint location;
  final int bedrooms;
  final int bathrooms;
  final List<String> amenities;
  final String ownerId;
  final DateTime availableFrom;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyListing({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.images,
    required this.address,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.amenities,
    required this.ownerId,
    required this.availableFrom,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PropertyListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyListing(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      address: data['address'] ?? '',
      location: data['location'] as GeoPoint,
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      amenities: List<String>.from(data['amenities'] ?? []),
      ownerId: data['ownerId'] ?? '',
      availableFrom: (data['availableFrom'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'price': price,
      'images': images,
      'address': address,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'ownerId': ownerId,
      'availableFrom': Timestamp.fromDate(availableFrom),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
