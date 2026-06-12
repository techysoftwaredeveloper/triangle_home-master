import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/progress_bar.dart';

// Steps
import 'onboarding_steps/profile_step.dart';
import 'onboarding_steps/role_step.dart';
import 'onboarding_steps/contact_step.dart';
import 'onboarding_steps/address_step.dart';
import 'onboarding_steps/kyc_aadhaar_step.dart';
import 'onboarding_steps/kyc_pan_step.dart';
import 'onboarding_steps/preferences_step.dart';
import 'onboarding_steps/banking_step.dart';
import 'onboarding_steps/review_submit_step.dart';
import 'hoster_dashboard_screen.dart';

class PartnerOnboardingScreen extends StatefulWidget {
  const PartnerOnboardingScreen({super.key});

  @override
  State<PartnerOnboardingScreen> createState() => _PartnerOnboardingScreenState();
}

class _PartnerOnboardingScreenState extends State<PartnerOnboardingScreen> {
  late PageController _pageController;
  final IsarService _isarService = IsarService();
  int _currentPage = 0;
  bool _isLoading = true;
  Map<String, dynamic> _onboardingData = {};
  int _onboardingVersion = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Load from Isar (Local Draft)
      final localDraft = await _isarService.getAdminCache('partner_onboarding_draft_${user.uid}');
      if (localDraft != null) {
        _onboardingData = jsonDecode(localDraft);
        _currentPage = _onboardingData['last_step'] ?? 0;
      }

      // 2. Load from Firestore if local is empty or to sync latest
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final firestoreData = data['onboardingData']?.cast<String, dynamic>() ?? {};
        final firestoreUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
        final localUpdatedAt = _onboardingData['updatedAt'] != null 
            ? DateTime.tryParse(_onboardingData['updatedAt'].toString()) 
            : null;

