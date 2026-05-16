import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
      child: Column(
        children: [
          TabHeader(
            title: 'Users',
            subtitle: 'Manage all users on the platform',
            isNarrow: widget.isNarrow,
            actions: [
              _buildHeaderAction('Export', Icons.file_download_outlined, isOutline: true),
              const SizedBox(width: 12),
              _buildHeaderAction('Add New User', Icons.add, hasDropdown: true),
            ],
          ),
          const SizedBox(height: 32),
          _buildSummaryCards(),
          const SizedBox(height: 32),
          _buildCategoryTabs(),
          const SizedBox(height: 24),
          _buildFilterRow(),
          const SizedBox(height: 24),
          if (!widget.isNarrow) _buildTableHeader(),
          const SizedBox(height: 12),
          _buildUsersList(),
          const SizedBox(height: 32),
          _buildPaginationFooter(),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(String label, IconData icon, {bool isOutline = false, bool hasDropdown = false}) {
    return Container(
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
    );
  }

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const SummaryCard(
            count: '2,842',
            label: 'Total Users',
            bg: Color(0xFFEFF6FF),
            color: Color(0xFF2563EB),
            icon: Icons.people_rounded,
            percentage: '12.6%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '1,523',
            label: 'Students',
            bg: Color(0xFFF0FDF4),
            color: Color(0xFF16A34A),
            icon: Icons.school_rounded,
            sub: '53.6% of total',
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '671',
            label: 'Professionals',
            bg: Color(0xFFF5F3FF),
            color: Color(0xFF7C3AED),
            icon: Icons.business_center_rounded,
            sub: '23.6% of total',
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '482',
            label: 'Hosters',
            bg: Color(0xFFFFF7ED),
            color: Color(0xFFD97706),
            icon: Icons.person_pin_rounded,
            sub: '16.9% of total',
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '166',
            label: 'Blocked/Inactive',
            bg: Color(0xFFFEF2F2),
            color: Color(0xFFDC2626),
            icon: Icons.block_rounded,
            sub: '5.9% of total',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
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
        tabs: const [
          Tab(text: 'All Users (2,842)'),
          Tab(text: 'Students (1,523)'),
          Tab(text: 'Professionals (671)'),
          Tab(text: 'Hosters (482)'),
          Tab(text: 'Inactive (166)'),
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

  Widget _buildUsersList() {
    return Column(
      children: [
        _UserCard(
          name: 'John Doe',
          id: 'USR00124',
          role: 'Student',
          phone: '+91 70254 77997',
          email: 'john.doe@email.com',
          joined: '18 May 2025, 10:30 AM',
          status: 'Active',
          isNarrow: widget.isNarrow,
        ),
        _UserCard(
          name: 'Sarah Ahmed',
          id: 'USR00123',
          role: 'Student',
          phone: '+91 79022 33445',
          email: 'sarah.ahmed@email.com',
          joined: '17 May 2025, 08:20 PM',
          status: 'Active',
          isNarrow: widget.isNarrow,
        ),
        _UserCard(
          name: 'Mike Johnson',
          id: 'USR00122',
          role: 'Hoster',
          phone: '+91 98470 12345',
          email: 'mike.johnson@greenpg.com',
          joined: '17 May 2025, 06:15 PM',
          status: 'Active',
          isNarrow: widget.isNarrow,
        ),
        _UserCard(
          name: 'Priya Sharma',
          id: 'USR00121',
          role: 'Professional',
          phone: '+91 96332 11223',
          email: 'priya.sharma@email.com',
          joined: '16 May 2025, 03:45 PM',
          status: 'Active',
          isNarrow: widget.isNarrow,
        ),
        _UserCard(
          name: 'Rahul Patel',
          id: 'USR00120',
          role: 'Professional',
          phone: '+91 81234 56789',
          email: 'rahul.patel@gmail.com',
          joined: '16 May 2025, 11:20 AM',
          status: 'Inactive',
          isNarrow: widget.isNarrow,
        ),
      ],
    );
  }

  Widget _buildPaginationFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.isNarrow ? '1-10 of 2,842' : 'Showing 1 to 10 of 2,842 users',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            const PaginationBtn(icon: Icons.chevron_left),
            const PaginationBtn(label: '1', active: true),
            if (!widget.isNarrow) ...[
              const PaginationBtn(label: '2'),
              const PaginationBtn(label: '3'),
              const PaginationBtn(label: '4'),
              const PaginationBtn(label: '5'),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...', style: TextStyle(color: Colors.grey))),
              const PaginationBtn(label: '285'),
            ],
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
}

class _UserCard extends StatelessWidget {
  final String name;
  final String id;
  final String role;
  final String phone;
  final String email;
  final String joined;
  final String status;
  final bool isNarrow;

  const _UserCard({
    required this.name,
    required this.id,
    required this.role,
    required this.phone,
    required this.email,
    required this.joined,
    required this.status,
    required this.isNarrow,
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
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(Icons.person, color: Colors.grey),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 12),
                        ],
                      ),
                      Text(id, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(joined.split(',')[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  Text(joined.split(',')[1].trim(), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
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
          const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
        ],
      ),
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
