enum BookingStatus {
  pending,
  approved,
  confirmed,
  rejected,
  cancelled,
  checkedIn,
  checkedOut,
  expired
}

enum PropertyStatus {
  pending,
  approved,
  rejected,
  suspended,
  active
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
  partiallyPaid
}

enum PaymentType {
  rent,
  deposit,
  maintenance,
  other
}

enum UserRole {
  student,
  hoster,
  admin,
  guest
}

enum HosterStatus {
  pending,
  approved,
  rejected,
  suspended
}

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
