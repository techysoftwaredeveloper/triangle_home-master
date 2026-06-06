import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyStatsModel {
  final String propertyId;
  final int availableBeds;
  final int availableRooms;
  final int occupiedBeds;
  final DateTime lastUpdated;

  PropertyStatsModel({
    required this.propertyId,
    required this.availableBeds,
    required this.availableRooms,
    required this.occupiedBeds,
    required this.lastUpdated,
  });

  factory PropertyStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyStatsModel(
      propertyId: doc.id,
      availableBeds: data['availableBeds'] ?? 0,
      availableRooms: data['availableRooms'] ?? 0,
      occupiedBeds: data['occupiedBeds'] ?? 0,
      lastUpdated: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'availableBeds': availableBeds,
      'availableRooms': availableRooms,
      'occupiedBeds': occupiedBeds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
