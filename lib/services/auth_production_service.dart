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

      // Priority 2: Check standard "users" collection (Security Rule compliant)
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        if (role == 'student') return UserRole.student;
        if (role == 'hoster') return UserRole.hoster;
      }

      // Priority 3: No fallback to legacy collections (Rules compliant)
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
