import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/services/isar_service.dart';
import '../hoster_dashboard_screen.dart';

class ReviewSubmitStep extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onBack;

  const ReviewSubmitStep({super.key, required this.onboardingData, required this.onBack});

  @override
  State<ReviewSubmitStep> createState() => _ReviewSubmitStepState();
}

class _ReviewSubmitStepState extends State<ReviewSubmitStep> {
  bool _isSubmitting = false;

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final data = widget.onboardingData;

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'info.name': data['name'],
        'info.gender': data['gender'],
        'info.dob': data['dob'],
        'info.profileImage': data['profileImage'],
        'info.phone': data['phone'],
        'info.email': data['email'],
        'info.addressLine1': data['address1'],
        'info.addressLine2': data['address2'],
        'info.city': data['city'],
        'info.state': data['state'],
        'info.pincode': data['pincode'],
        'role': 'hoster', // Set role to hoster
        'accountStatus': 'pending', // Wait for admin approval
        'onboardingStatus': 'submitted',
        'verification': {
          'aadhaarFrontUrl': data['aadhaarFront'],
          'aadhaarBackUrl': data['aadhaarBack'],
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
      });

      // Clear local onboarding draft cache since application is submitted
      await IsarService().clearAdminCache('partner_onboarding_draft_${user.uid}');

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Application Submitted'),
            content: const Text('Your partner application is under review. We will notify you once approved.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HosterDashboardScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting application: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review your application',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 24),
          _buildSection('Personal Details', [
            'Name: ${widget.onboardingData['name']}',
            'Gender: ${widget.onboardingData['gender']}',
          ]),
          _buildSection('Contact', [
            'Email: ${widget.onboardingData['email']}',
            'Phone: ${widget.onboardingData['phone']}',
          ]),
          _buildSection('Address', [
            '${widget.onboardingData['address1']}, ${widget.onboardingData['city']}',
          ]),
          _buildSection('Banking', [
            'Acc No: ${widget.onboardingData['bankAccNo']}',
            'IFSC: ${widget.onboardingData['bankIfsc']}',
          ]),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: widget.onBack,
              child: const Text('Go back and edit', style: TextStyle(color: AppTheme.textLightColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textLightColor)),
          const SizedBox(height: 8),
          ...items.map((item) => Text(item, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
