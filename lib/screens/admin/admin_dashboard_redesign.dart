import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/splash_screen.dart';

// Import Modular Tabs
import 'package:triangle_home/screens/admin/tabs/overview_tab.dart';
import 'package:triangle_home/screens/admin/tabs/approvals_tab.dart';
import 'package:triangle_home/screens/admin/tabs/listings_tab.dart';
import 'package:triangle_home/screens/admin/tabs/users_tab.dart';
import 'package:triangle_home/screens/admin/tabs/bookings_tab.dart';
import 'package:triangle_home/screens/admin/tabs/payments_tab.dart';
import 'package:triangle_home/screens/admin/tabs/suggestions_tab.dart';
import 'package:triangle_home/screens/admin/tabs/report_tab.dart';
import 'package:triangle_home/screens/admin/tabs/moderation_tab.dart';
import 'package:triangle_home/screens/admin/tabs/settings_tab.dart';
import 'package:triangle_home/screens/admin/tabs/ops_dashboard_tab.dart';

class _ModuleLiveBadge extends StatefulWidget {
  const _ModuleLiveBadge();
  @override
  State<_ModuleLiveBadge> createState() => _ModuleLiveBadgeState();
}

class _ModuleLiveBadgeState extends State<_ModuleLiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FadeTransition(
          opacity: _controller,
          child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
        ),
        const SizedBox(width: 6),
        const Text(
          'Live',
          style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
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
    return StreamBuilder<Map<String, dynamic>>(
      stream: _adminService.getStatsStream(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        return Scaffold(
          backgroundColor: const Color(0xFF020617), // Enterprise Dark Background
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool isNarrow = constraints.maxWidth < 900;
              final double sidebarWidth = isNarrow ? 72 : 280; // Prompt requested 280px

              return Row(
                children: [
                  _buildSidebar(sidebarWidth, isNarrow, data),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBar(data),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF020617),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                              ),
                              child: _buildMainContent(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTopBar(Map<String, dynamic> data) {
    final int notificationCount = data['totalNotifications'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 700;
        final bool isVerySmall = constraints.maxWidth < 500;

        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(color: Color(0xFF020617)), // Enterprise Dark
          child: Row(
            children: [
              const Icon(
                Icons.change_history_rounded,
                color: Color(0xFFA855F7),
                size: 28,
              ),
              if (!isVerySmall) ...[
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Triangle Homes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    _ModuleLiveBadge(),
                  ],
                ),
              ],

              const Spacer(),

              // Global Smart Search
              if (!isVerySmall)
                Flexible(
                  flex: 3,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05), // Glassmorphism
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 18),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search properties, hosters, residents...',
                              hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 24),

              const SizedBox(width: 24),

              // Notifications
              Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white70,
                    size: 24,
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 24),

              // Profile
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA855F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'SA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (!isSmall) ...[
                    const SizedBox(width: 12),
                    const Text(
                      'Super Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white60,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(double width, bool isNarrow, Map<String, dynamic> data) {
    final int pendingApprovals = data['pendingApprovals'] ?? 0;

    return Container(
      width: width,
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.fromLTRB(
        0,
        MediaQuery.of(context).padding.top + 16,
        0,
        24,
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavItem(
                    0,
                    Icons.auto_awesome_mosaic_rounded,
                    'Operations',
                    width,
                    isNarrow,
                  ),
                  _buildNavItem(
                    1,
                    Icons.home_rounded,
                    'Overview',
                    width,
                    isNarrow,
                  ),
                  _buildNavItem(
                    2,
                    Icons.assignment_turned_in_rounded,
                    'Approvals',
                    width,
                    isNarrow,
                    badge:
                        pendingApprovals > 0
                            ? pendingApprovals.toString()
                            : null,
                  ),
                  _buildNavItem(
                    3,
                    Icons.business_rounded,
                    'Listings',
                    width,
                    isNarrow,
                  ),
                  _buildNavItem(
                    4,
                    Icons.people_rounded,
                    'Users',
                    width,
                    isNarrow,
                  ),
                  _buildNavItem(
                    5,
                    Icons.calendar_today_rounded,
                    'Bookings',
                    width,
                    isNarrow,
                  ),
                  _buildNavItem(
                    6,
                    Icons.account_balance_wallet_rounded,
                    'Payments',
                    width,
                    isNarrow,
                  ),
                  _buildNavItem(
                    7,
                    Icons.lightbulb_rounded,
                    'Suggestions',
                    width,
                    isNarrow,
                  ),
                  _buildNavItem(
                    8,
                    Icons.analytics_rounded,
                    'Reports',
                    width,
                    isNarrow,
                  ),
                  _buildNavItem(
                    9,
                    Icons.security_rounded,
                    'Moderation',
                    width,
                    isNarrow,
                  ),
                  _buildNavItem(
                    10,
                    Icons.settings_rounded,
                    'Settings',
                    width,
                    isNarrow,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickActionBtn(isNarrow),
          const SizedBox(height: 32),
          _buildLogoutBtn(isNarrow),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    double width,
    bool isNarrow, {
    String? badge,
  }) {
    bool isActive = _activeNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeNavIndex = index),
      child: Container(
        width: width - (isNarrow ? 16 : 32),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: isNarrow ? 0 : 16,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: Colors.white10) : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: isNarrow ? Alignment.center : Alignment.centerLeft,
          children: [
            Row(
              mainAxisAlignment:
                  isNarrow ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF6366F1) : Colors.white60,
                  size: 22,
                ),
                if (!isNarrow) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white60,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ],
            ),
            if (badge != null)
              Positioned(
                right: isNarrow ? -2 : 0,
                top: isNarrow ? -4 : 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
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

  Widget _buildQuickActionBtn(bool isNarrow) {
    return Container(
      width: isNarrow ? 48 : 200,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFA855F7),
            size: 20,
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 12),
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutBtn(bool isNarrow) {
    return InkWell(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
          if (!isNarrow) ...[
            const SizedBox(width: 12),
            const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 800;

        switch (_activeNavIndex) {
          case 0:
            return OpsDashboardTab(
              adminService: _adminService,
              isNarrow: isNarrow,
            );
          case 1:
            return OverviewTab(adminService: _adminService, isNarrow: isNarrow);
          case 2:
            return ApprovalsTab(
              adminService: _adminService,
              isNarrow: isNarrow,
            );
          case 3:
            return ListingsTab(adminService: _adminService, isNarrow: isNarrow);
          case 4:
            return UsersTab(adminService: _adminService, isNarrow: isNarrow);
          case 5:
            return BookingsTab(adminService: _adminService, isNarrow: isNarrow);
          case 6:
            return PaymentsTab(adminService: _adminService, isNarrow: isNarrow);
          case 7:
            return SuggestionsTab(
              adminService: _adminService,
              isNarrow: isNarrow,
            );
          case 8:
            return ReportTab(adminService: _adminService, isNarrow: isNarrow);
          case 9:
            return ModerationTab(
              adminService: _adminService,
              isNarrow: isNarrow,
            );
          case 10:
            return SettingsTab(adminService: _adminService, isNarrow: isNarrow);
          default:
            return const Center(child: Text('Tab Content Coming Soon'));
        }
      },
    );
  }
}
