import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/models/approval_request.dart';
import 'package:intl/intl.dart';

class AdminDashboardRedesign extends StatefulWidget {
  const AdminDashboardRedesign({super.key});

  @override
  State<AdminDashboardRedesign> createState() => _AdminDashboardRedesignState();
}

class _AdminDashboardRedesignState extends State<AdminDashboardRedesign> {
  final AdminService _adminService = AdminService();
  int _activeNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32)),
                child: _buildMainContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 80,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.change_history_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildNavItem(0, Icons.grid_view_rounded, 'Overview'),
                  _buildNavItem(1, Icons.assignment_turned_in_outlined, 'Approvals', badge: '7'),
                  _buildNavItem(2, Icons.business_outlined, 'Listings'),
                  _buildNavItem(3, Icons.people_outline_rounded, 'Users'),
                  _buildNavItem(4, Icons.calendar_today_outlined, 'Bookings'),
                  _buildNavItem(5, Icons.account_balance_wallet_outlined, 'Payments'),
                  _buildNavItem(6, Icons.lightbulb_outline_rounded, 'Suggestions'),
                  _buildNavItem(7, Icons.analytics_outlined, 'Reports'),
                  _buildNavItem(8, Icons.security_outlined, 'Moderation'),
                  _buildNavItem(9, Icons.settings_outlined, 'Settings'),
                ],
              ),
            ),
          ),
          _buildQuickActionBtn(),
          const SizedBox(height: 16),
          _buildLogoutBtn(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {String? badge}) {
    bool isActive = _activeNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeNavIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isActive ? Colors.white : Colors.white60, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isActive ? Colors.white : Colors.white60, fontSize: 8, fontFamily: 'Outfit'),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                right: 4,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _buildLogoutBtn() {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(height: 2),
          const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 600;

        return _activeNavIndex == 1
            ? _ApprovalsView(adminService: _adminService, isNarrow: isNarrow)
            : _activeNavIndex == 2
                ? _ListingsView(adminService: _adminService, isNarrow: isNarrow)
                : StreamBuilder<Map<String, dynamic>>(
          stream: _adminService.getStatsStream(),
          builder: (context, snapshot) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(isNarrow ? 16 : 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTopBar(isNarrow),
                      const SizedBox(height: 24),
                      _buildHeader(isNarrow),
                      const SizedBox(height: 24),
                      _buildSystemStatusRow(isNarrow),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Critical Actions Required', trailing: 'View All'),
                      const SizedBox(height: 16),
                      _buildCriticalActionsScroll(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Platform Overview', trailing: 'This Month'),
                      const SizedBox(height: 16),
                      _buildPlatformStatsGrid(isNarrow, snapshot.data),
                      const SizedBox(height: 32),

                      if (isNarrow) ...[
                        _buildSuggestionsPipeline(snapshot.data),
                        const SizedBox(height: 24),
                        _buildRecentActivity(),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSuggestionsPipeline(snapshot.data)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildRecentActivity()),
                          ],
                        ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildTopBar(bool isNarrow) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(isNarrow ? 'Search...' : 'Search platform metrics...', style: const TextStyle(color: Colors.grey, fontSize: 12))),
                if (!isNarrow) Text('⌘ K', style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 9)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildIconBadge(Icons.notifications_outlined, '6'),
        const SizedBox(width: 12),
        _buildUserChip(),
      ],
    );
  }

  Widget _buildIconBadge(IconData icon, String count) {
    return Stack(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 22),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
            child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  Widget _buildUserChip() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: const Row(
        children: [
          CircleAvatar(radius: 12, backgroundColor: Color(0xFF8B5CF6), child: Text('SA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
          SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isNarrow ? 'Good morning' : 'Good morning, Super Admin 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Outfit')),
              const SizedBox(height: 2),
              Text(isNarrow ? 'Daily activity.' : 'Platform activity for today.', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Outfit')),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: const Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text('18 May 2025', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatusRow(bool isNarrow) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _buildStatusTag(),
          if (!isNarrow) ...[
            _buildMiniMetric(Icons.auto_graph_rounded, 'Uptime', '99.98%', Colors.green),
            _buildMiniMetric(Icons.speed_rounded, 'Response', '420ms', Colors.blue),
            _buildMiniMetric(Icons.people_alt_outlined, 'Active', '32', Colors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 14),
          SizedBox(width: 6),
          Text('All systems operational', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {required String trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        Text(trailing, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCriticalActionsScroll() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildActionCard('3', 'Pending Host Approvals', const Color(0xFFFEE2E2), const Color(0xFFDC2626), Icons.assignment_ind_outlined),
          const SizedBox(width: 12),
          _buildActionCard('2', 'Reported Listings', const Color(0xFFFFEDD5), const Color(0xFFD97706), Icons.flag_outlined),
          const SizedBox(width: 12),
          _buildActionCard('5', 'Failed Payments', const Color(0xFFF1F5F9), const Color(0xFF475569), Icons.money_off_rounded),
          const SizedBox(width: 12),
          _buildActionCard('4', 'Verification Requests', const Color(0xFFF5F3FF), const Color(0xFF7C3AED), Icons.verified_user_outlined),
          const SizedBox(width: 12),
          _buildActionCard('1', 'Suspicious Accounts', const Color(0xFFFFF1F2), const Color(0xFFE11D48), Icons.report_problem_outlined),
        ],
      ),
    );
  }

  Widget _buildActionCard(String count, String label, Color bg, Color text, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: text, size: 16),
          ),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.2)),
          const SizedBox(height: 12),
          Text('Review Now', style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPlatformStatsGrid(bool isNarrow, Map<String, dynamic>? data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isNarrow ? 2 : 5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatBox('Students', data?['totalStudents']?.toString() ?? '...', '12.5%', true),
        _buildStatBox('Hosters', data?['totalHosters']?.toString() ?? '...', '8.3%', true),
        _buildStatBox('Live Listings', data?['totalProperties']?.toString() ?? '...', '15.2%', true),
        _buildStatBox('Occupancy', '78.6%', '6.1%', true),
        _buildStatBox('Revenue', '₹${data?['totalRevenue'] ?? '...'}', '18.7%', true),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, String percent, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.green, size: 10),
              Text(percent, style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsPipeline(Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Suggestions Pipeline', trailing: 'View All'),
          const SizedBox(height: 20),
          _buildPipelineRow(Icons.rocket_launch_outlined, 'New Suggestions', '18', Colors.blue),
          _buildPipelineRow(Icons.access_time_rounded, 'Under Review', '12', Colors.orange),
          _buildPipelineRow(Icons.phone_in_talk_outlined, 'Contacted', '7', Colors.purple),
          _buildPipelineRow(Icons.check_circle_outline_rounded, 'Approved', '6', Colors.green),
          _buildPipelineRow(Icons.cancel_outlined, 'Rejected', '3', Colors.red),
        ],
      ),
    );
  }

  Widget _buildPipelineRow(IconData icon, String label, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(count, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recent Activity', trailing: 'View All'),
          const SizedBox(height: 20),
          _buildActivityItem('Sunrise Hostels approved', 'Kozhikode, Kerala', '10:30 AM', Icons.home_outlined, Colors.green),
          _buildActivityItem('New hoster registration', 'John Doe', '09:45 AM', Icons.person_outline, Colors.blue),
          _buildActivityItem('New property suggestion submitted', 'Green Valley PG', '09:20 AM', Icons.lightbulb_outline, Colors.purple),
          _buildActivityItem('Payment received', 'Room A-203', '08:50 AM', Icons.payments_outlined, Colors.orange),
          _buildActivityItem('Listing reported', 'Comfort Living PG', '08:15 AM', Icons.flag_outlined, Colors.red),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
        ],
      ),
    );
  }
}

