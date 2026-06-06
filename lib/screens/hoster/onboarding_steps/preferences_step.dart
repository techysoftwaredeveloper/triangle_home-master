import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class PreferencesStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> initialData;

  const PreferencesStep({super.key, required this.onContinue, required this.initialData});

  @override
  State<PreferencesStep> createState() => _PreferencesStepState();
}

class _PreferencesStepState extends State<PreferencesStep> {
  final List<String> _preferredTenants = [];
  String? _preferredGender;

  @override
  void initState() {
    super.initState();
    if (widget.initialData['preferredTenants'] != null) {
      _preferredTenants.addAll(List<String>.from(widget.initialData['preferredTenants']));
    }
    _preferredGender = widget.initialData['preferredGender'];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hosting Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 32),
          const Text('Preferred Tenant Types', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Students', 'Professionals', 'Families', 'Bachelors'].map((type) {
              final isSelected = _preferredTenants.contains(type);
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _preferredTenants.add(type);
                    } else {
                      _preferredTenants.remove(type);
                    }
                  });
                },
                selectedColor: AppTheme.successColor.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.successColor,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text('Gender Preference', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: ['Male', 'Female', 'Any'].map((g) {
              final isSelected = _preferredGender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _preferredGender = g),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.successColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        g,
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onContinue({
                'preferredTenants': _preferredTenants,
                'preferredGender': _preferredGender,
              }),
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
    );
  }
}
