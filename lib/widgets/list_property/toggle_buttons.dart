
import 'package:flutter/material.dart';

class CustomToggleButtons extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final Function(String) onOptionSelected;
  final bool wrap;

  const CustomToggleButtons({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    this.wrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) => _buildButton(context, option)).toList(),
      );
    }

    return Row(
      children: options.map((option) {
        final button = _buildButton(context, option);
        return Expanded(child: Padding(
          padding: EdgeInsets.only(
            right: option != options.last ? 8 : 0,
          ),
          child: button,
        ));
      }).toList(),
    );
  }

  Widget _buildButton(BuildContext context, String option) {
    final isSelected = selectedOption == option;
    return InkWell(
      onTap: () => onOptionSelected(option),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            option,
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
