import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class BedModel {
  final String id;
  final String propertyId;
  final String roomId;
  final String bedNumber;
  final BedStatus status;
  final double monthlyRent;
  final double securityDeposit;
  final String? reservedBy;
  final String? currentResidentId;
  final DateTime? reservationExpiresAt;
  final DateTime? availableFrom;
  final DateTime createdAt;
  final DateTime updatedAt;

  BedModel({
    required this.id,
    required this.propertyId,
    required this.roomId,
    required this.bedNumber,
    required this.status,
    required this.monthlyRent,
    required this.securityDeposit,
    this.reservedBy,
    this.currentResidentId,
    this.reservationExpiresAt,
    this.availableFrom,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BedModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BedModel(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      roomId: data['roomId'] ?? '',
      bedNumber: data['bedNumber'] ?? '',
      status: BedStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'available'),
        orElse: () => BedStatus.available,
      ),
      monthlyRent: (data['monthlyRent'] ?? 0).toDouble(),
      securityDeposit: (data['securityDeposit'] ?? 0).toDouble(),
      reservedBy: data['reservedBy'],
      currentResidentId: data['currentResidentId'],
      reservationExpiresAt:
          (data['reservationExpiresAt'] as Timestamp?)?.toDate(),
      availableFrom: (data['availableFrom'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'roomId': roomId,
      'bedNumber': bedNumber,
      'status': status.name,
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'reservedBy': reservedBy,
      'currentResidentId': currentResidentId,
      'reservationExpiresAt':
          reservationExpiresAt != null
              ? Timestamp.fromDate(reservationExpiresAt!)
              : null,
      'availableFrom':
          availableFrom != null ? Timestamp.fromDate(availableFrom!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
