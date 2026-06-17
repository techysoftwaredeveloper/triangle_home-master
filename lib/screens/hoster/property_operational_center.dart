import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/core/extensions/string_extensions.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/services/booking_service.dart';
import 'package:triangle_home/services/lead_service.dart';
import 'package:triangle_home/services/inventory_service.dart';
import 'package:triangle_home/services/resident_service.dart';
import 'package:triangle_home/services/finance_service.dart';
import 'package:triangle_home/services/admin_api_service.dart';
import 'package:triangle_home/services/property_structure_service.dart';
import 'package:triangle_home/models/lead.dart';
import 'package:triangle_home/models/room_model.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/staff_service.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/models/staff_model.dart';
import 'package:triangle_home/models/user.dart' as model;

num _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
  return 0;
}

class PropertyOperationalCenter extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> propertyData;

  const PropertyOperationalCenter({
    super.key,
    required this.propertyId,
    required this.propertyData,
  });

  @override
  State<PropertyOperationalCenter> createState() => _PropertyOperationalCenterState();
}

class _PropertyOperationalCenterState extends State<PropertyOperationalCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PropertyService _propertyService = PropertyService();
  final BookingService _bookingService = BookingService();
  final LeadService _leadService = LeadService();
  final AdminApiService _adminApiService = AdminApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _propertyService.getPropertyBeds(widget.propertyId),
      builder: (context, bedSnapshot) {
        final allBeds = bedSnapshot.data ?? [];
        final totalBeds = allBeds.length;
        final occupiedBeds = allBeds.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'occupied').length;
        final vacantBeds = allBeds.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'available').length;
        final reservedBeds = allBeds.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'reserved').length;
        final maintenanceBeds = allBeds.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'maintenance').length;
        final blockedBeds = allBeds.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'blocked').length;

        final occupancyRate = totalBeds > 0 ? (occupiedBeds / totalBeds * 100).round() : 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: _buildPropertyHeroSummary(totalBeds, vacantBeds, occupiedBeds, reservedBeds, maintenanceBeds, blockedBeds),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    child: _buildTabBar(),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  propertyId: widget.propertyId,
                  totalBeds: totalBeds,
                  occupiedBeds: occupiedBeds,
                  vacantBeds: vacantBeds,
                  reservedBeds: reservedBeds,
                  blockedBeds: blockedBeds,
                  occupancyRate: occupancyRate,
                  propertyService: _propertyService,
                  bookingService: _bookingService,
                  leadService: _leadService,
                  tabController: _tabController,
                  propertyData: widget.propertyData,
                ),
                _BedsTab(propertyId: widget.propertyId, propertyData: widget.propertyData),
                _ResidentsTab(propertyId: widget.propertyId),
                _BookingsTab(propertyId: widget.propertyId, bookingService: _bookingService),
                _FinanceTab(propertyId: widget.propertyId),
                _LeadsTab(propertyId: widget.propertyId, leadService: _leadService),
                _HostsTab(
                  propertyId: widget.propertyId,
                  ownerId: widget.propertyData['ownerId'] ?? '',
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _handleFabPress(),
            backgroundColor: AppTheme.successColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              _getFabLabel(), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        );
      }
    );
  }

  String _getFabLabel() {
    switch (_tabController.index) {
      case 0: return 'New Booking';
      case 1: return 'Add Room / Bed';
      case 2: return 'Add Resident';
      case 3: return 'New Booking';
      case 4: return 'Log Expense';
      case 5: return 'Add Lead';
      case 6: return 'Invite Host';
      default: return 'New';
    }
  }

  void _handleFabPress() {
    switch (_tabController.index) {
      case 0: _tabController.animateTo(3); break;
      case 1: _showAddRoomDialog(); break;
      case 2: _tabController.animateTo(3); break;
      case 4: _showAddExpenseDialog(); break;
      case 6: _showInviteHostDialog(); break;
      default: _showAddRoomDialog();
    }
  }

  void _showAddRoomDialog({int? initialFloor}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRoomBottomSheet(
        propertyId: widget.propertyId,
        propertyData: widget.propertyData,
        initialFloor: initialFloor,
        onComplete: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room created successfully'))),
      ),
    );
  }

  void _showAddFloorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddFloorBottomSheet(
        propertyId: widget.propertyId,
        onComplete: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Floor added successfully'))),
      ),
    );
  }

  void _showAddBedDialog(Map<String, dynamic> room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddBedBottomSheet(
        propertyId: widget.propertyId,
        propertyData: widget.propertyData,
        room: room,
        onComplete: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bed added successfully'))),
      ),
    );
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddExpenseDialog(
        propertyId: widget.propertyId,
        onComplete: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense logged successfully'))),
      ),
    );
  }

  void _showInviteHostDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteHostDialog(
        propertyId: widget.propertyId,
        onComplete: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent successfully'))),
      ),
    );
  }

  void _showManagePermissionsDialog(HostAssignment staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManagePermissionsDialog(
        staff: staff,
        onComplete: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions updated successfully'))),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.propertyData['name'] ?? 'Property Name',
                style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Outfit'),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                child: const Text('Active', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                '${widget.propertyData['locality'] ?? ""}, ${widget.propertyData['city'] ?? "Kochi"}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _appBarAction(Icons.file_upload_outlined, 'Export', () {}),
        _appBarAction(Icons.add_box_outlined, 'Add Room', () => _showAddRoomDialog()),
        IconButton(icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1E293B)), onPressed: () {}),
      ],
    );
  }

  Widget _appBarAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1E293B), size: 20),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyHeroSummary(int totalBeds, int vacantBeds, int occupiedBeds, int reservedBeds, int maintenanceBeds, int blockedBeds) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tag(Icons.apartment_rounded, 'Hostel / PG'),
              const SizedBox(width: 8),
              _tag(Icons.male_rounded, 'Male Accommodation'),
              const SizedBox(width: 8),
              _tag(Icons.restaurant_rounded, 'Food Available'),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _heroStatCard(totalBeds.toString(), 'Total Beds', Icons.hotel, const Color(0xFF1E293B)),
                _heroStatCard(occupiedBeds.toString(), 'Occupied Beds', Icons.person_outline, const Color(0xFF16A34A)),
                _heroStatCard(vacantBeds.toString(), 'Available Beds', Icons.bed_outlined, const Color(0xFF3B82F6)),
                _heroStatCard(reservedBeds.toString(), 'Reserved Beds', Icons.event_available, const Color(0xFFF59E0B)),
                _heroStatCard(maintenanceBeds.toString(), 'Maintenance', Icons.build_circle_outlined, const Color(0xFFEF4444)),
                _heroStatCard(blockedBeds.toString(), 'Blocked Beds', Icons.lock_outline, const Color(0xFF64748B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _heroStat(String val, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _tag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1))),
      child: TabBar(
        controller: _tabController, isScrollable: true,
        labelColor: const Color(0xFF16A34A), unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF16A34A), indicatorWeight: 3, indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'), Tab(text: 'Beds & Inventory'), Tab(text: 'Residents'),
          Tab(text: 'Bookings'), Tab(text: 'Finance'), Tab(text: 'Leads'), Tab(text: 'Hosts'),
        ],
      ),
    );
  }
}

