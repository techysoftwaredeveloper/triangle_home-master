import 'package:flutter/material.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/ticket_model.dart';
import 'package:triangle_home/services/maintenance_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MaintenanceCenterScreen extends StatefulWidget {
  final String propertyId;

  const MaintenanceCenterScreen({super.key, required this.propertyId});

  @override
  State<MaintenanceCenterScreen> createState() =>
      _MaintenanceCenterScreenState();
}

class _MaintenanceCenterScreenState extends State<MaintenanceCenterScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Maintenance Ops',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDarkColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: _maintenanceService.getPropertyTickets(widget.propertyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTickets = snapshot.data ?? [];
          final metrics = _calculateMetrics(allTickets);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildMetricGrid(metrics)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ticket Queue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      _buildSortChip(),
                    ],
                  ),
                ),
              ),
              if (allTickets.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No tickets reported')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _HosterTicketCard(
                        ticket: _sortTickets(allTickets)[index],
                        onTap:
                            () => _openDetail(
                              context,
                              _sortTickets(allTickets)[index],
                            ),
                      ),
                      childCount: allTickets.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricGrid(Map<String, int> m) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [
          _kpiCard('OPEN', m['open'] ?? 0, Colors.blue),
          _kpiCard('EMERGENCY', m['emergency'] ?? 0, Colors.red),
          _kpiCard('SLA BREACH', m['breached'] ?? 0, Colors.orange),
          _kpiCard('RESOLVED TODAY', m['resolvedToday'] ?? 0, Colors.green),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.sort_rounded, size: 14, color: AppTheme.textMutedColor),
          SizedBox(width: 6),
          Text(
            'Smart Priority',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateMetrics(List<TicketModel> tickets) {
    final now = DateTime.now();
    return {
      'open':
          tickets
              .where(
                (t) =>
                    t.status != TicketStatus.resolved &&
                    t.status != TicketStatus.closed,
              )
              .length,
      'emergency':
          tickets
              .where(
                (t) =>
                    t.priority == TicketPriority.emergency &&
                    t.status != TicketStatus.closed,
              )
              .length,
      'breached':
          tickets
              .where(
                (t) =>
                    t.slaDueAt.isBefore(now) &&
                    t.status != TicketStatus.resolved &&
                    t.status != TicketStatus.closed,
              )
              .length,
      'resolvedToday':
          tickets
              .where(
                (t) =>
                    t.resolvedAt != null &&
                    DateFormat('yMd').format(t.resolvedAt!) ==
                        DateFormat('yMd').format(now),
              )
              .length,
    };
  }

  List<TicketModel> _sortTickets(List<TicketModel> tickets) {
    final list = List<TicketModel>.from(tickets);
    list.sort((a, b) {
      // 1. Emergency + Breached first
      bool aCrit =
          a.priority == TicketPriority.emergency ||
          a.slaDueAt.isBefore(DateTime.now());
      bool bCrit =
          b.priority == TicketPriority.emergency ||
          b.slaDueAt.isBefore(DateTime.now());
      if (aCrit && !bCrit) return -1;
      if (!aCrit && bCrit) return 1;

      // 2. Nearest SLA first
      return a.slaDueAt.compareTo(b.slaDueAt);
    });
    return list;
  }

  void _openDetail(BuildContext context, TicketModel ticket) {
    // Navigate to enhanced detail
  }
}

class _HosterTicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;

  const _HosterTicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isBreached = ticket.slaDueAt.isBefore(DateTime.now());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isBreached
                    ? Colors.red.withValues(alpha: 0.2)
                    : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSlaTimer(isBreached),
                _PriorityBadge(priority: ticket.priority),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ticket.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.meeting_room_rounded,
                  size: 14,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  'Room ${ticket.roomId} • Bed ${ticket.bedId}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'By ${ticket.residentId.substring(0, 5)}...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                _StatusTag(status: ticket.status),
                const Spacer(),
                const Text(
                  'Details',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.successColor,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlaTimer(bool isBreached) {
    final diff = ticket.slaDueAt.difference(DateTime.now());
    return Row(
      children: [
        Icon(
          Icons.timer_outlined,
          size: 14,
          color: isBreached ? Colors.red : Colors.blue,
        ),
        const SizedBox(width: 6),
        Text(
          isBreached
              ? 'BREACHED'
              : '${diff.inHours}h ${diff.inMinutes % 60}m left',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isBreached ? Colors.red : Colors.blue,
          ),
        ),
      ],
    );
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
