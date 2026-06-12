import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final String? prefix;
  final int maxLines;
  final String? hintText;
  final Color? activeColor;
  final Widget? suffix;
  final bool readOnly;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.prefix,
    this.maxLines = 1,
    this.hintText,
    this.activeColor,
    this.suffix,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDarkColor,
                  fontFamily: AppTheme.fontFamily,
                ),
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                ],
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            readOnly: readOnly,
            style: TextStyle(
              fontSize: 15,
              color: readOnly ? AppTheme.textLightColor : AppTheme.textColor,
              fontFamily: AppTheme.fontFamily,
            ),
            decoration: InputDecoration(
              hintText: hintText ?? 'Enter $label',
              hintStyle: const TextStyle(
                color: AppTheme.textMutedColor,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixText: prefix,
              prefixStyle: TextStyle(
                color: activeColor ?? AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              suffixIcon: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: activeColor ?? AppTheme.primaryColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator:
                validator ??
                (required
                    ? (value) {
                      if (value == null || value.isEmpty) {
                        return '$label is required';
                      }
                      return null;
                    }
                    : null),
          ),
        ],
      ),
    );
  }
}
