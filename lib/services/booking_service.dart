import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/core/errors/failures.dart';
import 'package:triangle_home/repositories/booking/booking_repository.dart';
import 'package:triangle_home/services/admin_api_service.dart';
import 'package:triangle_home/services/booking_event_service.dart';
import 'package:flutter/foundation.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingRepository _bookingRepo = BookingRepository();
  final BookingEventService _eventService = BookingEventService();
  final AdminApiService _apiService = AdminApiService();

  // ==================== BOOKING ACTIONS ====================

  /// Creates a booking via the API
  Future<String> requestBooking({
    required String propertyId,
    required String studentId,
    required String requestId, // For idempotency
    required Map<String, dynamic> bookingData,
    String? roomId,
    String? bedId,
    Map<String, dynamic>? breakdown,
    String? moveInDate,
    String? floor,
    String? roomName,
    String? bedName,
  }) async {
    try {
      final response = await _apiService.performRequest(
        method: 'POST',
        endpoint: '/bookings',
        body: {
          'propertyId': propertyId,
          'requestId': requestId,
          'roomId': roomId,
          'bedId': bedId,
          'breakdown': breakdown,
          'moveInDate': moveInDate,
          'floor': floor,
          'roomName': roomName,
          'bedName': bedName,
          ...bookingData,
        },
      );

      if (response['success'] == true) {
        // Log event locally for UI if needed, though server might also log
        final bookingId = response['id'] ?? '';
        await _eventService.logEvent(
          bookingId: bookingId,
          newStatus: BookingStatus.inquiryCreated,
          performerId: studentId,
        );
        return bookingId;
      } else {
        throw BookingFailure(response['error'] ?? 'Failed to request booking');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw BookingFailure('Booking request failed: $e');
    }
  }

  /// Updates booking status via the API
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus, {
    String? reason,
    String? performerId,
  }) async {
    try {
      final response = await _apiService.performRequest(
        method: 'PATCH',
        endpoint: '/bookings/$bookingId/status',
        body: {
          'status': newStatus.name,
          'reason': reason,
        },
      );

      if (response['success'] != true) {
        throw BookingFailure(response['error'] ?? 'Failed to update booking status');
      }

      // Log the audit event locally
      await _eventService.logEvent(
        bookingId: bookingId,
        newStatus: newStatus,
        reason: reason,
        performerId: performerId,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw BookingFailure('Failed to update booking status: $e');
    }
  }

  // ==================== QUERIES & MAINTENANCE ====================

  /// Checks and cancels bookings that have expired without payment
  Future<void> cancelExpiredBookings() async {
    try {
      final now = Timestamp.now();
      final expiredBookings =
          await _firestore
              .collection('bookings')
              .where('status', isEqualTo: BookingStatus.reservationPending.name)
              .where('expiryTime', isLessThan: now)
              .get();

      for (final doc in expiredBookings.docs) {
        await updateBookingStatus(doc.id, BookingStatus.reservationExpired);
      }
    } catch (e) {
      debugPrint('Failed to cancel expired bookings: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getStudentBookings(
    String studentId,
  ) {
    return _bookingRepo.getStudentBookingsQuery(studentId).snapshots();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getHosterBookings(
    String hosterId,
  ) {
    final snake = _firestore
        .collection('bookings')
        .where('hoster_id', isEqualTo: hosterId)
        .snapshots();
    final camel = _firestore
        .collection('bookings')
        .where('hosterId', isEqualTo: hosterId)
        .snapshots();

    return Rx.combineLatest2(snake, camel, (a, b) {
      final seen = <String>{};
      final merged = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in [...a.docs, ...b.docs]) {
        if (seen.add(doc.id)) {
          merged.add(doc);
        }
      }
      merged.sort((x, y) {
        final xTime = x.data()['createdAt'] as Timestamp?;
        final yTime = y.data()['createdAt'] as Timestamp?;
        if (xTime == null || yTime == null) return 0;
        return yTime.compareTo(xTime);
      });
      return merged;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPropertyBookings(
    String propertyId,
  ) {
    return _firestore
        .collection('bookings')
        .where('property_id', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getBookingById(String id) async {
    final doc = await _bookingRepo.getBooking(id);
    return doc.data();
  }
}
