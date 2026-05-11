import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/services/admin_api_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminApiService _apiService = AdminApiService();
  int _selectedIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh stats every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          _buildNavigationRail(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBgColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32)),
                child: _buildCurrentView(),
              ),
            ),
          ),
        ],
      ),
    );
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
      unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.6), size: 24),
      selectedLabelTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        fontFamily: AppTheme.fontFamily,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.white.withOpacity(0.6),
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
          apiService: _apiService,
          onTabSwitch: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return _UsersView(apiService: _apiService);
      case 2:
        return _PropertiesView(apiService: _apiService);
      case 3:
        return _BookingsView(apiService: _apiService);
      default:
        return const Center(child: Text('Select an option'));
    }
  }
}

// ── Overview View ────────────────────────────────────────────────────────────
class _StatsView extends StatelessWidget {
  final AdminApiService apiService;
  final Function(int) onTabSwitch;
  const _StatsView({required this.apiService, required this.onTabSwitch});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: apiService.getStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        if (snapshot.hasError) {
          return _ErrorState(error: snapshot.error.toString());
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.textDarkColor,
                ),
              ).animate().fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 8),
              Text(
                'Monitor and manage your property ecosystem',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLightColor,
                  fontFamily: AppTheme.fontFamily,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),

              LayoutBuilder(builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
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
                      title: 'Active Students',
                      value: stats['totalStudents'].toString(),
                      icon: Icons.school_rounded,
                      gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                      index: 1,
                      onTap: () => onTabSwitch(1),
                    ),
                    _StatCard(
                      title: 'Total Hosters',
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
              }),

              const SizedBox(height: 40),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.textDarkColor
                ),
              ),
              const SizedBox(height: 16),
              _QuickActionsSection(),
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
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                if (onTap != null)
                  const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 16),
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
                    color: Colors.white.withOpacity(0.8),
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
    ).animate().fadeIn(delay: (100 * index).ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      {'label': 'Add Admin', 'icon': Icons.admin_panel_settings_rounded, 'color': Colors.blueGrey},
      {'label': 'Global Mail', 'icon': Icons.mail_outline_rounded, 'color': Colors.indigo},
      {'label': 'Reports', 'icon': Icons.analytics_rounded, 'color': Colors.teal},
      {'label': 'Settings', 'icon': Icons.settings_suggest_rounded, 'color': Colors.orange},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: actions.map((action) => _ActionTile(
        label: action['label'] as String,
        icon: action['icon'] as IconData,
        color: action['color'] as Color,
      )).toList(),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ActionTile({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: AppTheme.fontFamily),
          ),
        ],
      ),
    );
  }
}

// ── Users View ──────────────────────────────────────────────────────────────
class _UsersView extends StatefulWidget {
  final AdminApiService apiService;
  const _UsersView({required this.apiService});

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
            tabs: const [
              Tab(height: 60, child: Text('Hosters', style: TextStyle(fontWeight: FontWeight.bold))),
              Tab(height: 60, child: Text('Students', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        _buildSearchBar('Search by name, email or phone...'),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: widget.apiService.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

              final students = (snapshot.data!['students'] as List).where(_filterUser).toList();
              final hosters = (snapshot.data!['hosters'] as List).where(_filterUser).toList();

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

  bool _filterUser(dynamic u) {
    final query = _searchQuery.toLowerCase();
    final name = (u['name'] ?? '').toString().toLowerCase();
    final email = (u['email'] ?? '').toString().toLowerCase();
    final phone = (u['phoneNumber'] ?? '').toString().toLowerCase();
    return name.contains(query) || email.contains(query) || phone.contains(query);
  }

  Widget _buildSearchBar(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List users, {required bool isHoster}) {
    if (users.isEmpty) return _EmptyState(message: 'No users found matching your search');

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final bool isBanned = user['accountStatus'] == 'banned';
        final bool isApproved = user['status'] == 'approved';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _UserAvatar(name: user['name'] ?? 'U'),
            title: Text(
              user['name'] ?? 'Anonymous User',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: AppTheme.fontFamily),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(user['email'] ?? 'No email provided', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                _UserBadgeRow(isBanned: isBanned, isHoster: isHoster, isApproved: isApproved),
              ],
            ),
            trailing: isHoster && !isApproved
              ? _ApproveButton(onPressed: () async {
                  await widget.apiService.approveHoster(user['id']);
                  setState(() {});
                })
              : _UserActionIcon(
                  isBanned: isBanned,
                  onTap: () async {
                    final newStatus = isBanned ? 'active' : 'banned';
                    await widget.apiService.toggleUserStatus(user['id'], isHoster ? 'hoster' : 'student', newStatus);
                    setState(() {});
                  },
                ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1);
      },
    );
  }
}

// ── Listings View ────────────────────────────────────────────────────────────
class _PropertiesView extends StatefulWidget {
  final AdminApiService apiService;
  const _PropertiesView({required this.apiService});

