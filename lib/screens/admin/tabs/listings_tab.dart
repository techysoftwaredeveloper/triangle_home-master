import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/analytics_widgets.dart';
import 'package:triangle_home/screens/admin/widgets/activity_feed_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListingsTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const ListingsTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<ListingsTab> {
  final Set<String> _selectedIds = {};
  bool _isDrawerOpen = false;
  Map<String, dynamic>? _selectedProperty;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          children: [
            // Center Panel: Workspace
            Expanded(
              flex: 3,
              child: _buildWorkspace(),
            ),

            // Right Panel: Intelligence (Only on desktop)
            if (!widget.isNarrow)
              Container(
                width: 320,
                color: const Color(0xFF0F172A),
                child: _buildIntelligencePanel(),
              ),
          ],
        ),

        // Property Detail Drawer
        if (_isDrawerOpen) _buildPropertyDrawer(),
      ],
    );
  }

  Widget _buildWorkspace() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getPropertiesStream(),
      builder: (context, snapshot) {
        final allProperties = snapshot.data ?? [];

        return Container(
          color: const Color(0xFF020617), // Enterprise Dark Background
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildKPISection(),
                const SizedBox(height: 48),
                _buildFiltersSection(),
                const SizedBox(height: 24),
                if (_selectedIds.isNotEmpty) _buildBulkOperationsToolbar(),
                const SizedBox(height: 24),
                _buildListingsGrid(allProperties),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Listings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(width: 12),
                const _LiveBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time overview of all properties and inventory',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildKPISection() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: widget.adminService.getGlobalStatsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        
        return LayoutBuilder(
          builder: (context, constraints) {
            // Dynamically calculate cross axis count based on available width
            int crossAxisCount = 6;
            if (constraints.maxWidth < 600) {
              crossAxisCount = 2;
            } else if (constraints.maxWidth < 1000) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth < 1300) {
              crossAxisCount = 4;
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3, // Slightly taller cards
              children: [
                _KPICard(
                  title: 'Total Properties',
                  value: stats['totalProperties']?.toString() ?? '0',
                  trend: '+8 this month',
                  icon: Icons.business_rounded,
                  color: const Color(0xFF6366F1),
                ),
                _KPICard(
                  title: 'Total Beds',
                  value: stats['totalBeds']?.toString() ?? '0',
                  trend: '+120 this month',
                  icon: Icons.bed_rounded,
                  color: const Color(0xFF3B82F6),
                ),
                _KPICard(
                  title: 'Occupied Beds',
                  value: stats['occupiedBeds']?.toString() ?? '0',
                  subValue: '${stats['occupancyRate'] ?? 0}% Occupancy',
                  icon: Icons.hotel_rounded,
                  color: const Color(0xFF10B981),
                ),
                _KPICard(
                  title: 'Monthly Revenue',
                  value: '₹${stats['monthlyRevenue'] ?? "0"}',
                  trend: '+18.5% vs last month',
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF10B981),
                ),
                _KPICard(
                  title: 'Pending Approvals',
                  value: stats['pendingApprovals']?.toString() ?? '0',
                  link: 'View all >',
                  icon: Icons.assignment_late_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
                _KPICard(
                  title: 'Critical Alerts',
                  value: stats['criticalAlerts']?.toString() ?? '0',
                  link: 'View all >',
                  icon: Icons.warning_rounded,
                  color: const Color(0xFFEF4444),
                  isAlert: true,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFiltersSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _FilterDropdown(label: 'Status', value: 'All'),
        _FilterDropdown(label: 'Occupancy', value: 'All'),
        _FilterDropdown(label: 'Compliance', value: 'All'),
        _FilterDropdown(label: 'Property Type', value: 'All'),
        _FilterDropdown(label: 'City', value: 'All'),
        _FilterDropdown(label: 'Gender', value: 'All'),
        const _MoreFiltersBtn(),
        const _ResetBtn(),
        const _ExportBtn(),
      ],
    );
  }

  Widget _buildBulkOperationsToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Text(
            '${_selectedIds.length} properties selected',
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
          _ToolbarAction(
            label: 'Suspend', 
            icon: Icons.pause_circle_filled_rounded, 
            color: const Color(0xFFF59E0B),
            onTap: () => _handleBulkAction('suspend'),
          ),
          _ToolbarAction(
            label: 'Verify', 
            icon: Icons.verified_user_rounded, 
            color: const Color(0xFF3B82F6),
            onTap: () => _handleBulkAction('verify'),
          ),
          _ToolbarAction(
            label: 'Archive', 
            icon: Icons.archive_rounded, 
            color: Colors.white54,
            onTap: () => _handleBulkAction('archive'),
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
    // Implement atomic batch write
    final batch = FirebaseFirestore.instance.batch();
    final timestamp = FieldValue.serverTimestamp();
    final adminId = 'admin'; // Replace with actual admin ID

    for (final id in _selectedIds) {
      final docRef = FirebaseFirestore.instance.collection('properties').doc(id);
      final auditRef = FirebaseFirestore.instance.collection('auditLogs').doc();

      String newStatus = action == 'approve' ? 'active' : action == 'suspend' ? 'suspended' : action == 'reject' ? 'rejected' : 'archived';

      batch.update(docRef, {
        'status': newStatus,
        'updatedAt': timestamp,
      });

      batch.set(auditRef, {
        'adminId': adminId,
        'action': 'bulk_$action',
        'propertyId': id,
        'timestamp': timestamp,
        'newValue': newStatus,
        'type': 'property',
      });
    }

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully processed $action for ${_selectedIds.length} properties')),
        );
        setState(() => _selectedIds.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing bulk action: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildListingsGrid(List<Map<String, dynamic>> properties) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1300, // Wider for new columns
          child: Column(
            children: [
              _buildGridHeader(),
              if (properties.isEmpty)
                _EmptyState(label: 'No Data Available')
              else
                ...properties.map((p) => _PropertyRow(
                  property: p,
                  isSelected: _selectedIds.contains(p['id']),
                  onSelect: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIds.add(p['id']);
                      } else {
                        _selectedIds.remove(p['id']);
                      }
                    });
                  },
                  onTap: () {
                    setState(() {
                      _selectedProperty = p;
                      _isDrawerOpen = true;
                    });
                  },
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Checkbox(
              value: false,
              onChanged: (v) {},
              activeColor: const Color(0xFF6366F1),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(flex: 3, child: _HeaderLabel('PROPERTY')),
          const Expanded(flex: 2, child: _HeaderLabel('HOSTER')),
          const Expanded(flex: 2, child: _HeaderLabel('INVENTORY')),
          const Expanded(flex: 1, child: _HeaderLabel('OCCUPANCY')),
          const Expanded(flex: 1, child: _HeaderLabel('REVENUE')),
          const Expanded(flex: 2, child: _HeaderLabel('COMPLIANCE')),
          const Expanded(flex: 1, child: _HeaderLabel('HEALTH SCORE')),
          const Expanded(flex: 1, child: _HeaderLabel('STATUS')),
          const SizedBox(width: 48, child: _HeaderLabel('ACTIONS')),
        ],
      ),
    );
  }

  Widget _buildIntelligencePanel() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getActivityLogsStream(),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];
        
        return StreamBuilder<Map<String, dynamic>>(
          stream: widget.adminService.getGlobalStatsStream(),
          builder: (context, statsSnap) {
            final stats = statsSnap.data ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ActivityFeedWidget(activities: activities),
                  const SizedBox(height: 48),
                  const _SectionHeader(label: 'Analytics Intelligence'),
                  const SizedBox(height: 24),
                  OccupancyOverviewDonut(data: stats['occupancyOverview'] ?? {}),
                  const SizedBox(height: 32),
                  RevenueTrendChart(data: stats['revenueTrend'] ?? {}),
                  const SizedBox(height: 32),
                  TopPerformingPropertiesList(properties: stats['topProperties'] ?? []),
                  const SizedBox(height: 32),
                  HighRiskPropertiesList(properties: stats['highRiskProperties'] ?? []),
                  const SizedBox(height: 32),
                  ComplianceSummaryList(data: stats['complianceSummary'] ?? {}),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPropertyDrawer() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 600,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(-10, 0))],
        ),
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(child: _buildDrawerContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedProperty?['name'] ?? 'Property Details',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'ID: ${_selectedProperty?['id'] ?? "N/A"}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => setState(() => _isDrawerOpen = false),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerContent() {
    if (_selectedProperty == null) return _EmptyState(label: 'No property selected');

    return Container(
      color: const Color(0xFF0F172A),
      child: DefaultTabController(
        length: 8, // Prompt requested 8 tabs
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              labelColor: const Color(0xFF8B5CF6),
              unselectedLabelColor: Colors.white38,
              indicatorColor: const Color(0xFF8B5CF6),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Rooms'),
                Tab(text: 'Beds'),
                Tab(text: 'Residents'),
                Tab(text: 'Bookings'),
                Tab(text: 'Payments'),
                Tab(text: 'Complaints'),
                Tab(text: 'Compliance'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildRoomsTab(),
                  _buildBedsTab(),
                  _buildResidentsTab(),
                  _buildBookingsTab(),
                  _buildPaymentsTab(),
                  _buildComplaintsTab(),
                  _buildComplianceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _DetailSection(title: 'Property Information'),
        _DetailItem(label: 'Name', value: _selectedProperty?['name']),
        _DetailItem(label: 'Location', value: _selectedProperty?['location']),
        _DetailItem(label: 'Type', value: _selectedProperty?['category']),
        _DetailItem(label: 'Gender', value: _selectedProperty?['gender']),
        const SizedBox(height: 24),
        const _DetailSection(title: 'Hoster Information'),
        _DetailItem(label: 'Hoster', value: _selectedProperty?['hosterName']),
        _DetailItem(label: 'Phone', value: _selectedProperty?['hosterPhone']),
        _DetailItem(label: 'Email', value: _selectedProperty?['hosterEmail']),
        const SizedBox(height: 24),
        const _DetailSection(title: 'Operational Status'),
        _DetailItem(label: 'Status', value: _selectedProperty?['status'], isStatus: true),
        _DetailItem(label: 'Health Score', value: _selectedProperty?['healthScore']?.toString() ?? 'N/A'),
      ],
    );
  }

  Widget _buildBookingsTab() => const _NotConfigured(label: 'Bookings');

  Widget _buildRoomsTab() {
    final propertyId = _selectedProperty?['id'];
    if (propertyId == null) return _EmptyState(label: 'Select a property');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .collection('rooms')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final rooms = snapshot.data?.docs ?? [];
        
        if (rooms.isEmpty) return const _NotConfigured(label: 'Rooms');

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index].data();
            return _DrawerListTile(
              title: 'Room ${room['roomNumber']}',
              subtitle: '${room['type'] ?? "Standard"} • ${room['sharing'] ?? 1} Sharing',
              trailing: '${room['occupancy'] ?? 0}% Full',
              icon: Icons.meeting_room_rounded,
              color: const Color(0xFF6366F1),
            );
          },
        );
      },
    );
  }

  Widget _buildBedsTab() {
    final propertyId = _selectedProperty?['id'];
    if (propertyId == null) return _EmptyState(label: 'Select a property');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('beds')
          .where('propertyId', isEqualTo: propertyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final beds = snapshot.data?.docs ?? [];

        if (beds.isEmpty) return const _NotConfigured(label: 'Beds');

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: beds.length,
          itemBuilder: (context, index) {
            final bed = beds[index].data();
            final status = bed['status'] ?? 'available';
            final color = _getBedColor(status);

            return Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bed_rounded, color: color, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'B${bed['bedNumber'] ?? index + 1}', 
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getBedColor(String status) {
    switch (status.toLowerCase()) {
      case 'occupied': return const Color(0xFF10B981);
      case 'reserved': return const Color(0xFFF59E0B);
      case 'blocked': return const Color(0xFFEF4444);
      case 'maintenance': return const Color(0xFF3B82F6);
      default: return Colors.white38;
    }
  }

  Widget _buildResidentsTab() {
    final propertyId = _selectedProperty?['id'];
    if (propertyId == null) return _EmptyState(label: 'Select a property');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('activePropertyId', isEqualTo: propertyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final residents = snapshot.data?.docs ?? [];

        if (residents.isEmpty) return const _NotConfigured(label: 'Residents');

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: residents.length,
          itemBuilder: (context, index) {
            final resident = residents[index].data();
            return _DrawerListTile(
              title: resident['name'] ?? 'Unknown Resident',
              subtitle: resident['email'] ?? 'No Email',
              trailing: 'Room ${resident['roomNumber'] ?? "N/A"}',
              icon: Icons.person_rounded,
              color: const Color(0xFF8B5CF6),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    final propertyId = _selectedProperty?['id'];
    if (propertyId == null) return _EmptyState(label: 'Select a property');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('propertyId', isEqualTo: propertyId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final payments = snapshot.data?.docs ?? [];

        if (payments.isEmpty) return const _NotConfigured(label: 'Payments');

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index].data();
            final status = payment['status'] ?? 'pending';
            final amount = payment['amount'] ?? 0;

            return _DrawerListTile(
              title: '₹$amount',
              subtitle: payment['type'] ?? 'Rent Payment',
              trailing: status.toString().toUpperCase(),
              icon: Icons.payments_rounded,
              color: status == 'paid' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            );
          },
        );
      },
    );
  }

  Widget _buildComplaintsTab() {
    final propertyId = _selectedProperty?['id'];
    if (propertyId == null) return _EmptyState(label: 'Select a property');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('propertyId', isEqualTo: propertyId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final complaints = snapshot.data?.docs ?? [];

        if (complaints.isEmpty) return const _NotConfigured(label: 'Complaints');

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index].data();
            return _DrawerListTile(
              title: complaint['title'] ?? 'Complaint',
              subtitle: complaint['category'] ?? 'General',
              trailing: complaint['status']?.toString().toUpperCase(),
              icon: Icons.report_problem_rounded,
              color: const Color(0xFFEF4444),
            );
          },
        );
      },
    );
  }

  Widget _buildComplianceTab() {
    final propertyId = _selectedProperty?['id'];
    if (propertyId == null) return _EmptyState(label: 'Select a property');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('complianceStats')
          .doc(propertyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data?.data() ?? {};

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _ComplianceDocItem(label: 'KYC Document', status: stats['kycStatus']),
            _ComplianceDocItem(label: 'Fire Safety Certificate', status: stats['fireSafetyStatus']),
            _ComplianceDocItem(label: 'Police Verification', status: stats['policeStatus']),
            _ComplianceDocItem(label: 'Business License', status: stats['licenseStatus']),
          ],
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Add New Listing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 44, width: 1, color: Colors.white24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
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
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          _PulseCircle(),
          SizedBox(width: 6),
          Text(
            'Live',
            style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
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

class _PulseCircleState extends State<_PulseCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FadeTransition(
          opacity: _controller,
          child: Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle)),
        ),
        const SizedBox(width: 6),
        const Text(
          'Live',
          style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final String? subValue;
  final String? link;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const _KPICard({
    required this.title,
    required this.value,
    this.trend,
    this.subValue,
    this.link,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5), // Glassmorphism
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? const Color(0xFFEF4444).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: isAlert 
            ? [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)] 
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (link != null)
                Flexible(
                  child: Text(
                    link!, 
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Text(
              trend!, 
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              subValue!, 
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  const _FilterDropdown({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _MoreFiltersBtn extends StatelessWidget {
  const _MoreFiltersBtn();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune_rounded, size: 16, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 8),
          const Text('More Filters', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ResetBtn extends StatelessWidget {
  const _ResetBtn();
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(Icons.refresh_rounded, size: 16, color: Colors.white.withValues(alpha: 0.4)),
      label: Text('Reset', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _ExportBtn extends StatelessWidget {
  const _ExportBtn();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.file_download_outlined, size: 16, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 8),
          const Text('Export', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
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
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String label;
  const _HeaderLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10, 
        fontWeight: FontWeight.bold, 
        color: Colors.white.withValues(alpha: 0.3), 
        letterSpacing: 1.0,
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final Map<String, dynamic> property;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onTap;

  const _PropertyRow({
    required this.property,
    required this.isSelected,
    required this.onSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Checkbox(
                value: isSelected,
                onChanged: onSelect,
                activeColor: const Color(0xFF6366F1),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: _PropertyInfo(property: property)),
            Expanded(flex: 2, child: _HosterInfo(property: property)),
            Expanded(flex: 2, child: _InventoryInfo(property: property)),
            Expanded(flex: 1, child: _OccupancyRing(value: property['occupancy'] ?? 0)),
            Expanded(flex: 1, child: _RevenueInfo(property: property)),
            Expanded(flex: 2, child: _ComplianceBadges(property: property)),
            Expanded(flex: 1, child: _HealthScore(score: property['healthScore'] ?? 0)),
            Expanded(flex: 1, child: _StatusBadge(status: property['status'])),
            SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF475569)),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyInfo extends StatelessWidget {
  final Map<String, dynamic> property;
  const _PropertyInfo({required this.property});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            property['propertyImage'] ?? 'https://via.placeholder.com/48',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 48,
              height: 48,
              color: Colors.white.withValues(alpha: 0.05),
              child: const Icon(Icons.home_work_rounded, color: Colors.white38, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                property['name'] ?? 'Untitled',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'ID: ${property['id']?.substring(0, 8) ?? "N/A"}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
              ),
              Text(
                property['location'] ?? 'Unknown',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HosterInfo extends StatelessWidget {
  final Map<String, dynamic> property;
  const _HosterInfo({required this.property});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
          child: Text(
            (property['hosterName'] ?? 'U')[0],
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                property['hosterName'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Text('Verified', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryInfo extends StatelessWidget {
  final Map<String, dynamic> property;
  const _InventoryInfo({required this.property});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${property['beds'] ?? 0} Beds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
        Text('${property['rooms'] ?? 0} Rooms', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }
}

class _OccupancyRing extends StatelessWidget {
  final int value;
  const _OccupancyRing({required this.value});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: value / 100,
              strokeWidth: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(_getColor(value)),
            ),
          ),
          Text('$value%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
  Color _getColor(int v) {
    if (v > 75) return const Color(0xFF10B981);
    if (v > 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _RevenueInfo extends StatelessWidget {
  final Map<String, dynamic> property;
  const _RevenueInfo({required this.property});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('₹${property['revenue'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
        const Row(
          children: [
            Icon(Icons.arrow_upward, color: Color(0xFF10B981), size: 10),
            Text('12.4%', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _ComplianceBadges extends StatelessWidget {
  final Map<String, dynamic> property;
  const _ComplianceBadges({required this.property});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ComplianceIcon(
          icon: Icons.assignment_ind_rounded, 
          color: property['kycStatus'] == 'verified' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          label: 'KYC',
        ),
        _ComplianceIcon(
          icon: Icons.local_fire_department_rounded, 
          color: property['fireSafetyStatus'] == 'verified' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          label: 'Fire',
        ),
        _ComplianceIcon(
          icon: Icons.security_rounded, 
          color: property['policeStatus'] == 'verified' ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.24),
          label: 'Police',
        ),
        _ComplianceIcon(
          icon: Icons.policy_rounded, 
          color: property['licenseStatus'] == 'verified' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          label: 'License',
        ),
      ],
    );
  }
}

class _ComplianceIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _ComplianceIcon({
    required this.icon, 
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: color, size: 12),
        ),
      ),
    );
  }
}

class _HealthScore extends StatelessWidget {
  final int score;
  const _HealthScore({required this.score});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getColor(score).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          score.toString(),
          style: TextStyle(color: _getColor(score), fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
  Color _getColor(int s) {
    if (s > 80) return const Color(0xFF10B981);
    if (s > 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({this.status});
  @override
  Widget build(BuildContext context) {
    final label = status?.toUpperCase() ?? 'DRAFT';
    final color = _getColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }
  Color _getColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'active': case 'approved': return const Color(0xFF10B981);
      case 'pending': case 'review': return const Color(0xFFF59E0B);
      case 'rejected': case 'suspended': return const Color(0xFFEF4444);
      default: return const Color(0xFF94A3B8);
    }
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  const _DetailSection({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool isStatus;
  const _DetailItem({required this.label, this.value, this.isStatus = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          if (isStatus) 
            _StatusBadge(status: value?.toString()) 
          else 
            Text(
              value?.toString() ?? 'N/A', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _NotConfigured extends StatelessWidget {
  final String label;
  const _NotConfigured({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync_problem_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            '$label Not Configured', 
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
          ),
          Text(
            'Awaiting Sync', 
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label, 
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
    );
  }
}

class _ComplianceDocItem extends StatelessWidget {
  final String label;
  final String? status;

  const _ComplianceDocItem({required this.label, this.status});

  @override
  Widget build(BuildContext context) {
    final isVerified = status == 'verified';
    final color = isVerified ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.description_rounded, color: Colors.white.withValues(alpha: 0.2), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              (status ?? 'MISSING').toUpperCase(), 
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  final IconData icon;
  final Color color;

  const _DrawerListTile({
    required this.title, 
    required this.subtitle, 
    this.trailing, 
    required this.icon, 
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
            Text(
              label, 
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
