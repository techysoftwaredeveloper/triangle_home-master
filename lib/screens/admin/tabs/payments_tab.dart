import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
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

class _PaymentsTabState extends State<PaymentsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() => setState(() {}));
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

        // Filtering logic based on real data
        final filteredPayments =
            allPayments.where((p) {
              final matchesSearch =
                  (p['id']?.toString().toLowerCase().contains(_searchQuery) ??
                      false) ||
                  (p['bookingId']?.toString().toLowerCase().contains(
                        _searchQuery,
                      ) ??
                      false) ||
                  (p['userName']?.toString().toLowerCase().contains(
                        _searchQuery,
                      ) ??
                      false) ||
                  (p['propertyName']?.toString().toLowerCase().contains(
                        _searchQuery,
                      ) ??
                      false);

              final status = p['status']?.toString().toLowerCase() ?? '';
              final flow = p['flow']?.toString().toLowerCase() ?? '';

              switch (_tabController.index) {
                case 1:
                  return matchesSearch && flow.contains('hoster');
                case 2:
                  return matchesSearch && flow.contains('triangle');
                case 3:
                  return matchesSearch && status == 'pending';
                case 4:
                  return matchesSearch && status == 'refunded';
                case 5:
                  return matchesSearch && status == 'payout';
                default:
                  return matchesSearch;
              }
            }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSummaryRow(allPayments),
              const SizedBox(height: 64),
              _buildCategoryTabs(allPayments),
              const SizedBox(height: 24),
              _buildFilterRow(),
              const SizedBox(height: 24),
              _buildPolicyBanner(),
              const SizedBox(height: 32),

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
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              allPayments.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(),
                              ),
                            )
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
                    _buildTableHeader(),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        allPayments.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
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
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Payments',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                fontFamily: 'Outfit',
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage all payments, settlements and revenue',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildActionBtn(
              'Export',
              Icons.file_download_outlined,
              isOutline: true,
            ),
            const SizedBox(width: 16),
            _buildActionBtn('Filters', Icons.tune_rounded, hasDropdown: true),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    String label,
    IconData icon, {
    bool isOutline = false,
    bool hasDropdown = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOutline ? Colors.white : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(10),
        border: isOutline ? Border.all(color: const Color(0xFFE2E8F0)) : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isOutline ? const Color(0xFF64748B) : Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isOutline ? const Color(0xFF0F172A) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: isOutline ? const Color(0xFF64748B) : Colors.white,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<Map<String, dynamic>> payments) {
    double totalRevenue = 0;
    double platformEarnings = 0;
    double hosterShare = 0;
    int successCount = 0;
    int pendingCount = 0;
    int refundCount = 0;
    double totalRefunded = 0;
    double totalPayouts = 0;

    for (var p in payments) {
      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
      final status = p['status']?.toString().toLowerCase() ?? 'pending';
      final flow = p['flow']?.toString().toLowerCase() ?? '';

      if (status == 'success' || status == 'paid') {
        successCount++;
        totalRevenue += amount;
        if (flow.contains('triangle')) {
          platformEarnings += amount;
        } else if (flow.contains('hoster')) {
          hosterShare += amount;
        }
      } else if (status == 'pending') {
        pendingCount++;
      } else if (status == 'refunded') {
        refundCount++;
        totalRefunded += amount;
      } else if (status == 'payout') {
        totalPayouts += amount;
      }
    }

    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _PaymentMetricCard(
            label: 'Total Revenue',
            val: format.format(totalRevenue),
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF6366F1),
            bgColor: const Color(0xFFEEF2FF),
            trend: '18.3%',
            isTrendUp: true,
            breakdown: [
              {
                'label': 'Triangle Homes (Platform)',
                'val': format.format(platformEarnings),
              },
              {'label': 'Direct to Hosters', 'val': format.format(hosterShare)},
            ],
          ),
          const SizedBox(width: 16),
          _PaymentMetricCard(
            label: 'Successful Payments',
            val: successCount.toString(),
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            trend: '15.7%',
            isTrendUp: true,
            breakdown: [
              {'label': 'To Hosters', 'val': format.format(hosterShare)},
              {
                'label': 'Platform Earnings',
                'val': format.format(platformEarnings),
              },
            ],
          ),
          const SizedBox(width: 16),
          _PaymentMetricCard(
            label: 'Pending Payments',
            val: pendingCount.toString(),
            icon: Icons.hourglass_top_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFF7ED),
            trend: '6.8%',
            isTrendUp: false,
            breakdown: [
              {'label': 'To Hosters', 'val': '₹0'},
              {'label': 'Platform Earnings', 'val': '₹0'},
            ],
          ),
          const SizedBox(width: 16),
          _PaymentMetricCard(
            label: 'Refunds',
            val: refundCount.toString(),
            icon: Icons.refresh_rounded,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            trend: '5.1%',
            isTrendUp: false,
            breakdown: [
              {'label': 'Total Refunded', 'val': format.format(totalRefunded)},
            ],
          ),
          const SizedBox(width: 16),
          _PaymentMetricCard(
            label: 'Hoster Payouts',
            val: format.format(totalPayouts),
            icon: Icons.account_balance_rounded,
            iconColor: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
            trend: '17.9%',
            isTrendUp: true,
            breakdown: [
              {'label': 'Successful Payouts', 'val': '0'},
              {'label': 'Pending Payouts', 'val': '0'},
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> payments) {
    final hosterCount =
        payments
            .where(
              (p) =>
                  (p['flow'] ?? '').toString().toLowerCase().contains('hoster'),
            )
            .length;
    final platformCount =
        payments
            .where(
              (p) => (p['flow'] ?? '').toString().toLowerCase().contains(
                'triangle',
              ),
            )
            .length;
    final pendingCount = payments.where((p) => p['status'] == 'pending').length;
    final refundCount = payments.where((p) => p['status'] == 'refunded').length;
    final payoutCount = payments.where((p) => p['status'] == 'payout').length;

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
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFamily: 'Outfit',
        ),
        tabs: [
          Tab(text: 'All Transactions (${payments.length})'),
          Tab(text: 'To Hosters ($hosterCount)'),
          Tab(text: 'Platform Earnings ($platformCount)'),
          Tab(text: 'Pending ($pendingCount)'),
          Tab(text: 'Refunds ($refundCount)'),
          Tab(text: 'Payouts ($payoutCount)'),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged:
                                (val) => setState(() => _searchQuery = val),
                            decoration: const InputDecoration(
                              hintText:
                                  'Search by Transaction ID, Booking ID, User, Property...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                        if (!isCompact)
                          const Text(
                            '⌘ K',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 16),
                  _buildSmallFilter('Status'),
                  const SizedBox(width: 16),
                  _buildSmallFilter('Payment Type'),
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
                    _buildSmallFilter('Status'),
                    const SizedBox(width: 12),
                    _buildSmallFilter('Payment Type'),
                    const SizedBox(width: 12),
                  ],
                  _buildSmallFilter('User Type'),
                  const SizedBox(width: 12),
                  _buildSmallFilter(
                    'Date Range',
                    icon: Icons.calendar_month_outlined,
                  ),
                  const SizedBox(width: 12),
                  _buildSmallFilter('Newest First', icon: Icons.sort_rounded),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallFilter(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 800;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child:
              isCompact
                  ? Column(
                    children: [
                      _policyItem(
                        Icons.school_outlined,
                        'Student Booking Policy',
                        'Minimum stay: 1 Month (30 Nights)\nPayment is collected monthly in advance.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Color(0xFFE2E8F0)),
                      ),
                      _policyItem(
                        Icons.work_outline_rounded,
                        'Professional Booking Policy',
                        'Minimum stay: 3 Days (2 Nights)\nPayment is collected in advance.',
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            'Learn More',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(
                        child: _policyItem(
                          Icons.school_outlined,
                          'Student Booking Policy',
                          'Minimum stay: 1 Month (30 Nights)\nPayment is collected monthly in advance.',
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        child: _policyItem(
                          Icons.work_outline_rounded,
                          'Professional Booking Policy',
                          'Minimum stay: 3 Days (2 Nights)\nPayment is collected in advance.',
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Text(
                        'Learn More',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
        );
      },
    );
  }

  Widget _policyItem(IconData icon, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
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
          Expanded(flex: 3, child: _headerLabel('TRANSACTION')),
          Expanded(flex: 3, child: _headerLabel('BOOKING / PROPERTY')),
          Expanded(flex: 2, child: _headerLabel('USER & TYPE')),
          Expanded(flex: 2, child: _headerLabel('DURATION')),
          Expanded(flex: 2, child: _headerLabel('PAYMENT FLOW')),
          Expanded(flex: 2, child: _headerLabel('AMOUNT')),
          Expanded(flex: 2, child: _headerLabel('STATUS')),
          Expanded(flex: 2, child: _headerLabel('DATE & TIME')),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _headerLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> items) {
    return Column(
      children: items.map((item) => _TransactionTableCard(item: item)).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: const Text(
        'No matching transactions found',
        style: TextStyle(color: Color(0xFF64748B)),
      ),
    );
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
                Flexible(
                  child: Text(
                    isCompact
                        ? '1-${count < 10 ? count : 10} of $count'
                        : 'Showing 1 to ${count < 10 ? count : 10} of $count transactions',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                  if (!isCompact) ...[
                    _PageBtn(label: '3'),
                    _PageBtn(label: '4'),
                    _PageBtn(label: '5'),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '...',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                  _PageBtn(label: '42'),
                  _PageBtn(icon: Icons.chevron_right),
                  if (isCompact) ...[
                    const SizedBox(width: 16),
                    _buildPageSizeSelector(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
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
          Text(
            '10 / page',
            style: TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
          ),
          SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
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
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Flow Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: hosterPct,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFF6366F1),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      format.format(totalRevenue),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Total Revenue',
                      style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _chartLegend(
            'Direct to Hoster',
            format.format(directToHoster),
            '${(hosterPct * 100).toStringAsFixed(1)}%',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _chartLegend(
            'Paid to Triangle Homes',
            format.format(triangleHomes),
            '${((1 - hosterPct) * 100).toStringAsFixed(1)}%',
            const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, String val, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        Text(
          val,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($pct)',
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
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

    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Distribution',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          _distRow(
            Icons.account_balance_rounded,
            'Direct to Hosters',
            format.format(directToHoster),
            totalRevenue > 0
                ? '${((directToHoster / totalRevenue) * 100).toStringAsFixed(1)}%'
                : '0%',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 20),
          _distRow(
            Icons.change_history_rounded,
            'Triangle Homes (Platform)',
            format.format(triangleHomes),
            totalRevenue > 0
                ? '${((triangleHomes / totalRevenue) * 100).toStringAsFixed(1)}%'
                : '0%',
            const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _distRow(
    IconData icon,
    String label,
    String val,
    String pct,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                pct,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        Text(
          val,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
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

    final sortedHosters =
        hosterPayouts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedHosters.take(5).toList();
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Hosters (Payouts)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          if (top5.isEmpty)
            const Text(
              'No data available',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            )
          else
            ...List.generate(
              top5.length,
              (i) => _hosterPayoutRow(
                i + 1,
                top5[i].key,
                format.format(top5[i].value),
                'Paid',
              ),
            ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'View All Hosters →',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hosterPayoutRow(int rank, String name, String amount, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            status,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
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

    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          if (methodTotals.isEmpty)
            const Text(
              'No data available',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            )
          else
            ...methodTotals.entries.map(
              (e) => _methodRow(
                e.key,
                format.format(e.value),
                total > 0
                    ? '${((e.value / total) * 100).toStringAsFixed(1)}%'
                    : '0%',
              ),
            ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'View All Methods →',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodRow(String label, String amount, String pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            pct,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCharts(List<Map<String, dynamic>> payments) {
    return Row(
      children: [
        Expanded(
          child: _miniChart('Revenue Trend', '₹4,83,250', '18.3%', true),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _miniChart('Platform Earnings', '₹1,85,250', '18.3%', true),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _miniChart('Payouts to Hosters', '₹2,92,500', '17.9%', true),
        ),
      ],
    );
  }

  Widget _miniChart(String title, String val, String trend, bool isUp) {
    return Container(
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const Text(
                'This Month',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_upward : Icons.arrow_downward,
                color: const Color(0xFF10B981),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' vs last month',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniSparklinePainter(
                color: isUp ? const Color(0xFF6366F1) : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '1 May',
                style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
              ),
              Text(
                '31 May',
                style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMetricCard extends StatelessWidget {
  final String label;
  final String val;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String trend;
  final bool isTrendUp;
  final List<Map<String, String>> breakdown;

  const _PaymentMetricCard({
    required this.label,
    required this.val,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.trend,
    required this.isTrendUp,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Row(
                children: [
                  Icon(
                    isTrendUp ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF10B981),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    ' vs last month',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            val,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          ...breakdown.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['label']!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b['val']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTableCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TransactionTableCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString().toLowerCase() ?? 'pending';
    final flow = item['flow']?.toString() ?? 'Direct to Hoster';
    final flowTarget =
        item['flowTarget'] ??
        (flow.contains('Hoster') ? item['propertyName'] : 'Triangle Homes');
    final amountFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final IconData flowIcon;
    final Color flowIconColor;
    if (status == 'refunded') {
      flowIcon = Icons.cancel_outlined;
      flowIconColor = const Color(0xFFEF4444);
    } else if (flow.contains('Payout')) {
      flowIcon = Icons.arrow_upward_rounded;
      flowIconColor = const Color(0xFF8B5CF6);
    } else {
      flowIcon = Icons.arrow_downward_rounded;
      flowIconColor = const Color(0xFF10B981);
    }

    return Container(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: flowIconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(flowIcon, color: flowIconColor, size: 16),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['id']?.toString().toUpperCase() ?? 'TXN-100567',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      item['method'] ?? 'UPI',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.business_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['propertyName'] ?? 'Sunrise Hostel',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['propertyType'] ?? 'PG / Hostel',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        item['bookingId'] ?? 'BK-10023',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                        ),
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
                  radius: 14,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Text(
                    (item['userName'] ?? 'U')[0],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['userName'] ?? 'John Doe',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['userRole'] ?? 'Student',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item['duration'] ?? 1} Month',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flow,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: flowIconColor,
                  ),
                ),
                Text(
                  flowTarget,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountFormat.format(item['amount'] ?? 6500),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Text(
                  'incl. Platform Fee',
                  style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusBg(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item['createdAt'] is Timestamp
                  ? '${DateFormat('dd MMM yyyy').format((item['createdAt'] as Timestamp).toDate())}\n${DateFormat('hh:mm a').format((item['createdAt'] as Timestamp).toDate())}'
                  : 'N/A',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
        ],
      ),
    );
  }

  Color _getStatusColor(String s) {
    if (s == 'success' || s == 'paid') return const Color(0xFF10B981);
    if (s == 'pending') return const Color(0xFFF59E0B);
    if (s == 'refunded') return const Color(0xFFEF4444);
    return Colors.grey;
  }

  Color _getStatusBg(String s) {
    if (s == 'success' || s == 'paid') return const Color(0xFFECFDF5);
    if (s == 'pending') return const Color(0xFFFFF7ED);
    if (s == 'refunded') return const Color(0xFFFEF2F2);
    return const Color(0xFFF1F5F9);
  }
}

class _PageBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool active;
  const _PageBtn({this.label, this.icon, this.active = false});

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
        child:
            icon != null
                ? Icon(
                  icon,
                  size: 18,
                  color: active ? Colors.white : const Color(0xFF64748B),
                )
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

class _MiniSparklinePainter extends CustomPainter {
  final Color color;
  _MiniSparklinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.1);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
