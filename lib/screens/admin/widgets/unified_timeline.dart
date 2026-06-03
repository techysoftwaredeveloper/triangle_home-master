import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/admin/timeline_aggregator_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class UnifiedTimeline extends StatelessWidget {
  final String bookingId;

  const UnifiedTimeline({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final TimelineAggregatorService aggregator = TimelineAggregatorService();

    return StreamBuilder<List<TimelineEvent>>(
      stream: aggregator.getUnifiedTimeline(bookingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'No events found for this booking',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _TimelineItem(
              event: events[index],
              isLast: index == events.length - 1,
            );
          },
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndicator(),
          const SizedBox(width: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    final Color color = _getSeverityColor(event.severity);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(_getCategoryIcon(event.category), size: 16, color: color),
        ),
        if (!isLast)
          Expanded(child: Container(width: 2, color: Colors.grey[200])),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDarkColor,
                  fontFamily: 'Outfit',
                ),
              ),
              Text(
                DateFormat('hh:mm a').format(event.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (event.description.isNotEmpty)
            Text(
              event.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 12,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                'By ${event.performer}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                  fontFamily: 'Outfit',
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy').format(event.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(TimelineCategory category) {
    switch (category) {
      case TimelineCategory.booking:
        return Icons.book_rounded;
      case TimelineCategory.payment:
        return Icons.payments_rounded;
      case TimelineCategory.financial:
        return Icons.account_balance_wallet_rounded;
      case TimelineCategory.dispute:
        return Icons.report_problem_rounded;
      case TimelineCategory.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  Color _getSeverityColor(TimelineSeverity severity) {
    switch (severity) {
      case TimelineSeverity.info:
        return AppTheme.successColor;
      case TimelineSeverity.warning:
        return Colors.orange;
      case TimelineSeverity.critical:
        return Colors.red;
    }
  }
}
