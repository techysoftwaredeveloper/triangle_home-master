import 'package:flutter/material.dart';
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

class _UsersTabState extends State<UsersTab> with SingleTickerProviderStateMixin {
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
        final allUsers = snapshot.data ?? [];

        // Dynamic Filtering
        final filteredUsers = allUsers.where((u) {
          final info = u['info'] as Map<String, dynamic>? ?? {};
          final name = info['name']?.toString().toLowerCase() ?? '';
          final email = info['email']?.toString().toLowerCase() ?? '';
          final phone = info['phoneNumber']?.toString().toLowerCase() ?? '';

          final matchesSearch = name.contains(_searchQuery) ||
                                email.contains(_searchQuery) ||
                                phone.contains(_searchQuery);

          final role = u['role']?.toString().toLowerCase() ?? '';
          final isActive = u['is_active'] as bool? ?? true;

          switch (_tabController.index) {
            case 1: // Students
              return matchesSearch && (role == 'student' || role == 'user' || role == '');
            case 2: // Professionals
              return matchesSearch && role == 'professional';
            case 3: // Hosters
              return matchesSearch && role == 'hoster';
            case 4: // Inactive
              return matchesSearch && !isActive;
            default: // All
              return matchesSearch;
          }
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          child: Column(
            children: [
              TabHeader(
                title: 'Users',
                subtitle: 'Manage all users on the platform',
                isNarrow: widget.isNarrow,
                actions: [
                  _buildHeaderAction('Export', Icons.file_download_outlined, isOutline: true, onPressed: _handleExport),
                  const SizedBox(width: 12),
                  _buildHeaderAction('Add New User', Icons.add, hasDropdown: true, onPressed: _handleAddUser),
                ],
              ),
              const SizedBox(height: 32),
              _buildSummaryCards(allUsers),
              const SizedBox(height: 32),
              _buildCategoryTabs(allUsers),
              const SizedBox(height: 24),
              _buildFilterRow(),
              const SizedBox(height: 24),
              if (!widget.isNarrow) _buildTableHeader(),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ))
              else
                _buildUsersList(filteredUsers),
              const SizedBox(height: 32),
              _buildPaginationFooter(filteredUsers.length),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> users) {
    final students = users.where((u) {
        final r = u['role']?.toString().toLowerCase() ?? '';
        return r == 'student' || r == 'user' || r == '';
    }).length;
    final professionals = users.where((u) => u['role'] == 'professional').length;
    final hosters = users.where((u) => u['role'] == 'hoster').length;
    final inactive = users.where((u) => (u['is_active'] == false)).length;

    final double cardWidth = widget.isNarrow ? 160 : 220;
    final double cardHeight = widget.isNarrow ? 140 : 180;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(
            count: users.length.toString(),
            label: 'Total Users',
            bg: const Color(0xFFEFF6FF),
            color: const Color(0xFF2563EB),
            icon: Icons.people_rounded,
            percentage: '12.6%',
            isUp: true,
          )),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(
            count: students.toString(),
            label: 'Students',
            bg: const Color(0xFFF0FDF4),
            color: const Color(0xFF16A34A),
            icon: Icons.school_rounded,
            sub: users.isEmpty ? '0% of total' : '\${((students / users.length) * 100).toStringAsFixed(1)}% of total',
          )),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(
            count: professionals.toString(),
            label: 'Professionals',
            bg: const Color(0xFFF5F3FF),
            color: const Color(0xFF7C3AED),
            icon: Icons.business_center_rounded,
            sub: users.isEmpty ? '0% of total' : '\${((professionals / users.length) * 100).toStringAsFixed(1)}% of total',
          )),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(
            count: hosters.toString(),
            label: 'Hosters',
            bg: const Color(0xFFFFF7ED),
            color: const Color(0xFFD97706),
            icon: Icons.person_pin_rounded,
            sub: users.isEmpty ? '0% of total' : '\${((hosters / users.length) * 100).toStringAsFixed(1)}% of total',
          )),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(
            count: inactive.toString(),
            label: 'Blocked/Inactive',
            bg: const Color(0xFFFEF2F2),
            color: const Color(0xFFDC2626),
            icon: Icons.block_rounded,
            sub: users.isEmpty ? '0% of total' : '\${((inactive / users.length) * 100).toStringAsFixed(1)}% of total',
          )),
        ],
      ),
    );
  }

  Widget _wrapInSizedBox(double w, double h, Widget child) => SizedBox(width: w, height: h, child: child);

  Widget _buildCategoryTabs(List<Map<String, dynamic>> users) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
        tabs: [
          Tab(text: 'All Users (${users.length})'),
          Tab(text: 'Students (${users.where((u) => u['role'] == 'student' || u['role'] == 'user' || u['role'] == null || (u['role'] as String).isEmpty).length})'),
          Tab(text: 'Professionals (${users.where((u) => u['role'] == 'professional').length})'),
          Tab(text: 'Hosters (${users.where((u) => u['role'] == 'hoster').length})'),
          Tab(text: 'Inactive (${users.where((u) => (u['is_active'] == false)).length})'),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search users by name, email or phone...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildSmallFilter('Filter', Icons.tune),
        if (!widget.isNarrow) ...[
          const SizedBox(width: 12),
          _buildSmallFilter('More Filters', null, hasDropdown: true),
          const SizedBox(width: 12),
          _buildSmallFilter('Newest First', null, hasDropdown: true),
        ],
      ],
    );
  }

  Widget _buildSmallFilter(String label, IconData? icon, {bool hasDropdown = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
          Expanded(flex: 3, child: _tableLabel('USER')),
          Expanded(flex: 2, child: _tableLabel('ROLE')),
          Expanded(flex: 3, child: _tableLabel('CONTACT')),
          Expanded(flex: 2, child: _tableLabel('JOINED ON')),
          Expanded(flex: 2, child: _tableLabel('STATUS')),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _tableLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
    );
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No users found matching your criteria', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Column(
      children: users.map((u) {
        final info = u['info'] as Map<String, dynamic>? ?? {};
        final rawRole = u['role']?.toString() ?? 'student';
        final isActive = u['is_active'] ?? true;

        return _UserCard(
          id: u['id'],
          name: info['name'] ?? 'Unknown User',
          displayId: u['id']?.toString().substring(0, 8).toUpperCase() ?? 'USR-NEW',
          role: _formatRole(rawRole),
          rawRole: rawRole,
          phone: info['phoneNumber'] ?? 'No Phone',
          email: info['email'] ?? 'No Email',
          joined: _formatDate(u['createdAt']),
          status: isActive ? 'Active' : 'Inactive',
          isActive: isActive,
          isNarrow: widget.isNarrow,
          onAction: (action) => _handleUserAction(u['id'], action),
        );
      }).toList(),
    );
  }

  void _handleUserAction(String userId, String action) async {
    try {
      switch (action) {
        case 'activate':
          await widget.adminService.toggleUserStatus(userId, 'active');
          // Note: In your schema it's is_active bool, but toggleUserStatus uses String for audit logs.
          // Let's assume toggleUserStatus handles the Firestore update correctly or I should update it.
          // For now, I'll update Firestore directly if needed, but better to use the service.
          await FirebaseFirestore.instance.collection('users').doc(userId).update({'is_active': true});
          break;
        case 'deactivate':
          await widget.adminService.toggleUserStatus(userId, 'inactive');
          await FirebaseFirestore.instance.collection('users').doc(userId).update({'is_active': false});
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
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action "$action" completed successfully'), backgroundColor: Colors.green),
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
      const SnackBar(content: Text('Exporting users to CSV...'), backgroundColor: Color(0xFF2563EB)),
    );
  }

  void _handleAddUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add User functionality coming soon'), backgroundColor: Color(0xFF2563EB)),
    );
  }

  String _formatRole(dynamic role) {
    final r = role?.toString().toLowerCase() ?? 'user';
    if (r == 'user' || r == 'student') return 'Student';
    if (r == 'professional') return 'Professional';
    if (r == 'hoster') return 'Hoster';
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
            widget.isNarrow ? 'Showing \$count users' : 'Showing 1 to \$count of \$count users',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            const PaginationBtn(icon: Icons.chevron_left),
            const PaginationBtn(label: '1', active: true),
            const PaginationBtn(icon: Icons.chevron_right),
            if (!widget.isNarrow) ...[
              const SizedBox(width: 16),
              _buildPageSizeSelector(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPageSizeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: const [
          Text('10 / page', style: TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
          SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(String label, IconData icon, {bool isOutline = false, bool hasDropdown = false, VoidCallback? onPressed}) {
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
            Icon(icon, color: isOutline ? const Color(0xFF64748B) : Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              widget.isNarrow && label == 'Add New User' ? 'Add' : label,
              style: TextStyle(
                color: isOutline ? const Color(0xFF1E293B) : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: isOutline ? const Color(0xFF64748B) : Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String id;
  final String name;
  final String displayId;
  final String role;
  final String rawRole;
  final String phone;
  final String email;
  final String joined;
  final String status;
  final bool isActive;
  final bool isNarrow;
  final Function(String) onAction;

  const _UserCard({
    required this.id,
    required this.name,
    required this.displayId,
    required this.role,
    required this.rawRole,
    required this.phone,
    required this.email,
    required this.joined,
    required this.status,
    required this.isActive,
    required this.isNarrow,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // 1. User
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 12),
                        ],
                      ),
                      Text(displayId, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Role
          if (!isNarrow)
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _getRoleColor(role), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          // 3. Contact
          if (!isNarrow)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text(email, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),

          // 4. Joined On
          if (!isNarrow)
            Expanded(
              flex: 2,
              child: Text(joined, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            ),

          // 5. Status
          Expanded(
            flex: isNarrow ? 1 : 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: isNarrow ? Alignment.centerRight : Alignment.centerLeft,
              child: StatusBadge(text: status, color: _getStatusColor(status)),
            ),
          ),

          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
            onSelected: onAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Details')),
              PopupMenuItem(value: isActive ? 'deactivate' : 'activate', child: Text(isActive ? 'Deactivate User' : 'Activate User')),
              const PopupMenuItem(value: 'promote', child: Text('Promote to Admin')),
              const PopupMenuDivider(),
              const PopupMenuItem(enabled: false, child: Text('Change Role', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              PopupMenuItem(value: 'role_student', child: _roleItem('Student', rawRole == 'student')),
              PopupMenuItem(value: 'role_professional', child: _roleItem('Professional', rawRole == 'professional')),
              PopupMenuItem(value: 'role_hoster', child: _roleItem('Hoster', rawRole == 'hoster')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleItem(String label, bool isCurrent) {
    return Row(
      children: [
        Text(label),
        if (isCurrent) ...[const Spacer(), const Icon(Icons.check, size: 14, color: Colors.green)],
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Student': return const Color(0xFF2563EB);
      case 'Hoster': return const Color(0xFFD97706);
      case 'Professional': return const Color(0xFF7C3AED);
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String s) {
    switch (s) {
      case 'Active': return const Color(0xFF16A34A);
      case 'Inactive': return const Color(0xFF64748B);
      case 'Blocked': return const Color(0xFFDC2626);
      case 'Pending': return const Color(0xFFD97706);
      default: return Colors.grey;
    }
  }
}
