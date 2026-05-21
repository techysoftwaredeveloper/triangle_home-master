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
              const SizedBox(height: 32),
              _buildSectionHeader('Critical Actions Required', trailing: 'View All'),
              const SizedBox(height: 16),
              _buildCriticalActions(data),
              const SizedBox(height: 32),
              _buildSectionHeader('Platform Overview', trailing: 'This Month'),
              const SizedBox(height: 16),
              _buildPlatformStatsGrid(data),
              const SizedBox(height: 32),
              // ... rest of build remains the same
              if (isNarrow) ...[
                _buildSuggestionsPipeline(data),
                const SizedBox(height: 24),
                _buildRecentActivity(data),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildSuggestionsPipeline(data)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildRecentActivity(data)),
                  ],
                ),

              const SizedBox(height: 32),

              if (isNarrow) ...[
                _buildModerationTrust(data),
                const SizedBox(height: 24),
                _buildRevenueOverview(data),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildModerationTrust(data)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildRevenueOverview(data)),
                  ],
                ),

              const SizedBox(height: 32),

              if (isNarrow) ...[
                _buildBookingsOverview(data),
                const SizedBox(height: 24),
                _buildTopCities(data),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildBookingsOverview(data)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildTopCities(data)),
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
                isNarrow ? 'Good morning 👋' : 'Good morning, Super Admin 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isNarrow ? "Platform activity today." : "Here's what's happening with your platform today.",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontFamily: 'Outfit'),
              ),
            ],
          ),
        ),
        if (!isNarrow) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.now()),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildStatusTag(),
            const SizedBox(width: 24),
            _buildMiniMetric(Icons.auto_graph_rounded, 'Uptime', '99.98%', Colors.green),
            _buildVerticalDivider(),
            _buildMiniMetric(Icons.speed_rounded, 'Response', '420ms', Colors.blue),
            _buildVerticalDivider(),
            _buildMiniMetric(Icons.people_alt_outlined, 'Logged In', (data?['activeNow'] ?? 2).toString(), Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
          SizedBox(width: 8),
          Text(
            'All systems operational',
            style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSectionHeader(String title, {required String trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          trailing,
          style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCriticalActions(Map<String, dynamic>? data) {
    final double cardWidth = isNarrow ? 160 : 220;
    final double cardHeight = isNarrow ? 140 : 180;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _wrapInSizedBox(cardWidth, cardHeight, _buildActionCard(data?['pendingHosters']?.toString() ?? '0', 'Pending Host\nApprovals', const Color(0xFFFEE2E2), const Color(0xFFDC2626), Icons.assignment_ind_outlined)),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, _buildActionCard(data?['pendingProperties']?.toString() ?? '0', 'Pending Listing\nApprovals', const Color(0xFFFFEDD5), const Color(0xFFD97706), Icons.home_work_outlined)),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, _buildActionCard(data?['pendingReports']?.toString() ?? '0', 'Open Incident\nReports', const Color(0xFFFFF1F2), const Color(0xFFE11D48), Icons.flag_outlined)),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, _buildActionCard(data?['pendingBookings']?.toString() ?? '0', 'Pending\nBookings', const Color(0xFFF5F3FF), const Color(0xFF7C3AED), Icons.calendar_month_outlined)),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, _buildActionCard('0', 'Failed\nPayments', const Color(0xFFF1F5F9), const Color(0xFF475569), Icons.money_off_rounded)),
        ],
      ),
    );
  }

  Widget _wrapInSizedBox(double w, double h, Widget child) => SizedBox(width: w, height: h, child: child);

  Widget _buildActionCard(String count, String label, Color bg, Color text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: text, size: 22),
            ),
            const SizedBox(height: 16),
            Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.3)),
            const SizedBox(height: 20),
            Text(
              'Review Now',
              style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
            ),
          ],
        ),
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
      childAspectRatio: isNarrow ? 0.85 : 1.05,
      children: [
        _buildStatBox('Students', data?['totalStudents']?.toString() ?? '0', '12.5%', true, const Color(0xFFEFF6FF), Colors.blue),
        _buildStatBox('Hosters', data?['totalHosters']?.toString() ?? '0', '8.3%', true, const Color(0xFFF0FDF4), Colors.green),
        _buildStatBox('Active Listings', data?['totalProperties']?.toString() ?? '0', '15.2%', true, const Color(0xFFEFF6FF), Colors.blue),
        _buildStatBox('Occupancy Rate', '${data?['occupancyRate'] ?? 78.6}%', '6.1%', true, const Color(0xFFF5F3FF), Colors.purple),
        _buildStatBox('Revenue', '₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(data?['totalRevenue'] ?? 0)}', '18.7%', true, const Color(0xFFFFF7ED), Colors.orange),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, String change, bool isUp, Color bg, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(label.contains('Revenue') ? Icons.payments_outlined : Icons.people_outline, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: isNarrow ? 11 : 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: isNarrow ? 22 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.green, size: 12),
                const SizedBox(width: 2),
                Text(change, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsPipeline(Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Suggestions Pipeline', trailing: 'View All'),
          const SizedBox(height: 24),
          _buildPipelineItem('New Suggestions', (data?['newSuggestions'] ?? 18).toString(), Colors.blue, Icons.rocket_launch_outlined),
          _buildPipelineItem('Under Review', (data?['reviewSuggestions'] ?? 12).toString(), Colors.orange, Icons.timer_outlined),
          _buildPipelineItem('Contacted', (data?['contactedSuggestions'] ?? 7).toString(), Colors.purple, Icons.phone_in_talk_outlined),
          _buildPipelineItem('Approved', (data?['approvedSuggestions'] ?? 6).toString(), Colors.green, Icons.check_circle_outline),
          _buildPipelineItem('Rejected', (data?['rejectedSuggestions'] ?? 3).toString(), Colors.red, Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _buildPipelineItem(String label, String count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF475569))
            ),
          ),
          const SizedBox(width: 12),
          Text(count, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recent Activity', trailing: 'View All'),
          const SizedBox(height: 24),
          _buildActivityItem('Sunrise Hostels approved by Admin', 'Kozhikode, Kerala', '10:30 AM', Icons.home_work_outlined, Colors.green),
          _buildActivityItem('New hoster registration', 'John Doe', '09:45 AM', Icons.person_outline, Colors.blue),
          _buildActivityItem('New property suggestion submitted', 'Green Valley PG, Calicut', '09:20 AM', Icons.lightbulb_outline, Colors.purple),
          _buildActivityItem('Payment received', 'Room A-203, Sunrise Hostels', '08:50 AM', Icons.payments_outlined, Colors.orange),
          _buildActivityItem('Listing reported', 'Comfort Living PG', '08:15 AM', Icons.flag_outlined, Colors.red),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Moderation & Trust', trailing: 'View All'),
          const SizedBox(height: 24),
          _buildModerationItem('Flagged Listings', (data?['pendingProperties'] ?? 0).toString(), Colors.red, Icons.outlined_flag),
          _buildModerationItem('Reported Users', (data?['pendingReports'] ?? 0).toString(), Colors.orange, Icons.person_off_outlined),
          _buildModerationItem('Blocked Accounts', (data?['blockedUsers'] ?? 3).toString(), Colors.purple, Icons.block_flipped),
          _buildModerationItem('Verification Queue', (data?['pendingHosters'] ?? 0).toString(), Colors.blue, Icons.verified_user_outlined),
        ],
      ),
    );
  }

  Widget _buildModerationItem(String label, String count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF475569))
            ),
          ),
          const SizedBox(width: 12),
          Text(count, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview(Map<String, dynamic>? data) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Revenue Overview', trailing: 'This Month'),
          const SizedBox(height: 24),
          Text(format.format(data?['totalRevenue'] ?? 0), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.arrow_upward, color: Colors.green, size: 14),
              Text('18.7%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(' vs last month', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          // Mock chart area
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(20, (index) {
                double height = 20 + (index % 5) * 15 + (index % 3) * 10;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: height,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildBreakdownItem('Paid', format.format(data?['totalRevenue'] ?? 0), Colors.green),
              _buildBreakdownItem('Pending', '₹0', Colors.orange),
              _buildBreakdownItem('Refunded', '₹0', Colors.red),
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
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ),
          const SizedBox(height: 4),
          Container(height: 4, width: 30, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Bookings Overview', trailing: 'This Month'),
          const SizedBox(height: 24),
          Text((data?['totalBookings'] ?? 0).toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.arrow_upward, color: Colors.green, size: 14),
              Text('14.6%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(' vs last month', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          // Mock bar chart area
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(30, (index) {
                double height = 30 + (index % 7) * 15 + (index % 4) * 8;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: height,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCities(Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Top Cities by Listings', trailing: 'This Month'),
          const SizedBox(height: 32),
          _buildCityProgress('Kozhikode', 312, 0.9),
          _buildCityProgress('Calicut', 210, 0.7),
          _buildCityProgress('Kannur', 146, 0.5),
          _buildCityProgress('Thrissur', 98, 0.35),
          _buildCityProgress('Kochi', 76, 0.25),
        ],
      ),
    );
  }

  Widget _buildCityProgress(String city, int count, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(city, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              Text(count.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }
}