// ── Overview Tab ────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final String propertyId;
  final int totalBeds;
  final int occupiedBeds;
  final int vacantBeds;
  final int reservedBeds;
  final int blockedBeds;
  final int occupancyRate;
  final PropertyService propertyService;
  final BookingService bookingService;
  final LeadService leadService;
  final TabController tabController;
  final Map<String, dynamic> propertyData;

  const _OverviewTab({
    required this.propertyId,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.vacantBeds,
    required this.reservedBeds,
    required this.blockedBeds,
    required this.occupancyRate,
    required this.propertyService,
    required this.bookingService,
    required this.leadService,
    required this.tabController,
    required this.propertyData,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildOccupancyOverview(context),
        const SizedBox(height: 24),
        _buildBedInventorySnapshot(context),
        const SizedBox(height: 24),
        _buildResidentQuickMetrics(context),
        const SizedBox(height: 24),
        _buildDualOverview(context),
        const SizedBox(height: 24),
        _buildHostAndActions(context),
        const SizedBox(height: 24),
        _buildRecentActivityAndAmenities(context),
        const SizedBox(height: 60),
      ],
    );
  }

  // 1. Occupancy Overview
  Widget _buildOccupancyOverview(BuildContext context) {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader(Icons.pie_chart_outline_rounded, 'Occupancy Overview', const Color(0xFF16A34A)),
              _viewDetailsBtn(() => tabController.animateTo(1)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniMetric('Total Beds', '$totalBeds', null),
              _miniMetric('Occupied', '$occupiedBeds', const Color(0xFF16A34A)),
              _miniMetric('Vacant', '$vacantBeds', const Color(0xFF3B82F6)),
              _miniMetric('Reserved', '$reservedBeds', const Color(0xFFF59E0B)),
              _miniMetric('Blocked', '$blockedBeds', const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Occupancy Progress', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              Text('$occupancyRate%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: occupancyRate / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Bed Inventory Snapshot (Realtime)
  Widget _buildBedInventorySnapshot(BuildContext context) {
    return StreamBuilder<List<RoomModel>>(
      stream: InventoryService().getPropertyRooms(propertyId),
      builder: (context, roomSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: propertyService.getPropertyBeds(propertyId),
          builder: (context, bedSnapshot) {
            final rooms = roomSnapshot.data ?? [];
            final beds = bedSnapshot.data ?? [];

            final Map<int, List<RoomModel>> grouped = {};
            for (final r in rooms) { grouped.putIfAbsent(r.floor, () => []).add(r); }
            final sortedFloors = grouped.keys.toList()..sort();

            return _sectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 12),
                          const Text('Bed Inventory Snapshot (Floor Wise)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                        ],
                      ),
                      _viewDetailsBtn(() => tabController.animateTo(1), label: 'View All Beds'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (rooms.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No rooms configured', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))))),
                  ...sortedFloors.take(3).map((floor) {
                    final floorRooms = grouped[floor]!;
                    final isFirst = floor == sortedFloors.first;
                    return Column(
                      children: [
                        _OverviewFloorSection(
                          label: floor == 0 ? 'Ground Floor' : 'Floor $floor',
                          initialExpanded: isFirst,
                          child: _buildRealtimeRoomPreviewRow(context, floorRooms, beds),
                        ),
                        if (floor != sortedFloors.last) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend('Occupied', const Color(0xFF16A34A)),
                      const SizedBox(width: 16),
                      _legend('Vacant', const Color(0xFF3B82F6)),
                      const SizedBox(width: 16),
                      _legend('Reserved', const Color(0xFFF59E0B)),
                      const SizedBox(width: 16),
                      _legend('Maintenance', const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildRealtimeRoomPreviewRow(BuildContext context, List<RoomModel> floorRooms, List<Map<String, dynamic>> allBeds) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: floorRooms.map((r) {
          final roomBeds = allBeds.where((b) => b['roomId'] == r.id).toList();
          return _roomSnapCard('Room ${r.roomNumber}', '${r.totalBeds} Beds', roomBeds);
        }).toList(),
      ),
    );
  }

  Widget _roomSnapCard(String title, String subtitle, List<Map<String, dynamic>> beds) {
    return Container(
      width: 150, margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B))),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: beds.map((b) {
              final status = b['status']?.toString().toLowerCase() ?? 'available';
              Color color = status == 'occupied' ? const Color(0xFF16A34A) : status == 'available' ? const Color(0xFF3B82F6) : status == 'reserved' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
              return Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 3. Resident Quick Metrics
  Widget _buildResidentQuickMetrics(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _residentStatBox(Icons.people_outline, 'Active Residents', '21', const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _residentStatBox(Icons.calendar_today_outlined, 'Upcoming Check-ins', '2', const Color(0xFF16A34A))),
        const SizedBox(width: 12),
        Expanded(child: _residentStatBox(Icons.exit_to_app_rounded, 'Upcoming Check-outs', '1', const Color(0xFFEF4444))),
        const SizedBox(width: 12),
        Expanded(child: _residentStatBox(Icons.campaign_outlined, 'Notice Submitted', '0', const Color(0xFFF59E0B))),
      ],
    );
  }

  Widget _residentStatBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: color, size: 16), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const Text('View All >', style: TextStyle(fontSize: 7, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 4. Dual Overview Sections
  Widget _buildDualOverview(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _sectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Revenue Overview (This Month)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 16),
              _revRow('Expected Revenue', '₹65,000'),
              _revRow('Collected Revenue', '₹49,500', color: const Color(0xFF16A34A)),
              _revRow('Pending Revenue', '₹13,500', color: const Color(0xFFF59E0B)),
              _revRow('Overdue Payments', '₹2,000', color: const Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: _viewDetailsBtn(() => tabController.animateTo(4), label: 'View Finance')),
            ],
          ),
        )),
        const SizedBox(width: 16),
        Expanded(child: _sectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Booking Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 16),
              _pipeRow(Icons.auto_awesome_outlined, 'New Leads', '36', const Color(0xFF3B82F6)),
              _pipeRow(Icons.calendar_today_outlined, 'Visits Scheduled', '18', const Color(0xFFF59E0B)),
              _pipeRow(Icons.bookmark_outline_rounded, 'Bookings Pending', '8', const Color(0xFF8B5CF6)),
              _pipeRow(Icons.check_circle_outline_rounded, 'Confirmed Bookings', '12', const Color(0xFF16A34A)),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: _viewDetailsBtn(() => tabController.animateTo(5), label: 'View Leads & Bookings')),
            ],
          ),
        )),
      ],
    );
  }

  // 5. Host & Quick Actions
  Widget _buildHostAndActions(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _sectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assigned Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://img.freepik.com/free-photo/handsome-man_23-2148844715.jpg')),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Ajay Kumar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    _statusBadge('Primary Host', const Color(0xFF16A34A)),
                  ])),
                ],
              ),
              const SizedBox(height: 12),
              const Text('+91 98765 43210', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              const Text('since 12 Jan 2024', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _outlineBtn(Icons.call_outlined, 'Call', const Color(0xFF16A34A))),
                const SizedBox(width: 8),
                Expanded(child: _outlineBtn(Icons.person_outline, 'Change', const Color(0xFF64748B))),
              ]),
            ],
          ),
        )),
        const SizedBox(width: 16),
        Expanded(flex: 4, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.3,
              children: [
                _qAction(Icons.event_available, 'Add Booking', const Color(0xFF16A34A)),
                _qAction(Icons.bed_outlined, 'Assign Bed', const Color(0xFF3B82F6)),
                _qAction(Icons.people_outline, 'Residents', const Color(0xFF8B5CF6)),
                _qAction(Icons.calendar_today, 'Bookings', const Color(0xFFF59E0B)),
                _qAction(Icons.payments_outlined, 'Payments', const Color(0xFF16A34A)),
                _qAction(Icons.report_gmailerrorred_rounded, 'Complaints', const Color(0xFFEF4444)),
              ],
            ),
          ],
        )),
      ],
    );
  }

  // 6. Recent Activity & Amenities
  Widget _buildRecentActivityAndAmenities(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _sectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), _viewDetailsBtn(() => {})]),
              const SizedBox(height: 16),
              _activityItem(Icons.bed_rounded, 'Bed D203-C marked as Vacant', 'Today, 09:30 AM', const Color(0xFF3B82F6)),
              _activityItem(Icons.calendar_today, 'New booking confirmed for Bed D204-A', 'Today, 08:15 AM', const Color(0xFF16A34A)),
              _activityItem(Icons.payments_outlined, 'Rent collected from 3 residents', 'Yesterday, 07:45 PM', const Color(0xFFF59E0B)),
            ],
          ),
        )),
        const SizedBox(width: 16),
        Expanded(child: _sectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), _viewDetailsBtn(() => {})]),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8, crossAxisSpacing: 8,
                children: [
                  _amenity(Icons.wifi, 'WiFi'),
                  _amenity(Icons.videocam_outlined, 'CCTV'),
                  _amenity(Icons.restaurant, 'Food'),
                  _amenity(Icons.local_laundry_service, 'Laundry'),
                  _amenity(Icons.local_parking, 'Parking'),
                  _amenity(Icons.battery_charging_full, 'Backup'),
                  _amenity(Icons.water_drop, 'RO Water'),
                  _amenity(Icons.hot_tub, 'Hot Water'),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  // Common UI Patterns
  Widget _sectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: child,
    );
  }

  Widget _sectionHeader(IconData? icon, String title, Color color) {
    return Row(children: [
      if (icon != null) Icon(icon, color: color, size: 18),
      if (icon != null) const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
    ]);
  }

  Widget _viewDetailsBtn(VoidCallback onTap, {String label = 'View Details'}) {
    return InkWell(onTap: onTap, child: Text(label, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Widget _miniMetric(String label, String value, Color? color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF1E293B))),
      Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _legend(String l, Color c) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 4), Text(l, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)))]);
  }

  Widget _revRow(String l, String v, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))), Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF1E293B)))]),
    );
  }

  Widget _pipeRow(IconData i, String l, String v, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [Icon(i, size: 12, color: c), const SizedBox(width: 8), Expanded(child: Text(l, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))), Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _statusBadge(String t, Color c) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(t, style: TextStyle(color: c, fontSize: 7, fontWeight: FontWeight.bold)));
  }

  Widget _outlineBtn(IconData i, String l, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: c.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 12, color: c), const SizedBox(width: 4), Text(l, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _qAction(IconData i, String l, Color c) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: c, size: 14), const SizedBox(height: 2), Text(l, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]),
    );
  }

  Widget _activityItem(IconData i, String t, String s, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Icon(i, size: 14, color: c), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)), Text(s, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)))]))]),
    );
  }

  Widget _amenity(IconData i, String l) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 14, color: const Color(0xFF16A34A)), const SizedBox(height: 2), Text(l, style: const TextStyle(fontSize: 7, color: Color(0xFF64748B)))]);
  }

  Color _getBedColorByCode(String code) {
    if (code == 'O') return const Color(0xFF16A34A);
    if (code == 'V') return const Color(0xFF3B82F6);
    if (code == 'R') return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ── Floor Section ──────────────────────────────────────────────────────────
class _FloorSection extends StatefulWidget {
  final int floorNumber;
  final List<RoomModel> rooms;
  final List<Map<String, dynamic>> beds;
  final int floorOccupied;
  final int floorTotal;
  final Widget Function(String) bedIndicatorBuilder;
  final Widget Function(String, String, List<String>, {String? occupancyType, VoidCallback? onAddBed}) roomCardBuilder;
  final VoidCallback onAddRoom;

  const _FloorSection({
    required this.floorNumber, required this.rooms, required this.beds,
    required this.floorOccupied, required this.floorTotal,
    required this.bedIndicatorBuilder, required this.roomCardBuilder,
    required this.onAddRoom,
  });

  @override
  State<_FloorSection> createState() => _FloorSectionState();
}

class _FloorSectionState extends State<_FloorSection> {
  bool _expanded = true;
  String? _expandedRoomId;

  @override
  Widget build(BuildContext context) {
    final label = widget.floorNumber == 0 ? 'Ground Floor' : 'Floor ${widget.floorNumber}';
    final available = widget.beds.where((b) => widget.rooms.any((r) => r.id == b['roomId']) && b['status'] == 'available').length;
    final reserved = widget.beds.where((b) => widget.rooms.any((r) => r.id == b['roomId']) && b['status'] == 'reserved').length;
    final maintenance = widget.beds.where((b) => widget.rooms.any((r) => r.id == b['roomId']) && b['status'] == 'maintenance').length;
    
    final occupancyRate = widget.floorTotal > 0 ? (widget.floorOccupied / widget.floorTotal * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.layers_outlined, size: 20, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                        Text('${widget.rooms.length} Rooms • ${widget.floorTotal} Beds', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _miniStat('Occupied', widget.floorOccupied, const Color(0xFF16A34A)),
                          _miniStat('Available', available, const Color(0xFF3B82F6)),
                          _miniStat('Reserved', reserved, const Color(0xFFF59E0B)),
                          _miniStat('Maintenance', maintenance, const Color(0xFFEF4444)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 32, height: 32,
                        child: CircularProgressIndicator(value: occupancyRate / 100, strokeWidth: 3, backgroundColor: const Color(0xFFF1F5F9), color: const Color(0xFF16A34A)),
                      ),
                      Text('$occupancyRate%', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF64748B), size: 20),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 20),
                LayoutBuilder(builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
                  double spacing = 12;
                  double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

                  return Wrap(
                    spacing: spacing, runSpacing: spacing,
                    children: widget.rooms.map((r) {
                      final roomBeds = widget.beds.where((b) => b['roomId'] == r.id).toList();
                      
                      return SizedBox(
                        width: itemWidth,
                        child: widget.roomCardBuilder(
                          'Room ${r.roomNumber}', r.occupancyType, roomBeds.map((b) => b['status'].toString()).toList(),
                          occupancyType: r.occupancyType,
                          onAddBed: () {
                            setState(() {
                              if (_expandedRoomId == r.id) {
                                _expandedRoomId = null;
                              } else {
                                _expandedRoomId = r.id;
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ],
          ),
        ),
        if (_expanded && _expandedRoomId != null) ...[
          const SizedBox(height: 16),
          _buildExpandedRoomDetails(_expandedRoomId!),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
          Text(value.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildExpandedRoomDetails(String roomId) {
    RoomModel? room;
    for (final r in widget.rooms) {
      if (r.id == roomId) {
        room = r;
        break;
      }
    }

    if (room == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _expandedRoomId != null) {
          setState(() => _expandedRoomId = null);
        }
      });
      return const SizedBox.shrink();
    }

    final roomBeds = widget.beds.where((b) => b['roomId'] == roomId).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Room ${room?.roomNumber ?? ""} • ${room?.occupancyType ?? ""} (${room?.totalBeds ?? 0} Beds)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              TextButton(onPressed: () => setState(() => _expandedRoomId = null), child: const Text('Collapse', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(0.8),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(3),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1.2),
            },
            children: [
              const TableRow(
                children: [
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Bed', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Status', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Resident / Booking', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Check-in Date', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Rent', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Actions', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))),
                ],
              ),
              ...roomBeds.asMap().entries.map((entry) {
                final i = entry.key;
                final b = entry.value;
                final bedLabel = '${room?.roomNumber ?? ""}-${String.fromCharCode(65 + i)}';
                final status = b['status']?.toString().toLowerCase() ?? 'available';
                final color = status == 'occupied' ? const Color(0xFF16A34A) : status == 'available' ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);
                
                return TableRow(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(bedLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: color),
                            const SizedBox(width: 4),
                            Text(status.capitalize(), style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: status == 'occupied' ? Row(
                        children: [
                          const CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Arjun Nair', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              Text('Booking ID: BK-2025-${1048+i}', style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ) : Text(status == 'available' ? '—' : 'Reserved for Guest', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(status == 'occupied' ? '10 May 2025' : '—', style: const TextStyle(fontSize: 9))),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('₹8,000', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          if (status == 'occupied') const Text('Paid', style: TextStyle(fontSize: 8, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          const Icon(Icons.more_vert, size: 14, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Beds Tab ────────────────────────────────────────────────────────────
class _BedsTab extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> propertyData;
  const _BedsTab({required this.propertyId, required this.propertyData});
  @override
  State<_BedsTab> createState() => _BedsTabState();
}

class _BedsTabState extends State<_BedsTab> {
  final _structureService = PropertyStructureService();
  int? _selectedFloor;
  String _selectedRoomType = 'All Room Types';
  String _selectedStatus = 'All Status';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomModel>>(
      stream: InventoryService().getPropertyRooms(widget.propertyId),
      builder: (context, roomSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: PropertyService().getPropertyBeds(widget.propertyId),
          builder: (context, bedSnapshot) {
            if (!roomSnapshot.hasData || !bedSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final rooms = roomSnapshot.data!;
            final beds = bedSnapshot.data!;

            final totalBeds = beds.length;
            final occupiedBeds = beds.where((b) => b['status'] == 'occupied').length;
            final availableBeds = beds.where((b) => b['status'] == 'available').length;
            final reservedBeds = beds.where((b) => b['status'] == 'reserved').length;
            final maintenanceBeds = beds.where((b) => b['status'] == 'maintenance').length;
            final blockedBeds = beds.where((b) => b['status'] == 'blocked').length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBedStats(totalBeds, occupiedBeds, availableBeds, reservedBeds, maintenanceBeds, blockedBeds),
                const SizedBox(height: 24),
                _buildFilters(rooms),
                const SizedBox(height: 16),
                _buildFloorSelector(rooms),
                const SizedBox(height: 24),
                _buildInventoryList(context, rooms, beds),
                const SizedBox(height: 100),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildBedStats(int total, int occupied, int available, int reserved, int maintenance, int blocked) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard('Total Beds', total.toString(), Icons.hotel, const Color(0xFF1E293B)),
          _statCard('Occupied Beds', occupied.toString(), Icons.person_outline, const Color(0xFF16A34A)),
          _statCard('Available Beds', available.toString(), Icons.bed_outlined, const Color(0xFF3B82F6)),
          _statCard('Reserved Beds', reserved.toString(), Icons.event_available, const Color(0xFFF59E0B)),
          _statCard('Maintenance', maintenance.toString(), Icons.build_circle_outlined, const Color(0xFFEF4444)),
          _statCard('Blocked Beds', blocked.toString(), Icons.lock_outline, const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFilters(List<RoomModel> rooms) {
    final roomTypes = ['All Room Types', ...rooms.map((r) => r.occupancyType).toSet()];
    final statuses = ['All Status', 'Available', 'Occupied', 'Reserved', 'Maintenance'];
    final floors = ['All Floors', ...rooms.map((r) => r.floor.toString()).toSet().toList()..sort()];

    return Row(
      children: [
        Expanded(child: _filterDropdown(_selectedFloor?.toString() ?? 'All Floors', floors, (v) {
          setState(() {
            _selectedFloor = v == 'All Floors' ? null : int.tryParse(v!);
          });
        })),
        const SizedBox(width: 8),
        Expanded(child: _filterDropdown(_selectedRoomType, roomTypes, (v) => setState(() => _selectedRoomType = v!))),
        const SizedBox(width: 8),
        Expanded(child: _filterDropdown(_selectedStatus, statuses, (v) => setState(() => _selectedStatus = v!))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: const Icon(Icons.tune, size: 18, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _filterDropdown(String selected, List<String> items, ValueChanged<String?> onChanged) {
    // Ensure selected value is in items to avoid error
    final safeSelected = items.contains(selected) ? selected : items.first;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeSelected,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFloorSelector(List<RoomModel> rooms) {
    final floors = rooms.map((r) => r.floor).toSet().toList()..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _floorChip('All', _selectedFloor == null, () => setState(() => _selectedFloor = null)),
          ...floors.map((f) => _floorChip(f == 0 ? 'Ground Floor' : 'Floor $f', _selectedFloor == f, () => setState(() => _selectedFloor = f))),
        ],
      ),
    );
  }

  Widget _floorChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF16A34A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildInventoryList(BuildContext context, List<RoomModel> rooms, List<Map<String, dynamic>> beds) {
    var filteredRooms = rooms;
    if (_selectedFloor != null) {
      filteredRooms = filteredRooms.where((r) => r.floor == _selectedFloor).toList();
    }
    if (_selectedRoomType != 'All Room Types') {
      filteredRooms = filteredRooms.where((r) => r.occupancyType == _selectedRoomType).toList();
    }

    final Map<int, List<RoomModel>> grouped = {};
    for (final r in filteredRooms) { grouped.putIfAbsent(r.floor, () => []).add(r); }
    final sortedFloors = grouped.keys.toList()..sort();

    return Column(
      children: sortedFloors.map((floor) {
        final floorRooms = grouped[floor]!;
        var floorBeds = beds.where((b) => floorRooms.any((r) => r.id == b['roomId'])).toList();
        
        if (_selectedStatus != 'All Status') {
          floorBeds = floorBeds.where((b) => b['status'].toString().toLowerCase() == _selectedStatus.toLowerCase()).toList();
          final filteredFloorRooms = floorRooms.where((r) => floorBeds.any((b) => b['roomId'] == r.id)).toList();
          if (filteredFloorRooms.isEmpty) return const SizedBox.shrink();
          
          return _FloorSection(
            floorNumber: floor, rooms: filteredFloorRooms, beds: beds,
            floorOccupied: floorBeds.where((b) => b['status'] == 'occupied').length,
            floorTotal: floorBeds.length,
            bedIndicatorBuilder: _bedIndicator,
            roomCardBuilder: _roomCard,
            onAddRoom: () {
               final state = context.findAncestorStateOfType<_PropertyOperationalCenterState>();
               state?._showAddRoomDialog(initialFloor: floor);
            },
          );
        }

        return _FloorSection(
          floorNumber: floor, rooms: floorRooms, beds: beds,
          floorOccupied: floorBeds.where((b) => b['status'] == 'occupied').length,
          floorTotal: floorBeds.length,
          bedIndicatorBuilder: _bedIndicator,
          roomCardBuilder: _roomCard,
          onAddRoom: () {
             final state = context.findAncestorStateOfType<_PropertyOperationalCenterState>();
             state?._showAddRoomDialog(initialFloor: floor);
          },
        );
      }).toList(),
    );
  }

  Widget _roomCard(String name, String occupancyLabel, List<String> statuses, {String? occupancyType, VoidCallback? onAddBed}) {
    final occupied = statuses.where((s) => s.toLowerCase() == 'occupied').length;
    final total = statuses.length;
    final rate = total > 0 ? (occupied / total * 100).round() : 0;

    return GestureDetector(
      onTap: onAddBed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.more_vert, size: 14, color: Color(0xFF64748B)),
              ],
            ),
            const SizedBox(height: 2),
            Text(occupancyLabel, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
            Text('$total Beds', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: statuses.asMap().entries.map((entry) {
                return _bedIndicator(entry.value, label: String.fromCharCode(65 + entry.key));
              }).toList(),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '$rate% Occupied',
                style: TextStyle(
                  fontSize: 8, 
                  fontWeight: FontWeight.bold, 
                  color: rate == 100 ? const Color(0xFF16A34A) : rate > 0 ? const Color(0xFFF59E0B) : const Color(0xFF64748B)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bedIndicator(String status, {String? label}) {
    final s = status.toLowerCase();
    Color color = s == 'occupied' ? const Color(0xFF16A34A) : s == 'available' ? const Color(0xFF3B82F6) : s == 'reserved' ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 10, color: color),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ],
      ),
    );
  }
}

// ── Residents Tab ────────────────────────────────────────────────────────────
class _ResidentsTab extends StatefulWidget {
  final String propertyId;
  const _ResidentsTab({required this.propertyId});
  @override
  State<_ResidentsTab> createState() => _ResidentsTabState();
}

class _ResidentsTabState extends State<_ResidentsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ResidentService().getPropertyResidents(widget.propertyId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsHeader(),
            const SizedBox(height: 24),
            _buildSearchAndFilters(),
            const SizedBox(height: 16),
            ...docs.map((doc) => _buildResidentCard(doc.data())).toList(),
            if (docs.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No active residents found'))),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 100),
          ],
        );
      }
    );
  }

  Widget _buildStatsHeader() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _resStatCard('21', 'Active Residents', Icons.people_outline, const Color(0xFF16A34A)),
          _resStatCard('2', 'Upcoming Check-ins', Icons.calendar_today, const Color(0xFF3B82F6)),
          _resStatCard('1', 'Upcoming Check-outs', Icons.logout, const Color(0xFFF59E0B)),
          _resStatCard('3', 'Pending KYC', Icons.assignment_ind_outlined, const Color(0xFF8B5CF6)),
          _resStatCard('4', 'Due Payments', Icons.payments_outlined, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _resStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('View all', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
              Icon(Icons.chevron_right, size: 10, color: color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    hintText: 'Search by name, phone, room...',
                    hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Icon(Icons.tune, size: 20, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('All Status', true),
              _filterChip('All Floors', false),
              _filterChip('All Room Types', false),
              _filterChip('All Sharing Types', false),
              _filterChip('Rent Status', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF16A34A).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF1E293B), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 14, color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildResidentCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data['studentName'] ?? 'Arjun Nair', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 6),
                        _tag('Student', const Color(0xFF3B82F6)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _infoRow(Icons.phone_outlined, '+91 98765 43210'),
                    _infoRow(Icons.school_outlined, 'CUSAT, Kochi'),
                    _infoRow(Icons.calendar_today_outlined, 'Check-in: 10 May 2025'),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusTag('Active', const Color(0xFF16A34A)),
                  const SizedBox(height: 8),
                  const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Room D203', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const Text('Bed D203-A', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                    const Text('Double Sharing • Floor 2', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('₹8,000 / month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const Text('Paid', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        const Text('View', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Resident Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _actionBtn(Icons.person_add_outlined, 'Add Resident', const Color(0xFF16A34A)),
              _actionBtn(Icons.swap_horiz, 'Move Resident', const Color(0xFF3B82F6)),
              _actionBtn(Icons.logout, 'Check-out', const Color(0xFFF59E0B)),
              _actionBtn(Icons.notifications_outlined, 'Send Notice', const Color(0xFFEF4444)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.1))),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Bookings Tab ────────────────────────────────────────────────────────────
class _BookingsTab extends StatefulWidget {
  final String propertyId;
  final BookingService bookingService;
  const _BookingsTab({required this.propertyId, required this.bookingService});
  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.bookingService.getPropertyBookings(widget.propertyId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsHeader(),
            const SizedBox(height: 24),
            _buildPipeline(),
            const SizedBox(height: 24),
            _buildSearchAndFilters(),
            const SizedBox(height: 16),
            ...docs.map((doc) => _buildBookingCard(doc.data())).toList(),
            if (docs.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No bookings found'))),
            const SizedBox(height: 24),
            _buildHorizontalSummaries(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 100),
          ],
        );
      }
    );
  }

  Widget _buildStatsHeader() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _resStatCard('54', 'Total Bookings', Icons.book_online_outlined, const Color(0xFF16A34A)),
          _resStatCard('6', 'Upcoming Check-ins', Icons.calendar_today, const Color(0xFF3B82F6)),
          _resStatCard('38', 'Active Stays', Icons.people_outline, const Color(0xFF8B5CF6)),
          _resStatCard('4', 'Upcoming Check-outs', Icons.logout, const Color(0xFFF59E0B)),
          _resStatCard('7', 'Booking Requests', Icons.mark_email_unread_outlined, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _resStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 130, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(children: [Text('View all', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)), Icon(Icons.chevron_right, size: 10, color: color)]),
        ],
      ),
    );
  }

  Widget _buildPipeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Booking Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Text('View Pipeline Details >', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _pipelineStep('7', 'Requests', Icons.mail_outline, const Color(0xFF8B5CF6)),
              _pipelineArrow(),
              _pipelineStep('18', 'Visit Sch.', Icons.calendar_today, const Color(0xFF3B82F6)),
              _pipelineArrow(),
              _pipelineStep('26', 'Confirmed', Icons.check_circle_outline, const Color(0xFF16A34A)),
              _pipelineArrow(),
              _pipelineStep('6', 'Check-in P.', Icons.access_time, const Color(0xFFF59E0B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pipelineStep(String val, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Icon(icon, size: 12, color: color)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))), Text(val, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
        ],
      ),
    );
  }

  Widget _pipelineArrow() { return const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right, size: 14, color: Color(0xFFCBD5E1))); }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: const TextField(decoration: InputDecoration(icon: Icon(Icons.search, size: 20, color: Color(0xFF64748B)), hintText: 'Search bookings...', hintStyle: TextStyle(fontSize: 12), border: InputBorder.none)))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.tune, size: 20, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Requests', 'Confirmed', 'Active Stay', 'Check-in Today'].map((s) => _filterChip(s, s == 'All')).toList())),
      ],
    );
  }

  Widget _filterChip(String l, bool s) {
    return Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: s ? const Color(0xFF16A34A).withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: s ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0))), child: Text(l, style: TextStyle(fontSize: 10, color: s ? const Color(0xFF16A34A) : const Color(0xFF1E293B), fontWeight: s ? FontWeight.bold : FontWeight.normal)));
  }

  Widget _buildBookingCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(data['studentName'] ?? 'Arjun Nair', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 6), _tag('Student', const Color(0xFF3B82F6))]), Text('+91 98765 43210', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))])),
              _statusTag('Active Stay', const Color(0xFF16A34A)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bookCol('Room D203', 'Bed D203-A', 'Floor 2 • Double Sharing'),
              _bookCol('₹8,000 / month', 'Paid', 'Booking ID: BK-2025-1048'),
              Column(children: [const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF16A34A)), const SizedBox(height: 8), const Icon(Icons.message_outlined, size: 16, color: Color(0xFF16A34A))]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookCol(String t, String s, String b) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text(s, style: TextStyle(fontSize: 10, color: s == 'Paid' ? const Color(0xFF16A34A) : const Color(0xFFEF4444), fontWeight: FontWeight.bold)), Text(b, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)))]);
  }

  Widget _tag(String l, Color c) { return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(l, style: TextStyle(fontSize: 8, color: c, fontWeight: FontWeight.bold))); }
  Widget _statusTag(String l, Color c) { return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(l, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold))); }

  Widget _buildHorizontalSummaries() {
    return Column(
      children: [
        _horizSum('Today\'s Check-ins (2)', 'View all', [
          _sumItem('Aman Kumar', '10:00 AM', const Color(0xFF16A34A)),
          _sumItem('Meera Suresh', '02:00 PM', const Color(0xFF16A34A)),
        ]),
        const SizedBox(height: 16),
        _horizSum('Booking Requests (7)', 'View all', [
          _sumItem('Karthik Nair', '₹8,000 budget', const Color(0xFF8B5CF6)),
        ]),
      ],
    );
  }

  Widget _horizSum(String t, String l, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(l, style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: items)),
      ],
    );
  }

  Widget _sumItem(String n, String s, Color c) {
    return Container(
      width: 160, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), const SizedBox(height: 4), Text(s, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionBtn(Icons.add, 'Add Booking', const Color(0xFF16A34A)),
          _actionBtn(Icons.bed_outlined, 'Assign Bed', const Color(0xFF3B82F6)),
          _actionBtn(Icons.logout, 'Check-out', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData i, String l, Color c) {
    return Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.1))), child: Row(children: [Icon(i, size: 16, color: c), const SizedBox(width: 8), Text(l, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold))]));
  }
}

