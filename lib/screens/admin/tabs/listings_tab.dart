import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ListingsTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const ListingsTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<ListingsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getPropertiesStream(),
      builder: (context, snapshot) {
        final allProperties = snapshot.data ?? [];
        
        final List<Map<String, dynamic>> displayListings = List.from(allProperties);
        if (displayListings.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
           _addMockListings(displayListings);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSummaryRow(displayListings),
              const SizedBox(height: 64),
              _buildCategoryTabs(displayListings),
              const SizedBox(height: 24),
              _buildFilterRow(),
              const SizedBox(height: 24),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: widget.isNarrow ? 0 : 1000,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.isNarrow) _buildTableHeader(),
                      const SizedBox(height: 12),
                      _buildListingsList(displayListings),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              _buildPaginationFooter(displayListings.length),
              const SizedBox(height: 40),
            ],
          ),
        );
      }
    );
  }

  void _addMockListings(List<Map<String, dynamic>> items) {
    items.addAll([
      {
        'id': 'L001',
        'name': 'Sunrise Hostels',
        'category': 'PG Hostel',
        'location': 'Kozhikode, Kerala',
        'rooms': 15,
        'sharing': '3 Sharing',
        'hosterName': 'John Doe',
        'hosterId': 'HST001',
        'hosterPhone': '+91 70254 77997',
        'views': 1245,
        'bookings': 32,
        'occupancy': 86,
        'status': 'active',
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'L002',
        'name': 'Green Valley PG',
        'category': 'PG Accommodation',
        'location': 'Kozhikode, Kerala',
        'rooms': 20,
        'sharing': '2 & 3 Sharing',
        'hosterName': 'Mike Johnson',
        'hosterId': 'HST002',
        'hosterPhone': '+91 98470 12345',
        'views': 982,
        'bookings': 28,
        'occupancy': 78,
        'status': 'active',
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'L003',
        'name': 'Comfort Living PG',
        'category': 'PG Accommodation',
        'location': 'Thrissur, Kerala',
        'rooms': 12,
        'sharing': '3 Sharing',
        'hosterName': 'Aman Singh',
        'hosterId': 'HST003',
        'hosterPhone': '+91 88910 56789',
        'views': 645,
        'bookings': 14,
        'occupancy': 65,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'L004',
        'name': 'Happy Stay Pg',
        'category': 'PG Hostel',
        'location': 'Malappuram, Kerala',
        'rooms': 18,
        'sharing': '2 & 3 Sharing',
        'hosterName': 'Rahul Sharma',
        'hosterId': 'HST004',
        'hosterPhone': '+91 96332 11223',
        'views': 1102,
        'bookings': 26,
        'occupancy': 72,
        'status': 'active',
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'L005',
        'name': 'City Corner Hostel',
        'category': 'Hostel',
        'location': 'Calicut, Kerala',
        'rooms': 25,
        'sharing': '4 Sharing',
        'hosterName': 'Neha Patel',
        'hosterId': 'HST005',
        'hosterPhone': '+91 81234 56789',
        'views': 523,
        'bookings': 8,
        'occupancy': 42,
        'status': 'inactive',
        'createdAt': Timestamp.now(),
      },
    ]);
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Listings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Outfit'),
            ),
            SizedBox(height: 4),
            Text(
              'Manage all properties listed on the platform',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontFamily: 'Outfit'),
            ),
          ],
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: const [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Add New Listing',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            height: 44,
            width: 1,
            color: Colors.white24,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<Map<String, dynamic>> items) {
    final active = items.where((i) => i['status'] == 'active').length;
    final review = items.where((i) => i['status'] == 'pending').length;
    final inactive = items.where((i) => i['status'] == 'inactive' || i['status'] == 'rejected').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _ListingStatCard(
            count: items.length.toString(),
            label: 'Total Listings',
            icon: Icons.business_outlined,
            iconColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
            trend: '12.5%',
            isTrendUp: true,
          ),
          const SizedBox(width: 16),
          _ListingStatCard(
            count: active.toString(),
            label: 'Active Listings',
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            sub: '83.3% of total',
          ),
          const SizedBox(width: 16),
          _ListingStatCard(
            count: review.toString(),
            label: 'Under Review',
            icon: Icons.hourglass_top_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFF7ED),
            sub: '6.3% of total',
          ),
          const SizedBox(width: 16),
          _ListingStatCard(
            count: inactive.toString(),
            label: 'Inactive/Rejected',
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
            sub: '10.4% of total',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> items) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        onTap: (index) => setState(() {}),
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit'),
        tabs: const [
          Tab(text: 'All Listings (1,076)'),
          Tab(text: 'Active (896)'),
          Tab(text: 'Under Review (68)'),
          Tab(text: 'Inactive (112)'),
          Tab(text: 'Rejected (48)'),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by property name, hoster or location...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _FilterActionBtn(label: 'Filter', icon: Icons.tune_rounded),
        const SizedBox(width: 16),
        _FilterActionBtn(label: 'More Filters', hasDropdown: true),
        const SizedBox(width: 16),
        _FilterActionBtn(label: 'Newest First', hasDropdown: true),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerLabel('PROPERTY')),
          Expanded(flex: 2, child: _headerLabel('HOSTER & DETAILS')),
          Expanded(flex: 2, child: _headerLabel('STATS')),
          Expanded(flex: 2, child: _headerLabel('STATUS')),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _headerLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
    );
  }

  Widget _buildListingsList(List<Map<String, dynamic>> items) {
    return Column(
      children: items.map<Widget>((item) => _ListingTableCard(
        item: item, 
        isNarrow: widget.isNarrow,
        onTap: () {
          // TODO: Open detailed view
        },
        onAction: (action) => _handleListingAction(item['id'], action),
      )).toList(),
    );
  }

  void _handleListingAction(String id, String action) async {
    try {
      if (action == 'approve') {
        await widget.adminService.approveItem(id, 'property');
      } else if (action == 'reject') {
        await widget.adminService.rejectItem(id, 'property');
      } else if (action == 'delete') {
        await widget.adminService.deleteListing(id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listing $action successfully'), backgroundColor: Colors.green),
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

  Widget _buildPaginationFooter(int count) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 650;
        
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    isCompact ? '1-10 of 1,076' : 'Showing 1 to 10 of 1,076 listings',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isCompact) _buildPageSizeSelector(),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PageNavBtn(icon: Icons.chevron_left),
                  _PageNavBtn(label: '1', active: true),
                  _PageNavBtn(label: '2'),
                  if (!isCompact) ...[
                    _PageNavBtn(label: '3'),
                    _PageNavBtn(label: '4'),
                    _PageNavBtn(label: '5'),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('...', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                  _PageNavBtn(label: '108'),
                  _PageNavBtn(icon: Icons.chevron_right),
                  if (isCompact) ...[
                    const SizedBox(width: 16),
                    _buildPageSizeSelector(),
                  ],
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPageSizeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('10 / page', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
          SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}

class _ListingStatCard extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String? trend;
  final bool? isTrendUp;
  final String? sub;

  const _ListingStatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.trend,
    this.isTrendUp,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            count,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          if (trend != null)
            Row(
              children: [
                Icon(isTrendUp == true ? Icons.arrow_upward : Icons.arrow_downward, color: const Color(0xFF10B981), size: 14),
                const SizedBox(width: 4),
                Text(trend!, style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Text('this month', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            )
          else if (sub != null)
            Text(sub!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FilterActionBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool hasDropdown;

  const _FilterActionBtn({required this.label, this.icon, this.hasDropdown = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: const Color(0xFF64748B)), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          if (hasDropdown) ...[
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
          ],
        ],
      ),
    );
  }
}

class _ListingTableCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isNarrow;
  final VoidCallback onTap;
  final Function(String) onAction;

  const _ListingTableCard({
    required this.item,
    required this.isNarrow,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString().toLowerCase() ?? 'pending';
    final String statusLabel;
    final Color statusColor;
    final Color statusBg;

    switch (status) {
      case 'active':
        statusLabel = 'Active';
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFECFDF5);
        break;
      case 'pending':
        statusLabel = 'Under Review';
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFFF7ED);
        break;
      case 'rejected':
        statusLabel = 'Rejected';
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFFEF2F2);
        break;
      default:
        statusLabel = 'Inactive';
        statusColor = const Color(0xFF64748B);
        statusBg = const Color(0xFFF1F5F9);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        width: isNarrow ? MediaQuery.of(context).size.width - 32 : 1000,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['propertyImage'] ?? 'https://via.placeholder.com/60',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.home_work_outlined, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item['name'] ?? 'Untitled',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                          ],
                        ),
                        Text(item['category'] ?? 'Property', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item['location'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['rooms'] ?? 0} Rooms  •  ${item['sharing'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF3E8FF),
                    child: Text(
                      (item['hosterName'] ?? 'U')[0],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['hosterName'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text('Verified Hoster', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(item['hosterPhone'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text('Hoster ID: ${item['hosterId'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statRow('Views', (item['views'] ?? 0).toString()),
                  _statRow('Bookings', (item['bookings'] ?? 0).toString()),
                  _statRow('Occupancy', '${item['occupancy'] ?? 0}%', isPrimary: true),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Listed on', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  Text(
                    item['createdAt'] is Timestamp 
                      ? DateFormat('dd MMM yyyy').format((item['createdAt'] as Timestamp).toDate())
                      : 'N/A',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 20),
              onSelected: onAction,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                if (status == 'pending') const PopupMenuItem(value: 'approve', child: Text('Approve Listing')),
                if (status == 'active') const PopupMenuItem(value: 'reject', child: Text('Reject Listing')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'delete', child: Text('Delete Listing', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          Text(
            value,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600, 
              color: isPrimary ? const Color(0xFF0F172A) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageNavBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool active;

  const _PageNavBtn({this.label, this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2563EB) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: icon != null
          ? Icon(icon, size: 18, color: active ? Colors.white : const Color(0xFF64748B))
          : Text(
              label!,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
}
