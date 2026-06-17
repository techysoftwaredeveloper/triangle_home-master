import 'package:flutter/material.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/lifecycle_models.dart';
import 'package:triangle_home/models/resident_stay.dart';
import 'package:triangle_home/services/stay_lifecycle_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CheckoutWizardScreen extends StatefulWidget {
  final ResidentStayModel stay;

  const CheckoutWizardScreen({super.key, required this.stay});

  @override
  State<CheckoutWizardScreen> createState() => _CheckoutWizardScreenState();
}

class _CheckoutWizardScreenState extends State<CheckoutWizardScreen> {
  final StayLifecycleService _lifecycleService = StayLifecycleService();
  int _currentStep = 0;
  bool _isValidating = true;
  CheckoutValidationResult? _validationResult;

  // Step 2: Inspection Data
  InspectionCondition _condition = InspectionCondition.good;
  final TextEditingController _damageNotesController = TextEditingController();

  // Step 3: Settlement Data
  final List<DepositDeduction> _deductions = [];
  final double _originalDeposit = 5000; // Mocked

  @override
  void initState() {
    super.initState();
    _performInitialValidation();
  }

  Future<void> _performInitialValidation() async {
    final result = await _lifecycleService.validateCheckout(widget.stay.id);
    if (mounted) {
      setState(() {
        _validationResult = result;
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Checkout Wizard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDarkColor,
        elevation: 0,
      ),
      body:
          _isValidating
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildStepIndicator(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildCurrentStep(),
                    ),
                  ),
                  _buildBottomNav(),
                ],
              ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: const Color(0xFFF8FAFC),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) => _stepCircle(index)),
      ),
    );
  }

  Widget _stepCircle(int index) {
    bool isDone = _currentStep > index;
    bool isActive = _currentStep == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color:
            isDone
                ? AppTheme.successColor
                : (isActive ? AppTheme.primaryColor : Colors.grey[300]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child:
            isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildValidationStep();
      case 1:
        return _buildInspectionStep();
      case 2:
        return _buildSettlementStep();
      case 3:
        return _buildFinalStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildValidationStep() {
    final bool passed = _validationResult?.canCheckout ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pre-Checkout Verification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'The system automatically checks for pending dues and tickets.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 32),
        _validationRow(
          'Overdue Rent',
          passed,
          passed
              ? 'No outstanding dues'
              : _validationResult?.reason ?? 'Check failed',
        ),
        _validationRow('Maintenance Tickets', passed, 'No open tickets'),
        _validationRow(
          'Move-Out Notice',
          widget.stay.status == StayStatus.noticeSubmitted,
          'Notice officially received',
        ),
        if (!passed) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Checkout Blocked: ${_validationResult?.reason}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _validationRow(String label, bool passed, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.grey[300],
            size: 24,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                detail,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Inspection',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        const Text(
          'Overall Condition',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.textMutedColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _conditionChip(
              InspectionCondition.excellent,
              'Excellent',
              Colors.green,
            ),
            const SizedBox(width: 8),
            _conditionChip(InspectionCondition.good, 'Good', Colors.blue),
            const SizedBox(width: 8),
            _conditionChip(InspectionCondition.damaged, 'Damaged', Colors.red),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Damage Notes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.textMutedColor,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _damageNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe any damages or missing assets...',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Inspection Photos *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.textMutedColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
              style: BorderStyle.none,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.add_a_photo_rounded,
              color: Colors.grey,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _conditionChip(InspectionCondition val, String label, Color color) {
    bool isSelected = _condition == val;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (s) => setState(() => _condition = val),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? color : Colors.transparent),
      ),
    );
  }

  Widget _buildSettlementStep() {
    final totals = _lifecycleService.calculateSettlement(
      _originalDeposit,
      _deductions,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deposit Settlement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        _amountSummary('Original Deposit', _originalDeposit),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Deductions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Deduction'),
            ),
          ],
        ),
        if (_deductions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No deductions added',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          )
        else
          ..._deductions.map(
            (d) => ListTile(
              title: Text(d.reason),
              trailing: Text('- ₹${d.amount}'),
            ),
          ),
        const Divider(height: 32),
        _amountSummary(
          'Total Deduction',
          totals['deductionTotal']!,
          color: Colors.red,
        ),
        const SizedBox(height: 8),
        _amountSummary(
          'Refund Amount',
          totals['refundAmount']!,
          color: AppTheme.successColor,
          isBold: true,
        ),
      ],
    );
  }

  Widget _amountSummary(
    String label,
    double val, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? AppTheme.textDarkColor : AppTheme.textMutedColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${NumberFormat('#,##,###').format(val)}',
          style: TextStyle(
            color: color ?? AppTheme.textDarkColor,
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFinalStep() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          const Icon(
            Icons.verified_user_rounded,
            size: 80,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 32),
          const Text(
            'Final Confirmation',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Proceeding will mark the stay as completed and physically release the bed back to available inventory.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _summaryRow(
                  'Resident',
                  widget.stay.residentId.substring(0, 8).toUpperCase(),
                ),
                _summaryRow('Bed ID', widget.stay.bedId),
                _summaryRow('Refund', '₹4,500'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Back'),
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  (_validationResult?.canCheckout == false && _currentStep == 0)
                      ? null
                      : () {
                        if (_currentStep < 3) {
                          setState(() => _currentStep++);
                        } else {
                          // Execute finalizeCheckout transaction
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 3 ? 'Finalize Release' : 'Next Step',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
