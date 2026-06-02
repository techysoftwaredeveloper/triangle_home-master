import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/list_property/intro_screen.dart';
import 'package:triangle_home/screens/list_property/host_profile_step.dart';
import 'package:triangle_home/screens/list_property/host_verification_step.dart';
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
import 'package:triangle_home/services/firebase_service.dart';
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

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final hosterInfo = (userData['info'] as Map?)?.cast<String, dynamic>() ?? {};

        if (_propertyData['hostProfile'] == null) {
          _propertyData['hostProfile'] = {
            'name': hosterInfo['name'] ?? '',
            'email': hosterInfo['email'] ?? '',
            'phone': hosterInfo['phone'] ?? user.phoneNumber?.replaceFirst('+91', '') ?? '',
            'hostType': hosterInfo['hostType'] ?? 'Property Owner',
          };
        }
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
    
    final draft = {
      ..._propertyData,
      'last_step': _currentPage,
    };
    await _isarService.savePropertyDraft(user.uid, jsonEncode(draft));
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _saveDraft(); // Auto-save on page change to capture progress
  }

  void _nextPage(Map<String, dynamic> data) {
    setState(() {
      _propertyData.addAll(data);
      if (_currentPage < 9) {
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
      
      // Real-time URLs are already uploaded in previous steps
      final List<String> imageUrls = (_propertyData['image_urls'] as List?)?.cast<String>() ?? [];
      final Map<String, dynamic>? verification = _propertyData['verification'];
      final Map<String, dynamic>? documents = _propertyData['documents'];

      final Map<String, dynamic> finalData = {
        'hoster_id': user.uid,
        'status': 'pending',
        'images': imageUrls,
        'image_urls': imageUrls, // Compatibility
        'verification': verification,
        'documents': documents,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Map details for compatibility
      if (_propertyData['propertyBasics'] != null) {
        final basics = _propertyData['propertyBasics'] as Map<String, dynamic>;
        finalData['basicInfo'] = basics;
        finalData['name'] = basics['name'];
        finalData['propertyType'] = basics['type'];
      }

      if (_propertyData['location'] != null) {
        final loc = _propertyData['location'] as Map<String, dynamic>;
        finalData['location'] = '${loc['locality']}, ${loc['city']}';
        finalData['city'] = loc['city'];
        finalData['locality'] = loc['locality'];
        finalData['pincode'] = loc['pincode'];
      }

      if (_propertyData['pricing'] != null) {
        final pricing = _propertyData['pricing'] as Map<String, dynamic>;
        finalData['monthlyRent'] = pricing['singleRent'];
        finalData['securityDeposit'] = pricing['deposit'];
        finalData['pricing'] = pricing;
      }

      if (_propertyData['amenities'] != null) {
        finalData['amenities'] = _propertyData['amenities'];
      }

      if (_propertyData['details'] != null) {
        finalData['rooms'] = _propertyData['details']['totalRooms'];
        finalData['occupancy'] = 0; // Default
        finalData['details'] = _propertyData['details'];
      }

      // Add Hoster Info for Admin convenience
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userData.exists) {
        final info = userData.data()?['info'] as Map? ?? {};
        finalData['hosterName'] = info['name'] ?? 'Unknown';
        finalData['hosterPhone'] = info['phone'] ?? user.phoneNumber ?? 'N/A';
      }

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('properties').add(finalData);

      // Flatten and map based on how individual steps save data
      
      // Basic Info
      if (_propertyData['propertyBasics'] != null) {
        final basics = _propertyData['propertyBasics'] as Map<String, dynamic>;
        finalData['basicInfo'] = basics;
        finalData['name'] = basics['name'];
        finalData['type'] = basics['type'];
        // For search compatibility
        finalData['propertyType'] = basics['type'];
      }

      // Location
      if (_propertyData['location'] != null) {
        final loc = _propertyData['location'] as Map<String, dynamic>;
        finalData['address'] = loc['address'];
        finalData['city'] = loc['city'];
        finalData['locality'] = loc['locality'];
        finalData['pincode'] = loc['pincode'];
      }

      // Pricing
      if (_propertyData['pricing'] != null) {
        final pricing = _propertyData['pricing'] as Map<String, dynamic>;
        finalData['pricing'] = pricing;
        // Use single room rent as primary rent for search/filtering
        finalData['monthlyRent'] = pricing['singleRent'];
      }

      // Amenities
      if (_propertyData['amenities'] != null) {
        finalData['features'] = _propertyData['amenities'];
      }

      // Details
      if (_propertyData['details'] != null) {
        finalData['details'] = _propertyData['details'];
      }

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('properties').add(finalData);

      // 4. Clear local draft
      await _isarService.clearPropertyDraft(user.uid);

      if (mounted) setState(() => _isSubmitted = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
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
        onAddAnother: () => setState(() {
          _isSubmitted = false;
          _currentPage = 0;
          _propertyData = {};
          // Clear draft from Isar when starting fresh
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDarkColor, size: 20),
          onPressed: _previousPage,
        ),
        title: Text(
          _currentPage == 9 ? 'Review & Submit' : 'List Your Property',
          style: const TextStyle(color: AppTheme.textDarkColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
      ),
      body: Column(
        children: [
          if (_currentPage < 9) ProgressBar(currentStep: _currentPage, totalSteps: 9),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: [
                HostProfileStep(onContinue: _nextPage, initialData: _propertyData),
                HostVerificationStep(onContinue: _nextPage, initialData: _propertyData),
                PropertyBasicsStep(onContinue: _nextPage, initialData: _propertyData),
                LocationStep(onContinue: _nextPage, initialData: _propertyData),
                PropertyDetailsStep(onContinue: _nextPage, initialData: _propertyData),
                AmenitiesStep(onContinue: _nextPage, initialData: _propertyData),
                PhotosStep(onContinue: _nextPage, initialData: _propertyData),
                PricingStep(onContinue: _nextPage, initialData: _propertyData),
                DocumentsStep(onContinue: _nextPage, initialData: _propertyData),
                      ReviewSubmitStep(
                        propertyData: _propertyData,
                        onSubmit: _finalSubmit,
                        isSubmitting: _isSubmitting,
                        onEdit: (step) => _pageController.animateToPage(
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