class _OverviewFloorSection extends StatefulWidget {
  final String label;
  final bool initialExpanded;
  final Widget child;

  const _OverviewFloorSection({
    required this.label,
    required this.initialExpanded,
    required this.child,
  });

  @override
  State<_OverviewFloorSection> createState() => _OverviewFloorSectionState();
}

class _OverviewFloorSectionState extends State<_OverviewFloorSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const Spacer(),
                Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20, color: const Color(0xFF64748B)),
              ],
            ),
          ),
        ),
        if (_isExpanded) widget.child,
      ],
    );
  }
}

// ── Finance Tab ────────────────────────────────────────────────────────────
class _FinanceTab extends StatefulWidget {
  final String propertyId;
  const _FinanceTab({required this.propertyId});
  @override
  State<_FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<_FinanceTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FinanceService().getPropertyPayments(widget.propertyId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsHeader(),
            const SizedBox(height: 24),
            _buildRevenueOverview(),
            const SizedBox(height: 24),
            _buildPaymentsOverview(),
            const SizedBox(height: 24),
            _buildRecentTransactions(docs),
            const SizedBox(height: 24),
            _buildExpenseSummary(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 100),
          ],
        );
      }
    );
  }

  Widget _buildStatsHeader() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _resStatCard('₹3,45,000', 'Total Revenue', Icons.account_balance_wallet_outlined, const Color(0xFF16A34A)),
          _resStatCard('₹2,48,500', 'Collected', Icons.check_circle_outline, const Color(0xFF3B82F6)),
          _resStatCard('₹72,500', 'Pending', Icons.access_time, const Color(0xFFF59E0B)),
          _resStatCard('₹24,000', 'Overdue', Icons.report_gmailerrorred_rounded, const Color(0xFFEF4444)),
          _resStatCard('₹1,24,000', 'Deposits Held', Icons.lock_outline, const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _resStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 140, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(children: [Text('View details', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)), Icon(Icons.chevron_right, size: 10, color: color)]),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview() {
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Revenue Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Icon(Icons.show_chart, size: 16, color: Color(0xFF64748B))]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Current Month (May 2025)', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))), const Text('₹3,45,000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Row(children: [const Icon(Icons.arrow_upward, size: 10, color: Color(0xFF16A34A)), const Text('12% vs Apr 2025', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))])])),
              Expanded(flex: 2, child: Container(height: 80, color: const Color(0xFFF8FAFC), child: const Center(child: Text('Chart Placeholder', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)))))),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _miniChartStat('Collected', '72%', const Color(0xFF16A34A))),
              Expanded(child: _miniChartStat('Pending', '21%', const Color(0xFFF59E0B))),
              Expanded(child: _miniChartStat('Overdue', '7%', const Color(0xFFEF4444))),
              Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF16A34A), width: 4)), child: const Center(child: Text('86%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _miniChartStat(String l, String v, Color c) {
    return Column(children: [Text(l, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))), Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c))]);
  }

  Widget _buildPaymentsOverview() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Payments Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Text('View All Payments >', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          children: [
            _payCard('Paid', '32', '₹2,48,500', const Color(0xFF16A34A), Icons.check_circle_outline),
            _payCard('Pending', '9', '₹72,500', const Color(0xFFF59E0B), Icons.access_time),
            _payCard('Overdue', '4', '₹24,000', const Color(0xFFEF4444), Icons.report_gmailerrorred_rounded),
            _payCard('Partial Paid', '6', '₹18,500', const Color(0xFF3B82F6), Icons.hourglass_bottom),
          ],
        ),
      ],
    );
  }

  Widget _payCard(String l, String c, String a, Color col, IconData i) {
    return Container(
      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(i, size: 14, color: col)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Row(children: [Text(l, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))), const SizedBox(width: 4), Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))]), Text(a, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))])),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Text('View All Transactions >', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        ...docs.take(5).map((doc) => _buildTransactionItem(doc.data())).toList(),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          const CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Arjun Nair', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), const Text('Rent - May 2025', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('₹8,000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF16A34A))), const Text('10 May 2025', style: TextStyle(fontSize: 8, color: Color(0xFF64748B)))]),
        ],
      ),
    );
  }

  Widget _buildExpenseSummary() {
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Expense Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Text('This Month', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))]),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _expItem('Maintenance', '₹18,500', Icons.build_outlined, const Color(0xFFEF4444)),
            _expItem('Utilities', '₹12,800', Icons.bolt, const Color(0xFFF59E0B)),
            _expItem('Food & Sup.', '₹24,300', Icons.restaurant, const Color(0xFF3B82F6)),
            _expItem('Salary', '₹35,000', Icons.people_outline, const Color(0xFF8B5CF6)),
          ]),
        ],
      ),
    );
  }

  Widget _expItem(String l, String v, IconData i, Color c) {
    return Column(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, size: 14, color: c)), const SizedBox(height: 4), Text(l, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))), Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))]);
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionBtn(Icons.payments_outlined, 'Collect Rent', const Color(0xFF16A34A)),
          _actionBtn(Icons.add_card, 'Add Expense', const Color(0xFFEF4444)),
          _actionBtn(Icons.description_outlined, 'Generate Invoice', const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData i, String l, Color c) {
    return Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.1))), child: Row(children: [Icon(i, size: 16, color: c), const SizedBox(width: 8), Text(l, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold))]));
  }
}

