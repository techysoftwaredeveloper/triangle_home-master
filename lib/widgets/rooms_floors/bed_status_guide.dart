import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class BedStatusGuide extends StatelessWidget {
  const BedStatusGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bed Status Guide',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildGuideItem(AppTheme.successGreen, 'Available'),
              const SizedBox(width: 24),
              _buildGuideItem(const Color(0xFF64748B), 'Occupied'),
              const SizedBox(width: 24),
              _buildGuideItem(AppTheme.primaryColor, 'Selected'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor),
        ),
      ],
    );
  }
}
