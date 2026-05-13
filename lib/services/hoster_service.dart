import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class HosterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getHosterStats(String hosterId) async {
    final properties = await _firestore
        .collection('properties')
        .where('hosterId', isEqualTo: hosterId)
        .get();

    final bookings = await _firestore
        .collection('bookings')
        .where('hosterId', isEqualTo: hosterId)
        .get();

    final payments = await _firestore
        .collection('payments')
        .where('hosterId', isEqualTo: hosterId)
        .get();

    double totalEarnings = 0;
    for (var doc in payments.docs) {
      totalEarnings += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalProperties': properties.docs.length,
      'totalBookings': bookings.docs.length,
      'totalEarnings': totalEarnings,
      'pendingBookings': bookings.docs
          .where((doc) => doc.data()['status'] == BookingStatus.pending.name)
          .length,
    };
  }
}
