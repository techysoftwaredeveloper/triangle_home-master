import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const ReportTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      stream: widget.adminService.getReportsStream(),
      builder: (context, snapshot) {
        final allReports = snapshot.data ?? [];

        // Filtering
        final filteredReports = allReports.where((r) {
          final matchesSearch = (r['id']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (r['title']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (r['reporterName']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (r['targetName']?.toString().toLowerCase().contains(_searchQuery) ?? false);

          final status = r['status']?.toString().toLowerCase() ?? 'pending';

          switch (_tabController.index) {
            case 1: return matchesSearch && status == 'pending';
            case 2: return matchesSearch && status == 'resolved';
            case 3: return matchesSearch && status == 'rejected';
            default: return matchesSearch;
          }
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabHeader(
                title: 'Reports',
                subtitle: 'Monitor issues, activities and platform health',
                isNarrow: widget.isNarrow,
                actions: [
                  _buildHeaderAction('Export', Icons.file_download_outlined, isOutline: true, onPressed: _handleExport),
                  const SizedBox(width: 12),
                  _buildHeaderAction('Filters', Icons.tune_rounded, hasDropdown: true),
                ],
              ),
              const SizedBox(height: 32),
              _buildSummaryCards(allReports),
              const SizedBox(height: 32),
              _buildCategoryTabs(allReports),
              const SizedBox(height: 24),
              _buildFilterRow(),
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
                          if (snapshot.connectionState == ConnectionState.waiting && allReports.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                          else if (filteredReports.isEmpty)
                            _buildEmptyState()
                          else
                            _buildReportsList(filteredReports),
                          const SizedBox(height: 32),
                          _buildPaginationFooter(filteredReports.length),
                          const SizedBox(height: 48),
                          _buildAnalyticsRow(allReports),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildReportSummaryStats(allReports),
                          const SizedBox(height: 24),
                          _buildReportsByType(allReports),
                          const SizedBox(height: 24),
                          _buildTopReportedProperties(allReports),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    if (snapshot.connectionState == ConnectionState.waiting && allReports.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    else if (filteredReports.isEmpty)
                      _buildEmptyState()
                    else
                      _buildReportsList(filteredReports),
                    const SizedBox(height: 32),
                    _buildPaginationFooter(filteredReports.length),
                    const SizedBox(height: 32),
                    _buildReportSummaryStats(allReports),
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
          Icon(Icons.checklist_rtl_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No reports found matching your criteria', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting report audit log...'), backgroundColor: Color(0xFF2563EB)),
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
            Text(label, style: TextStyle(color: isOutline ? const Color(0xFF1E293B) : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            if (hasDropdown) ...[
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: isOutline ? const Color(0xFF64748B) : Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> reports) {
    final pending = reports.where((r) => (r['status'] ?? '').toString().toLowerCase() == 'pending').length;
    final resolved = reports.where((r) => (r['status'] ?? '').toString().toLowerCase() == 'resolved').length;
    final rejected = reports.where((r) => (r['status'] ?? '').toString().toLowerCase() == 'rejected').length;

    final double cardWidth = widget.isNarrow ? 160 : 220;
    final double cardHeight = widget.isNarrow ? 140 : 180;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(count: reports.length.toString(), label: 'Total Reports', bg: const Color(0xFFFEF2F2), color: const Color(0xFFEF4444), icon: Icons.flag_rounded, percentage: '12.5%', isUp: false)),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(count: pending.toString(), label: 'Pending Review', bg: const Color(0xFFFFFBEB), color: const Color(0xFFD97706), icon: Icons.timer_outlined, percentage: '10.0%', isUp: false)),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(count: resolved.toString(), label: 'Resolved', bg: const Color(0xFFF0FDF4), color: const Color(0xFF16A34A), icon: Icons.check_circle_outline_rounded, percentage: '21.7%', isUp: true)),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(count: rejected.toString(), label: 'Rejected', bg: const Color(0xFFF1F5F9), color: const Color(0xFF64748B), icon: Icons.cancel_outlined, percentage: '14.2%', isUp: false)),
          const SizedBox(width: 16),
          _wrapInSizedBox(cardWidth, cardHeight, SummaryCard(count: '4.8', label: 'Avg. Res. (Days)', bg: const Color(0xFFEFF6FF), color: const Color(0xFF2563EB), icon: Icons.speed_rounded, percentage: '8.6%', isUp: true)),
        ],
      ),
    );
  }

  Widget _wrapInSizedBox(double w, double h, Widget child) => SizedBox(width: w, height: h, child: child);

  Widget _buildCategoryTabs(List<Map<String, dynamic>> reports) {
    int pending = 0;
    int resolved = 0;
    int rejected = 0;

    for (var r in reports) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      if (status == 'pending') {
        pending++;
      } else if (status == 'resolved') {
        resolved++;
      } else if (status == 'rejected') {
        rejected++;
      }
    }

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
          Tab(text: 'All Reports (${reports.length})'),
          Tab(text: 'Pending ($pending)'),
          Tab(text: 'Resolved ($resolved)'),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: widget.isNarrow ? 'Search...' : 'Search by report ID, title, user or property...',
                      border: InputBorder.none,
                      hintStyle: const TextStyle(fontSize: 12)
                    )
                  )
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildSmallFilter(widget.isNarrow ? '' : 'Report Type', icon: Icons.tune),
        if (!widget.isNarrow) ...[
          const SizedBox(width: 12),
          _buildSmallFilter('Status'),
          const SizedBox(width: 12),
          _buildSmallFilter('Date Range', icon: Icons.calendar_month_outlined),
          const SizedBox(width: 12),
          _buildSmallFilter('Priority'),
          const SizedBox(width: 12),
          _buildSmallFilter('More Filters'),
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
          if (icon != null) ...[Icon(icon, size: 16, color: const Color(0xFF64748B)), if (label.isNotEmpty) const SizedBox(width: 8)],
          if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _tableLabel('REPORT')),
          Expanded(flex: 2, child: _tableLabel('TYPE')),
          Expanded(flex: 2, child: _tableLabel('REPORTED BY')),
          Expanded(flex: 3, child: _tableLabel('AGAINST')),
          Expanded(flex: 2, child: _tableLabel('PRIORITY')),
          Expanded(flex: 2, child: _tableLabel('STATUS')),
          Expanded(flex: 2, child: _tableLabel('DATE')),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _tableLabel(String text) => Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5));

  Widget _buildReportsList(List<Map<String, dynamic>> reports) {
    return Column(
      children: reports.map((r) => _ReportRow(
        id: r['id']?.toString().toUpperCase() ?? 'RPT-NEW',
        title: r['title'] ?? 'Untitled Issue',
        category: r['category'] ?? 'General Report',
        type: r['type'] ?? 'Issue',
        typeColor: _getTypeColor(r['type']),
        user: r['reporterName'] ?? 'Unknown',
        userType: r['reporterRole'] ?? 'User',
        target: r['targetName'] ?? 'Platform Content',
        targetId: r['targetId']?.toString().toUpperCase() ?? '',
        priority: _formatPriority(r['priority']),
        priorityColor: _getPriorityColor(r['priority']),
        status: _formatStatus(r['status']),
        statusColor: _getStatusColor(r['status']),
        date: _formatDateTime(r['createdAt']),
        isNarrow: widget.isNarrow,
        onAction: (action) => _handleReportAction(r['id'], action),
      )).toList(),
    );
  }

  Color _getTypeColor(dynamic type) {
    final t = type?.toString().toLowerCase() ?? '';
    if (t.contains('listing') || t.contains('fake')) return Colors.red;
    if (t.contains('user') || t.contains('inappropriate')) return Colors.orange;
    if (t.contains('maintenance')) return Colors.blue;
    if (t.contains('payment')) return Colors.purple;
    return Colors.grey;
  }

  String _formatPriority(dynamic p) {
    final pr = p?.toString().toLowerCase() ?? 'medium';
    return pr[0].toUpperCase() + pr.substring(1);
  }

  Color _getPriorityColor(dynamic p) {
    final pr = p?.toString().toLowerCase() ?? 'medium';
    if (pr == 'high') return Colors.red;
    if (pr == 'low') return Colors.blue;
    return Colors.orange;
  }

  String _formatStatus(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'pending') return 'Pending';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'resolved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      final d = date.toDate();
      return '${DateFormat('dd MMM yyyy').format(d)}\n${DateFormat('hh:mm a').format(d)}';
    }
    return date.toString();
  }

  void _handleReportAction(String id, String action) async {
    try {
      await widget.adminService.updateReportStatus(id, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report updated to $action'), backgroundColor: Colors.green),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.isNarrow ? '1-$count of $count' : 'Showing 1 to $count of $count reports', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Row(
          children: [
            const PaginationBtn(icon: Icons.chevron_left),
            const PaginationBtn(label: '1', active: true),
            const PaginationBtn(icon: Icons.chevron_right),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsRow(List<Map<String, dynamic>> reports) {
    return Row(
      children: [
        _analyticsChart('Reports Trend', Icons.show_chart_rounded),
        const SizedBox(width: 24),
        _analyticsChart('Reports by Priority', Icons.pie_chart_rounded),
        const SizedBox(width: 24),
        _analyticsChart('Average Resolution Time', Icons.speed_rounded),
      ],
    );
  }

  Widget _analyticsChart(String title, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))), const Icon(Icons.more_horiz, size: 18, color: Colors.grey)]),
            const SizedBox(height: 24),
            Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)), child: Center(child: Icon(icon, color: const Color(0xFFCBD5E1), size: 40))),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSummaryStats(List<Map<String, dynamic>> reports) {
    int pending = 0;
    int resolved = 0;
    int rejected = 0;
    int inProgress = 0;

    for (var r in reports) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      if (status == 'pending') {
        pending++;
      } else if (status == 'resolved') {
        resolved++;
      } else if (status == 'rejected') {
        rejected++;
      } else if (status.contains('progress')) {
        inProgress++;
      }
    }

    final resolvedPct = reports.isNotEmpty ? (resolved / reports.length) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Report Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 140, height: 140, child: CircularProgressIndicator(value: resolvedPct.toDouble(), strokeWidth: 12, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)))),
                Column(mainAxisSize: MainAxisSize.min, children: [Text(reports.length.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const Text('Total Reports', style: TextStyle(fontSize: 9, color: Colors.grey))]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _summaryLeg('Pending', '$pending (${reports.isNotEmpty ? ((pending/reports.length)*100).toStringAsFixed(1) : 0}%)', Colors.orange),
          _summaryLeg('Resolved', '$resolved (${reports.isNotEmpty ? ((resolved/reports.length)*100).toStringAsFixed(1) : 0}%)', Colors.green),
          _summaryLeg('Rejected', '$rejected (${reports.isNotEmpty ? ((rejected/reports.length)*100).toStringAsFixed(1) : 0}%)', Colors.red),
          _summaryLeg('In Progress', '$inProgress (${reports.isNotEmpty ? ((inProgress/reports.length)*100).toStringAsFixed(1) : 0}%)', Colors.blue),
        ],
      ),
    );
  }

  Widget _summaryLeg(String l, String v, Color c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 12), Text(l, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))), const Spacer(), Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));

  Widget _buildReportsByType(List<Map<String, dynamic>> reports) {
    final Map<String, int> typeCounts = {};
    for (var r in reports) {
      final t = r['type'] ?? 'Other';
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }

    final sortedTypes = typeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedTypes.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports by Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          if (top5.isEmpty)
             const Text('No type data available', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ...top5.map((e) => _typeItem(Icons.flag_outlined, e.key, e.value.toString(), reports.isNotEmpty ? '${((e.value/reports.length)*100).toStringAsFixed(1)}%' : '0%', _getTypeColor(e.key))),
        ],
      ),
    );
  }

  Widget _typeItem(IconData i, String l, String v, String p, Color c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(i, color: c, size: 16)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), Text(p, style: TextStyle(fontSize: 10, color: Colors.grey.shade400))])), Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));

  Widget _buildTopReportedProperties(List<Map<String, dynamic>> reports) {
    final Map<String, int> targetCounts = {};
    for (var r in reports) {
      if (r['category']?.toString().toLowerCase().contains('property') == true || r['category']?.toString().toLowerCase().contains('listing') == true) {
        final name = r['targetName'] ?? 'Unknown';
        targetCounts[name] = (targetCounts[name] ?? 0) + 1;
      }
    }

    final sortedTargets = targetCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sortedTargets.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Reported Properties', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          if (top3.isEmpty)
            const Text('No property report data available', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ...top3.map((e) => _propertyReportItem(e.key, '${e.value} Reports')),
          const SizedBox(height: 16),
          const Center(child: Text('View All Properties →', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _propertyReportItem(String name, String count) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.business_rounded, color: Colors.grey, size: 16)), const SizedBox(width: 12), Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)), Text(count, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)))]));
}

