import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/providers/property_detail_provider.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/booking/confirm_booking_screen.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/property_detail_v2/property_gallery.dart';
import 'package:triangle_home/widgets/property_detail_v2/property_overview_card.dart';
import 'package:triangle_home/widgets/property_detail_v2/occupancy_types_section.dart';
import 'package:triangle_home/widgets/property_detail_v2/host_profile_section.dart';
import 'package:triangle_home/widgets/property_detail_v2/sticky_booking_bar.dart';
import 'package:triangle_home/widgets/property_detail_v2/amenities_grid.dart';
import 'package:triangle_home/widgets/property_detail_v2/house_rules_card.dart';
import 'package:triangle_home/widgets/rooms_floors/rooms_floors_header_stats.dart';
import 'package:triangle_home/widgets/rooms_floors/floor_accordion.dart';
import 'package:triangle_home/widgets/rooms_floors/bed_status_guide.dart';
import 'package:triangle_home/widgets/property_detail_v2/review_card.dart';
import 'package:triangle_home/services/review_service.dart';
import 'package:triangle_home/models/review_model.dart';

class PropertyDetailScreenV2 extends ConsumerStatefulWidget {
  final Map<String, dynamic> property;

  const PropertyDetailScreenV2({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreenV2> createState() => _PropertyDetailScreenV2State();
}

class _PropertyDetailScreenV2State extends ConsumerState<PropertyDetailScreenV2> {
  Map<String, dynamic>? _selectedRoom;
  Map<String, dynamic>? _selectedBed;
  final ReviewService _reviewService = ReviewService();

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
          final pInfo = profile['professional_info'] as Map? ?? {};
          primaryTenant = {
            'name': info['name'] ?? user.displayName ?? 'Primary Tenant',
            'phone': info['phoneNumber'] ?? user.phoneNumber ?? 'Not provided',
            'email': info['email'] ?? user.email ?? 'Not provided',
            'college': profile['student_info']?['college'] ?? pInfo['companyName'] ?? 'Your college',
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
      'selectedRoomName': _selectedRoom?['roomNumber'],
      'selectedBedName': _selectedBed?['bedNumber'],
      'selectedFloor': _selectedRoom?['floor']?.toString() ?? _extractFloor(_selectedRoom?['roomNumber']?.toString() ?? ''),
      'price': rent,
      'monthlyRent': rent,
      'deposit': deposit,
      'securityDeposit': deposit,
      'moveInDate': DateTime.now().toIso8601String(),
    };

    final confirmBooking = ConfirmBookingScreen(
      accommodation: bookingData,
      tenantDetails: [primaryTenant],
    );

    if (user == null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => LoginScreen(
                isStudent: true,
                onLoginNavigateTo: confirmBooking,
              ),
        ),
      );
    } else {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => confirmBooking),
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
                child: statsAsync.when(
                  data: (stats) => PropertyGallery(
                    images: List<String>.from(widget.property['images'] ?? []),
                    property: widget.property,
                    stats: stats,
                  ),
                  loading: () => PropertyGallery(
                    images: List<String>.from(widget.property['images'] ?? []),
                    property: widget.property,
                  ),
                  error: (_, __) => PropertyGallery(
                    images: List<String>.from(widget.property['images'] ?? []),
                    property: widget.property,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (stats) => bedsAsync.when(
                    data: (beds) {
                      // Calculate min deposit from beds if not in property
                      double? minDeposit;
                      for (var bed in beds) {
                        final dep = _parsePrice(bed['securityDeposit'] ?? bed['deposit'] ?? bed['advance']);
                        if (dep > 0 && (minDeposit == null || dep < minDeposit)) {
                          minDeposit = dep;
                        }
                      }
                      
                      return PropertyOverviewCard(
                        property: widget.property, 
                        stats: stats,
                        calculatedDeposit: minDeposit,
                      );
                    },
                    loading: () => PropertyOverviewCard(property: widget.property, stats: stats),
                    error: (_, __) => PropertyOverviewCard(property: widget.property, stats: stats),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
              _buildSectionTitle('Amenities'),
              SliverToBoxAdapter(
                child: AmenitiesGrid(
                  amenities: _getCombinedAmenities(),
                ),
              ),
              SliverToBoxAdapter(
                child: OccupancyTypesSection(
                  occupancyTypes: occupancyTypes,
                  onViewAll: () {
                    // This could scroll to the Rooms & Floors section
                  },
                ),
              ),
              
              // Rooms & Floors Section (Now part of the same scroll view)
              _buildSectionTitle('Rooms & Floors'),
              roomsAsync.when(
                data: (rooms) => bedsAsync.when(
                  data: (beds) {
                    final Map<String, List<Map<String, dynamic>>> roomsByFloor = {};
                    for (var room in rooms) {
                      final floor = room['floor']?.toString() ?? _extractFloor(room['roomNumber']?.toString() ?? '');
                      roomsByFloor.putIfAbsent(floor, () => []).add(room);
                    }
                    final sortedFloors = roomsByFloor.keys.toList()..sort();

                    final int totalFloors = sortedFloors.length;
                    final int totalRooms = rooms.length;
                    final int totalBedsCount = beds.length;
                    final int availableBedsCount = beds.where((b) => b['status']?.toString().toLowerCase() == 'available').length;

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        RoomsFloorsHeaderStats(
                          totalFloors: totalFloors,
                          totalRooms: totalRooms,
                          totalBeds: totalBedsCount,
                          availableBeds: availableBedsCount,
                        ),
                        ...sortedFloors.map((floor) {
                          return FloorAccordion(
                            floorName: floor,
                            rooms: roomsByFloor[floor]!,
                            allBeds: beds,
                            selectedBedId: _selectedBed?['id'],
                            onBedSelected: _onBedSelected,
                            initiallyExpanded: sortedFloors.indexOf(floor) == 0,
                          );
                        }),
                      ]),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              const SliverToBoxAdapter(child: BedStatusGuide()),

              _buildSectionTitle('User Reviews'),
              SliverToBoxAdapter(
                child: StreamBuilder<List<ReviewModel>>(
                  stream: _reviewService.getPropertyReviews(propertyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                    }
                    final reviews = snapshot.data ?? [];
                    if (reviews.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      );
                    }
                    return SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) => ReviewCard(review: reviews[index]),
                      ),
                    );
                  },
                ),
              ),

              _buildSectionTitle('House Rules'),
              SliverToBoxAdapter(
                child: HouseRulesCard(
                  rules: widget.property['rules'] ?? [
                    'No smoking inside rooms',
                    'No outsiders allowed after 10 PM',
                    'Maintain silence in common areas',
                    'Keep your room and surroundings clean',
                  ],
                ),
              ),
              
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

  List<dynamic> _getCombinedAmenities() {
    final List<dynamic> combined = [];
    final prop = widget.property;

    // 1. Check 'amenities' field
    if (prop['amenities'] is List) {
      combined.addAll(prop['amenities']);
    }

    // 2. Check 'features' field
    if (prop['features'] is List) {
      for (var f in prop['features']) {
        if (!combined.contains(f)) combined.add(f);
      }
    }

    // 3. Check 'basicInfo.amenities' or similar
    if (prop['basicInfo'] is Map && prop['basicInfo']['amenities'] is List) {
      for (var a in prop['basicInfo']['amenities']) {
        if (!combined.contains(a)) combined.add(a);
      }
    }

    // 4. Check 'amenityCategories' (common in some parts of the app)
    if (prop['amenityCategories'] is Map) {
      final categories = prop['amenityCategories'] as Map;
      for (var list in categories.values) {
        if (list is List) {
          for (var item in list) {
            String label = '';
            if (item is Map) {
              label = item['label']?.toString() ?? '';
            } else {
              label = item.toString();
            }
            if (label.isNotEmpty && !combined.contains(label)) {
              combined.add(label);
            }
          }
        }
      }
    }

    return combined;
  }

  String _extractFloor(String roomNumber) {
    if (roomNumber.isEmpty) return 'Floor 1';
    final match = RegExp(r'[Ff](\d+)|(\d)').firstMatch(roomNumber);
    if (match != null) {
      return 'Floor ${match.group(1) ?? match.group(2)}';
    }
    return 'Floor 1';
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (title == 'Amenities')
              TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
