import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class AddressStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> initialData;

  const AddressStep({super.key, required this.onContinue, required this.initialData});

  @override
  State<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<AddressStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  String? _selectedState;

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    _address1Controller = TextEditingController(text: widget.initialData['address1'] ?? '');
    _address2Controller = TextEditingController(text: widget.initialData['address2'] ?? '');
    _cityController = TextEditingController(text: widget.initialData['city'] ?? '');
    _pincodeController = TextEditingController(text: widget.initialData['pincode'] ?? '');
    _selectedState = widget.initialData['state'];
  }

  @override
  void dispose() {
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            InputField(label: 'Address Line 1', controller: _address1Controller, required: true),
            const SizedBox(height: 16),
            InputField(label: 'Address Line 2 (Optional)', controller: _address2Controller),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: InputField(label: 'City', controller: _cityController, required: true)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('State', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLightColor)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedState,
                            hint: const Text('Select'),
                            items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
                            onChanged: (v) => setState(() => _selectedState = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InputField(label: 'Pincode', controller: _pincodeController, required: true, keyboardType: TextInputType.number),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _selectedState != null) {
                    widget.onContinue({
                      'address1': _address1Controller.text,
                      'address2': _address2Controller.text,
                      'city': _cityController.text,
                      'pincode': _pincodeController.text,
                      'state': _selectedState,
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
