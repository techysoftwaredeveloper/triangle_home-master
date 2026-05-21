import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SuggestionDetailScreen extends StatefulWidget {
  final String suggestionId;
  final AdminService adminService;
  final Map<String, dynamic>? initialData;

  const SuggestionDetailScreen({
    super.key,
    required this.suggestionId,
    required this.adminService,
    this.initialData,
  });

  @override
  State<SuggestionDetailScreen> createState() => _SuggestionDetailScreenState();
}

class _SuggestionDetailScreenState extends State<SuggestionDetailScreen> {
  bool _isUpdating = false;

  String _formatStatus(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'pending' || status == 'under review') return 'Pending';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    switch (status) {
      case 'contacted': return const Color(0xFF7C3AED); // Purple
      case 'shortlisted': return const Color(0xFF2563EB); // Blue
      case 'converted': return const Color(0xFF16A34A); // Green
      case 'rejected': return const Color(0xFFDC2626); // Red
      default: return const Color(0xFFD97706); // Orange
    }
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(date.toDate());
    }
    if (date is String) {
      try {
        return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(date));
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }

  Future<void> _handleAction(String action) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);
    try {
      await widget.adminService.updateSuggestionStatus(widget.suggestionId, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lead marked as ${action.toUpperCase()}'),
            backgroundColor: _getStatusColor(action),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: widget.adminService.getSuggestionStream(widget.suggestionId),
      initialData: widget.initialData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final suggestion = snapshot.data;
        if (suggestion == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Suggestion not found')),
          );
        }

        final status = _formatStatus(suggestion['status']);
        final statusColor = _getStatusColor(suggestion['status']);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Lead Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Outfit',
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_left_rounded, color: Color(0xFF1E293B), size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(Icons.home_work_outlined, color: Color(0xFF94A3B8), size: 64),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: StatusBadge(text: status, color: statusColor),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title and Category
                    Text(
                      suggestion['business_name'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion['category'] ?? 'Accommodation',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                    const SizedBox(height: 16),

                    // Business Location
                    _buildSectionTitle('BUSINESS LOCATION'),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion['business_address'] ?? 'No Address Provided',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                    const SizedBox(height: 16),

                    // Business Owner
                    _buildSectionTitle('BUSINESS OWNER'),
                    const SizedBox(height: 12),
                    Text(
                      suggestion['owner_name'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion['owner_phone'] ?? 'N/A',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    ),
                    Text(
                      suggestion['owner_email'] ?? 'N/A',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                    const SizedBox(height: 16),

                    // Submission Date
                    _buildSectionTitle('SUBMISSION DATE'),
                    const SizedBox(height: 12),
                    Text(
                      _formatDateTime(suggestion['createdAt']),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                    const SizedBox(height: 16),

                    // Suggested By
                    _buildSectionTitle('SUGGESTED BY'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: Text(
                            suggestion['suggester_name']?.toString().isNotEmpty == true ? suggestion['suggester_name'][0] : 'U',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion['suggester_name'] ?? 'Unknown User',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                              ),
                              const Text(
                                'Community Member',
                                style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      suggestion['suggester_phone'] ?? 'No Phone',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                    ),
                    Text(
                      suggestion['suggester_email'] ?? 'No Email',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    _actionBtn(
                      'Mark as Contacted',
                      const Color(0xFFF5F3FF),
                      const Color(0xFF7C3AED),
                      Icons.phone_in_talk_outlined,
                      () => _handleAction('contacted'),
                      isActive: suggestion['status'] == 'contacted'
                    ),
                    const SizedBox(height: 12),
                    _actionBtn(
                      'Mark as Shortlisted',
                      const Color(0xFFEFF6FF),
                      const Color(0xFF2563EB),
                      Icons.star_outline_rounded,
                      () => _handleAction('shortlisted'),
                      isActive: suggestion['status'] == 'shortlisted'
                    ),
                    const SizedBox(height: 12),
                    _actionBtn(
                      'Mark as Converted',
                      const Color(0xFFF0FDF4),
                      const Color(0xFF16A34A),
                      Icons.check_circle_outline_rounded,
                      () => _handleAction('converted'),
                      isActive: suggestion['status'] == 'converted'
                    ),
                    const SizedBox(height: 12),
                    _actionBtn(
                      'Reject Lead',
                      const Color(0xFFFEF2F2),
                      const Color(0xFFDC2626),
                      Icons.cancel_outlined,
                      () => _handleAction('rejected'),
                      isActive: suggestion['status'] == 'rejected'
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              if (_isUpdating)
                Container(
                  color: Colors.white.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _actionBtn(String l, Color bg, Color t, IconData i, VoidCallback onTap, {bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? t : bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, size: 18, color: isActive ? Colors.white : t),
            const SizedBox(width: 8),
            Text(
              l,
              style: TextStyle(
                color: isActive ? Colors.white : t,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
