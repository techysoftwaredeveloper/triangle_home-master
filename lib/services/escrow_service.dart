import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/escrow_record.dart';
import 'package:triangle_home/services/admin_api_service.dart';

class EscrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminApiService _apiService = AdminApiService();

  /// Creates an escrow record via the API
  Future<void> createEscrow({
    required String bookingId,
    required double deposit,
    required double rent,
    double commissionRate = 25.0,
  }) async {
    final response = await _apiService.performRequest(
      method: 'POST',
      endpoint: '/compliance/escrow',
      body: {
        'bookingId': bookingId,
        'deposit': deposit,
        'rent': rent,
        'commissionRate': commissionRate,
      },
    );

    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Failed to create escrow');
    }
  }

  /// Checks if a booking is ready for payout (48h after check-in, no disputes, not frozen)
  Future<void> evaluatePayoutReadiness(String bookingId) async {
    final bookingDoc =
        await _firestore.collection('bookings').doc(bookingId).get();
    final escrowDoc =
        await _firestore.collection('escrow').doc(bookingId).get();

    final data = bookingDoc.data();
    final escrowData = escrowDoc.data();
    if (data == null || escrowData == null) return;

    final status = data['status'];
    final checkedInAt = (data['checkedInAt'] as Timestamp?)?.toDate();
    final hasDispute = data['hasDispute'] ?? false;
    final isFrozen = escrowData['isFrozen'] ?? false;

    if (status == BookingStatus.checkedIn.name &&
        !hasDispute &&
        !isFrozen &&
        checkedInAt != null &&
        DateTime.now().difference(checkedInAt).inHours >= 48) {
      await _firestore.collection('escrow').doc(bookingId).update({
        'escrowStatus': EscrowStatus.readyForPayout.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Freezes an escrow for critical issues (Fraud, Dispute, Suspension)
  Future<void> freezeEscrow(String bookingId, String reason) async {
    await _firestore.collection('escrow').doc(bookingId).update({
      'isFrozen': true,
      'freezeReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log financial event
    await _firestore.collection('financial_events').add({
      'bookingId': bookingId,
      'event': 'ESCROW_FROZEN',
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<EscrowRecord?> getEscrowStream(String bookingId) {
    return _firestore.collection('escrow').doc(bookingId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return EscrowRecord.fromFirestore(doc.data()!);
    });
  }
}
