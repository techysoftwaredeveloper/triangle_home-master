import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class EscrowRecord {
  final String bookingId;
  final double depositAmount;
  final double rentAmount;
  final double platformFeeAmount;
  final double grossAmount;
  final double commissionRate;
  final double commissionAmount;
  final double hosterAmount;
  final EscrowStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? releaseEligibleAt;
  final bool isFrozen;
  final String? freezeReason;

  EscrowRecord({
    required this.bookingId,
    required this.depositAmount,
    required this.rentAmount,
    required this.platformFeeAmount,
    required this.grossAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.hosterAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.releaseEligibleAt,
    this.isFrozen = false,
    this.freezeReason,
  });

  factory EscrowRecord.fromFirestore(Map<String, dynamic> data) {
    return EscrowRecord(
      bookingId: data['bookingId'] ?? '',
      depositAmount: (data['depositAmount'] ?? 0).toDouble(),
      rentAmount: (data['rentAmount'] ?? 0).toDouble(),
      platformFeeAmount: (data['platformFeeAmount'] ?? 0).toDouble(),
      grossAmount: (data['grossAmount'] ?? 0).toDouble(),
      commissionRate: (data['commissionRate'] ?? 25).toDouble(),
      commissionAmount: (data['commissionAmount'] ?? 0).toDouble(),
      hosterAmount: (data['hosterAmount'] ?? 0).toDouble(),
      status: EscrowStatus.values.firstWhere(
        (e) => e.name == (data['escrowStatus'] ?? 'held'),
        orElse: () => EscrowStatus.held,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      releaseEligibleAt: (data['releaseEligibleAt'] as Timestamp?)?.toDate(),
      isFrozen: data['isFrozen'] ?? false,
      freezeReason: data['freezeReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'depositAmount': depositAmount,
      'rentAmount': rentAmount,
      'platformFeeAmount': platformFeeAmount,
      'grossAmount': grossAmount,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'hosterAmount': hosterAmount,
      'escrowStatus': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      if (releaseEligibleAt != null)
        'releaseEligibleAt': Timestamp.fromDate(releaseEligibleAt!),
      'isFrozen': isFrozen,
      if (freezeReason != null) 'freezeReason': freezeReason,
    };
  }
}
