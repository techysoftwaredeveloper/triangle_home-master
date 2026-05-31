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

  void _handleBookingAction(String id, String action) async {
    try {
      if (action == 'confirm') {
        await widget.adminService.updateBookingStatus(id, 'confirmed');
      } else if (action == 'cancel') {
        await widget.adminService.updateBookingStatus(id, 'cancelled');
      } else if (action == 'checkout') {
        await widget.adminService.updateBookingStatus(id, 'checked_out');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking $action successfully'),
            backgroundColor: action == 'cancel' ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to perform $action: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getBookingsStream(),
      builder: (context, snapshot) {
        final allBookings = snapshot.data ?? [];

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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildSummaryRow(allBookings),
                    const SizedBox(height: 64),
                    _buildCategoryTabs(allBookings),
                    const SizedBox(height: 24),
                    _buildFilterControls(),
                    const SizedBox(height: 24),
                    _buildPolicyBanner(),
                    const SizedBox(height: 24),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: widget.isNarrow ? 0 : 1100,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!widget.isNarrow) _buildTableHeader(),
                            const SizedBox(height: 12),
                            if (snapshot.connectionState == ConnectionState.waiting && allBookings.isEmpty)
                              const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
                            else if (filteredBookings.isEmpty)
                              _buildEmptyState()
                            else
                              _buildBookingsList(filteredBookings),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    _buildPaginationFooter(filteredBookings.length),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (!widget.isNarrow && _selectedBooking != null)
              _buildSideSheet(),
          ],
        );
      }
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Bookings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Outfit')),
                SizedBox(height: 4),
                Text('Manage all booking requests and reservations', style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontFamily: 'Outfit')),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderActionBtn('Export', Icons.file_download_outlined, isOutline: true),
                const SizedBox(width: 16),
                _buildHeaderActionBtn('Filters', Icons.tune_rounded, hasDropdown: true),
              ],
            ),
          ],
        );
      }
    );
  }

  Widget _buildHeaderActionBtn(String label, IconData icon, {bool isOutline = false, bool hasDropdown = false}) {
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
          Text(label, style: TextStyle(color: isOutline ? const Color(0xFF0F172A) : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          if (hasDropdown) ...[
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: isOutline ? const Color(0xFF64748B) : Colors.white, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<Map<String, dynamic>> bookings) {
    final confirmed = bookings.where((b) => b['status'] == 'confirmed').length;
    final pending = bookings.where((b) => b['status'] == 'pending').length;
    final cancelled = bookings.where((b) => b['status'] == 'cancelled' || b['status'] == 'rejected').length;
    
    double totalRevenue = 0;
    for (var b in bookings) {
      if (b['status'] == 'confirmed' || b['status'] == 'checked_out') {
        totalRevenue += (b['price'] as num?)?.toDouble() ?? 0;
      }
    }

    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _StatCard(count: bookings.length.toString(), label: 'Total Bookings', icon: Icons.calendar_today_outlined, iconColor: const Color(0xFF3B82F6), bgColor: const Color(0xFFEFF6FF), trend: '14.6%', isTrendUp: true),
          const SizedBox(width: 16),
          _StatCard(count: confirmed.toString(), label: 'Confirmed', icon: Icons.check_circle_outline, iconColor: const Color(0xFF10B981), bgColor: const Color(0xFFECFDF5), sub: '69.4% of total'),
          const SizedBox(width: 16),
          _StatCard(count: pending.toString(), label: 'Pending', icon: Icons.hourglass_top_outlined, iconColor: const Color(0xFFF59E0B), bgColor: const Color(0xFFFFF7ED), sub: '17.2% of total'),
          const SizedBox(width: 16),
          _StatCard(count: cancelled.toString(), label: 'Cancelled', icon: Icons.cancel_outlined, iconColor: const Color(0xFF8B5CF6), bgColor: const Color(0xFFF5F3FF), sub: '7.8% of total'),
          const SizedBox(width: 16),
          _StatCard(count: format.format(totalRevenue), label: 'Total Revenue', icon: Icons.account_balance_wallet_outlined, iconColor: const Color(0xFFE11D48), bgColor: const Color(0xFFFFF1F2), trend: '18.3%', isTrendUp: true),
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
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        onTap: (index) => setState(() {}),
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit'),
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

  Widget _buildFilterControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 900;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: 'Search by booking ID, guest name, property...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))))),
                        if (!isCompact) const Text('⌘ K', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 16),
                  _FilterBtn(label: 'Status', hasDropdown: true),
                  const SizedBox(width: 16),
                  _FilterBtn(label: 'User Type', hasDropdown: true),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  if (isCompact) ...[
                    _FilterBtn(label: 'Status', hasDropdown: true),
                    const SizedBox(width: 12),
                    _FilterBtn(label: 'User Type', hasDropdown: true),
                    const SizedBox(width: 12),
                  ],
                  _FilterBtn(label: 'Date Range', icon: Icons.calendar_month_outlined, hasDropdown: true),
                  const SizedBox(width: 12),
                  _FilterBtn(label: 'More Filters', hasDropdown: true),
                  const SizedBox(width: 12),
                  _FilterBtn(label: 'Newest First', hasDropdown: true),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPolicyBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 800;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: isCompact 
            ? Column(
                children: [
                  _policyItem(Icons.school_outlined, 'Student Booking Policy', 'Minimum stay: 1 Month (30 Nights)\nPayment is collected monthly in advance.'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Color(0xFFE2E8F0))),
                  _policyItem(Icons.work_outline_rounded, 'Professional Booking Policy', 'Minimum stay: 3 Days (2 Nights)\nPayment is collected in advance.'),
                ],
              )
            : Row(
                children: [
                  _policyItem(Icons.school_outlined, 'Student Booking Policy', 'Minimum stay: 1 Month (30 Nights)\nPayment is collected monthly in advance.'),
                  const SizedBox(width: 48),
                  _policyItem(Icons.work_outline_rounded, 'Professional Booking Policy', 'Minimum stay: 3 Days (2 Nights)\nPayment is collected in advance.'),
                  const Spacer(),
                  const Text('Learn More', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2563EB)),
                ],
              ),
        );
      }
    );
  }

  Widget _policyItem(IconData icon, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF6366F1), size: 18)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))), const SizedBox(height: 4), Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4))]),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      child: Row(
        children: [
          Expanded(flex: 2, child: _headerLabel('BOOKING ID')),
          Expanded(flex: 3, child: _headerLabel('PROPERTY')),
          Expanded(flex: 2, child: _headerLabel('GUEST')),
          Expanded(flex: 2, child: _headerLabel('USER TYPE')),
          Expanded(flex: 2, child: _headerLabel('STAY DURATION')),
          Expanded(flex: 2, child: _headerLabel('STATUS')),
          Expanded(flex: 2, child: _headerLabel('AMOUNT')),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _headerLabel(String text) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5));

  Widget _buildBookingsList(List<Map<String, dynamic>> items) {
    return Column(
      children: items.map<Widget>((item) => _BookingTableCard(
        item: item, 
        isSelected: _selectedBooking?['id'] == item['id'],
        onTap: () => setState(() => _selectedBooking = item),
      )).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(height: 200, width: 1100, alignment: Alignment.center, child: const Text('No matching bookings found', style: TextStyle(color: Color(0xFF64748B))));
  }

  Widget _buildPaginationFooter(int count) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 750;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(isCompact ? '1-10 of $count' : 'Showing 1 to ${count < 10 ? count : 10} of $count bookings', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
                if (!isCompact) _buildPageSizeSelector(),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PageBtn(icon: Icons.chevron_left),
                  _PageBtn(label: '1', active: true),
                  _PageBtn(label: '2'),
                  if (!isCompact) ...[_PageBtn(label: '3'), _PageBtn(label: '4'), _PageBtn(label: '5')],
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('...', style: TextStyle(color: Color(0xFF94A3B8)))),
                  _PageBtn(label: '42'),
                  _PageBtn(icon: Icons.chevron_right),
                  if (isCompact) ...[const SizedBox(width: 16), _buildPageSizeSelector()],
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [Text('10 / page', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A))), SizedBox(width: 8), Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B))]),
    );
  }

  Widget _buildSideSheet() {
    final b = _selectedBooking!;
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    return Container(
      width: 400,
      decoration: const BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Booking Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                IconButton(icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)), onPressed: () => setState(() => _selectedBooking = null)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.network(
                          b['propertyImage'] ?? '',
                          height: 200, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 200, color: const Color(0xFFF1F5F9), child: const Icon(Icons.business_rounded, size: 40, color: Colors.grey)),
                        ),
                        Positioned(top: 16, right: 16, child: _StatusPill(status: b['status']?.toString() ?? 'pending')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(b['propertyName'] ?? 'Untitled Property', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text(b['location'] ?? 'Location N/A', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text(b['propertyType']?.toString().toUpperCase() ?? 'PG / HOSTEL', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                  
                  const Divider(height: 48),
                  _sheetSection('Guest Information'),
                  Row(
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: const Color(0xFFF3E8FF), child: Text((b['guestName'] ?? 'U')[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['guestName'] ?? 'Unknown Guest', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text(b['userRole']?.toString().toUpperCase() ?? 'STUDENT', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                          ],
                        ),
                      ),
                      const Text('View Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(b['guestPhone'] ?? 'No contact', style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                  Text(b['guestEmail'] ?? 'No email', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),

                  const Divider(height: 48),
                  _sheetSection('Stay Information'),
                  _sheetRow('Check-In Date', _formatDate(b['checkIn'])),
                  _sheetRow('Check-Out Date', _formatDate(b['checkOut'])),
                  _sheetRow('Duration', '${b['duration'] ?? 1} Month (${b['nights'] ?? 30} Nights)'),
                  _sheetRow('Room / Bed', b['roomNumber'] ?? 'A-203'),
                  _sheetRow('Rent (Monthly)', format.format(b['price'] ?? 0)),

                  const Divider(height: 48),
                  _sheetSection('Payment Information'),
                  _sheetRow('Total Amount', format.format(b['price'] ?? 0)),
                  _sheetRow('Paid Amount', format.format(b['paidAmount'] ?? 0)),
                  _sheetRow('Payment Method', b['paymentMethod']?.toString().toUpperCase() ?? 'UPI'),
                  _sheetRow('Payment Status', (b['paymentStatus'] ?? 'pending').toString().toUpperCase(), valueColor: b['paymentStatus'] == 'paid' ? Colors.green : Colors.orange),
                  _sheetRow('Transaction ID', b['transactionId'] ?? 'UPI1234567890'),
                  _sheetRow('Paid On', _formatDate(b['paidAt'])),

                  const Divider(height: 48),
                  _sheetSection('Booking Timeline'),
                  _timelineItem('Booking Request', _formatDate(b['createdAt']), true),
                  _timelineItem('Confirmed', _formatDate(b['updatedAt']), b['status'] == 'confirmed'),
                  _timelineItem('Check-In', 'Pending', false),
                  _timelineItem('Checked Out', 'Pending', false),

                  const SizedBox(height: 40),
                  _sheetActionBtn('View Invoice', Icons.description_outlined, const Color(0xFFEFF6FF), const Color(0xFF2563EB), () => _handleBookingAction(b['id'], 'invoice')),
                  const SizedBox(height: 12),
                  _sheetActionBtn('Send Message', Icons.message_outlined, const Color(0xFFF5F3FF), const Color(0xFF8B5CF6), () => _handleBookingAction(b['id'], 'message')),
                  const SizedBox(height: 12),
                  _sheetActionBtn('Cancel Booking', Icons.cancel_outlined, const Color(0xFFFEF2F2), const Color(0xFFEF4444), () => _handleBookingAction(b['id'], 'cancel')),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetSection(String title) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5)));

  Widget _sheetRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _timelineItem(String title, String date, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(completed ? Icons.check_circle : Icons.circle_outlined, size: 18, color: completed ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: completed ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))), Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))]),
        ],
      ),
    );
  }

  Widget _sheetActionBtn(String label, IconData icon, Color bg, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) return DateFormat('dd MMM yyyy').format(date.toDate());
    return date.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String? trend;
  final bool? isTrendUp;
  final String? sub;
  const _StatCard({required this.count, required this.label, required this.icon, required this.iconColor, required this.bgColor, this.trend, this.isTrendUp, this.sub});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(height: 20),
          Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          if (trend != null) Row(children: [Icon(isTrendUp == true ? Icons.arrow_upward : Icons.arrow_downward, color: const Color(0xFF10B981), size: 14), const SizedBox(width: 4), Text(trend!, style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 4), const Text('vs last month', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11))])
          else if (sub != null) Text(sub!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool hasDropdown;
  const _FilterBtn({required this.label, this.icon, this.hasDropdown = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [if (icon != null) ...[Icon(icon, size: 18, color: const Color(0xFF64748B)), const SizedBox(width: 8)], Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))), if (hasDropdown) ...[const SizedBox(width: 8), const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B))]]),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _PolicyCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.bgColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4))]))]),
    );
  }
}

