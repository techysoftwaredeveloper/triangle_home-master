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
            actions: [
              _buildFilterBtn(),
            ],
          ),
          const SizedBox(height: 32),
          _buildSummaryCards(),
          const SizedBox(height: 32),
          _buildCategoryTabs(),
          const SizedBox(height: 24),
          _buildSearchAndSort(),
          const SizedBox(height: 24),
          _buildRequestsList(),
          const SizedBox(height: 32),
          _buildFooterHelpBar(),
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
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
            label: 'Total Pending',
            bg: const Color(0xFFF1F5F9),
            color: const Color(0xFF475569),
            icon: Icons.hourglass_empty_rounded,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '3',
            label: 'Hoster Requests',
            bg: const Color(0xFFFFF7ED),
            color: const Color(0xFFD97706),
            icon: Icons.business_center_rounded,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '2',
            label: 'Property Listings',
            bg: const Color(0xFFEFF6FF),
            color: const Color(0xFF2563EB),
            icon: Icons.home_work_rounded,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '1',
            label: 'User Verifications',
            bg: const Color(0xFFF0FDF4),
            color: const Color(0xFF16A34A),
            icon: Icons.person_search_rounded,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '1',
            label: 'Other Requests',
            bg: const Color(0xFFF5F3FF),
            color: const Color(0xFF7C3AED),
            icon: Icons.description_rounded,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '24',
            label: 'Approved Today',
            bg: const Color(0xFFF0FDF4),
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
            isUp: true,
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
          Tab(text: 'All (7)'),
          Tab(text: 'Hoster Requests (3)'),
          Tab(text: 'Property Listings (2)'),
          Tab(text: 'User Verifications (1)'),
          Tab(text: 'Other (1)'),
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

  Widget _buildRequestsList() {
    return Column(
      children: [
        _ApprovalRequestCard(
          type: 'Hoster Request',
          title: 'Sunrise Hostels',
          requestedBy: 'John Doe',
          isVerified: true,
          phone: '+91 70254 77997',
          email: 'john@gmail.com',
          location: 'Kozhikode, Kerala',
          tags: ['PG Hostel', '15 Properties'],
          date: '18 May 2025, 10:30 AM',
          docs: '3/3 Uploaded',
          icon: Icons.business_center_rounded,
          iconColor: const Color(0xFFD97706),
          isNarrow: widget.isNarrow,
        ),
        _ApprovalRequestCard(
          type: 'Property Listing',
          title: 'Green Valley PG',
          requestedBy: 'John Doe',
          isVerified: true,
          location: 'Kozhikode, Kerala',
          tags: ['PG Accommodation', '6 Rooms'],
          date: '18 May 2025, 09:45 AM',
          docs: '4/4 Uploaded',
          icon: Icons.home_work_rounded,
          iconColor: const Color(0xFF2563EB),
          isNarrow: widget.isNarrow,
        ),
        _ApprovalRequestCard(
          type: 'User Verification',
          title: 'Sarah Ahmed',
          requestedBy: 'Sarah Ahmed',
          isVerified: true,
          phone: '+91 79022 33445',
          email: 'sarah.ahmed@example.com',
          verificationType: 'Identity Verification',
          date: '17 May 2025, 08:20 PM',
          icon: Icons.person_search_rounded,
          iconColor: const Color(0xFF16A34A),
          isNarrow: widget.isNarrow,
        ),
        _ApprovalRequestCard(
          type: 'Property Listing',
          title: 'Comfort Living PG',
          requestedBy: 'Mike Johnson',
          isVerified: true,
          location: 'Thrissur, Kerala',
          tags: ['PG Accommodation', '8 Rooms'],
          date: '17 May 2025, 06:15 PM',
          docs: '3/4 Uploaded',
          icon: Icons.home_work_rounded,
          iconColor: const Color(0xFF2563EB),
          isNarrow: widget.isNarrow,
        ),
        _ApprovalRequestCard(
          type: 'Other Request',
          title: 'Document Update',
          requestedBy: 'Lily Thomas',
          isVerified: true,
          email: 'lily@sunrisehostels.com',
          requestType: 'Document Update',
          date: '17 May 2025, 03:40 PM',
          icon: Icons.description_rounded,
          iconColor: const Color(0xFF7C3AED),
          isNarrow: widget.isNarrow,
        ),
      ],
    );
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
          ),
        ],
      ),
    );
  }
}

class _ApprovalRequestCard extends StatelessWidget {
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
  final String? verificationType;
  final String? requestType;
  final IconData icon;
  final Color iconColor;
  final bool isNarrow;

  const _ApprovalRequestCard({
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
    this.verificationType,
    this.requestType,
    required this.icon,
    required this.iconColor,
    required this.isNarrow,
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
                    Text(
                      verificationType != null ? 'Verification Type' : (requestType != null ? 'Request Type' : 'Requested on'),
                      style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      verificationType ?? (requestType ?? date),
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RequestActionButton(
                  label: 'Approve',
                  bg: const Color(0xFF2563EB),
                  text: Colors.white,
                  hasDropdown: !isNarrow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RequestActionButton(
                  label: 'Reject',
                  bg: const Color(0xFFFEE2E2),
                  text: const Color(0xFFDC2626),
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

  const _RequestActionButton({
    required this.label,
    required this.bg,
    required this.text,
    this.border = false,
    this.hasDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: border ? Border.all(color: const Color(0xFFE2E8F0)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: text),
          ],
        ],
      ),
    );
  }
}
