import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class PermissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks if a user has unlocked the private details of a property
  Stream<bool> hasPrivateAccess(String propertyId, String userId) {
    return _firestore
        .collection('unlocked_data')
        .doc('${userId}_$propertyId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Checks if a user can view private details based on their current booking status
  /// This is used for UI logic before attempting a fetch
  bool canViewPrivateUI(BookingStatus status) {
    const allowedStatuses = [
      BookingStatus.hosterApproved,
      BookingStatus.bookingConfirmed,
      BookingStatus.checkinPending,
      BookingStatus.checkedIn,
      BookingStatus.checkedOut,
      BookingStatus.completed,
    ];
    return allowedStatuses.contains(status);
  }

  /// Grants a user access to a property's private vault
  /// Note: Requires administrative permissions or a secure backend context
  Future<void> grantPrivateAccess({
    required String propertyId,
    required String userId,
    required String bookingId,
  }) async {
    await _firestore.collection('unlocked_data').doc('${userId}_$propertyId').set({
      'user_id': userId,
      'property_id': propertyId,
      'booking_id': bookingId,
      'unlocked_at': FieldValue.serverTimestamp(),
    });
  }

  /// Revokes access to a property's private vault
  Future<void> revokePrivateAccess(String propertyId, String userId) async {
    await _firestore.collection('unlocked_data').doc('${userId}_$propertyId').delete();
  }
}
