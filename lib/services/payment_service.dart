import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/core/errors/failures.dart';
import 'package:triangle_home/services/booking_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService();

  /// Records a payment with idempotency protection
  Future<String> recordPayment({
    required String bookingId,
    required String requestId, // From Razorpay or generated locally before calling Razorpay
    required double amount,
    required PaymentType type,
    required String paymentMethod,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // 1. Idempotency Check
      final existing = await _firestore
          .collection('payments')
          .where('request_id', isEqualTo: requestId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      // 2. Perform payment record and trigger booking confirmation
      final paymentDocRef = _firestore.collection('payments').doc();

      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw const PaymentFailure('Booking not found', code: ErrorCodes.bookingExpired);
        }

        // Record Payment
        transaction.set(paymentDocRef, {
          'booking_id': bookingId,
          'request_id': requestId,
          'amount': amount,
          'type': type.name,
          'method': paymentMethod,
          'status': PaymentStatus.completed.name,
          'createdAt': FieldValue.serverTimestamp(),
          ...?extraData,
        });

        // Use BookingService logic to handle transitions and side effects (occupancy)
        // Note: Transactions cannot call other non-transactional methods easily.
        // We'll manually replicate the transition logic here but ideally, this would be a unified workflow.

        final currentStatus = bookingDoc.data()?['status'] as String? ?? 'pending';
        if (currentStatus == BookingStatus.approved.name) {
          // Atomic update of booking AND occupancy
          transaction.update(bookingRef, {
            'status': BookingStatus.confirmed.name,
            'paymentStatus': PaymentStatus.completed.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          final propertyId = bookingDoc.data()?['property_id'] as String?;
          if (propertyId != null) {
            transaction.update(_firestore.collection('properties').doc(propertyId), {
              'currentOccupancy': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      return paymentDocRef.id;
    } catch (e) {
      if (e is Failure) rethrow;
      throw PaymentFailure('Payment recording failed: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingPayments(String bookingId) {
    return _firestore
        .collection('payments')
        .where('booking_id', isEqualTo: bookingId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
