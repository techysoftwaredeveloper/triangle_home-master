import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyStatsModel {
  final String propertyId;
  final int totalBeds;
  final int availableBeds;
  final int occupiedBeds;
  final int reservedBeds;
  final int availableRooms;
  final DateTime lastUpdated;

  PropertyStatsModel({
    required this.propertyId,
    required this.totalBeds,
    required this.availableBeds,
    required this.occupiedBeds,
    required this.reservedBeds,
    required this.availableRooms,
    required this.lastUpdated,
  });

  factory PropertyStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PropertyStatsModel(
      propertyId: doc.id,
      totalBeds: (data['totalBeds'] as num? ?? 0).toInt(),
      availableBeds: (data['availableBeds'] as num? ?? 0).toInt(),
      occupiedBeds: (data['occupiedBeds'] as num? ?? 0).toInt(),
      reservedBeds: (data['reservedBeds'] as num? ?? 0).toInt(),
      availableRooms: (data['availableRooms'] as num? ?? 0).toInt(),
      lastUpdated: () {
        final val = data['updatedAt'];
        if (val is Timestamp) return val.toDate();
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        return DateTime.now();
      }(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalBeds': totalBeds,
      'availableBeds': availableBeds,
      'occupiedBeds': occupiedBeds,
      'reservedBeds': reservedBeds,
      'availableRooms': availableRooms,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
