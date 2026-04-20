import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/models/user.dart';

class AuthService {
  Future<User?> loginWithPhone(String phoneNumber) async {
    // This would connect to a backend service
    // For now we return a mock user
    await Future.delayed(const Duration(seconds: 2));

    return User(
      id: '1',
      phoneNumber: phoneNumber,
      email: 'user@example.com',
      name: 'Test User',
      profilePicture: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<User?> loginWithSocial(String provider) async {
    // This would connect to a social auth provider
    // For now we return a mock user
    await Future.delayed(const Duration(seconds: 2));

    return User(
      id: '2',
      phoneNumber: '+1234567890',
      email: 'social@example.com',
      name: 'Social User',
      profilePicture: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> logout() async {
    // This would clear any stored tokens
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userProvider = StateProvider<User?>((ref) => null);

// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Phone number verification
//   Future<void> verifyPhoneNumber({
//     required String phoneNumber,
//     required Function(String) onCodeSent,
//     required Function(String) onVerificationCompleted,
//     required Function(String) onError,
//   }) async {
//     try {
//       await _auth.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           await _auth.signInWithCredential(credential);
//           onVerificationCompleted('Auto verification completed');
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           onError(e.message ?? 'Verification failed');
//         },
//         codeSent: (String verificationId, int? resendToken) {
//           onCodeSent(verificationId);
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {},
//         timeout: const Duration(seconds: 60),
//       );
//     } catch (e) {
//       onError(e.toString());
//     }
//   }

//   // Verify OTP
//   Future<bool> verifyOTP({
//     required String verificationId,
//     required String smsCode,
//   }) async {
//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: verificationId,
//         smsCode: smsCode,
//       );
      
//       UserCredential userCredential = await _auth.signInWithCredential(credential);
      
//       if (userCredential.user != null) {
//         await _createUserInFirestore(userCredential.user!);
//         return true;
//       }
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }

//   // Create user in Firestore
//   Future<void> _createUserInFirestore(User user) async {
//     final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
//     if (!userDoc.exists) {
//       await _firestore.collection('users').doc(user.uid).set({
//         'phoneNumber': user.phoneNumber,
//         'createdAt': FieldValue.serverTimestamp(),
//         'lastLogin': FieldValue.serverTimestamp(),
//       });
//     } else {
//       await _firestore.collection('users').doc(user.uid).update({
//         'lastLogin': FieldValue.serverTimestamp(),
//       });
//     }
//   }

//   // Get current user
//   User? get currentUser => _auth.currentUser;

//   // Sign out
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }

//   // Stream of auth state changes
//   Stream<User?> get authStateChanges => _auth.authStateChanges();
// }

// final authServiceProvider = Provider<AuthService>((ref) {
//   return AuthService();
// });

// final authStateProvider = StreamProvider<User?>((ref) {
//   final authService = ref.watch(authServiceProvider);
//   return authService.authStateChanges;
// });