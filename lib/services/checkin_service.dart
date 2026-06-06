import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a secure check-in session for a confirmed booking
  Future<void> generateCheckInSession(String bookingId) async {
    final bookingDoc =
        await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) throw 'Booking not found';

    final data = bookingDoc.data()!;
    if (data['status'] != BookingStatus.bookingConfirmed.name) {
      throw 'Check-in only available for confirmed bookings';
    }

    final String otp = (100000 + Random().nextInt(900000)).toString();
    final expiry = DateTime.now().add(const Duration(hours: 24));

    await _firestore.collection('checkins').doc(bookingId).set({
      'bookingId': bookingId,
      'propertyId': data['property_id'],
      'roomId': data['roomId'],
      'bedId': data['bedId'],
      'residentId': data['user_id'],
      'hostId': data['hoster_id'],
      'method': CheckInMethod.qr.name,
      'status': CheckInStatus.pending.name,
      'otpCode': otp,
      'expiresAt': Timestamp.fromDate(expiry),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verifies a QR check-in (Scanned by Resident from Hoster's device)
  Future<void> verifyQrCheckIn(String bookingId, String scannedByUid) async {
    final checkInDoc =
        await _firestore.collection('checkins').doc(bookingId).get();
    if (!checkInDoc.exists) throw 'Check-in session not found';

    final data = checkInDoc.data()!;
    if (data['residentId'] != scannedByUid) {
      throw 'Invalid resident for this check-in';
    }
    if (data['status'] != CheckInStatus.pending.name) {
      throw 'Check-in already processed';
    }
    if ((data['expiresAt'] as Timestamp).toDate().isBefore(DateTime.now())) {
      throw 'Check-in session expired';
    }

    await _performCheckInHandshake(bookingId, CheckInMethod.qr);
  }

  /// Verifies an OTP check-in (Entered by Hoster from Resident's app)
  Future<void> verifyOtpCheckIn(String bookingId, String enteredOtp) async {
    final checkInDoc =
        await _firestore.collection('checkins').doc(bookingId).get();
    if (!checkInDoc.exists) throw 'Check-in session not found';

    final data = checkInDoc.data()!;
    if (data['otpCode'] != enteredOtp) throw 'Invalid OTP code';
    if (data['status'] != CheckInStatus.pending.name) {
      throw 'Check-in already processed';
    }

    await _performCheckInHandshake(bookingId, CheckInMethod.otp);
  }

  /// Atomic operation to finalize check-in and activate residency
  Future<void> _performCheckInHandshake(
    String bookingId,
    CheckInMethod method,
  ) async {
    await _firestore.runTransaction((transaction) async {
      final checkInRef = _firestore.collection('checkins').doc(bookingId);
      final bookingRef = _firestore.collection('bookings').doc(bookingId);

      final bookingDoc = await transaction.get(bookingRef);
      final bData = bookingDoc.data()!;

      // 1. Update Check-In Session
      transaction.update(checkInRef, {
        'status': CheckInStatus.verified.name,
        'method': method.name,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // 2. Trigger Resident Activation
      await _activateResidentLogic(transaction, bookingId, bData);

      // 3. Update Booking Status via standard service logic (nested call simulation)
      transaction.update(bookingRef, {
        'status': BookingStatus.checkedIn.name,
        'checkedInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _activateResidentLogic(
    Transaction transaction,
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    final stayRef = _firestore.collection('resident_stays').doc();
    final escrowRef = _firestore.collection('escrow').doc(bookingId);
    final bedRef = _firestore
        .collection('properties')
        .doc(data['property_id'])
        .collection('rooms')
        .doc(data['roomId'])
        .collection('beds')
        .doc(data['bedId']);

    // A. Create Residency Record
    transaction.set(stayRef, {
      'residentId': data['user_id'],
      'bookingId': bookingId,
      'propertyId': data['property_id'],
      'roomId': data['roomId'],
      'bedId': data['bedId'],
      'checkInDate': FieldValue.serverTimestamp(),
      'status': StayStatus.active.name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // B. Update Bed Status to Occupied
    transaction.update(bedRef, {
      'status': BedStatus.occupied.name,
      'currentResidentId': data['user_id'],
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // C. Set Payout Eligibility Window (now + 48h)
    transaction.update(escrowRef, {
      'releaseEligibleAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 48)),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // D. Log Financial Event
    transaction.set(_firestore.collection('financial_events').doc(), {
      'bookingId': bookingId,
      'event': 'CHECK_IN_COMPLETED',
      'reason': 'Resident activated, payout hold started',
      'performedBy': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
