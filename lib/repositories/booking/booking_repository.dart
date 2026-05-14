import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/core/errors/failures.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> getBooking(String id) async {
    try {
      return await _firestore.collection('bookings').doc(id).get();
    } on FirebaseException catch (e) {
      throw BookingFailure('Failed to fetch booking: ${e.message}', code: e.code);
    } catch (e) {
      throw BookingFailure('Unexpected error fetching booking: $e');
    }
  }

  Future<void> updateStatus(String id, BookingStatus status) async {
    try {
      await _firestore.collection('bookings').doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw BookingFailure('Failed to update booking status: ${e.message}', code: e.code);
    } catch (e) {
      throw BookingFailure('Unexpected error updating booking status: $e');
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> findByIdempotency(String requestId) async {
    try {
      return await _firestore
          .collection('bookings')
          .where('request_id', isEqualTo: requestId)
          .limit(1)
          .get();
    } on FirebaseException catch (e) {
      throw BookingFailure('Idempotency check failed: ${e.message}', code: e.code);
    } catch (e) {
      throw BookingFailure('Unexpected error during idempotency check: $e');
    }
  }

  Query<Map<String, dynamic>> getStudentBookingsQuery(String userId) {
    return _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: userId)
        .orderBy('createdAt', descending: true);
  }
}
