import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class PayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Requests a payout for a hoster (usually triggered after check-in hold)
  Future<void> requestPayout(String bookingId) async {
    await _firestore.collection('escrow').doc(bookingId).update({
      'escrowStatus': EscrowStatus.payoutRequested.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('financial_events').add({
      'bookingId': bookingId,
      'event': FinancialEventType.payoutRequested.name,
      'performedBy': 'hoster',
      'timestamp': FieldValue.serverTimestamp(),
    });
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
