import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class RefundModel {
  final String id;
  final String bookingId;
  final String transactionId;
  final double amount;
  final RefundStatus status;
  final String reason;
  final String requestedBy;
  final DateTime createdAt;
  final DateTime? processedAt;

  RefundModel({
    required this.id,
    required this.bookingId,
    required this.transactionId,
    required this.amount,
    required this.status,
    required this.reason,
    required this.requestedBy,
    required this.createdAt,
    this.processedAt,
  });

  factory RefundModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RefundModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      transactionId: data['transactionId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: RefundStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RefundStatus.requested,
      ),
      reason: data['reason'] ?? '',
      requestedBy: data['requestedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'transactionId': transactionId,
      'amount': amount,
      'status': status.name,
      'reason': reason,
      'requestedBy': requestedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }
}
