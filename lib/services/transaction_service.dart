import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/transaction.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new transaction record with initial state
  Future<String> createTransaction(TransactionModel transaction) async {
    final docRef = await _firestore.collection('transactions').add({
      ...transaction.toFirestore(),
      'status': TransactionStatus.created.name,
    });
    
    // Log financial event
    await _logFinancialEvent(
      bookingId: transaction.bookingId,
      type: FinancialEventType.paymentReceived,
      amount: transaction.amount,
      userId: transaction.userId,
      extraData: {'transactionId': docRef.id, 'type': transaction.type.name}
    );

    return docRef.id;
  }

  /// Internal helper for logging financial events
  Future<void> _logFinancialEvent({
    required String bookingId,
    required FinancialEventType type,
    required double amount,
    required String userId,
    Map<String, dynamic>? extraData,
  }) async {
    await _firestore.collection('financial_events').add({
      'bookingId': bookingId,
      'event': type.name,
      'amount': amount,
      'performedBy': userId,
      'timestamp': FieldValue.serverTimestamp(),
      if (extraData != null) 'data': extraData,
    });
  }

  /// Verifies if a payment has already been processed (Idempotency check)
  Future<bool> isPaymentProcessed(String gatewayPaymentId) async {
    final snapshot = await _firestore
        .collection('processed_payments')
        .doc(gatewayPaymentId)
        .get();
    return snapshot.exists;
  }

  /// Verifies a payment and updates transaction status with audit trail
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status, {String? paymentId}) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': status.name,
      if (paymentId != null) 'gatewayPaymentId': paymentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log payment event for specific transitions
    await _firestore.collection('payment_events').add({
      'transactionId': transactionId,
      'event': status == TransactionStatus.success ? 'PAYMENT_SUCCESS' : 'STATUS_UPDATE',
      'status': status.name,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches transactions for a specific booking
  Stream<List<TransactionModel>> getBookingTransactions(String bookingId) {
    return _firestore
        .collection('transactions')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}
