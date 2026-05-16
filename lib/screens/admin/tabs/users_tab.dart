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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            subtitle: 'Manage and moderate all platform users',
            isNarrow: widget.isNarrow,
            actions: [
              if (!widget.isNarrow) ...[
                _buildHeaderAction('Export', Icons.file_download_outlined, isOutline: true),
                const SizedBox(width: 12),
              ],
              _buildHeaderAction('Add New User', Icons.add, hasDropdown: true),
            ],
          ),
          const SizedBox(height: 32),
          _buildSummaryCards(),
          const SizedBox(height: 32),
          _buildCategoryTabs(),
          const SizedBox(height: 24),
          SearchFilterRow(hint: 'Search by name, email or phone...', isNarrow: widget.isNarrow),
          const SizedBox(height: 24),
          if (!widget.isNarrow) _buildTableHeader(),
          const SizedBox(height: 12),
          _buildUsersList(),
          const SizedBox(height: 32),
          _buildPagination(),
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
          if (hasDropdown && !widget.isNarrow) ...[
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
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
          SummaryCard(
            count: '2,842',
            label: 'TOTAL USERS',
            bg: const Color(0xFFEFF6FF),
            color: const Color(0xFF2563EB),
            icon: Icons.people_rounded,
            percentage: '12.6%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '1,523',
            label: 'STUDENTS',
            bg: const Color(0xFFF0FDF4),
            color: const Color(0xFF16A34A),
            icon: Icons.school_rounded,
            sub: '53.6% of total',
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '671',
            label: 'PROFESSIONALS',
            bg: const Color(0xFFF5F3FF),
            color: const Color(0xFF7C3AED),
            icon: Icons.business_center_rounded,
            sub: '23.6% of total',
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
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
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

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 3, child: _tableLabel('USER')),
          Expanded(flex: 2, child: _tableLabel('ROLE')),
          Expanded(flex: 3, child: _tableLabel('CONTACT')),
          Expanded(flex: 2, child: _tableLabel('STATUS')),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _tableLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildUsersList() {
    return Column(
      children: List.generate(5, (index) => _UserCard(isNarrow: widget.isNarrow, index: index)),
    );
  }

  Widget _buildPagination() {
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
            if (!widget.isNarrow) const PaginationBtn(label: '2'),
            const Text('...', style: TextStyle(color: Colors.grey)),
            const PaginationBtn(label: '285'),
            const PaginationBtn(icon: Icons.chevron_right),
          ],
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final bool isNarrow;
  final int index;
  const _UserCard({required this.isNarrow, required this.index});

  @override
  Widget build(BuildContext context) {
    final names = ['John Doe', 'Sarah Ahmed', 'Mike Johnson', 'Priya Sharma', 'Rahul Patel'];
    final roles = ['Student', 'Student', 'Hoster', 'Professional', 'Professional'];
    final status = ['Active', 'Active', 'Active', 'Active', 'Inactive'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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
                                names[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 12),
                          ],
                        ),
                        Text(
                          'USR00${124 - index}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isNarrow)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(roles[index]).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roles[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _getRoleColor(roles[index]),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (!isNarrow)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '+91 70254 77997',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'user\${index}@email.com',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            Expanded(
              flex: isNarrow ? 1 : 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StatusBadge(
                    text: status[index],
                    color: status[index] == 'Active' ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
          ],
        ),
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
}
