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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final double sidebarWidth = isMobile ? 80 : 100;

          return Row(
            children: [
              _buildSidebar(sidebarWidth),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(32)),
                    child: Column(
                      children: [
                        _buildTopBar(constraints.maxWidth - sidebarWidth),
                        Expanded(child: _buildMainContent()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTopBar(double availableWidth) {
    final bool isMedium = availableWidth < 700;
    final bool isCompact = availableWidth < 500;
    final bool showSearch = availableWidth > 550;
    final bool showBrand = availableWidth > 500;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBrand) ...[
            const Icon(Icons.change_history_rounded, color: Color(0xFFA855F7), size: 22),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Triangle Homes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMedium ? 15 : 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ],

          const Spacer(),

          // Search Box
          if (showSearch)
            Flexible(
              flex: 4,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white60, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search...',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(width: isCompact ? 16 : 24),

          // Notifications
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_outlined, color: Colors.white70, size: isCompact ? 22 : 24),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                  child: const Text('6', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),

          SizedBox(width: isCompact ? 16 : 24),

          // Profile
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: isCompact ? 12 : 14,
                  backgroundColor: const Color(0xFF8B5CF6),
                  child: Text('SA', style: TextStyle(color: Colors.white, fontSize: isCompact ? 8 : 9, fontWeight: FontWeight.bold)),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isMedium ? 11 : 12,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                ],
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white60, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.change_history_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavItem(0, Icons.grid_view_rounded, 'Overview', width),
                  _buildNavItem(1, Icons.assignment_turned_in_outlined, 'Approvals', width, badge: '7'),
                  _buildNavItem(2, Icons.business_outlined, 'Listings', width),
                  _buildNavItem(3, Icons.people_outline_rounded, 'Users', width),
                  _buildNavItem(4, Icons.calendar_today_outlined, 'Bookings', width),
                  _buildNavItem(5, Icons.account_balance_wallet_outlined, 'Payments', width),
                  _buildNavItem(6, Icons.lightbulb_outline_rounded, 'Suggestions', width),
                  _buildNavItem(7, Icons.analytics_outlined, 'Reports', width),
                  _buildNavItem(8, Icons.security_outlined, 'Moderation', width),
                  _buildNavItem(9, Icons.settings_outlined, 'Settings', width),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickActionBtn(),
          const SizedBox(height: 24),
          _buildLogoutBtn(),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, double width, {String? badge}) {
    bool isActive = _activeNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeNavIndex = index),
      child: Container(
        width: width - 16,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white60,
                    fontSize: 8,
                    fontFamily: 'Outfit',
                  ),
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Icon(Icons.bolt_rounded, color: Color(0xFFA855F7), size: 20),
    );
  }

  Widget _buildLogoutBtn() {
    return InkWell(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(height: 4),
          const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 9)),
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
            return OverviewTab(adminService: _adminService, isNarrow: isNarrow);
          case 1:
            return ApprovalsTab(adminService: _adminService, isNarrow: isNarrow);
          case 2:
            return ListingsTab(adminService: _adminService, isNarrow: isNarrow);
          case 3:
            return UsersTab(adminService: _adminService, isNarrow: isNarrow);
          case 4:
            return BookingsTab(adminService: _adminService, isNarrow: isNarrow);
          default:
            return Center(
              child: Text(
                'Tab \${_activeNavIndex} - Content Coming Soon',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            );
        }
      },
    );
  }
}
