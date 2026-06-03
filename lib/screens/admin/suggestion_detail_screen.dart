import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';

class SuggestionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> suggestion;
  final AdminService adminService;

  const SuggestionDetailScreen({
    super.key,
    required this.suggestion,
    required this.adminService,
  });

  @override
  State<SuggestionDetailScreen> createState() => _SuggestionDetailScreenState();
}

class _SuggestionDetailScreenState extends State<SuggestionDetailScreen> {
  late Map<String, dynamic> _currentSuggestion;

  @override
  void initState() {
    super.initState();
    _currentSuggestion = widget.suggestion;
  }

  String _formatStatus(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'pending' || status == 'under review') return 'Pending';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    switch (status) {
      case 'contacted':
        return Colors.blue;
      case 'shortlisted':
        return Colors.purple;
      case 'converted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _handleAction(String action) async {
    try {
      await widget.adminService.updateSuggestionStatus(
        _currentSuggestion['id'],
        action,
      );
      if (mounted) {
        setState(() {
          _currentSuggestion['status'] = action;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _currentSuggestion;
    final statusText = _formatStatus(s['status']);
    final statusColor = _getStatusColor(s['status']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lead Details',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.home_work_outlined,
                      color: Colors.grey,
                      size: 60,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: StatusBadge(text: statusText, color: statusColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              s['business_name'] ?? 'Untitled',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s['category'] ?? 'Accommodation',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),

            const Divider(height: 48),
            _detailTitle('Business Location'),
            _iconDetail(
              Icons.location_on_outlined,
              s['business_address'] ?? 'Location N/A',
              '',
            ),

            const Divider(height: 48),
            _detailTitle('Business Owner'),
            Text(
              s['owner_name'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              s['owner_phone'] ?? 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              s['owner_email'] ?? 'N/A',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),

            const Divider(height: 48),
            _detailTitle('Suggested By'),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF5F3FF),
                  child: Text(
                    s['suggester_name']?.toString().isNotEmpty == true
                        ? s['suggester_name'][0]
                        : 'U',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['suggester_name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'Community Member',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              s['suggester_phone'] ?? 'No Phone',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              s['suggester_email'] ?? 'No Email',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 48),
            _actionBtn(
              'Mark as Contacted',
              const Color(0xFFF5F3FF),
              const Color(0xFF7C3AED),
              Icons.phone_in_talk_outlined,
              () => _handleAction('contacted'),
            ),
            const SizedBox(height: 12),
            _actionBtn(
              'Mark as Shortlisted',
              const Color(0xFFEFF6FF),
              const Color(0xFF2563EB),
              Icons.star_outline_rounded,
              () => _handleAction('shortlisted'),
            ),
            const SizedBox(height: 12),
            _actionBtn(
              'Mark as Converted',
              const Color(0xFFF0FDF4),
              const Color(0xFF16A34A),
              Icons.check_circle_outline_rounded,
              () => _handleAction('converted'),
            ),
            const SizedBox(height: 12),
            _actionBtn(
              'Reject Lead',
              const Color(0xFFFEF2F2),
              const Color(0xFFDC2626),
              Icons.cancel_outlined,
              () => _handleAction('rejected'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      t.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 1,
      ),
    ),
  );

  Widget _iconDetail(IconData i, String t, String s) => Row(
    children: [
      Icon(i, size: 20, color: const Color(0xFF2563EB)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (s.isNotEmpty)
              Text(
                s,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _actionBtn(
    String l,
    Color bg,
    Color t,
    IconData i,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, size: 18, color: t),
          const SizedBox(width: 10),
          Text(
            l,
            style: TextStyle(
              color: t,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}
