import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:triangle_home/core/extensions/string_extensions.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/services/booking_service.dart';
import 'package:triangle_home/services/lead_service.dart';
import 'package:triangle_home/services/inventory_service.dart';
import 'package:triangle_home/services/resident_service.dart';
import 'package:triangle_home/services/finance_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildPropertyHeroSummary(occupancyRate, vacantBeds, occupiedBeds),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
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
                    ),
                    _BedsTab(propertyId: widget.propertyId),
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
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddRoomDialog(),
            backgroundColor: AppTheme.successColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) => Text(
                _tabController.index == 1 ? 'Add Room / Bed' : 'New', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        );
      }
    );
  }

  void _showAddRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddRoomDialog(
        propertyId: widget.propertyId,
        onComplete: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room created successfully'))),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
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
          Text(
            '${widget.propertyData['city'] ?? "Kochi"}, Kerala',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E293B), size: 22), onPressed: () {}),
        IconButton(icon: const Icon(Icons.share_outlined, color: Color(0xFF1E293B), size: 22), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1E293B)), onPressed: () {}),
      ],
    );
  }

  Widget _buildPropertyHeroSummary(int occupancy, int vacant, int residents) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  (widget.propertyData['images'] as List?)?.first ?? 'https://via.placeholder.com/300',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _heroStat('$occupancy%', 'Occupancy', const Color(0xFF16A34A)),
                    _heroStat('$vacant', 'Available Beds', const Color(0xFF3B82F6)),
                    _heroStat('$residents', 'Residents', const Color(0xFF1E293B)),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('payments')
                          .where('propertyId', isEqualTo: widget.propertyId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        double revenue = 0;
                        final docs = snapshot.data?.docs ?? [];
                        for (var doc in docs) {
                          revenue += _parseNum((doc.data() as Map)['amount']).toDouble();
                        }
                        return _heroStat('₹${(revenue / 1000).toStringAsFixed(1)}k', 'Monthly Revenue', const Color(0xFF16A34A));
                      }
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _tag(Icons.apartment_rounded, 'Hostel / PG'),
              const SizedBox(width: 8),
              _tag(Icons.male_rounded, 'Male Accommodation'),
              const SizedBox(width: 8),
              _tag(Icons.restaurant_rounded, 'Food Available'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String val, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF16A34A),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF16A34A),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        onTap: (index) {
          // Add haptic feedback if needed
        },
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          fontFamily: 'Outfit',
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Beds & Inventory'),
          Tab(text: 'Residents'),
          Tab(text: 'Bookings'),
          Tab(text: 'Finance'),
          Tab(text: 'Leads'),
          Tab(text: 'Hosts'),
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
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildOccupancyOverview(),
          const SizedBox(height: 24),
          _buildInventorySnapshot(),
          const SizedBox(height: 24),
          _buildResidentSummary(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildRevenueOverview()),
              const SizedBox(width: 16),
              Expanded(child: _buildBookingPipeline()),
            ],
          ),
          const SizedBox(height: 24),
          _buildAssignedHost(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
          const SizedBox(height: 24),
          _buildAmenities(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOccupancyOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 12),
                  Text('Occupancy Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                ],
              ),
              TextButton(
                onPressed: () {
                  tabController.animateTo(1);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('View Details', style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('$totalBeds', 'Total Beds'),
              _miniStat('$occupiedBeds', 'Occupied Beds', color: const Color(0xFF16A34A)),
              _miniStat('$vacantBeds', 'Vacant Beds', color: const Color(0xFF3B82F6)),
              _miniStat('$reservedBeds', 'Reserved Beds', color: const Color(0xFFD97706)),
              _miniStat('$blockedBeds', 'Blocked Beds'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Occupancy Progress', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              Text('$occupancyRate%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: occupancyRate / 100,
            backgroundColor: const Color(0xFFF1F5F9),
            color: const Color(0xFF16A34A),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String val, String label, {Color? color}) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF1E293B))),
        Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInventorySnapshot() {
    return StreamBuilder<List<RoomModel>>(
      stream: InventoryService().getPropertyRooms(propertyId),
      builder: (context, roomSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: PropertyService().getPropertyBeds(propertyId),
          builder: (context, bedSnapshot) {
            final rooms = roomSnapshot.data ?? [];
            final beds = bedSnapshot.data ?? [];

            // Group rooms by floor
            final Map<int, List<RoomModel>> roomsByFloor = {};
            for (final r in rooms) {
              roomsByFloor.putIfAbsent(r.floor, () => []).add(r);
            }
            final sortedFloors = roomsByFloor.keys.toList()..sort();

            // Build bed status summary for header
            final totalRooms = rooms.length;
            final totalBedCount = beds.length;
            final occupiedCount = beds.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'occupied').length;
            final availableCount = beds.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'available').length;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Color(0xFF64748B), size: 20),
                          SizedBox(width: 12),
                          Text('Bed Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                          SizedBox(width: 8),
                          Text('(Floor Wise)', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      Text('View All Beds', style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  // Quick stats strip
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _inventoryStat('$totalRooms', 'Rooms', const Color(0xFF8B5CF6)),
                        _inventoryStat('$totalBedCount', 'Total Beds', const Color(0xFF1E293B)),
                        _inventoryStat('$occupiedCount', 'Occupied', const Color(0xFF16A34A)),
                        _inventoryStat('$availableCount', 'Available', const Color(0xFF3B82F6)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Floor-wise room listing
                  if (sortedFloors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.bed_outlined, size: 40, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            const Text('No rooms added yet', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text('Use the + button to add your first room & beds', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    )
                  else
                    ...sortedFloors.map((floor) {
                      final floorRooms = roomsByFloor[floor]!;
                      final floorBeds = beds.where((b) => floorRooms.any((r) => r.id == b['roomId'])).toList();
                      final floorOccupied = floorBeds.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'occupied').length;
                      final floorTotal = floorBeds.length;
                      return _FloorSection(
                        floorNumber: floor,
                        rooms: floorRooms,
                        beds: beds,
                        floorOccupied: floorOccupied,
                        floorTotal: floorTotal,
                        bedIndicatorBuilder: _bedIndicator,
                        roomCardBuilder: _roomCard,
                      );
                    }),

                  const SizedBox(height: 12),
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _legend('Occupied', const Color(0xFF16A34A)),
                      _legend('Available', const Color(0xFF3B82F6)),
                      _legend('Reserved', const Color(0xFFD97706)),
                      _legend('Maintenance', const Color(0xFFEF4444)),
                      _legend('Blocked', const Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _inventoryStat(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
      ],
    );
  }


  Widget _roomCard(String name, String capacity, List<String> statuses, {String? occupancyType}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
          Text(capacity, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          if (occupancyType != null) ...
            [Text(occupancyType, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)))],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: statuses.isEmpty
                ? [const Text('No beds', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)))]
                : statuses.map((s) => _bedIndicator(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _bedIndicator(String rawStatus) {
    final s = rawStatus.toLowerCase();
    Color c;
    String label;
    if (s == 'occupied') {
      c = const Color(0xFF16A34A);
      label = 'O';
    } else if (s == 'available') {
      c = const Color(0xFF3B82F6);
      label = 'V';
    } else if (s == 'reserved') {
      c = const Color(0xFFD97706);
      label = 'R';
    } else if (s == 'maintenance') {
      c = const Color(0xFFEF4444);
      label = 'M';
    } else if (s == 'blocked') {
      c = const Color(0xFF94A3B8);
      label = 'B';
    } else {
      c = const Color(0xFF3B82F6);
      label = s.isNotEmpty ? s[0].toUpperCase() : 'V';
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildResidentSummary() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: bookingService.getPropertyBookings(propertyId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final active = docs.where((d) => (d.data()['status'] ?? '').toString().toLowerCase() == 'confirmed').length;
        final upcoming = docs.where((d) => (d.data()['status'] ?? '').toString().toLowerCase() == 'pending').length;
        
        return Row(
          children: [
            Expanded(child: _summaryBox(Icons.people_outline_rounded, 'Active Residents', '$active', const Color(0xFF3B82F6), const Color(0xFFDBEAFE))),
            const SizedBox(width: 12),
            Expanded(child: _summaryBox(Icons.calendar_today_outlined, 'Upcoming Check-ins', '$upcoming', const Color(0xFF16A34A), const Color(0xFFDCFCE7))),
            const SizedBox(width: 12),
            Expanded(child: _summaryBox(Icons.exit_to_app_rounded, 'Upcoming Check-outs', '1', const Color(0xFFF59E0B), const Color(0xFFFEF3C7))),
            const SizedBox(width: 12),
            Expanded(child: _summaryBox(Icons.campaign_outlined, 'Notice Submitted', '0', const Color(0xFFEF4444), const Color(0xFFFEE2E2))),
          ],
        );
      }
    );
  }

  Widget _summaryBox(IconData icon, String label, String val, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
              Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          const Text('View All >', style: TextStyle(fontSize: 8, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('propertyId', isEqualTo: propertyId)
          .snapshots(),
      builder: (context, snapshot) {
        double collected = 0;
        final docs = snapshot.data?.docs ?? [];
        for (var doc in docs) {
          collected += _parseNum((doc.data() as Map)['amount']).toDouble();
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: PropertyService().getPropertyBeds(propertyId),
          builder: (context, bedSnapshot) {
            double expected = 0;
            final beds = bedSnapshot.data ?? [];
            for (var bed in beds) {
              if ((bed['status'] ?? '').toString().toLowerCase() == 'occupied') {
                expected += _parseNum(bed['monthlyRent'] ?? bed['price']).toDouble();
              }
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Revenue Overview (This Month)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  _revRow('Expected Revenue', '₹${NumberFormat('#,##,###').format(expected)}'),
                  _revRow('Collected Revenue', '₹${NumberFormat('#,##,###').format(collected)}', color: const Color(0xFF16A34A)),
                  _revRow('Pending Revenue', '₹${NumberFormat('#,##,###').format(expected - collected > 0 ? expected - collected : 0)}', color: const Color(0xFFF59E0B)),
                  _revRow('Overdue Payments', '₹0', color: const Color(0xFFEF4444)),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: Text('View Finance >', style: TextStyle(fontSize: 10, color: AppTheme.successColor, fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _revRow(String l, String v, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildBookingPipeline() {
    return StreamBuilder<List<Lead>>(
      stream: leadService.getPropertyLeads(propertyId),
      builder: (context, snapshot) {
        final leads = snapshot.data ?? [];
        final newLeads = leads.where((l) => l.status == LeadStatus.newLead).length;
        final visits = leads.where((l) => l.status == LeadStatus.visitScheduled).length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Booking Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              _pipeRow(Icons.auto_awesome_outlined, 'New Leads', '$newLeads', const Color(0xFF3B82F6)),
              _pipeRow(Icons.calendar_today_outlined, 'Visits Scheduled', '$visits', const Color(0xFFF59E0B)),
              _pipeRow(Icons.bookmark_outline_rounded, 'Bookings Pending', '8', const Color(0xFF8B5CF6)),
              _pipeRow(Icons.check_circle_outline_rounded, 'Confirmed Bookings', '12', const Color(0xFF16A34A)),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: Text('View Leads & Bookings >', style: TextStyle(fontSize: 10, color: AppTheme.successColor, fontWeight: FontWeight.bold))),
            ],
          ),
        );
      }
    );
  }

  Widget _pipeRow(IconData i, String l, String v, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(i, size: 12, color: c),
          const SizedBox(width: 8),
          Expanded(child: Text(l, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500))),
          Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildAssignedHost() {
    final staffService = StaffService();
    return StreamBuilder<List<StaffMember>>(
      stream: staffService.getPropertyStaffMembers(propertyId),
      builder: (context, snapshot) {
        final staff = snapshot.data ?? [];
        final primaryHost = staff.firstWhere(
          (s) => s.assignment.role == StaffRole.primaryHost,
          orElse: () => StaffMember(
            assignment: HostAssignment(
              id: '',
              propertyId: propertyId,
              userId: '',
              role: StaffRole.primaryHost,
              status: StaffStatus.inactive,
              assignedAt: DateTime.now(),
            ),
            user: model.User(
              id: '',
              name: 'No Primary Host',
              phoneNumber: 'N/A',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );

        final hasPrimaryHost = primaryHost.user.id.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assigned Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: primaryHost.user.profilePicture != null
                        ? NetworkImage(primaryHost.user.profilePicture!)
                        : null,
                    child: primaryHost.user.profilePicture == null
                        ? const Icon(Icons.person, size: 32, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(primaryHost.user.name ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)), child: const Text('Primary Host', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF94A3B8)), const SizedBox(width: 6), Text(primaryHost.user.phoneNumber, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]),
                        if (primaryHost.user.email != null)
                          Row(children: [const Icon(Icons.email_outlined, size: 12, color: Color(0xFF94A3B8)), const SizedBox(width: 6), Text(primaryHost.user.email!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]),
                        Row(children: [const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)), const SizedBox(width: 6), Text('Since ${DateFormat('dd MMM yyyy').format(primaryHost.assignment.assignedAt)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _hostAction(Icons.call_outlined, 'Call', onTap: hasPrimaryHost ? () {} : null)),
                  const SizedBox(width: 12),
                  Expanded(child: _hostAction(Icons.person_outline_rounded, 'Change Host')),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _hostAction(IconData i, String l, {VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: InkWell(
        onTap: onTap,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 16, color: const Color(0xFF16A34A)), const SizedBox(width: 8), Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))]),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _qAction(Icons.event_available_outlined, 'Add Booking', const Color(0xFF16A34A), const Color(0xFFDCFCE7), onTap: () => tabController.animateTo(3)),
            _qAction(Icons.bed_outlined, 'Assign Bed', const Color(0xFF3B82F6), const Color(0xFFDBEAFE), onTap: () => tabController.animateTo(1)),
            _qAction(Icons.people_outline_rounded, 'Residents', const Color(0xFF8B5CF6), const Color(0xFFF3E8FF), onTap: () => tabController.animateTo(2)),
            _qAction(Icons.calendar_today_outlined, 'Bookings', const Color(0xFFF59E0B), const Color(0xFFFEF3C7), onTap: () => tabController.animateTo(3)),
            _qAction(Icons.payments_outlined, 'Payments', const Color(0xFF16A34A), const Color(0xFFDCFCE7), onTap: () => tabController.animateTo(4)),
            _qAction(Icons.report_gmailerrorred_rounded, 'Complaints', const Color(0xFFEF4444), const Color(0xFFFEE2E2), onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _qAction(IconData i, String l, Color c, Color bg, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(i, color: c, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              l,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
              Text('View All', style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _activityItem(Icons.bed_outlined, 'Bed D203-C marked as Vacant', 'Today, 09:30 AM', const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
          _activityItem(Icons.calendar_today_outlined, 'New booking confirmed for Bed D204-A', 'Today, 08:15 AM', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
          _activityItem(Icons.payments_outlined, 'Rent collected from 3 residents', 'Yesterday, 07:45 PM', const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
        ],
      ),
    );
  }

  Widget _activityItem(IconData i, String t, String s, Color c, Color bg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(i, color: c, size: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(s, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
            Text('View All', style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _amenity(Icons.wifi_rounded, 'WiFi'),
            _amenity(Icons.videocam_outlined, 'CCTV'),
            _amenity(Icons.restaurant_rounded, 'Food'),
            _amenity(Icons.local_laundry_service_outlined, 'Laundry'),
            _amenity(Icons.local_parking_rounded, 'Parking'),
            _amenity(Icons.battery_charging_full_rounded, 'Power Backup'),
            _amenity(Icons.water_drop_outlined, 'RO Water'),
            _amenity(Icons.hot_tub_rounded, 'Hot Water'),
          ],
        ),
      ],
    );
  }

  Widget _amenity(IconData i, String l) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, color: const Color(0xFF16A34A), size: 20),
          const SizedBox(height: 8),
          Text(l, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

// ── Floor Section (collapsible, real data) ────────────────────────────────────
class _FloorSection extends StatefulWidget {
  final int floorNumber;
  final List<RoomModel> rooms;
  final List<Map<String, dynamic>> beds;
  final int floorOccupied;
  final int floorTotal;
  final Widget Function(String) bedIndicatorBuilder;
  final Widget Function(String, String, List<String>, {String? occupancyType}) roomCardBuilder;

  const _FloorSection({
    required this.floorNumber,
    required this.rooms,
    required this.beds,
    required this.floorOccupied,
    required this.floorTotal,
    required this.bedIndicatorBuilder,
    required this.roomCardBuilder,
  });

  @override
  State<_FloorSection> createState() => _FloorSectionState();
}

class _FloorSectionState extends State<_FloorSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final label = widget.floorNumber == 0 ? 'Ground Floor' : 'Floor ${widget.floorNumber}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floor header — tappable to expand/collapse
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.rooms.length} room${widget.rooms.length != 1 ? 's' : ''} · ${widget.floorOccupied}/${widget.floorTotal} occupied',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Rooms row — shown when expanded
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.rooms.map((r) {
                  final roomBeds = widget.beds.where((b) => b['roomId'] == r.id).toList();
                  final statuses = roomBeds.map((b) => (b['status'] ?? 'available').toString()).toList();
                  final occupiedInRoom = roomBeds.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'occupied').length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: widget.roomCardBuilder(
                      'Room ${r.roomNumber}',
                      '${r.totalBeds} Beds · $occupiedInRoom occupied',
                      statuses,
                      occupancyType: r.occupancyType.isNotEmpty ? r.occupancyType : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Beds Tab ────────────────────────────────────────────────────────────
class _BedsTab extends StatefulWidget {
  final String propertyId;
  const _BedsTab({required this.propertyId});

  @override
  State<_BedsTab> createState() => _BedsTabState();
}

class _BedsTabState extends State<_BedsTab> {
  final InventoryService _inventoryService = InventoryService();
  String _selectedFloor = 'All Floors';
  String? _expandedRoomId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomModel>>(
      stream: _inventoryService.getPropertyRooms(widget.propertyId),
      builder: (context, roomSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: PropertyService().getPropertyBeds(widget.propertyId),
          builder: (context, bedSnapshot) {
            if (roomSnapshot.connectionState == ConnectionState.waiting || 
                bedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final rooms = roomSnapshot.data ?? [];
            final beds = bedSnapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildKPIs(beds),
                  const SizedBox(height: 24),
                  _buildFloorTabs(rooms),
                  const SizedBox(height: 24),
                  _buildInventoryList(rooms, beds),
                  const SizedBox(height: 24),
                  _buildInventoryAnalytics(beds, rooms),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildKPIs(List<Map<String, dynamic>> beds) {
    final total = beds.length;
    final occupied = beds.where((b) => b['status'] == BedStatus.occupied.name).length;
    final available = beds.where((b) => b['status'] == BedStatus.available.name).length;
    final maintenance = beds.where((b) => b['status'] == BedStatus.maintenance.name).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _kpiCard('Total Beds', total, Icons.bed_rounded, Colors.grey),
          const SizedBox(width: 12),
          _kpiCard('Occupied', occupied, Icons.check_circle_rounded, const Color(0xFF16A34A)),
          const SizedBox(width: 12),
          _kpiCard('Available', available, Icons.radio_button_unchecked_rounded, const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          _kpiCard('Maintenance', maintenance, Icons.build_rounded, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, int val, IconData icon, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text('$val', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFloorTabs(List<RoomModel> rooms) {
    final floors = ['All Floors', ...rooms.map((r) => 'Floor ${r.floor}').toSet().toList()..sort()];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: floors.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(f),
            selected: _selectedFloor == f,
            onSelected: (val) => setState(() => _selectedFloor = f),
            selectedColor: const Color(0xFF16A34A),
            labelStyle: TextStyle(color: _selectedFloor == f ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _selectedFloor == f ? Colors.transparent : const Color(0xFFE2E8F0))),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildInventoryList(List<RoomModel> rooms, List<Map<String, dynamic>> beds) {
    final filteredRooms = rooms.where((r) {
      if (_selectedFloor != 'All Floors' && 'Floor ${r.floor}' != _selectedFloor) return false;
      return true;
    }).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: filteredRooms.map((r) => _RoomCard(
        room: r, 
        beds: beds.where((b) => b['roomId'] == r.id).toList(),
        isExpanded: _expandedRoomId == r.id,
        propertyId: widget.propertyId,
        onTap: () => setState(() => _expandedRoomId = _expandedRoomId == r.id ? null : r.id),
      )).toList(),
    );
  }

  Widget _buildInventoryAnalytics(List<Map<String, dynamic>> beds, List<RoomModel> rooms) {
    final total = beds.length;
    final occupied = beds.where((b) => b['status'] == BedStatus.occupied.name).length;
    final occupancy = total == 0 ? 0 : (occupied / total * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inventory Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _analyticCard('Average Occupancy', '$occupancy%', Icons.trending_up_rounded, const Color(0xFF16A34A))),
            const SizedBox(width: 12),
            Expanded(child: _analyticCard('Bed Turnover', '3', Icons.swap_horiz_rounded, const Color(0xFF3B82F6))),
          ],
        ),
      ],
    );
  }

  Widget _analyticCard(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final List<Map<String, dynamic>> beds;
  final bool isExpanded;
  final String propertyId;
  final VoidCallback onTap;

  const _RoomCard({required this.room, required this.beds, required this.isExpanded, required this.propertyId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final occupancy = beds.isEmpty ? 0 : (beds.where((b) => b['status'] == BedStatus.occupied.name).length / beds.length * 100).round();

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 155,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: isExpanded ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Room ${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Icon(Icons.more_vert_rounded, size: 16, color: Colors.grey),
                  ],
                ),
                Text(room.occupancyType, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: beds.map((b) => _bedIcon(b)).toList(),
                ),
                const SizedBox(height: 12),
                Text('$occupancy% Occupied', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: occupancy == 100 ? Colors.green : Colors.orange)),
              ],
            ),
          ),
        ),
        if (isExpanded) _buildExpandedDetails(context),
      ],
    );
  }

  Widget _bedIcon(Map<String, dynamic> bed) {
    final status = (bed['status'] ?? 'available').toString().toLowerCase();
    Color color = const Color(0xFF16A34A);
    if (status == 'occupied') color = const Color(0xFF3B82F6);
    if (status == 'reserved') color = const Color(0xFFD97706);
    if (status == 'maintenance') color = const Color(0xFFEF4444);

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)),
      child: Center(child: Text((bed['bedNumber'] ?? 'A').toString().substring(0, 1), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildExpandedDetails(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: beds.map((b) => _bedDetailRow(context, b)).toList(),
      ),
    );
  }

  Widget _bedDetailRow(BuildContext context, Map<String, dynamic> bed) {
    final status = (bed['status'] ?? 'available').toString().toLowerCase();
    final isOccupied = status == 'occupied';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
      child: Row(
        children: [
          _bedIcon(bed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bed['bedNumber'] ?? 'Bed A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isOccupied ? const Color(0xFF3B82F6) : const Color(0xFF16A34A))),
              ],
            ),
          ),
          const Icon(Icons.more_horiz_rounded, color: Colors.grey, size: 20),
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
  final ResidentService _residentService = ResidentService();
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildResidentSummary(),
                const SizedBox(height: 24),
                _buildSearchAndFilters(),
                const SizedBox(height: 24),
                _buildResidentList(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResidentSummary() {
    return StreamBuilder<Map<String, int>>(
      stream: _residentService.getResidentSummary(widget.propertyId),
      builder: (context, snapshot) {
        final metrics = snapshot.data ?? {'active': 0, 'upcomingCheckins': 0, 'upcomingCheckouts': 0, 'pendingKyc': 0, 'duePayments': 0};
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _summaryMetric('Active Residents', metrics['active']!, Icons.people_rounded, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
              const SizedBox(width: 12),
              _summaryMetric('Check-ins', metrics['upcomingCheckins']!, Icons.login_rounded, const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
              const SizedBox(width: 12),
              _summaryMetric('Check-outs', metrics['upcomingCheckouts']!, Icons.logout_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
              const SizedBox(width: 12),
              _summaryMetric('Pending KYC', metrics['pendingKyc']!, Icons.verified_user_outlined, const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
            ],
          ),
        );
      }
    );
  }

  Widget _summaryMetric(String label, int val, IconData icon, Color color, Color bg) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
              Text('$val', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search by resident name or booking ID...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildResidentList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _residentService.getPropertyResidents(widget.propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No active residents found'));

        return Column(
          children: docs.map((doc) => _ResidentCard(
            data: doc.data(), 
            bookingId: doc.id,
            propertyId: widget.propertyId,
          )).toList(),
        );
      }
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  final String propertyId;
  const _ResidentCard({required this.data, required this.bookingId, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'active').toString().toLowerCase();
    final rentStatus = (data['paymentStatus'] ?? 'paid').toString().toLowerCase();
    
    final checkIn = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final stayDuration = DateTime.now().difference(checkIn).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person, size: 28, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['studentName'] ?? 'Resident', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                    Text(data['studentInfo']?['college'] ?? 'N/A', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: const TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room ${data['roomName'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Bed ${data['bedNumber'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${_parseNum(data['price']).toStringAsFixed(0)} / mo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(rentStatus.capitalize(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stayDetail('Check-in', DateFormat('dd MMM yyyy').format(checkIn)),
              const SizedBox(width: 24),
              _stayDetail('Duration', '$stayDuration Days'),
              const Spacer(),
              const Text('View Details', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stayDetail(String l, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
      ],
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
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.bookingService.getPropertyBookings(widget.propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final bookings = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookingMetrics(bookings),
              const SizedBox(height: 24),
              _buildBookingPipeline(bookings),
              const SizedBox(height: 24),
              _buildSearchAndFilters(),
              const SizedBox(height: 24),
              _buildBookingList(bookings),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingMetrics(List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings) {
    final total = bookings.length;
    final confirmed = bookings.where((b) => b.data()['status'] == 'confirmed').length;
    final active = bookings.where((b) => b.data()['status'] == 'active').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _metricCard('Total Bookings', total, Icons.calendar_today_rounded, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
          const SizedBox(width: 12),
          _metricCard('Upcoming', confirmed, Icons.login_rounded, const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
          const SizedBox(width: 12),
          _metricCard('Active Stays', active, Icons.people_rounded, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF)),
        ],
      ),
    );
  }

  Widget _metricCard(String label, int val, IconData icon, Color color, Color bg) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
              Text('$val', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBookingPipeline(List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings) {
    final stages = [
      {'label': 'Requests', 'status': 'requested', 'icon': Icons.bookmark_outline_rounded},
      {'label': 'Confirmed', 'status': 'confirmed', 'icon': Icons.check_circle_outline_rounded},
      {'label': 'Active Stay', 'status': 'active', 'icon': Icons.people_outline_rounded},
      {'label': 'Completed', 'status': 'completed', 'icon': Icons.done_all_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Lifecycle Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: stages.map((stage) {
                final count = bookings.where((b) => b.data()['status'] == stage['status']).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                        child: Icon(stage['icon'] as IconData, color: const Color(0xFF64748B), size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(stage['label'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search by tenant or booking ID...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBookingList(List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings) {
    if (bookings.isEmpty) return const Center(child: Text('No bookings found for this property'));
    return Column(
      children: bookings.take(3).map((doc) => _BookingCard(data: doc.data(), bookingId: doc.id)).toList(),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  const _BookingCard({required this.data, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final isConfirmed = status == 'confirmed';
    final isActive = status == 'active';
    
    final statusColor = isActive ? const Color(0xFF16A34A) : isConfirmed ? const Color(0xFF3B82F6) : const Color(0xFFD97706);
    final statusBg = statusColor.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person, size: 28, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['studentName'] ?? 'Resident', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                    Text(data['studentPhone'] ?? '+91 98765 43210', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room ${data['roomName'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Bed ${data['bedNumber'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${_parseNum(data['price']).toStringAsFixed(0)} / mo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text('Paid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stayDetail('Booking ID', bookingId.substring(0, 8)),
              const SizedBox(width: 20),
              _stayDetail('Check-in', DateFormat('dd MMM yyyy').format((data['checkinDate'] as Timestamp?)?.toDate() ?? DateTime.now())),
              const Spacer(),
              const Text('View Details', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stayDetail(String l, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
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
  final FinanceService _financeService = FinanceService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _financeService.getPropertyPayments(widget.propertyId),
      builder: (context, paymentSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _financeService.getPropertyExpenses(widget.propertyId),
          builder: (context, expenseSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: BookingService().getPropertyBookings(widget.propertyId),
              builder: (context, bookingSnapshot) {
                if (paymentSnapshot.connectionState == ConnectionState.waiting ||
                    expenseSnapshot.connectionState == ConnectionState.waiting ||
                    bookingSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = paymentSnapshot.data?.docs ?? [];
                final expenses = expenseSnapshot.data?.docs ?? [];
                final activeResidents = bookingSnapshot.data?.docs
                    .where((d) => (d.data()['status'] ?? '').toString().toLowerCase() == 'active' || (d.data()['status'] ?? '').toString().toLowerCase() == 'checkedin')
                    .length ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFinanceKPIs(payments),
                      const SizedBox(height: 24),
                      _buildRevenueOverview(payments),
                      const SizedBox(height: 24),
                      _buildPaymentsBreakdown(payments, activeResidents),
                      const SizedBox(height: 24),
                      _buildRecentTransactions(payments),
                      const SizedBox(height: 24),
                      _buildExpenseSummary(expenses),
                      const SizedBox(height: 24),
                      _buildDepositsAndSettlements(widget.propertyId),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFinanceKPIs(List<QueryDocumentSnapshot<Map<String, dynamic>>> payments) {
    double total = 0;
    double collected = 0;

    for (var doc in payments) {
      final amount = _parseNum(doc.data()['amount']).toDouble();
      final status = (doc.data()['status'] ?? 'pending').toString().toLowerCase();
      total += amount;
      if (status == 'paid' || status == 'completed') collected += amount;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _kpiCard('Total Revenue', total, const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
          const SizedBox(width: 12),
          _kpiCard('Collected', collected, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
          const SizedBox(width: 12),
          _kpiCard('Pending', total - collected, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, double val, Color color, Color bg) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('₹${NumberFormat('#,##,###').format(val)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview(List<QueryDocumentSnapshot<Map<String, dynamic>>> payments) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 1), FlSpot(1, 1.5), FlSpot(2, 1.2), FlSpot(3, 2), FlSpot(4, 1.8), FlSpot(5, 2.5)],
                    isCurved: true,
                    color: const Color(0xFF16A34A),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF16A34A).withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsBreakdown(List<QueryDocumentSnapshot<Map<String, dynamic>>> payments, int residents) {
    int paid = payments.where((p) => (p.data()['status'] ?? '').toString().toLowerCase() == 'paid').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _payStatusBox('Paid', paid, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
          _payStatusBox('Pending', payments.length - paid, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          _payStatusBox('Residents', residents, const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
        ],
      ),
    );
  }

  Widget _payStatusBox(String l, int v, Color c, Color bg) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(Icons.check_circle_outline_rounded, size: 16, color: c)),
        const SizedBox(height: 8),
        Text('$v', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(l, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentTransactions(List<QueryDocumentSnapshot<Map<String, dynamic>>> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        ...payments.take(3).map((doc) {
          final data = doc.data();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Expanded(child: Text(data['studentName'] ?? 'Resident', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Text('₹${NumberFormat('#,##,###').format(_parseNum(data['amount']))}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExpenseSummary(List<QueryDocumentSnapshot<Map<String, dynamic>>> expenses) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expense Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          if (expenses.isEmpty) const Text('No expenses logged', style: TextStyle(fontSize: 11, color: Colors.grey))
          else ...expenses.take(3).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [Text(e.data()['category'] ?? 'Other', style: const TextStyle(fontSize: 12)), const Spacer(), Text('₹${_parseNum(e.data()['amount'])}', style: const TextStyle(fontWeight: FontWeight.bold))]),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDepositsAndSettlements(String propertyId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Deposits & Settlements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
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
  final TextEditingController _searchController = TextEditingController();

  void _showConversionFlow(Lead lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConversionFlow(lead: lead, propertyId: widget.propertyId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Lead>>(
      stream: widget.leadService.getPropertyLeads(widget.propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final leads = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeadKPIs(leads),
              const SizedBox(height: 24),
              _buildLeadPipeline(leads),
              const SizedBox(height: 24),
              _buildSearchAndFilters(),
              const SizedBox(height: 24),
              _buildLeadList(leads),
              const SizedBox(height: 24),
              _buildFollowupsWidget(leads),
              const SizedBox(height: 24),
              _buildQuickActionsLeads(),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeadKPIs(List<Lead> leads) {
    final total = leads.length;
    final newLeads = leads.where((l) => l.status == LeadStatus.newLead).length;
    final visits = leads.where((l) => l.status == LeadStatus.visitScheduled).length;
    final interested = leads.where((l) => l.status == LeadStatus.interested).length;
    final converted = leads.where((l) => l.status == LeadStatus.converted).length;
    final notConverted = leads.where((l) => l.status == LeadStatus.lost || l.status == LeadStatus.notInterested || l.status == LeadStatus.closed).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _metricCard('Total Leads', total, Icons.group_outlined, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
          const SizedBox(width: 12),
          _metricCard('New Leads', newLeads, Icons.auto_awesome_outlined, const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
          const SizedBox(width: 12),
          _metricCard('Visits Scheduled', visits, Icons.calendar_today_outlined, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          const SizedBox(width: 12),
          _metricCard('Interested', interested, Icons.favorite_outline_rounded, const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
          const SizedBox(width: 12),
          _metricCard('Converted', converted, Icons.check_circle_outline_rounded, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
          const SizedBox(width: 12),
          _metricCard('Not Converted', notConverted, Icons.cancel_outlined, const Color(0xFF64748B), const Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  Widget _metricCard(String label, int val, IconData icon, Color color, Color bg) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
              Text('$val', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          const Text('View all >', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLeadPipeline(List<Lead> leads) {
    final stages = [
      {'label': 'New Leads', 'status': LeadStatus.newLead, 'icon': Icons.auto_awesome_outlined},
      {'label': 'Visits Scheduled', 'status': LeadStatus.visitScheduled, 'icon': Icons.calendar_today_outlined},
      {'label': 'Interested', 'status': LeadStatus.interested, 'icon': Icons.remove_red_eye_outlined},
      {'label': 'Booking Pending', 'status': LeadStatus.bookingPending, 'icon': Icons.bookmark_outline_rounded},
      {'label': 'Converted', 'status': LeadStatus.converted, 'icon': Icons.check_circle_outline_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lead Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
              Text('View Pipeline Details >', style: TextStyle(color: AppTheme.successColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: stages.map((stage) {
                final count = leads.where((l) => l.status == stage['status']).length;
                final isLast = stages.last == stage;
                return Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                          child: Icon(stage['icon'] as IconData, color: const Color(0xFF64748B), size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(stage['label'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (!isLast) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 16),
                      const SizedBox(width: 12),
                    ],
                  ],
                );
              }).toList(),
            ),
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
                height: 48,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, phone, email or lead ID...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Icon(Icons.grid_view_rounded, color: Color(0xFF64748B), size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterDropdown('All Status', (v) {}),
              _filterDropdown('All Sources', (v) {}),
              _filterDropdown('All Room Types', (v) {}),
              _filterDropdown('All Sharing Types', (v) {}),
              _filterDropdown('Move-in Date', (v) {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeadList(List<Lead> leads) {
    if (leads.isEmpty) return const Center(child: Text('No leads found for this property'));
    return Column(
      children: leads.take(4).map((lead) => _LeadCard(
        lead: lead,
        onConvert: (l) => _showConversionFlow(l),
      )).toList(),
    );
  }

  Widget _buildFollowupsWidget(List<Lead> leads) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final followups = leads.where((l) {
      if (l.nextFollowupDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(l.nextFollowupDate!) == todayStr;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.notification_important_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 12),
                  Text('Today\'s Follow-ups (${followups.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                ],
              ),
              Text('View All', style: TextStyle(color: AppTheme.successColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          if (followups.isEmpty)
            const Text('No follow-ups scheduled for today', style: TextStyle(fontSize: 11, color: Colors.grey))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: followups.map((l) => _followupItem(l)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _followupItem(Lead lead) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          const CircleAvatar(radius: 14, backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.person, size: 14, color: Color(0xFF16A34A))),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lead.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(DateFormat('hh:mm a').format(lead.nextFollowupDate!), style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(Icons.call_rounded, size: 14, color: Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsLeads() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _qActionBtn(Icons.person_add_alt_1_rounded, 'Add Lead', const Color(0xFF16A34A)),
              const SizedBox(width: 12),
              _qActionBtn(Icons.calendar_today_outlined, 'Schedule Visit', const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _qActionBtn(Icons.check_circle_outline_rounded, 'Convert to Booking', const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _qActionBtn(Icons.chat_bubble_outline_rounded, 'Send Message', const Color(0xFF16A34A)),
              const SizedBox(width: 12),
              _qActionBtn(Icons.cloud_upload_outlined, 'Import Leads', const Color(0xFF8B5CF6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qActionBtn(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.1))),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _filterDropdown(String current, ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Text(current, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  final Function(Lead) onConvert;
  const _LeadCard({required this.lead, required this.onConvert});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(lead.status);
    final statusBg = statusColor.withOpacity(0.1);
    final scoreColor = _getScoreColor(lead.leadScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person, size: 28, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(lead.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                          child: Text(_getStatusLabel(lead.status), style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text(lead.studentInfo?['college'] ?? lead.professionalInfo?['company'] ?? 'Interested Prospect', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text(lead.phone, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.call_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(height: 12),
                  const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 20),
                ],
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _leadPreferenceItem('Preferred', lead.preferredSharing ?? 'Double Sharing'),
              _leadPreferenceItem('Budget', lead.budgetRange ?? '₹8k - ₹10k'),
              _leadPreferenceItem('Move-in', _formatDate(lead.preferredMoveInDate)),
              _leadPreferenceItem('Source', lead.source ?? 'Website'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lead Score', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: scoreColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${lead.leadScore.round()} - ${_getScoreLabel(lead.leadScore)}', style: TextStyle(color: scoreColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Interest Level', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                  Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 12, color: i < lead.interestLevel ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1)))),
                ],
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey, size: 20),
                onSelected: (val) {
                  if (val == 'convert') onConvert(lead);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'profile', child: Text('View Profile')),
                  const PopupMenuItem(value: 'visit', child: Text('Schedule Visit')),
                  const PopupMenuItem(value: 'convert', child: Text('Convert to Booking')),
                  const PopupMenuItem(value: 'lost', child: Text('Mark as Lost')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.redAccent;
    if (score >= 70) return Colors.orangeAccent;
    if (score >= 40) return Colors.blueAccent;
    return Colors.grey;
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'HOT';
    if (score >= 70) return 'WARM';
    if (score >= 40) return 'MEDIUM';
    return 'COLD';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead: return const Color(0xFFF59E0B);
      case LeadStatus.visitScheduled: return const Color(0xFF3B82F6);
      case LeadStatus.interested: return const Color(0xFF8B5CF6);
      case LeadStatus.bookingPending: return const Color(0xFFD97706);
      case LeadStatus.converted: return const Color(0xFF16A34A);
      default: return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead: return 'New';
      case LeadStatus.visitScheduled: return 'Visit Scheduled';
      case LeadStatus.interested: return 'Interested';
      case LeadStatus.bookingPending: return 'Booking Pending';
      case LeadStatus.converted: return 'Converted';
      default: return status.name.capitalize();
    }
  }

  Widget _leadPreferenceItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _followupInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
      ],
    );
  }
}

// ── Hosts Tab ────────────────────────────────────────────────────────────
class _HostsTab extends StatefulWidget {
  final String propertyId;
  final String ownerId;
  const _HostsTab({super.key, required this.propertyId, required this.ownerId});

  @override
  State<_HostsTab> createState() => _HostsTabState();
}

class _HostsTabState extends State<_HostsTab> {
  final StaffService _staffService = StaffService();
  final HosterService _hosterService = HosterService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StaffMember>>(
      stream: _staffService.getPropertyStaffMembers(widget.propertyId),
      builder: (context, staffSnapshot) {
        final staff = staffSnapshot.data ?? [];
        
        // Calculate KPIs from real staff data
        final totalHosts = staff.length;
        final primaryHosts = staff.where((s) => s.assignment.role == StaffRole.primaryHost).length;
        final assistantHosts = staff.where((s) => s.assignment.role == StaffRole.assistantHost).length;
        final activePermissions = staff.fold<int>(0, (acc, s) => acc + s.assignment.permissions.length);
        
        return StreamBuilder<Map<String, dynamic>>(
          stream: _staffService.getStaffKPIs(widget.propertyId), // For pending invites
          builder: (context, kpiSnapshot) {
            final kpis = kpiSnapshot.data ?? {
              'pendingInvitations': 0,
            };

            final combinedKpis = {
              'totalHosts': totalHosts,
              'primaryHosts': primaryHosts,
              'assistantHosts': assistantHosts,
              'activePermissions': activePermissions,
              'pendingInvitations': kpis['pendingInvitations'],
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStaffKPIs(combinedKpis),
                  const SizedBox(height: 24),
                  _buildOwnerSection(),
                  const SizedBox(height: 24),
                  _buildPrimaryHostSection(staff),
                  const SizedBox(height: 24),
                  _buildAssistantHostsSection(staff),
                  const SizedBox(height: 24),
                  _buildActivityFeed(staff),
                  const SizedBox(height: 24),
                  _buildQuickActionsStaff(),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildStaffKPIs(Map<String, dynamic> kpis) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _staffKpiCard('Total Hosts', kpis['totalHosts'], Icons.people_outline_rounded, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
          const SizedBox(width: 12),
          _staffKpiCard('Primary Hosts', kpis['primaryHosts'], Icons.person_pin_rounded, const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
          const SizedBox(width: 12),
          _staffKpiCard('Assistant Hosts', kpis['assistantHosts'], Icons.person_outline_rounded, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF)),
          const SizedBox(width: 12),
          _staffKpiCard('Permissions', kpis['activePermissions'], Icons.vpn_key_outlined, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          const SizedBox(width: 12),
          _staffKpiCard('Pending Invites', kpis['pendingInvitations'], Icons.mail_outline_rounded, const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
        ],
      ),
    );
  }

  Widget _staffKpiCard(String label, int val, IconData icon, Color color, Color bg) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
              Text('$val', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          const Text('View all >', style: TextStyle(fontSize: 8, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOwnerSection() {
    if (widget.ownerId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _hosterService.getUserProfileStream(widget.ownerId),
      builder: (context, snapshot) {
        final userData = snapshot.data ?? {};
        if (userData.isEmpty) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return const SizedBox.shrink();
        }

        final info = userData['info'] as Map? ?? {};
        final name = info['name'] ?? userData['name'] ?? 'Unknown Owner';
        final phone = userData['phone'] ?? userData['phoneNumber'] ?? 'N/A';
        final email = userData['email'] ?? 'N/A';
        final profileImage = info['profileImage'] ?? userData['profilePicture'];
        final createdAt = (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Property Owner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28, 
                    backgroundColor: const Color(0xFFF1F5F9), 
                    backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                    child: profileImage == null ? const Icon(Icons.person, size: 32, color: Colors.grey) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)), child: const Text('Owner', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Owner Since', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                      Text(DateFormat('dd MMM yyyy').format(createdAt), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPrimaryHostSection(List<StaffMember> staff) {
    final primary = staff.firstWhere(
      (s) => s.assignment.role == StaffRole.primaryHost,
      orElse: () => StaffMember(
        assignment: HostAssignment(id: '', propertyId: widget.propertyId, userId: '', role: StaffRole.primaryHost, status: StaffStatus.inactive, assignedAt: DateTime.now()),
        user: model.User(id: '', name: 'Not Assigned', phoneNumber: 'N/A', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ),
    );

    final isActive = primary.assignment.status == StaffStatus.active;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Primary Host', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            if (primary.user.id.isNotEmpty)
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? const Color(0xFF16A34A) : Colors.grey, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF16A34A) : Colors.grey)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 16),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28, 
                    backgroundColor: const Color(0xFFF1F5F9), 
                    backgroundImage: primary.user.profilePicture != null ? NetworkImage(primary.user.profilePicture!) : null,
                    child: primary.user.profilePicture == null ? const Icon(Icons.person, size: 32, color: Colors.grey) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(primary.user.name ?? 'Not Assigned', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)), child: const Text('Primary Host', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        Text(primary.user.phoneNumber, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        if (primary.user.email != null)
                          Text(primary.user.email!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        if (primary.user.id.isNotEmpty)
                          Text('Assigned Since: ${DateFormat('dd MMM yyyy').format(primary.assignment.assignedAt)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              if (primary.user.id.isNotEmpty) ...[
                const Divider(height: 32, color: Color(0xFFF1F5F9)),
                _buildPermissionsGrid(primary.assignment.permissions),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsGrid(List<String> perms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Permissions', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
            Text('${perms.length} Enabled', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: perms.take(6).map((p) => _permissionChip(p)).toList()..add(_viewAllChip()),
        ),
      ],
    );
  }

  Widget _permissionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _viewAllChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: const Text('View all >', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
    );
  }

  Widget _buildAssistantHostsSection(List<StaffMember> staff) {
    final assistants = staff.where((s) => s.assignment.role == StaffRole.assistantHost).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Assistant Hosts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const Text('View all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
          ],
        ),
        const SizedBox(height: 12),
        if (assistants.isEmpty)
          _buildEmptyStaffState()
        else
          ...assistants.map((s) => _assistantHostCard(s)).toList(),
      ],
    );
  }

  Widget _buildEmptyStaffState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle), child: const Icon(Icons.mail_outline_rounded, color: Color(0xFF16A34A), size: 32)),
          const SizedBox(height: 16),
          const Text('No assistant hosts yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const Text('Invite staff to manage your property', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _assistantHostCard(StaffMember staff) {
    final isActive = staff.assignment.status == StaffStatus.active;
    return InkWell(
      onTap: () => _showManagePermissionsDialog(staff.assignment),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24, 
              backgroundColor: const Color(0xFFF1F5F9), 
              backgroundImage: staff.user.profilePicture != null ? NetworkImage(staff.user.profilePicture!) : null,
              child: staff.user.profilePicture == null ? const Icon(Icons.person, size: 24, color: Colors.grey) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.user.name ?? 'Unknown', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(staff.user.phoneNumber, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  if (staff.user.email != null)
                    Text(staff.user.email!, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  Text('Assigned: ${DateFormat('dd MMM yyyy').format(staff.assignment.assignedAt)}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Permissions', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
                Text('${staff.assignment.permissions.length} Enabled', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(color: isActive ? const Color(0xFF16A34A) : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed(List<StaffMember> staff) {
    return StreamBuilder<List<StaffActivity>>(
      stream: _staffService.getPropertyActivity(widget.propertyId),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Host Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const Text('View all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  if (activities.isEmpty)
                    const Text('No recent activity', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else
                    ...activities.map((a) => _activityItem(a, staff)).toList(),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _activityItem(StaffActivity activity, List<StaffMember> staff) {
    final host = staff.firstWhere((s) => s.user.id == activity.hostId, orElse: () => StaffMember(
      assignment: HostAssignment(id: '', propertyId: widget.propertyId, userId: activity.hostId, role: StaffRole.assistantHost, status: StaffStatus.inactive, assignedAt: DateTime.now()),
      user: model.User(id: activity.hostId, name: 'Unknown Host', phoneNumber: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    ));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.assignment_outlined, size: 14, color: Color(0xFF64748B))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    children: [
                      TextSpan(text: host.user.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      TextSpan(text: ' ${activity.description}'),
                    ],
                  ),
                ),
                Text(DateFormat('hh:mm a, dd MMM').format(activity.timestamp), style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
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

  Widget _buildQuickActionsStaff() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _staffActionBtn(Icons.person_add_alt_1_rounded, 'Add Host', const Color(0xFF16A34A), onTap: () {}),
              const SizedBox(width: 12),
              _staffActionBtn(Icons.mail_outline_rounded, 'Invite Host', const Color(0xFF3B82F6), onTap: _showInviteHostDialog),
              const SizedBox(width: 12),
              _staffActionBtn(Icons.vpn_key_outlined, 'Manage Permissions', const Color(0xFFF59E0B), onTap: () {}),
              const SizedBox(width: 12),
              _staffActionBtn(Icons.history_rounded, 'Host Activity Log', const Color(0xFF8B5CF6), onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _staffActionBtn(IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.1))),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Dialogs ────────────────────────────────────────────────────────────
class _AddRoomDialog extends StatefulWidget {
  final String propertyId;
  final VoidCallback onComplete;
  const _AddRoomDialog({required this.propertyId, required this.onComplete});

  @override
  State<_AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<_AddRoomDialog> {
  final _numberController = TextEditingController();
  final _floorController = TextEditingController();
  final _rentController = TextEditingController();
  final _bedCountController = TextEditingController(text: '1');
  RoomType _selectedType = RoomType.single;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add New Room', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(_numberController, 'Room Number (e.g. 101, A203)', Icons.meeting_room_outlined),
            const SizedBox(height: 16),
            _buildField(_floorController, 'Floor Number', Icons.layers_outlined, isNumber: true),
            const SizedBox(height: 16),
            _buildField(_rentController, 'Monthly Rent (₹)', Icons.payments_outlined, isNumber: true),
            const SizedBox(height: 16),
            _buildField(_bedCountController, 'Number of Beds', Icons.bed_outlined, isNumber: true),
            const SizedBox(height: 16),
            DropdownButtonFormField<RoomType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Room Type',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: RoomType.values.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.name.capitalize()),
              )).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add Room'),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _submit() async {
    if (_numberController.text.isEmpty || _floorController.text.isEmpty || _rentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bedCount = int.tryParse(_bedCountController.text) ?? 1;
      final rent = double.tryParse(_rentController.text) ?? 0;
      final floor = int.tryParse(_floorController.text) ?? 1;

      final room = RoomModel(
        id: '',
        propertyId: widget.propertyId,
        roomNumber: _numberController.text,
        roomType: _selectedType,
        occupancyType: '${_selectedType.name.capitalize()} Sharing',
        floor: floor,
        totalBeds: bedCount,
        availableBeds: bedCount,
        occupiedBeds: 0,
        baseRent: rent,
        baseDeposit: rent * 2, // Default 2 months deposit
        amenities: [],
        images: [],
        genderRestriction: 'Anyone',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final List<Map<String, dynamic>> bedData = List.generate(bedCount, (index) => {
        'bedNumber': '${_numberController.text}-${String.fromCharCode(65 + index)}',
        'status': BedStatus.available.name,
        'price': rent,
      });

      await InventoryService().createRoomWithBeds(
        propertyId: widget.propertyId, 
        room: room, 
        bedData: bedData,
      );

      widget.onComplete();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _MoveBedFlow extends StatelessWidget {
  final String propertyId;
  final String bookingId;
  final String currentBedId;
  const _MoveBedFlow({required this.propertyId, required this.bookingId, required this.currentBedId});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Move Bed Flow'));
  }
}

class _ConversionFlow extends StatefulWidget {
  final Lead lead;
  final String propertyId;
  const _ConversionFlow({required this.lead, required this.propertyId});

  @override
  State<_ConversionFlow> createState() => _ConversionFlowState();
}

class _ConversionFlowState extends State<_ConversionFlow> {
  int _currentStep = 0;
  String? _selectedFloor;
  String? _selectedRoom;
  String? _selectedBed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Convert to Booking', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Assign a specific bed to finalize the resident stay.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 3) setState(() => _currentStep++);
                else _finalizeConversion();
              },
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep--);
              },
              steps: [
                Step(
                  title: const Text('Confirm Property'),
                  subtitle: Text(widget.lead.interestedPropertyName ?? 'Sunrise PG'),
                  content: const Text('Ensure the prospect is interested in this specific property.'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Select Floor'),
                  content: _buildSelectionGrid(['Ground Floor', 'Floor 1', 'Floor 2', 'Floor 3'], _selectedFloor, (v) => setState(() => _selectedFloor = v)),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Select Room'),
                  content: _buildSelectionGrid(['Room D-201', 'Room D-202', 'Room D-203', 'Room D-204'], _selectedRoom, (v) => setState(() => _selectedRoom = v)),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Select Available Bed'),
                  content: _buildSelectionGrid(['Bed A (Available)', 'Bed B (Available)', 'Bed C (Maintenance)'], _selectedBed, (v) => setState(() => _selectedBed = v)),
                  isActive: _currentStep >= 3,
                  state: _currentStep == 3 ? StepState.editing : StepState.indexed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionGrid(List<String> options, String? selected, Function(String) onSelect) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((opt) {
        final isSelected = selected == opt;
        final isDisabled = opt.contains('Maintenance');
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: isDisabled ? null : (val) => onSelect(opt),
          selectedColor: const Color(0xFF16A34A),
          labelStyle: TextStyle(color: isSelected ? Colors.white : (isDisabled ? Colors.grey : const Color(0xFF475569)), fontWeight: FontWeight.bold),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0))),
        );
      }).toList(),
    );
  }

  void _finalizeConversion() async {
    // Implement actual service call here
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lead ${widget.lead.name} successfully converted to Booking at $_selectedBed!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }
}

class _AddExpenseDialog extends StatefulWidget {
  final String propertyId;
  final VoidCallback onComplete;
  const _AddExpenseDialog({required this.propertyId, required this.onComplete});

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Maintenance';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log New Expense', style: TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _category,
            items: ['Maintenance', 'Utilities', 'Food & Supplies', 'Salary', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 16),
          TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹'), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Log Expense'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_amountController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FinanceService().createExpense({
        'propertyId': widget.propertyId,
        'category': _category,
        'amount': double.tryParse(_amountController.text) ?? 0,
        'description': _descController.text,
      });
      widget.onComplete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _InviteHostDialog extends StatefulWidget {
  final String propertyId;
  final VoidCallback onComplete;
  const _InviteHostDialog({super.key, required this.propertyId, required this.onComplete});

  @override
  State<_InviteHostDialog> createState() => _InviteHostDialogState();
}

class _InviteHostDialogState extends State<_InviteHostDialog> {
  final _emailController = TextEditingController();
  StaffRole _selectedRole = StaffRole.assistantHost;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite New Host', style: TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email Address', hintText: 'Enter host email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<StaffRole>(
            value: _selectedRole,
            items: [StaffRole.assistantHost, StaffRole.primaryHost, StaffRole.propertyManager].map((r) => DropdownMenuItem(value: r, child: Text(r.name.capitalize()))).toList(),
            onChanged: (v) => setState(() => _selectedRole = v!),
            decoration: const InputDecoration(labelText: 'Role'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Send Invitation'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final invitedBy = currentUser?.displayName ?? currentUser?.email ?? 'Property Admin';

      await StaffService().inviteHost(
        propertyId: widget.propertyId,
        email: _emailController.text,
        role: _selectedRole,
        invitedBy: invitedBy,
      );
      widget.onComplete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _ManagePermissionsDialog extends StatefulWidget {
  final HostAssignment staff;
  final VoidCallback onComplete;
  const _ManagePermissionsDialog({super.key, required this.staff, required this.onComplete});

  @override
  State<_ManagePermissionsDialog> createState() => _ManagePermissionsDialogState();
}

class _ManagePermissionsDialogState extends State<_ManagePermissionsDialog> {
  late List<String> _selectedPermissions;
  bool _isLoading = false;

  final List<String> _allPermissions = [
    'View Leads', 'Create Leads', 'Edit Leads', 'Convert Leads',
    'View Bookings', 'Create Bookings', 'Cancel Bookings', 'Modify Bookings',
    'Assign Beds', 'Block Beds', 'Manage Rooms',
    'View Residents', 'Check-in', 'Check-out', 'Move Residents',
    'View Finance', 'Collect Rent', 'Manage Deposits',
    'View Complaints', 'Resolve Complaints'
  ];

  @override
  void initState() {
    super.initState();
    _selectedPermissions = List.from(widget.staff.permissions);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manage Permissions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Select specific modules this host can access and manage.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: _allPermissions.map((p) {
                final isSelected = _selectedPermissions.contains(p);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) _selectedPermissions.add(p);
                      else _selectedPermissions.remove(p);
                    });
                  },
                  title: Text(p, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  activeColor: const Color(0xFF16A34A),
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Update Permissions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await StaffService().updatePermissions(widget.staff.id, _selectedPermissions);
      widget.onComplete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
