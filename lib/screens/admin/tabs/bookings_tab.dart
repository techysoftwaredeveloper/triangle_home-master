import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';

class BookingsTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const BookingsTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _selectedBooking;

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
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
            child: Column(
              children: [
                TabHeader(
                  title: 'Bookings',
                  subtitle: 'Manage all booking requests and reservations',
                  isNarrow: widget.isNarrow,
                  actions: [
                    _buildHeaderAction('Export', Icons.file_download_outlined, isOutline: true),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSummaryCards(),
                const SizedBox(height: 32),
                _buildCategoryTabs(),
                const SizedBox(height: 24),
                SearchFilterRow(hint: 'Search by guest, property or ID...', isNarrow: widget.isNarrow),
                const SizedBox(height: 24),
                if (!widget.isNarrow) _buildTableHeader(),
                const SizedBox(height: 12),
                _buildBookingsList(),
                const SizedBox(height: 32),
                _buildPagination(),
              ],
            ),
          ),
        ),
        if (!widget.isNarrow && _selectedBooking != null)
          _buildDetailPanel(),
      ],
    );
  }

  Widget _buildHeaderAction(String label, IconData icon, {bool isOutline = false}) {
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
            label,
            style: TextStyle(
              color: isOutline ? const Color(0xFF1E293B) : Colors.white,
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
          const SummaryCard(
            count: '452',
            label: 'TOTAL BOOKINGS',
            bg: Color(0xFFEFF6FF),
            color: Color(0xFF2563EB),
            icon: Icons.calendar_today_rounded,
            percentage: '14.6%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '312',
            label: 'CONFIRMED',
            bg: Color(0xFFF0FDF4),
            color: Color(0xFF16A34A),
            icon: Icons.check_circle_rounded,
            sub: '69.0% of total',
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '₹4.8L',
            label: 'REVENUE',
            bg: Color(0xFFFFF1F2),
            color: Color(0xFFE11D48),
            icon: Icons.payments_outlined,
            percentage: '18.7%',
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
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'All Bookings (452)'),
          Tab(text: 'Pending (78)'),
          Tab(text: 'Confirmed (312)'),
          Tab(text: 'Cancelled (34)'),
          Tab(text: 'Checked Out (28)'),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _tableLabel('BOOKING')),
          Expanded(flex: 3, child: _tableLabel('PROPERTY')),
          Expanded(flex: 2, child: _tableLabel('GUEST')),
          Expanded(flex: 2, child: _tableLabel('STATUS')),
          Expanded(flex: 2, child: _tableLabel('AMOUNT')),
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

  Widget _buildBookingsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getBookingsStream(),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Column(
            children: List.generate(
              5,
              (index) => _buildBookingCard({
                'id': 'BK-100\${index + 1}',
                'propertyName': 'Sunrise Hostels',
                'studentName': 'John Doe',
                'status': 'Confirmed',
                'price': '6,500',
                'date': '18 May 2025',
              }),
            ),
          );
        }
        return Column(
          children: bookings.map((b) => _buildBookingCard(b)).toList(),
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    final bool isSelected = _selectedBooking?['id'] == b['id'];
    final String price = b['price'].toString();

    return GestureDetector(
      onTap: () => setState(() => _selectedBooking = b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['id'] ?? 'BK-1001', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(b['date'] ?? '18 May 2025', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                b['propertyName'] ?? 'Property',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!widget.isNarrow)
              Expanded(
                flex: 2,
                child: Text(b['studentName'] ?? 'Guest', style: const TextStyle(fontSize: 12)),
              ),
            Expanded(
              flex: 2,
              child: StatusBadge(text: b['status'] ?? 'Pending', color: _getStatusColor(b['status'])),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹$price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text('Paid', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? s) {
    switch (s) {
      case 'Confirmed': return const Color(0xFF16A34A);
      case 'Pending': return const Color(0xFFD97706);
      case 'Cancelled': return const Color(0xFFDC2626);
      default: return Colors.blue;
    }
  }

  Widget _buildDetailPanel() {
    final String price = _selectedBooking!['price'].toString();
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Booking Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedBooking = null)),
              ],
            ),
            const SizedBox(height: 24),
            _detailSection('Property', _selectedBooking!['propertyName'], Icons.home_work_outlined),
            _detailSection('Guest', _selectedBooking!['studentName'], Icons.person_outline),
            _detailSection('Amount', '₹$price', Icons.payments_outlined),
            const SizedBox(height: 40),
            _actionBtn('View Invoice', Colors.blue.shade600, Colors.white),
            const SizedBox(height: 12),
            _actionBtn('Send Message', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color bg, Color text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.isNarrow ? '1-10 of 452' : 'Showing 1 to 10 of 452 bookings',
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
            const PaginationBtn(icon: Icons.chevron_right),
          ],
        ),
      ],
    );
  }
}
