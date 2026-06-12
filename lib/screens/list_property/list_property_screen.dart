import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/screens/list_property/host_profile_step.dart';
import 'package:triangle_home/screens/list_property/property_basics_step.dart';
import 'package:triangle_home/screens/list_property/location_step.dart';
import 'package:triangle_home/screens/list_property/property_details_step.dart';
import 'package:triangle_home/screens/list_property/amenities_step.dart';
import 'package:triangle_home/screens/list_property/photos_step.dart';
import 'package:triangle_home/screens/list_property/pricing_step.dart';
import 'package:triangle_home/screens/list_property/documents_step.dart';
import 'package:triangle_home/screens/list_property/review_submit_step.dart';
import 'package:triangle_home/screens/list_property/success_step.dart';
import '../hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/progress_bar.dart';

class ListPropertyScreen extends StatefulWidget {
  const ListPropertyScreen({super.key});

  @override
  State<ListPropertyScreen> createState() => _ListPropertyScreenState();
}

class _ListPropertyScreenState extends State<ListPropertyScreen> {
  late PageController _pageController;
  final IsarService _isarService = IsarService();
  int _currentPage = 0;
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  Map<String, dynamic> _propertyData = {};
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0); // Temporary init
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final draftJson = await _isarService.getPropertyDraft(user.uid);
    if (draftJson != null) {
      _propertyData = jsonDecode(draftJson);
      // Restore the exact page the user was on
      if (_propertyData.containsKey('last_step')) {
        _currentPage = _propertyData['last_step'];
      }
    }

    final String? existingPropertyId = _propertyData['propertyId'];
    if (existingPropertyId == null) {
      final docRef = FirebaseFirestore.instance.collection('properties').doc();
      _propertyData['propertyId'] = docRef.id;
      try {
        await docRef.set({
          'status': 'draft',
          'hoster_id': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error creating initial Firestore draft: $e');
      }
    } else {
      // Ensure the Firestore draft document actually exists (in case a previous create failed under old rules)
      try {
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(existingPropertyId)
            .set({
              'status': 'draft',
              'hoster_id': user.uid,
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error healing existing Firestore draft: $e');
      }
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final hosterInfo =
            (userData['info'] as Map?)?.cast<String, dynamic>() ?? {};

        final bool isVerified =
            (userData['role'] == 'hoster') ||
            (userData['onboardingStatus'] == 'approved') ||
            (userData['accountStatus'] == 'active') ||
            (userData['status'] == 'approved') ||
            (userData['permissions'] is Map &&
                userData['permissions']['status'] == 'approved');

        if (_propertyData['hostProfile'] == null) {
          _propertyData['hostProfile'] = {
            'name': hosterInfo['name'] ?? '',
            'email': hosterInfo['email'] ?? '',
            'phone':
                hosterInfo['phone'] ??
                user.phoneNumber?.replaceFirst('+91', '') ??
                '',
            'hostType': hosterInfo['hostType'] ?? 'Property Owner',
          };
        }
        _propertyData['isHostVerified'] = isVerified;
      }
    } catch (e) {
      debugPrint('Error loading hoster info: $e');
    }

    if (mounted) {
      // Re-initialize controller with the correct starting page
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentPage);
      setState(() => _isInitialLoading = false);
    }
  }

  void _saveDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final draft = {..._propertyData, 'last_step': _currentPage};
    await _isarService.savePropertyDraft(user.uid, jsonEncode(draft));
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _saveDraft(); // Auto-save on page change to capture progress
  }

  void _nextPage(Map<String, dynamic> data) {
    setState(() {
      _propertyData.addAll(data);
      if (_currentPage < 8) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HosterDashboardScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _finalSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;

      final List<String> imageUrls =
          (_propertyData['image_urls'] as List?)?.cast<String>() ?? [];
      final Map<String, dynamic>? verification = _propertyData['verification'];
      final Map<String, dynamic>? documents = _propertyData['documents'];
      final Map<String, dynamic>? hostProfile = _propertyData['hostProfile'];

      final Map<String, dynamic> finalData = {
        'hoster_id': user.uid,
        'status': 'approved', // Changed to approved for visibility
        'images': imageUrls,
        'image_urls': imageUrls,
        'verification': verification,
        'documents': documents,
        'hostProfile': hostProfile,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Map Property Basics
      if (_propertyData['propertyBasics'] != null) {
        final basics = _propertyData['propertyBasics'] as Map<String, dynamic>;
        finalData['basicInfo'] = basics;
        finalData['name'] = basics['name'];
        finalData['type'] = basics['type'];
        finalData['propertyType'] = basics['type'];
      }

      // 2. Map Location
      if (_propertyData['location'] != null) {
        final loc = _propertyData['location'] as Map<String, dynamic>;
        final String cityName = (loc['city'] ?? '').toString().trim();
        final String localityName = (loc['locality'] ?? '').toString().trim();

        finalData['location'] = '$localityName, $cityName';
        finalData['address'] = loc['address'];
        finalData['city'] = cityName;
        finalData['locality'] = localityName;
        finalData['pincode'] = loc['pincode'];
        finalData['city_normalized'] = cityName.toLowerCase();
        finalData['locality_normalized'] = localityName.toLowerCase();

        // Add Search Terms
        final String title = (finalData['name'] ?? '').toString().toLowerCase();
        finalData['search_terms'] = {
          ...title.split(' '),
          ...cityName.toLowerCase().split(' '),
          finalData['type']?.toString().toLowerCase() ?? '',
        }.where((t) => t.length > 2).toList();
      }

      // 3. Map Pricing
      if (_propertyData['pricing'] != null) {
        final pricing = _propertyData['pricing'] as Map<String, dynamic>;
        finalData['pricing'] = pricing;
        finalData['monthlyRent'] = pricing['singleRent'];
        finalData['securityDeposit'] = pricing['deposit'];
      }

      // 4. Map Amenities
      if (_propertyData['amenities'] != null) {
        finalData['amenities'] = _propertyData['amenities'];
        finalData['features'] = _propertyData['amenities'];
      }

      // 5. Map Property Details (CRITICAL FIX)
      if (_propertyData['propertyDetails'] != null) {
        final details = _propertyData['propertyDetails'] as Map<String, dynamic>;
        finalData['propertyDetails'] = details;
        finalData['gender'] = details['gender'];
        finalData['description'] = details['description'];
        finalData['totalCapacity'] = details['totalCapacity'];
        finalData['floorsCount'] = details['floorsCount'] ?? 1;
        finalData['rooms'] = (details['singleRooms'] ?? 0) +
            (details['doubleRooms'] ?? 0) +
            (details['tripleRooms'] ?? 0);
      }

      // Add Hoster Info + persist verification status
      final userData =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userData.exists) {
        final d = userData.data()!;
        final info = d['info'] as Map? ?? {};
        finalData['hosterName'] = info['name'] ?? 'Unknown';
        finalData['hosterPhone'] = info['phone'] ?? user.phoneNumber ?? 'N/A';
        // Persist isHostVerified so admin listings show correct status
        finalData['isHostVerified'] =
            (d['onboardingStatus'] == 'approved') ||
            (d['accountStatus'] == 'active') ||
            (d['status'] == 'approved') ||
            (d['permissions'] is Map &&
                d['permissions']['status'] == 'approved') ||
            (d['isVerified'] == true);
      }

      // Save to Firestore (ONLY ONCE)
      final String propertyId = _propertyData['propertyId']!;
      final docRef = FirebaseFirestore.instance.collection('properties').doc(propertyId);
      await docRef.set(finalData, SetOptions(merge: true));

      // 3. Initialize Property Stats
      try {
        await FirebaseFirestore.instance.collection('propertyStats').doc(propertyId).set({
          'propertyId': propertyId,
          'totalBeds': finalData['rooms'] != null ? (finalData['rooms'] * 2) : 0, // Heuristic default
          'availableBeds': finalData['rooms'] != null ? (finalData['rooms'] * 2) : 0,
          'occupiedBeds': 0,
          'availableRooms': finalData['rooms'] ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error initializing property stats: $e');
      }

      // 4. Create Notification for Admins
      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          'user_id': 'admin', // Broadcast type
          'title': 'New Property Request',
          'body': 'A new listing "${finalData['name']}" is pending approval.',
          'type': 'new_property_request',
          'data': {'propertyId': docRef.id},
          'is_read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error notifying admins: $e');
      }

      // 5. Clear local draft
      await _isarService.clearPropertyDraft(user.uid);

      if (mounted) setState(() => _isSubmitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isSubmitted) {
      return ListPropertySuccessScreen(
        onGoToDashboard: () {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HosterDashboardScreen()),
              (route) => false,
            );
          }
        },
        onAddAnother:
            () => setState(() {
              _isSubmitted = false;
              _currentPage = 0;
              _propertyData = {};
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) _isarService.clearPropertyDraft(user.uid);
              _pageController.jumpToPage(0);
            }),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textDarkColor,
            size: 20,
          ),
          onPressed: _previousPage,
        ),
        title: Text(
          _currentPage == 8 ? 'Review & Submit' : 'List Your Property',
          style: const TextStyle(
            color: AppTheme.textDarkColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
      ),
      body: Column(
        children: [
          if (_currentPage < 8)
            ProgressBar(currentStep: _currentPage, totalSteps: 8),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: [
                PropertyBasicsStep(
                  onContinue: _nextPage,
                  initialData: _propertyData,
                ),
                LocationStep(onContinue: _nextPage, initialData: _propertyData),
                PropertyDetailsStep(
                  onContinue: _nextPage,
                  initialData: _propertyData,
                ),
                AmenitiesStep(
                  onContinue: _nextPage,
                  initialData: _propertyData,
                ),
                PhotosStep(onContinue: _nextPage, initialData: _propertyData),
                PricingStep(onContinue: _nextPage, initialData: _propertyData),
                DocumentsStep(
                  onContinue: _nextPage,
                  initialData: _propertyData,
                ),
                HostProfileStep(
                  onContinue: _nextPage,
                  initialData: _propertyData,
                ),
                ReviewSubmitStep(
                  propertyData: _propertyData,
                  onSubmit: _finalSubmit,
                  isSubmitting: _isSubmitting,
                  onEdit:
                      (step) => _pageController.animateToPage(
                        step,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
