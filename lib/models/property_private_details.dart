import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyPrivateDetails {
  final String propertyId;
  final String exactAddress;
  final GeoPoint? exactLocation;
  final String hosterPhone;
  final String hosterEmail;
  final String hosterName;
  final String accessInstructions;
  final String emergencyContact;
  final DateTime updatedAt;

  PropertyPrivateDetails({
    required this.propertyId,
    required this.exactAddress,
    this.exactLocation,
    required this.hosterPhone,
    required this.hosterEmail,
    required this.hosterName,
    required this.accessInstructions,
    required this.emergencyContact,
    required this.updatedAt,
  });

  factory PropertyPrivateDetails.fromFirestore(String id, Map<String, dynamic> data) {
    return PropertyPrivateDetails(
      propertyId: id,
      exactAddress: data['exactAddress'] ?? '',
      exactLocation: data['exactLocation'] as GeoPoint?,
      hosterPhone: data['hosterPhone'] ?? '',
      hosterEmail: data['hosterEmail'] ?? '',
      hosterName: data['hosterName'] ?? '',
      accessInstructions: data['accessInstructions'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'exactAddress': exactAddress,
      'exactLocation': exactLocation,
      'hosterPhone': hosterPhone,
      'hosterEmail': hosterEmail,
      'hosterName': hosterName,
      'accessInstructions': accessInstructions,
      'emergencyContact': emergencyContact,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
