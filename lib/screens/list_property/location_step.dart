import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class LocationStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const LocationStep({super.key, required this.onContinue, this.initialData});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _localityController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData?['location'] ?? {};
    _addressController = TextEditingController(text: data['address'] ?? '');
    _localityController = TextEditingController(text: data['locality'] ?? '');
    _cityController = TextEditingController(text: data['city'] ?? '');
    _pincodeController = TextEditingController(text: data['pincode'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            InputField(
              label: 'Full Address',
              controller: _addressController,
              required: true,
              hintText: 'Building No, Street, Area',
              maxLines: 2,
              activeColor: AppTheme.successColor,
            ),
            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Locality',
                    controller: _localityController,
                    required: true,
                    activeColor: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InputField(
                    label: 'City',
                    controller: _cityController,
                    required: true,
                    activeColor: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            InputField(
              label: 'Pincode',
              controller: _pincodeController,
              required: true,
              keyboardType: TextInputType.number,
              activeColor: AppTheme.successColor,
            ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_rounded, color: AppTheme.successColor, size: 32),
                    const SizedBox(height: 8),
                    const Text('Mark on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Drag pin to exact location', style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onContinue({
                      'location': {
                        'address': _addressController.text,
                        'locality': _localityController.text,
                        'city': _cityController.text,
                        'pincode': _pincodeController.text,
                      }
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
