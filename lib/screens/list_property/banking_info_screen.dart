import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class BankingInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  const BankingInfoScreen({super.key, required this.onContinue});

  @override
  State<BankingInfoScreen> createState() => _BankingInfoScreenState();
}

class _BankingInfoScreenState extends State<BankingInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

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
              'Payout Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textDarkColor,
              ),
            ).animate().fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 8),
            const Text(
              'We need your banking details to process rent payments securely.',
              style: TextStyle(color: AppTheme.textLightColor, fontSize: 14),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            InputField(
              label: 'Account Holder Name',
              controller: _accountNameController,
              required: true,
            ),

            DropdownField(
              label: 'Select Bank',
              controller: _bankNameController,
              required: true,
              items: const ['HDFC Bank', 'ICICI Bank', 'SBI', 'Axis Bank', 'Others'],
            ),

            InputField(
              label: 'Account Number',
              controller: _accountNumberController,
              required: true,
              keyboardType: TextInputType.number,
            ),

            InputField(
              label: 'IFSC Code',
              controller: _ifscController,
              required: true,
              textCapitalization: TextCapitalization.characters,
            ),

            InputField(
              label: 'UPI ID (Optional)',
              controller: _upiController,
              hintText: 'e.g. name@okaxis',
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onContinue({
                      'bankingInfo': {
                        'accountName': _accountNameController.text,
                        'bankName': _bankNameController.text,
                        'accountNumber': _accountNumberController.text,
                        'ifsc': _ifscController.text,
                        'upiId': _upiController.text,
                      }
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                ),
                child: const Text(
                  'Continue to Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
