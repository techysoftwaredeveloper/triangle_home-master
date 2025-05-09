
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _accountNameController = TextEditingController(text: 'Aravind Pradeep Kumar');
  final _bankNameController = TextEditingController(text: 'HDFC Bank');
  final _accountNumberController = TextEditingController(text: '600000216837');
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController(text: 'HDFC600098');
  final _upiController = TextEditingController(text: 'pradeep.aravind@okhdfcbank');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Banking Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            InputField(
              label: 'Name as per bank account',
              controller: _accountNameController,
              required: true,
              textCapitalization: TextCapitalization.words,maxLines: 2,
            ),
            DropdownField(
              label: 'Name of bank',
              controller: _bankNameController,
              items: const ['HDFC Bank', 'SBI', 'ICICI Bank', 'Axis Bank'],
              required: true,
            ),
            InputField(
              label: 'Bank account number',
              controller: _accountNumberController,
              required: true,
              keyboardType: TextInputType.number,
              maxLines: 1,
            ),
            InputField(
              label: 'Re-enter bank account number',
              controller: _confirmAccountController,
              required: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLines: 1,
              validator: (value) {
                if (value != _accountNumberController.text) {
                  return 'Account numbers do not match';
                }
                return null;
              },
            ),
            InputField(
              label: 'IFSC Code',
              controller: _ifscController,
              required: true,
              maxLines: 1,
              textCapitalization: TextCapitalization.characters,
            ),
            InputField(
              label: 'UPI ID for incoming payments',
              controller: _upiController,
              keyboardType: TextInputType.emailAddress,
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onContinue(
                      {
                        'accountName': _accountNameController.text,
                        'bankName': _bankNameController.text,
                        'accountNumber': _accountNumberController.text,
                        'ifscCode': _ifscController.text,
                        'upiId': _upiController.text,
                      },
                    );
                  }
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
