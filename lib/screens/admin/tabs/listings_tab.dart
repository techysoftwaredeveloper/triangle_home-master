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
          SearchFilterRow(hint: 'Search properties...', isNarrow: widget.isNarrow),
          const SizedBox(height: 24),
          if (!widget.isNarrow) _buildTableHeader(),
          const SizedBox(height: 12),
          _buildListingsList(),
          const SizedBox(height: 32),
          _PaginationFooter(
            text: widget.isNarrow ? '1-10 of 1,076' : 'Showing 1 to 10 of 1,076 listings',
            isNarrow: widget.isNarrow,
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
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
            count: '1,076',
            label: 'TOTAL LISTINGS',
            bg: const Color(0xFFEFF6FF),
            color: const Color(0xFF2563EB),
            icon: Icons.business_rounded,
            percentage: '12.5%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '896',
            label: 'ACTIVE',
            bg: const Color(0xFFF0FDF4),
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_rounded,
            sub: '83.3% of total',
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '68',
            label: 'UNDER REVIEW',
            bg: const Color(0xFFFFFBEB),
            color: const Color(0xFFD97706),
            icon: Icons.hourglass_top_rounded,
            sub: '6.3% of total',
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
          Tab(text: 'All Listings (1,076)'),
          Tab(text: 'Active (896)'),
          Tab(text: 'Under Review (68)'),
          Tab(text: 'Inactive (112)'),
          Tab(text: 'Rejected (48)'),
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
          Expanded(flex: 2, child: _tableLabel('HOSTER')),
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
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildListingsList() {
    return Column(
      children: List.generate(4, (index) => _ListingCard(isNarrow: widget.isNarrow)),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final bool isNarrow;
  const _ListingCard({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_work_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sunrise Hostels',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Kozhikode, Kerala',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (!isNarrow)
            const Expanded(
              flex: 2,
              child: Text(
                'John Doe',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          if (!isNarrow)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('86% Occupancy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('32 Bookings', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                StatusBadge(text: 'Active', color: Colors.green),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  final String text;
  final bool isNarrow;

  const _PaginationFooter({required this.text, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            const PaginationBtn(icon: Icons.chevron_left),
            const PaginationBtn(label: '1', active: true),
            if (!isNarrow) const PaginationBtn(label: '2'),
            const Text('...', style: TextStyle(color: Colors.grey)),
            const PaginationBtn(icon: Icons.chevron_right),
          ],
        ),
      ],
    );
  }
}
