import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/screens/admin/property_detail_screen.dart';
import 'package:triangle_home/splash_screen.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  int _selectedIndex = 0;
  StreamSubscription? _notifSubscription;

  @override
  void initState() {
    super.initState();
    _initNotificationListener();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  void _showTopNotification(String title, String body, String? propertyId) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notification_important, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(body, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (propertyId != null) {
                  // Fetch full property details in real-time
                  final doc = await FirebaseFirestore.instance
                      .collection('properties')
                      .doc(propertyId)
                      .get();
                  
                  if (doc.exists && mounted) {
                    final data = doc.data()!;
                    data['id'] = doc.id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailScreen(
                          property: data,
                          adminService: _adminService,
                        ),
                      ),
                    );
                  }
                } else {
                  setState(() => _selectedIndex = 2);
                }
              },
              child: const Text('VIEW', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  void _initNotificationListener() {
    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('user_id', isEqualTo: 'admin')
        .where('is_read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final notifDoc = snapshot.docs.first;
        final notif = notifDoc.data();
        final createdAt = notif['createdAt'] as Timestamp?;
        
        if (createdAt != null && 
            DateTime.now().difference(createdAt.toDate()).inSeconds < 30) {
          final String? propId = notif['data']?['propertyId'];
          _showTopNotification(notif['title'], notif['body'], propId);
          
          // Mark as read so it doesn't pop up again
          notifDoc.reference.update({'is_read': true});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
          onPressed: () => _handleExit(context),
          tooltip: 'Exit Control Panel',
        ),
        title: const Text(
          'Control Panel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontFamily,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                const SizedBox(width: 8),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          _buildNavigationRail(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                ),
                child: _buildCurrentView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExit(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Exit Control Panel?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'You will be signed out from the admin session.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Sign Out & Exit'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      backgroundColor: AppTheme.primaryColor,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      labelType: NavigationRailLabelType.selected,
      selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
      unselectedIconTheme: IconThemeData(
        color: Colors.white.withValues(alpha: 0.6),
        size: 24,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        fontFamily: AppTheme.fontFamily,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 11,
        fontFamily: AppTheme.fontFamily,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Overview'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('Users'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.home_work_outlined),
          selectedIcon: Icon(Icons.home_work_rounded),
          label: Text('Listings'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bookmark_border_rounded),
          selectedIcon: Icon(Icons.bookmark_rounded),
          label: Text('Bookings'),
        ),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _StatsView(
          adminService: _adminService,
          onTabSwitch: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return _UsersView(adminService: _adminService);
      case 2:
        return _PropertiesView(adminService: _adminService);
      case 3:
        return _BookingsView(adminService: _adminService);
      default:
        return const Center(child: Text('Select an option'));
    }
  }
}

// ── Overview View (REALTIME) ──────────────────────────────────────────────────
class _StatsView extends StatelessWidget {
  final AdminService adminService;
  final Function(int) onTabSwitch;
  const _StatsView({required this.adminService, required this.onTabSwitch});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: adminService.getStatsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.textDarkColor,
                ),
              ).animate().fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 8),
              const Text(
                'Real-time metrics for your property ecosystem',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLightColor,
                  fontFamily: AppTheme.fontFamily,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount =
                      constraints.maxWidth > 800
                          ? 3
                          : (constraints.maxWidth > 500 ? 2 : 1);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        title: 'Total Revenue',
                        value: '₹${stats['totalRevenue']}',
                        icon: Icons.account_balance_wallet_rounded,
                        gradient: const [Color(0xFF0F172A), Color(0xFF334155)],
                        index: 0,
                      ),
                      _StatCard(
                        title: 'Students',
                        value: stats['totalStudents'].toString(),
                        icon: Icons.school_rounded,
                        gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                        index: 1,
                        onTap: () => onTabSwitch(1),
                      ),
                      _StatCard(
                        title: 'Hosters',
                        value: stats['totalHosters'].toString(),
                        icon: Icons.person_pin_rounded,
                        gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                        index: 2,
                        onTap: () => onTabSwitch(1),
                      ),
                      _StatCard(
                        title: 'Live Listings',
                        value: stats['totalProperties'].toString(),
                        icon: Icons.holiday_village_rounded,
                        gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                        index: 3,
                        onTap: () => onTabSwitch(2),
                      ),
                      _StatCard(
                        title: 'Pending Hosters',
                        value: stats['pendingHosters']?.toString() ?? '0',
                        icon: Icons.person_add_alt_1_rounded,
                        gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                        index: 4,
                        onTap: () => onTabSwitch(1),
                      ),
                      _StatCard(
                        title: 'Listing Approvals',
                        value: stats['pendingProperties'].toString(),
                        icon: Icons.notification_important_rounded,
                        gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
                        index: 5,
                        onTap: () => onTabSwitch(2),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final int index;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    if (onTap != null)
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 1.0,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (100 * index).ms)
        .scale(begin: const Offset(0.9, 0.9));
  }
}

