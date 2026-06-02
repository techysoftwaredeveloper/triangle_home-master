import 'package:triangle_home/core/constants/enums.dart';

class StateTransitionGuard {
  static const Map<BookingStatus, List<BookingStatus>> _validBookingTransitions = {
    // Initial
    BookingStatus.inquiryCreated: [
      BookingStatus.compatibilityPending,
      BookingStatus.cancelled
    ],

    // Compatibility
    BookingStatus.compatibilityPending: [
      BookingStatus.compatibilityApproved,
      BookingStatus.compatibilityRejected,
      BookingStatus.cancelled
    ],
    BookingStatus.compatibilityApproved: [
      BookingStatus.visitRequested,
      BookingStatus.reservationPending,
      BookingStatus.cancelled
    ],
    BookingStatus.compatibilityRejected: [],

    // Visit
    BookingStatus.visitRequested: [
      BookingStatus.visitScheduled,
      BookingStatus.cancelled
    ],
    BookingStatus.visitScheduled: [
      BookingStatus.visitCompleted,
      BookingStatus.cancelled
    ],
    BookingStatus.visitCompleted: [
      BookingStatus.reservationPending,
      BookingStatus.cancelled
    ],

    // Reservation
    BookingStatus.reservationPending: [
      BookingStatus.reserved,
      BookingStatus.reservationExpired,
      BookingStatus.cancelled
    ],
    BookingStatus.reserved: [
      BookingStatus.paymentPending,
      BookingStatus.reservationExpired,
      BookingStatus.cancelled
    ],
    BookingStatus.reservationExpired: [
      BookingStatus.reservationPending // Allow re-try
    ],

    // Payment
    BookingStatus.paymentPending: [
      BookingStatus.paymentSuccess,
      BookingStatus.paymentFailed,
      BookingStatus.cancelled
    ],
    BookingStatus.paymentSuccess: [
      BookingStatus.hosterApprovalPending
    ],
    BookingStatus.paymentFailed: [
      BookingStatus.paymentPending,
      BookingStatus.cancelled
    ],

    // Hoster Approval
    BookingStatus.hosterApprovalPending: [
      BookingStatus.hosterApproved,
      BookingStatus.hosterRejected
    ],
    BookingStatus.hosterApproved: [
      BookingStatus.bookingConfirmed
    ],
    BookingStatus.hosterRejected: [
      BookingStatus.refunded
    ],

    // Confirmed & Active
    BookingStatus.bookingConfirmed: [
      BookingStatus.checkinPending,
      BookingStatus.cancelled
    ],
    BookingStatus.checkinPending: [
      BookingStatus.checkedIn,
      BookingStatus.cancelled
    ],
    BookingStatus.checkedIn: [
      BookingStatus.checkedOut,
      BookingStatus.disputeOpen
    ],
    BookingStatus.checkedOut: [
      BookingStatus.completed
    ],

    // Special States
    BookingStatus.disputeOpen: [
      BookingStatus.checkedIn,
      BookingStatus.completed,
      BookingStatus.refunded
    ],

    // Terminal
    BookingStatus.completed: [],
    BookingStatus.cancelled: [
      BookingStatus.refunded // If payment was made
    ],
    BookingStatus.refunded: [],
  };

  static const Map<PropertyStatus, List<PropertyStatus>> _validPropertyTransitions = {
    PropertyStatus.pending: [PropertyStatus.approved, PropertyStatus.rejected],
    PropertyStatus.approved: [PropertyStatus.suspended, PropertyStatus.active],
    PropertyStatus.active: [PropertyStatus.suspended],
    PropertyStatus.suspended: [PropertyStatus.active],
    PropertyStatus.rejected: [PropertyStatus.pending], // Allow re-submission
  };

  static bool isValidBookingTransition(BookingStatus current, BookingStatus next) {
    // Basic catch-all: can always go to dispute if not terminal
    if (next == BookingStatus.disputeOpen && 
        current != BookingStatus.completed && 
        current != BookingStatus.cancelled && 
        current != BookingStatus.refunded) {
      return true;
    }

    return _validBookingTransitions[current]?.contains(next) ?? false;
  }

  static bool isValidPropertyTransition(PropertyStatus current, PropertyStatus next) {
    return _validPropertyTransitions[current]?.contains(next) ?? false;
  }
}
