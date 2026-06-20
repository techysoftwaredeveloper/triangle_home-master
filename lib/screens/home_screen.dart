import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:triangle_home/providers/location_provider.dart';
import 'package:triangle_home/providers/property_provider.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/screens/hoster/partner_onboarding_screen.dart';
import 'package:triangle_home/screens/profile/profile_screen.dart';
import 'package:triangle_home/screens/search_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/home/accommodation_types.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/home/state_tags.dart';
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
  final LocationApiService _locationApi = LocationApiService();
  final IsarService _isarService = IsarService();

  List<String> _states = [];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _fetchCitiesFromFirestore();
    _getCurrentCityFromLocation();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['role'] == 'hoster') {
          // If any hoster accidentally on Home, redirect to Dashboard/Onboarding
          if (data['status'] == 'approved' || data['onboardingStatus'] == 'submitted') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HosterDashboardScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => PartnerOnboardingScreen()),
              (route) => false,
            );
          }
        }
      }
    }
  }

  Future<void> _fetchCitiesFromFirestore() async {
    // 1. CACHE-FIRST: Load from Isar
    final cachedCities = await _isarService.getCachedMajorCities();
    if (cachedCities.isNotEmpty && mounted) {
      setState(() => _states = cachedCities);
    }

    try {
      // 2. Try REST API first
      final cities = await _locationApi.getMajorCities();
      if (!mounted) return;

      if (cities.isNotEmpty) {
        setState(() => _states = cities);
        await _isarService.saveMajorCities(cities);
        return;
      }
    } catch (e) {
      debugPrint('❌ REST API cities error: $e');
    }

    try {
      // 3. FIRESTORE FALLBACK: read cities collection doc IDs
      final snapshot = await FirebaseFirestore.instance
          .collection('cities')
          .where('active', isEqualTo: true)
          .get();
      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final firestoreCities = snapshot.docs
            .map((d) => d.id)
            .where((id) => id.isNotEmpty)
            .toList()
          ..sort();
        setState(() => _states = firestoreCities);
        await _isarService.saveMajorCities(firestoreCities);
        return;
      }
    } catch (e) {
      debugPrint('❌ Firestore cities error: $e');
    }

    // 4. Ultimate hardcoded fallback (with Kottayam)
    if (_states.isEmpty && mounted) {
      setState(
        () => _states = [
          "Bangalore",
          "Chennai",
          "Delhi",
          "Hyderabad",
          "Kochi",
          "Kottayam",
          "Kozhikode",
          "Malappuram",
          "Mumbai",
        ],
      );
    }
  }

  Future<void> _getCurrentCityFromLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          final detected = place.locality?.trim() ?? '';
          final subLocality = place.subLocality?.trim() ?? '';
          
          if (mounted) {
            final locNotifier = ref.read(locationProvider.notifier);
            locNotifier.updateDetectedCity(detected);
            locNotifier.updateDetectedLocality(subLocality);
            
            final currentSelected = ref.read(locationProvider).selectedCity;
            if (currentSelected.isEmpty) {
              locNotifier.updateSelectedCity(detected);
            }
          }

          if (detected.isNotEmpty) {
            _locationApi.addLocation(city: detected, locality: subLocality);
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
      ref.read(locationProvider.notifier).updateSelectedCity(city);
    }
  }

  Future<void> _handleNearMeSelected() async {
    ref.read(locationProvider.notifier).setDetecting(true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions denied';
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String? detectedCity = place.locality?.trim();
        final String? detectedLocality = place.subLocality?.trim();

        if (mounted) {
          final locNotifier = ref.read(locationProvider.notifier);
          locNotifier.updateDetectedCity(detectedCity ?? '');
          locNotifier.updateDetectedLocality(detectedLocality ?? '');
          locNotifier.updateSelectedCity(detectedCity ?? 'Unknown');
          locNotifier.setDetecting(false);

          Fluttertoast.showToast(
            msg:
                "Showing properties near ${detectedLocality ?? detectedCity ?? 'you'}",
            backgroundColor: AppTheme.primaryColor,
            textColor: Colors.white,
          );
        }

        if (detectedCity != null && detectedCity.isNotEmpty) {
          _locationApi.addLocation(city: detectedCity, locality: detectedLocality ?? '');
        }
      }
    } catch (e) {
      debugPrint('Near Me Error: $e');
      if (mounted) {
        ref.read(locationProvider.notifier).setDetecting(false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _navigateToProfileOrLogin(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(isStudent: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final currentCity = locationState.selectedCity;
    final propertiesState = ref.watch(paginatedPropertiesProvider(currentCity));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchCitiesFromFirestore();
          ref.invalidate(paginatedPropertiesProvider(currentCity));
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed:
                                  () => _navigateToProfileOrLogin(context),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/Logo_update.svg',
                                    height: 24,
                                    width: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'TRIANGLE HOMES',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'outfit',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SearchScreen(),
                                ),
                              ),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Search Area/City/College',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
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
                    selectedState: locationState.isDetecting ? 'Detecting...' : currentCity,
                    currentLocation: locationState.detectedCity,
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
                  _buildRecommendationsSection(),
                  HighestRatedSection(
                    title: 'Highest Rated College Hostels of 2025',
                    items: _mockInstitutions,
                    onItemTap: (item) {},
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: propertiesState.when(
                      data: (accommodations) {
                        if (accommodations.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 32, horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.home_work_outlined,
                                    size: 48,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  currentCity.isEmpty
                                      ? 'No properties available yet'
                                      : 'No properties in $currentCity yet',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textLightColor),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        return NearbyAccommodations(
                          accommodations: accommodations,
                          selectedCity: currentCity,
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryColor)),
                      ),
                      error: (error, stack) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Failed to load properties. Pull to refresh.',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  HighestRatedSection(
                    title: 'Highest Rated College Apartments of 2025',
                    items: _mockApartments,
                    onItemTap: (item) {},
                  ),
                  HighestRatedSection(
                    title: 'Highest Rated College Paying Guest Accommodation of 2025',
                    items: _mockPGs,
                    onItemTap: (item) {},
                  ),
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

  Widget _buildRecommendationsSection() {
    final recommendationsAsync = ref.watch(recommendedPropertiesProvider);

    return recommendationsAsync.when(
      data: (properties) {
        if (properties.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended for You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final property = properties[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    child: NearbyAccommodations(
                      accommodations: [property],
                      selectedCity: property['city'] ?? '',
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  final List<Map<String, dynamic>> _mockInstitutions = [
    {
      'name': 'Yenepoya University',
      'location': 'Mangaluru, Karnataka',
      'logo': 'https://www.yenepoya.edu.in/images/logo.png',
    },
    {
      'name': 'IIT Delhi',
      'location': 'New Delhi',
      'logo': 'https://home.iitd.ac.in/images/logo.png',
    },
    {
      'name': 'IIM Ahmedabad',
      'location': 'Ahmedabad, Gujarat',
      'logo': 'https://www.iima.ac.in/sites/default/files/iima-logo.png',
    },
    {
      'name': 'Madras Christian College',
      'location': 'Chennai, Tamil Nadu',
      'logo': 'https://mcc.edu.in/wp-content/uploads/2020/07/mcc-logo.png',
    },
    {
      'name': 'SRM University',
      'location': 'Chennai, Tamil Nadu',
      'logo': 'https://www.srmist.edu.in/wp-content/uploads/2021/01/logo.png',
    },
  ];

  final List<Map<String, dynamic>> _mockApartments = [
    {
      'name': 'Prestige Apartments',
      'location': 'Bangalore, Karnataka',
      'logo': 'https://www.prestigeconstructions.com/images/logo.png',
    },
    {
      'name': 'Brigade Gateway',
      'location': 'Bangalore, Karnataka',
      'logo': 'https://www.brigadegroup.com/images/logo.png',
    },
  ];

  final List<Map<String, dynamic>> _mockPGs = [
    {
      'name': 'Zolo Stay PGs',
      'location': 'Chennai, Tamil Nadu',
      'logo': 'https://www.zolostays.com/images/logo.png',
    },
    {
      'name': 'Stanza Living',
      'location': 'Kochi, Kerala',
      'logo': 'https://www.stanzaliving.com/images/logo.png',
    },
  ];
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyHeaderDelegate({required this.height, required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
