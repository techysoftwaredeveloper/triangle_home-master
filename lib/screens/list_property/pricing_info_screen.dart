import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/property_management_screen.dart';
import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class PricingInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;

  const PricingInfoScreen({super.key, required this.onContinue});

  @override
  State<PricingInfoScreen> createState() => _PricingInfoScreenState();
}

class _PricingInfoScreenState extends State<PricingInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _price1Controller = TextEditingController(text: '7,500');
  final _price2Controller = TextEditingController(text: '7,500');
  final _price3Controller = TextEditingController(text: '7,500');
  final _price4Controller = TextEditingController(text: '5,300');
  final _addressLine1Controller = TextEditingController(text: '14/44');
  final _addressLine2Controller = TextEditingController(
    text: '4th Cross Street',
  );
  final _localityController = TextEditingController(text: 'Anna Nagar');
  final _cityController = TextEditingController(text: 'Chennai');
  final _stateController = TextEditingController(text: 'Tamil Nadu');

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
              'Pricing and Address Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            const Text(
              'Pricing Details:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            InputField(
              label: 'Men - 1 Sharing | Yearly (In Rupees)',
              controller: _price1Controller,
              required: true,
              keyboardType: TextInputType.number,
              prefix: '₹',
              maxLines: 2,
            ),
            InputField(
              label: 'Men - 2 Sharing | Yearly (In Rupees)',
              controller: _price2Controller,
              required: true,
              keyboardType: TextInputType.number,
              prefix: '₹',
              maxLines: 2,
            ),
            InputField(
              label: 'Men - 3 Sharing | Yearly (In Rupees)',
              controller: _price3Controller,
              required: true,
              keyboardType: TextInputType.number,
              prefix: '₹',
              maxLines: 2,
            ),
            InputField(
              label: 'Men - 4 Sharing | Yearly (In Rupees)',
              controller: _price4Controller,
              required: true,
              keyboardType: TextInputType.number,
              prefix: '₹',
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text(
              'Address And Location:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            InputField(
              label: 'Address Line 1',
              controller: _addressLine1Controller,
              required: true,
              maxLines: 3,
            ),
            InputField(
              label: 'Address Line 2',
              controller: _addressLine2Controller,
              maxLines: 3,
            ),
            InputField(
              label: 'Locality',
              controller: _localityController,
              required: true,
              maxLines: 3,
            ),
            InputField(
              label: 'City',
              controller: _cityController,
              required: true,
              maxLines: 3,
            ),
            DropdownField(
              label: 'State',
              controller: _stateController,
              items: const [
                'Tamil Nadu',
                'Karnataka',
                'Kerala',
                'Andhra Pradesh',
              ],
              required: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onContinue({
                      '1 sharing': _price1Controller.text,
                      '2 sharing': _price2Controller.text,
                      '3 sharing': _price3Controller.text,
                      '4 sharing': _price4Controller.text,
                      'addressLine1': _addressLine1Controller.text,
                      'addressLine2': _addressLine2Controller.text,
                      'locality': _localityController.text,
                      'city': _cityController.text,
                      'state': _stateController.text,
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PropertyManagementScreen(),
                      ),
                    );
                  }
                },
                // onPressed: () {
                //   if (_formKey.currentState?.validate() ?? false) {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => const PropertyManagementScreen(),
                //       ),
                //     );
                //   }
                // },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
