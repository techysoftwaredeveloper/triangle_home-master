import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';

class ProgressBar extends StatelessWidget {
  final int currentStep;

  const ProgressBar({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final bool isActive = index <= currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryColor
                              : AppTheme.dividerColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ] : null,
                        ),
                      ),
                    ),
                    if (index < 3) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepTitle(currentStep),
                style: const TextStyle(
                  color: AppTheme.textDarkColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              Text(
                'Step ${currentStep + 1} of 4',
                style: const TextStyle(
                  color: AppTheme.textMutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Basic Information';
      case 1: return 'Banking Details';
      case 2: return 'Property Photos';
      case 3: return 'Pricing & Address';
      default: return '';
    }
  }
}
