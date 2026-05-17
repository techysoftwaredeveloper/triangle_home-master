import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentsTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const PaymentsTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
      stream: widget.adminService.getPaymentsStream(),
      builder: (context, snapshot) {
        final allPayments = snapshot.data ?? [];

        // Filtering logic
        final filteredPayments = allPayments.where((p) {
          final matchesSearch = (p['id']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (p['bookingId']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (p['userName']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (p['propertyName']?.toString().toLowerCase().contains(_searchQuery) ?? false);

          final status = p['status']?.toString().toLowerCase() ?? '';
          final flow = p['flow']?.toString().toLowerCase() ?? '';

          switch (_tabController.index) {
            case 1: return matchesSearch && flow.contains('hoster');
            case 2: return matchesSearch && flow.contains('triangle');
            case 3: return matchesSearch && status == 'pending';
            case 4: return matchesSearch && status == 'refunded';
            case 5: return matchesSearch && status == 'paid';
            default: return matchesSearch;
          }
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabHeader(
                title: 'Payments',
                subtitle: 'Manage all payments, settlements and revenue',
                isNarrow: widget.isNarrow,
                actions: [
                  _buildHeaderAction('Export', Icons.file_download_outlined, isOutline: true, onPressed: _handleExport),
                  const SizedBox(width: 12),
                  _buildHeaderAction('Filters', Icons.tune_rounded, hasDropdown: true),
                ],
              ),
              const SizedBox(height: 32),
              _buildSummaryCards(allPayments),
              const SizedBox(height: 32),
              _buildCategoryTabs(allPayments),
              const SizedBox(height: 24),
              _buildFilterRow(),
              const SizedBox(height: 24),
              _buildPolicyBar(),
              const SizedBox(height: 24),

              if (!widget.isNarrow)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildTableHeader(),
                          const SizedBox(height: 12),
                          if (snapshot.connectionState == ConnectionState.waiting && allPayments.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                          else if (filteredPayments.isEmpty)
                            _buildEmptyState()
                          else
                            _buildTransactionList(filteredPayments),
                          const SizedBox(height: 32),
                          _buildPaginationFooter(filteredPayments.length),
                          const SizedBox(height: 48),
                          _buildTrendCharts(allPayments),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildFlowOverview(allPayments),
                          const SizedBox(height: 24),
                          _buildRevenueDistribution(allPayments),
                          const SizedBox(height: 24),
                          _buildTopHosters(allPayments),
                          const SizedBox(height: 24),
                          _buildPaymentMethods(allPayments),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    if (snapshot.connectionState == ConnectionState.waiting && allPayments.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    else if (filteredPayments.isEmpty)
                      _buildEmptyState()
                    else
                      _buildTransactionList(filteredPayments),
                    const SizedBox(height: 32),
                    _buildPaginationFooter(filteredPayments.length),
                    const SizedBox(height: 48),
                    _buildTrendCharts(allPayments),
                    const SizedBox(height: 32),
                    _buildFlowOverview(allPayments),
                    const SizedBox(height: 24),
                    _buildRevenueDistribution(allPayments),
                    const SizedBox(height: 24),
                    _buildTopHosters(allPayments),
                    const SizedBox(height: 24),
                    _buildPaymentMethods(allPayments),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No transactions found matching your criteria', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting payment ledger to CSV...'), backgroundColor: Color(0xFF2563EB)),
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

  Widget _buildSummaryCards(List<Map<String, dynamic>> payments) {
    double totalRevenue = 0;
    double platformEarnings = 0;
    double hosterShare = 0;
    int successCount = 0;
    int pendingCount = 0;
    int refundCount = 0;
    double totalRefunded = 0;

    for (var p in payments) {
      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
      final status = p['status']?.toString().toLowerCase() ?? 'pending';
      final flow = p['flow']?.toString().toLowerCase() ?? '';

      if (status == 'success' || status == 'paid') {
        successCount++;
        totalRevenue += amount;
        if (flow.contains('triangle')) {
          platformEarnings += amount;
        } else {
          hosterShare += amount;
        }
      } else if (status == 'pending') {
        pendingCount++;
      } else if (status == 'refunded') {
        refundCount++;
        totalRefunded += amount;
      }
    }

    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildMetricCard(
            format.format(totalRevenue), 'Total Revenue',
            const Color(0xFFEFF6FF), const Color(0xFF2563EB), Icons.account_balance_wallet_rounded,
            percentage: '18.3%', isUp: true,
            breakdown: [
              {'label': 'Triangle Homes', 'val': format.format(platformEarnings)},
              {'label': 'Direct to Hosters', 'val': format.format(hosterShare)},
            ]
          ),
          const SizedBox(width: 16),
          _buildMetricCard(
            successCount.toString(), 'Successful Payments',
            const Color(0xFFF0FDF4), const Color(0xFF16A34A), Icons.check_circle_rounded,
            percentage: '15.7%', isUp: true,
            breakdown: [
              {'label': 'To Hosters', 'val': format.format(hosterShare)},
              {'label': 'Platform Earnings', 'val': format.format(platformEarnings)},
            ]
          ),
          const SizedBox(width: 16),
          _buildMetricCard(
            pendingCount.toString(), 'Pending Payments',
            const Color(0xFFFFFBEB), const Color(0xFFD97706), Icons.hourglass_top_rounded,
            percentage: '6.8%', isUp: false,
            breakdown: [
              {'label': 'Awaiting Verification', 'val': 'Action Required'},
            ]
          ),
          const SizedBox(width: 16),
          _buildMetricCard(
            refundCount.toString(), 'Refunds',
            const Color(0xFFF5F3FF), const Color(0xFF7C3AED), Icons.restart_alt_rounded,
            percentage: '5.1%', isUp: false,
            breakdown: [
              {'label': 'Total Refunded', 'val': format.format(totalRefunded)},
            ]
          ),
          const SizedBox(width: 16),
          _buildMetricCard(
            format.format(hosterShare), 'Hoster Payouts',
            const Color(0xFFFEF2F2), const Color(0xFFDC2626), Icons.account_balance_rounded,
            percentage: '17.9%', isUp: true,
            breakdown: [
              {'label': 'Completed Shares', 'val': format.format(hosterShare)},
            ]
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String val, String label, Color bg, Color color, IconData icon, {String? percentage, bool? isUp, required List<Map<String, String>> breakdown}) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              if (percentage != null)
                Row(
                  children: [
                    Icon(isUp == false ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.green, size: 14),
                    Text(percentage, style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                    const Text(' vs last month', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          ...breakdown.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b['label']!, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                Text(b['val']!, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> payments) {
    final hosterCount = payments.where((p) => (p['flow'] ?? '').toString().toLowerCase().contains('hoster')).length;
    final triangleCount = payments.where((p) => (p['flow'] ?? '').toString().toLowerCase().contains('triangle')).length;
    final pendingCount = payments.where((p) => p['status'] == 'pending').length;
    final refundCount = payments.where((p) => p['status'] == 'refunded').length;

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
          Tab(text: 'All Transactions (${payments.length})'),
          Tab(text: 'To Hosters ($hosterCount)'),
          Tab(text: 'Platform Earnings ($triangleCount)'),
          Tab(text: 'Pending ($pendingCount)'),
          Tab(text: 'Refunds ($refundCount)'),
          const Tab(text: 'Payouts (0)'),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: widget.isNarrow ? 'Search payments...' : 'Search by Transaction ID, Booking ID, User...',
                      border: InputBorder.none,
                      hintStyle: const TextStyle(fontSize: 12)
                    )
                  )
                ),
                if (!widget.isNarrow) const Text('⌘ K', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildSmallFilter(widget.isNarrow ? '' : 'Status', icon: Icons.tune),
        if (!widget.isNarrow) ...[
          const SizedBox(width: 12),
          _buildSmallFilter('Payment Type'),
          const SizedBox(width: 12),
          _buildSmallFilter('User Type'),
          const SizedBox(width: 12),
          _buildSmallFilter('Date Range', icon: Icons.calendar_month_outlined),
          const SizedBox(width: 12),
          _buildSmallFilter('Newest First', icon: Icons.sort_rounded),
        ],
      ],
    );
  }

  Widget _buildSmallFilter(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: const Color(0xFF64748B)), const SizedBox(width: 8)],
          if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildPolicyBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: widget.isNarrow
        ? Column(
            children: [
              _policyItem(Icons.school_outlined, 'Student Policy', 'Min stay: 1 Month'),
              const SizedBox(height: 12),
              _policyItem(Icons.work_outline_rounded, 'Pro Policy', 'Min stay: 3 Days'),
            ],
          )
        : Row(
            children: [
              _policyItem(Icons.school_outlined, 'Student Booking Policy', 'Minimum stay: 1 Month (30 Nights)\nPayment is collected monthly in advance.'),
              _verticalDivider(),
              _policyItem(Icons.work_outline_rounded, 'Professional Booking Policy', 'Minimum stay: 3 Days (2 Nights)\nPayment is collected in advance.'),
              const Spacer(),
              const Text('Learn More', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2563EB)),
            ],
          ),
    );
  }

  Widget _policyItem(IconData icon, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
            Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4)),
          ],
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 40, width: 1, margin: const EdgeInsets.symmetric(horizontal: 32), color: const Color(0xFFE2E8F0));
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 3, child: _tableLabel('TRANSACTION')),
          Expanded(flex: 3, child: _tableLabel('BOOKING / PROPERTY')),
          Expanded(flex: 2, child: _tableLabel('USER & TYPE')),
          Expanded(flex: 2, child: _tableLabel('DURATION')),
          Expanded(flex: 2, child: _tableLabel('PAYMENT FLOW')),
          Expanded(flex: 2, child: _tableLabel('AMOUNT')),
          Expanded(flex: 2, child: _tableLabel('STATUS')),
          Expanded(flex: 2, child: _tableLabel('DATE & TIME')),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _tableLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5));
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> payments) {
    return Column(
      children: payments.map((p) => _TransactionRow(
        txId: p['id']?.toString().toUpperCase() ?? 'TXN-NEW',
        method: p['method'] ?? 'UPI',
        property: p['propertyName'] ?? 'Untitled Property',
        bookingId: p['bookingId'] ?? 'N/A',
        user: p['userName'] ?? 'Unknown User',
        userType: p['userRole'] ?? 'Student',
        duration: '${p['duration'] ?? 1} Month',
        flow: p['flow'] ?? 'Direct to Hoster',
        flowTarget: p['flowTarget'] ?? 'Hoster',
        amount: '₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(p['amount'] ?? 0)}',
        status: (p['status'] ?? 'PENDING').toString().toUpperCase(),
        statusColor: _getStatusColor(p['status']),
        dateTime: _formatDateTime(p['createdAt']),
        icon: _getFlowIcon(p['status']),
        iconColor: _getStatusColor(p['status']),
        isNarrow: widget.isNarrow,
      )).toList(),
    );
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'success' || status == 'paid') return Colors.green;
    if (status == 'pending') return Colors.orange;
    if (status == 'refunded') return Colors.red;
    return Colors.grey;
  }

  IconData _getFlowIcon(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'refunded') return Icons.refresh_rounded;
    if (status == 'pending') return Icons.access_time_rounded;
    return Icons.arrow_downward_rounded;
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return '${DateFormat('dd MMM yyyy').format(date.toDate())}\n${DateFormat('hh:mm a').format(date.toDate())}';
    }
    return date.toString();
  }

  Widget _buildPaginationFooter(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.isNarrow ? '1-$count of $count' : 'Showing 1 to $count of $count transactions',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            const PaginationBtn(icon: Icons.chevron_left),
            const PaginationBtn(label: '1', active: true),
            const PaginationBtn(icon: Icons.chevron_right),
            if (!widget.isNarrow) ...[
                const SizedBox(width: 16),
                _pageSizeSelector(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _pageSizeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: const [
          Text('10 / page', style: TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
          SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildTrendCharts(List<Map<String, dynamic>> payments) {
    double totalRevenue = 0;
    double platformEarnings = 0;
    double hosterShare = 0;

    for (var p in payments) {
      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
      final status = p['status']?.toString().toLowerCase() ?? 'pending';
      final flow = p['flow']?.toString().toLowerCase() ?? '';

      if (status == 'success' || status == 'paid') {
        totalRevenue += amount;
        if (flow.contains('triangle')) {
          platformEarnings += amount;
        } else {
          hosterShare += amount;
        }
      }
    }

    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final charts = [
      _trendChart('Revenue Trend', format.format(totalRevenue), '18.3%', true),
      _trendChart('Platform Earnings', format.format(platformEarnings), '18.3%', true),
      _trendChart('Payouts to Hosters', format.format(hosterShare), '17.9%', true),
    ];

    if (widget.isNarrow) {
      return Column(
        children: charts.map((c) => Padding(padding: const EdgeInsets.only(bottom: 24), child: SizedBox(width: double.infinity, child: c))).toList(),
      );
    }

    return Row(
      children: charts.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 24), child: c))).toList(),
    );
  }

  Widget _trendChart(String title, String val, String change, bool isUp) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const Text('This Month', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Row(
            children: [
              Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.green, size: 12),
              Text(change, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              const Text(' vs last month', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.show_chart_rounded, color: Color(0xFFCBD5E1)))),
        ],
      ),
    );
  }

  Widget _buildFlowOverview(List<Map<String, dynamic>> payments) {
    double totalRevenue = 0;
    double directToHoster = 0;
    double triangleHomes = 0;

    for (var p in payments) {
      final status = p['status']?.toString().toLowerCase() ?? 'pending';
      if (status == 'success' || status == 'paid') {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0;
        final flow = p['flow']?.toString().toLowerCase() ?? '';
        totalRevenue += amount;
        if (flow.contains('hoster')) {
          directToHoster += amount;
        } else {
          triangleHomes += amount;
        }
      }
    }

    final hosterPct = totalRevenue > 0 ? (directToHoster / totalRevenue) : 0.0;
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Flow Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 140, height: 140, child: CircularProgressIndicator(value: hosterPct.toDouble(), strokeWidth: 12, backgroundColor: const Color(0xFF8B5CF6), valueColor: const AlwaysStoppedAnimation(Color(0xFF22C55E)))),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(format.format(totalRevenue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const Text('Total Revenue', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _flowLeg('Direct to Hoster', '${format.format(directToHoster)} (${(hosterPct * 100).toStringAsFixed(1)}%)', const Color(0xFF22C55E)),
          const SizedBox(height: 12),
          _flowLeg('Paid to Triangle Homes', '${format.format(triangleHomes)} (${((1 - hosterPct) * 100).toStringAsFixed(1)}%)', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _flowLeg(String label, String val, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
      ],
    );
  }

  Widget _buildRevenueDistribution(List<Map<String, dynamic>> payments) {
    double totalRevenue = 0;
    double directToHoster = 0;
    double triangleHomes = 0;

    for (var p in payments) {
      final status = p['status']?.toString().toLowerCase() ?? 'pending';
      if (status == 'success' || status == 'paid') {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0;
        final flow = p['flow']?.toString().toLowerCase() ?? '';
        totalRevenue += amount;
        if (flow.contains('hoster')) {
          directToHoster += amount;
        } else {
          triangleHomes += amount;
        }
      }
    }

    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          _distItem(Icons.payments_outlined, 'Direct to Hosters', format.format(directToHoster), totalRevenue > 0 ? '${((directToHoster/totalRevenue)*100).toStringAsFixed(1)}%' : '0%', Colors.green),
          const SizedBox(height: 16),
          _distItem(Icons.change_history_rounded, 'Triangle Homes (Platform)', format.format(triangleHomes), totalRevenue > 0 ? '${((triangleHomes/totalRevenue)*100).toStringAsFixed(1)}%' : '0%', Colors.purple),
        ],
      ),
    );
  }

  Widget _distItem(IconData icon, String label, String val, String pct, Color color) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), Text(pct, style: TextStyle(fontSize: 10, color: Colors.grey.shade400))])),
        const SizedBox(width: 8),
        FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildTopHosters(List<Map<String, dynamic>> payments) {
    final Map<String, double> hosterPayouts = {};
    for (var p in payments) {
      final status = p['status']?.toString().toLowerCase() ?? 'pending';
      if (status == 'success' || status == 'paid') {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0;
        final name = p['propertyName'] ?? 'Untitled';
        hosterPayouts[name] = (hosterPayouts[name] ?? 0) + amount;
      }
    }

    final sortedHosters = hosterPayouts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedHosters.take(5).toList();
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Hosters (Payouts)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          if (top5.isEmpty)
            const Text('No payout data available', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ...List.generate(top5.length, (index) => _hosterRank(index + 1, top5[index].key, format.format(top5[index].value), 'Paid')),
          const SizedBox(height: 16),
          const Center(child: Text('View All Hosters →', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _hosterRank(int rank, String name, String val, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: Center(child: Text(rank.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          FittedBox(fit: BoxFit.scaleDown, child: Text(status, style: TextStyle(fontSize: 10, color: status == 'Paid' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(List<Map<String, dynamic>> payments) {
    final Map<String, double> methodTotals = {};
    double total = 0;
    for (var p in payments) {
      final status = p['status']?.toString().toLowerCase() ?? 'pending';
      if (status == 'success' || status == 'paid') {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0;
        final method = p['method'] ?? 'UPI';
        methodTotals[method] = (methodTotals[method] ?? 0) + amount;
        total += amount;
      }
    }

    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Methods', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          if (methodTotals.isEmpty)
             const Text('No method data available', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ...methodTotals.entries.map((e) => _methodRow(e.key, format.format(e.value), total > 0 ? '${((e.value/total)*100).toStringAsFixed(1)}%' : '0%', Colors.blue)),
          const SizedBox(height: 16),
          const Center(child: Text('View All Methods →', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _methodRow(String label, String val, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Text(pct, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String txId;
  final String method;
  final String property;
  final String bookingId;
  final String user;
  final String userType;
  final String duration;
  final String flow;
  final String flowTarget;
  final String amount;
  final String status;
  final Color statusColor;
  final String dateTime;
  final IconData icon;
  final Color iconColor;
  final bool isNarrow;

  const _TransactionRow({
    required this.txId,
    required this.method,
    required this.property,
    required this.bookingId,
    required this.user,
    required this.userType,
    required this.duration,
    required this.flow,
    required this.flowTarget,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.dateTime,
    required this.icon,
    required this.iconColor,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: isNarrow
        ? Column(
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 14)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(txId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text(method, style: const TextStyle(fontSize: 9, color: Colors.grey))])),
                  Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(property, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  StatusBadge(text: status, color: statusColor),
                ],
              ),
            ],
          )
        : Row(
            children: [
              // 1. Transaction
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 16)),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(txId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text(method, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
                  ],
                ),
              ),
              // 2. Booking / Property
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.business_rounded, color: Colors.grey, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(property, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), Text(bookingId, style: const TextStyle(fontSize: 10, color: Colors.grey))])),
                  ],
                ),
              ),
              // 3. User & Type
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: const Color(0xFFF1F5F9), child: Text(user.isNotEmpty ? user[0] : 'U', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), if(userType.isNotEmpty) Text(userType, style: TextStyle(fontSize: 9, color: userType == 'Student' ? Colors.blue : Colors.purple, fontWeight: FontWeight.bold))])),
                  ],
                ),
              ),
              // 4. Duration
              Expanded(flex: 2, child: Text(duration, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              // 5. Payment Flow
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(flow, style: TextStyle(fontSize: 9, color: flow.toLowerCase().contains('direct') ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
                    Text(flowTarget, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                  ],
                ),
              ),
              // 6. Amount
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), const Text('incl. Platform Fee', style: TextStyle(fontSize: 8, color: Colors.grey))])),
              // 7. Status
              Expanded(flex: 2, child: Center(child: StatusBadge(text: status, color: statusColor))),
              // 8. Date & Time
              Expanded(flex: 2, child: Text(dateTime, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))),
              const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
            ],
          ),
    );
  }
}

