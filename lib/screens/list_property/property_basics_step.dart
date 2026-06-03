import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class PropertyBasicsStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const PropertyBasicsStep({
    super.key,
    required this.onContinue,
    this.initialData,
  });

  @override
  State<PropertyBasicsStep> createState() => _PropertyBasicsStepState();
}

class _PropertyBasicsStepState extends State<PropertyBasicsStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _propertyTypeController;
  late TextEditingController _nameController;
  late TextEditingController _wardenController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData?['propertyBasics'] ?? {};
    _propertyTypeController = TextEditingController(
      text: data['type'] ?? 'Hostel',
    );
    _nameController = TextEditingController(text: data['name'] ?? '');
    _wardenController = TextEditingController(text: data['wardenName'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownField(
              label: 'Property Type',
              controller: _propertyTypeController,
              required: true,
              items: const [
                'Hostel',
                'PG Accommodation',
                'Apartment',
                'Guest House',
              ],
              activeColor: AppTheme.successColor,
            ),
            InputField(
              label: 'Property/Hostel Name',
              controller: _nameController,
              required: true,
              hintText: 'e.g. Sunshine Hostel',
              activeColor: AppTheme.successColor,
            ),
            InputField(
              label: 'Manager/Warden Name',
              controller: _wardenController,
              required: true,
              activeColor: AppTheme.successColor,
            ),
            InputField(
              label: 'Contact Phone',
              controller: _phoneController,
              required: true,
              keyboardType: TextInputType.phone,
              activeColor: AppTheme.successColor,
            ),
            InputField(
              label: 'Contact Email',
              controller: _emailController,
              required: true,
              keyboardType: TextInputType.emailAddress,
              activeColor: AppTheme.successColor,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onContinue({
                      'propertyBasics': {
                        'type': _propertyTypeController.text,
                        'name': _nameController.text,
                        'wardenName': _wardenController.text,
                        'phone': _phoneController.text,
                        'email': _emailController.text,
                      },
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
