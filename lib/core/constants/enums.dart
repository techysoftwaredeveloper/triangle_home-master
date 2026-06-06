enum BookingStatus {
  // Initial
  inquiryCreated,

  // Compatibility
  compatibilityPending,
  compatibilityApproved,
  compatibilityRejected,

  // Visit
  visitRequested,
  visitScheduled,
  visitCompleted,

  // Reservation
  reservationPending,
  reserved,
  reservationExpired,

  // Payment
  paymentPending,
  paymentSuccess,
  paymentFailed,

  // Hoster Approval
  hosterApprovalPending,
  hosterApproved,
  hosterRejected,

  // Confirmed & Active
  bookingConfirmed, // Data Unlocked at this stage
  checkinPending,
  checkedIn,
  checkedOut,

  // Special States
  disputeOpen,

  // Final Terminal States
  completed,
  cancelled,
  refunded,
  approved,
  pending,
  confirmed,
}

enum PropertyStatus { pending, approved, rejected, suspended, active, paused }

enum PaymentStatus { pending, completed, failed, refunded, partiallyPaid }

enum PaymentType { reservationFee, rent, deposit, platformFee, refund, other }

enum TransactionStatus {
  created,
  pending,
  verificationPending,
  success,
  failed,
  refunded,
  partialRefund,
}

enum TransactionType {
  reservationFee,
  deposit,
  firstMonthRent,
  serviceFee,
  refund,
  payout,
}

enum EscrowStatus {
  held,
  readyForPayout,
  payoutRequested,
  payoutApproved,
  payoutReleased,
  disputed,
  refunded,
}

enum FinancialEventType {
  paymentReceived,
  escrowCreated,
  payoutRequested,
  payoutReleased,
  refundInitiated,
  refundCompleted,
}

enum UserRole { student, hoster, admin, guest }

enum DisputeStatus {
  open,
  underReview,
  waitingForUser,
  waitingForHoster,
  resolved,
  rejected,
}

enum RefundStatus { requested, approved, processing, completed, failed }

enum BedStatus { available, reserved, booked, occupied, maintenance, blocked }

enum RoomType { single, double, triple, dormitory }

enum CheckInStatus { pending, verified, expired, cancelled }

enum CheckInMethod { qr, otp }

enum StayStatus {
  active,
  noticeSubmitted,
  checkoutPending,
  inspectionPending,
  settlementPending,
  completed,
  terminated,
}

enum RentStatus { pending, paid, overdue, waived }

enum NoticeStatus { pending, approved, rejected, withdrawn }

enum InspectionCondition { excellent, good, damaged }

enum DepositStatus { pending, proposed, approved, processed, disputed }

enum CheckoutStatus {
  none,
  noticeSubmitted,
  inspectionPending,
  settlementPending,
  awaitingResidentApproval,
  completed,
}

enum AttachmentType { image, video, document }

enum TicketCategory {
  electrical,
  plumbing,
  cleaning,
  internet,
  furniture,
  food,
  security,
  other,
}

enum TicketPriority { low, medium, high, emergency }

enum TicketStatus { open, assigned, inProgress, resolved, closed, reopened }

enum MaintenanceEventType {
  ticketCreated,
  ticketAssigned,
  ticketResolved,
  ticketReopened,
  slaBreached,
}

enum AdminActionType {
  payoutReleased,
  disputeResolved,
  bookingCancelled,
  refundApproved,
  userSuspended,
}

enum InventoryEventType {
  bedCreated,
  bedReserved,
  bedOccupied,
  bedReleased,
  roomCreated,
  roomDeleted,
  statusChanged,
}

enum TimelineSeverity { info, warning, critical }

extension BookingStatusX on BookingStatus {
  String get name => toString().split('.').last;
}

extension PropertyStatusX on PropertyStatus {
  String get name => toString().split('.').last;
}

extension PaymentStatusX on PaymentStatus {
  String get name => toString().split('.').last;
}

extension UserRoleX on UserRole {
  String get name => toString().split('.').last;
}
