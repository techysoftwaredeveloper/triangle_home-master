import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/admin_api_service.dart';

class PayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminApiService _apiService = AdminApiService();

  /// Requests a payout via the API
  Future<void> requestPayout(String bookingId) async {
    final response = await _apiService.performRequest(
      method: 'POST',
      endpoint: '/compliance/payout/request',
      body: {'bookingId': bookingId},
    );

    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Failed to request payout');
    }
  }

  /// Final approval and release of funds (Admin Only)
  Future<void> releasePayout(String bookingId, String adminId) async {
    await _firestore.collection('escrow').doc(bookingId).update({
      'escrowStatus': EscrowStatus.payoutReleased.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('financial_events').add({
      'bookingId': bookingId,
      'event': FinancialEventType.payoutReleased.name,
      'performedBy': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // In a real scenario, this would trigger the actual bank transfer via Razorpay Route/Marketplace
  }
}
