import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ModerationTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const ModerationTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<ModerationTab> createState() => _ModerationTabState();
}

class _ModerationTabState extends State<ModerationTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _selectedItem;
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
      stream: widget.adminService.getAuditLogsStream(),
      builder: (context, snapshot) {
        final allLogs = snapshot.data ?? [];

        // Filtering
        final filteredLogs =
            allLogs.where((l) {
              final matchesSearch =
                  (l['id']?.toString().toLowerCase().contains(_searchQuery) ??
                      false) ||
                  (l['action']?.toString().toLowerCase().contains(
                        _searchQuery,
                      ) ??
                      false) ||
                  (l['targetId']?.toString().toLowerCase().contains(
                        _searchQuery,
                      ) ??
                      false) ||
                  (l['reason']?.toString().toLowerCase().contains(
                        _searchQuery,
                      ) ??
                      false);

              final type = l['targetType']?.toString().toLowerCase() ?? '';

              switch (_tabController.index) {
                case 1:
                  return matchesSearch && type == 'property';
                case 2:
                  return matchesSearch && type == 'users';
                case 3:
                  return matchesSearch && type == 'review';
                case 4:
                  return matchesSearch && type == 'message';
                default:
                  return matchesSearch;
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
                      title: 'Moderation',
                      subtitle:
                          'Review and take action on content, users and listings',
                      isNarrow: widget.isNarrow,
                      actions: [
                        _buildHeaderAction(
                          'Export',
                          Icons.file_download_outlined,
                          isOutline: true,
                          onPressed: _handleExport,
                        ),
                        const SizedBox(width: 12),
                        _buildHeaderAction(
                          'Filters',
                          Icons.tune_rounded,
                          hasDropdown: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSummaryCards(allLogs),
                    const SizedBox(height: 32),
                    _buildCategoryTabs(allLogs),
                    const SizedBox(height: 24),
                    _buildFilterRow(),
                    const SizedBox(height: 24),
                    if (!widget.isNarrow) _buildTableHeader(),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        allLogs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (filteredLogs.isEmpty)
                      _buildEmptyState()
                    else
                      _buildModerationList(filteredLogs),
                    const SizedBox(height: 32),
                    _buildPaginationFooter(filteredLogs.length),
                  ],
                ),
              ),
            ),
            if (!widget.isNarrow && _selectedItem != null) _buildDetailPanel(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gpp_good_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'System is secure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No moderation flags or suspicious logs found.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting audit logs to CSV...'),
        backgroundColor: Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildHeaderAction(
    String label,
    IconData icon, {
    bool isOutline = false,
    bool hasDropdown = false,
    VoidCallback? onPressed,
  }) {
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
            Icon(
              icon,
              color: isOutline ? const Color(0xFF64748B) : Colors.white,
              size: 18,
            ),
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
              Icon(
                Icons.keyboard_arrow_down,
                color: isOutline ? const Color(0xFF64748B) : Colors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> logs) {
    int pendingCount = 0;
    int resolvedCount = 0;

    for (var l in logs) {
      final status = (l['status'] ?? 'pending').toString().toLowerCase();
      if (status == 'pending') {
        pendingCount++;
      } else if (status == 'resolved') {
        resolvedCount++;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          SummaryCard(
            count: logs.length.toString(),
            label: 'Total Audit Logs',
            bg: const Color(0xFFEFF6FF),
            color: const Color(0xFF2563EB),
            icon: Icons.security_rounded,
            percentage: '12.4%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: pendingCount.toString(),
            label: 'Pending Review',
            bg: const Color(0xFFFFFBEB),
            color: const Color(0xFFD97706),
            icon: Icons.timer_outlined,
            sub:
                logs.isEmpty
                    ? '0%'
                    : '${((pendingCount / logs.length) * 100).toStringAsFixed(1)}% of total',
          ),
          const SizedBox(width: 16),
          SummaryCard(
            count: resolvedCount.toString(),
            label: 'Resolved Issues',
            bg: const Color(0xFFF0FDF4),
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_rounded,
            percentage: '18.7%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '42',
            label: 'Auto-Approved',
            bg: Color(0xFFF5F3FF),
            color: Color(0xFF7C3AED),
            icon: Icons.thumb_up_alt_outlined,
            sub: 'System Validated',
          ),
          const SizedBox(width: 16),
          const SummaryCard(
            count: '18',
            label: 'Auto-Rejected',
            bg: Color(0xFFFEF2F2),
            color: Color(0xFFDC2626),
            icon: Icons.thumb_down_alt_outlined,
            sub: 'Policy Breach',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> logs) {
    final properties = logs.where((l) => l['targetType'] == 'property').length;
    final users = logs.where((l) => l['targetType'] == 'users').length;

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
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          fontFamily: 'Outfit',
        ),
        tabs: [
          Tab(text: 'All (${logs.length})'),
          Tab(text: 'Listings ($properties)'),
          Tab(text: 'Users ($users)'),
          const Tab(text: 'Reviews (0)'),
          const Tab(text: 'Messages (0)'),
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
                      hintText:
                          widget.isNarrow
                              ? 'Search...'
                              : 'Search by id, property, user or reason...',
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
        _buildSmallFilter('Content Type'),
        const SizedBox(width: 12),
        _buildSmallFilter('Status'),
        const SizedBox(width: 12),
        _buildSmallFilter('Priority'),
        if (!widget.isNarrow) ...[
          const SizedBox(width: 12),
          _buildSmallFilter('Date Range', icon: Icons.calendar_month_outlined),
          const SizedBox(width: 12),
          _buildSmallFilter('More Filters'),
        ],
      ],
    );
  }

  Widget _buildSmallFilter(
    String label, {
    IconData? icon,
    bool hasDropdown = true,
  }) {
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
          if (!widget.isNarrow || label == 'Status')
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          if (hasDropdown) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            child: Icon(
              Icons.check_box_outline_blank_rounded,
              size: 18,
              color: Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _tableLabel('ID')),
          Expanded(flex: 2, child: _tableLabel('TYPE')),
          Expanded(flex: 3, child: _tableLabel('ACTION')),
          Expanded(flex: 2, child: _tableLabel('PERFORMED BY')),
          Expanded(flex: 3, child: _tableLabel('REASON / DATA')),
          Expanded(flex: 2, child: _tableLabel('PRIORITY')),
          Expanded(flex: 2, child: _tableLabel('STATUS')),
          Expanded(flex: 2, child: _tableLabel('TIMESTAMP')),
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

  Widget _buildModerationList(List<Map<String, dynamic>> logs) {
    return Column(
      children:
          logs
              .map(
                (l) => _ModerationRow(
                  id:
                      l['id']?.toString().substring(0, 8).toUpperCase() ??
                      'MOD-NEW',
                  type: _formatType(l['targetType']),
                  subject: _formatAction(l['action']),
                  subjectId: l['targetId']?.toString().toUpperCase() ?? '',
                  reportedBy: l['performedBy'] ?? 'System',
                  reason: l['reason'] ?? 'Routine Audit',
                  priority: _getPriority(l['action']),
                  priorityColor: _getPriorityColor(l['action']),
                  status: (l['status'] ?? 'Resolved').toString(),
                  statusColor:
                      (l['status'] == 'Pending') ? Colors.orange : Colors.green,
                  date: _formatDateTime(l['timestamp']),
                  isSelected: _selectedItem?['id'] == l['id'],
                  onTap: () => setState(() => _selectedItem = l),
                  isNarrow: widget.isNarrow,
                  onAction: (action) => _handleAction(l['id'], action),
                ),
              )
              .toList(),
    );
  }

  String _formatType(dynamic type) {
    final t = type?.toString().toLowerCase() ?? '';
    if (t == 'users') return 'User';
    if (t == 'property') return 'Listing';
    if (t.isEmpty) return 'System';
    return t[0].toUpperCase() + t.substring(1);
  }

  String _formatAction(dynamic action) {
    final a = action?.toString().replaceAll('_', ' ').toLowerCase() ?? 'Action';
    return a
        .split(' ')
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
        .join(' ');
  }

  String _getPriority(dynamic action) {
    final a = action?.toString().toLowerCase() ?? '';
    if (a.contains('delete') || a.contains('block') || a.contains('ban'))
      return 'High';
    if (a.contains('update') || a.contains('edit')) return 'Medium';
    return 'Low';
  }

  Color _getPriorityColor(dynamic action) {
    final p = _getPriority(action);
    if (p == 'High') return Colors.red;
    if (p == 'Medium') return Colors.orange;
    return Colors.blue;
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      final d = date.toDate();
      return '${DateFormat('dd MMM yyyy').format(d)}\n${DateFormat('hh:mm a').format(d)}';
    }
    return date.toString();
  }

  void _handleAction(String id, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moderation action "$action" on $id coming soon'),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildDetailPanel() {
    final l = _selectedItem!;
    final action = _formatAction(l['action']);
    final priorityColor = _getPriorityColor(l['action']);

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
                const Text(
                  'Audit Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _selectedItem = null),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: StatusBadge(
                      text: l['status'] ?? 'Resolved',
                      color:
                          (l['status'] == 'Pending')
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              action,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatType(l['targetType']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  'Target ID: ${l['targetId']?.toString().toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 48),
            _buildDetailSectionTitle('Log Information'),
            _detailRow('Performed By', l['performedBy'] ?? 'System'),
            _detailRow(
              'Timestamp',
              _formatDateTime(l['timestamp']).replaceAll('\n', ' '),
            ),

            const SizedBox(height: 16),
            const Text(
              'Reason / Note',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l['reason'] ?? 'Routine automated audit log entry.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Priority Level',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded, size: 12, color: priorityColor),
                  const SizedBox(width: 4),
                  Text(
                    _getPriority(l['action']),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 48),
            _buildDetailSectionTitle('System Context'),
            const Text(
              'No additional security context provided for this entry.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),

            const SizedBox(height: 40),
            _actionButton(
              'Acknowledge Log',
              const Color(0xFFF0FDF4),
              const Color(0xFF16A34A),
              Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            _actionButton(
              'Reverse Action',
              const Color(0xFFFEF2F2),
              const Color(0xFFDC2626),
              Icons.history_rounded,
            ),
            const SizedBox(height: 12),
            _actionButton(
              'Escalate to Dev',
              const Color(0xFFEFF6FF),
              const Color(0xFF2563EB),
              Icons.code_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color bg, Color text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: text.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: text),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.isNarrow
              ? '1-$count of $count'
              : 'Showing 1 to $count of $count items',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
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
}

class _ModerationRow extends StatelessWidget {
  final String id;
  final String type;
  final String subject;
  final String? subjectId;
  final String reportedBy;
  final String reason;
  final String priority;
  final Color priorityColor;
  final String status;
  final Color statusColor;
  final String date;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNarrow;
  final Function(String) onAction;

  const _ModerationRow({
    required this.id,
    required this.type,
    required this.subject,
    this.subjectId,
    required this.reportedBy,
    required this.reason,
    required this.priority,
    required this.priorityColor,
    required this.status,
    required this.statusColor,
    required this.date,
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
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          ),
        ),
        child:
            isNarrow
                ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                id,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                subject,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(text: status, color: statusColor),
                      ],
                    ),
                  ],
                )
                : Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      child: Icon(
                        Icons.check_box_outline_blank_rounded,
                        size: 18,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 1. ID
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            id,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            type,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 2. Type
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              type == 'Listing'
                                  ? Icons.home_work_outlined
                                  : Icons.person_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 3. Subject
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subjectId != null)
                            Text(
                              subjectId!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 4. Reported By
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportedBy,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Admin',
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // 5. Reason
                    Expanded(
                      flex: 3,
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 6. Priority
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 7. Status
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: StatusBadge(text: status, color: statusColor),
                      ),
                    ),
                    // 8. Date
                    Expanded(
                      flex: 2,
                      child: Text(
                        date,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFFCBD5E1),
                        size: 18,
                      ),
                      onSelected: onAction,
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'acknowledge',
                              child: Text('Acknowledge'),
                            ),
                            const PopupMenuItem(
                              value: 'reverse',
                              child: Text('Reverse Action'),
                            ),
                            const PopupMenuItem(
                              value: 'escalate',
                              child: Text('Escalate'),
                            ),
                          ],
                    ),
                  ],
                ),
      ),
    );
  }
}
