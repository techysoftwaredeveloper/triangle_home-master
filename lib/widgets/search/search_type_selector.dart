import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

  const SearchTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildOptionButton(
            'By Area',
            selectedType == 'By Area',
            () => onTypeSelected('By Area'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionButton(
            'By College',
            selectedType == 'By College',
            () => onTypeSelected('By College'),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildOptionButton(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}