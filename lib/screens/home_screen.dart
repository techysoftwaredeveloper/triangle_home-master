import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/widgets/home/highest_rated_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PropertyService _propertyService = PropertyService();

  List<String> _states = [];
  String _currentCity = '';
  String _detectedCity = '';

  @override
  void initState() {
    super.initState();
    _fetchCitiesFromFirestore();
    _getCurrentCityFromLocation();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedPropertiesProvider.notifier).fetchNextBatch();
    }
  }

  Future<void> _fetchCitiesFromFirestore() async {
    try {
      final List<String> cities = await _propertyService.getCities();

      if (!mounted) return;
      setState(() {
        _states = cities;
      });
    } catch (e) {
      debugPrint('❌ Error fetching cities: $e');
      if (mounted && e.toString().contains('permission-denied')) {
        _showAppCheckErrorDialog();
      }
    }
  }

  void _showAppCheckErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text(
          'This device is not authorized to access Triangle Home data. '
          'During development, your debug secret must be registered in the Firebase Console under App Check settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentCityFromLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

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
          String detectedCity = place.locality?.trim() ?? '';

          if (detectedCity.isNotEmpty) {
            setState(() {
              _detectedCity = detectedCity;
              _currentCity = detectedCity;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching location or city: $e');
    }
  }

  void _handleCitySelected(String city) {
    setState(() {
      _currentCity = city;
    });
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
    final propertiesState = ref.watch(paginatedPropertiesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          // Hard Reload logic to enter Hoster Page
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Check if user is hoster or allow shortcut entry
            final hosterDoc = await FirebaseFirestore.instance.collection('hoster').doc(user.uid).get();

            if (mounted) {
              if (hosterDoc.exists) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HosterDashboardScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Register as a hoster to access the dashboard.')),
                );
              }
            }
          } else {
            if (mounted) {
              _navigateToProfileOrLogin(context);
            }
          }
        },
        displacement: 100, // Deep swipe
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StateTags(
              states: _states,
              selectedState: _currentCity,
              currentLocation: _detectedCity,
              onStateSelected: _handleCitySelected,
            ),
            const AccommodationTypes(),

            // Highest Rated Sections
            HighestRatedSection(
              title: 'Highest Rated College Hostels of 2025',
              items: _mockInstitutions,
              onItemTap: (item) {},
            ),

            const SizedBox(height: 10),
            propertiesState.when(
              data:
                  (accommodations) => NearbyAccommodations(
                    accommodations: accommodations,
                    selectedCity: 'near me',
                    customTitle: 'PG Accommodation Near Yenepoya University',
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) =>
                      Center(child: Text('Error: ${error.toString()}')),
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

            const SizedBox(height: 10),
            const EnrollmentCard(),
            const HosterRegistrationCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 0),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(150),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
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
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Search for Area/City/College',
                            style: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'outfit',
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(Icons.search, color: Colors.black54),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _mockInstitutions = [
    {
      'name': 'Yenepoya University',
      'location': 'Mangaluru, Karnataka',
      'logo': 'https://www.yenepoya.edu.in/images/logo.png',
    },
    {
      'name': 'Madras Christian College',
      'location': 'Chennai, Tamil Nadu',
      'logo': 'https://mcc.edu.in/wp-content/uploads/2020/07/mcc-logo.png',
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
