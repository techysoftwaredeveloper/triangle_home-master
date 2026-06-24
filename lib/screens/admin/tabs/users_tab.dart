import 'package:flutter/material.dart';
import 'package:triangle_home/screens/admin/user_profile_view_screen.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UsersTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const UsersTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Data Fetching Error',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry Connection'),
                  ),
                ],
              ),
            ),
          );
        }

        final allUsers = snapshot.data ?? [];

        // Dynamic Filtering
        final filteredUsers = allUsers.where((u) {
          final info = Map<String, dynamic>.from((u['info'] as Map? ?? {}));
          final name = info['name']?.toString().toLowerCase() ?? '';
          final email = info['email']?.toString().toLowerCase() ?? '';
          final phone = (info['phone'] ?? info['phoneNumber'])
                  ?.toString()
                  .toLowerCase() ??
              '';

          final matchesSearch = name.contains(_searchQuery) ||
              email.contains(_searchQuery) ||
              phone.contains(_searchQuery);

          // Support both top-level and nested role
          final permissions =
              Map<String, dynamic>.from((u['permissions'] as Map? ?? {}));
          final role = (u['role'] ?? permissions['role'])
                  ?.toString()
                  .toLowerCase() ??
              '';
          final isActive = u['is_active'] as bool? ?? true;

          switch (_tabController.index) {
            case 1: // Students
              return matchesSearch &&
                  (role == 'student' || role == 'user' || role == '');
            case 2: // Professionals
              return matchesSearch && role == 'professional';
            case 3: // Hosters
              return matchesSearch &&
                  (role == 'hoster' ||
                      role == 'owner' ||
                      role == 'manager' ||
                      role == 'agency');
            case 4: // Blocked
              return matchesSearch && !isActive;
            default: // All
              return matchesSearch;
          }
        }).toList();

        return Container(
          color: const Color(0xFF020617),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabHeader(
                  title: 'Users Hub',
                  subtitle: widget.isNarrow
                      ? 'Community'
                      : 'Manage all platform users and community members',
                  isNarrow: widget.isNarrow,
                  actions: [
                    if (!widget.isNarrow)
                      _buildHeaderAction(
                        'Export',
                        Icons.file_download_outlined,
                        isOutline: true,
                        onPressed: _handleExport,
                      ),
                    if (!widget.isNarrow) const SizedBox(width: 12),
                    _buildHeaderAction(
                      'Add User',
                      Icons.add,
                      hasDropdown: true,
                      onPressed: _handleAddUser,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSummaryCards(allUsers),
                const SizedBox(height: 64),
                _buildCategoryTabs(allUsers),
                const SizedBox(height: 24),
                _buildFilterRow(),
                const SizedBox(height: 24),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    allUsers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  _buildUsersGrid(filteredUsers),
                const SizedBox(height: 32),
                _buildPaginationFooter(filteredUsers.length),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> users) {
    final students = users.where((u) {
      final permissions =
          Map<String, dynamic>.from((u['permissions'] as Map? ?? {}));
      final r = (u['role'] ?? permissions['role'])?.toString().toLowerCase() ??
          '';
      return r == 'student' || r == 'user' || r == '';
    }).length;

    final professionals = users.where((u) {
      final permissions =
          Map<String, dynamic>.from((u['permissions'] as Map? ?? {}));
      final r = (u['role'] ?? permissions['role'])?.toString().toLowerCase() ??
          '';
      return r == 'professional';
    }).length;

    final hosters = users.where((u) {
      final permissions =
          Map<String, dynamic>.from((u['permissions'] as Map? ?? {}));
      final r = (u['role'] ?? permissions['role'])?.toString().toLowerCase() ??
          '';
      return r == 'hoster' ||
          r == 'owner' ||
          r == 'manager' ||
          r == 'agency';
    }).length;

    final inactive = users.where((u) => (u['is_active'] == false)).length;

    final double cardWidth = widget.isNarrow ? 160 : 220;
    final double cardHeight = widget.isNarrow ? 140 : 180;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _wrapInSizedBox(
            cardWidth,
            cardHeight,
            SummaryCard(
              count: users.length.toString(),
              label: 'Total Users',
              bg: const Color(0xFFEFF6FF).withValues(alpha: 0.1),
              color: const Color(0xFF2563EB),
              icon: Icons.people_rounded,
              percentage: '12.6%',
              isUp: true,
              isDark: true,
            ),
          ),
          const SizedBox(width: 16),
          _wrapInSizedBox(
            cardWidth,
            cardHeight,
            SummaryCard(
              count: students.toString(),
              label: 'Students',
              bg: const Color(0xFFF0FDF4).withValues(alpha: 0.1),
              color: const Color(0xFF16A34A),
              icon: Icons.school_rounded,
              sub: users.isEmpty
                  ? '0% of total'
                  : '${((students / users.length) * 100).toStringAsFixed(1)}% of total',
              isDark: true,
            ),
          ),
          const SizedBox(width: 16),
          _wrapInSizedBox(
            cardWidth,
            cardHeight,
            SummaryCard(
              count: professionals.toString(),
              label: 'Professionals',
              bg: const Color(0xFFF5F3FF).withValues(alpha: 0.1),
              color: const Color(0xFF7C3AED),
              icon: Icons.business_center_rounded,
              sub: users.isEmpty
                  ? '0% of total'
                  : '${((professionals / users.length) * 100).toStringAsFixed(1)}% of total',
              isDark: true,
            ),
          ),
          const SizedBox(width: 16),
          _wrapInSizedBox(
            cardWidth,
            cardHeight,
            SummaryCard(
              count: hosters.toString(),
              label: 'Hosters',
              bg: const Color(0xFFFFF7ED).withValues(alpha: 0.1),
              color: const Color(0xFFD97706),
              icon: Icons.person_pin_rounded,
              sub: users.isEmpty
                  ? '0% of total'
                  : '${((hosters / users.length) * 100).toStringAsFixed(1)}% of total',
              isDark: true,
            ),
          ),
          const SizedBox(width: 16),
          _wrapInSizedBox(
            cardWidth,
            cardHeight,
            SummaryCard(
              count: inactive.toString(),
              label: 'Inactive',
              bg: const Color(0xFFFEF2F2).withValues(alpha: 0.1),
              color: const Color(0xFFDC2626),
              icon: Icons.block_rounded,
              sub: users.isEmpty
                  ? '0% of total'
                  : '${((inactive / users.length) * 100).toStringAsFixed(1)}% of total',
              isDark: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapInSizedBox(double w, double h, Widget child) =>
      SizedBox(width: w, height: h, child: child);

  Widget _buildCategoryTabs(List<Map<String, dynamic>> users) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          fontFamily: 'Outfit',
        ),
        tabs: [
          Tab(text: 'All (${users.length})'),
          Tab(
            text: 'Students (${users.where((u) {
              final p =
                  Map<String, dynamic>.from((u['permissions'] as Map? ?? {}));
              final r = (u['role'] ?? p['role'])?.toString().toLowerCase() ?? '';
              return r == 'student' || r == 'user' || r.isEmpty;
            }).length})',
          ),
          Tab(
            text: 'Pros (${users.where((u) {
              final p =
                  Map<String, dynamic>.from((u['permissions'] as Map? ?? {}));
              return (u['role'] ?? p['role'])?.toString().toLowerCase() ==
                  'professional';
            }).length})',
          ),
          Tab(
            text: 'Hosters (${users.where((u) {
              final p =
                  Map<String, dynamic>.from((u['permissions'] as Map? ?? {}));
              final r = (u['role'] ?? p['role'])?.toString().toLowerCase() ?? '';
              return r == 'hoster' ||
                  r == 'owner' ||
                  r == 'manager' ||
                  r == 'agency';
            }).length})',
          ),
          Tab(
            text:
                'Blocked (${users.where((u) => (u['is_active'] == false)).length})',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search by name, email or ID...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 3,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildSmallFilter('User Role'),
                const SizedBox(width: 12),
                _buildSmallFilter('Account Status'),
                const SizedBox(width: 12),
                _buildSmallFilter('Location'),
                const SizedBox(width: 12),
                _buildSmallFilter('Join Date'),
                const SizedBox(width: 12),
                _buildSmallFilter('More Filters', hasDropdown: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallFilter(
    String label, {
    IconData? icon,
    bool hasDropdown = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF475569),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsersGrid(List<Map<String, dynamic>> users) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1200,
          child: Column(
            children: [
              _buildGridHeader(),
              if (users.isEmpty)
                _buildEmptyState()
              else
                ...users.map((u) {
                  final info = Map<String, dynamic>.from((u['info'] as Map? ?? {}));
                  final permissions = Map<String, dynamic>.from((u['permissions'] as Map? ?? {}));
                  final rawRole = (u['role'] ?? permissions['role'])?.toString() ?? 'student';
                  final isActive = u['is_active'] as bool? ?? true;

                  String userStatus = isActive ? 'Active' : 'Blocked';
                  if (isActive) {
                    final r = rawRole.toLowerCase();
                    if (r == 'hoster' || r == 'owner' || r == 'manager' || r == 'agency') {
                      final onboardingStatus = (u['status'] ?? u['accountStatus'] ?? permissions['status'] ?? '').toString().toLowerCase();
                      if (onboardingStatus == 'pending') {
                        userStatus = 'Pending';
                      } else if (onboardingStatus == 'approved' || onboardingStatus == 'active') {
                        userStatus = 'Approved';
                      } else if (onboardingStatus == 'rejected') {
                        userStatus = 'Rejected';
                      }
                    }
                  }

                  return _UserRow(
                    user: u,
                    name: info['name']?.toString() ?? 'Unknown User',
                    displayId: u['id']?.toString().substring(0, 8).toUpperCase() ?? 'USR-NEW',
                    role: _formatRole(rawRole),
                    rawRole: rawRole,
                    phone: (info['phone'] ?? info['phoneNumber'])?.toString() ?? 'No Phone',
                    email: info['email']?.toString() ?? 'No Email',
                    joined: _formatDate(u['createdAt'] ?? u['updatedAt']),
                    status: userStatus,
                    isActive: isActive,
                    onAction: () => _showUserActionsBottomSheet(context, u),
                    onTap: () => _viewUserProfile(u),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: const Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const SizedBox(width: 16),
          const Expanded(flex: 3, child: _HeaderLabel('USER')),
          const Expanded(flex: 2, child: _HeaderLabel('ROLE')),
          const Expanded(flex: 3, child: _HeaderLabel('CONTACT')),
          const Expanded(flex: 2, child: _HeaderLabel('LOCATION')),
          const Expanded(flex: 2, child: _HeaderLabel('JOINED')),
          const Expanded(flex: 2, child: _HeaderLabel('STATUS')),
          const SizedBox(width: 48, child: _HeaderLabel('ACTIONS')),
        ],
      ),
    );
  }

  void _viewUserProfile(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(
          userId: user['id'],
          adminService: widget.adminService,
          initialData: user,
        ),
      ),
    );
  }

  void _showUserActionsBottomSheet(BuildContext context, Map<String, dynamic> user) {
    final info = Map<String, dynamic>.from((user['info'] as Map? ?? {}));
    final name = info['name']?.toString() ?? 'Unknown User';
    final isActive = user['is_active'] as bool? ?? true;
    final userId = user['id'];
    final rawRole = (user['role'] ?? user['permissions']?['role'])?.toString().toLowerCase() ?? 'student';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF1E293B),
                    child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('ID: ${userId.toString().toUpperCase()}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _actionItem(Icons.visibility_outlined, 'View Full Profile', () {
                Navigator.pop(context);
                _viewUserProfile(user);
              }),
              _actionItem(
                isActive ? Icons.block_flipped : Icons.check_circle_outline,
                isActive ? 'Deactivate Account' : 'Activate Account',
                () {
                  Navigator.pop(context);
                  _handleUserAction(userId, isActive ? 'deactivate' : 'activate');
                },
                color: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
              _actionItem(Icons.admin_panel_settings_outlined, 'Promote to Admin', () {
                Navigator.pop(context);
                _handleUserAction(userId, 'promote');
              }),
              _actionItem(Icons.manage_accounts_outlined, 'Change User Role', () {
                Navigator.pop(context);
                _showChangeRoleDialog(userId, rawRole);
              }),
              const Divider(color: Color(0x0DFFFFFF), height: 32),
              _actionItem(Icons.delete_forever_outlined, 'Delete User Permanently', () {
                Navigator.pop(context);
                _handleUserAction(userId, 'delete');
              }, color: const Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? const Color(0xFF94A3B8)),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(String userId, String currentRole) {
    // We already have _showChangeRoleBottomSheet in UserProfileViewScreen, 
    // but let's implement a quick one here or just use a simple alert dialog.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Select New Role', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roleDialogOption(userId, 'student', 'Student', Icons.school_outlined),
            _roleDialogOption(userId, 'professional', 'Professional', Icons.business_center_outlined),
            _roleDialogOption(userId, 'hoster', 'Hoster', Icons.person_pin_outlined),
            _roleDialogOption(userId, 'owner', 'Owner', Icons.home_work_outlined),
          ],
        ),
      ),
    );
  }

  Widget _roleDialogOption(String userId, String role, String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6366F1)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        _handleUserAction(userId, 'role_$role');
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 64, color: Color(0x1AFFFFFF)),
          const SizedBox(height: 16),
          const Text('No community members found', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleUserAction(String userId, String action) async {
    try {
      switch (action) {
        case 'activate':
          await widget.adminService.toggleUserStatus(userId, true);
          break;
        case 'deactivate':
          await widget.adminService.toggleUserStatus(userId, false);
          break;
        case 'promote':
          await widget.adminService.promoteToAdmin(userId);
          break;
        case 'role_student':
          await widget.adminService.updateUserRole(userId, 'student');
          break;
        case 'role_professional':
          await widget.adminService.updateUserRole(userId, 'professional');
          break;
        case 'role_hoster':
          await widget.adminService.updateUserRole(userId, 'hoster');
          break;
        case 'role_owner':
          await widget.adminService.updateUserRole(userId, 'owner');
          break;
        case 'delete':
          await _showDeleteUserConfirmation(userId);
          return; // The confirmation dialog handles the actual call
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting community list...')),
    );
  }

  void _handleAddUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add User feature coming soon')),
    );
  }

  Future<void> _showDeleteUserConfirmation(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Permanently?'),
        content: const Text(
          'This action cannot be undone. All user profile data and authentication will be permanently removed.',
        ),
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

    if (confirmed == true) {
      try {
        await widget.adminService.deleteUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _formatRole(dynamic role) {
    final r = role?.toString().toLowerCase() ?? 'user';
    if (r == 'user' || r == 'student') return 'Student';
    if (r == 'professional') return 'Professional';
    if (r == 'hoster') return 'Hoster';
    if (r == 'owner') return 'Owner';
    if (r.isEmpty) return 'Student';
    return r[0].toUpperCase() + r.substring(1);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    }
    return date.toString();
  }

  Widget _buildPaginationFooter(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.isNarrow
                ? 'Showing $count members'
                : 'Showing 1 to $count of $count members',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            const PaginationBtn(icon: Icons.chevron_left),
            const PaginationBtn(label: '1', active: true),
            const PaginationBtn(icon: Icons.chevron_right),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAction(
    String label,
    IconData icon, {
    bool isOutline = false,
    bool hasDropdown = false,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOutline ? Colors.white : const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(10),
          border: isOutline ? Border.all(color: const Color(0xFFE2E8F0)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isOutline ? const Color(0xFF64748B) : Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isOutline ? const Color(0xFF1E293B) : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                color: isOutline ? const Color(0xFF64748B) : Colors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final String name;
  final String displayId;
  final String role;
  final String rawRole;
  final String phone;
  final String email;
  final String joined;
  final String status;
  final bool isActive;
  final VoidCallback onAction;
  final VoidCallback onTap;

  const _UserRow({
    required this.user,
    required this.name,
    required this.displayId,
    required this.role,
    required this.rawRole,
    required this.phone,
    required this.email,
    required this.joined,
    required this.status,
    required this.isActive,
    required this.onAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = Map<String, dynamic>.from(user['info'] as Map? ?? {});
    final location = info['city']?.toString() ?? info['location']?.toString() ?? 'Unknown';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
        ),
        child: Row(
          children: [
            // Selection Checkbox (Placeholder for now)
            SizedBox(
              width: 24,
              child: Checkbox(
                value: false,
                onChanged: (v) {},
                activeColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0x33FFFFFF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 16),

            // 1. User Info
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          displayId,
                          style: const TextStyle(color: Color(0x4DFFFFFF), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Role
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(color: _getRoleColor(role), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Contact
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phone, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                  Text(email, style: const TextStyle(fontSize: 11, color: Color(0x80FFFFFF))),
                ],
              ),
            ),

            // 4. Location
            Expanded(
              flex: 2,
              child: Text(
                location,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 5. Joined
            Expanded(
              flex: 2,
              child: Text(joined, style: const TextStyle(fontSize: 12, color: Color(0x80FFFFFF))),
            ),

            // 6. Status
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  StatusBadge(text: status, color: _getStatusColor(status)),
                ],
              ),
            ),

            // Actions
            SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF475569), size: 18),
                onPressed: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Student': return const Color(0xFF2563EB);
      case 'Hoster': return const Color(0xFFD97706);
      case 'Owner': return const Color(0xFF10B981);
      case 'Professional': return const Color(0xFF7C3AED);
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String s) {
    switch (s) {
      case 'Active':
      case 'Approved': return const Color(0xFF16A34A);
      case 'Inactive': return const Color(0xFF64748B);
      case 'Blocked':
      case 'Rejected': return const Color(0xFFDC2626);
      case 'Pending': return const Color(0xFFD97706);
      default: return Colors.grey;
    }
  }
}

class _HeaderLabel extends StatelessWidget {
  final String label;
  const _HeaderLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0x4DFFFFFF),
        letterSpacing: 1.0,
      ),
    );
  }
}

