import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class HouseRulesCard extends StatelessWidget {
  final List<dynamic> rules;

  const HouseRulesCard({super.key, required this.rules});

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules.map((rule) => _buildRuleItem(rule.toString())).toList(),
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getRuleIcon(rule),
            size: 18,
            color: _getRuleColor(rule),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rule,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRuleIcon(String rule) {
    final r = rule.toLowerCase();
    if (r.contains('smoking')) return Icons.smoke_free;
    if (r.contains('outsider') || r.contains('visitor')) return Icons.person_off_outlined;
    if (r.contains('quiet') || r.contains('silence') || r.contains('noise')) return Icons.volume_off_outlined;
    if (r.contains('clean') || r.contains('hygiene')) return Icons.cleaning_services_outlined;
    if (r.contains('time') || r.contains('pm') || r.contains('am')) return Icons.access_time;
    if (r.contains('pet')) return Icons.pets_outlined;
    if (r.contains('alcohol') || r.contains('drink')) return Icons.no_drinks;
    return Icons.info_outline;
  }

  Color _getRuleColor(String rule) {
    final r = rule.toLowerCase();
    if (r.contains('no ') || r.contains('don\'t') || r.contains('not allowed')) {
      return Colors.red[400]!;
    }
    return AppTheme.primaryColor;
  }
}
