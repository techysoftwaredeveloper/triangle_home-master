import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/core/constants/transitions.dart';
import 'package:triangle_home/core/errors/failures.dart';
import 'package:triangle_home/repositories/booking/booking_repository.dart';
import 'package:triangle_home/repositories/property/property_repository.dart';
import 'package:triangle_home/services/configuration_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingRepository _bookingRepo = BookingRepository();
  final PropertyRepository _propertyRepo = PropertyRepository();
  final ConfigurationService _configService = ConfigurationService();

  // ==================== BOOKING ACTIONS ====================

  /// Creates a booking with idempotency and availability check
  Future<String> requestBooking({
    required String propertyId,
    required String studentId,
    required String requestId, // For idempotency
    required Map<String, dynamic> bookingData,
  }) async {
    try {
      // 1. Check Idempotency first
      final existingBooking = await _bookingRepo.findByIdempotency(requestId);

      if (existingBooking.docs.isNotEmpty) {
        return existingBooking.docs.first.id; // Return existing if already processed
      }

      // 2. Perform Atomic Transaction for Availability & Creation
      return await _firestore.runTransaction((transaction) async {
        final propertyDoc = await transaction.get(_firestore.collection('properties').doc(propertyId));

        if (!propertyDoc.exists) {
          throw const BookingFailure('Property not found', code: ErrorCodes.propertyNotFound);
        }

        final data = propertyDoc.data()!;
        final int capacity = data['capacity'] ?? 0;
        final int currentOccupancy = data['currentOccupancy'] ?? 0;

        if (currentOccupancy >= capacity) {
          throw const BookingFailure('No beds available', code: ErrorCodes.roomFull);
        }

        final timeout = _configService.bookingTimeoutMinutes;

        // Create booking doc
        final newBookingRef = _firestore.collection('bookings').doc();
        transaction.set(newBookingRef, {
          ...bookingData,
          'property_id': propertyId,
          'user_id': studentId,
          'request_id': requestId,
          'status': BookingStatus.pending.name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'expiryTime': Timestamp.fromDate(DateTime.now().add(Duration(minutes: timeout))),
        });

        return newBookingRef.id;
      });
    } catch (e) {
      if (e is Failure) rethrow;
      throw BookingFailure('Booking request failed: $e');
    }
  }

  /// Updates booking status with transition guards and atomic occupancy management
  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw const BookingFailure('Booking not found');
        }

        final currentStatusName = bookingDoc.data()?['status'] as String? ?? 'pending';
        final currentStatus = BookingStatus.values.firstWhere((e) => e.name == currentStatusName, orElse: () => BookingStatus.pending);

        // 1. Validate Transition
        if (!StateTransitionGuard.isValidBookingTransition(currentStatus, newStatus)) {
          throw BookingFailure('Invalid status transition from $currentStatusName to ${newStatus.name}');
        }

        // 2. Handle Occupancy Side Effects
        final propertyId = bookingDoc.data()?['property_id'] as String?;
        if (propertyId != null) {
          final propertyRef = _firestore.collection('properties').doc(propertyId);

          // If becoming confirmed, increment occupancy
          if (newStatus == BookingStatus.confirmed && currentStatus != BookingStatus.confirmed) {
            transaction.update(propertyRef, {
              'currentOccupancy': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // If cancelling from confirmed or checking out, decrement occupancy
          if ((newStatus == BookingStatus.cancelled && currentStatus == BookingStatus.confirmed) ||
              (newStatus == BookingStatus.checkedOut && currentStatus == BookingStatus.checkedIn)) {
            transaction.update(propertyRef, {
              'currentOccupancy': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // 3. Update Booking
        transaction.update(bookingRef, {
          'status': newStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
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
      final expiredBookings = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: BookingStatus.pending.name)
          .where('expiryTime', isLessThan: now)
          .get();

      for (final doc in expiredBookings.docs) {
        await updateBookingStatus(doc.id, BookingStatus.expired);
      }
    } catch (e) {
      print('Failed to cancel expired bookings: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getStudentBookings(String studentId) {
    return _bookingRepo.getStudentBookingsQuery(studentId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getHosterBookings(String hosterId) {
    return _firestore
        .collection('bookings')
        .where('hoster_id', isEqualTo: hosterId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getBookingById(String id) async {
    final doc = await _bookingRepo.getBooking(id);
    return doc.data();
  }
}
