import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/core/constants/transitions.dart';
import 'package:triangle_home/core/errors/failures.dart';
import 'package:triangle_home/repositories/booking/booking_repository.dart';
import 'package:triangle_home/services/configuration_service.dart';
import 'package:triangle_home/services/booking_event_service.dart';
import 'package:triangle_home/services/permission_service.dart';
import 'package:triangle_home/services/escrow_service.dart';
import 'package:flutter/foundation.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingRepository _bookingRepo = BookingRepository();
  final ConfigurationService _configService = ConfigurationService();
  final BookingEventService _eventService = BookingEventService();
  final PermissionService _permissionService = PermissionService();
  final EscrowService _escrowService = EscrowService();

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
        return existingBooking
            .docs
            .first
            .id; // Return existing if already processed
      }

      // 2. Perform Atomic Transaction for Availability & Creation
      final String bookingId = await _firestore.runTransaction((
        transaction,
      ) async {
        final propertyDoc = await transaction.get(
          _firestore.collection('properties').doc(propertyId),
        );

        if (!propertyDoc.exists) {
          throw const BookingFailure(
            'Property not found',
            code: ErrorCodes.propertyNotFound,
          );
        }

        final data = propertyDoc.data()!;
        final int capacity = data['capacity'] ?? 0;
        final int currentOccupancy = data['currentOccupancy'] ?? 0;

        if (currentOccupancy >= capacity) {
          throw const BookingFailure(
            'No beds available',
            code: ErrorCodes.roomFull,
          );
        }

        final timeout = _configService.bookingTimeoutMinutes;

        // Create booking doc
        final newBookingRef = _firestore.collection('bookings').doc();
        transaction.set(newBookingRef, {
          ...bookingData,
          'property_id': propertyId,
          'user_id': studentId,
          'request_id': requestId,
          'status': BookingStatus.inquiryCreated.name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'expiryTime': Timestamp.fromDate(
            DateTime.now().add(Duration(minutes: timeout)),
          ),
        });

        return newBookingRef.id;
      });

      // 3. Log initial event
      await _eventService.logEvent(
        bookingId: bookingId,
        newStatus: BookingStatus.inquiryCreated,
        performerId: studentId,
      );

      return bookingId;
    } catch (e) {
      if (e is Failure) rethrow;
      throw BookingFailure('Booking request failed: $e');
    }
  }

  /// Updates booking status with transition guards and atomic occupancy management
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus, {
    String? reason,
    String? performerId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw const BookingFailure('Booking not found');
        }

        final currentStatusName =
            bookingDoc.data()?['status'] as String? ?? 'inquiryCreated';
        final currentStatus = BookingStatus.values.firstWhere(
          (e) => e.name == currentStatusName,
          orElse: () => BookingStatus.inquiryCreated,
        );

        // 1. Validate Transition
        if (!StateTransitionGuard.isValidBookingTransition(
          currentStatus,
          newStatus,
        )) {
          throw BookingFailure(
            'Invalid status transition from $currentStatusName to ${newStatus.name}',
          );
        }

        // 2. Handle Occupancy & Bed Inventory Side Effects
        final propertyId = bookingDoc.data()?['property_id'] as String?;
        final roomId = bookingDoc.data()?['roomId'] as String?;
        final bedId = bookingDoc.data()?['bedId'] as String?;

        if (propertyId != null) {
          final propertyRef = _firestore
              .collection('properties')
              .doc(propertyId);

          // SOURCE OF TRUTH: Bed Inventory
          if (bedId != null && roomId != null) {
            final bedRef = propertyRef
                .collection('rooms')
                .doc(roomId)
                .collection('beds')
                .doc(bedId);
            final bedDoc = await transaction.get(bedRef);

            if (!bedDoc.exists) {
              throw const BookingFailure('Bed not found in inventory');
            }

            final bedStatus = bedDoc.data()?['status'];

            // Transition: Confirming Booking
            if (newStatus == BookingStatus.bookingConfirmed &&
                currentStatus != BookingStatus.bookingConfirmed) {
              if (bedStatus != BedStatus.available.name &&
                  bedStatus != BedStatus.reserved.name) {
                throw const BookingFailure('Bed is no longer available');
              }
              transaction.update(bedRef, {
                'status': BedStatus.booked.name,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              // Cache update on property
              transaction.update(propertyRef, {
                'currentOccupancy': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }

            // Transition: Checking In
            if (newStatus == BookingStatus.checkedIn &&
                currentStatus != BookingStatus.checkedIn) {
              transaction.update(bedRef, {
                'status': BedStatus.occupied.name,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }

            // Transition: Cancellation/Checkout
            if ((newStatus == BookingStatus.cancelled &&
                    currentStatus == BookingStatus.bookingConfirmed) ||
                (newStatus == BookingStatus.checkedOut &&
                    currentStatus == BookingStatus.checkedIn) ||
                (newStatus == BookingStatus.reservationExpired)) {
              transaction.update(bedRef, {
                'status': BedStatus.available.name,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              transaction.update(propertyRef, {
                'currentOccupancy': FieldValue.increment(-1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          } else {
            // Fallback for property-level only occupancy if no bed selected
            if (newStatus == BookingStatus.bookingConfirmed &&
                currentStatus != BookingStatus.bookingConfirmed) {
              transaction.update(propertyRef, {
                'currentOccupancy': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            if ((newStatus == BookingStatus.cancelled &&
                    currentStatus == BookingStatus.bookingConfirmed) ||
                (newStatus == BookingStatus.checkedOut &&
                    currentStatus == BookingStatus.checkedIn)) {
              transaction.update(propertyRef, {
                'currentOccupancy': FieldValue.increment(-1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          // If checking in, set release eligibility on escrow
          if (newStatus == BookingStatus.checkedIn) {
            transaction.update(_firestore.collection('escrow').doc(bookingId), {
              'releaseEligibleAt': Timestamp.fromDate(
                DateTime.now().add(const Duration(hours: 48)),
              ),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // 3. Update Booking
        transaction.update(bookingRef, {
          'status': newStatus.name,
          if (newStatus == BookingStatus.checkedIn)
            'checkedInAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // 4. Handle Financial Side Effects
      if (newStatus == BookingStatus.paymentSuccess) {
        final bookingDoc =
            await _firestore.collection('bookings').doc(bookingId).get();
        final data = bookingDoc.data()!;
        await _escrowService.createEscrow(
          bookingId: bookingId,
          deposit: (data['pricing_breakdown']?['deposit'] ?? 0).toDouble(),
          rent: (data['pricing_breakdown']?['rent'] ?? 0).toDouble(),
          platformFee:
              (data['pricing_breakdown']?['serviceFee'] ?? 0).toDouble(),
        );
      }

      // 5. Handle Permission Unlocking (Side Effect)
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      final userId = bookingDoc.data()?['user_id'];
      final propertyId = bookingDoc.data()?['property_id'];

      if (userId != null && propertyId != null) {
        if (_permissionService.canViewPrivateUI(newStatus)) {
          await _permissionService.grantPrivateAccess(
            propertyId: propertyId,
            userId: userId,
            bookingId: bookingId,
          );
        } else if (newStatus == BookingStatus.cancelled ||
            newStatus == BookingStatus.reservationExpired ||
            newStatus == BookingStatus.refunded) {
          await _permissionService.revokePrivateAccess(propertyId, userId);
        }
      }

      // 5. Log the audit event
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

  Stream<QuerySnapshot<Map<String, dynamic>>> getHosterBookings(
    String hosterId,
  ) {
    return _firestore
        .collection('bookings')
        .where('hoster_id', isEqualTo: hosterId)
        .orderBy('createdAt', descending: true)
        .snapshots();
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
