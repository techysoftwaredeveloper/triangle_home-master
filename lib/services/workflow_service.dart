import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/audit_service.dart';
import 'package:triangle_home/services/monitoring_service.dart';

class WorkflowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();
  final MonitoringService _monitoringService = MonitoringService();

  /// Orchestrates the process after a booking is confirmed (usually after payment)
  Future<void> handleBookingConfirmation(String bookingId) async {
    try {
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) return;

      final data = bookingDoc.data()!;
      final propertyId = data['propertyId'];
      final studentPhone = data['userPhone'];

      // 1. Generate Invoice (Dummy implementation for now)
      await _firestore.collection('invoices').add({
        'bookingId': bookingId,
        'studentPhone': studentPhone,
        'amount': data['price'],
        'status': 'paid',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Notify Hoster (Dummy implementation for now)
      await _firestore.collection('notifications').add({
        'userPhone': data['hosterPhone'] ?? '', // Assume this exists in data
        'title': 'New Confirmed Booking',
        'body': 'A student has completed payment for your property.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 3. Log System Event (Standardized)
      await _monitoringService.logSystemEvent(
        SystemEvent.bookingApproved,
        targetId: bookingId,
        extraData: {'propertyId': propertyId},
      );

      // 4. Log Audit
      await _auditService.logAction(
        action: 'workflow_booking_confirmed',
        targetId: bookingId,
        targetType: 'booking',
        extraData: {'propertyId': propertyId},
      );

      await _monitoringService.logEvent('booking_confirmation_workflow_success', params: {'bookingId': bookingId});
    } catch (e, stack) {
      await _monitoringService.logError('Workflow Failure: handleBookingConfirmation', stackTrace: stack.toString(), extra: {'bookingId': bookingId});
    }
  }

  /// Handles the check-out workflow
  Future<void> handleTenantCheckOut(String bookingId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) return;

        final propertyId = bookingDoc.data()?['propertyId'];

        // Update Booking
        transaction.update(bookingRef, {
          'status': BookingStatus.checkedOut.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Decrement Occupancy
        if (propertyId != null) {
          transaction.update(_firestore.collection('properties').doc(propertyId), {
            'currentOccupancy': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      await _auditService.logAction(
        action: 'workflow_checkout_completed',
        targetId: bookingId,
        targetType: 'booking',
      );
    } catch (e, stack) {
      await _monitoringService.logError('Workflow Failure: handleTenantCheckOut', stackTrace: stack.toString(), extra: {'bookingId': bookingId});
    }
  }
}
