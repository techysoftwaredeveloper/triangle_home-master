import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class HostProfileStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const HostProfileStep({
    super.key,
    required this.onContinue,
    this.initialData,
  });

  @override
  State<HostProfileStep> createState() => _HostProfileStepState();
}

class _HostProfileStepState extends State<HostProfileStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedHostType = 'Property Owner';

  final List<Map<String, dynamic>> _hostTypes = [
    {'label': 'Property Owner', 'icon': Icons.home_rounded},
    {'label': 'Hostel Operator', 'icon': Icons.business_rounded},
    {'label': 'PG Owner', 'icon': Icons.apartment_rounded},
    {'label': 'Property Manager', 'icon': Icons.person_pin_rounded},
    {'label': 'Real Estate Agency', 'icon': Icons.corporate_fare_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData?['hostProfile'] ?? {};
    _nameController = TextEditingController(text: data['name'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _selectedHostType = data['hostType'] ?? 'Property Owner';
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
              'Basic Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 20),
            InputField(
              label: 'Full Name',
              controller: _nameController,
              required: true,
              hintText: 'Enter your legal name',
            ),
            InputField(
              label: 'Email Address',
              controller: _emailController,
              required: true,
              keyboardType: TextInputType.emailAddress,
              hintText: 'yourname@example.com',
            ),
            InputField(
              label: 'Phone Number',
              controller: _phoneController,
              required: true,
              keyboardType: TextInputType.phone,
              prefix: '+91 ',
            ),
            const SizedBox(height: 24),
            const Text(
              'Host Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _hostTypes.length,
              itemBuilder: (context, index) {
                final type = _hostTypes[index];
                final isSelected = _selectedHostType == type['label'];
                return InkWell(
                  onTap:
                      () => setState(() => _selectedHostType = type['label']),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppTheme.successColor.withValues(alpha: 0.05)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppTheme.successColor
                                : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          type['icon'],
                          color:
                              isSelected
                                  ? AppTheme.successColor
                                  : AppTheme.textMutedColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            type['label'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                              color:
                                  isSelected
                                      ? AppTheme.successColor
                                      : AppTheme.textDarkColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onContinue({
                      'hostProfile': {
                        'name': _nameController.text,
                        'email': _emailController.text,
                        'phone': _phoneController.text,
                        'hostType': _selectedHostType,
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
