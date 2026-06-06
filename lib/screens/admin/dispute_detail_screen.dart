import 'package:flutter/material.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/dispute.dart';
import 'package:triangle_home/screens/admin/widgets/evidence_viewer.dart';
import 'package:triangle_home/screens/admin/widgets/unified_timeline.dart';
import 'package:triangle_home/services/admin/admin_dispute_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';

class DisputeDetailScreen extends StatefulWidget {
  final DisputeModel dispute;

  const DisputeDetailScreen({super.key, required this.dispute});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  final AdminDisputeService _disputeService = AdminDisputeService();
  bool _isProcessing = false;
  final TextEditingController _noteController = TextEditingController();

  Future<void> _updateStatus(DisputeStatus status) async {
    setState(() => _isProcessing = true);
    try {
      await _disputeService.updateDisputeStatus(
        disputeId: widget.dispute.id,
        bookingId: widget.dispute.bookingId,
        newStatus: status,
        adminId: 'ADMIN_001', // Mocking current admin
        resolutionNote: _noteController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dispute status updated to ${status.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Dispute Case',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDarkColor,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSectionTitle('Statement'),
                _buildStatement(),
                const SizedBox(height: 32),
                _buildSectionTitle('Evidence'),
                EvidenceViewer(evidence: widget.dispute.evidence),
                const SizedBox(height: 32),
                _buildSectionTitle('Case Timeline'),
                UnifiedTimeline(bookingId: widget.dispute.bookingId),
                const SizedBox(height: 32),
                _buildSectionTitle('Resolution Note'),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a decision or note for the parties...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          _buildBottomActions(),
          if (_isProcessing)
            Container(
              color: Colors.white.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CASE #${widget.dispute.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMutedColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.dispute.category.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkColor,
                    ),
                  ),
                ],
              ),
              _StatusBadge(status: widget.dispute.status),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _headerMeta(
                'Opened On',
                DateFormat('dd MMM yyyy').format(widget.dispute.createdAt),
              ),
              _headerMeta('Booking ID', widget.dispute.bookingId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textMutedColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatement() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Primary Complaint:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.dispute.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDarkColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final s = widget.dispute.status;
    if (s == DisputeStatus.resolved || s == DisputeStatus.rejected) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(DisputeStatus.rejected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: Colors.red,
                  elevation: 0,
                ),
                child: const Text(
                  'Reject Case',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(DisputeStatus.resolved),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  elevation: 0,
                ),
                child: const Text(
                  'Resolve Dispute',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DisputeStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.orange;
    if (status == DisputeStatus.resolved) color = Colors.green;
    if (status == DisputeStatus.rejected) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