// ── Approvals View ──────────────────────────────────────────────────────────
class _ApprovalsView extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;
  const _ApprovalsView({required this.adminService, required this.isNarrow});

  @override
  State<_ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<_ApprovalsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildTopSection(),
              const SizedBox(height: 32),
              _buildSummaryCards(),
              const SizedBox(height: 32),
              _buildTabSection(),
              const SizedBox(height: 24),
              _buildSearchAndSort(),
              const SizedBox(height: 24),
              _buildRequestsList(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Approvals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(
                widget.isNarrow ? 'Review pending requests' : 'Review and take action on pending requests',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterBtn(),
      ],
    );
  }

  Widget _buildFilterBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: const Row(
        children: [
          Icon(Icons.tune_rounded, size: 18, color: Color(0xFF64748B)),
          SizedBox(width: 8),
          Text('Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildSummaryCard('7', 'Total Pending', const Color(0xFFF1F5F9), const Color(0xFF475569)),
          const SizedBox(width: 12),
          _buildSummaryCard('3', 'Hoster Requests', const Color(0xFFFFF7ED), const Color(0xFFD97706)),
          const SizedBox(width: 12),
          _buildSummaryCard('2', 'Property Listings', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          _buildSummaryCard('1', 'User Verifications', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
          const SizedBox(width: 12),
          _buildSummaryCard('1', 'Other Requests', const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          _buildSummaryCard('24', 'Approved Today', const Color(0xFFF0FDF4), const Color(0xFF16A34A), isSuccess: true),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String count, String label, Color bg, Color text, {bool isSuccess = false}) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: text)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
        tabs: const [
          Tab(text: 'All (7)'),
          Tab(text: 'Hoster Requests (3)'),
          Tab(text: 'Property Listings (2)'),
          Tab(text: 'User Verifications (1)'),
          Tab(text: 'Other (1)'),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: 'Search approvals...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (!widget.isNarrow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Row(
              children: [
                Text('Newest First', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRequestsList() {
    final requests = [
      ApprovalRequest(
        id: '1',
        type: ApprovalType.hosterRequest,
        title: 'Sunrise Hostels',
        requestedBy: 'John Doe',
        isUserVerified: true,
        phone: '+91 70254 77997',
        email: 'john@gmail.com',
        location: 'Kozhikode, Kerala',
        tags: ['PG Hostel', '15 Properties'],
        requestedAt: DateTime.now(),
        metadata: {'docs': '3/3 Uploaded'},
      ),
      ApprovalRequest(
        id: '2',
        type: ApprovalType.propertyListing,
        title: 'Green Valley PG',
        requestedBy: 'John Doe',
        isUserVerified: true,
        location: 'Kozhikode, Kerala',
        tags: ['PG Accommodation', '6 Rooms'],
        requestedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        metadata: {'docs': '4/4 Uploaded'},
      ),
      ApprovalRequest(
        id: '3',
        type: ApprovalType.userVerification,
        title: 'Sarah Ahmed',
        requestedBy: 'Sarah Ahmed',
        isUserVerified: true,
        phone: '+91 79022 33445',
        email: 'sarah.ahmed@example.com',
        tags: ['Identity Verification'],
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        metadata: {'type': 'Identity Verification'},
      ),
    ];

    return Column(
      children: requests.map((r) => _buildApprovalCard(r)).toList(),
    );
  }

  Widget _buildApprovalCard(ApprovalRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardImage(r),
                const SizedBox(width: 20),
                Expanded(child: _buildCardDetails(r)),
                if (!widget.isNarrow) _buildStatusBadge(r.status),
              ],
            ),
          ),
          _buildCardActions(r),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildCardImage(ApprovalRequest r) {
    IconData typeIcon;
    Color iconColor;
    switch (r.type) {
      case ApprovalType.hosterRequest: typeIcon = Icons.business_rounded; iconColor = const Color(0xFFD97706); break;
      case ApprovalType.propertyListing: typeIcon = Icons.home_work_rounded; iconColor = const Color(0xFF2563EB); break;
      case ApprovalType.userVerification: typeIcon = Icons.person_search_rounded; iconColor = const Color(0xFF16A34A); break;
      default: typeIcon = Icons.description_rounded; iconColor = const Color(0xFF7C3AED);
    }

    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
        ),
        Positioned(
          left: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Icon(typeIcon, size: 12, color: iconColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetails(ApprovalRequest r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.type == ApprovalType.hosterRequest ? 'Hoster Request' :
          r.type == ApprovalType.propertyListing ? 'Property Listing' : 'User Verification',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
        ),
        const SizedBox(height: 4),
        Text(r.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(r.requestedBy, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            if (r.isUserVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, size: 12, color: Color(0xFF3B82F6)),
            ],
          ],
        ),
        if (r.phone != null) Text(r.phone!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        if (r.location != null) Text(r.location!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: r.tags.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
      child: const Text('Pending', style: TextStyle(color: Color(0xFFD97706), fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCardActions(ApprovalRequest r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.type == ApprovalType.userVerification ? 'Verification Type' : 'Requested on', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    Text(
                      r.type == ApprovalType.userVerification ? r.metadata['type'] : DateFormat('dd MMM yyyy, hh:mm a').format(r.requestedAt),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              _buildDocBadge(r.metadata['docs'] ?? ''),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActionButton('View Details', Colors.white, const Color(0xFF1E293B), hasBorder: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildActionButton('Approve', const Color(0xFF2563EB), Colors.white, hasDropdown: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildActionButton('Reject', const Color(0xFFFEE2E2), const Color(0xFFDC2626))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocBadge(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('Documents', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
      ],
    );
  }

  Widget _buildActionButton(String label, Color bg, Color text, {bool hasBorder = false, bool hasDropdown = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: hasBorder ? Border.all(color: const Color(0xFFE2E8F0)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
          if (hasDropdown) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: text),
          ],
        ],
      ),
    );
  }
}

// ── Listings View (NEW) ──────────────────────────────────────────────────────
class _ListingsView extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;
  const _ListingsView({required this.adminService, required this.isNarrow});

  @override
  State<_ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends State<_ListingsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildTopSection(),
              const SizedBox(height: 32),
              _buildSummaryCards(),
              const SizedBox(height: 32),
              _buildTabSection(),
              const SizedBox(height: 24),
              _buildFilterRow(),
              const SizedBox(height: 24),
              if (!widget.isNarrow) _buildTableHeader(),
              const SizedBox(height: 12),
              _buildListingsList(),
              const SizedBox(height: 32),
              _buildPagination(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Listings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(
                widget.isNarrow ? 'Manage properties' : 'Manage all properties listed on the platform',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              if (!widget.isNarrow)
                const Text('Add New Listing', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              if (!widget.isNarrow) const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildSummaryCard('1,076', 'Total Listings', const Color(0xFFEFF6FF), const Color(0xFF2563EB), percentage: '12.5%', isUp: true),
          const SizedBox(width: 16),
          _buildSummaryCard('896', 'Active Listings', const Color(0xFFF0FDF4), const Color(0xFF16A34A), sub: '83.3% of total'),
          const SizedBox(width: 16),
          _buildSummaryCard('68', 'Under Review', const Color(0xFFFFFBEB), const Color(0xFFD97706), sub: '6.3% of total'),
          const SizedBox(width: 16),
          _buildSummaryCard('112', 'Inactive/Rejected', const Color(0xFFFEF2F2), const Color(0xFFDC2626), sub: '10.4% of total'),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String count, String label, Color bg, Color color, {String? percentage, bool isUp = true, String? sub}) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.business_rounded, color: color, size: 20),
              ),
              if (percentage != null)
                Row(
                  children: [
                    Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.green, size: 12),
                    Text(percentage, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 10, color: const Color(0xFF94A3B8))),
          ],
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF2563EB),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'All Listings (1,076)'),
          Tab(text: 'Active (896)'),
          Tab(text: 'Under Review (68)'),
          Tab(text: 'Inactive (112)'),
          Tab(text: 'Rejected (48)'),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey, size: 18),
                SizedBox(width: 8),
                Expanded(child: TextField(decoration: InputDecoration(hintText: 'Search properties...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 12)))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildFilterAction(Icons.tune, widget.isNarrow ? '' : 'Filter'),
        if (!widget.isNarrow) ...[
            const SizedBox(width: 12),
            _buildFilterAction(null, 'More Filters', hasDropdown: true),
            const SizedBox(width: 12),
            _buildFilterAction(null, 'Newest First', hasDropdown: true),
        ],
      ],
    );
  }

  Widget _buildFilterAction(IconData? icon, String label, {bool hasDropdown = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: const Color(0xFF64748B)), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          if (hasDropdown) ...[const SizedBox(width: 8), const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B))],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 3, child: _tableLabel('PROPERTY')),
          Expanded(flex: 2, child: _tableLabel('HOSTER & DETAILS')),
          Expanded(flex: 2, child: _tableLabel('STATS')),
          Expanded(flex: 2, child: _tableLabel('STATUS')),
          const SizedBox(width: 40), // Space for action dots
        ],
      ),
    );
  }

  Widget _tableLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5));
  }

  Widget _buildListingsList() {
    return Column(
      children: List.generate(3, (index) => _buildListingCard(index)),
    );
  }

  Widget _buildListingCard(int index) {
    // Mock data for high-fidelity card
    final titles = ['Sunrise Hostels', 'Green Valley PG', 'Comfort Living PG'];
    final locs = ['Kozhikode, Kerala', 'Kozhikode, Kerala', 'Thrissur, Kerala'];
    final types = ['PG Hostel', 'PG Accommodation', 'PG Accommodation'];
    final rooms = ['15 Rooms • 3 Sharing', '20 Rooms • 2 & 3 Sharing', '12 Rooms • 3 Sharing'];
    final hosters = ['John Doe', 'Mike Johnson', 'Aman Singh'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // 1. Property Column
                Expanded(
                  flex: widget.isNarrow ? 1 : 3,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(width: 50, height: 50, color: const Color(0xFFF1F5F9), child: const Icon(Icons.business_rounded, color: Colors.grey, size: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 12),
                              ],
                            ),
                            Text(types[index], style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            if (!widget.isNarrow) ...[
                                const SizedBox(height: 4),
                                Row(
                                    children: [
                                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text(locs[index], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Hoster Column (Hidden on mobile)
                if (!widget.isNarrow)
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        CircleAvatar(radius: 16, backgroundColor: const Color(0xFFF5F3FF), child: Text(hosters[index][0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hosters[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                              const Text('Verified Hoster', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 3. Stats Column (Hidden on mobile)
                if (!widget.isNarrow)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _miniStat('Views', '1,245'),
                        _miniStat('Bookings', '32'),
                      ],
                    ),
                  ),

                // 4. Status Column
                Expanded(
                  flex: widget.isNarrow ? 0 : 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Active', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      if (!widget.isNarrow) ...[
                        const SizedBox(height: 8),
                        const Text('10 May 2025', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
              ],
            ),
            if (widget.isNarrow) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Row(
                            children: [
                                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(locs[index], style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                        ),
                        Text(rooms[index], style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.isNarrow ? '1-10 of 1,076' : 'Showing 1 to 10 of 1,076 listings',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            _pageBtn(Icons.chevron_left, false),
            _pageBtn(null, true, label: '1'),
            if (!widget.isNarrow) _pageBtn(null, false, label: '2'),
            if (!widget.isNarrow) _pageBtn(null, false, label: '3'),
            if (!widget.isNarrow) ...[
                const Text('...', style: TextStyle(color: Colors.grey)),
                _pageBtn(null, false, label: '108'),
            ],
            _pageBtn(Icons.chevron_right, false),
          ],
        ),
      ],
    );
  }

  Widget _pageBtn(IconData? icon, bool active, {String? label}) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2563EB) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: icon != null
          ? Icon(icon, size: 16, color: const Color(0xFF64748B))
          : Text(label!, style: TextStyle(color: active ? Colors.white : const Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

