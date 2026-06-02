import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class RoomModel {
  final String id;
  final String roomNumber;
  final RoomType roomType;
  final int floor;
  final int totalBeds;
  final int availableBeds;
  final int occupiedBeds;
  final double baseRent;
  final double baseDeposit;
  final List<String> amenities;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.floor,
    required this.totalBeds,
    required this.availableBeds,
    required this.occupiedBeds,
    required this.baseRent,
    required this.baseDeposit,
    required this.amenities,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      roomNumber: data['roomNumber'] ?? '',
      roomType: RoomType.values.firstWhere(
        (e) => e.name == (data['roomType'] ?? 'single'),
        orElse: () => RoomType.single,
      ),
      floor: data['floor'] ?? 0,
      totalBeds: data['totalBeds'] ?? 0,
      availableBeds: data['availableBeds'] ?? 0,
      occupiedBeds: data['occupiedBeds'] ?? 0,
      baseRent: (data['baseRent'] ?? 0).toDouble(),
      baseDeposit: (data['baseDeposit'] ?? 0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomNumber': roomNumber,
      'roomType': roomType.name,
      'floor': floor,
      'totalBeds': totalBeds,
      'availableBeds': availableBeds,
      'occupiedBeds': occupiedBeds,
      'baseRent': baseRent,
      'baseDeposit': baseDeposit,
      'amenities': amenities,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
