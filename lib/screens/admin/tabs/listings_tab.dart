import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';

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
            title: 'Listings',
            subtitle: 'Manage all properties listed on the platform',
            isNarrow: widget.isNarrow,
            actions: [
              _buildAddButton(),
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
          _buildListingsList(),
          const SizedBox(height: 32),
          _buildPaginationFooter(),
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

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const SummaryCard(
            count: '1,076',
            label: 'Total Listings',
            bg: Color(0xFFEFF6FF),
            color: Color(0xFF2563EB),
            icon: Icons.business_rounded,
            percentage: '12.5%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '896',
            label: 'Active Listings',
            bg: Color(0xFFF0FDF4),
            color: Color(0xFF16A34A),
            icon: Icons.check_circle_rounded,
            sub: '83.3% of total',
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '68',
            label: 'Under Review',
            bg: Color(0xFFFFFBEB),
            color: Color(0xFFD97706),
            icon: Icons.hourglass_top_rounded,
            sub: '6.3% of total',
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '112',
            label: 'Inactive/Rejected',
            bg: Color(0xFFFEF2F2),
            color: Color(0xFFDC2626),
            icon: Icons.cancel_outlined,
            sub: '10.4% of total',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
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

  Widget _buildListingsList() {
    return Column(
      children: [
        _ListingCard(
          title: 'Sunrise Hostels',
          type: 'PG Hostel',
          location: 'Kozhikode, Kerala',
          rooms: '15 Rooms • 3 Sharing',
          hoster: 'John Doe',
          hosterId: 'HST001',
          views: '1,245',
          bookings: '32',
          occupancy: '86%',
          status: 'Active',
          statusColor: Colors.green,
          date: '10 May 2025',
          isNarrow: widget.isNarrow,
        ),
        _ListingCard(
          title: 'Green Valley PG',
          type: 'PG Accommodation',
          location: 'Kozhikode, Kerala',
          rooms: '20 Rooms • 2 & 3 Sharing',
          hoster: 'Mike Johnson',
          hosterId: 'HST002',
          views: '982',
          bookings: '28',
          occupancy: '78%',
          status: 'Active',
          statusColor: Colors.green,
          date: '08 May 2025',
          isNarrow: widget.isNarrow,
        ),
        _ListingCard(
          title: 'Comfort Living PG',
          type: 'PG Accommodation',
          location: 'Thrissur, Kerala',
          rooms: '12 Rooms • 3 Sharing',
          hoster: 'Aman Singh',
          hosterId: 'HST003',
          views: '645',
          bookings: '14',
          occupancy: '65%',
          status: 'Under Review',
          statusColor: Colors.orange,
          date: '17 May 2025',
          isNarrow: widget.isNarrow,
        ),
        _ListingCard(
          title: 'Happy Stay PG',
          type: 'PG Hostel',
          location: 'Malappuram, Kerala',
          rooms: '18 Rooms • 2 & 3 Sharing',
          hoster: 'Rahul Sharma',
          hosterId: 'HST004',
          views: '1,102',
          bookings: '26',
          occupancy: '72%',
          status: 'Active',
          statusColor: Colors.green,
          date: '05 May 2025',
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
            widget.isNarrow ? '1-10 of 1,076' : 'Showing 1 to 10 of 1,076 listings',
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
              const PaginationBtn(label: '108'),
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

class _ListingCard extends StatelessWidget {
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
                    child: Text(hoster[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hoster, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                        const Text('Verified Hoster', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        Text('ID: \$hosterId', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
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
          Text('\$label: ', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
