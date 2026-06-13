import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

enum UserRole { student, hoster, admin, superadmin, none }

class AuthProductionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for Auth Changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // 1. Production-Grade Phone Verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatic handling on some Android devices
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      rethrow;
    }
  }

  // 2. Comprehensive Role & Status Detection
  Future<Map<String, dynamic>> getUserAuthDetails(User user) async {
    try {
      final idTokenResult = await user.getIdTokenResult(true);
      final roleClaim = idTokenResult.claims?['role'];

      // Check Firestore for detailed status
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final firestoreRole = userData?['role'];
      final status = userData?['status'] ?? userData?['accountStatus'] ?? 'pending';
      final onboardingStatus = userData?['onboardingStatus'] ?? '';

      UserRole finalRole = UserRole.none;
      if (roleClaim == 'superadmin') {
        finalRole = UserRole.superadmin;
      } else if (roleClaim == 'admin') {
        finalRole = UserRole.admin;
      } else if (roleClaim == 'hoster' ||
          roleClaim == 'owner' ||
          roleClaim == 'manager' ||
          roleClaim == 'agency' ||
          firestoreRole == 'hoster' ||
          firestoreRole == 'owner' ||
          firestoreRole == 'manager' ||
          firestoreRole == 'agency') {
        finalRole = UserRole.hoster;
      } else if (firestoreRole == 'student' || firestoreRole == 'user') {
        finalRole = UserRole.student;
      }

      return {
        'role': finalRole,
        'status': status,
        'onboardingStatus': onboardingStatus,
      };
    } catch (e) {
      debugPrint('Error detecting role/status: $e');
      return {'role': UserRole.none, 'status': 'unknown'};
    }
  }

  // Legacy support for older code
  Future<UserRole> getUserRole(User user) async {
    final details = await getUserAuthDetails(user);
    return details['role'] as UserRole;
  }

  // 3. Secure Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. Complete Data Safety: Account Deletion
  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String uid = user.uid;

    try {
      // 1. Delete User Collections
      // Delete user's own document
      await _firestore.collection('users').doc(uid).delete();

      // Delete user's wishlists
      final wishlists = await _firestore
          .collection('wishlists')
          .where('user_id', isEqualTo: uid)
          .get();
      for (var doc in wishlists.docs) {
        await doc.reference.delete();
      }

      // 2. Cleanup Storage (Best effort)
      try {
        final storage = FirebaseStorage.instance;
        // Delete verification documents
        await storage.ref().child('verifications/$uid').listAll().then((result) {
          for (var file in result.items) {
            file.delete();
          }
        });
        // Delete profile images
        await storage.ref().child('profile_images/$uid').delete().catchError((_) {});
      } catch (e) {
        debugPrint('Storage cleanup warning: $e');
      }

      // 3. Delete Firebase Auth Account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Sensitive actions require recent authentication. Please sign out and sign in again before deleting your account.';
      }
      rethrow;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
}
