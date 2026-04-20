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
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/home/accommodation_types.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/home/state_tags.dart';
import 'package:triangle_home/widgets/home/enrollment_card.dart';
import 'package:triangle_home/widgets/home/hoster_registration_card.dart';
import 'package:triangle_home/widgets/home/nearby_accommodations.dart';
import 'package:triangle_home/widgets/home/top_hostels.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
      final snapshot =
          await FirebaseFirestore.instance.collection('cities').get();
      
      debugPrint('📍 Found ${snapshot.docs.length} cities in Firestore');
      if (snapshot.docs.isNotEmpty) {
        debugPrint('📍 Available cities: ${snapshot.docs.map((d) => d['name']).join(', ')}');
      } else {
        debugPrint('⚠️ No cities found in Firestore! Please run uploadCitiesToFirestore()');
      }
      
      final List<String> cities =
          snapshot.docs.map((doc) => doc['name'].toString()).toList();
      setState(() {
        _states = cities;
      });
    } catch (e) {
      debugPrint('❌ Error fetching cities: $e');
    }
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

          if (detectedCity.isEmpty) {
            debugPrint('Detected city is empty');
            return;
          }

          final snapshot =
              await FirebaseFirestore.instance.collection('cities').get();

          // Find matching city (case-insensitive)
          String? matchedCity;
          for (final doc in snapshot.docs) {
            final cityName = doc['name'].toString();
            if (cityName.toLowerCase() == detectedCity.toLowerCase()) {
              matchedCity = cityName;
              break;
            }
          }

          if (matchedCity != null) {
            setState(() {
              _detectedCity = matchedCity!;
              _currentCity = _detectedCity;
            });

            _fetchAreasByCity(_detectedCity);
          } else {
            debugPrint(
              'City "$detectedCity" not found in Firestore. Available cities: ${snapshot.docs.map((d) => d['name']).join(', ')}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching location or city: $e');
    }
  }

  Future<void> _fetchAreasByCity(String city) async {
    try {
      // First, find the document by city name (case-insensitive)
      final snapshot =
          await FirebaseFirestore.instance.collection('cities').get();

      String? docId;
      for (final doc in snapshot.docs) {
        final cityName = doc['name'].toString();
        if (cityName.toLowerCase() == city.toLowerCase()) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('cities')
                .doc(docId)
                .get();

        if (doc.exists) {
          setState(() {
            // _allLocalities = areas;
            // _selectedLocalities = areas.take(2).toList();
          });
        } else {
          debugPrint('City document "$docId" not found.');
        }
      } else {
        debugPrint('City "$city" not found in Firestore.');
      }
    } catch (e) {
      debugPrint('Error fetching areas: $e');
    }
  }

  void _handleCitySelected(String city) {
    setState(() {
      _currentCity = city;
    });
    _fetchAreasByCity(city);
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
      body: SingleChildScrollView(
        controller: _scrollController,
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
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirebaseService().getTopHostels(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return TopHostels(hostels: snapshot.data!);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 10),
            propertiesState.when(
              data:
                  (accommodations) => NearbyAccommodations(
                    accommodations: accommodations,
                    selectedCity: _currentCity,
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) =>
                      Center(child: Text('Error: ${error.toString()}')),
            ),
            const SizedBox(height: 10),
            const EnrollmentCard(),
            const HosterRegistrationCard(),
            const SizedBox(height: 20),
          ],
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
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                      ),
                      onPressed: () => _navigateToProfileOrLogin(context),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/Logosmall.svg',
                            height: 15,
                            width: 15,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'TRIANGLE HOMES',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 4,
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
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: IgnorePointer(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                fontFamily: 'outfit',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search for Area/City/College',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontFamily: 'outfit',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SvgPicture.asset(
                            'assets/images/searchicon.svg',
                            height: 20,
                            width: 20,
                            colorFilter: ColorFilter.mode(
                              Colors.grey[600]!,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
