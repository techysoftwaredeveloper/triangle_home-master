import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
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

class _SuggestionsTabState extends State<SuggestionsTab>
    with SingleTickerProviderStateMixin {
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
      setState(() => _searchQuery = _searchController.text.toLowerCase());
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

        final filteredSuggestions =
            allSuggestions.where((s) {
              final matchesSearch =
                  (s['business_name']?.toString().toLowerCase().contains(
                        _searchQuery,
                      ) ??
                      false) ||
                  (s['business_address']?.toString().toLowerCase().contains(
                        _searchQuery,
                      ) ??
                      false) ||
                  (s['suggester_name']?.toString().toLowerCase().contains(
                        _searchQuery,
                      ) ??
                      false);

              final status = s['status']?.toString().toLowerCase() ?? 'pending';

              switch (_tabController.index) {
                case 1:
                  return matchesSearch &&
                      (status == 'under review' || status == 'pending');
                case 2:
                  return matchesSearch && status == 'contacted';
                case 3:
                  return matchesSearch && status == 'shortlisted';
                case 4:
                  return matchesSearch && status == 'converted';
                case 5:
                  return matchesSearch && status == 'rejected';
                default:
                  return matchesSearch;
              }
            }).toList();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildSummaryRow(allSuggestions),
                          const SizedBox(height: 64),
                          _buildCategoryTabs(allSuggestions),
                          const SizedBox(height: 24),
                          _buildFilterRow(),
                          const SizedBox(height: 24),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: SizedBox(
                              width: 1100, // Explicitly bound width for children with flex
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!widget.isNarrow) _buildTableHeader(),
                                  const SizedBox(height: 12),
                                  if (snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      allSuggestions.isEmpty)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(60),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else if (filteredSuggestions.isEmpty)
                                    _buildEmptyState()
                                  else
                                    _buildSuggestionsList(filteredSuggestions),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildPaginationFooter(filteredSuggestions.length),
                ],
              ),
            ),
            if (!widget.isNarrow && _selectedSuggestion != null)
              _buildSideSheet(),
          ],
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
              'Suggestions',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                fontFamily: 'Outfit',
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Review and manage property suggestions from users',
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
              onPressed: _handleExport,
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
          boxShadow:
              isOutline
                  ? null
                  : [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
      ),
    );
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting suggestions to CSV...')),
    );
  }

  Widget _buildSummaryRow(List<Map<String, dynamic>> suggestions) {
    final underReview =
        suggestions
            .where(
              (s) =>
                  (s['status'] ?? '').toString().toLowerCase().contains(
                    'review',
                  ) ||
                  (s['status'] ?? '').toString().toLowerCase() == 'pending',
            )
            .length;
    final contacted =
        suggestions
            .where(
              (s) =>
                  (s['status'] ?? '').toString().toLowerCase() == 'contacted',
            )
            .length;
    final shortlisted =
        suggestions
            .where(
              (s) =>
                  (s['status'] ?? '').toString().toLowerCase() == 'shortlisted',
            )
            .length;
    final converted =
        suggestions
            .where(
              (s) =>
                  (s['status'] ?? '').toString().toLowerCase() == 'converted',
            )
            .length;
    final rejected =
        suggestions
            .where(
              (s) => (s['status'] ?? '').toString().toLowerCase() == 'rejected',
            )
            .length;

    String getPct(int count) =>
        suggestions.isEmpty
            ? '0%'
            : '${((count / suggestions.length) * 100).toStringAsFixed(1)}%';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _StatCard(
            count: suggestions.length.toString(),
            label: 'Total Suggestions',
            icon: Icons.lightbulb_outline_rounded,
            iconColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
            trend: '16.4%',
            isTrendUp: true,
          ),
          const SizedBox(width: 16),
          _StatCard(
            count: underReview.toString(),
            label: 'Under Review',
            icon: Icons.remove_red_eye_outlined,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            sub: '${getPct(underReview)} of total',
          ),
          const SizedBox(width: 16),
          _StatCard(
            count: contacted.toString(),
            label: 'Contacted',
            icon: Icons.phone_in_talk_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFF7ED),
            sub: '${getPct(contacted)} of total',
          ),
          const SizedBox(width: 16),
          _StatCard(
            count: shortlisted.toString(),
            label: 'Shortlisted',
            icon: Icons.star_outline_rounded,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            sub: '${getPct(shortlisted)} of total',
          ),
          const SizedBox(width: 16),
          _StatCard(
            count: converted.toString(),
            label: 'Converted',
            icon: Icons.home_work_outlined,
            iconColor: const Color(0xFF0EA5E9),
            bgColor: const Color(0xFFF0F9FF),
            sub: '${getPct(converted)} of total',
          ),
          const SizedBox(width: 16),
          _StatCard(
            count: rejected.toString(),
            label: 'Rejected',
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
            sub: '${getPct(rejected)} of total',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> suggestions) {
    final underReview =
        suggestions
            .where(
              (s) =>
                  (s['status'] ?? '').toString().toLowerCase().contains(
                    'review',
                  ) ||
                  (s['status'] ?? '').toString().toLowerCase() == 'pending',
            )
            .length;
    final contacted =
        suggestions
            .where(
              (s) =>
                  (s['status'] ?? '').toString().toLowerCase() == 'contacted',
            )
            .length;
    final shortlisted =
        suggestions
            .where(
              (s) =>
                  (s['status'] ?? '').toString().toLowerCase() == 'shortlisted',
            )
            .length;
    final converted =
        suggestions
            .where(
              (s) =>
                  (s['status'] ?? '').toString().toLowerCase() == 'converted',
            )
            .length;
    final rejected =
        suggestions
            .where(
              (s) => (s['status'] ?? '').toString().toLowerCase() == 'rejected',
            )
            .length;

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
                            decoration: const InputDecoration(
                              hintText:
                                  'Search by property name, location or user...',
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
                  _FilterBtn(label: 'Status', hasDropdown: true),
                  const SizedBox(width: 16),
                  _FilterBtn(label: 'Property Type', hasDropdown: true),
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
                    _FilterBtn(label: 'Property Type', hasDropdown: true),
                    const SizedBox(width: 12),
                  ],
                  _FilterBtn(label: 'City', hasDropdown: true),
                  const SizedBox(width: 12),
                  _FilterBtn(label: 'More Filters', hasDropdown: true),
                  const SizedBox(width: 12),
                  _FilterBtn(label: 'Newest First', hasDropdown: true),
                ],
              ),
            ),
          ],
        );
      },
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
          Expanded(flex: 3, child: _headerLabel('SUGGESTION')),
          Expanded(flex: 3, child: _headerLabel('LOCATION')),
          Expanded(flex: 2, child: _headerLabel('SUGGESTED BY')),
          Expanded(flex: 2, child: _headerLabel('STATUS')),
          Expanded(flex: 2, child: _headerLabel('DATE')),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _headerLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Color(0xFF94A3B8),
      letterSpacing: 0.5,
    ),
  );

  Widget _buildSuggestionsList(List<Map<String, dynamic>> items) {
    return Column(
      children:
          items
              .map<Widget>(
                (item) => _SuggestionTableCard(
                  item: item,
                  isSelected: _selectedSuggestion?['id'] == item['id'],
                  onTap: () => setState(() => _selectedSuggestion = item),
                ),
              )
              .toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      width: 1100,
      alignment: Alignment.center,
      child: const Text(
        'No matching suggestions found',
        style: TextStyle(color: Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildPaginationFooter(int count) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: LayoutBuilder(
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
                          ? '1-10 of $count'
                          : 'Showing 1 to ${count < 10 ? count : 10} of $count suggestions',
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
                    _PageBtn(label: '13'),
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
      ),
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

  Widget _buildSideSheet() {
    final s = _selectedSuggestion!;
    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Suggestion Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () => setState(() => _selectedSuggestion = null),
                ),
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
                          s['property_image'] ?? '',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                height: 200,
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(
                                  Icons.home_work_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: _StatusPill(
                            status: s['status']?.toString() ?? 'pending',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s['business_name'] ?? 'Untitled Property',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        s['category'] ?? 'PG / Hostel',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s['rooms_count'] ?? 30} Rooms',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 48),
                  _sheetSection('Location'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['business_address'] ?? 'Location N/A',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              s['sub_location'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 48),
                  _sheetSection('Suggested By'),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFF3E8FF),
                        child: Text(
                          (s['suggester_name'] ?? 'U')[0],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['suggester_name'] ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'STUDENT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s['suggester_phone'] ?? 'No phone',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    s['suggester_email'] ?? 'No email',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const Divider(height: 48),
                  _sheetSection('Property Details'),
                  _sheetRow('Property Type', s['category'] ?? 'PG / Hostel'),
                  _sheetRow('Total Rooms', (s['rooms_count'] ?? 30).toString()),
                  _sheetRow('Rent Range', '₹4,000 - ₹7,000'),

                  const Divider(height: 48),
                  _sheetSection('Description'),
                  Text(
                    s['description'] ?? 'No description provided.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 48),
                  _sheetSection('Actions'),
                  _sheetActionBtn(
                    'Mark as Contacted',
                    Icons.phone_in_talk_outlined,
                    const Color(0xFFF5F3FF),
                    const Color(0xFF6366F1),
                    () => _handleSuggestionAction(s['id'], 'contacted'),
                  ),
                  const SizedBox(height: 12),
                  _sheetActionBtn(
                    'Mark as Shortlisted',
                    Icons.star_outline_rounded,
                    const Color(0xFFEEF2FF),
                    const Color(0xFF4F46E5),
                    () => _handleSuggestionAction(s['id'], 'shortlisted'),
                  ),
                  const SizedBox(height: 12),
                  _sheetActionBtn(
                    'Mark as Converted',
                    Icons.check_circle_outline,
                    const Color(0xFFECFDF5),
                    const Color(0xFF10B981),
                    () => _handleSuggestionAction(s['id'], 'converted'),
                  ),
                  const SizedBox(height: 12),
                  _sheetActionBtn(
                    'Reject Suggestion',
                    Icons.cancel_outlined,
                    const Color(0xFFFEF2F2),
                    const Color(0xFFEF4444),
                    () => _handleSuggestionAction(s['id'], 'rejected'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSuggestionAction(String id, String action) async {
    try {
      if (action == 'converted') {
        await widget.adminService.convertSuggestionToApprovals(id);
      } else {
        await widget.adminService.updateSuggestionStatus(id, action);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lead status updated to $action successfully'),
            backgroundColor: Colors.green,
          ),
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

  Widget _sheetSection(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    ),
  );
  Widget _sheetRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    ),
  );

  Widget _sheetActionBtn(
    String label,
    IconData icon,
    Color bg,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
  const _StatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.trend,
    this.isTrendUp,
    this.sub,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            count,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          if (trend != null)
            Row(
              children: [
                Icon(
                  isTrendUp == true ? Icons.arrow_upward : Icons.arrow_downward,
                  color: const Color(0xFF10B981),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  trend!,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'vs last month',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            )
          else if (sub != null)
            Text(
              sub!,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool hasDropdown;
  const _FilterBtn({required this.label, this.hasDropdown = false})
    : icon = null;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionTableCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final VoidCallback onTap;
  const _SuggestionTableCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString().toLowerCase() ?? 'pending';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 1100,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['property_image'] ?? '',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(
                              Icons.home_work_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['business_name'] ?? 'Untitled Suggestion',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item['category'] ?? 'PG / Hostel',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '${item['rooms_count'] ?? 30} Rooms',
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
              flex: 3,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['business_address'] ?? 'Location N/A',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item['sub_location'] ?? '',
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
                      (item['suggester_name'] ?? 'U')[0],
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
                          item['suggester_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'STUDENT',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item['suggester_phone'] ?? '',
                          style: const TextStyle(
                            fontSize: 10,
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
              child: Center(child: _StatusPill(status: status)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item['createdAt'] is Timestamp
                    ? DateFormat(
                      'dd MMM yyyy\nHH:mm a',
                    ).format((item['createdAt'] as Timestamp).toDate())
                    : 'N/A',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.more_vert, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final String label;
    final Color color;
    final Color bg;
    if (s == 'converted') {
      label = 'Converted';
      color = const Color(0xFF10B981);
      bg = const Color(0xFFECFDF5);
    } else if (s == 'contacted') {
      label = 'Contacted';
      color = const Color(0xFFF59E0B);
      bg = const Color(0xFFFFF7ED);
    } else if (s == 'shortlisted') {
      label = 'Shortlisted';
      color = const Color(0xFF6366F1);
      bg = const Color(0xFFEEF2FF);
    } else if (s == 'rejected') {
      label = 'Rejected';
      color = const Color(0xFFEF4444);
      bg = const Color(0xFFFEF2F2);
    } else {
      label = 'Under Review';
      color = const Color(0xFF10B981);
      bg = const Color(0xFFECFDF5);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
