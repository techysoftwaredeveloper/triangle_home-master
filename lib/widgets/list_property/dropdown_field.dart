import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class DropdownField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> items;
  final bool required;
  final Function(String)? onChanged;
  final Color? activeColor;

  const DropdownField({
    super.key,
    required this.label,
    required this.controller,
    required this.items,
    this.required = false,
    this.onChanged,
    this.activeColor,
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
          GestureDetector(
            onTap: () => _showDropdownDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      controller.text.isEmpty
                          ? 'Select $label'
                          : controller.text,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            controller.text.isEmpty
                                ? AppTheme.textMutedColor
                                : AppTheme.textColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: AppTheme.textMutedColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDropdownDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select $label',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.fontFamily,
                          color: AppTheme.textDarkColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textMutedColor,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = controller.text == item;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color:
                              isSelected
                                  ? (activeColor ?? AppTheme.primaryColor)
                                      .withValues(alpha: 0.05)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            title: Text(
                              item,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? (activeColor ?? AppTheme.primaryColor)
                                        : AppTheme.textColor,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                            trailing:
                                isSelected
                                    ? Icon(
                                      Icons.check_circle_rounded,
                                      color:
                                          activeColor ?? AppTheme.primaryColor,
                                    )
                                    : null,
                            onTap: () {
                              controller.text = item;
                              if (onChanged != null) onChanged!(item);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}
