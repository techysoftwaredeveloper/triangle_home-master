import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_profile_screen.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/services/booking_service.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/hoster/hoster_bottom_nav.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HosterDashboardScreen extends StatefulWidget {
  const HosterDashboardScreen({super.key});

  @override
  State<HosterDashboardScreen> createState() => _HosterDashboardScreenState();
}

class _HosterDashboardScreenState extends State<HosterDashboardScreen> {
  int _selectedIndex = 0;
  final PropertyService _propertyService = PropertyService();
  final BookingService _bookingService = BookingService();
  final HosterService _hosterService = HosterService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _DashboardTab(uid: _uid, hosterService: _hosterService),
      _PropertiesTab(uid: _uid, propertyService: _propertyService),
      _BookingsTab(uid: _uid, bookingService: _bookingService),
      _LeadsTab(uid: _uid),
      const HosterProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: tabs[_selectedIndex],
      bottomNavigationBar: HosterBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton.extended(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ListPropertyScreen(),
                      ),
                    ),
                backgroundColor: AppTheme.successColor,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Add Property',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                elevation: 10,
              )
              : null,
    );
  }
}

// ── Dashboard Tab ────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final String uid;
  final HosterService hosterService;
  const _DashboardTab({required this.uid, required this.hosterService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: hosterService.getDetailedHosterStatsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final properties = data['properties'] as List? ?? [];
        final recentActivity = data['recentActivity'] as List? ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildHeader(context, data),
          body: RefreshIndicator(
            onRefresh:
                () async => hosterService.getDetailedHosterStatsStream(uid),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildPropertyStatusCard(
                    properties.isNotEmpty ? properties.first : null,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Today\'s Actions'),
                  _buildActionCards(data),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Overview'),
                  _buildOverviewGrid(data),
                  const SizedBox(height: 32),
                  _buildSectionHeader('My Properties', onViewAll: () {}),
                  _buildPropertiesCarousel(properties),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRevenueInsight(data)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildHostManagement()),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Recent Activity'),
                  _buildRecentActivity(recentActivity),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context, Map data) {
    final name = data['hosterName'] ?? 'Jibin';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'J';
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFDCFCE7),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning, $name 👋',
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              Text(
                data['hosterRole'] ?? 'Host & Property Manager',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF1E293B),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPropertyStatusCard(Map? property) {
    if (property == null) return const SizedBox.shrink();
    final images = property['images'] as List? ?? [];
    final name = property['basicInfo']?['name'] ?? 'Sunrise PG';
    final occupancy = 92;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                images.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: images.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                    : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.apartment),
                    ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${property['city'] ?? "Kochi"}, ${property['locality'] ?? "Kerala"}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Since Jan 2024',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildCircularOccupancy(occupancy),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  Widget _buildCircularOccupancy(int value) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: value / 100,
            strokeWidth: 4,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Text(
              'Occupancy',
              style: TextStyle(
                fontSize: 6,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCards(Map data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _actionCard(
            'New Inquiries',
            data['newInquiries']?.toString() ?? '0',
            Icons.chat_bubble_rounded,
            const Color(0xFF3B82F6),
          ),
          _actionCard(
            'Pending Check-ins',
            data['pendingCheckins']?.toString() ?? '0',
            Icons.calendar_today_rounded,
            const Color(0xFFF59E0B),
          ),
          _actionCard(
            'Rent Payments Due',
            data['paymentsDue']?.toString() ?? '0',
            Icons.currency_rupee_rounded,
            const Color(0xFFF97316),
          ),
          _actionCard(
            'Bookings Confirmed',
            data['bookingsConfirmed']?.toString() ?? '0',
            Icons.check_circle_rounded,
            const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, String count, IconData icon, Color color) {
    return Container(
      width: 130,
      height: 160,
      margin: const EdgeInsets.only(right: 12, top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(Map data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _overviewCard(
          'Active Residents',
          data['activeResidents']?.toString() ?? '0',
          '6 vs last month',
          true,
        ),
        _overviewCard(
          'Vacant Beds',
          data['vacantBeds']?.toString() ?? '0',
          '2 vs last month',
          false,
        ),
        _overviewCard(
          'Occupancy',
          '${data['occupancy']}%',
          '8% vs last month',
          true,
        ),
        _overviewCard(
          'Monthly Revenue',
          '₹${(data['monthlyRevenue'] ?? 0).toString()}',
          '12% vs last month',
          true,
        ),
      ],
    );
  }

  Widget _overviewCard(
    String title,
    String value,
    String change,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title.contains('Residents')
                    ? Icons.people_rounded
                    : title.contains('Beds')
                    ? Icons.bed_rounded
                    : title.contains('Occupancy')
                    ? Icons.pie_chart_rounded
                    : Icons.currency_rupee_rounded,
                size: 16,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 10,
                color:
                    isPositive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesCarousel(List properties) {
    if (properties.isEmpty)
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No properties listed')),
      );

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: properties.length,
            controller: PageController(viewportFraction: 0.9),
            itemBuilder: (context, index) {
              final p = properties[index];
              final images = p['images'] as List? ?? [];
              final name = p['basicInfo']?['name'] ?? 'Property';

              return Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child:
                          images.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: images.first,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                              : Container(height: 120, color: Colors.grey[200]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      Text(
                                        ' ${p['city']}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _propStat('95%', 'Occupancy'),
                              _propStat('2', 'Vacant Beds'),
                              _propStat('4', 'Inquiries'),
                              _propStat('21', 'Residents'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              [0, 1, 2]
                  .map(
                    (i) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color:
                            i == 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _propStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueInsight(Map data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue This Month',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'View Report',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${(data['monthlyRevenue'] ?? 0).toString()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 10,
                color: Color(0xFF16A34A),
              ),
              const Text(
                ' 12%',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' from last month',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 4),
                      FlSpot(1, 6),
                      FlSpot(2, 4.5),
                      FlSpot(3, 8),
                      FlSpot(4, 5),
                      FlSpot(5, 7),
                      FlSpot(6, 9.5),
                    ],
                    isCurved: true,
                    color: const Color(0xFF16A34A),
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 May',
                style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
              ),
              Text(
                '29 May',
                style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHostManagement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Host Management',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'Manage',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _mgmtRow(
            Icons.people_outline_rounded,
            'Total Hosts',
            '4',
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _mgmtRow(
            Icons.person_pin_rounded,
            'Active Hosts',
            '3',
            const Color(0xFF16A34A),
          ),
          const SizedBox(height: 12),
          _mgmtRow(
            Icons.mail_outline_rounded,
            'Pending Invitations',
            '1',
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_rounded,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                Text(
                  ' Invite New Host',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mgmtRow(IconData i, String l, String v, Color c) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(i, size: 14, color: c),
        ),
        const SizedBox(width: 8),
        Text(
          l,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          v,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(List activities) {
    return Column(
      children:
          activities
              .map(
                (a) => Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              (a['type'] == 'booking'
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFFF7ED)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          a['type'] == 'booking'
                              ? Icons.calendar_today_rounded
                              : Icons.currency_rupee_rounded,
                          size: 16,
                          color:
                              (a['type'] == 'booking'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFF59E0B)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a['title'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a['time'],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontFamily: 'Outfit',
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Properties Tab ────────────────────────────────────────────────────────────
class _PropertiesTab extends StatelessWidget {
  final String uid;
  final PropertyService propertyService;
  const _PropertiesTab({required this.uid, required this.propertyService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: propertyService.getHosterProperties(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 64,
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No properties listed yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start earning by listing your first property',
                  style: TextStyle(color: AppTheme.textLightColor),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ListPropertyScreen(),
                        ),
                      ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Your First Property'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final basic = data['basicInfo'] as Map<String, dynamic>? ?? {};
            final images = data['images'] as List? ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () {},
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child:
                              images.isNotEmpty
                                  ? Image.network(
                                    images.first,
                                    fit: BoxFit.cover,
                                  )
                                  : const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                  ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              basic['type'] ?? 'PG',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  basic['collegeName'] ?? 'Unnamed Property',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 14,
                                      color: AppTheme.textMutedColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      data['city'] ?? 'Location',
                                      style: const TextStyle(
                                        color: AppTheme.textMutedColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFCBD5E1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Bookings Tab ──────────────────────────────────────────────────────────────
class _BookingsTab extends StatelessWidget {
  final String uid;
  final BookingService bookingService;
  const _BookingsTab({required this.uid, required this.bookingService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: bookingService.getHosterBookings(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No bookings received yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final status = data['status'] as String? ?? 'pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['propertyName'] ?? 'Property',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'For: ${data['studentName'] ?? 'Student'}',
                              style: const TextStyle(
                                color: AppTheme.textMutedColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount: ₹${data['price'] ?? '0'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View Details'),
                      ),
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
}

class _LeadsTab extends StatelessWidget {
  final String uid;
  const _LeadsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Leads & Inquiries',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_rounded,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              'No new leads found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Text(
              'New inquiries from students will appear here',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppTheme.successColor;
        break;
      case 'rejected':
      case 'cancelled':
        color = AppTheme.errorColor;
        break;
      default:
        color = AppTheme.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}
