import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class BasicInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  const BasicInfoScreen({super.key, required this.onContinue});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propertyTypeController = TextEditingController();
  final _nameController = TextEditingController();
  final _wardenController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

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
              'Tell us about your property',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textDarkColor,
              ),
            ).animate().fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 8),
            const Text(
              'Start with the basic details of your accommodation.',
              style: TextStyle(color: AppTheme.textLightColor, fontSize: 14),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            DropdownField(
              label: 'Property Type',
              controller: _propertyTypeController,
              required: true,
              items: const ['College Hostel', 'Paying Guest Accommodation', 'Apartment'],
            ),

            InputField(
              label: 'Property/College Name',
              controller: _nameController,
              required: true,
              hintText: 'e.g. Sunshine PG or Oxford Hostel',
            ),

            InputField(
              label: 'Warden/Manager Name',
              controller: _wardenController,
              required: true,
            ),

            InputField(
              label: 'Contact Phone Number',
              controller: _phoneController,
              required: true,
              keyboardType: TextInputType.phone,
              prefix: '+91 ',
            ),

            InputField(
              label: 'Contact Email',
              controller: _emailController,
              required: true,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onContinue({
                      'propertyType': _propertyTypeController.text,
                      'basicInfo': {
                        'name': _nameController.text,
                        'wardenName': _wardenController.text,
                        'phone': _phoneController.text,
                        'email': _emailController.text,
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
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                child: const Text(
                  'Continue to Banking',
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