// ── Users View (REALTIME) ─────────────────────────────────────────────────────
class _UsersView extends StatefulWidget {
  final AdminService adminService;
  const _UsersView({required this.adminService});

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          elevation: 1,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textMutedColor,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 4,
            tabs: const [
              Tab(
                height: 60,
                child: Text(
                  'Hosters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                height: 60,
                child: Text(
                  'Students',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        _buildSearchBar('Search live users...'),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.adminService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final allUsers = snapshot.data ?? [];
              final students =
                  allUsers
                      .where(
                        (u) => (u['role'] == 'student' || u['role'] == 'user'),
                      )
                      .where(_filterUser)
                      .toList();
              final hosters =
                  allUsers
                      .where((u) => u['role'] == 'hoster')
                      .where(_filterUser)
                      .toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildUserList(hosters, isHoster: true),
                  _buildUserList(students, isHoster: false),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  bool _filterUser(Map<String, dynamic> u) {
    final query = _searchQuery.toLowerCase();
    final name = (u['name'] ?? '').toString().toLowerCase();
    final email = (u['email'] ?? '').toString().toLowerCase();
    final phone = (u['phoneNumber'] ?? '').toString().toLowerCase();
    return name.contains(query) ||
        email.contains(query) ||
        phone.contains(query);
  }

  Widget _buildSearchBar(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.primaryColor,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List users, {required bool isHoster}) {
    if (users.isEmpty) return const Center(child: Text('No users found'));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final bool isBanned = user['accountStatus'] == 'banned';
        final bool isApproved = user['status'] == 'approved';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    user['name']?[0].toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  user['name'] ?? 'Anonymous User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? 'No email',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (isBanned)
                          _Badge(text: 'Banned', color: Colors.red)
                        else ...[
                          if (isHoster)
                            _Badge(
                              text: isApproved ? 'Approved' : 'Pending',
                              color: isApproved ? Colors.green : Colors.orange,
                            )
                          else
                            const _Badge(text: 'Active', color: Colors.blue),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing:
                    isHoster && !isApproved
                        ? ElevatedButton(
                          onPressed:
                              () =>
                                  widget.adminService.approveHoster(user['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        )
                        : IconButton(
                          icon: Icon(
                            isBanned
                                ? Icons.settings_backup_restore_rounded
                                : Icons.block_flipped,
                            color:
                                isBanned
                                    ? Colors.green
                                    : Colors.red.withValues(alpha: 0.6),
                          ),
                          onPressed:
                              () => widget.adminService.toggleUserStatus(
                                user['id'],
                                isBanned,
                              ),
                        ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms);
      },
    );
  }
}

// ── Listings View (REALTIME) ──────────────────────────────────────────────────
class _PropertiesView extends StatefulWidget {
  final AdminService adminService;
  const _PropertiesView({required this.adminService});

  @override
  State<_PropertiesView> createState() => _PropertiesViewState();
}

class _PropertiesViewState extends State<_PropertiesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          elevation: 1,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primaryColor,
            tabs: const [
              Tab(height: 60, text: 'All'),
              Tab(height: 60, text: 'Pending'),
              Tab(height: 60, text: 'Approved'),
              Tab(height: 60, text: 'Rejected'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.adminService.getPropertiesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snapshot.data ?? [];
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildList(all),
                  _buildList(
                    all.where((p) => p['status'] == 'pending').toList(),
                  ),
                  _buildList(
                    all.where((p) => p['status'] == 'approved').toList(),
                  ),
                  _buildList(
                    all.where((p) => p['status'] == 'rejected').toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> props) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: props.length,
      itemBuilder: (context, index) {
        final p = props[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(
                    property: p,
                    adminService: widget.adminService,
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(p['title'] ?? 'Untitled'),
              subtitle: Text(p['address'] ?? 'No address'),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMutedColor),
                onSelected: (value) async {
                  if (value == 'details') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailScreen(
                          property: p,
                          adminService: widget.adminService,
                        ),
                      ),
                    );
                  } else if (value == 'approve') {
                    await widget.adminService.updatePropertyStatus(
                      p['id'],
                      PropertyStatus.approved,
                    );
                  } else if (value == 'reject') {
                    await widget.adminService.updatePropertyStatus(
                      p['id'],
                      PropertyStatus.rejected,
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Listing?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.adminService.deleteListing(p['id']);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 12),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  if (p['status'] != 'approved' && p['status'] != 'active')
                    const PopupMenuItem(
                      value: 'approve',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                          SizedBox(width: 12),
                          Text('Approve', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                  if (p['status'] != 'rejected')
                    const PopupMenuItem(
                      value: 'reject',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, size: 18, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Reject', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete Listing', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Bookings View (REALTIME) ──────────────────────────────────────────────────
class _BookingsView extends StatelessWidget {
  final AdminService adminService;
  const _BookingsView({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: adminService.getBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookings = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final b = bookings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(b['propertyName'] ?? 'Booking'),
                  subtitle: Text('By ${b['studentName']}'),
                  trailing: Text(
                    '₹${b['price']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
