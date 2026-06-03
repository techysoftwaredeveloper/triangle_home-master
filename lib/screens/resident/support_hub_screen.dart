import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/ticket_model.dart';
import 'package:triangle_home/services/maintenance_service.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportHubScreen extends StatefulWidget {
  const SupportHubScreen({super.key});

  @override
  State<SupportHubScreen> createState() => _SupportHubScreenState();
}

class _SupportHubScreenState extends State<SupportHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MaintenanceService _maintenanceService = MaintenanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('Please login')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Support Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDarkColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.successColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.successColor,
          tabs: const [Tab(text: 'Active Issues'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketList(user.uid, isActive: true),
          _buildTicketList(user.uid, isActive: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketForm(context),
        backgroundColor: AppTheme.successColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Report Issue',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTicketList(String userId, {required bool isActive}) {
    return StreamBuilder<List<TicketModel>>(
      stream: _maintenanceService.getResidentTickets(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTickets = snapshot.data ?? [];
        final tickets =
            allTickets.where((t) {
              if (isActive) {
                return t.status != TicketStatus.resolved &&
                    t.status != TicketStatus.closed;
              } else {
                return t.status == TicketStatus.resolved ||
                    t.status == TicketStatus.closed;
              }
            }).toList();

        if (tickets.isEmpty) {
          return _buildEmptyState(isActive);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: tickets.length,
          itemBuilder: (context, index) => _TicketCard(ticket: tickets[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.assignment_turned_in_outlined
                : Icons.history_rounded,
            size: 64,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          Text(
            isActive ? 'No active issues' : 'No issue history',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewTicketForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NewTicketBottomSheet(),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {}, // Navigate to Detail
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryBadge(),
                _PriorityBadge(priority: ticket.priority),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ticket.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_StatusTag(status: ticket.status), _buildSlaTimer()],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getCategoryIcon(ticket.category), size: 16, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          ticket.category.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSlaTimer() {
    final now = DateTime.now();
    final diff = ticket.slaDueAt.difference(now);
    final bool isBreached = diff.isNegative;

    return Row(
      children: [
        Icon(
          Icons.timer_outlined,
          size: 14,
          color: isBreached ? Colors.red : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          isBreached
              ? 'SLA BREACHED'
              : 'Due in ${diff.inHours}h ${diff.inMinutes % 60}m',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isBreached ? Colors.red : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(TicketCategory cat) {
    switch (ticket.category) {
      case TicketCategory.electrical:
        return Icons.bolt_rounded;
      case TicketCategory.plumbing:
        return Icons.water_drop_rounded;
      case TicketCategory.internet:
        return Icons.wifi_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final TicketPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.blue;
    if (priority == TicketPriority.emergency) color = Colors.red;
    if (priority == TicketPriority.high) color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final TicketStatus status;
  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDarkColor,
        ),
      ),
    );
  }
}

class _NewTicketBottomSheet extends StatefulWidget {
  const _NewTicketBottomSheet();

  @override
  State<_NewTicketBottomSheet> createState() => _NewTicketBottomSheetState();
}

class _NewTicketBottomSheetState extends State<_NewTicketBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _isarService = IsarService();
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadDraft();

    // Auto-save when user types
    _titleController.addListener(_saveDraft);
    _descController.addListener(_saveDraft);
  }

  Future<void> _loadDraft() async {
    if (_uid == null) return;
    final draftStr = await _isarService.getMaintenanceDraft(_uid!);
    if (draftStr != null) {
      try {
        final draft = json.decode(draftStr);
        if (mounted) {
          setState(() {
            _titleController.text = draft['title'] ?? '';
            _descController.text = draft['description'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error loading draft: $e');
      }
    }
  }

  void _saveDraft() {
    if (_uid == null) return;
    final draft = {
      'title': _titleController.text,
      'description': _descController.text,
    };
    _isarService.saveMaintenanceDraft(_uid!, json.encode(draft));
  }

  void _submit() async {
    // TODO: Create ticket via MaintenanceService / SyncService
    // After submission:
    if (_uid != null) {
      await _isarService.clearMaintenanceDraft(_uid!);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_saveDraft);
    _descController.removeListener(_saveDraft);
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Report Issue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Drafts are saved automatically',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Issue Title',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Submit Ticket',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
