import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/providers/property_detail_provider.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/booking_summary_screen.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/property_detail_v2/property_gallery.dart';
import 'package:triangle_home/widgets/property_detail_v2/property_overview_card.dart';
import 'package:triangle_home/widgets/property_detail_v2/occupancy_types_section.dart';
import 'package:triangle_home/widgets/property_detail_v2/available_rooms_section.dart';
import 'package:triangle_home/widgets/property_detail_v2/host_profile_section.dart';
import 'package:triangle_home/widgets/property_detail_v2/sticky_booking_bar.dart';

class PropertyDetailScreenV2 extends ConsumerStatefulWidget {
  final Map<String, dynamic> property;

  const PropertyDetailScreenV2({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreenV2> createState() => _PropertyDetailScreenV2State();
}

class _PropertyDetailScreenV2State extends ConsumerState<PropertyDetailScreenV2> {
  Map<String, dynamic>? _selectedRoom;
  Map<String, dynamic>? _selectedBed;

  void _onBedSelected(Map<String, dynamic> room, Map<String, dynamic> bed) {
    setState(() {
      if (_selectedBed?['id'] == bed['id']) {
        _selectedBed = null;
        _selectedRoom = null;
      } else {
        _selectedRoom = room;
        _selectedBed = bed;
      }
    });
  }

  Future<void> _handleBooking() async {
    if (_selectedBed == null) return;

    final user = FirebaseAuth.instance.currentUser;
    
    // Fetch real user info if available
    Map<String, String> primaryTenant = {
      'name': 'Primary Tenant',
      'phone': 'Your registered phone',
      'email': 'Your registered email',
      'college': 'Your college',
    };

    if (user != null) {
      try {
        final profile = await FirebaseService().getUserProfile();
        if (profile != null) {
          final info = profile['info'] as Map? ?? {};
          primaryTenant = {
            'name': info['name'] ?? user.displayName ?? 'Primary Tenant',
            'phone': info['phoneNumber'] ?? user.phoneNumber ?? 'Not provided',
            'email': info['email'] ?? user.email ?? 'Not provided',
            'college': profile['student_info']?['college'] ?? 'Your college',
          };
        }
      } catch (e) {
        debugPrint('Error fetching user profile for booking: $e');
      }
    }

    // Determine prices with fallback to property-level defaults
    final double rent = _parsePrice(_selectedBed?['monthlyRent'] ?? widget.property['monthlyRent'] ?? widget.property['price']);
    final double deposit = _parsePrice(_selectedBed?['securityDeposit'] ?? widget.property['securityDeposit'] ?? widget.property['deposit']);

    final bookingData = {
      ...widget.property,
      'selectedRoomId': _selectedRoom?['id'],
      'selectedBedId': _selectedBed?['id'],
      'roomNumber': _selectedRoom?['roomNumber'],
      'bedNumber': _selectedBed?['bedNumber'],
      'price': rent,
      'monthlyRent': rent,
      'deposit': deposit,
      'securityDeposit': deposit,
    };

    final bookingSummary = BookingSummaryScreen(
      accommodation: bookingData,
      tenantDetails: [primaryTenant],
      tenants: const [],
      tenantCount: 1,
    );

    if (user == null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => LoginScreen(
                isStudent: true,
                onLoginNavigateTo: bookingSummary,
              ),
        ),
      );
    } else {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => bookingSummary),
      );
    }
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final propertyId = widget.property['id'] as String;
    final statsAsync = ref.watch(propertyStatsProvider(propertyId));
    final occupancyTypes = ref.watch(occupancyTypesProvider(propertyId));
    final roomsAsync = ref.watch(propertyRoomsProvider(propertyId));
    final bedsAsync = ref.watch(propertyBedsProvider(propertyId));
    final hostId = widget.property['hoster_id'] as String? ?? '';
    final hostAsync = ref.watch(hostProfileProvider(hostId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            key: const Key('property_detail_scroll'),
            slivers: [
              SliverToBoxAdapter(
                child: PropertyGallery(
                  images: List<String>.from(widget.property['images'] ?? []),
                ),
              ),
              SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (stats) => PropertyOverviewCard(property: widget.property, stats: stats),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
              SliverToBoxAdapter(
                child: OccupancyTypesSection(occupancyTypes: occupancyTypes),
              ),
              SliverToBoxAdapter(
                child: roomsAsync.when(
                  data: (rooms) => bedsAsync.when(
                    data: (beds) => AvailableRoomsSection(
                      rooms: rooms,
                      beds: beds,
                      selectedBedId: _selectedBed?['id'],
                      onBedSelected: _onBedSelected,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
              // Missing sections like Food, Safety, Rules would go here
              _buildSectionTitle('Amenities'),
              _buildAmenitiesList(),
              _buildSectionTitle('Property Rules'),
              _buildRulesList(),
              SliverToBoxAdapter(
                child: hostAsync.when(
                  data: (host) => host.isNotEmpty ? HostProfileSection(host: host) : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StickyBookingBar(
              selectedRoom: _selectedRoom,
              selectedBed: _selectedBed,
              onBookPressed: _handleBooking,
              defaultRent: widget.property['monthlyRent'] ?? widget.property['price'],
              defaultDeposit: widget.property['securityDeposit'] ?? widget.property['deposit'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAmenitiesList() {
    final amenities = widget.property['amenities'] as List? ?? [];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: amenities.map((a) => _buildAmenityChip(a.toString())).toList(),
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.successColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRulesList() {
    final rules = widget.property['rules'] as List? ?? [
      'No smoking inside rooms',
      'No outsiders allowed after 10 PM',
      'Maintain silence in common areas',
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: rules.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                Expanded(child: Text(r.toString(), style: const TextStyle(color: Colors.grey))),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}
