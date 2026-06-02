import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class PricingStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const PricingStep({super.key, required this.onContinue, this.initialData});

  @override
  State<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends State<PricingStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _singleRentController;
  late TextEditingController _doubleRentController;
  late TextEditingController _tripleRentController;
  late TextEditingController _depositController;
  late TextEditingController _noticePeriodController;
  bool _isFoodIncluded = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData?['pricing'] ?? {};
    _singleRentController = TextEditingController(text: data['singleRent'] ?? '');
    _doubleRentController = TextEditingController(text: data['doubleRent'] ?? '');
    _tripleRentController = TextEditingController(text: data['tripleRent'] ?? '');
    _depositController = TextEditingController(text: data['deposit'] ?? '');
    _noticePeriodController = TextEditingController(text: data['noticePeriod'] ?? '30 Days');
    _isFoodIncluded = data['foodIncluded'] ?? false;
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
              label: 'Single Room Rent (Monthly)',
              controller: _singleRentController,
              required: true,
              keyboardType: TextInputType.number,
              prefix: '₹ ',
              activeColor: AppTheme.successColor,
            ),
            InputField(
              label: 'Double Room Rent (Monthly)',
              controller: _doubleRentController,
              required: true,
              keyboardType: TextInputType.number,
              prefix: '₹ ',
              activeColor: AppTheme.successColor,
            ),
            InputField(
              label: 'Triple Room Rent (Monthly)',
              controller: _tripleRentController,
              required: true,
              keyboardType: TextInputType.number,
              prefix: '₹ ',
              activeColor: AppTheme.successColor,
            ),
            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Security Deposit',
                    controller: _depositController,
                    required: true,
                    keyboardType: TextInputType.number,
                    prefix: '₹ ',
                    activeColor: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownField(
                    label: 'Notice Period',
                    controller: _noticePeriodController,
                    required: true,
                    items: const ['15 Days', '30 Days', '45 Days', '60 Days'],
                    activeColor: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Food Included?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor)),
                Row(
                  children: [
                    _buildToggleButton('Yes', _isFoodIncluded, () => setState(() => _isFoodIncluded = true)),
                    const SizedBox(width: 12),
                    _buildToggleButton('No', !_isFoodIncluded, () => setState(() => _isFoodIncluded = false)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onContinue({
                      'pricing': {
                        'singleRent': _singleRentController.text,
                        'doubleRent': _doubleRentController.text,
                        'tripleRent': _tripleRentController.text,
                        'deposit': _depositController.text,
                        'noticePeriod': _noticePeriodController.text,
                        'foodIncluded': _isFoodIncluded,
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

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.successColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.successColor : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textMutedColor,
          ),
        ),
      ),
    );
  }
}
