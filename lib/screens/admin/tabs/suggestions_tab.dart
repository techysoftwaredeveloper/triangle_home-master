import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SuggestionsTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const SuggestionsTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<SuggestionsTab> createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends State<SuggestionsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _selectedSuggestion;
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
      stream: widget.adminService.getSuggestionsStream(),
      builder: (context, snapshot) {
        final allSuggestions = snapshot.data ?? [];

        // Filtering
        final filteredSuggestions = allSuggestions.where((s) {
          final matchesSearch = (s['propertyName']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (s['location']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                                (s['userName']?.toString().toLowerCase().contains(_searchQuery) ?? false);

          final status = s['status']?.toString().toLowerCase() ?? 'under review';

          switch (_tabController.index) {
            case 1: return matchesSearch && (status == 'under review' || status == 'pending');
            case 2: return matchesSearch && status == 'contacted';
            case 3: return matchesSearch && status == 'shortlisted';
            case 4: return matchesSearch && status == 'converted';
            case 5: return matchesSearch && status == 'rejected';
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
                      title: 'Suggestions',
                      subtitle: 'Review and manage property suggestions from users',
                      isNarrow: widget.isNarrow,
                      actions: [
                        _buildHeaderAction('Export', Icons.file_download_outlined, isOutline: true, onPressed: _handleExport),
                        const SizedBox(width: 12),
                        _buildHeaderAction('Filters', Icons.tune_rounded, hasDropdown: true),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSummaryCards(allSuggestions),
                    const SizedBox(height: 32),
                    _buildCategoryTabs(allSuggestions),
                    const SizedBox(height: 24),
                    _buildFilterRow(),
                    const SizedBox(height: 24),
                    if (!widget.isNarrow) _buildTableHeader(),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting && allSuggestions.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    else if (filteredSuggestions.isEmpty)
                      _buildEmptyState()
                    else
                      _buildSuggestionsList(filteredSuggestions),
                    const SizedBox(height: 32),
                    _buildPaginationFooter(filteredSuggestions.length),
                  ],
                ),
              ),
            ),
            if (!widget.isNarrow && _selectedSuggestion != null)
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
          Icon(Icons.lightbulb_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No suggestions found',
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

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting suggestions to CSV...'), backgroundColor: Color(0xFF2563EB)),
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

  Widget _buildSummaryCards(List<Map<String, dynamic>> suggestions) {
    final underReview = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase().contains('review') || (s['status'] ?? '').toString().toLowerCase() == 'pending').length;
    final contacted = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'contacted').length;
    final shortlisted = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'shortlisted').length;
    final converted = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'converted').length;
    final rejected = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'rejected').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          SummaryCard(
            count: suggestions.length.toString(),
            label: 'Total Suggestions',
            bg: const Color(0xFFEFF6FF),
            color: const Color(0xFF2563EB),
            icon: Icons.lightbulb_outline_rounded,
            percentage: '16.4%',
            isUp: true,
          ),
          const SizedBox(width: 16),
          _buildSmallSummaryCard(underReview.toString(), 'Under Review', suggestions.isEmpty ? '0% of total' : '${((underReview/suggestions.length)*100).toStringAsFixed(1)}% of total', const Color(0xFFFFFBEB), const Color(0xFFD97706), Icons.timer_outlined),
          const SizedBox(width: 16),
          _buildSmallSummaryCard(contacted.toString(), 'Contacted', suggestions.isEmpty ? '0% of total' : '${((contacted/suggestions.length)*100).toStringAsFixed(1)}% of total', const Color(0xFFEFF6FF), const Color(0xFF2563EB), Icons.phone_in_talk_outlined),
          const SizedBox(width: 16),
          _buildSmallSummaryCard(shortlisted.toString(), 'Shortlisted', suggestions.isEmpty ? '0% of total' : '${((shortlisted/suggestions.length)*100).toStringAsFixed(1)}% of total', const Color(0xFFF5F3FF), const Color(0xFF7C3AED), Icons.star_outline_rounded),
          const SizedBox(width: 16),
          _buildSmallSummaryCard(converted.toString(), 'Converted', suggestions.isEmpty ? '0% of total' : '${((converted/suggestions.length)*100).toStringAsFixed(1)}% of total', const Color(0xFFF0FDF4), const Color(0xFF16A34A), Icons.check_circle_outline_rounded),
          const SizedBox(width: 16),
          _buildSmallSummaryCard(rejected.toString(), 'Rejected', suggestions.isEmpty ? '0% of total' : '${((rejected/suggestions.length)*100).toStringAsFixed(1)}% of total', const Color(0xFFFEF2F2), const Color(0xFFDC2626), Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryCard(String count, String label, String sub, Color bg, Color color, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> suggestions) {
    final underReview = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase().contains('review') || (s['status'] ?? '').toString().toLowerCase() == 'pending').length;
    final contacted = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'contacted').length;
    final shortlisted = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'shortlisted').length;
    final converted = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'converted').length;
    final rejected = suggestions.where((s) => (s['status'] ?? '').toString().toLowerCase() == 'rejected').length;

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
          Tab(text: 'All Suggestions (${suggestions.length})'),
          Tab(text: 'Under Review ($underReview)'),
          Tab(text: 'Contacted ($contacted)'),
          Tab(text: 'Shortlisted ($shortlisted)'),
          Tab(text: 'Converted ($converted)'),
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
                      hintText: widget.isNarrow ? 'Search...' : 'Search by property name, location or user...',
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
          _buildSmallFilter('Property Type'),
          const SizedBox(width: 12),
          _buildSmallFilter('City'),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: const Color(0xFF64748B)), if (label.isNotEmpty) const SizedBox(width: 8)],
          if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          if (hasDropdown && !widget.isNarrow) ...[const SizedBox(width: 6), const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B))],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 3, child: _tableLabel('SUGGESTION')),
          Expanded(flex: 2, child: _tableLabel('LOCATION')),
          Expanded(flex: 2, child: _tableLabel('SUGGESTED BY')),
          Expanded(flex: 2, child: _tableLabel('STATUS')),
          Expanded(flex: 2, child: _tableLabel('DATE')),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _tableLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5));
  }

  Widget _buildSuggestionsList(List<Map<String, dynamic>> suggestions) {
    return Column(
      children: suggestions.map((s) => _SuggestionCard(
        id: s['id'],
        title: s['propertyName'] ?? 'Untitled Suggestion',
        type: s['propertyType'] ?? 'Accommodation',
        rooms: '${s['totalRooms'] ?? 0} Rooms',
        location: s['location'] ?? 'Location N/A',
        subLocation: s['landmark'] ?? 'Area N/A',
        user: s['userName'] ?? 'Unknown User',
        userType: s['userRole'] ?? 'User',
        phone: s['userPhone'] ?? 'No Phone',
        status: _formatStatus(s['status']),
        statusColor: _getStatusColor(s['status']),
        date: _formatDateTime(s['createdAt']),
        isSelected: _selectedSuggestion?['id'] == s['id'],
        onTap: () => setState(() => _selectedSuggestion = s),
        isNarrow: widget.isNarrow,
        onAction: (action) => _handleAction(s['id'], action),
      )).toList(),
    );
  }

  String _formatStatus(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'under review';
    if (status == 'pending' || status == 'under review') return 'Under Review';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'under review';
    switch (status) {
      case 'contacted': return Colors.blue;
      case 'shortlisted': return Colors.purple;
      case 'converted': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return '${DateFormat('dd MMM yyyy').format(date.toDate())}\n${DateFormat('hh:mm a').format(date.toDate())}';
    }
    return date.toString();
  }

  void _handleAction(String id, String action) async {
    try {
      await widget.adminService.updateSuggestionStatus(id, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suggestion updated to $action'), backgroundColor: Colors.green),
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

  Widget _buildDetailPanel() {
    final s = _selectedSuggestion!;
    final status = _formatStatus(s['status']);

    return Container(
      width: 350,
      decoration: const BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Color(0xFFE2E8F0)))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Suggestion Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _selectedSuggestion = null)),
              ],
            ),
            const SizedBox(height: 24),
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Stack(children: [Container(height: 180, width: double.infinity, color: const Color(0xFFF1F5F9), child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40)), Positioned(top: 12, right: 12, child: StatusBadge(text: status, color: _getStatusColor(s['status'])))])),
            const SizedBox(height: 20),
            Text(s['propertyName'] ?? 'Untitled', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Row(children: [Text(s['propertyType'] ?? 'Accommodation', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))), const SizedBox(width: 8), const Text('•', style: TextStyle(color: Colors.grey)), const SizedBox(width: 8), Text('${s['totalRooms'] ?? 0} Rooms', style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold))]),

            const Divider(height: 48),
            _detailTitle('Location'),
            _iconDetail(Icons.location_on_outlined, s['location'] ?? 'Location N/A', s['landmark'] ?? 'Area N/A'),

            const Divider(height: 48),
            _detailTitle('Suggested By'),
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: const Color(0xFFF5F3FF), child: Text(s['userName']?.toString().isNotEmpty == true ? s['userName'][0] : 'U', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['userName'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(s['userRole'] ?? 'User', style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold))])),
                const Text('View Profile', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(s['userPhone'] ?? 'No Phone', style: const TextStyle(fontSize: 12)),
            Text(s['userEmail'] ?? 'No Email', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),

            const Divider(height: 48),
            _detailTitle('Property Details'),
            _keyValueDetail('Property Type', s['propertyType'] ?? 'N/A'),
            _keyValueDetail('Total Rooms', (s['totalRooms'] ?? 0).toString()),
            _keyValueDetail('Rent Range', s['rentRange'] ?? 'N/A'),
            _keyValueDetail('Availability', s['availability'] ?? 'Immediately'),

            const Divider(height: 48),
            _detailTitle('Description'),
            Text(s['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5)),

            const Divider(height: 48),
            _detailTitle('Photos'),
            const Text('No photos attached', style: TextStyle(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 40),
            _actionBtn('Mark as Contacted', const Color(0xFFF5F3FF), const Color(0xFF7C3AED), Icons.phone_in_talk_outlined, () => _handleAction(s['id'], 'contacted')),
            const SizedBox(height: 12),
            _actionBtn('Mark as Shortlisted', const Color(0xFFEFF6FF), const Color(0xFF2563EB), Icons.star_outline_rounded, () => _handleAction(s['id'], 'shortlisted')),
            const SizedBox(height: 12),
            _actionBtn('Mark as Converted', const Color(0xFFF0FDF4), const Color(0xFF16A34A), Icons.check_circle_outline_rounded, () => _handleAction(s['id'], 'converted')),
            const SizedBox(height: 12),
            _actionBtn('Reject Suggestion', const Color(0xFFFEF2F2), const Color(0xFFDC2626), Icons.cancel_outlined, () => _handleAction(s['id'], 'rejected')),
          ],
        ),
      ),
    );
  }

  Widget _detailTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)));

  Widget _iconDetail(IconData i, String t, String s) => Row(children: [Icon(i, size: 18, color: const Color(0xFF2563EB)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]))]);

  Widget _keyValueDetail(String k, String v) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))), Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));

  Widget _actionBtn(String l, Color bg, Color t, IconData i, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 16, color: t), const SizedBox(width: 8), Text(l, style: TextStyle(color: t, fontWeight: FontWeight.bold, fontSize: 13))])));

  Widget _buildPaginationFooter(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.isNarrow ? '1-$count of $count' : 'Showing 1 to $count of $count suggestions', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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

class _SuggestionCard extends StatelessWidget {
  final String id;
  final String title;
  final String type;
  final String rooms;
  final String location;
  final String subLocation;
  final String user;
  final String userType;
  final String phone;
  final String status;
  final Color statusColor;
  final String date;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNarrow;
  final Function(String) onAction;

  const _SuggestionCard({required this.id, required this.title, required this.type, required this.rooms, required this.location, required this.subLocation, required this.user, required this.userType, required this.phone, required this.status, required this.statusColor, required this.date, required this.isSelected, required this.onTap, required this.isNarrow, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFEFF6FF) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9))),
        child: isNarrow
          ? Column(
              children: [
                Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.home_work_outlined, color: Colors.grey, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), Text(type, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))]))
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(location, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    StatusBadge(text: status, color: statusColor),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                // 1. Suggestion
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.home_work_outlined, color: Colors.grey, size: 20)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), Text(type, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))), Text(rooms, style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold))])),
                    ],
                  ),
                ),
                // 2. Location
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)), const SizedBox(width: 4), Expanded(child: Text(location, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis))]), Text(subLocation, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis)])),
                // 3. Suggested By
                Expanded(flex: 2, child: Row(children: [CircleAvatar(radius: 14, backgroundColor: const Color(0xFFF1F5F9), child: Text(user.isNotEmpty ? user[0] : 'U', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(width: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(userType, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 8, fontWeight: FontWeight.bold)))]), Text(phone, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))]))])),
                // 4. Status
                Expanded(flex: 2, child: Center(child: StatusBadge(text: status, color: statusColor))),
                // 5. Date
                Expanded(flex: 2, child: Text(date, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 18),
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'contacted', child: Text('Mark Contacted')),
                    const PopupMenuItem(value: 'shortlisted', child: Text('Mark Shortlisted')),
                    const PopupMenuItem(value: 'converted', child: Text('Mark Converted')),
                    const PopupMenuItem(value: 'rejected', child: Text('Reject Suggestion')),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

