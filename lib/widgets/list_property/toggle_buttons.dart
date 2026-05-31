import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

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
        spacing: 12,
        runSpacing: 12,
        children: options.map((option) => _buildButton(context, option)).toList(),
      );
    }

    return Row(
      children: options.map((option) {
        final button = _buildButton(context, option);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option != options.last ? 12 : 0,
            ),
            child: button,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButton(BuildContext context, String option) {
    final isSelected = selectedOption == option;
    return InkWell(
      onTap: () => onOptionSelected(option),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Center(
          child: Text(
            option,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textLightColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
      ),
    );
  }
}
