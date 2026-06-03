import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:triangle_home/core/constants/enums.dart';

class TimelineAggregatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Unifies all audit trails for a specific booking into a single chronological stream
  Stream<List<TimelineEvent>> getUnifiedTimeline(String bookingId) {
    // 1. Booking Events
    final bookingEvents =
        _firestore
            .collection('booking_events')
            .where('booking_id', isEqualTo: bookingId)
            .snapshots();

    // 2. Financial Events
    final financialEvents =
        _firestore
            .collection('financial_events')
            .where('bookingId', isEqualTo: bookingId)
            .snapshots();

    // 3. Payment Events (Indexed by bookingId for this aggregator)
    final paymentEvents =
        _firestore
            .collection('payment_events')
            .where('bookingId', isEqualTo: bookingId)
            .snapshots();

    // 4. Dispute Events
    final disputeEvents =
        _firestore
            .collection('dispute_events')
            .where('bookingId', isEqualTo: bookingId)
            .snapshots();

    // 5. Admin Actions
    final adminActions =
        _firestore
            .collection('admin_actions')
            .where('bookingId', isEqualTo: bookingId)
            .snapshots();

    return Rx.combineLatest5(
      bookingEvents,
      financialEvents,
      paymentEvents,
      disputeEvents,
      adminActions,
      (
        QuerySnapshot bSnap,
        QuerySnapshot fSnap,
        QuerySnapshot pSnap,
        QuerySnapshot dSnap,
        QuerySnapshot aSnap,
      ) {
        final List<TimelineEvent> events = [];

        // Map Booking Events
        for (var doc in bSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final eventName = data['event']?.toString().toLowerCase() ?? '';
          events.add(
            TimelineEvent(
              title: data['event'] ?? 'Status Change',
              description: data['reason'] ?? '',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              performer: data['performed_by'] ?? 'System',
              category: TimelineCategory.booking,
              severity: _getBookingSeverity(eventName),
            ),
          );
        }

        // Map Financial Events
        for (var doc in fSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final eventName = data['event']?.toString().toLowerCase() ?? '';
          events.add(
            TimelineEvent(
              title: data['event'] ?? 'Financial Update',
              description: 'Amount: ₹${data['amount'] ?? 0}',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              performer: data['performedBy'] ?? 'System',
              category: TimelineCategory.financial,
              severity: _getFinancialSeverity(eventName),
            ),
          );
        }

        // Map Payment Events
        for (var doc in pSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          events.add(
            TimelineEvent(
              title: data['event'] ?? 'Gateway Event',
              description: data['status'] ?? '',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              performer: 'Razorpay',
              category: TimelineCategory.payment,
              severity:
                  data['event']?.toString().contains('FAILED') == true
                      ? TimelineSeverity.critical
                      : TimelineSeverity.info,
            ),
          );
        }

        // Map Dispute Events
        for (var doc in dSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          events.add(
            TimelineEvent(
              title: data['event'] ?? 'Dispute Update',
              description: data['reason'] ?? '',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              performer: data['performedBy'] ?? 'User',
              category: TimelineCategory.dispute,
              severity: TimelineSeverity.warning,
            ),
          );
        }

        // Map Admin Actions
        for (var doc in aSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          events.add(
            TimelineEvent(
              title: data['actionType'] ?? 'Admin Action',
              description: data['reason'] ?? '',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              performer: data['adminId'] ?? 'Admin',
              category: TimelineCategory.admin,
              severity: TimelineSeverity.info,
            ),
          );
        }

        events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return events;
      },
    );
  }

  TimelineSeverity _getBookingSeverity(String event) {
    if (event.contains('rejected') ||
        event.contains('cancelled') ||
        event.contains('expired')) {
      return TimelineSeverity.warning;
    }
    return TimelineSeverity.info;
  }

  TimelineSeverity _getFinancialSeverity(String event) {
    if (event.contains('refund')) return TimelineSeverity.critical;
    if (event.contains('released')) return TimelineSeverity.info;
    return TimelineSeverity.info;
  }
}

enum TimelineCategory { booking, payment, financial, dispute, admin }

class TimelineEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final String performer;
  final TimelineCategory category;
  final TimelineSeverity severity;

  TimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.performer,
    required this.category,
    required this.severity,
  });
}
