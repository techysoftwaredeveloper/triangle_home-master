import 'package:cloud_firestore/cloud_firestore.dart';
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
}
