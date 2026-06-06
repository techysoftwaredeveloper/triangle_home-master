import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:intl/intl.dart';

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
              _buildCriticalActions(data),
              const SizedBox(height: 40),
              _buildSectionHeader('Platform Overview', trailing: 'This Month'),
              const SizedBox(height: 16),
              _buildPlatformStatsGrid(data),
              const SizedBox(height: 40),

              if (isNarrow) ...[
                _buildSuggestionsPipeline(data),
                const SizedBox(height: 24),
                _buildRecentActivity(data),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildSuggestionsPipeline(data)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildRecentActivity(data)),
                  ],
                ),

              const SizedBox(height: 40),

              if (isNarrow) ...[
                _buildModerationTrust(data),
                const SizedBox(height: 24),
                _buildRevenueOverview(data),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildModerationTrust(data)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildRevenueOverview(data)),
                  ],
                ),

              const SizedBox(height: 40),

              if (isNarrow) ...[
                _buildBookingsOverview(data),
                const SizedBox(height: 24),
                _buildTopCities(data),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildBookingsOverview(data)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildTopCities(data)),
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
            _buildStatusTag(),
            const SizedBox(width: 32),
            _buildMiniMetric(
              Icons.auto_graph_rounded,
              'Uptime',
              '99.98%',
              const Color(0xFF10B981),
            ),
            _buildVerticalDivider(),
            _buildMiniMetric(
              Icons.speed_rounded,
              'Response Time',
              '420ms',
              const Color(0xFF6366F1),
            ),
            _buildVerticalDivider(),
            _buildMiniMetric(
              Icons.people_alt_outlined,
              'Active Now',
              (data?['activeNow'] ?? 32).toString(),
              const Color(0xFF16A34A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'System Status',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'All systems operational',
                style: TextStyle(
                  color: Color(0xFF16A34A),
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

  Widget _buildCriticalActions(Map<String, dynamic>? data) {
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
          ),
          const SizedBox(width: 16),
          _buildActionCard(
            data?['reportedListings']?.toString() ?? '0',
            'Reported Listings',
            const Color(0xFFFFEDD5),
            const Color(0xFFF59E0B),
            Icons.flag_outlined,
            cardWidth,
          ),
          const SizedBox(width: 16),
          _buildActionCard(
            data?['failedPayments']?.toString() ?? '0',
            'Failed Payments',
            const Color(0xFFFEF9C3),
            const Color(0xFFEAB308),
            Icons.money_off_rounded,
            cardWidth,
          ),
          const SizedBox(width: 16),
          _buildActionCard(
            data?['pendingApprovals']?.toString() ?? '0',
            'Verification Requests',
            const Color(0xFFF3E8FF),
            const Color(0xFFA855F7),
            Icons.verified_user_outlined,
            cardWidth,
          ),
          const SizedBox(width: 16),
          _buildActionCard(
            '0',
            'Suspicious Account',
            const Color(0xFFFCE7F3),
            const Color(0xFFEC4899),
            Icons.report_problem_outlined,
            cardWidth,
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
          Text(
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

  Widget _buildPlatformStatsGrid(Map<String, dynamic>? data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isNarrow ? 2 : 5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isNarrow ? 1.1 : 1.0,
      children: [
        _buildStatBox(
          'Students',
          data?['totalStudents']?.toString() ?? '0',
          '0%',
          true,
          const Color(0xFFEFF6FF),
          const Color(0xFF3B82F6),
          Icons.people_outline,
        ),
        _buildStatBox(
          'Hosters',
          data?['totalHosters']?.toString() ?? '0',
          '0%',
          true,
          const Color(0xFFF0FDF4),
          const Color(0xFF10B981),
          Icons.business_center_outlined,
        ),
        _buildStatBox(
          'Active Listings',
          data?['activeProperties']?.toString() ?? '0',
          '0%',
          true,
          const Color(0xFFF5F3FF),
          const Color(0xFF8B5CF6),
          Icons.home_work_outlined,
        ),
        _buildStatBox(
          'Occupancy Rate',
          '${data?['occupancyRate'] ?? '0.0'}%',
          '0%',
          true,
          const Color(0xFFFDF4FF),
          const Color(0xFFD946EF),
          Icons.pie_chart_outline,
        ),
        _buildStatBox(
          'Revenue',
          '₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(data?['totalRevenue'] ?? 0)}',
          '0%',
          true,
          const Color(0xFFFFF7ED),
          const Color(0xFFF59E0B),
          Icons.account_balance_wallet_outlined,
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
              // Subtle sparkline or ghost icon could go here
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
              FittedBox(
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

  Widget _buildSuggestionsPipeline(Map<String, dynamic>? data) {
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
            (data?['newSuggestions'] ?? 18).toString(),
            const Color(0xFF3B82F6),
            Icons.rocket_launch_outlined,
          ),
          _buildPipelineItem(
            'Under Review',
            (data?['reviewSuggestions'] ?? 12).toString(),
            const Color(0xFFF59E0B),
            Icons.timer_outlined,
          ),
          _buildPipelineItem(
            'Contacted',
            (data?['contactedSuggestions'] ?? 7).toString(),
            const Color(0xFF8B5CF6),
            Icons.phone_in_talk_outlined,
          ),
          _buildPipelineItem(
            'Approved',
            (data?['approvedSuggestions'] ?? 6).toString(),
            const Color(0xFF10B981),
            Icons.check_circle_outline,
          ),
          _buildPipelineItem(
            'Rejected',
            (data?['rejectedSuggestions'] ?? 3).toString(),
            const Color(0xFFEF4444),
            Icons.cancel_outlined,
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
          Text(
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

  Widget _buildRecentActivity(Map<String, dynamic>? data) {
    final activities = (data?['recentActivities'] as List?) ?? [];
    final displayActivities = activities;

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
          if (displayActivities.isEmpty)
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
            ...displayActivities.map(
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

  Widget _buildModerationTrust(Map<String, dynamic>? data) {
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
            (data?['reportedListings'] ?? 2).toString(),
            const Color(0xFFEF4444),
            Icons.outlined_flag,
          ),
          _buildModerationItem(
            'Reported Users',
            (data?['reportedUsers'] ?? 1).toString(),
            const Color(0xFFF59E0B),
            Icons.person_off_outlined,
          ),
          _buildModerationItem(
            'Blocked Accounts',
            (data?['blockedUsers'] ?? 3).toString(),
            const Color(0xFF8B5CF6),
            Icons.block_flipped,
          ),
          _buildModerationItem(
            'Verification Queue',
            (data?['pendingApprovals'] ?? 4).toString(),
            const Color(0xFF3B82F6),
            Icons.verified_user_outlined,
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
          Text(
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

  Widget _buildRevenueOverview(Map<String, dynamic>? data) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
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
          Text(
            format.format(data?['totalRevenue'] ?? 485250),
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
          // Mock Area Chart
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(painter: _AreaChartPainter()),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildBreakdownItem(
                'Paid',
                format.format(data?['paidRevenue'] ?? 375000),
                const Color(0xFF10B981),
              ),
              _buildBreakdownItem(
                'Pending',
                format.format(data?['pendingRevenue'] ?? 75250),
                const Color(0xFFF59E0B),
              ),
              _buildBreakdownItem(
                'Refunded',
                format.format(data?['refundedRevenue'] ?? 35000),
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

  Widget _buildBookingsOverview(Map<String, dynamic>? data) {
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
          Text(
            (data?['totalBookings'] ?? 452).toString(),
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
          // Bar Chart
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (index) {
                double h = 40 + (index % 7) * 20 + (index % 4) * 10;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                );
              }),
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

  Widget _buildTopCities(Map<String, dynamic>? data) {
    final topCities = (data?['topCities'] as List?) ?? [];
    final displayCities = topCities;

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
          if (displayCities.isEmpty)
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
            ...displayCities.map((c) {
              final count = c['count'] as int;
              final max = (displayCities.first['count'] as int);
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
}

class _AreaChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.8,
      size.width * 0.4,
      size.height * 0.9,
    );
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height,
      size.width * 0.8,
      size.height * 0.6,
    );
    path.lineTo(size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final linePaint =
        Paint()
          ..color = const Color(0xFF10B981)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final linePath = Path();
    linePath.moveTo(0, size.height);
    linePath.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.8,
      size.width * 0.4,
      size.height * 0.9,
    );
    linePath.quadraticBezierTo(
      size.width * 0.6,
      size.height,
      size.width * 0.8,
      size.height * 0.6,
    );
    linePath.lineTo(size.width, size.height * 0.7);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