// ── Leads Tab ────────────────────────────────────────────────────────────
class _LeadsTab extends StatefulWidget {
  final String propertyId;
  final LeadService leadService;
  const _LeadsTab({required this.propertyId, required this.leadService});
  @override
  State<_LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<_LeadsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Lead>>(
      stream: widget.leadService.getPropertyLeads(widget.propertyId),
      builder: (context, snapshot) {
        final leads = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsHeader(),
            const SizedBox(height: 24),
            _buildPipeline(),
            const SizedBox(height: 24),
            _buildSearchAndFilters(),
            const SizedBox(height: 16),
            ...leads.map((l) => _buildLeadCard(l)).toList(),
            if (leads.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No leads found'))),
            const SizedBox(height: 24),
            _buildFollowUps(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 100),
          ],
        );
      }
    );
  }

  Widget _buildStatsHeader() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _resStatCard('86', 'Total Leads', Icons.filter_alt_outlined, const Color(0xFF16A34A)),
          _resStatCard('32', 'New Leads', Icons.fiber_new_outlined, const Color(0xFF3B82F6)),
          _resStatCard('18', 'Visits Sch.', Icons.calendar_today, const Color(0xFFF59E0B)),
          _resStatCard('20', 'Interested', Icons.star_outline, const Color(0xFF8B5CF6)),
          _resStatCard('14', 'Converted', Icons.check_circle_outline, const Color(0xFF16A34A)),
          _resStatCard('26', 'Not Conv.', Icons.cancel_outlined, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _resStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 120, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(children: [Text('View all', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)), Icon(Icons.chevron_right, size: 10, color: color)]),
        ],
      ),
    );
  }

  Widget _buildPipeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Lead Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Text('View Pipeline Details >', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _pipeStep('32', 'New Leads', Icons.fiber_new, const Color(0xFF3B82F6)),
              _pipeArrow(),
              _pipeStep('18', 'Visits Sch.', Icons.calendar_today, const Color(0xFFF59E0B)),
              _pipeArrow(),
              _pipeStep('20', 'Interested', Icons.star, const Color(0xFF8B5CF6)),
              _pipeArrow(),
              _pipeStep('14', 'Converted', Icons.check_circle, const Color(0xFF16A34A)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pipeStep(String val, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Icon(icon, size: 12, color: color)), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))), Text(val, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])]),
    );
  }

  Widget _pipeArrow() { return const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right, size: 14, color: Color(0xFFCBD5E1))); }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: const TextField(decoration: InputDecoration(icon: Icon(Icons.search, size: 20, color: Color(0xFF64748B)), hintText: 'Search by name, email...', hintStyle: TextStyle(fontSize: 12), border: InputBorder.none)))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.tune, size: 20, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All Status', 'All Sources', 'All Room Types', 'All Sharing Types'].map((s) => _filterChip(s, s == 'All Status')).toList())),
      ],
    );
  }

  Widget _filterChip(String l, bool s) {
    return Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: s ? const Color(0xFF16A34A).withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: s ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0))), child: Text(l, style: TextStyle(fontSize: 10, color: s ? const Color(0xFF16A34A) : const Color(0xFF1E293B), fontWeight: s ? FontWeight.bold : FontWeight.normal)));
  }

  Widget _buildLeadCard(Lead lead) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(lead.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 6), _tag('New', const Color(0xFF16A34A))]), Text('+91 98765 43210', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))])),
              const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Preferred', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))), const Text('Double Sharing', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))), const SizedBox(height: 4), const Text('Budget', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))), const Text('₹8,000 - ₹10,000', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Last Contact', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))), const Text('Today, 10:30 AM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text('Interest Level', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))), Row(children: List.generate(5, (i) => Icon(Icons.star, size: 10, color: i < 4 ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1))))])),
              Column(children: [const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF16A34A)), const SizedBox(height: 8), const Icon(Icons.message_outlined, size: 16, color: Color(0xFF16A34A))]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String l, Color c) { return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(l, style: TextStyle(fontSize: 8, color: c, fontWeight: FontWeight.bold))); }

  Widget _buildFollowUps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Today\'s Follow-ups (5)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Text('View All >', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _followUpItem('Aman Kumar', '10:00 AM', Icons.phone),
              _followUpItem('Riya Patel', '11:30 AM', Icons.chat_bubble_outline),
              _followUpItem('Aditya Nair', '02:00 PM', Icons.calendar_today),
            ],
          ),
        ),
      ],
    );
  }

  Widget _followUpItem(String n, String t, IconData i) {
    return Container(
      width: 150, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), const SizedBox(height: 8), Row(children: [Icon(i, size: 12, color: const Color(0xFF16A34A)), const SizedBox(width: 6), Text(t, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)))]), const SizedBox(height: 4), Container(height: 2, width: 40, color: const Color(0xFF16A34A))]),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionBtn(Icons.add, 'Add Lead', const Color(0xFF16A34A)),
          _actionBtn(Icons.calendar_today, 'Schedule Visit', const Color(0xFF3B82F6)),
          _actionBtn(Icons.swap_horiz, 'Convert', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData i, String l, Color c) {
    return Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.1))), child: Row(children: [Icon(i, size: 16, color: c), const SizedBox(width: 8), Text(l, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold))]));
  }
}

