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
      stream: widget.adminService.getPropertiesStream(),
      builder: (context, snapshot) {
        final allProperties = snapshot.data ?? [];

        // Filtering logic
        final filteredProperties = allProperties.where((p) {
          final matchesSearch = (p['name']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (p['hosterName']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (p['location']?.toString().toLowerCase().contains(_searchQuery) ?? false);

          final status = p['status']?.toString().toLowerCase() ?? '';

          switch (_tabController.index) {
            case 1: return matchesSearch && status == 'active';
            case 2: return matchesSearch && status == 'pending';
            case 3: return matchesSearch && status == 'inactive';
            case 4: return matchesSearch && status == 'rejected';
            default: return matchesSearch;
          }
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          child: Column(
            children: [
              TabHeader(
                title: 'Listings',
                subtitle: 'Manage all properties listed on the platform',
                isNarrow: widget.isNarrow,
                actions: [
                  _buildAddButton(),
                ],
              ),
              const SizedBox(height: 32),
              _buildSummaryCards(allProperties),
              const SizedBox(height: 32),
              _buildCategoryTabs(allProperties),
              const SizedBox(height: 24),
              _buildFilterRow(),
              const SizedBox(height: 24),
              if (!widget.isNarrow) _buildTableHeader(),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting && allProperties.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ))
              else if (filteredProperties.isEmpty)
                _buildEmptyState()
              else
                _buildListingsList(filteredProperties),
              const SizedBox(height: 32),
              _buildPaginationFooter(filteredProperties.length),
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
          Icon(Icons.home_work_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: const [
          Icon(Icons.add, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Add New Listing',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> properties) {
    final active = properties.where((p) => p['status'] == 'active').length;
    final review = properties.where((p) => p['status'] == 'pending').length;
    final inactive = properties.where((p) => p['status'] == 'inactive' || p['status'] == 'rejected').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          SummaryCard(
            count: properties.length.toString(),
            label: 'Total Listings',
            bg: const Color(0xFFEFF6FF),
            color: const Color(0xFF2563EB),
            icon: Icons.business_rounded,
            percentage: '12.5%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: active.toString(),
            label: 'Active Listings',
            bg: const Color(0xFFF0FDF4),
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_rounded,
            sub: properties.isEmpty ? '0% of total' : '${((active/properties.length)*100).toStringAsFixed(1)}% of total',
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: review.toString(),
            label: 'Under Review',
            bg: const Color(0xFFFFFBEB),
            color: const Color(0xFFD97706),
            icon: Icons.hourglass_top_rounded,
            sub: properties.isEmpty ? '0% of total' : '${((review/properties.length)*100).toStringAsFixed(1)}% of total',
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: inactive.toString(),
            label: 'Inactive/Rejected',
            bg: const Color(0xFFFEF2F2),
            color: const Color(0xFFDC2626),
            icon: Icons.cancel_outlined,
            sub: properties.isEmpty ? '0% of total' : '${((inactive/properties.length)*100).toStringAsFixed(1)}% of total',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> properties) {
    final active = properties.where((p) => p['status'] == 'active').length;
    final review = properties.where((p) => p['status'] == 'pending').length;
    final inactive = properties.where((p) => p['status'] == 'inactive').length;
    final rejected = properties.where((p) => p['status'] == 'rejected').length;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
        tabs: [
          Tab(text: 'All Listings (${properties.length})'),
          Tab(text: 'Active ($active)'),
          Tab(text: 'Under Review ($review)'),
          Tab(text: 'Inactive ($inactive)'),
          Tab(text: 'Rejected ($rejected)'),
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
                      hintText: 'Search by property name, hoster or location...',
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
          Expanded(flex: 3, child: _tableLabel('PROPERTY')),
          Expanded(flex: 2, child: _tableLabel('HOSTER & DETAILS')),
          Expanded(flex: 2, child: _tableLabel('STATS')),
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

  Widget _buildListingsList(List<Map<String, dynamic>> properties) {
    return Column(
      children: properties.map((p) => _ListingCard(
        id: p['id'],
        title: p['name'] ?? 'Untitled Property',
        type: p['category'] ?? 'Property',
        location: p['location'] ?? 'Unknown Location',
        rooms: '${p['rooms'] ?? 0} Rooms',
        hoster: p['hosterName'] ?? 'Unknown Hoster',
        hosterId: p['hosterId']?.toString().substring(0, 6).toUpperCase() ?? 'N/A',
        views: (p['views'] ?? 0).toString(),
        bookings: (p['bookingsCount'] ?? 0).toString(),
        occupancy: '${p['occupancy'] ?? 0}%',
        status: _formatStatus(p['status']),
        statusColor: _getStatusColor(p['status']),
        date: _formatDate(p['createdAt']),
        isNarrow: widget.isNarrow,
      )).toList(),
    );
  }

  String _formatStatus(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'active') return 'Active';
    if (status == 'pending') return 'Under Review';
    if (status == 'inactive') return 'Inactive';
    if (status == 'rejected') return 'Rejected';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'active') return Colors.green;
    if (status == 'pending') return Colors.orange;
    if (status == 'rejected') return Colors.red;
    return Colors.grey;
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
            widget.isNarrow ? '1-$count of $count' : 'Showing 1 to $count of $count listings',
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
}

class _ListingCard extends StatelessWidget {
  final String id;
  final String title;
  final String type;
  final String location;
  final String rooms;
  final String hoster;
  final String hosterId;
  final String views;
  final String bookings;
  final String occupancy;
  final String status;
  final Color statusColor;
  final String date;
  final bool isNarrow;

  const _ListingCard({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.rooms,
    required this.hoster,
    required this.hosterId,
    required this.views,
    required this.bookings,
    required this.occupancy,
    required this.status,
    required this.statusColor,
    required this.date,
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
          // 1. Property
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_work_outlined, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 12),
                        ],
                      ),
                      Text(type, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      if (!isNarrow) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(location, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Hoster
          if (!isNarrow)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFF5F3FF),
                    child: Text(hoster.isNotEmpty ? hoster[0] : 'U', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hoster, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const Text('Verified Hoster', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        Text('ID: $hosterId', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 3. Stats
          if (!isNarrow)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _miniStat('Views', views),
                  _miniStat('Bookings', bookings),
                  _miniStat('Occupancy', occupancy, isBold: true),
                ],
              ),
            ),

          // 4. Status
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(text: status, color: statusColor),
                const SizedBox(height: 4),
                Text(status == 'Active' ? 'Listed on' : 'Submitted on', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                Text(date, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

