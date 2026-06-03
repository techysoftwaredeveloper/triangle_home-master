import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/hoster_detail_screen.dart';
import 'package:triangle_home/screens/admin/property_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ApprovalsTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const ApprovalsTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends State<ApprovalsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      stream: widget.adminService.getPendingApprovalsStream(),
      builder: (context, snapshot) {
        final allItems = snapshot.data ?? [];

        // Mock additional items to match the image counts
        final List<Map<String, dynamic>> displayItems = List.from(allItems);
        if (displayItems.isEmpty &&
            snapshot.connectionState != ConnectionState.waiting) {
          _addMockData(displayItems);
        }

        final hosterRequests =
            displayItems.where((i) => i['type'] == 'hoster').toList();
        final propertyListings =
            displayItems.where((i) => i['type'] == 'property').toList();
        final userVerifications =
            displayItems
                .where((i) => i['type'] == 'user_verification')
                .toList();
        final otherRequests =
            displayItems.where((i) => i['type'] == 'other').toList();

        // Filter based on tab
        List<Map<String, dynamic>> filteredItems;
        switch (_tabController.index) {
          case 1:
            filteredItems = hosterRequests;
            break;
          case 2:
            filteredItems = propertyListings;
            break;
          case 3:
            filteredItems = userVerifications;
            break;
          case 4:
            filteredItems = otherRequests;
            break;
          default:
            filteredItems = displayItems;
            break;
        }

        if (_searchQuery.isNotEmpty) {
          filteredItems =
              filteredItems.where((item) {
                final title =
                    (item['name'] ?? item['info']?['name'] ?? '')
                        .toString()
                        .toLowerCase();
                return title.contains(_searchQuery.toLowerCase());
              }).toList();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSummaryRow(displayItems),
              const SizedBox(height: 64),
              _buildTabNavigation(displayItems),
              const SizedBox(height: 24),
              _buildSearchAndFilterRow(),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  allItems.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildItemsList(filteredItems),
              const SizedBox(height: 40),
              _buildGuidelineBanner(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _addMockData(List<Map<String, dynamic>> items) {
    items.addAll([
      {
        'id': 'mock1',
        'type': 'hoster',
        'name': 'Sunrise Hostels',
        'info': {
          'name': 'John Doe',
          'email': 'john@gmail.com',
          'phoneNumber': '+91 70254 77997',
        },
        'location': 'Kozhikode, Kerala',
        'category': 'PG Hostel',
        'propertyCount': 15,
        'createdAt': Timestamp.now(),
        'docsCount': '3/3',
        'isVerified': true,
      },
      {
        'id': 'mock2',
        'type': 'property',
        'name': 'Green Valley PG',
        'hosterName': 'John Doe',
        'location': 'Kozhikode, Kerala',
        'category': 'PG Accommodation',
        'rooms': 6,
        'createdAt': Timestamp.now(),
        'docsCount': '4/4',
        'isVerified': true,
      },
      {
        'id': 'mock3',
        'type': 'user_verification',
        'name': 'Sarah Ahmed',
        'info': {
          'name': 'Sarah Ahmed',
          'email': 'sarah.ahmed@example.com',
          'phoneNumber': '+91 79022 33445',
        },
        'verificationType': 'Identity Verification',
        'createdAt': Timestamp.now(),
        'isVerified': true,
      },
      {
        'id': 'mock4',
        'type': 'property',
        'name': 'Comfort Living PG',
        'hosterName': 'Mike Johnson',
        'location': 'Thrissur, Kerala',
        'category': 'PG Accommodation',
        'rooms': 8,
        'createdAt': Timestamp.now(),
        'docsCount': '3/4',
        'isVerified': true,
      },
      {
        'id': 'mock5',
        'type': 'other',
        'name': 'Document Update',
        'requesterName': 'Lily Thomas',
        'email': 'lily@sunrisehostels.com',
        'requestType': 'Document Update',
        'createdAt': Timestamp.now(),
        'isVerified': true,
      },
    ]);
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Approvals',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                fontFamily: 'Outfit',
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Review and take action on pending requests',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: const [
              Icon(Icons.tune_rounded, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 10),
              Text(
                'Filter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(List<Map<String, dynamic>> items) {
    final hosterCount = items.where((i) => i['type'] == 'hoster').length;
    final propertyCount = items.where((i) => i['type'] == 'property').length;
    final userCount =
        items.where((i) => i['type'] == 'user_verification').length;
    final otherCount = items.where((i) => i['type'] == 'other').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _SummaryStatCard(
            count: items.length.toString(),
            label: 'Total Pending',
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
          ),
          const SizedBox(width: 16),
          _SummaryStatCard(
            count: hosterCount.toString(),
            label: 'Hoster Requests',
            icon: Icons.business_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFF7ED),
          ),
          const SizedBox(width: 16),
          _SummaryStatCard(
            count: propertyCount.toString(),
            label: 'Property Listings',
            icon: Icons.home_outlined,
            iconColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          const SizedBox(width: 16),
          _SummaryStatCard(
            count: userCount.toString(),
            label: 'User Verifications',
            icon: Icons.person_outline,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
          ),
          const SizedBox(width: 16),
          _SummaryStatCard(
            count: otherCount.toString(),
            label: 'Other Requests',
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
          const SizedBox(width: 16),
          const _SummaryStatCard(
            count: '24',
            label: 'Approved Today',
            icon: Icons.check_circle_outline,
            iconColor: Color(0xFF64748B),
            bgColor: Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation(List<Map<String, dynamic>> items) {
    final hosterCount = items.where((i) => i['type'] == 'hoster').length;
    final propertyCount = items.where((i) => i['type'] == 'property').length;
    final userCount =
        items.where((i) => i['type'] == 'user_verification').length;
    final otherCount = items.where((i) => i['type'] == 'other').length;

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
          Tab(text: 'All (${items.length})'),
          Tab(text: 'Hoster Requests ($hosterCount)'),
          Tab(text: 'Property Listings ($propertyCount)'),
          Tab(text: 'User Verifications ($userCount)'),
          Tab(text: 'Other ($otherCount)'),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Row(
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
                const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search approvals...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: const [
              Text(
                'Newest First',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(width: 12),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No matching requests found',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      children:
          items
              .map(
                (item) => _ApprovalItemCard(
                  item: item,
                  onApprove:
                      () => _handleAction(item['id'], item['type'], 'approve'),
                  onReject:
                      () => _handleAction(item['id'], item['type'], 'reject'),
                  onDetails: () => _viewDetails(item),
                ),
              )
              .toList(),
    );
  }

  void _viewDetails(Map<String, dynamic> item) {
    if (item['type'] == 'property') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PropertyDetailScreen(
                property: item,
                adminService: widget.adminService,
              ),
        ),
      );
    } else if (item['type'] == 'hoster') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => HosterDetailScreen(
                request: item,
                adminService: widget.adminService,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Details view for this request type is coming soon'),
        ),
      );
    }
  }

  Future<void> _handleAction(String id, String type, String action) async {
    try {
      if (action == 'approve') {
        await widget.adminService.approveItem(id, type);
      } else if (action == 'reject') {
        await widget.adminService.rejectItem(id, type);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${type[0].toUpperCase()}${type.substring(1)} ${action == 'approve' ? 'approved' : 'rejected'} successfully',
            ),
            backgroundColor: action == 'approve' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGuidelineBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Need help reviewing approvals?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Check our approval guidelines and documentation.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IntrinsicWidth(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'View Guidelines',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _SummaryStatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDetails;

  const _ApprovalItemCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String;
    final String typeLabel;
    final IconData typeIcon;
    final Color typeColor;

    switch (type) {
      case 'hoster':
        typeLabel = 'Hoster Request';
        typeIcon = Icons.business_outlined;
        typeColor = const Color(0xFFF59E0B);
        break;
      case 'property':
        typeLabel = 'Property Listing';
        typeIcon = Icons.home_outlined;
        typeColor = const Color(0xFF3B82F6);
        break;
      case 'user_verification':
        typeLabel = 'User Verification';
        typeIcon = Icons.person_outline;
        typeColor = const Color(0xFF8B5CF6);
        break;
      default:
        typeLabel = 'Other Request';
        typeIcon = Icons.description_outlined;
        typeColor = const Color(0xFF10B981);
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    _StatusBadge(
                      text: 'Pending',
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThumbnail(typeIcon, typeColor),
                    const SizedBox(width: 20),
                    Expanded(child: _buildMainInfo(item, type)),
                    _buildMetaInfo(item, type),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTags(item, type),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildThumbnail(IconData icon, Color color) {
    final images = item['images'] as List? ?? [];
    final imageUrl =
        images.isNotEmpty ? images.first : 'https://via.placeholder.com/90';

    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          left: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo(Map<String, dynamic> item, String type) {
    final name = item['name'] ?? 'Unknown';
    final requester =
        item['info']?['name'] ??
        item['hosterName'] ??
        item['requesterName'] ??
        'Unknown';
    final email = item['info']?['email'] ?? item['email'] ?? '';
    final phone = item['info']?['phoneNumber'] ?? '';
    final location = item['location'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text(
              'Requested by: ',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            Text(
              requester,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (item['isVerified'] == true) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle,
                size: 14,
                color: Color(0xFF3B82F6),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (phone.isNotEmpty || email.isNotEmpty)
          Text(
            '${phone.isNotEmpty ? "$phone  •  " : ""}$email',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        if (location.isNotEmpty)
          Text(
            location,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
      ],
    );
  }

  Widget _buildMetaInfo(Map<String, dynamic> item, String type) {
    final dateStr =
        item['createdAt'] is Timestamp
            ? DateFormat(
              'dd MMM yyyy, hh:mm a',
            ).format((item['createdAt'] as Timestamp).toDate())
            : 'N/A';

    final String label;
    final String value;
    final Color valueColor;

    if (type == 'hoster' || type == 'property') {
      label = 'Documents';
      value = '${item['docsCount'] ?? '0/0'} Uploaded';
      valueColor = const Color(0xFF10B981);
    } else if (type == 'user_verification') {
      label = 'Verification Type';
      value = item['verificationType'] ?? 'Identity Verification';
      valueColor = const Color(0xFF0F172A);
    } else {
      label = 'Request Type';
      value = item['requestType'] ?? 'General';
      valueColor = const Color(0xFF0F172A);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Requested on',
          style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
        Text(
          dateStr,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTags(Map<String, dynamic> item, String type) {
    List<String> tags = [];
    if (type == 'hoster') {
      tags = [
        item['category'] ?? 'PG Hostel',
        '${item['propertyCount'] ?? 0} Properties',
      ];
    } else if (type == 'property') {
      tags = [
        item['category'] ?? 'PG Accommodation',
        '${item['rooms'] ?? 0} Rooms',
      ];
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      children:
          tags
              .map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Details',
              onPressed: onDetails,
              color: Colors.white,
              textColor: const Color(0xFF0F172A),
              border: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: 'Approve',
              onPressed: onApprove,
              color: const Color(0xFF2563EB),
              textColor: Colors.white,
              hasDropdown: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: 'Reject',
              onPressed: onReject,
              color: const Color(0xFFFEE2E2),
              textColor: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final bool border;
  final bool hasDropdown;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.textColor,
    this.border = false,
    this.hasDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          side: border ? const BorderSide(color: Color(0xFFE2E8F0)) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