// ── Hosts Tab ────────────────────────────────────────────────────────────
class _HostsTab extends StatefulWidget {
  final String propertyId;
  final String ownerId;
  const _HostsTab({required this.propertyId, required this.ownerId});
  @override
  State<_HostsTab> createState() => _HostsTabState();
}

class _HostsTabState extends State<_HostsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StaffMember>>(
      stream: StaffService().getPropertyStaffMembers(widget.propertyId),
      builder: (context, snapshot) {
        final staff = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsHeader(),
            const SizedBox(height: 24),
            _buildOwnerSection(),
            const SizedBox(height: 24),
            _buildPrimaryHost(staff),
            const SizedBox(height: 24),
            _buildAssistantHosts(staff),
            const SizedBox(height: 24),
            _buildHostActivity(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 100),
          ],
        );
      }
    );
  }

  Widget _buildStatsHeader() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _resStatCard('5', 'Total Hosts', Icons.people_outline, const Color(0xFF16A34A)),
          _resStatCard('1', 'Primary Hosts', Icons.star_outline, const Color(0xFF3B82F6)),
          _resStatCard('4', 'Assistant Hosts', Icons.person_add_alt_1_outlined, const Color(0xFF8B5CF6)),
          _resStatCard('18', 'Active Perms.', Icons.vpn_key_outlined, const Color(0xFFF59E0B)),
          _resStatCard('0', 'Pending Invit.', Icons.mark_email_read_outlined, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _resStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 130, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(children: [Text('View all', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)), Icon(Icons.chevron_right, size: 10, color: color)]),
        ],
      ),
    );
  }

  Widget _buildOwnerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Property Owner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.person_outline, color: Color(0xFF94A3B8))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Text('Rahul Nair', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 6), _tag('Owner', const Color(0xFF16A34A))]), const Text('+91 98765 43210', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))), const Text('rahul.nair@email.com', style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('Owner Since', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))), const Text('12 Jan 2023', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)), const SizedBox(height: 4), Row(children: [const Icon(Icons.business_outlined, size: 10, color: Color(0xFF64748B)), const SizedBox(width: 4), const Text('4 Properties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))])]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryHost(List<StaffMember> staff) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Primary Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)), const SizedBox(width: 4), const Text('Active', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold)), const Icon(Icons.chevron_right, size: 14, color: Color(0xFF64748B))])]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Text('Ajay Kumar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 6), _tag('Primary Host', const Color(0xFF3B82F6))]), const Text('+91 98765 43210', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))), const Text('Assigned Since: 12 Jan 2024', style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))])),
                ],
              ),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), const Text('18 / 18 Enabled', style: TextStyle(fontSize: 8, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))]),
              const SizedBox(height: 12),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['Leads', 'Bookings', 'Beds', 'Payments', 'Residents', 'Complaints'].map((p) => _permTag(p)).toList())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _permTag(String l) {
    return Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(children: [const Icon(Icons.check_circle, size: 10, color: Color(0xFF16A34A)), const SizedBox(width: 4), Text(l, style: const TextStyle(fontSize: 8, color: Color(0xFF1E293B)))]));
  }

  Widget _buildAssistantHosts(List<StaffMember> staff) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Assistant Hosts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Text('View all', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        ...staff.take(3).map((s) => _assistantItem(s)).toList(),
      ],
    );
  }

  Widget _assistantItem(StaffMember s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.user.name ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(s.assignment.role.name, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('Permissions', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))), const Text('6 / 18', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))]),
          const SizedBox(width: 12),
          _statusBadge('Active', const Color(0xFF3B82F6)),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _statusBadge(String t, Color c) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(t, style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.bold)));
  }

  Widget _buildHostActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Host Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Text('View all', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            children: [
              _actItem(Icons.bed_outlined, 'Ajay Kumar assigned bed D203-A to Arjun Nair', 'Today, 10:30 AM', const Color(0xFF3B82F6)),
              _actItem(Icons.person_add_outlined, 'Sneha Menon added new lead Karthik Nair', 'Today, 09:15 AM', const Color(0xFF16A34A)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actItem(IconData i, String t, String s, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(i, size: 14, color: c)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)), Text(s, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)))])),
        ],
      ),
    );
  }

  Widget _tag(String l, Color c) { return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(l, style: TextStyle(fontSize: 8, color: c, fontWeight: FontWeight.bold))); }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionBtn(Icons.person_add_outlined, 'Add Host', const Color(0xFF16A34A)),
          _actionBtn(Icons.mail_outline, 'Invite Host', const Color(0xFF3B82F6)),
          _actionBtn(Icons.lock_open_outlined, 'Manage Perms.', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData i, String l, Color c) {
    return Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.1))), child: Row(children: [Icon(i, size: 16, color: c), const SizedBox(width: 8), Text(l, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold))]));
  }
}

