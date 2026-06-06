import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class RoleStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> initialData;

  const RoleStep({super.key, required this.onContinue, required this.initialData});

  @override
  State<RoleStep> createState() => _RoleStepState();
}

class _RoleStepState extends State<RoleStep> {
  String? _selectedRole;

  final List<Map<String, dynamic>> _roles = [
    {'id': 'owner', 'title': 'Property Owner', 'desc': 'I own the property and want to host.', 'icon': Icons.home_rounded},
    {'id': 'manager', 'title': 'Property Manager', 'desc': 'I manage properties for others.', 'icon': Icons.manage_accounts_rounded},
    {'id': 'agency', 'title': 'Real Estate Agency', 'desc': 'We are a registered business/firm.', 'icon': Icons.business_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialData['role'];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select your partnership role',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us how you plan to host on Triangle Homes.',
            style: TextStyle(color: AppTheme.textLightColor),
          ),
          const SizedBox(height: 32),
          ..._roles.map((role) {
            final isSelected = _selectedRole == role['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = role['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.successColor.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppTheme.successColor : Colors.grey[200]!, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(role['icon'], color: isSelected ? AppTheme.successColor : Colors.grey, size: 32),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(role['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(role['desc'], style: TextStyle(color: AppTheme.textLightColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: AppTheme.successColor),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRole != null ? () => widget.onContinue({'role': _selectedRole}) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
