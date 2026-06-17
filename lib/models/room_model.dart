import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class RoomModel {
  final String id;
  final String propertyId;
  final String roomNumber;
  final RoomType roomType;
  final String occupancyType; // e.g., "Single Occupancy", "Double Sharing"
  final int floor;
  final String floorId;
  final int totalBeds;
  final int availableBeds;
  final int occupiedBeds;
  final double baseRent;
  final double baseDeposit;
  final List<String> amenities;
  final List<String> images;
  final String genderRestriction; // "Man", "Woman", "Anyone"
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomModel({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    required this.roomType,
    required this.occupancyType,
    required this.floor,
    required this.floorId,
    required this.totalBeds,
    required this.availableBeds,
    required this.occupiedBeds,
    required this.baseRent,
    required this.baseDeposit,
    required this.amenities,
    required this.images,
    required this.genderRestriction,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      roomType: RoomType.values.firstWhere(
        (e) => e.name == (data['roomType'] ?? 'single'),
        orElse: () => RoomType.single,
      ),
      occupancyType: data['occupancyType'] ?? '',
      floor: (data['floor'] as num?)?.toInt() ?? 0,
      floorId: data['floorId'] ?? '',
      totalBeds: (data['totalBeds'] as num?)?.toInt() ?? 0,
      availableBeds: (data['availableBeds'] as num?)?.toInt() ?? 0,
      occupiedBeds: (data['occupiedBeds'] as num?)?.toInt() ?? 0,
      baseRent: (data['baseRent'] ?? 0).toDouble(),
      baseDeposit: (data['baseDeposit'] ?? 0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      genderRestriction: data['genderRestriction'] ?? 'Anyone',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'roomNumber': roomNumber,
      'roomType': roomType.name,
      'occupancyType': occupancyType,
      'floor': floor,
      'floorId': floorId,
      'totalBeds': totalBeds,
      'availableBeds': availableBeds,
      'occupiedBeds': occupiedBeds,
      'baseRent': baseRent,
      'baseDeposit': baseDeposit,
      'amenities': amenities,
      'images': images,
      'genderRestriction': genderRestriction,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