// ── Bottom Sheets ──────────────────────────────────────────────────────────
class _AddRoomBottomSheet extends StatefulWidget {
  final String propertyId; final Map<String, dynamic> propertyData;
  final int? initialFloor; final VoidCallback onComplete;
  const _AddRoomBottomSheet({required this.propertyId, required this.propertyData, this.initialFloor, required this.onComplete});
  @override State<_AddRoomBottomSheet> createState() => _AddRoomBottomSheetState();
}
class _AddRoomBottomSheetState extends State<_AddRoomBottomSheet> {
  final _structureService = PropertyStructureService();
  final _numberController = TextEditingController();
  final _floorController = TextEditingController();
  final _rentController = TextEditingController();
  int _bedCount = 1; RoomType _selectedType = RoomType.single; bool _isLoading = false;

  @override void initState() {
    super.initState();
    if (widget.initialFloor != null) {
      _floorController.text = widget.initialFloor.toString();
      _suggestRoomNumber();
    }
    _floorController.addListener(_suggestRoomNumber);
  }

  Future<void> _suggestRoomNumber() async {
    final floor = int.tryParse(_floorController.text);
    if (floor == null) return;
    final system = widget.propertyData['numberingSystem'] ?? 'Numeric (101)';
    final suggestion = await _structureService.getNextRoomNumber(widget.propertyId, floor, system);
    if (suggestion.isNotEmpty && mounted) setState(() => _numberController.text = suggestion);
  }

