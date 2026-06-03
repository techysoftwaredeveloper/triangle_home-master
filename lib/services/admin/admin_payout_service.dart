import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class AdminPayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Releases payout to a hoster with strict safety checks
  Future<void> releasePayout({
    required String bookingId,
    required String adminId,
    String? reason,
  }) async {
    // 1. Fetch current Escrow and Booking state
    final escrowDoc =
        await _firestore.collection('escrow').doc(bookingId).get();
    final bookingDoc =
        await _firestore.collection('bookings').doc(bookingId).get();

    if (!escrowDoc.exists || !bookingDoc.exists) {
      throw 'Escrow or Booking record not found';
    }

    final escrowData = escrowDoc.data()!;
    final bookingData = bookingDoc.data()!;

    // 2. Perform Safety Validation
    // Rule A: Escrow Status must be READY_FOR_PAYOUT
    if (escrowData['escrowStatus'] != EscrowStatus.readyForPayout.name) {
      throw 'Payout not eligible. Current status: ${escrowData['escrowStatus']}';
    }

    // Rule B: Booking Status must be CHECKED_IN
    if (bookingData['status'] != BookingStatus.checkedIn.name) {
      throw 'Payout blocked: User has not checked in.';
    }

    // Rule C: No active disputes
    final disputeSnapshot =
        await _firestore
            .collection('disputes')
            .where('bookingId', isEqualTo: bookingId)
            .where(
              'status',
              whereIn: [
                DisputeStatus.open.name,
                DisputeStatus.underReview.name,
              ],
            )
            .get();

    if (disputeSnapshot.docs.isNotEmpty) {
      throw 'Payout blocked: Active dispute found for this booking.';
    }

    // 3. Process Payout Transactionally
    await _firestore.runTransaction((transaction) async {
      // A. Update Escrow Record
      transaction.update(_firestore.collection('escrow').doc(bookingId), {
        'escrowStatus': EscrowStatus.payoutReleased.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // B. Log Admin Action
      transaction.set(_firestore.collection('admin_actions').doc(), {
        'adminId': adminId,
        'actionType': AdminActionType.payoutReleased.name,
        'bookingId': bookingId,
        'timestamp': FieldValue.serverTimestamp(),
        'reason': reason ?? 'Manual release by Admin',
      });

      // C. Log Financial Event
      transaction.set(_firestore.collection('financial_events').doc(), {
        'bookingId': bookingId,
        'event': FinancialEventType.payoutReleased.name,
        'performedBy': adminId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Validates if a booking is eligible for payout release
  Future<PayoutValidationResult> validatePayoutEligibility(
    String bookingId,
  ) async {
    try {
      final escrowDoc =
          await _firestore.collection('escrow').doc(bookingId).get();
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!escrowDoc.exists || !bookingDoc.exists) {
        return PayoutValidationResult(
          canRelease: false,
          reason: 'Records not found',
        );
      }

      final escrowData = escrowDoc.data()!;
      final bookingData = bookingDoc.data()!;

      // Rule 1: No active disputes
      final disputeSnapshot =
          await _firestore
              .collection('disputes')
              .where('bookingId', isEqualTo: bookingId)
              .where(
                'status',
                whereIn: [
                  DisputeStatus.open.name,
                  DisputeStatus.underReview.name,
                ],
              )
              .get();

      if (disputeSnapshot.docs.isNotEmpty) {
        return PayoutValidationResult(
          canRelease: false,
          reason: 'Active dispute found',
        );
      }

      // Rule 2: Booking Status must be CHECKED_IN
      if (bookingData['status'] != BookingStatus.checkedIn.name &&
          bookingData['status'] != BookingStatus.checkedOut.name &&
          bookingData['status'] != BookingStatus.completed.name) {
        return PayoutValidationResult(
          canRelease: false,
          reason: 'User not checked in',
        );
      }

      // Rule 3: 48-hour hold window (if not already released)
      if (escrowData['escrowStatus'] == EscrowStatus.payoutReleased.name) {
        return PayoutValidationResult(
          canRelease: false,
          reason: 'Already released',
        );
      }

      final checkedInAt = (bookingData['checkedInAt'] as Timestamp?)?.toDate();
      if (checkedInAt == null) {
        return PayoutValidationResult(
          canRelease: false,
          reason: 'Check-in time not recorded',
        );
      }

      final hoursPassed = DateTime.now().difference(checkedInAt).inHours;
      if (hoursPassed < 48) {
        return PayoutValidationResult(
          canRelease: false,
          reason: 'Holding window active (${48 - hoursPassed}h left)',
        );
      }

      return PayoutValidationResult(canRelease: true);
    } catch (e) {
      return PayoutValidationResult(
        canRelease: false,
        reason: 'Validation error: $e',
      );
    }
  }
}

class PayoutValidationResult {
  final bool canRelease;
  final String? reason;

  PayoutValidationResult({required this.canRelease, this.reason});
}
