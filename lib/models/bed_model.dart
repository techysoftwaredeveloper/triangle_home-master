import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class BedModel {
  final String id;
  final String propertyId;
  final String roomId;
  final String bedNumber;
  final BedStatus status;
  final String? reservedBy;
  final String? currentResidentId;
  final DateTime? reservationExpiresAt;
  final DateTime? lastCleanedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BedModel({
    required this.id,
    required this.propertyId,
    required this.roomId,
    required this.bedNumber,
    required this.status,
    this.reservedBy,
    this.currentResidentId,
    this.reservationExpiresAt,
    this.lastCleanedAt,
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
      reservedBy: data['reservedBy'],
      currentResidentId: data['currentResidentId'],
      reservationExpiresAt:
          (data['reservationExpiresAt'] as Timestamp?)?.toDate(),
      lastCleanedAt: (data['lastCleanedAt'] as Timestamp?)?.toDate(),
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
      'reservedBy': reservedBy,
      'currentResidentId': currentResidentId,
      'reservationExpiresAt':
          reservationExpiresAt != null
              ? Timestamp.fromDate(reservationExpiresAt!)
              : null,
      'lastCleanedAt':
          lastCleanedAt != null ? Timestamp.fromDate(lastCleanedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
