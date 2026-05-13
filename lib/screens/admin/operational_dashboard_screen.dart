import 'package:flutter/material.dart';
import 'package:triangle_home/services/audit_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OperationalDashboardScreen extends StatelessWidget {
  const OperationalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auditService = AuditService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Operational Health', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('System Health Overview'),
            const SizedBox(height: 16),
            _buildHealthCards(),
            const SizedBox(height: 32),
            _buildSectionHeader('Recent Audit Logs'),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: auditService.getLogs(limit: 10),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final logs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data();
                    final timestamp = log['timestamp'] as Timestamp?;
                    return Card(
                      child: ListTile(
                        title: Text(log['action']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'ACTION'),
                        subtitle: Text('${log['targetType']} ID: ${log['targetId']}\n${log['reason'] ?? ""}'),
                        trailing: Text(
                          timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '--:--',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: AppTheme.fontFamily),
    );
  }

  Widget _buildHealthCards() {
    return const Row(
      children: [
        Expanded(child: _HealthCard(title: 'Stuck Bookings', value: '0', color: Colors.orange)),
        SizedBox(width: 16),
        Expanded(child: _HealthCard(title: 'Failed Payments', value: '0', color: Colors.red)),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _HealthCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
