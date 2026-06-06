import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _phoneController = TextEditingController(text: widget.initialData['phone'] ?? user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.initialData['email'] ?? user?.email ?? '');
    _isPhoneVerified = widget.initialData['phoneVerified'] ?? (user?.phoneNumber != null);
    _isEmailVerified = widget.initialData['emailVerified'] ?? (user?.emailVerified ?? false);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
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
              suffix: _isPhoneVerified 
                ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                : TextButton(onPressed: () {}, child: const Text('Verify')),
            ),
            const SizedBox(height: 20),
            InputField(
              label: 'Email Address',
              controller: _emailController,
              required: true,
              keyboardType: TextInputType.emailAddress,
              suffix: _isEmailVerified
                ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                : TextButton(onPressed: () {}, child: const Text('Verify')),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onContinue({
                      'phone': _phoneController.text,
                      'email': _emailController.text,
                      'phoneVerified': _isPhoneVerified,
                      'emailVerified': _isEmailVerified,
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
