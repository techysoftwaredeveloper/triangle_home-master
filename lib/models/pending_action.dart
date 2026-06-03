import 'package:isar/isar.dart';

part 'pending_action.g.dart';

@collection
class PendingAction {
  Id id = Isar.autoIncrement;

  String actionId;
  String
  type; // e.g., 'BOOKING_CONFIRM', 'PAYMENT_VERIFY', 'MAINTENANCE_CREATE'
  String payload; // JSON payload
  int retryCount;
  DateTime createdAt;

  PendingAction({
    required this.actionId,
    required this.type,
    required this.payload,
    this.retryCount = 0,
    required this.createdAt,
  });
}
