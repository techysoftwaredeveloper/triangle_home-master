import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double? completionPercentage;
  final Function(int)? onStepTap;

  const ProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 9,
    this.completionPercentage,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final bool isActive = index <= currentStep;
              return Expanded(
                child: GestureDetector(
                  onTap: (onStepTap != null && index < currentStep) ? () => onStepTap!(index) : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? AppTheme.primaryColor
                                    : AppTheme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (index < totalSteps - 1) const SizedBox(width: 4),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStepTitle(currentStep),
                    style: const TextStyle(
                      color: AppTheme.textDarkColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  if (completionPercentage != null)
                    Text(
                      'Overall Completion: ${(completionPercentage! * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: const TextStyle(
                  color: AppTheme.textMutedColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Property Basics';
      case 1:
        return 'Location';
      case 2:
        return 'Property Details';
      case 3:
        return 'Amenities';
      case 4:
        return 'Photos';
      case 5:
        return 'Pricing';
      case 6:
        return 'Documents';
      case 7:
        return 'Host Profile';
      default:
        return '';
    }
  }
}
