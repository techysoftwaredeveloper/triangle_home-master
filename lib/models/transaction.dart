import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class TransactionModel {
  final String transactionId;
  final String bookingId;
  final String userId;
  final String propertyId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String paymentGateway;
  final String? gatewayOrderId;
  final String? gatewayPaymentId;
  final String? gatewaySignature;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.transactionId,
    required this.bookingId,
    required this.userId,
    required this.propertyId,
    required this.amount,
    required this.type,
    required this.status,
    this.paymentGateway = 'RAZORPAY',
    this.gatewayOrderId,
    this.gatewayPaymentId,
    this.gatewaySignature,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TransactionModel(
      transactionId: id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == (data['transactionType'] ?? 'other'),
        orElse: () => TransactionType.reservationFee,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'created'),
        orElse: () => TransactionStatus.created,
      ),
      paymentGateway: data['paymentGateway'] ?? 'RAZORPAY',
      gatewayOrderId: data['gatewayOrderId'],
      gatewayPaymentId: data['gatewayPaymentId'],
      gatewaySignature: data['gatewaySignature'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'propertyId': propertyId,
      'amount': amount,
      'transactionType': type.name,
      'status': status.name,
      'paymentGateway': paymentGateway,
      'gatewayOrderId': gatewayOrderId,
      'gatewayPaymentId': gatewayPaymentId,
      'gatewaySignature': gatewaySignature,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
