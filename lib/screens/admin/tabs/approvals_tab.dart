import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';

class ApprovalsTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const ApprovalsTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends State<ApprovalsTab> with SingleTickerProviderStateMixin {
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
            title: 'Approvals',
            subtitle: 'Review and take action on pending requests',
            isNarrow: widget.isNarrow,
          ),
          const SizedBox(height: 32),
          _buildSummaryCards(),
          const SizedBox(height: 32),
          Container(
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
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'All (7)'),
                Tab(text: 'Hosters (3)'),
                Tab(text: 'Listings (2)'),
                Tab(text: 'Users (1)'),
                Tab(text: 'Other (1)'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SearchFilterRow(hint: 'Search approvals...', isNarrow: widget.isNarrow),
          const SizedBox(height: 24),
          _buildRequestsList(),
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
            count: '7',
            label: 'PENDING',
            bg: const Color(0xFFF1F5F9),
            color: const Color(0xFF475569),
            icon: Icons.hourglass_empty_rounded,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '3',
            label: 'HOSTERS',
            bg: const Color(0xFFFFF7ED),
            color: const Color(0xFFD97706),
            icon: Icons.business_center_rounded,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '24',
            label: 'APPROVED TODAY',
            bg: const Color(0xFFF0FDF4),
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
            isUp: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return Column(
      children: List.generate(3, (index) => _ApprovalCard(isNarrow: widget.isNarrow)),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final bool isNarrow;
  const _ApprovalCard({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sunrise Hostels',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'By John Doe',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isNarrow)
                  const StatusBadge(text: 'Pending', color: Colors.orange),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Spacer(),
                _ActionButton(
                  label: 'View Details',
                  bg: Colors.white,
                  text: Colors.black,
                  border: true,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  label: 'Approve',
                  bg: Colors.blue.shade600,
                  text: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;
  final bool border;

  const _ActionButton({
    required this.label,
    required this.bg,
    required this.text,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: border ? Border.all(color: Colors.grey.shade300) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