class _ReportRow extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final String type;
  final Color typeColor;
  final String user;
  final String userType;
  final String target;
  final String targetId;
  final String priority;
  final Color priorityColor;
  final String status;
  final Color statusColor;
  final String date;
  final bool isNarrow;
  final Function(String) onAction;

  const _ReportRow({required this.id, required this.title, required this.category, required this.type, required this.typeColor, required this.user, required this.userType, required this.target, required this.targetId, required this.priority, required this.priorityColor, required this.status, required this.statusColor, required this.date, required this.isNarrow, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: isNarrow
        ? Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis)])),
              StatusBadge(text: status, color: statusColor),
            ]),
          ])
        : Row(children: [
            // 1. Report
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), Text(category, style: const TextStyle(fontSize: 10, color: Colors.grey))])),
            // 2. Type
            Expanded(flex: 2, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(type, textAlign: TextAlign.center, style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold))))),
            // 3. Reported By
            Expanded(flex: 2, child: Row(children: [CircleAvatar(radius: 12, backgroundColor: const Color(0xFFF1F5F9), child: Text(user.isNotEmpty ? user[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), Text(userType, style: const TextStyle(fontSize: 9, color: Colors.grey))]))])),
            // 4. Against
            Expanded(flex: 3, child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.business_rounded, color: Colors.grey, size: 16)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(target, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), if(targetId.isNotEmpty) Text(targetId, style: const TextStyle(fontSize: 9, color: Colors.grey))]))])),
            // 5. Priority
            Expanded(flex: 2, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(priority, style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold))))),
            // 6. Status
            Expanded(flex: 2, child: Center(child: StatusBadge(text: status, color: statusColor))),
            // 7. Date
            Expanded(flex: 2, child: Text(date, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
              onSelected: onAction,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'resolved', child: Text('Mark as Resolved')),
                const PopupMenuItem(value: 'rejected', child: Text('Reject Report')),
                const PopupMenuItem(value: 'investigation', child: Text('Mark Under Investigation')),
              ],
            ),
          ]),
    );
  }
}