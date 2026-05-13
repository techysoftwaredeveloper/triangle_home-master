class Failure {
  final String message;
  final String code;

  const Failure(this.message, {this.code = 'UNKNOWN_ERROR'});

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code = 'AUTH_ERROR'});
}

class BookingFailure extends Failure {
  const BookingFailure(super.message, {super.code = 'BOOKING_ERROR'});
}

class PropertyFailure extends Failure {
  const PropertyFailure(super.message, {super.code = 'PROPERTY_ERROR'});
}

class PaymentFailure extends Failure {
  const PaymentFailure(super.message, {super.code = 'PAYMENT_ERROR'});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code = 'SERVER_ERROR'});
}

// Specific Error Codes
class ErrorCodes {
  static const String bedAlreadyOccupied = 'BED_ALREADY_OCCUPIED';
  static const String roomFull = 'ROOM_FULL';
  static const String bookingExpired = 'BOOKING_EXPIRED';
  static const String paymentFailed = 'PAYMENT_FAILED';
  static const String unauthorizedHoster = 'UNAUTHORIZED_HOSTER';
  static const String insufficientPermissions = 'INSUFFICIENT_PERMISSIONS';
  static const String propertyNotFound = 'PROPERTY_NOT_FOUND';
  static const String userNotFound = 'USER_NOT_FOUND';
}
