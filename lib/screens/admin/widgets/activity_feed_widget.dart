import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityFeedWidget extends StatefulWidget {
  final List<Map<String, dynamic>> activities;

  const ActivityFeedWidget({super.key, required this.activities});

  @override
  State<ActivityFeedWidget> createState() => _ActivityFeedWidgetState();
}

class _ActivityFeedWidgetState extends State<ActivityFeedWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ActivityFeedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activities.length > oldWidget.activities.length) {
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Live Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Live',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (widget.activities.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No Activity Available',
                style: TextStyle(color: Colors.white24, fontSize: 13),
              ),
            ),
          )
        else
          SizedBox(
            height: 400, // Fixed height for auto-scrolling feed
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.activities.length,
              itemBuilder: (context, index) => _ActivityItem(activity: widget.activities[index]),
            ),
          ),
        
        if (widget.activities.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'View All Activity',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final timestamp = activity['timestamp'];
    final timeStr = timestamp != null 
        ? DateFormat('hh:mm a').format((timestamp as dynamic).toDate())
        : 'Now';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getIconColor(activity['type']).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(activity['type']),
              color: _getIconColor(activity['type']),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    children: [
                      TextSpan(
                        text: activity['action'] ?? 'Action performed',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (activity['property'] != null)
                  Text(
                    activity['property'],
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'property': return Icons.home_work_rounded;
      case 'booking': return Icons.bookmark_rounded;
      case 'payment': return Icons.payments_rounded;
      case 'complaint': return Icons.report_problem_rounded;
      case 'hoster': return Icons.person_rounded;
      default: return Icons.info_rounded;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'property': return const Color(0xFF6366F1);
      case 'booking': return const Color(0xFFF59E0B);
      case 'payment': return const Color(0xFF10B981);
      case 'complaint': return const Color(0xFFEF4444);
      case 'hoster': return const Color(0xFFA855F7);
      default: return Colors.white38;
    }
  }
}