  @override Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 20),
        const Text('Add New Room', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'Room Number', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: TextField(controller: _floorController, decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder()), keyboardType: TextInputType.number)), const SizedBox(width: 16), Expanded(child: TextField(controller: _rentController, decoration: const InputDecoration(labelText: 'Rent', border: OutlineInputBorder()), keyboardType: TextInputType.number))]),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF064E3B), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Room'),
        ),
      ])),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final floor = int.tryParse(_floorController.text) ?? 0;
      final floorsSnap = await FirebaseFirestore.instance.collection('properties').doc(widget.propertyId).collection('floors').where('floorNumber', isEqualTo: floor).get();
      String fId = floorsSnap.docs.isNotEmpty ? floorsSnap.docs.first.id : FirebaseFirestore.instance.collection('properties').doc(widget.propertyId).collection('floors').doc().id;
      await _structureService.createRoomWithBeds(propertyId: widget.propertyId, floorId: fId, roomData: {'roomNumber': _numberController.text, 'roomType': _selectedType.name, 'floor': floor, 'genderRestriction': widget.propertyData['gender'] ?? 'Anyone'}, bedCount: _bedCount, numberingSystem: widget.propertyData['numberingSystem'] ?? 'Numeric (101)');
      widget.onComplete(); Navigator.pop(context);
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); } finally { setState(() => _isLoading = false); }
  }
}

