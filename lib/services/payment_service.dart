import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/core/errors/failures.dart';
import 'package:triangle_home/services/admin_api_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminApiService _apiService = AdminApiService();

  /// Records a payment via the API
  Future<String> recordPayment({
    required String bookingId,
    required String requestId, 
    required double amount,
    required PaymentType type,
    required String paymentMethod,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final response = await _apiService.performRequest(
        method: 'POST',
        endpoint: '/payments/record',
        body: {
          'bookingId': bookingId,
          'requestId': requestId,
          'amount': amount,
          'type': type.name,
          'paymentMethod': paymentMethod,
          'extraData': extraData,
        },
      );

      if (response['success'] == true) {
        return response['paymentId'] ?? '';
      } else {
        throw PaymentFailure(response['error'] ?? 'Payment recording failed');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw PaymentFailure('Payment recording failed: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingPayments(
    String bookingId,
  ) {
    return _firestore
        .collection('payments')
        .where('booking_id', isEqualTo: bookingId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Records a processed payment in the 'processed_payments' collection
  Future<void> recordProcessedPayment({
    required String bookingId,
    required String propertyId,
    required String roomId,
    required String bedId,
    required String paymentType,
    required double rent,
    required double securityDeposit,
    required double gst,
    required double totalAmount,
  }) async {
    try {
      await _firestore.collection('processed_payments').add({
        'bookingId': bookingId,
        'propertyId': propertyId,
        'roomId': roomId,
        'bedId': bedId,
        'paymentType': paymentType,
        'rent': rent,
        'securityDeposit': securityDeposit,
        'gst': gst,
        'totalAmount': totalAmount,
        'paymentStatus': 'paid',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw PaymentFailure('Failed to record processed payment: $e');
    }
  }

  /// Create payment record (Legacy/Sync with FirebaseService)
  Future<String> createPayment({
    required String bookingId,
    required String propertyId,
    required double amount,
    required String paymentMethod,
    required String paymentType,
    String? transactionId,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? hosterId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw 'User not authenticated';

    final docRef = await _firestore.collection('payments').add({
      'user_id': userId,
      'booking_id': bookingId,
      'property_id': propertyId,
      'hoster_id': hosterId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentType': paymentType,
      'transactionId': transactionId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }
}
