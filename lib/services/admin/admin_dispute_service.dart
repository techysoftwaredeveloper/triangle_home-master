import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class AdminDisputeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates the status of a dispute and logs the action
  Future<void> updateDisputeStatus({
    required String disputeId,
    required String bookingId,
    required DisputeStatus newStatus,
    required String adminId,
    String? resolutionNote,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // 1. Update Dispute
      transaction.update(_firestore.collection('disputes').doc(disputeId), {
        'status': newStatus.name,
        if (newStatus == DisputeStatus.resolved ||
            newStatus == DisputeStatus.rejected)
          'resolvedAt': FieldValue.serverTimestamp(),
        if (resolutionNote != null) 'decision': resolutionNote,
      });

      // 2. Log Admin Action
      transaction.set(_firestore.collection('admin_actions').doc(), {
        'adminId': adminId,
        'actionType': AdminActionType.disputeResolved.name,
        'bookingId': bookingId,
        'timestamp': FieldValue.serverTimestamp(),
        'reason': resolutionNote ?? 'Status updated to ${newStatus.name}',
      });

      // 3. Log Dispute Event for Timeline
      transaction.set(_firestore.collection('dispute_events').doc(), {
        'bookingId': bookingId,
        'disputeId': disputeId,
        'event': 'STATUS_UPDATED_${newStatus.name.toUpperCase()}',
        'reason': resolutionNote ?? '',
        'performedBy': adminId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 4. Freeze Escrow if needed
      if (newStatus == DisputeStatus.open ||
          newStatus == DisputeStatus.underReview) {
        transaction.update(_firestore.collection('escrow').doc(bookingId), {
          'escrowStatus': EscrowStatus.disputed.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
