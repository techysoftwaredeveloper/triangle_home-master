enum AccommodationType {
  apartment,
  pgAccommodation,
  house,
  villa,
  hostel,
}

class Accommodation {
  final String id;
  final String title;
  final String description;
  final AccommodationType type;
  final double price;
  final List<String> images;
  final String address;
  final double latitude;
  final double longitude;
  final int bedrooms;
  final int bathrooms;
  final List<String> amenities;
  final double rating;
  final int reviewCount;
  final String ownerId;
  final DateTime availableFrom;
  final DateTime createdAt;
  final DateTime updatedAt;

  Accommodation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.images,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.bedrooms,
    required this.bathrooms,
    required this.amenities,
    required this.rating,
    required this.reviewCount,
    required this.ownerId,
    required this.availableFrom,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    return Accommodation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: AccommodationType.values.firstWhere(
        (e) => e.toString() == 'AccommodationType.${json['type']}',
      ),
      price: json['price'].toDouble(),
      images: List<String>.from(json['images']),
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      amenities: List<String>.from(json['amenities']),
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      ownerId: json['ownerId'],
      availableFrom: DateTime.parse(json['availableFrom']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'price': price,
      'images': images,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'rating': rating,
      'reviewCount': reviewCount,
      'ownerId': ownerId,
      'availableFrom': availableFrom.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}