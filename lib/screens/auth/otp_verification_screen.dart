import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/services/auth_production_service.dart';
import 'package:triangle_home/screens/admin/admin_dashboard_redesign.dart';
import 'package:triangle_home/screens/hoster/partner_onboarding_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final bool isStudent;
  final Widget? onLoginNavigateTo;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.isStudent,
    this.onLoginNavigateTo,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with CodeAutoFill {
  String _otpCode = "";
  Timer? _timer;
  int _timeLeft = 30;
  bool _isLoading = false;

  @override
  void codeUpdated() {
    setState(() {
      _otpCode = code ?? "";
    });
    if (_otpCode.length == 6) {
      _verifyOTP(_otpCode);
    }
  }

  @override
  void initState() {
    super.initState();
    listenForCode();
    startTimer();
    _printAppSignature();
  }

  void _printAppSignature() async {
    final signature = await SmsAutoFill().getAppSignature;
    debugPrint("App Signature for SMS: $signature");
  }

  @override
  void dispose() {
    _timer?.cancel();
    cancel(); // from CodeAutoFill
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });
  }

  String formatTime(int seconds) {
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOTP(String otp) async {
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("User not found");

      // Mark phone as verified in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'verification': {
          'phoneVerified': true,
          'phoneVerifiedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      final authService = AuthProductionService();
      final authDetails = await authService.getUserAuthDetails(user);
      final role = authDetails['role'] as UserRole;
      final status = authDetails['status'] as String;
      final onboardingStatus = authDetails['onboardingStatus'] as String? ?? '';

      if (!mounted) return;

      // Production-Grade Redirection Logic
      switch (role) {
        case UserRole.superadmin:
        case UserRole.admin:
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboardRedesign()),
            (route) => false,
          );
          break;
        case UserRole.hoster:
          if (status == 'approved' || onboardingStatus == 'submitted') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HosterDashboardScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen()),
              (route) => false,
            );
          }
          break;
        case UserRole.student:
          if (widget.onLoginNavigateTo != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => widget.onLoginNavigateTo!),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          }
          break;
        case UserRole.none:
          if (widget.onLoginNavigateTo != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => widget.onLoginNavigateTo!),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        widget.isStudent
                            ? const HomeScreen()
                            : const PartnerOnboardingScreen(),
              ),
              (route) => false,
            );
          }
          break;
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Verification failed';
      if (e.code == 'invalid-verification-code') {
        message = 'Invalid OTP. Please try again.';
      }
      if (e.code == 'session-expired') {
        message = 'OTP expired. Please resend.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    if (_timeLeft > 0) return;

    setState(() {
      _timeLeft = 30;
      _isLoading = true;
      _otpCode = "";
    });

    startTimer();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${widget.phoneNumber}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Verification failed')),
          );
        },
        codeSent: (String newVerificationId, int? resendToken) {
          // Update verificationId locally if needed
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastFourDigits = widget.phoneNumber.substring(
      widget.phoneNumber.length.clamp(0, 4) > 4 ? widget.phoneNumber.length - 4 : 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                _OtpIllustration(),
                const SizedBox(height: 32),
                const Text(
                  'One Time Password',
                  style: TextStyle(
                    fontSize: AppTheme.font2XL,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
                Text(
                  'Please enter the one-time password sent to\nyour mobile number ending ****$lastFourDigits',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppTheme.fontBase,
                    color: AppTheme.textLightColor,
                    height: 1.5,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 36),
                
                // Unified PinFieldAutoFill for reliable SMS extraction
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: PinFieldAutoFill(
                    currentCode: _otpCode,
                    codeLength: 6,
                    onCodeChanged: (code) {
                      setState(() {
                        _otpCode = code ?? "";
                      });
                      if (_otpCode.length == 6) {
                        _verifyOTP(_otpCode);
                      }
                    },
                    decoration: UnderlineDecoration(
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDarkColor,
                      ),
                      colorBuilder: FixedColorBuilder(
                        AppTheme.primaryColor.withValues(alpha: 0.8),
                      ),
                      gapSpace: 12,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Edit Phone Number',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _timeLeft == 0 ? _resendOTP : null,
                          child: Text(
                            'Resend OTP',
                            style: TextStyle(
                              color:
                                  _timeLeft == 0
                                      ? AppTheme.primaryColor
                                      : AppTheme.textLightColor,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ),
                        if (_timeLeft > 0)
                          Text(
                            formatTime(_timeLeft),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || _otpCode.length != 6) ? null : () => _verifyOTP(_otpCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: AppTheme.dividerColor,
                      disabledForegroundColor: AppTheme.textMutedColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: AppTheme.fontMD,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpIllustration extends StatelessWidget {
  const _OtpIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 20,
            child: Container(
              width: 220,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          ),
          Positioned(
            bottom: 26,
            left: 40,
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          4,
                          (_) => Container(
                            width: 12,
                            height: 3,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 60,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            'OTP',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.8,
                              ),
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 16,
                  height: 10,
                  color: AppTheme.dividerColor,
                ),
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 26,
            right: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 44,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            right: 18,
            child: Container(
              width: 18,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.textDarkColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms)
    .scale(
      begin: const Offset(0.9, 0.9),
      end: const Offset(1, 1),
      duration: 600.ms,
    );
  }
}
