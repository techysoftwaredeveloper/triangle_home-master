import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:triangle_home/providers/property_provider.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/profile/profile_screen.dart';
import 'package:triangle_home/screens/search_screen.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/home/accommodation_types.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/home/state_tags.dart';
import 'package:triangle_home/widgets/home/enrollment_card.dart';
import 'package:triangle_home/widgets/home/hoster_registration_card.dart';
import 'package:triangle_home/widgets/home/nearby_accommodations.dart';
import 'package:triangle_home/widgets/home/highest_rated_section.dart';
import 'package:triangle_home/services/location_api_service.dart';
import 'package:triangle_home/services/isar_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PropertyService _propertyService = PropertyService();
  final LocationApiService _locationApi = LocationApiService();
  final IsarService _isarService = IsarService();

  List<String> _states = [];
  String _currentCity = '';
  String _detectedCity = '';

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _fetchCitiesFromFirestore();
    _getCurrentCityFromLocation();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await _isarService.getLocationPreference();
    if (prefs != null && mounted) {
      setState(() {
        _currentCity = prefs.lastSelectedCity ?? '';
        _detectedCity = prefs.lastDetectedCity ?? '';
      });
    }
  }

  Future<void> _fetchCitiesFromFirestore() async {
    // 1. CACHE-FIRST: Load from Isar
    final cachedCities = await _isarService.getCachedMajorCities();
    if (cachedCities.isNotEmpty && mounted) {
      setState(() => _states = cachedCities);
    }

    try {
      // 2. BACKGROUND SYNC: Fetch fresh data
      final cities = await _locationApi.getMajorCities();
      if (!mounted) return;

      if (cities.isNotEmpty) {
        setState(() => _states = cities);
        // Update cache
        await _isarService.saveMajorCities(cities);
      } else if (_states.isEmpty) {
        // Ultimate fallback
        setState(() => _states = ["Kozhikode", "Malappuram", "Kochi", "Bangalore", "Chennai", "Mumbai", "Hyderabad", "Delhi"]);
      }
    } catch (e) {
      debugPrint('❌ Error fetching cities: $e');
    }
  }

  Future<void> _getCurrentCityFromLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      // Guide: Do NOT request permission on startup.
      // Only proceed if already granted.

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          if (mounted) {
            setState(() {
              _detectedCity = place.locality?.trim() ?? '';
              // If no city selected yet, use detected
              if (_currentCity.isEmpty) _currentCity = _detectedCity;
            });
            _isarService.saveLocationPreference(selected: _currentCity, detected: _detectedCity);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
    }
  }

  void _handleCitySelected(String city) {
    if (city == 'near_me_trigger') {
      _handleNearMeSelected();
    } else {
      setState(() => _currentCity = city);
      _isarService.saveLocationPreference(selected: city, detected: _detectedCity);
      ref.invalidate(paginatedPropertiesProvider);
    }
  }

  Future<void> _handleNearMeSelected() async {
    setState(() => _currentCity = 'Detecting...');
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions denied';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String? detectedCity = place.locality?.trim();
        final String? detectedLocality = place.subLocality?.trim();

        if (mounted) {
          setState(() {
            _detectedCity = detectedCity ?? '';
            _currentCity = detectedCity ?? 'Unknown';
          });

          _isarService.saveLocationPreference(selected: _currentCity, detected: _detectedCity);
          ref.invalidate(paginatedPropertiesProvider);

          Fluttertoast.showToast(
            msg: "Showing properties near ${detectedLocality ?? detectedCity ?? 'you'}",
            backgroundColor: AppTheme.primaryColor,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint('Near Me Error: $e');
      if (mounted) {
        setState(() => _currentCity = _detectedCity.isNotEmpty ? _detectedCity : 'Global');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _navigateToProfileOrLogin(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(isStudent: true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesState = ref.watch(paginatedPropertiesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchCitiesFromFirestore();
          ref.invalidate(paginatedPropertiesProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: false,
              floating: true,
              backgroundColor: AppTheme.primaryColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: () => _navigateToProfileOrLogin(context),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/Logo.svg',
                                    height: 24,
                                    width: 24,
                                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'TRIANGLE HOMES',
                                    style: TextStyle(color: Colors.white, fontFamily: 'outfit', fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                            child: const Row(
                              children: [
                                Expanded(child: Text('Search Area/City/College', style: TextStyle(color: Colors.grey, fontSize: 13))),
                                Icon(Icons.search, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: 64,
                child: Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: StateTags(
                    states: _states,
                    selectedState: _currentCity,
                    currentLocation: _detectedCity,
                    onStateSelected: _handleCitySelected,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AccommodationTypes(),
                  HighestRatedSection(
                    title: 'Highest Rated College Hostels of 2025',
                    items: _mockInstitutions,
                    onItemTap: (item) {},
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: propertiesState.when(
                      data: (accommodations) => NearbyAccommodations(
                        accommodations: accommodations,
                        selectedCity: 'near me',
                        customTitle: 'PG Accommodation Near Yenepoya University',
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text('Error: ${error.toString()}')),
                    ),
                  ),
                  HighestRatedSection(
                    title: 'Highest Rated Apartments of 2025',
                    items: _mockApartments,
                    onItemTap: (item) {},
                  ),
                  HighestRatedSection(
                    title: 'Highest Rated PGs of 2025',
                    items: _mockPGs,
                    onItemTap: (item) {},
                  ),
                  const EnrollmentCard(),
                  const HosterRegistrationCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 0),
    );
  }

  final List<Map<String, dynamic>> _mockInstitutions = [
    {'name': 'Yenepoya University', 'location': 'Mangaluru, Karnataka', 'logo': 'https://www.yenepoya.edu.in/images/logo.png'},
    {'name': 'Madras Christian College', 'location': 'Chennai, Tamil Nadu', 'logo': 'https://mcc.edu.in/wp-content/uploads/2020/07/mcc-logo.png'},
  ];

  final List<Map<String, dynamic>> _mockApartments = [
    {'name': 'Prestige Apartments', 'location': 'Bangalore, Karnataka', 'logo': 'https://www.prestigeconstructions.com/images/logo.png'},
    {'name': 'Brigade Gateway', 'location': 'Bangalore, Karnataka', 'logo': 'https://www.brigadegroup.com/images/logo.png'},
  ];

  final List<Map<String, dynamic>> _mockPGs = [
    {'name': 'Zolo Stay PGs', 'location': 'Chennai, Tamil Nadu', 'logo': 'https://www.zolostays.com/images/logo.png'},
    {'name': 'Stanza Living', 'location': 'Kochi, Kerala', 'logo': 'https://www.stanzaliving.com/images/logo.png'},
  ];
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyHeaderDelegate({required this.height, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