  @override
  State<_PropertiesView> createState() => _PropertiesViewState();
}

class _PropertiesViewState extends State<_PropertiesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
            unselectedLabelColor: AppTheme.textMutedColor,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 4,
            tabs: const [
              Tab(height: 60, child: Text('All Listings', style: TextStyle(fontWeight: FontWeight.bold))),
              Tab(height: 60, child: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold))),
              Tab(height: 60, child: Text('Approved', style: TextStyle(fontWeight: FontWeight.bold))),
              Tab(height: 60, child: Text('Rejected', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        _buildSearchBar('Search properties by title, address, or type...'),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.apiService.getAllProperties(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

              final all = snapshot.data ?? [];
              final filtered = all.where((p) {
                final q = _searchQuery.toLowerCase();
                final title = (p['title'] ?? p['name'] ?? '').toString().toLowerCase();
                final addr = (p['address'] ?? '').toString().toLowerCase();
                return title.contains(q) || addr.contains(q);
              }).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildPropertyList(filtered),
                  _buildPropertyList(filtered.where((p) => p['status'] == 'pending').toList()),
                  _buildPropertyList(filtered.where((p) => p['status'] == 'approved').toList()),
                  _buildPropertyList(filtered.where((p) => p['status'] == 'rejected').toList()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyList(List<Map<String, dynamic>> properties) {
    if (properties.isEmpty) return _EmptyState(message: 'No property listings found');

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final p = properties[index];
        final String status = p['status'] ?? 'pending';
        final bool isPending = status == 'pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: (p['images'] as List?)?.isNotEmpty == true
                        ? Image.network(p['images'][0], fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 50)),
                    ),
                    Positioned(top: 16, right: 16, child: _PropertyStatusBadge(status: status)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['title'] ?? p['name'] ?? 'Untitled Property',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: AppTheme.fontFamily),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textMutedColor),
                        const SizedBox(width: 4),
                        Expanded(child: Text(p['address'] ?? 'No address', style: const TextStyle(color: AppTheme.textMutedColor, fontSize: 13))),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RENT / MONTH', style: TextStyle(fontSize: 10, color: AppTheme.textLightColor, fontWeight: FontWeight.bold)),
                            Text('₹${p['price'] ?? p['monthlyRent'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 20)),
                          ],
                        ),
                        if (isPending)
                          Row(
                            children: [
                              _CircleActionButton(icon: Icons.close_rounded, color: Colors.red, onTap: () => _updateStatus(p['id'], 'rejected')),
                              const SizedBox(width: 12),
                              _CircleActionButton(icon: Icons.check_rounded, color: Colors.green, onTap: () => _updateStatus(p['id'], 'approved')),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1);
      },
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await widget.apiService.updatePropertyStatus(id, status);
      setState(() {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Property $status successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ── Bookings View ────────────────────────────────────────────────────────────
class _BookingsView extends StatefulWidget {
  final AdminApiService apiService;
  const _BookingsView({required this.apiService});

  @override
  State<_BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<_BookingsView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text('All Platform Bookings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: AppTheme.fontFamily)),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.apiService.getAllBookings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

              final bookings = snapshot.data ?? [];
              if (bookings.isEmpty) return _EmptyState(message: 'No bookings found on the platform');

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final b = bookings[index];
                  final status = b['status'] as String? ?? 'pending';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['propertyName'] ?? 'Property', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('By ${b['studentName'] ?? 'Student'}', style: const TextStyle(color: AppTheme.textMutedColor, fontSize: 13)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${b['price'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
                            const SizedBox(height: 4),
                            _SimpleBadge(status: status),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (50 * index).ms);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── UI Components ────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String name;
  const _UserAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      child: Text(
        name[0].toUpperCase(),
        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}

class _UserBadgeRow extends StatelessWidget {
  final bool isBanned;
  final bool isHoster;
  final bool isApproved;
  const _UserBadgeRow({required this.isBanned, required this.isHoster, required this.isApproved});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        if (isBanned) _Badge(text: 'Banned', color: Colors.red)
        else ...[
          if (isHoster) _Badge(text: isApproved ? 'Approved Hoster' : 'Pending Hoster', color: isApproved ? Colors.green : Colors.orange)
          else _Badge(text: 'Active Student', color: Colors.blue),
        ]
      ],
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _ApproveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ApproveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _UserActionIcon extends StatelessWidget {
  final bool isBanned;
  final VoidCallback onTap;
  const _UserActionIcon({required this.isBanned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isBanned ? Icons.settings_backup_restore_rounded : Icons.block_flipped, color: isBanned ? Colors.green : Colors.red.withOpacity(0.6)),
      onPressed: onTap,
    );
  }
}

class _PropertyStatusBadge extends StatelessWidget {
  final String status;
  const _PropertyStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _SimpleBadge extends StatelessWidget {
  final String status;
  const _SimpleBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == 'confirmed' || status == 'approved' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.red);
    return Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10));
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Oops! Something went wrong', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMutedColor)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}
