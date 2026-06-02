import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OpsDashboardTab extends StatelessWidget {
  final AdminService adminService;
  final bool isNarrow;

  const OpsDashboardTab({super.key, required this.adminService, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: adminService.getStatsStream(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildMetricGrid(data),
              const SizedBox(height: 48),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildAdminActivityList()),
                  if (!isNarrow) const SizedBox(width: 32),
                  if (!isNarrow) Expanded(flex: 2, child: _buildAlertSummary(data)),
                ],
              ),
              if (isNarrow) ...[
                const SizedBox(height: 32),
                _buildAlertSummary(data),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Operations Center',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Outfit'),
        ),
        SizedBox(height: 4),
        Text(
          'Marketplace health and staff accountability',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontFamily: 'Outfit'),
        ),
      ],
    );
  }

  Widget _buildMetricGrid(Map data) {
    return GridView.count(
      crossAxisCount: isNarrow ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _MetricCard(
          label: 'Open Disputes',
          count: data['openDisputes']?.toString() ?? '0',
          icon: Icons.report_problem_rounded,
          color: Colors.orange,
        ),
        _MetricCard(
          label: 'Pending Payouts',
          count: data['readyPayouts']?.toString() ?? '0',
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.blue,
        ),
        _MetricCard(
          label: 'Expiring Locks',
          count: data['expiringReservations']?.toString() ?? '0',
          icon: Icons.timer_rounded,
          color: Colors.red,
        ),
        _MetricCard(
          label: 'Active Agents',
          count: '12', // Mocked
          icon: Icons.support_agent_rounded,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAdminActivityList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Admin Activity Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('admin_actions').orderBy('timestamp', descending: true).limit(10).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No recent actions recorded', style: TextStyle(color: Colors.grey))));
              
              return Column(
                children: docs.map((doc) {
                  final d = doc.data();
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: Color(0xFF0F172A)),
                    ),
                    title: Text(d['actionType'] ?? 'Action', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('Booking: ${d['bookingId']} • ${d['adminId']}', style: const TextStyle(fontSize: 11)),
                    trailing: Text(
                      d['timestamp'] != null ? DateFormat('hh:mm a').format((d['timestamp'] as Timestamp).toDate()) : '',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSummary(Map data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Action Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit')),
          const SizedBox(height: 24),
          _AlertItem(label: 'Pending Approvals', count: data['pendingApprovals']?.toString() ?? '0', color: Colors.blueAccent),
          _AlertItem(label: 'Reported Listings', count: data['reportedListings']?.toString() ?? '0', color: Colors.redAccent),
          _AlertItem(label: 'Critical Disputes', count: data['openDisputes']?.toString() ?? '0', color: Colors.orangeAccent),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('View All Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.label, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _AlertItem({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(10)),
            child: Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
