import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getPendingApprovalsStream(),
      builder: (context, snapshot) {
        final allItems = snapshot.data ?? [];

        // Filter based on tab
        final filteredItems = allItems.where((item) {
          switch (_tabController.index) {
            case 1: return item['type'] == 'hoster';
            case 2: return item['type'] == 'property';
            default: return true;
          }
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          child: Column(
            children: [
              TabHeader(
                title: 'Approvals',
                subtitle: 'Review and take action on pending requests',
                isNarrow: widget.isNarrow,
                actions: [
                  _buildFilterBtn(),
                ],
              ),
              const SizedBox(height: 32),
              _buildSummaryCards(allItems),
              const SizedBox(height: 32),
              _buildCategoryTabs(allItems),
              const SizedBox(height: 24),
              _buildSearchAndSort(),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting && allItems.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ))
              else if (filteredItems.isEmpty)
                _buildEmptyState()
              else
                _buildRequestsList(filteredItems),
              const SizedBox(height: 32),
              _buildFooterHelpBar(),
            ],
          ),
        );
      }
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rtl_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending approval requests found.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: const [
          Icon(Icons.tune_rounded, size: 18, color: Color(0xFF64748B)),
          SizedBox(width: 8),
          Text(
            'Filter',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> items) {
    final hosterCount = items.where((i) => i['type'] == 'hoster').length;
    final propertyCount = items.where((i) => i['type'] == 'property').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          SummaryCard(
            count: items.length.toString(),
            label: 'Total Pending',
            bg: const Color(0xFFF1F5F9),
            color: const Color(0xFF475569),
            icon: Icons.hourglass_empty_rounded,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: hosterCount.toString(),
            label: 'Hoster Requests',
            bg: const Color(0xFFFFF7ED),
            color: const Color(0xFFD97706),
            icon: Icons.business_center_rounded,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: propertyCount.toString(),
            label: 'Property Listings',
            bg: const Color(0xFFEFF6FF),
            color: const Color(0xFF2563EB),
            icon: Icons.home_work_rounded,
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '0',
            label: 'User Verifications',
            bg: Color(0xFFF0FDF4),
            color: Color(0xFF16A34A),
            icon: Icons.person_search_rounded,
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '24',
            label: 'Approved Today',
            bg: Color(0xFFF0FDF4),
            color: Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
            isUp: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> items) {
    final hosterCount = items.where((i) => i['type'] == 'hoster').length;
    final propertyCount = items.where((i) => i['type'] == 'property').length;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        onTap: (index) => setState(() {}),
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
        tabs: [
          Tab(text: 'All (${items.length})'),
          Tab(text: 'Hoster Requests ($hosterCount)'),
          Tab(text: 'Property Listings ($propertyCount)'),
          const Tab(text: 'User Verifications (0)'),
          const Tab(text: 'Other (0)'),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: Colors.grey, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search approvals...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13),
                    ),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: const [
                Text(
                  'Newest First',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRequestsList(List<Map<String, dynamic>> items) {
    return Column(
      children: items.map((item) {
        if (item['type'] == 'hoster') {
          final info = item['info'] as Map<String, dynamic>? ?? {};
          return _ApprovalRequestCard(
            id: item['id'],
            type: 'Hoster Request',
            title: info['name'] ?? 'New Hoster',
            requestedBy: info['name'] ?? 'Unknown',
            isVerified: item['isVerified'] ?? false,
            phone: info['phoneNumber'],
            email: info['email'],
            location: item['location'],
            tags: const ['Pending Verification'],
            date: _formatDate(item['createdAt']),
            docs: 'Documents Attached',
            icon: Icons.business_center_rounded,
            iconColor: const Color(0xFFD97706),
            isNarrow: widget.isNarrow,
            onApprove: () => _handleApprove(item['id'], 'hoster'),
            onReject: () => _handleReject(item['id'], 'hoster'),
          );
        } else {
          return _ApprovalRequestCard(
            id: item['id'],
            type: 'Property Listing',
            title: item['name'] ?? 'New Property',
            requestedBy: item['hosterName'] ?? 'Unknown',
            isVerified: true,
            location: item['location'] ?? 'Location N/A',
            tags: [item['category'] ?? 'Property', '${item['rooms'] ?? 0} Rooms'],
            date: _formatDate(item['createdAt']),
            docs: 'Photos Uploaded',
            icon: Icons.home_work_rounded,
            iconColor: const Color(0xFF2563EB),
            isNarrow: widget.isNarrow,
            onApprove: () => _handleApprove(item['id'], 'property'),
            onReject: () => _handleReject(item['id'], 'property'),
          );
        }
      }).toList(),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    }
    return date.toString();
  }

  Future<void> _handleApprove(String id, String type) async {
    try {
      await widget.adminService.approveItem(id, type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully approved \$type'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(String id, String type) async {
    try {
      await widget.adminService.rejectItem(id, type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully rejected \$type'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildFooterHelpBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Need help reviewing approvals?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Check our approval guidelines and documentation.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _RequestActionButton(
            label: 'View Guidelines',
            bg: Colors.white,
            text: const Color(0xFF1E293B),
            border: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ApprovalRequestCard extends StatelessWidget {
  final String id;
  final String type;
  final String title;
  final String requestedBy;
  final bool isVerified;
  final String? phone;
  final String? email;
  final String? location;
  final List<String> tags;
  final String date;
  final String? docs;
  final IconData icon;
  final Color iconColor;
  final bool isNarrow;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalRequestCard({
    required this.id,
    required this.type,
    required this.title,
    required this.requestedBy,
    required this.isVerified,
    this.phone,
    this.email,
    this.location,
    this.tags = const [],
    required this.date,
    this.docs,
    required this.icon,
    required this.iconColor,
    required this.isNarrow,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(),
                const SizedBox(width: 20),
                Expanded(child: _buildDetails()),
                if (!isNarrow) const StatusBadge(text: 'Pending', color: Colors.orange),
              ],
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
        ),
        Positioned(
          left: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              const Text(
                'Requested by: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Text(
                requestedBy,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              if (isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, size: 14, color: Color(0xFF3B82F6)),
              ],
            ],
          ),
        ),
        if (phone != null || email != null) ...[
          const SizedBox(height: 4),
          Text(
            '${phone ?? ''}  •  ${email ?? ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
        if (location != null) ...[
          const SizedBox(height: 4),
          Text(
            location!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
        const SizedBox(height: 12),
        if (tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requested on',
                      style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              if (docs != null) ...[
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Documents',
                      style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      docs!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RequestActionButton(
                  label: isNarrow ? 'Details' : 'View Details',
                  bg: Colors.white,
                  text: const Color(0xFF1E293B),
                  border: true,
                  onPressed: () {}, // TODO: Detail view
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RequestActionButton(
                  label: 'Approve',
                  bg: const Color(0xFF2563EB),
                  text: Colors.white,
                  hasDropdown: !isNarrow,
                  onPressed: onApprove,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RequestActionButton(
                  label: 'Reject',
                  bg: const Color(0xFFFEE2E2),
                  text: const Color(0xFFDC2626),
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestActionButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;
  final bool border;
  final bool hasDropdown;
  final VoidCallback onPressed;

  const _RequestActionButton({
    required this.label,
    required this.bg,
    required this.text,
    this.border = false,
    this.hasDropdown = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border ? Border.all(color: const Color(0xFFE2E8F0)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 14, color: text),
            ],
          ],
        ),
      ),
    );
  }
}