        // Sync logic: Prefer newer data based on updatedAt
        if (firestoreUpdatedAt != null && (localUpdatedAt == null || firestoreUpdatedAt.isAfter(localUpdatedAt))) {
          _onboardingData = firestoreData;
          _currentPage = data['onboardingStep'] ?? 0;
        } else if (_onboardingData.isEmpty) {
          // Fallback if local is empty and firestore has data (e.g. first time on new device)
          if (firestoreData.isNotEmpty) {
            _onboardingData = firestoreData;
            _currentPage = data['onboardingStep'] ?? 0;
          } else {
            // Pre-populate with existing registered profile details
            final info = data['info'] as Map? ?? {};
            String? dobStr;
            if (info['dob'] != null) {
              if (info['dob'] is Timestamp) {
                dobStr = (info['dob'] as Timestamp).toDate().toIso8601String();
              } else {
                dobStr = info['dob'].toString();
              }
            }
            _onboardingData = {
              'name': info['name'] ?? user.displayName ?? '',
              'email': info['email'] ?? user.email ?? '',
              'phone': info['phone'] ?? user.phoneNumber ?? '',
              'gender': info['gender'],
              'dob': dobStr,
              'profileImage': info['profileImage'],
            };
          }
        }
      } else {
        // Document doesn't exist, pre-populate from auth user
        if (_onboardingData.isEmpty) {
          _onboardingData = {
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
          };
        }
      }
    } catch (e) {
      debugPrint('Error loading onboarding progress: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentPage);
          }
        });
      }
    }
  }

  Future<void> _saveProgress(Map<String, dynamic> stepData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    _onboardingData.addAll(stepData);
    _onboardingData['last_step'] = _currentPage;
    _onboardingData['updatedAt'] = now.toIso8601String();

    try {
      // Save locally
      await _isarService.saveAdminCache('partner_onboarding_draft_${user.uid}', jsonEncode(_onboardingData));

      // Sync to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'onboardingData': _onboardingData,
        'onboardingStep': _currentPage,
        'onboardingStatus': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _resetOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Onboarding?'),
        content: const Text('This will clear all your progress and start over. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _isarService.clearAdminCache('partner_onboarding_draft_${user.uid}');
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'onboardingData': {},
          'onboardingStep': 0,
          'onboardingStatus': 'pending',
        });
      } catch (e) {
        debugPrint('Error resetting onboarding: $e');
      }
    }

    _onboardingData = {};
    _currentPage = 0;
    _onboardingVersion++;
    setState(() => _isLoading = false);
    _pageController.jumpToPage(0);
  }

  double _calculateCompletion() {
    // Total fields across 8 steps (excluding review)
    const int totalFields = 19;
    int filledFields = 0;

    // Step 0: Profile
    if (_onboardingData['name'] != null && _onboardingData['name'].toString().isNotEmpty) filledFields++;
    if (_onboardingData['gender'] != null) filledFields++;
    if (_onboardingData['dob'] != null) filledFields++;
    if (_onboardingData['profileImage'] != null) filledFields++;

    // Step 1: Role
    if (_onboardingData['role'] != null) filledFields++;

    // Step 2: Contact
    if (_onboardingData['phone'] != null && _onboardingData['phone'].toString().isNotEmpty) filledFields++;
    if (_onboardingData['email'] != null && _onboardingData['email'].toString().isNotEmpty) filledFields++;

    // Step 3: Address
    if (_onboardingData['address1'] != null && _onboardingData['address1'].toString().isNotEmpty) filledFields++;
    if (_onboardingData['city'] != null && _onboardingData['city'].toString().isNotEmpty) filledFields++;
    if (_onboardingData['state'] != null) filledFields++;
    if (_onboardingData['pincode'] != null && _onboardingData['pincode'].toString().isNotEmpty) filledFields++;

    // Step 4: Aadhaar
    if (_onboardingData['aadhaarFront'] != null) filledFields++;
    if (_onboardingData['aadhaarBack'] != null) filledFields++;

    // Step 5: PAN
    if (_onboardingData['panUrl'] != null) filledFields++;

    // Step 6: Preferences
    if (_onboardingData['preferredTenants'] != null && (_onboardingData['preferredTenants'] as List).isNotEmpty) filledFields++;
    if (_onboardingData['preferredGender'] != null) filledFields++;

    // Step 7: Banking
    if (_onboardingData['bankAccName'] != null && _onboardingData['bankAccName'].toString().isNotEmpty) filledFields++;
    if (_onboardingData['bankAccNo'] != null && _onboardingData['bankAccNo'].toString().isNotEmpty) filledFields++;
    if (_onboardingData['bankIfsc'] != null && _onboardingData['bankIfsc'].toString().isNotEmpty) filledFields++;

    return filledFields / totalFields;
  }

  void _nextPage(Map<String, dynamic> data) async {
    await _saveProgress(data);
    if (_currentPage < 8) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmExit();
    }
  }

  void _jumpToPage(int page) {
    if (page < _currentPage) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Onboarding?'),
        content: const Text('Any unsaved changes in the current step will be lost. You can continue later from your last saved step.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() ?? {};
        
        // Unified check for Hoster Approval
        final bool isApproved = 
            (userData['role'] == 'hoster') ||
            (userData['onboardingStatus'] == 'approved') ||
            (userData['accountStatus'] == 'active') ||
            (userData['status'] == 'approved');

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _confirmExit();
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDarkColor, size: 20),
                onPressed: _previousPage,
              ),
              title: Text(
                _getStepTitle(),
                style: const TextStyle(
                  color: AppTheme.textDarkColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.textLightColor, size: 20),
                  onPressed: _resetOnboarding,
                  tooltip: 'Reset Progress',
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    ProgressBar(
                      currentStep: _currentPage,
                      totalSteps: 9,
                      completionPercentage: _calculateCompletion(),
                      onStepTap: _jumpToPage,
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (page) => setState(() => _currentPage = page),
                        children: [
                          ProfileStep(key: ValueKey('step0_$_onboardingVersion'), onContinue: _nextPage, initialData: _onboardingData),
                          RoleStep(key: ValueKey('step1_$_onboardingVersion'), onContinue: _nextPage, initialData: _onboardingData),
                          ContactStep(key: ValueKey('step2_$_onboardingVersion'), onContinue: _nextPage, initialData: _onboardingData),
                          AddressStep(key: ValueKey('step3_$_onboardingVersion'), onContinue: _nextPage, initialData: _onboardingData),
                          KycAadhaarStep(key: ValueKey('step4_$_onboardingVersion'), onContinue: _nextPage, initialData: _onboardingData),
                          KycPanStep(key: ValueKey('step5_$_onboardingVersion'), onContinue: _nextPage, initialData: _onboardingData),
                          PreferencesStep(key: ValueKey('step6_$_onboardingVersion'), onContinue: _nextPage, initialData: _onboardingData),
                          BankingStep(key: ValueKey('step7_$_onboardingVersion'), onContinue: _nextPage, initialData: _onboardingData),
                          ReviewSubmitStep(onboardingData: _onboardingData, onBack: _previousPage),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Real-time Approval Overlay
                if (isApproved)
                  _buildApprovalOverlay(),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildApprovalOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 32),
          const Text(
            'Application Approved!',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Congratulations! Your hoster application has been approved. You can now access your dashboard and start listing properties.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => HosterDashboardScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentPage) {
      case 0: return 'Owner Profile';
      case 1: return 'Partner Role';
      case 2: return 'Contact Details';
      case 3: return 'Residential Address';
      case 4: return 'Aadhaar Verification';
      case 5: return 'PAN Verification';
      case 6: return 'Host Preferences';
      case 7: return 'Banking & Payouts';
      case 8: return 'Review & Submit';
      default: return 'Partner Onboarding';
    }
  }
}
