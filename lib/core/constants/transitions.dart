import 'package:triangle_home/core/constants/enums.dart';

class StateTransitionGuard {
  static const Map<BookingStatus, List<BookingStatus>> _validBookingTransitions = {
    BookingStatus.pending: [BookingStatus.approved, BookingStatus.rejected, BookingStatus.cancelled, BookingStatus.expired],
    BookingStatus.approved: [BookingStatus.confirmed, BookingStatus.cancelled, BookingStatus.expired],
    BookingStatus.confirmed: [BookingStatus.checkedIn, BookingStatus.cancelled],
    BookingStatus.checkedIn: [BookingStatus.checkedOut],
    BookingStatus.checkedOut: [],
    BookingStatus.rejected: [],
    BookingStatus.cancelled: [],
    BookingStatus.expired: [],
  };

  static const Map<PropertyStatus, List<PropertyStatus>> _validPropertyTransitions = {
    PropertyStatus.pending: [PropertyStatus.approved, PropertyStatus.rejected],
    PropertyStatus.approved: [PropertyStatus.suspended, PropertyStatus.active],
    PropertyStatus.active: [PropertyStatus.suspended],
    PropertyStatus.suspended: [PropertyStatus.active],
    PropertyStatus.rejected: [PropertyStatus.pending], // Allow re-submission
  };

  static bool isValidBookingTransition(BookingStatus current, BookingStatus next) {
    return _validBookingTransitions[current]?.contains(next) ?? false;
  }

  static bool isValidPropertyTransition(PropertyStatus current, PropertyStatus next) {
    return _validPropertyTransitions[current]?.contains(next) ?? false;
  }
}
