import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/resident_stay.dart';
import 'package:triangle_home/models/lifecycle_models.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';

class StayHubScreen extends StatefulWidget {
  const StayHubScreen({super.key});

  @override
  State<StayHubScreen> createState() => _StayHubScreenState();
}

class _StayHubScreenState extends State<StayHubScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('resident_stays')
              .where('residentId', isEqualTo: user.uid)
              .where('status', isNotEqualTo: StayStatus.completed.name)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoActiveStayState();
        }

        final stay = ResidentStayModel.fromFirestore(snapshot.data!.docs.first);
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(stay),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildRentLedger(stay),
                      const SizedBox(height: 24),
                      _buildNoticeCenter(stay),
                      const SizedBox(height: 24),
                      _buildSupportShortcut(stay),
                      const SizedBox(height: 24),
                      _buildTimeline(stay.id),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(ResidentStayModel stay) {
    final daysStayed = DateTime.now().difference(stay.checkInDate).inDays;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, Color(0xFF1E40AF)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ROOM & BED',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Room ${stay.roomId} • Bed ${stay.bedId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _StatusBadge(status: stay.status),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _metaItem(
                    'Check-In',
                    DateFormat('dd MMM yy').format(stay.checkInDate),
                  ),
                  const SizedBox(width: 32),
                  _metaItem('Days Stayed', '$daysStayed Days'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRentLedger(ResidentStayModel stay) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rent Ledger',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection('rent_cycles')
                    .where('stayId', isEqualTo: stay.id)
                    .orderBy('dueDate', descending: true)
                    .limit(3)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final cycles =
                  snapshot.data!.docs
                      .map((d) => RentCycle.fromFirestore(d))
                      .toList();

              if (cycles.isEmpty) {
                return const Text(
                  'No rent cycles generated yet',
                  style: TextStyle(color: Colors.grey),
                );
              }

              return Column(
                children: cycles.map((c) => _RentItem(cycle: c)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCenter(ResidentStayModel stay) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Move-Out Notice',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (stay.status == StayStatus.active) ...[
            const Text(
              'Planning to move? Please provide a 30-day notice period.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showNoticeForm(stay),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                ),
                child: const Text(
                  'Submit Move-Out Notice',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            _buildCheckoutProgress(stay),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckoutProgress(ResidentStayModel stay) {
    // A simplified visual step tracker
    return Column(
      children: [
        _stepItem('Notice Submitted', true),
        _stepItem('Inspection Scheduled', false),
        _stepItem('Deposit Settlement', false),
        _stepItem('Check-Out Finalized', false),
      ],
    );
  }

  Widget _stepItem(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isDone ? Colors.green : Colors.grey[300],
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDone ? AppTheme.textDarkColor : Colors.grey,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportShortcut(ResidentStayModel stay) {
    return InkWell(
      onTap: () {}, // Navigate to support hub
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Need Help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Raise a maintenance ticket',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white60),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(String stayId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stay Timeline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance
                  .collection('stay_events')
                  .where('stayId', isEqualTo: stayId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final events = snapshot.data!.docs;
            return Column(
              children:
                  events.map((e) => _TimelineItem(data: e.data())).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoActiveStayState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stay'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_outlined, size: 80, color: Colors.grey[200]),
            const SizedBox(height: 24),
            const Text(
              'No Active Stay',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Once you check-in, your stay details will appear here.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoticeForm(ResidentStayModel stay) {
    // Bottom sheet or dialog for notice submission
  }
}

class _RentItem extends StatelessWidget {
  final RentCycle cycle;
  const _RentItem({required this.cycle});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.orange;
    if (cycle.status == RentStatus.paid) statusColor = Colors.green;
    if (cycle.status == RentStatus.overdue) statusColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycle.month,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Due ${DateFormat('dd MMM').format(cycle.dueDate)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${cycle.rentAmount.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                cycle.status.name.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final StayStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.green;
    if (status == StayStatus.noticeSubmitted) color = Colors.orange;
    if (status == StayStatus.checkoutPending) color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TimelineItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['event']?.toString().replaceAll('_', ' ') ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat(
                    'hh:mm a, dd MMM',
                  ).format((data['timestamp'] as Timestamp).toDate()),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
