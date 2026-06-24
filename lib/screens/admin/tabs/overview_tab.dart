import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class OverviewTab extends StatelessWidget {
  final AdminService adminService;
  final bool isNarrow;

  const OverviewTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: adminService.getStatsStream(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSystemStatusRow(data),
              const SizedBox(height: 40),
              _buildSectionHeader(
                'Critical Actions Required',
                trailing: 'View All',
              ),
              const SizedBox(height: 16),
              _buildCriticalActions(data, isLoading),
              const SizedBox(height: 40),
              _buildSectionHeader('Platform Overview', trailing: 'This Month'),
              const SizedBox(height: 16),
              _buildPlatformStatsGrid(data, isLoading),
              const SizedBox(height: 40),

              if (isNarrow) ...[
                _buildSuggestionsPipeline(data, isLoading),
                const SizedBox(height: 24),
                _buildRecentActivity(data, isLoading),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildSuggestionsPipeline(data, isLoading)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildRecentActivity(data, isLoading)),
                  ],
                ),

              const SizedBox(height: 40),

              if (isNarrow) ...[
                _buildModerationTrust(data, isLoading),
                const SizedBox(height: 24),
                _buildRevenueOverview(data, isLoading),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildModerationTrust(data, isLoading)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildRevenueOverview(data, isLoading)),
                  ],
                ),

              const SizedBox(height: 40),

              if (isNarrow) ...[
                _buildBookingsOverview(data, isLoading),
                const SizedBox(height: 24),
                _buildTopCities(data, isLoading),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildBookingsOverview(data, isLoading)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildTopCities(data, isLoading)),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNarrow
                    ? 'Good morning, Admin 👋'
                    : 'Good morning, Super Admin 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's happening with your platform today.",
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
        if (!isNarrow) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSystemStatusRow(Map<String, dynamic>? data) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: adminService.getSystemHealthStream(),
      builder: (context, healthSnap) {
        final health = healthSnap.data ?? {};
        final status = health['status'] ?? 'operational';
        final uptime = health['uptime'] ?? '99.98%';
        final latency = health['latency'] ?? '420ms';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatusTag(status),
                const SizedBox(width: 32),
                _buildMiniMetric(
                  Icons.auto_graph_rounded,
                  'Uptime',
                  uptime,
                  const Color(0xFF10B981),
                ),
                _buildVerticalDivider(),
                _buildMiniMetric(
                  Icons.speed_rounded,
                  'Response Time',
                  latency,
                  const Color(0xFF6366F1),
                ),
                _buildVerticalDivider(),
                _buildMiniMetric(
                  Icons.people_alt_outlined,
                  'Active Now',
                  (data?['activeNow'] ?? 0).toString(),
                  const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatusTag(String status) {
    final bool isOperational = status == 'operational';
    final color = isOperational ? const Color(0xFF16A34A) : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOperational ? Icons.check_circle : Icons.warning_rounded, 
            color: color, 
            size: 20
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'System Status',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                isOperational ? 'All systems operational' : 'System Degraded',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildSectionHeader(String title, {required String trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontFamily: 'Outfit',
          ),
        ),
        InkWell(
          onTap: () {},
          child: Row(
            children: [
              Text(
                trailing,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing.toLowerCase().contains('month')) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalActions(Map<String, dynamic>? data, bool isLoading) {
    final double cardWidth = isNarrow ? 170 : 210;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildActionCard(
            data?['pendingHosters']?.toString() ?? '0',
            'Pending Host Approvals',
            const Color(0xFFFEE2E2),
            const Color(0xFFEF4444),
            Icons.assignment_ind_outlined,
            cardWidth,
            isLoading,
          ),
          const SizedBox(width: 16),
          _buildActionCard(
            data?['reportedListings']?.toString() ?? '0',
            'Reported Listings',
            const Color(0xFFFFEDD5),
            const Color(0xFFF59E0B),
            Icons.flag_outlined,
            cardWidth,
            isLoading,
          ),
          const SizedBox(width: 16),
          _buildActionCard(
            data?['failedPayments']?.toString() ?? '0',
            'Failed Payments',
            const Color(0xFFFEF9C3),
            const Color(0xFFEAB308),
            Icons.money_off_rounded,
            cardWidth,
            isLoading,
          ),
          const SizedBox(width: 16),
          _buildActionCard(
            data?['pendingApprovals']?.toString() ?? '0',
            'Verification Requests',
            const Color(0xFFF3E8FF),
            const Color(0xFFA855F7),
            Icons.verified_user_outlined,
            cardWidth,
            isLoading,
          ),
          const SizedBox(width: 16),
          _buildActionCard(
            '0',
            'Suspicious Account',
            const Color(0xFFFCE7F3),
            const Color(0xFFEC4899),
            Icons.report_problem_outlined,
            cardWidth,
            isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String count,
    String label,
    Color bg,
    Color color,
    IconData icon,
    double width,
    bool isLoading,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          isLoading 
            ? _buildSkeletonText(32, 60)
            : Text(
                count,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            child: Text(
              'Review Now',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStatsGrid(Map<String, dynamic>? data, bool isLoading) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isNarrow ? 2 : 6,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isNarrow ? 1.1 : 0.85,
      children: [
        _buildStatBox(
          'Students',
          data?['totalStudents']?.toString() ?? '0',
          '0%',
          true,
          const Color(0xFFEFF6FF),
          const Color(0xFF3B82F6),
          Icons.people_outline,
          isLoading,
        ),
        _buildStatBox(
          'Professionals',
          data?['totalProfessionals']?.toString() ?? '0',
          '0%',
          true,
          const Color(0xFFF5F3FF),
          const Color(0xFF8B5CF6),
          Icons.business_center_outlined,
          isLoading,
        ),
        _buildStatBox(
          'Hosters',
          data?['totalHosters']?.toString() ?? '0',
          '0%',
          true,
          const Color(0xFFF0FDF4),
          const Color(0xFF10B981),
          Icons.person_pin_outlined,
          isLoading,
        ),
        _buildStatBox(
          'Active Listings',
          data?['activeProperties']?.toString() ?? '0',
          '0%',
          true,
          const Color(0xFFF5F3FF),
          const Color(0xFF6366F1),
          Icons.home_work_outlined,
          isLoading,
        ),
        _buildStatBox(
          'Occupancy Rate',
          '${data?['occupancyRate'] ?? '0.0'}%',
          '0%',
          true,
          const Color(0xFFFDF4FF),
          const Color(0xFFD946EF),
          Icons.pie_chart_outline,
          isLoading,
        ),
        _buildStatBox(
          'Revenue',
          '₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(data?['totalRevenue'] ?? 0)}',
          '0%',
          true,
          const Color(0xFFFFF7ED),
          const Color(0xFFF59E0B),
          Icons.account_balance_wallet_outlined,
          isLoading,
        ),
      ],
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    String change,
    bool isUp,
    Color bg,
    Color color,
    IconData icon,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              isLoading 
                ? _buildSkeletonText(28, 80)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                  ),
            ],
          ),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_upward : Icons.arrow_downward,
                color: const Color(0xFF10B981),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'vs last month',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsPipeline(Map<String, dynamic>? data, bool isLoading) {
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
          _buildSectionHeader('Suggestions Pipeline', trailing: 'View All'),
          const SizedBox(height: 24),
          _buildPipelineItem(
            'New Suggestions',
            (data?['newSuggestions'] ?? 0).toString(),
            const Color(0xFF3B82F6),
            Icons.rocket_launch_outlined,
            isLoading,
          ),
          _buildPipelineItem(
            'Under Review',
            (data?['reviewSuggestions'] ?? 0).toString(),
            const Color(0xFFF59E0B),
            Icons.timer_outlined,
            isLoading,
          ),
          _buildPipelineItem(
            'Contacted',
            (data?['contactedSuggestions'] ?? 0).toString(),
            const Color(0xFF8B5CF6),
            Icons.phone_in_talk_outlined,
            isLoading,
          ),
          _buildPipelineItem(
            'Approved',
            (data?['approvedSuggestions'] ?? 0).toString(),
            const Color(0xFF10B981),
            Icons.check_circle_outline,
            isLoading,
          ),
          _buildPipelineItem(
            'Rejected',
            (data?['rejectedSuggestions'] ?? 0).toString(),
            const Color(0xFFEF4444),
            Icons.cancel_outlined,
            isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineItem(
    String label,
    String count,
    Color color,
    IconData icon,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          isLoading
            ? _buildSkeletonText(16, 30)
            : Text(
                count,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic>? data, bool isLoading) {
    final activities = (data?['recentActivities'] as List?) ?? [];

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
          _buildSectionHeader('Recent Activity', trailing: 'View All'),
          const SizedBox(height: 24),
          if (isLoading)
            ...List.generate(4, (index) => _buildSkeletonActivityItem())
          else if (activities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Text(
                  'No recent activity logs',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            )
          else
            ...activities.map(
              (a) => _buildActivityItem(
                a['title'] ?? '',
                a['subtitle'] ?? '',
                a['time'] ?? '',
                _getActivityIcon(a['title'] ?? ''),
                _getActivityColor(a['title'] ?? ''),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String title) {
    title = title.toLowerCase();
    if (title.contains('approved')) return Icons.home_work_outlined;
    if (title.contains('registration') || title.contains('user')) {
      return Icons.person_outline;
    }
    if (title.contains('suggestion')) return Icons.lightbulb_outline;
    if (title.contains('payment') || title.contains('received')) {
      return Icons.payments_outlined;
    }
    if (title.contains('report') || title.contains('listing')) {
      return Icons.flag_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _getActivityColor(String title) {
    title = title.toLowerCase();
    if (title.contains('approved')) return const Color(0xFF10B981);
    if (title.contains('registration')) return const Color(0xFF3B82F6);
    if (title.contains('suggestion')) return const Color(0xFF8B5CF6);
    if (title.contains('payment') || title.contains('received')) {
      return const Color(0xFFF59E0B);
    }
    if (title.contains('report') || title.contains('listing')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF64748B);
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationTrust(Map<String, dynamic>? data, bool isLoading) {
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
          _buildSectionHeader('Moderation & Trust', trailing: 'View All'),
          const SizedBox(height: 24),
          _buildModerationItem(
            'Flagged Listings',
            (data?['reportedListings'] ?? 0).toString(),
            const Color(0xFFEF4444),
            Icons.outlined_flag,
            isLoading,
          ),
          _buildModerationItem(
            'Reported Users',
            (data?['reportedUsers'] ?? 0).toString(),
            const Color(0xFFF59E0B),
            Icons.person_off_outlined,
            isLoading,
          ),
          _buildModerationItem(
            'Blocked Accounts',
            (data?['blockedUsers'] ?? 0).toString(),
            const Color(0xFF8B5CF6),
            Icons.block_flipped,
            isLoading,
          ),
          _buildModerationItem(
            'Verification Queue',
            (data?['pendingApprovals'] ?? 0).toString(),
            const Color(0xFF3B82F6),
            Icons.verified_user_outlined,
            isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildModerationItem(
    String label,
    String count,
    Color color,
    IconData icon,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          isLoading
            ? _buildSkeletonText(16, 30)
            : Text(
                count,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview(Map<String, dynamic>? data, bool isLoading) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final revenueHistory = (data?['revenueHistory'] as List?) ?? [];

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
          _buildSectionHeader('Revenue Overview', trailing: 'This Month'),
          const SizedBox(height: 24),
          isLoading 
            ? _buildSkeletonText(32, 120)
            : Text(
                format.format(data?['totalRevenue'] ?? 0),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.arrow_upward, color: Color(0xFF10B981), size: 16),
              SizedBox(width: 4),
              Text(
                '18.7%',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                ' vs last month',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            height: 140,
            width: double.infinity,
            child: isLoading 
              ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade300))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: revenueHistory.isEmpty 
                          ? [const FlSpot(0, 1), const FlSpot(1, 3), const FlSpot(2, 2), const FlSpot(3, 5)]
                          : revenueHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble())).toList(),
                        isCurved: true,
                        color: const Color(0xFF10B981),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildBreakdownItem(
                'Paid',
                format.format(data?['paidRevenue'] ?? 0),
                const Color(0xFF10B981),
              ),
              _buildBreakdownItem(
                'Pending',
                format.format(data?['pendingRevenue'] ?? 0),
                const Color(0xFFF59E0B),
              ),
              _buildBreakdownItem(
                'Refunded',
                format.format(data?['refundedRevenue'] ?? 0),
                const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsOverview(Map<String, dynamic>? data, bool isLoading) {
    final bookingHistory = (data?['bookingHistory'] as List?) ?? [];

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
          _buildSectionHeader('Bookings Overview', trailing: 'This Month'),
          const SizedBox(height: 24),
          isLoading
            ? _buildSkeletonText(32, 80)
            : Text(
                (data?['totalBookings'] ?? 0).toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.arrow_upward, color: Color(0xFF10B981), size: 16),
              SizedBox(width: 4),
              Text(
                '14.6%',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                ' vs last month',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            height: 180,
            width: double.infinity,
            child: isLoading
              ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade300))
              : BarChart(
                  BarChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: bookingHistory.isEmpty
                      ? List.generate(7, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (i + 2) * 5, color: const Color(0xFF3B82F6), width: 12, borderRadius: BorderRadius.circular(4))]))
                      : bookingHistory.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: (e.value['value'] as num).toDouble(), color: const Color(0xFF3B82F6), width: 12, borderRadius: BorderRadius.circular(4))])).toList(),
                  ),
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '1 May',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              Text(
                '11 May',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              Text(
                '19 May',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCities(Map<String, dynamic>? data, bool isLoading) {
    final topCities = (data?['topCities'] as List?) ?? [];

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
          _buildSectionHeader('Top Cities by Listings', trailing: 'This Month'),
          const SizedBox(height: 32),
          if (isLoading)
            ...List.generate(3, (index) => _buildSkeletonCityItem())
          else if (topCities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Text(
                  'No listings data available',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            )
          else
            ...topCities.map((c) {
              final count = c['count'] as int;
              final max = (topCities.first['count'] as int);
              return _buildCityProgress(
                c['name'],
                count,
                count / (max > 0 ? max : 1),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCityProgress(String city, int count, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                city,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enterprise Skeleton Loaders
  Widget _buildSkeletonText(double height, double width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  Widget _buildSkeletonActivityItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: Colors.grey.shade50),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonText(14, 120),
                const SizedBox(height: 6),
                _buildSkeletonText(12, 180),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCityItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildSkeletonText(14, 80), _buildSkeletonText(14, 30)],
          ),
          const SizedBox(height: 10),
          _buildSkeletonText(8, double.infinity),
        ],
      ),
    );
  }
}
