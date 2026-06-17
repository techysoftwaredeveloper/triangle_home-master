import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import 'package:lottie/lottie.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  Timer? _timer;
  int _timeLeft = 30;
  StreamSubscription? _smsSubscription;

  @override
  void initState() {
    super.initState();
    startTimer();
    _initSmsListener();
    _initBackspaceHandlers();
  }

  void _initBackspaceHandlers() {
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[i].text.isEmpty && i > 0) {
            _controllers[i - 1].clear();
            _focusNodes[i - 1].requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }

  void _initSmsListener() async {
    try {
      _smsSubscription = SmsAutoFill().code.listen((code) {
        if (code.length == 6) {
          for (int i = 0; i < 6; i++) {
            _controllers[i].text = code[i];
          }
          setState(() {});
        }
      });
      await SmsAutoFill().listenForCode();
      final sign = await SmsAutoFill().getAppSignature;
      debugPrint('SMS AutoFill Signature: $sign');
    } catch (e) {
      debugPrint('Error starting SMS listener: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _smsSubscription?.cancel();
    SmsAutoFill().unregisterListener();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
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

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0 && _focusNodes[index].hasFocus) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastFourDigits = widget.phoneNumber.substring(
      widget.phoneNumber.length - 4,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // const SizedBox(height: 0),
              Lottie.asset('assets/images/otp_animation.json', height: 200),
              //   'https://app.lottiefiles.com/animation/3732a84d-f86d-4e35-8524-a96a3ba9cd4e?channel=web&source=public-animation&panel=download&from=download',
              //   height: 200,
              // ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 32),
              const Text(
                'One Time Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'Please enter the one-time password sent to\nyour mobile number ending ****$lastFourDigits',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      autofillHints: const [AutofillHints.oneTimeCode],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 24),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF1E3A8A),
                            width: 2,
                          ),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => _onOtpDigitChanged(index, value),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Edit Mobile Number',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed:
                            _timeLeft == 0
                                ? () {
                                  setState(() {
                                    _timeLeft = 30;
                                  });
                                  startTimer();
                                }
                                : null,
                        child: Text(
                          'Resend OTP',
                          style: TextStyle(
                            color:
                                _timeLeft == 0
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_timeLeft > 0)
                        Text(
                          formatTime(_timeLeft),
                          style: const TextStyle(color: Colors.black54),
                        ),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final otp =
                        _controllers.map((c) => c.text).join();
                    if (otp.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter the complete 6-digit OTP'),
                        ),
                      );
                      return;
                    }

                    // Persist phone verified status to Firestore
                    try {
                      final uid =
                          FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .set({
                          'verification': {'phoneVerified': true},
                        }, SetOptions(merge: true));
                      }
                    } catch (_) {
                      // non-blocking — proceed even if write fails
                    }

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
