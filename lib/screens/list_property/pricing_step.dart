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
  
  late TextEditingController _singleDepositController;
  late TextEditingController _doubleDepositController;
  late TextEditingController _tripleDepositController;
  
  late TextEditingController _noticePeriodController;
  bool _isFoodIncluded = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData?['pricing'] ?? {};
    
    _singleRentController = TextEditingController(text: data['singleRent'] ?? '');
    _doubleRentController = TextEditingController(text: data['doubleRent'] ?? '');
    _tripleRentController = TextEditingController(text: data['tripleRent'] ?? '');
    
    _singleDepositController = TextEditingController(text: data['singleDeposit'] ?? '');
    _doubleDepositController = TextEditingController(text: data['doubleDeposit'] ?? '');
    _tripleDepositController = TextEditingController(text: data['tripleDeposit'] ?? '');
    
    _noticePeriodController = TextEditingController(text: data['noticePeriod'] ?? '30 Days');
    _isFoodIncluded = data['foodIncluded'] ?? false;

    // Add listeners for auto-calculating 2x rent as default security deposit
    _singleRentController.addListener(() => _autoUpdateDeposit(_singleRentController, _singleDepositController));
    _doubleRentController.addListener(() => _autoUpdateDeposit(_doubleRentController, _doubleDepositController));
    _tripleRentController.addListener(() => _autoUpdateDeposit(_tripleRentController, _tripleDepositController));
  }

  void _autoUpdateDeposit(TextEditingController rentCtrl, TextEditingController depositCtrl) {
    if (depositCtrl.text.isEmpty) {
      final rentValue = double.tryParse(rentCtrl.text) ?? 0;
      if (rentValue > 0) {
        depositCtrl.text = (rentValue * 2).toInt().toString();
      }
    }
  }

  @override
  void dispose() {
    _singleRentController.dispose();
    _doubleRentController.dispose();
    _tripleRentController.dispose();
    _singleDepositController.dispose();
    _doubleDepositController.dispose();
    _tripleDepositController.dispose();
    _noticePeriodController.dispose();
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
            _buildSectionTitle('MONTHLY RENT'),
            const SizedBox(height: 16),
            _buildRentAndDepositPair(
              rentLabel: 'Single Sharing Rent',
              rentController: _singleRentController,
              depositLabel: 'Single Security Deposit',
              depositController: _singleDepositController,
            ),
            const SizedBox(height: 16),
            _buildRentAndDepositPair(
              rentLabel: 'Double Sharing Rent',
              rentController: _doubleRentController,
              depositLabel: 'Double Security Deposit',
              depositController: _doubleDepositController,
            ),
            const SizedBox(height: 16),
            _buildRentAndDepositPair(
              rentLabel: 'Triple Sharing Rent',
              rentController: _tripleRentController,
              depositLabel: 'Triple Security Deposit',
              depositController: _tripleDepositController,
            ),
            
            const SizedBox(height: 24),
            _buildLegalNote(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('OTHER TERMS'),
            const SizedBox(height: 16),
            DropdownField(
              label: 'Notice Period',
              controller: _noticePeriodController,
              required: true,
              items: const ['15 Days', '30 Days', '45 Days', '60 Days'],
              activeColor: AppTheme.successColor,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Food Included?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkColor,
                  ),
                ),
                Row(
                  children: [
                    _buildToggleButton(
                      'Yes',
                      _isFoodIncluded,
                      () => setState(() => _isFoodIncluded = true),
                    ),
                    const SizedBox(width: 12),
                    _buildToggleButton(
                      'No',
                      !_isFoodIncluded,
                      () => setState(() => _isFoodIncluded = false),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
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
                        'singleDeposit': _singleDepositController.text,
                        'doubleDeposit': _doubleDepositController.text,
                        'tripleDeposit': _tripleDepositController.text,
                        'deposit': _singleDepositController.text, // Legacy fallback
                        'noticePeriod': _noticePeriodController.text,
                        'foodIncluded': _isFoodIncluded,
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.textMutedColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildRentAndDepositPair({
    required String rentLabel,
    required TextEditingController rentController,
    required String depositLabel,
    required TextEditingController depositController,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InputField(
            label: rentLabel,
            controller: rentController,
            required: false, // Optional sharing types
            keyboardType: TextInputType.number,
            prefix: '₹ ',
            activeColor: AppTheme.successColor,
          ),
          const SizedBox(height: 8),
          InputField(
            label: depositLabel,
            controller: depositController,
            required: false,
            keyboardType: TextInputType.number,
            prefix: '₹ ',
            activeColor: AppTheme.successColor,
            hintText: 'Defaults to 2x Rent',
          ),
        ],
      ),
    );
  }

  Widget _buildLegalNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Standard Security Deposit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'As per Indian business standards and the Model Tenancy Act, security deposits are typically 2 months of rent. We auto-calculate this for you, but you can override it if needed.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
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
          border: Border.all(
            color: isSelected ? AppTheme.successColor : Colors.grey.shade200,
          ),
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
