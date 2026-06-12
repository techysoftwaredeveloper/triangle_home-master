import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/services/admin_api_service.dart';
import 'package:triangle_home/services/isar_service.dart';

class OnboardingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AdminApiService _apiService;
  final IsarService _isarService;

  OnboardingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AdminApiService? apiService,
    IsarService? isarService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _apiService = apiService ?? AdminApiService(),
       _isarService = isarService ?? IsarService();

  Future<void> submitHosterApplication(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    // 1. Prepare consolidated update for Firestore
    final userUpdate = {
      'info': {
        'name': data['name'],
        'gender': data['gender'],
        'dob': data['dob'],
        'profileImage': data['profileImage'],
        'phone': data['phone'],
        'email': data['email'],
        'addressLine1': data['address1'],
        'addressLine2': data['address2'],
        'city': data['city'],
        'state': data['state'],
        'pincode': data['pincode'],
      },
      'role': 'hoster',
      'onboardingStatus': 'submitted',
      'accountStatus': 'pending', // Waiting for admin approval
      'verification': {
        'emailVerified': data['emailVerified'] ?? user.emailVerified,
        'phoneVerified': data['phoneVerified'] ?? (user.phoneNumber != null),
        'aadhaarNumber': data['aadhaarNumber'],
        'aadhaarFrontUrl': data['aadhaarFront'],
        'aadhaarBackUrl': data['aadhaarBack'],
        'panNumber': data['panNumber'],
        'panUrl': data['panUrl'],
        'govIdStatus': 'pending',
        'panStatus': 'pending',
      },
      'bank_info': {
        'accountName': data['bankAccName'],
        'accountNumber': data['bankAccNo'],
        'ifsc': data['bankIfsc'],
        'upiId': data['upiId'],
      },
      'host_preferences': {
        'tenantTypes': data['preferredTenants'],
        'genderPreference': data['preferredGender'],
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 2. Atomic update to users collection
    await _firestore.collection('users').doc(user.uid).update(userUpdate);

    // 3. Call backend to handle status change and custom claims
    await _apiService.resubmitHoster();

    // 4. Clear local onboarding draft cache
    await _isarService.clearAdminCache('partner_onboarding_draft_${user.uid}');
  }

  Future<void> syncVerificationStatus({bool email = true, bool phone = true}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (email) await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) return;

    final Map<String, dynamic> verificationUpdate = {};
    
    if (email && refreshed.emailVerified) {
      verificationUpdate['emailVerified'] = true;
      verificationUpdate['emailVerifiedAt'] = FieldValue.serverTimestamp();
    }
    
    if (phone && refreshed.phoneNumber != null) {
      verificationUpdate['phoneVerified'] = true;
      verificationUpdate['phoneVerifiedAt'] = FieldValue.serverTimestamp();
    }

    if (verificationUpdate.isNotEmpty) {
      await _firestore.collection('users').doc(refreshed.uid).set({
        'verification': verificationUpdate,
        'emailVerified': verificationUpdate['emailVerified'] ?? false, // Keep top-level for legacy
      }, SetOptions(merge: true));
    }
  }
}