class _BookingTableCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final VoidCallback onTap;
  const _BookingTableCard({required this.item, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final amountFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final role = item['userRole']?.toString().toLowerCase() ?? 'student';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 1100, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFF1F5F9) : Colors.white, border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
        child: Row(
          children: [
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['id']?.toString().toUpperCase() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))), const SizedBox(height: 4), Text(_formatDate(item['createdAt']), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))), Text(_formatTime(item['createdAt']), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))])) ,
            Expanded(flex: 3, child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['propertyImage'] ?? '', width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: const Color(0xFFF1F5F9), child: const Icon(Icons.business_rounded, size: 20, color: Colors.grey)))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['propertyName'] ?? 'Unknown Property', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis), Text(item['location'] ?? 'Location N/A', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis), Text(item['propertyType']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))]))])),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['guestName'] ?? 'Unknown Guest', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))), Text(item['guestPhone'] ?? 'No contact', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))])) ,
            Expanded(flex: 2, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (role == 'student' ? const Color(0xFF2563EB) : const Color(0xFF7C3AED)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(role == 'student' ? Icons.school_outlined : Icons.work_outline, size: 14, color: role == 'student' ? const Color(0xFF2563EB) : const Color(0xFF7C3AED)), const SizedBox(width: 6), Text(role.toUpperCase(), style: TextStyle(color: role == 'student' ? const Color(0xFF2563EB) : const Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.bold))])))),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${item['duration'] ?? 1} Month', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))), Text('${_formatDateShort(item['checkIn'])} - ${_formatDateShort(item['checkOut'])}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))), Text('(${item['nights'] ?? 30} Nights)', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))])) ,
            Expanded(flex: 2, child: Center(child: _StatusPill(status: item['status']?.toString() ?? 'pending'))),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(amountFormat.format(item['price'] ?? 6500), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))), Text((item['paymentStatus'] ?? 'paid').toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item['paymentStatus'] == 'paid' ? Colors.green : Colors.orange))])),
            const SizedBox(width: 16), const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
  String _formatDate(dynamic date) { if (date == null) return 'N/A'; if (date is Timestamp) return DateFormat('dd MMM yyyy').format(date.toDate()); return date.toString(); }
  String _formatDateShort(dynamic date) { if (date == null) return 'N/A'; if (date is Timestamp) return DateFormat('dd MMM').format(date.toDate()); return date.toString(); }
  String _formatTime(dynamic date) { if (date == null) return ''; if (date is Timestamp) return DateFormat('hh:mm a').format(date.toDate()); return ''; }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final String label; final Color color; final Color bg;
    if (s == 'confirmed' || s == 'checked_out') { label = s == 'confirmed' ? 'Confirmed' : 'Checked Out'; color = const Color(0xFF10B981); bg = const Color(0xFFECFDF5); }
    else if (s == 'pending') { label = 'Pending'; color = const Color(0xFFF59E0B); bg = const Color(0xFFFFF7ED); }
    else if (s == 'cancelled' || s == 'rejected') { label = 'Cancelled'; color = const Color(0xFFEF4444); bg = const Color(0xFFFEF2F2); }
    else { label = status; color = Colors.grey; bg = const Color(0xFFF1F5F9); }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }
}

class _PageBtn extends StatelessWidget {
  final String? label; final IconData? icon; final bool active;
  const _PageBtn({this.label, this.icon, this.active = false});
  @override
  Widget build(BuildContext context) {
    return Container(width: 36, height: 36, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: active ? const Color(0xFF2563EB) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))), child: Center(child: icon != null ? Icon(icon, size: 18, color: active ? Colors.white : const Color(0xFF64748B)) : Text(label!, style: TextStyle(color: active ? Colors.white : const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold))));
  }
}
