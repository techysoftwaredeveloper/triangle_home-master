import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class BookingEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Logs an immutable event for a booking status change
  Future<void> logEvent({
    required String bookingId,
    required BookingStatus newStatus,
    String? reason,
    String? performerId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await _firestore.collection('booking_events').add({
        'booking_id': bookingId,
        'event': newStatus.name,
        'status': newStatus.name,
        'reason': reason ?? '',
        'performed_by': performerId ?? 'system',
        'timestamp': FieldValue.serverTimestamp(),
        if (extraData != null) 'data': extraData,
      });
    } catch (e) {
      print('Failed to log booking event: $e');
    }
  }

  /// Gets the history of events for a specific booking
  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingHistory(String bookingId) {
    return _firestore
        .collection('booking_events')
        .where('booking_id', isEqualTo: bookingId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