class _AddFloorBottomSheet extends StatefulWidget {
  final String propertyId; final VoidCallback onComplete;
  const _AddFloorBottomSheet({required this.propertyId, required this.onComplete});
  @override State<_AddFloorBottomSheet> createState() => _AddFloorBottomSheetState();
}
class _AddFloorBottomSheetState extends State<_AddFloorBottomSheet> {
  final _structureService = PropertyStructureService();
  final _nameController = TextEditingController(); final _numberController = TextEditingController(); bool _isLoading = false;
  @override void initState() { super.initState(); _suggestFloor(); }
  Future<void> _suggestFloor() async { final next = await _structureService.getNextFloorNumber(widget.propertyId); setState(() { _numberController.text = next.toString(); _nameController.text = next == 0 ? 'Ground Floor' : 'Floor $next'; }); }
  @override Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Add Floor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'Floor Number', border: OutlineInputBorder()), keyboardType: TextInputType.number),
      const SizedBox(height: 16),
      TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Floor Name', border: OutlineInputBorder())),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _isLoading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF064E3B), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), child: const Text('Add Floor')),
    ]));
  }
  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try { await _structureService.createFloor(widget.propertyId, {'floorNumber': int.tryParse(_numberController.text) ?? 0, 'name': _nameController.text, 'status': 'Active'}); widget.onComplete(); Navigator.pop(context); }
    catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); } finally { setState(() => _isLoading = false); }
  }
}

class _AddBedBottomSheet extends StatefulWidget {
  final String propertyId; final Map<String, dynamic> propertyData; final Map<String, dynamic> room; final VoidCallback onComplete;
  const _AddBedBottomSheet({required this.propertyId, required this.propertyData, required this.room, required this.onComplete});
  @override State<_AddBedBottomSheet> createState() => _AddBedBottomSheetState();
}
class _AddBedBottomSheetState extends State<_AddBedBottomSheet> {
  final _structureService = PropertyStructureService();
  int _count = 1; bool _isLoading = false;
  @override Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Add Bed to ${widget.room['roomNumber']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Number of Beds'), Row(children: [IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _count = _count > 1 ? _count - 1 : 1)), Text('$_count'), IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _count++))])]),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _isLoading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF064E3B), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), child: const Text('Add Beds')),
    ]));
  }
  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try { await _structureService.addBedsToRoom(propertyId: widget.propertyId, roomId: widget.room['id'], floorId: widget.room['floorId'], floor: widget.room['floor'], count: _count, roomNumber: widget.room['roomNumber'], rent: (widget.room['baseRent'] as num?)?.toDouble() ?? 0, numberingSystem: widget.propertyData['numberingSystem'] ?? 'Numeric (101)'); widget.onComplete(); Navigator.pop(context); }
    catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); } finally { setState(() => _isLoading = false); }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child; _SliverTabBarDelegate({required this.child});
  @override double get minExtent => 48.0; @override double get maxExtent => 48.0;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) { return child; }
  @override bool shouldRebuild(_SliverTabBarDelegate oldDelegate) { return false; }
}

class _AddExpenseDialog extends StatefulWidget {
  final String propertyId; final VoidCallback onComplete;
  const _AddExpenseDialog({required this.propertyId, required this.onComplete});
  @override State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}
class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  @override Widget build(BuildContext context) { return AlertDialog(title: const Text('Log Expense'), actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]); }
}

class _InviteHostDialog extends StatefulWidget {
  final String propertyId; final VoidCallback onComplete;
  const _InviteHostDialog({required this.propertyId, required this.onComplete});
  @override State<_InviteHostDialog> createState() => _InviteHostDialogState();
}
class _InviteHostDialogState extends State<_InviteHostDialog> {
  @override Widget build(BuildContext context) { return AlertDialog(title: const Text('Invite Host'), actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]); }
}

class _ManagePermissionsDialog extends StatefulWidget {
  final dynamic staff; final VoidCallback onComplete;
  const _ManagePermissionsDialog({required this.staff, required this.onComplete});
  @override State<_ManagePermissionsDialog> createState() => _ManagePermissionsDialogState();
}
class _ManagePermissionsDialogState extends State<_ManagePermissionsDialog> {
  @override Widget build(BuildContext context) { return const Center(child: Text('Permissions')); }
}
