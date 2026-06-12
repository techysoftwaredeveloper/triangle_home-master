import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/screens/profile/verification_otp_screen.dart';
import 'package:triangle_home/services/onboarding_service.dart';
import 'dart:async';


class ContactStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> initialData;

  const ContactStep({super.key, required this.onContinue, required this.initialData});

  @override
  State<ContactStep> createState() => _ContactStepState();
}

class _ContactStepState extends State<ContactStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isPhoneVerified = false;
  bool _isEmailVerified = false;
  bool _isVerifying = false;
  bool _emailVerificationSent = false;
  Timer? _emailPollTimer;
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _phoneController = TextEditingController(text: widget.initialData['phone'] ?? user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.initialData['email'] ?? user?.email ?? '');
    _isPhoneVerified = widget.initialData['phoneVerified'] ?? (user?.phoneNumber != null);
    _isEmailVerified = widget.initialData['emailVerified'] ?? (user?.emailVerified ?? false);

    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _phoneController.dispose();
    _emailController.dispose();
    _emailPollTimer?.cancel();
    super.dispose();
  }

  void _onEmailChanged() {
    final user = FirebaseAuth.instance.currentUser;
    final currentEmail = user?.email ?? '';

    // If the email text changes from the verified one OR while verification is pending
    if ((_isEmailVerified || _emailVerificationSent) && _emailController.text != currentEmail) {
      setState(() {
        _isEmailVerified = false;
        _emailVerificationSent = false;
        _emailPollTimer?.cancel();
      });
    }
  }

  void _startEmailPolling() {
    _emailPollTimer?.cancel();
    _emailPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        await _onboardingService.syncVerificationStatus(email: true, phone: false);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.emailVerified && mounted) {
          setState(() {
            _isEmailVerified = true;
            _emailVerificationSent = false;
          });
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email verified successfully!')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error polling email verification: $e');
      }
    });
  }

  Future<void> _verifyEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isVerifying = true);
    try {
      if (user.email != _emailController.text) {
        await user.verifyBeforeUpdateEmail(_emailController.text);
      } else {
        await user.sendEmailVerification();
      }
      
      setState(() {
        _emailVerificationSent = true;
        _isVerifying = false;
      });
      _startEmailPolling();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent! Please check your inbox.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isVerifying = false);
      if (e.code == 'requires-recent-login') {
        _handleRecentLoginError();
      } else if (e.code == 'too-many-requests') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Too many requests. Please try again later.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send email: ${e.message}')),
          );
        }
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email: $e')),
        );
      }
    }
  }

  Future<void> _handleRecentLoginError() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('For security reasons, please verify your phone number again to continue changing your email.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verify Now')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final credential = await _verifyPhone(isReauth: true);
      if (credential is PhoneAuthCredential) {
        try {
          setState(() => _isVerifying = true);
          final user = FirebaseAuth.instance.currentUser;
          await user?.reauthenticateWithCredential(credential);
          // Retry email verification
          _verifyEmail();
        } catch (e) {
          if (mounted) {
            setState(() => _isVerifying = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Re-authentication failed: $e')),
            );
          }
        }
      }
    }
  }

  Future<dynamic> _verifyPhone({bool isReauth = false}) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return null;

    final completer = Completer<dynamic>();

    setState(() => _isVerifying = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone.startsWith('+') ? phone : '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            if (isReauth) {
              completer.complete(credential);
            } else {
              await user.linkWithCredential(credential);
              await _onboardingService.syncVerificationStatus(email: false, phone: true);
              setState(() {
                _isPhoneVerified = true;
                _isVerifying = false;
              });
              completer.complete(true);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isVerifying = false);
          debugPrint('Phone verification failed: ${e.code} - ${e.message}');
          
          String errorMessage = 'Verification failed. Please try again.';
          if (e.code == 'too-many-requests') {
            errorMessage = 'Too many attempts. Please try again later.';
          } else if (e.code == 'invalid-phone-number') {
            errorMessage = 'The provided phone number is not valid.';
          } else if (e.code == 'web-context-cancelled') {
            errorMessage = 'Verification was cancelled. Please try again.';
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
          completer.complete(false);
        },
        codeSent: (String verificationId, int? resendToken) async {
          setState(() => _isVerifying = false);
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationOtpScreen(
                verificationId: verificationId,
                phoneNumber: phone,
                email: isReauth ? 'REAUTH' : null,
              ),
            ),
          );
          completer.complete(result);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      completer.complete(false);
    }
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify your contact info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 8),
            const Text(
              'We use this to send you booking updates and leads.',
              style: TextStyle(color: AppTheme.textLightColor),
            ),
            const SizedBox(height: 32),
            InputField(
              label: 'Phone Number',
              controller: _phoneController,
              required: true,
              keyboardType: TextInputType.phone,
              readOnly: _isPhoneVerified,
              activeColor: _isPhoneVerified ? AppTheme.textMutedColor : null,
              suffix: _isPhoneVerified 
                ? const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 22)
                : _isVerifying 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: () async {
                        final result = await _verifyPhone();
                        if (result == true && mounted) {
                          setState(() => _isPhoneVerified = true);
                        }
                      },
                      child: const Text('Verify'),
                    ),
            ),
            if (_isPhoneVerified)
              const Padding(
                padding: EdgeInsets.only(bottom: 20, left: 4),
                child: Text(
                  'Verified during login',
                  style: TextStyle(fontSize: 12, color: AppTheme.successColor, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 20),
            InputField(
              label: 'Email Address',
              controller: _emailController,
              required: true,
              keyboardType: TextInputType.emailAddress,
              readOnly: _isEmailVerified,
              activeColor: _isEmailVerified ? AppTheme.successColor : null,
              suffix: _isEmailVerified
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 22)
                  : _isVerifying 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: _emailVerificationSent ? null : _verifyEmail, 
                          child: Text(_emailVerificationSent ? 'Sent' : 'Verify'),
                        ),
            ),
            if (_emailVerificationSent && !_isEmailVerified)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for verification link click...',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700], fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isPhoneVerified && _isEmailVerified) 
                  ? () {
                    if (_formKey.currentState!.validate()) {
                      widget.onContinue({
                        'phone': _phoneController.text,
                        'email': _emailController.text,
                        'phoneVerified': _isPhoneVerified,
                        'emailVerified': _isEmailVerified,
                      });
                    }
                  }
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
