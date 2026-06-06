import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class BankingStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> initialData;

  const BankingStep({super.key, required this.onContinue, required this.initialData});

  @override
  State<BankingStep> createState() => _BankingStepState();
}

class _BankingStepState extends State<BankingStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _accNameController;
  late TextEditingController _accNoController;
  late TextEditingController _ifscController;
  late TextEditingController _upiController;

  @override
  void initState() {
    super.initState();
    _accNameController = TextEditingController(text: widget.initialData['bankAccName'] ?? '');
    _accNoController = TextEditingController(text: widget.initialData['bankAccNo'] ?? '');
    _ifscController = TextEditingController(text: widget.initialData['bankIfsc'] ?? '');
    _upiController = TextEditingController(text: widget.initialData['upiId'] ?? '');
  }

  @override
  void dispose() {
    _accNameController.dispose();
    _accNoController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
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
              'Payout Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the bank account where you want to receive payments.',
              style: TextStyle(color: AppTheme.textLightColor),
            ),
            const SizedBox(height: 32),
            InputField(label: 'Account Holder Name', controller: _accNameController, required: true),
            const SizedBox(height: 16),
            InputField(label: 'Account Number', controller: _accNoController, required: true, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            InputField(label: 'IFSC Code', controller: _ifscController, required: true, textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 16),
            InputField(label: 'UPI ID (Optional)', controller: _upiController, hintText: 'e.g. name@okaxis'),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onContinue({
                      'bankAccName': _accNameController.text,
                      'bankAccNo': _accNoController.text,
                      'bankIfsc': _ifscController.text,
                      'upiId': _upiController.text,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
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
