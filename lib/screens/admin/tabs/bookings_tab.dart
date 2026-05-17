import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
      stream: widget.adminService.getBookingsStream(),
      builder: (context, snapshot) {
        final allBookings = snapshot.data ?? [];

        // Dynamic Filtering
        final filteredBookings = allBookings.where((b) {
          final matchesSearch = (b['id']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (b['guestName']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (b['propertyName']?.toString().toLowerCase().contains(_searchQuery) ?? false);

          final status = b['status']?.toString().toLowerCase() ?? '';

          switch (_tabController.index) {
            case 1: return matchesSearch && status == 'pending';
            case 2: return matchesSearch && status == 'confirmed';
            case 3: return matchesSearch && (status == 'cancelled' || status == 'rejected');
            case 4: return matchesSearch && status == 'checked_out';
            default: return matchesSearch;
          }
        }).toList();

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
                child: Column(
                  children: [
                    TabHeader(
                      title: 'Bookings',
                      subtitle: 'Manage all booking requests and reservations',
                      isNarrow: widget.isNarrow,
                      actions: [
                        _buildHeaderAction('Export', Icons.file_download_outlined, isOutline: true, onPressed: _handleExport),
                        const SizedBox(width: 12),
                        _buildHeaderAction('Filters', Icons.tune_rounded, hasDropdown: true),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSummaryCards(allBookings),
                    const SizedBox(height: 32),
                    _buildCategoryTabs(allBookings),
                    const SizedBox(height: 24),
                    _buildFilterRow(),
                    const SizedBox(height: 24),
                    _buildPolicyBar(),
                    const SizedBox(height: 24),
                    if (!widget.isNarrow) _buildTableHeader(),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting && allBookings.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ))
                    else if (filteredBookings.isEmpty)
                      _buildEmptyState()
                    else
                      _buildBookingsList(filteredBookings),
                    const SizedBox(height: 32),
                    _buildPaginationFooter(filteredBookings.length),
                  ],
                ),
              ),
            ),
            if (!widget.isNarrow && _selectedBooking != null)
              _buildDetailPanel(),
          ],
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
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
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

  Widget _buildHeaderAction(String label, IconData icon, {bool isOutline = false, bool hasDropdown = false, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
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
            if (hasDropdown) ...[
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: isOutline ? const Color(0xFF64748B) : Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> bookings) {
    final confirmed = bookings.where((b) => b['status'] == 'confirmed').length;
    final pending = bookings.where((b) => b['status'] == 'pending').length;
    final cancelled = bookings.where((b) => b['status'] == 'cancelled' || b['status'] == 'rejected').length;

    double totalRevenue = 0;
    for (var b in bookings) {
      if (b['status'] == 'confirmed' || b['status'] == 'checked_out') {
        totalRevenue += (b['price'] as num?)?.toDouble() ?? 0;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          SummaryCard(
            count: bookings.length.toString(),
            label: 'Total Bookings',
            bg: const Color(0xFFEFF6FF),
            color: const Color(0xFF2563EB),
            icon: Icons.calendar_today_rounded,
            percentage: '14.6%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: confirmed.toString(),
            label: 'Confirmed',
            bg: const Color(0xFFF0FDF4),
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_rounded,
            sub: bookings.isEmpty ? '0% of total' : '${((confirmed/bookings.length)*100).toStringAsFixed(1)}% of total',
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: pending.toString(),
            label: 'Pending',
            bg: const Color(0xFFFFFBEB),
            color: const Color(0xFFD97706),
            icon: Icons.hourglass_top_rounded,
            sub: bookings.isEmpty ? '0% of total' : '${((pending/bookings.length)*100).toStringAsFixed(1)}% of total',
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: cancelled.toString(),
            label: 'Cancelled',
            bg: const Color(0xFFFEF2F2),
            color: const Color(0xFFDC2626),
            icon: Icons.cancel_outlined,
            sub: bookings.isEmpty ? '0% of total' : '${((cancelled/bookings.length)*100).toStringAsFixed(1)}% of total',
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: '₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(totalRevenue)}',
            label: 'Total Revenue',
            bg: const Color(0xFFFFF1F2),
            color: const Color(0xFFE11D48),
            icon: Icons.payments_outlined,
            percentage: '18.3%',
            isUp: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> bookings) {
    final pending = bookings.where((b) => b['status'] == 'pending').length;
    final confirmed = bookings.where((b) => b['status'] == 'confirmed').length;
    final cancelled = bookings.where((b) => b['status'] == 'cancelled' || b['status'] == 'rejected').length;
    final checkedOut = bookings.where((b) => b['status'] == 'checked_out').length;

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
        tabs: [
          Tab(text: 'All Bookings (${bookings.length})'),
          Tab(text: 'Pending ($pending)'),
          Tab(text: 'Confirmed ($confirmed)'),
          Tab(text: 'Cancelled ($cancelled)'),
          Tab(text: 'Checked Out ($checkedOut)'),
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
                    decoration: InputDecoration(
                      hintText: widget.isNarrow ? 'Search bookings...' : 'Search by booking ID, guest name, property...',
                      border: InputBorder.none,
                      hintStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildSmallFilter(widget.isNarrow ? '' : 'Status', icon: Icons.tune),
        if (!widget.isNarrow) ...[
          const SizedBox(width: 12),
          _buildSmallFilter('User Type'),
          const SizedBox(width: 12),
          _buildSmallFilter('Date Range', icon: Icons.calendar_month_outlined),
          const SizedBox(width: 12),
          _buildSmallFilter('More Filters'),
          const SizedBox(width: 12),
          _buildSmallFilter('Newest First', hasDropdown: true),
        ],
      ],
    );
  }

  Widget _buildSmallFilter(String label, {IconData? icon, bool hasDropdown = true}) {
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
          if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          if (hasDropdown) ...[const SizedBox(width: 6), const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B))],
        ],
      ),
    );
  }

  Widget _buildPolicyBar() {
    return Row(
      children: [
        Expanded(
          child: _buildPolicyItem(
            Icons.info_outline_rounded,
            'Minimum Stay Policy',
            'Students: Minimum 1 Month stay\nProfessionals: Minimum 3 Days stay',
            const Color(0xFFEFF6FF),
            const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPolicyItem(
            Icons.verified_user_outlined,
            'Stay Validation',
            'Bookings below the minimum stay requirement cannot be confirmed.',
            const Color(0xFFF0FDF4),
            const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyItem(IconData icon, String title, String sub, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _tableLabel('BOOKING ID')),
          Expanded(flex: 3, child: _tableLabel('PROPERTY')),
          Expanded(flex: 2, child: _tableLabel('GUEST')),
          Expanded(flex: 2, child: _tableLabel('USER TYPE')),
          Expanded(flex: 2, child: _tableLabel('STAY DURATION')),
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
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    return Column(
      children: bookings.map((b) => _BookingCard(
        id: b['id']?.toString().substring(0, 8).toUpperCase() ?? 'BK-NEW',
        date: _formatDate(b['createdAt']),
        time: _formatTime(b['createdAt']),
        property: b['propertyName'] ?? 'Untitled Property',
        location: b['location'] ?? 'Location N/A',
        propType: b['propertyType'] ?? 'Accommodation',
        guest: b['guestName'] ?? 'Unknown Guest',
        phone: b['guestPhone'] ?? 'No Phone',
        userType: _formatUserType(b['userRole']),
        duration: '${b['duration'] ?? 1} Month',
        stayDates: _formatStayDates(b['checkIn'], b['checkOut']),
        nights: '${b['nights'] ?? 30} Nights',
        status: _formatStatus(b['status']),
        statusColor: _getStatusColor(b['status']),
        amount: '₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(b['price'] ?? 0)}',
        isPaid: b['paymentStatus'] == 'paid',
        isSelected: _selectedBooking?['id'] == b['id'],
        onTap: () => setState(() => _selectedBooking = b),
        isNarrow: widget.isNarrow,
        onAction: (action) => _handleBookingAction(b['id'], action),
      )).toList(),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) return DateFormat('dd MMM yyyy').format(date.toDate());
    return date.toString();
  }

  String _formatTime(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) return DateFormat('hh:mm a').format(date.toDate());
    return '';
  }

  String _formatUserType(dynamic role) {
    final r = role?.toString().toLowerCase() ?? 'student';
    if (r == 'professional') return 'Professional';
    return 'Student';
  }

  String _formatStayDates(dynamic start, dynamic end) {
    if (start == null || end == null) return 'Dates N/A';
    final s = start is Timestamp ? start.toDate() : DateTime.tryParse(start.toString());
    final e = end is Timestamp ? end.toDate() : DateTime.tryParse(end.toString());
    if (s == null || e == null) return 'Dates N/A';
    return '${DateFormat('dd MMM').format(s)} - ${DateFormat('dd MMM yyyy').format(e)}';
  }

  String _formatStatus(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'confirmed') return 'Confirmed';
    if (status == 'pending') return 'Pending';
    if (status == 'cancelled' || status == 'rejected') return 'Cancelled';
    if (status == 'checked_out') return 'Checked Out';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'confirmed' || status == 'checked_out') return Colors.green;
    if (status == 'pending') return Colors.orange;
    if (status == 'cancelled' || status == 'rejected') return Colors.red;
    return Colors.grey;
  }

  void _handleBookingAction(String id, String action) async {
    // TODO: Implement Booking Actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action "$action" on booking $id coming soon'), backgroundColor: const Color(0xFF2563EB)),
    );
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting bookings to CSV...'), backgroundColor: Color(0xFF2563EB)),
    );
  }

  Widget _buildDetailPanel() {
    final b = _selectedBooking!;
    final status = _formatStatus(b['status']);

    return Container(
      width: 350,
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
                const Text('Booking Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _selectedBooking = null)),
              ],
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerRight,
              child: StatusBadge(text: status, color: _getStatusColor(b['status'])),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(width: 80, height: 80, color: const Color(0xFFF1F5F9), child: const Icon(Icons.business_rounded, color: Colors.grey)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b['propertyName'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                      Text(b['location'] ?? 'Location N/A', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(b['propertyType'] ?? 'Accommodation', style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 48),
            _buildDetailSectionTitle('Booking Information'),
            _detailRow('Booking ID', b['id']?.toString().toUpperCase() ?? 'N/A'),
            _detailRow('Booking Date', _formatDate(b['createdAt'])),
            _detailRow('Status', status, valueColor: _getStatusColor(b['status'])),
            _detailRow('Payment Status', (b['paymentStatus'] ?? 'pending').toString().toUpperCase(), valueColor: b['paymentStatus'] == 'paid' ? Colors.green : Colors.orange),
            _detailRow('Total Amount', '₹${b['price'] ?? 0}'),

            const Divider(height: 48),
            _buildDetailSectionTitle('Guest Information'),
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: const Color(0xFFF5F3FF), child: Text(b['guestName']?.toString().isNotEmpty == true ? b['guestName'][0] : 'U', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b['guestName'] ?? 'Unknown Guest', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(_formatUserType(b['userRole']), style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Text('View Profile', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(b['guestPhone'] ?? 'No Phone', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
            Text(b['guestEmail'] ?? 'No Email', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),

            const Divider(height: 48),
            _buildDetailSectionTitle('Stay Information'),
            _detailRow('Check-In Date', _formatDate(b['checkIn'])),
            _detailRow('Check-Out Date', _formatDate(b['checkOut'])),
            _detailRow('Duration', '${b['duration'] ?? 1} Month'),
            _detailRow('Rent (Monthly)', '₹${b['price'] ?? 0}'),

            const Divider(height: 48),
            _buildDetailSectionTitle('Booking Timeline'),
            _buildTimelineItem(true, 'Booking Request', _formatDate(b['createdAt'])),
            _buildTimelineItem(b['status'] != 'pending', 'Status Updated', _formatDate(b['updatedAt'])),

            const SizedBox(height: 40),
            _actionButton('View Invoice', Colors.white, const Color(0xFF2563EB), hasBorder: true, icon: Icons.description_outlined, onPressed: () {}),
            const SizedBox(height: 12),
            _actionButton('Send Message', const Color(0xFFF5F3FF), const Color(0xFF7C3AED), icon: Icons.message_outlined, onPressed: () {}),
            const SizedBox(height: 12),
            _actionButton('Update Status', const Color(0xFFFEF2F2), const Color(0xFFDC2626), icon: Icons.edit_outlined, onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(bool completed, String title, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(completed ? Icons.check_circle : Icons.circle_outlined, size: 16, color: completed ? Colors.green : Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: completed ? const Color(0xFF1E293B) : Colors.grey)),
              Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color bg, Color text, {bool hasBorder = false, IconData? icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: hasBorder ? Border.all(color: text.withValues(alpha: 0.2)) : null,
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  if (icon != null) ...[Icon(icon, size: 16, color: text), const SizedBox(width: 8)],
                  Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
          ),
      ),
    );
  }

  Widget _buildPaginationFooter(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.isNarrow ? '1-$count of $count' : 'Showing 1 to $count of $count bookings',
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

class _BookingCard extends StatelessWidget {
  final String id;
  final String date;
  final String time;
  final String property;
  final String location;
  final String propType;
  final String guest;
  final String phone;
  final String userType;
  final String duration;
  final String stayDates;
  final String nights;
  final String status;
  final Color statusColor;
  final String amount;
  final bool isPaid;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNarrow;
  final Function(String) onAction;

  const _BookingCard({
    required this.id,
    required this.date,
    required this.time,
    required this.property,
    required this.location,
    required this.propType,
    required this.guest,
    required this.phone,
    required this.userType,
    required this.duration,
    required this.stayDates,
    required this.nights,
    required this.status,
    required this.statusColor,
    required this.amount,
    required this.isPaid,
    required this.isSelected,
    required this.onTap,
    required this.isNarrow,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9)),
          boxShadow: [if (isSelected) BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            // 1. Booking ID
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                  Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ),

            // 2. Property
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.business_rounded, color: Colors.grey, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(property, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(location, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        Text(propType, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Guest
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guest, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                  Text(phone, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ),

            // 4. User Type
            if (!isNarrow)
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (userType == 'Student' ? const Color(0xFF2563EB) : const Color(0xFF7C3AED)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(userType == 'Student' ? Icons.school_outlined : Icons.work_outline, size: 12, color: userType == 'Student' ? const Color(0xFF2563EB) : const Color(0xFF7C3AED)),
                        const SizedBox(width: 4),
                        Text(userType, style: TextStyle(color: userType == 'Student' ? const Color(0xFF2563EB) : const Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),

            // 5. Duration
            if (!isNarrow)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(duration, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B))),
                    Text(stayDates, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                    Text('($nights)', style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),

            // 6. Status
            Expanded(
              flex: 2,
              child: StatusBadge(text: status, color: statusColor),
            ),

            // 7. Amount
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                  Text(isPaid ? 'Paid' : 'Pending', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isPaid ? Colors.green : Colors.orange)),
                ],
              ),
            ),

            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
              onSelected: onAction,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'confirm', child: Text('Confirm Booking')),
                const PopupMenuItem(value: 'cancel', child: Text('Cancel Booking')),
                const PopupMenuItem(value: 'checkout', child: Text('Mark Checked Out')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'invoice', child: Text('View Invoice')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

