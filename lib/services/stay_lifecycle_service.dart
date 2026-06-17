import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/lifecycle_models.dart';

class StayLifecycleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ==================== NOTICE WORKFLOW ====================

  /// Submits a move-out notice for an active stay
  Future<void> submitMoveOutNotice(
    String stayId,
    DateTime requestedDate,
    String reason,
  ) async {
    final stayRef = _firestore.collection('resident_stays').doc(stayId);

    await _firestore.runTransaction((transaction) async {
      final stayDoc = await transaction.get(stayRef);
      if (!stayDoc.exists ||
          stayDoc.data()?['status'] != StayStatus.active.name) {
        throw 'Notice can only be submitted for active stays';
      }

      final noticeRef = _firestore.collection('notice_requests').doc();
      transaction.set(noticeRef, {
        'stayId': stayId,
        'noticeDate': FieldValue.serverTimestamp(),
        'requestedMoveOutDate': Timestamp.fromDate(requestedDate),
        'reason': reason,
        'status': NoticeStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(stayRef, {
        'status': StayStatus.noticeSubmitted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log to timeline
      _logTimelineEvent(
        transaction,
        stayId,
        'NOTICE_SUBMITTED',
        'Requested: ${requestedDate.toIso8601String()}',
      );
    });
  }

  // ==================== VALIDATION ENGINE ====================

  /// Validates if a resident is eligible for final checkout
  Future<CheckoutValidationResult> validateCheckout(String stayId) async {
    final stayDoc =
        await _firestore.collection('resident_stays').doc(stayId).get();
    if (!stayDoc.exists) {
      return CheckoutValidationResult(
        canCheckout: false,
        reason: 'Stay not found',
      );
    }

    // Validate the stay document is present (data not needed directly here)
    // 1. Check Overdue Rent
    final overdueRent =
        await _firestore
            .collection('rent_cycles')
            .where('stayId', isEqualTo: stayId)
            .where('status', isEqualTo: RentStatus.overdue.name)
            .get();
    if (overdueRent.docs.isNotEmpty) {
      return CheckoutValidationResult(
        canCheckout: false,
        reason: 'Outstanding rent payments found',
      );
    }

    // 2. Check Open Maintenance Tickets
    final openTickets =
        await _firestore
            .collection('maintenance_tickets')
            .where('stayId', isEqualTo: stayId)
            .where(
              'status',
              whereIn: [
                TicketStatus.open.name,
                TicketStatus.assigned.name,
                TicketStatus.inProgress.name,
              ],
            )
            .get();
    if (openTickets.docs.isNotEmpty) {
      return CheckoutValidationResult(
        canCheckout: false,
        reason: 'Unresolved maintenance tickets exist',
      );
    }

    // 3. Check Inspection Status
    final inspection =
        await _firestore
            .collection('checkout_inspections')
            .where('stayId', isEqualTo: stayId)
            .limit(1)
            .get();
    if (inspection.docs.isEmpty) {
      return CheckoutValidationResult(
        canCheckout: false,
        reason: 'Room inspection not completed',
      );
    }

    return CheckoutValidationResult(canCheckout: true);
  }

  // ==================== FINALIZATION ORCHESTRATOR ====================

  /// Finalizes the checkout process atomically
  Future<void> finalizeCheckout({
    required String stayId,
    required DepositRecord settlement,
    required String performedBy,
  }) async {
    final stayRef = _firestore.collection('resident_stays').doc(stayId);

    await _firestore.runTransaction((transaction) async {
      final stayDoc = await transaction.get(stayRef);
      final sData = stayDoc.data()!;

      // 1. Record Settlement
      final depositRef = _firestore.collection('deposit_records').doc();
      transaction.set(depositRef, {
        ...settlement.toFirestore(),
        'status': DepositStatus.approved.name,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Stay Status
      transaction.update(stayRef, {
        'status': StayStatus.completed.name,
        'checkOutDate': FieldValue.serverTimestamp(),
        'checkoutCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. TRIGGER BED RELEASE WORKFLOW
      // We call the inventory service logic manually here to ensure it's in the SAME transaction
      final propertyId = sData['propertyId'];
      final roomId = sData['roomId'];
      final bedId = sData['bedId'];

      final bedRef = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('rooms')
          .doc(roomId)
          .collection('beds')
          .doc(bedId);
      final roomRef = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('rooms')
          .doc(roomId);
      final propRef = _firestore.collection('properties').doc(propertyId);

      transaction.update(bedRef, {
        'status': BedStatus.available.name,
        'currentResidentId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(roomRef, {
        'occupiedBeds': FieldValue.increment(-1),
        'availableBeds': FieldValue.increment(1),
      });

      transaction.update(propRef, {
        'occupiedBeds': FieldValue.increment(-1),
        'availableBeds': FieldValue.increment(1),
      });

      // 4. Audit Trail
      _logTimelineEvent(
        transaction,
        stayId,
        'CHECKOUT_COMPLETED',
        'Performed by: $performedBy',
      );
      _logTimelineEvent(
        transaction,
        stayId,
        'BED_RELEASED',
        'Bed $bedId is now available',
      );
    });
  }

  // ==================== HELPERS ====================

  void _logTimelineEvent(
    Transaction transaction,
    String stayId,
    String event,
    String note,
  ) {
    final eventRef = _firestore.collection('stay_events').doc();
    transaction.set(eventRef, {
      'stayId': stayId,
      'event': event,
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Calculates final settlement amounts
  Map<String, double> calculateSettlement(
    double originalDeposit,
    List<DepositDeduction> deductions,
  ) {
    double totalDeduction = 0;
    for (var d in deductions) {
      totalDeduction += d.amount;
    }
    double refund = originalDeposit - totalDeduction;
    return {
      'deductionTotal': totalDeduction,
      'refundAmount': refund < 0 ? 0 : refund,
    };
  }
}

class CheckoutValidationResult {
  final bool canCheckout;
  final String? reason;
  CheckoutValidationResult({required this.canCheckout, this.reason});
}
