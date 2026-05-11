import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // 2. Comprehensive Role Detection
  Future<UserRole> getUserRole(User user) async {
    try {
      // Priority 1: Check Custom Claims (Most Secure, Token-based)
      final idTokenResult = await user.getIdTokenResult(true);
      final roleClaim = idTokenResult.claims?['role'];

      if (roleClaim == 'superadmin') return UserRole.superadmin;
      if (roleClaim == 'admin') return UserRole.admin;
      if (roleClaim == 'hoster') return UserRole.hoster;

      // Priority 2: Firestore Verification (Database-based)
      // Check Hoster collection
      final hosterDoc = await _firestore.collection('hoster').doc(user.uid).get();
      if (hosterDoc.exists) return UserRole.hoster;

      // Check Student collection
      // Note: Project uses phone as ID in some places, UID in others. Checking both for safety.
      final studentDoc = await _firestore.collection('student').doc(user.uid).get();
      if (studentDoc.exists) return UserRole.student;

      if (user.phoneNumber != null) {
        final studentPhoneDoc = await _firestore.collection('student').doc(user.phoneNumber).get();
        if (studentPhoneDoc.exists) return UserRole.student;
      }

      return UserRole.none;
    } catch (e) {
      debugPrint('Error detecting role: $e');
      return UserRole.none;
    }
  }

  // 3. Secure Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
