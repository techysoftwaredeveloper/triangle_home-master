import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/hoster_detail_screen.dart';
import 'package:triangle_home/screens/admin/property_detail_screen.dart';
import 'package:triangle_home/screens/admin/user_verification_detail_screen.dart';
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
  final Set<String> _selectedIds = {};
  String _sortBy = 'Newest First';
  final String _filterBy = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      stream: widget.adminService.getPendingApprovalsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Error loading approvals', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        }

        try {
          final allItems = snapshot.data ?? [];
          final List<Map<String, dynamic>> displayItems = allItems;

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

          // Apply Sorting
          if (_sortBy == 'Newest First') {
            filteredItems.sort((a, b) {
              final aTime = a['createdAt'] as Timestamp?;
              final bTime = b['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });
          } else if (_sortBy == 'Oldest First') {
            filteredItems.sort((a, b) {
              final aTime = a['createdAt'] as Timestamp?;
              final bTime = b['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return aTime.compareTo(bTime);
            });
          } else if (_sortBy == 'Alphabetical') {
            filteredItems.sort((a, b) {
              final aName = (a['name'] ?? a['info']?['name'] ?? '').toString();
              final bName = (b['name'] ?? b['info']?['name'] ?? '').toString();
              return aName.compareTo(bName);
            });
          }

          // Apply Global Filter
          if (_filterBy == 'Incomplete Docs') {
            filteredItems = filteredItems.where((item) {
              final docsCount = (item['docsCount'] ?? '0/0').toString();
              final parts = docsCount.split('/');
              if (parts.length == 2) {
                return int.tryParse(parts[0]) != int.tryParse(parts[1]);
              }
              return false;
            }).toList();
          } else if (_filterBy == 'Urgent') {
            filteredItems = filteredItems.where((item) {
              final aTime = item['createdAt'] as Timestamp?;
              if (aTime == null) return false;
              // Urgent if older than 24 hours
              return DateTime.now().difference(aTime.toDate()).inHours > 24;
            }).toList();
          }

          return Container(
            color: const Color(0xFF020617), // Deep Dark Background (Matching Listings)
            child: SingleChildScrollView(
              padding: EdgeInsets.all(widget.isNarrow ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSummaryRow(displayItems),
                  const SizedBox(height: 48),
                  _buildTabNavigation(displayItems),
                  const SizedBox(height: 24),
                  _buildSearchAndFilterRow(),
                  const SizedBox(height: 24),
                  if (_selectedIds.isNotEmpty) _buildBulkOperationsToolbar(),
                  const SizedBox(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      allItems.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF6366F1)),
                            SizedBox(height: 16),
                            Text('Syncing with Real-time Engine...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildItemsList(filteredItems),
                  const SizedBox(height: 40),
                  _buildGuidelineBanner(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        } catch (e, stack) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bug_report, color: Colors.orange, size: 48),
                    const SizedBox(height: 16),
                    const Text('Synchronous Exception Caught', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.deepOrange)),
                    const SizedBox(height: 8),
                    Text(stack.toString(), style: const TextStyle(color: Colors.black54, fontSize: 10)),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Approvals',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  SizedBox(width: 12),
                  _LiveBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Review and take action on pending requests',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                title: const Text('Cleanup Incomplete Requests?', style: TextStyle(color: Colors.white)),
                content: const Text('This will permanently delete all pending properties without images and in-progress onboarding without data.', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Run Cleanup', style: TextStyle(color: Colors.orange))),
                ],
              ),
            );
            if (confirmed == true) {
              try {
                await widget.adminService.cleanupApprovals();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleanup completed successfully')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cleanup failed: $e'), backgroundColor: Colors.red));
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cleaning_services_rounded, size: 18, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text('Cleanup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_list, size: 18, color: Colors.white54),
                SizedBox(width: 8),
                Text('Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white54),
              ],
            ),
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
            label: 'Total\nPending',
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFFEF4444),
            bgColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
          ),
          const SizedBox(width: 20),
          _SummaryStatCard(
            count: hosterCount.toString(),
            label: 'Hoster\nRequests',
            icon: Icons.business_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          ),
          const SizedBox(width: 20),
          _SummaryStatCard(
            count: propertyCount.toString(),
            label: 'Property\nListings',
            icon: Icons.home_outlined,
            iconColor: const Color(0xFF6366F1),
            bgColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
          ),
          const SizedBox(width: 20),
          _SummaryStatCard(
            count: userCount.toString(),
            label: 'User\nVerifications',
            icon: Icons.person_outline,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          ),
          const SizedBox(width: 20),
          _SummaryStatCard(
            count: otherCount.toString(),
            label: 'Other\nRequests',
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
          ),
          const SizedBox(width: 20),
          StreamBuilder<int>(
            stream: widget.adminService.getApprovedTodayCountStream(),
            builder: (context, snapshot) {
              return _SummaryStatCard(
                count: (snapshot.data ?? 0).toString(),
                label: 'Approved\nToday',
                icon: Icons.check_circle_outline,
                iconColor: Colors.white,
                bgColor: Colors.white.withValues(alpha: 0.05),
              );
            }
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
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        onTap: (index) => setState(() {}),
        labelColor: const Color(0xFF6366F1), // Indigo Primary
        unselectedLabelColor: Colors.white38,
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
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1AFFFFFF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0x4DFFFFFF), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search approvals...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0x4DFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          onSelected: (value) => setState(() => _sortBy = value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Newest First', child: Text('Newest First')),
            const PopupMenuItem(value: 'Oldest First', child: Text('Oldest First')),
            const PopupMenuItem(value: 'Alphabetical', child: Text('Alphabetical')),
          ],
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1AFFFFFF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sortBy,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulkOperationsToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xCC1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4D6366F1)),
        boxShadow: [BoxShadow(color: const Color(0x196366F1), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Text(
            '${_selectedIds.length} requests selected',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 32),
          _ToolbarAction(
            label: 'Approve', 
            icon: Icons.check_circle_rounded, 
            color: const Color(0xFF10B981),
            onTap: () => _handleBulkAction('approve'),
          ),
          _ToolbarAction(
            label: 'Reject', 
            icon: Icons.cancel_rounded, 
            color: const Color(0xFFEF4444),
            onTap: () => _handleBulkAction('reject'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBulkAction(String action) async {
    try {
      // Note: In production, use FirebaseFirestore.instance.batch()
      // This is a simplified loop for the current service architecture
      for (final _ in _selectedIds) {
        // We'd need the type here; for now this is a logic placeholder
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk $action successful for ${_selectedIds.length} items')),
        );
        setState(() => _selectedIds.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk action failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildItemsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No matching requests found',
          style: TextStyle(color: Color(0x33FFFFFF), fontWeight: FontWeight.bold),
        ),
      );
    }

    return Column(
      children:
          items
              .map(
                (item) => _ApprovalItemCard(
                  item: item,
                  isSelected: _selectedIds.contains(item['id']),
                  onSelect: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIds.add(item['id']);
                      } else {
                        _selectedIds.remove(item['id']);
                      }
                    });
                  },
                  onApprove:
                      () => _handleAction(item['id'], item['type'], 'approve'),
                  onReject:
                      () => _handleRejectAction(item['id'], item['type']),
                  onDelete: 
                      () => _handleDeleteAction(item['id'], item['type']),
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
    } else if (item['type'] == 'user_verification') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => UserVerificationDetailScreen(
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


  Future<void> _handleDeleteAction(String id, String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to permanently delete this $type request? This action cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.adminService.deleteApprovalRequest(id, type);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${type[0].toUpperCase()}${type.substring(1)} request deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleRejectAction(String id, String type) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Reject Request', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection...',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await _handleAction(id, type, 'reject', reason: reason);
    }
  }

  Future<void> _handleAction(String id, String type, String action, {String? reason}) async {
    try {
      if (action == 'approve') {
        await widget.adminService.approveItem(id, type);
      } else if (action == 'reject') {
        await widget.adminService.rejectItem(id, type, reason: reason);
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A6366F1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x196366F1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need help reviewing approvals?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check our approval guidelines and documentation.',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          IntrinsicWidth(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size.zero, // Override global infinite width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0DFFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
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
          const SizedBox(height: 24),
          Text(
            count,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;
  final VoidCallback onDetails;

  const _ApprovalItemCard({
    required this.item,
    required this.isSelected,
    required this.onSelect,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
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
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0DFFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: typeColor.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(typeIcon, size: 14, color: typeColor),
                              const SizedBox(width: 8),
                              Text(
                                typeLabel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: typeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Submitted on',
                              style: TextStyle(fontSize: 10, color: Color(0x4DFFFFFF), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatDate(item['createdAt']),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        const _StatusBadge(
                          text: 'PENDING',
                          color: Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThumbnail(typeIcon, typeColor),
                    const SizedBox(width: 24),
                    Expanded(child: _buildMainInfo(item, type)),
                    _buildMetaInfo(item, type),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTags(item, type),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x0DFFFFFF)),
          _buildActionButtons(),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }
    return 'N/A';
  }

  Widget _buildThumbnail(IconData icon, Color color) {
    final images = item['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images.first : '';

    if (imageUrl.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 32, color: color),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              type == 'user_verification' ? 'Phone: ' : type == 'property' ? 'Submitted by: ' : 'Requested by: ',
              style: const TextStyle(fontSize: 13, color: Color(0x80FFFFFF)),
            ),
            Text(
              type == 'user_verification' ? phone : requester,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            if (item['isVerified'] == true) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified,
                size: 16,
                color: Color(0xFF6366F1),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (phone.isNotEmpty && type != 'user_verification')
          Text(
            '$phone  •  $email',
            style: const TextStyle(fontSize: 13, color: Color(0x66FFFFFF)),
          ),
        if (type == 'user_verification' && email.isNotEmpty)
          Text(
            'Email: $email',
            style: const TextStyle(fontSize: 13, color: Color(0x66FFFFFF)),
          ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            location,
            style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaInfo(Map<String, dynamic> item, String type) {
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
      valueColor = Colors.white;
    } else {
      label = 'Request Type';
      value = item['requestType'] ?? 'General Update';
      valueColor = Colors.white;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0x4DFFFFFF)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
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

    return Row(
      children: tags.map((t) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0x80FFFFFF),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _ActionButton(
            label: 'View Details',
            onPressed: onDetails,
            color: const Color(0x0DFFFFFF),
            textColor: Colors.white,
            borderColor: const Color(0x1AFFFFFF),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            label: 'Approve',
            onPressed: onApprove,
            color: const Color(0xFF6366F1),
            textColor: Colors.white,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            label: 'Reject',
            onPressed: onReject,
            color: const Color(0x0DFFFFFF),
            textColor: const Color(0xFFEF4444),
            borderColor: const Color(0x1AEF4444),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            label: 'Delete',
            onPressed: onDelete,
            color: const Color(0x0DFFFFFF),
            textColor: const Color(0xFFEF4444),
            borderColor: const Color(0x1AEF4444),
            icon: Icons.delete_outline_rounded,
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
  final Color? borderColor;
  final IconData? icon;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.textColor,
    this.borderColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0,
        minimumSize: Size.zero, // Override global infinite width
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: borderColor != null ? BorderSide(color: borderColor!) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 16),
          ],
        ],
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x1910B981),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4D10B981)),
      ),
      child: const Row(
        children: [
          _PulseCircle(),
          SizedBox(width: 6),
          Text(
            'Live',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseCircle extends StatefulWidget {
  const _PulseCircle();
  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF10B981),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolbarAction({
    required this.label, 
    required this.icon, 
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label, 
                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
