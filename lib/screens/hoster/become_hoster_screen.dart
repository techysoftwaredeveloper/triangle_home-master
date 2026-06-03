import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_verification_center_screen.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class BecomeHosterScreen extends StatefulWidget {
  const BecomeHosterScreen({super.key});

  @override
  State<BecomeHosterScreen> createState() => _BecomeHosterScreenState();
}

class _BecomeHosterScreenState extends State<BecomeHosterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _businessNameController = TextEditingController();

  // State Variables
  String? _selectedGender;
  DateTime? _dob;
  String? _selectedState;
  String? _profileImageUrl;
  File? _newImageFile;

  String _selectedPropertyType = 'Hostel';
  bool _isTermsAccepted = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? _existingRequest;
  Map<String, dynamic>? _userBaseData;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  // Preferences
  List<String> _preferredTenants = [];
  String? _prefGender;

  final List<String> _propertyTypes = [
    'Hostel',
    'PG Accommodation',
    'Apartment',
    'Guest House',
  ];

  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _listenToStatusChanges();

    // Add auto-save listeners
    _nameController.addListener(_saveLocalDraft);
    _emailController.addListener(_saveLocalDraft);
    _address1Controller.addListener(_saveLocalDraft);
    _cityController.addListener(_saveLocalDraft);
    _pincodeController.addListener(_saveLocalDraft);
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _userSubscription?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  void _listenToStatusChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists && mounted) {
            final data = doc.data() as Map<String, dynamic>;
            setState(() {
              _userBaseData = data;
            });

            final perms = data['permissions'] as Map? ?? {};
            if (perms['role'] == 'hoster' && perms['status'] == 'approved') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HosterDashboardScreen()),
                (route) => false,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '🎉 Your hoster account has been approved! Welcome aboard.',
                  ),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        });

    _statusSubscription = FirebaseFirestore.instance
        .collection('hoster_requests')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists && mounted) {
            setState(() {
              _existingRequest = doc.data();
            });
          }
        });
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // 1. Check local draft
    final isar = IsarService();
    final draftJson = await isar.getAdminCache(
      'hoster_application_draft_${user.uid}',
    );
    if (draftJson != null) {
      final draft = jsonDecode(draftJson);
      _nameController.text = draft['name'] ?? '';
      _emailController.text = draft['email'] ?? '';
      _address1Controller.text = draft['address1'] ?? '';
      _cityController.text = draft['city'] ?? '';
      _pincodeController.text = draft['pincode'] ?? '';
      _selectedGender = draft['gender'];
      _selectedState = draft['state'];
      _selectedPropertyType = draft['propertyType'] ?? 'Hostel';
    }

    // 2. Fetch User Data
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (userDoc.exists) {
      _userBaseData = userDoc.data();
      final info = _userBaseData?['info'] as Map? ?? {};
      final prefs = _userBaseData?['host_preferences'] as Map? ?? {};

      if (_nameController.text.isEmpty)
        _nameController.text = info['name'] ?? '';
      if (_emailController.text.isEmpty)
        _emailController.text = info['email'] ?? user.email ?? '';
      _phoneController.text = info['phone'] ?? user.phoneNumber ?? '';
      if (_address1Controller.text.isEmpty)
        _address1Controller.text = info['addressLine1'] ?? '';
      _address2Controller.text = info['addressLine2'] ?? '';
      if (_cityController.text.isEmpty)
        _cityController.text = info['city'] ?? '';
      if (_pincodeController.text.isEmpty)
        _pincodeController.text = info['pincode'] ?? '';
      _selectedState ??= info['state'];
      _selectedGender ??= info['gender'];
      if (info['dob'] != null) _dob = (info['dob'] as Timestamp).toDate();
      _profileImageUrl = info['profileImage'];

      _preferredTenants = List<String>.from(prefs['tenantTypes'] ?? []);
      _prefGender = prefs['genderPreference'];
    }

    // 3. Fetch from hoster_requests
    final doc =
        await FirebaseFirestore.instance
            .collection('hoster_requests')
            .doc(user.uid)
            .get();

    if (!mounted) return;

    if (doc.exists) {
      setState(() {
        _existingRequest = doc.data();
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _saveLocalDraft() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final draft = {
      'name': _nameController.text,
      'email': _emailController.text,
      'address1': _address1Controller.text,
      'city': _cityController.text,
      'pincode': _pincodeController.text,
      'gender': _selectedGender,
      'state': _selectedState,
      'propertyType': _selectedPropertyType,
    };
    IsarService().saveAdminCache(
      'hoster_application_draft_${user.uid}',
      jsonEncode(draft),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _newImageFile = File(picked.path));
  }

  double _calculateCompletion() {
    int totalFields = 12;
    int filledFields = 0;

    if (_nameController.text.isNotEmpty) filledFields++;
    if (_selectedGender != null) filledFields++;
    if (_dob != null) filledFields++;
    if (_emailController.text.isNotEmpty) filledFields++;
    if (_phoneController.text.isNotEmpty) filledFields++;
    if (_address1Controller.text.isNotEmpty) filledFields++;
    if (_cityController.text.isNotEmpty) filledFields++;
    if (_selectedState != null) filledFields++;
    if (_pincodeController.text.isNotEmpty) filledFields++;
    if (_profileImageUrl != null || _newImageFile != null) filledFields++;
    if (_preferredTenants.isNotEmpty) filledFields++;
    if (_prefGender != null) filledFields++;

    return filledFields / totalFields;
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      String? imageUrl = _profileImageUrl;
      if (_newImageFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_images/${user.uid}.jpg',
        );
        await ref.putFile(_newImageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final submissionData = {
        'uid': user.uid,
        'info': {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'gender': _selectedGender,
          'dob': _dob != null ? Timestamp.fromDate(_dob!) : null,
          'addressLine1': _address1Controller.text.trim(),
          'addressLine2': _address2Controller.text.trim(),
          'city': _cityController.text.trim(),
          'state': _selectedState,
          'pincode': _pincodeController.text.trim(),
          'profileImage': imageUrl,
        },
        'business': {
          'businessName': _businessNameController.text.trim(),
          'propertyType': _selectedPropertyType,
        },
        'host_preferences': {
          'tenantTypes': _preferredTenants,
          'genderPreference': _prefGender,
        },
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewNote': '',
      };

      await FirebaseFirestore.instance
          .collection('hoster_requests')
          .doc(user.uid)
          .set(submissionData);

      // Update user document to reflect hoster intent/role and set to pending for admin approval
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'permissions': {
          'role': 'hoster',
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'info': submissionData['info'],
        'host_preferences': submissionData['host_preferences'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      final isar = IsarService();
      await isar.clearAdminCache('hoster_application_draft_${user.uid}');
      await isar.clearUserIntent();

      _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successColor,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Application Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your hoster application has been sent for review. We will verify your details and notify you soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textLightColor,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => ListPropertyScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Start Listing Property',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _reApply() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('hoster_requests')
        .doc(user.uid)
        .delete();

    setState(() {
      _existingRequest = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final status = _existingRequest?['status'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          status == 'pending'
              ? _buildPendingState()
              : status == 'rejected'
              ? _buildRejectedState()
              : _buildMainForm(),
        ],
      ),
    );
  }

  Widget _buildMainForm() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 160),
              sliver: SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusDashboard()
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                curve: Curves.easeOutQuad,
                              ),
                          const SizedBox(height: 32),
                          _buildPhotoSection()
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildBasicInfoSection()
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildContactSection()
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildAddressSection()
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildIdentitySection()
                              .animate()
                              .fadeIn(delay: 600.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildPreferencesSection()
                              .animate()
                              .fadeIn(delay: 700.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildTermsCheckbox()
                              .animate()
                              .fadeIn(delay: 800.ms)
                              .slideY(begin: 0.1, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.successColor,
      automaticallyImplyLeading: false,
      elevation: 0,
      collapsedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.successColor, Color(0xFF16A34A)],
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              top: 40,
              child: Opacity(
                opacity: 0.8,
                child: Image.network(
                  'https://img.freepik.com/free-vector/professional-services-concept-illustration_114360-12822.jpg?w=1080',
                  headers: const {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Referer': 'https://www.freepik.com/',
                  },
                  fit: BoxFit.contain,
                  width: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2, end: 0),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Partner with\nTriangle Homes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage properties & reach tenants',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const Spacer(),
                    const Center(
                      child: Text(
                        'Owner Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDashboard() {
    final completion = _calculateCompletion();
    final verif = _userBaseData?['verification'] as Map? ?? {};

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 64,
                    width: 64,
                    child: CircularProgressIndicator(
                      value: completion,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.successColor.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.successColor,
                      ),
                    ),
                  ),
                  Text(
                    '${(completion * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Completion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDarkColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Complete your profile to start hosting',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVerifIndicator(
                'Email',
                _userBaseData?['emailVerified'] == true ||
                    FirebaseAuth.instance.currentUser?.emailVerified == true,
              ),
              _buildVerifIndicator('Phone', true),
              _buildVerifIndicator(
                'Identity',
                verif['govIdVerified'] == true,
                isPending: verif['govIdStatus'] == 'pending',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifIndicator(
    String label,
    bool isDone, {
    bool isPending = false,
  }) {
    final color =
        isDone
            ? AppTheme.successColor
            : (isPending ? AppTheme.warningColor : Colors.grey[300]!);
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDone ? color.withValues(alpha: 0.1) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(
            isDone
                ? Icons.check_rounded
                : (isPending ? Icons.pending_rounded : Icons.circle_outlined),
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
            color: isDone ? color : AppTheme.textMutedColor,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Profile Photo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child:
                          _newImageFile != null
                              ? Image.file(_newImageFile!, fit: BoxFit.cover)
                              : (_profileImageUrl != null
                                  ? CachedNetworkImage(
                                    imageUrl: _profileImageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                  : Icon(
                                    Icons.person_rounded,
                                    size: 45,
                                    color: Colors.grey[300],
                                  )),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update your photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDarkColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'A clear photo builds trust with potential tenants.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 20),
          child: Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        _buildTextField('Full Name *', _nameController, Icons.person_rounded),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Gender *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkColor,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            Row(
              children:
                  ['Male', 'Female', 'Other']
                      .map(
                        (g) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedGender = g),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedGender == g
                                          ? AppTheme.successColor
                                          : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        _selectedGender == g
                                            ? AppTheme.successColor
                                            : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _selectedGender == g
                                              ? Colors.white
                                              : AppTheme.textLightColor,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildDateField(
          'Date of Birth *',
          _dob,
          (d) => setState(() => _dob = d),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 20),
          child: Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        _buildTextField(
          'Phone Number *',
          _phoneController,
          Icons.phone_android_rounded,
          isVerified: true,
          readOnly: true,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Email Address *',
          _emailController,
          Icons.email_rounded,
          isVerified: FirebaseAuth.instance.currentUser?.emailVerified ?? false,
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 20),
          child: Text(
            'Address Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        _buildTextField(
          'Address Line 1 *',
          _address1Controller,
          Icons.location_on_rounded,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Address Line 2 (Optional)',
          _address2Controller,
          Icons.location_on_rounded,
          isRequired: false,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'City *',
                _cityController,
                Icons.apartment_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                'State *',
                _indianStates,
                _selectedState,
                (v) => setState(() => _selectedState = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Pincode *',
          _pincodeController,
          Icons.pin_drop_rounded,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildIdentitySection() {
    final verif = _userBaseData?['verification'] as Map? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Identity Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkColor,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            TextButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HosterVerificationCenterScreen(),
                    ),
                  ),
              child: const Row(
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppTheme.successColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildIdentityTile(
          'Aadhaar Card',
          verif['govIdFrontUrl'] != null
              ? 'Documents Uploaded'
              : 'Not Uploaded',
          verif['govIdStatus'] == 'pending'
              ? 'In Review'
              : (verif['govIdVerified'] == true ? 'Verified' : 'Required'),
          verif['govIdVerified'] == true
              ? Colors.green
              : (verif['govIdStatus'] == 'pending'
                  ? Colors.orange
                  : Colors.grey),
          'https://cdn-icons-png.flaticon.com/512/11104/11104118.png',
        ),
        const SizedBox(height: 12),
        _buildIdentityTile(
          'PAN Card',
          verif['panFrontUrl'] != null ? 'Documents Uploaded' : 'Not Uploaded',
          verif['panVerified'] == true ? 'Verified' : 'Required',
          verif['panVerified'] == true ? Colors.green : Colors.grey,
          'https://cdn-icons-png.flaticon.com/512/10703/10703478.png',
        ),
      ],
    );
  }

  Widget _buildIdentityTile(
    String title,
    String subtitle,
    String status,
    Color color,
    String iconUrl,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HosterVerificationCenterScreen(),
                ),
              ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(iconUrl, width: 24, height: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkColor,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLightColor,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status == 'Verified'
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Host Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkColor,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Row(
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  Icon(
                    Icons.settings_rounded,
                    size: 14,
                    color: AppTheme.successColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPreferenceCard(
                'Tenants',
                ['Students', 'Pros', 'Families'],
                _preferredTenants,
                (v) => setState(() {
                  if (_preferredTenants.contains(v)) {
                    _preferredTenants.remove(v);
                  } else {
                    _preferredTenants.add(v);
                  }
                }),
                [
                  Icons.school_rounded,
                  Icons.work_rounded,
                  Icons.people_rounded,
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPreferenceCard(
                'Gender',
                ['Male', 'Female', 'Any'],
                _prefGender != null ? [_prefGender!] : [],
                (v) => setState(() => _prefGender = v),
                [
                  Icons.person_rounded,
                  Icons.person_pin_rounded,
                  Icons.people_alt_rounded,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferenceCard(
    String title,
    List<String> options,
    List<String> current,
    Function(String) onTap,
    List<IconData> icons,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLightColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(options.length, (i) {
              final isSelected = current.contains(options[i]);
              return InkWell(
                onTap: () => onTap(options[i]),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border:
                            isSelected
                                ? Border.all(
                                  color: AppTheme.successColor.withValues(
                                    alpha: 0.2,
                                  ),
                                )
                                : null,
                      ),
                      child: Icon(
                        icons[i],
                        size: 20,
                        color:
                            isSelected
                                ? AppTheme.successColor
                                : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      options[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected
                                ? AppTheme.successColor
                                : AppTheme.textLightColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
          value: _isTermsAccepted,
          onChanged: (v) => setState(() => _isTermsAccepted = v!),
          title: const Text(
            'I agree to the Terms & Conditions and Privacy Policy of Triangle Homes.',
            style: TextStyle(fontSize: 12, fontFamily: 'Outfit'),
          ),
          activeColor: AppTheme.successColor,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSubmitting)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              else
                const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              const SizedBox(width: 12),
              Text(
                _isSubmitting ? 'Submitting...' : 'Submit Application',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
      ).animate().slideY(
        begin: 1,
        end: 0,
        duration: 600.ms,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildPendingState() {
    return Column(
      children: [
        _buildSimpleHeader('Application Pending'),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_empty_rounded,
                      size: 64,
                      color: AppTheme.warningColor,
                    ),
                  ).animate().scale(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Application Under Review',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: AppTheme.textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your hoster application is under review. Our team will verify your details and get back to you within 48 hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLightColor,
                      fontFamily: 'Outfit',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildReviewInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedState() {
    final note = _existingRequest?['reviewNote'] as String? ?? '';
    return Column(
      children: [
        _buildSimpleHeader('Application Rejected'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Application Rejected',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unfortunately, your application was not approved at this time. Reason: ${note.isEmpty ? "Does not meet requirements." : note}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLightColor,
                    fontFamily: 'Outfit',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _reApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text(
                      'Re-Apply Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      color: AppTheme.successColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewInfoCard() {
    final info = _existingRequest?['info'] as Map? ?? {};
    final business = _existingRequest?['business'] as Map? ?? {};
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _summaryRow(Icons.person_outline, 'Name', info['name'] ?? ''),
              const Divider(height: 24),
              _summaryRow(
                Icons.business_outlined,
                'Type',
                business['propertyType'] ?? '',
              ),
              const Divider(height: 24),
              _summaryRow(
                Icons.phone_android_outlined,
                'Contact',
                info['phone'] ?? '',
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 400))
        .slideY(begin: 0.1, end: 0);
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textLightColor,
            fontFamily: 'Outfit',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: AppTheme.textDarkColor,
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isVerified = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Outfit',
            color: AppTheme.textDarkColor,
          ),
          validator:
              (v) =>
                  (isRequired && (v == null || v.isEmpty)) ? 'Required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.successColor, size: 20),
            suffixIcon:
                isVerified
                    ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                    : null,
            filled: true,
            fillColor:
                readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.successColor,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textLightColor,
          ),
          items:
              items
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Outfit',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.map_rounded,
              color: AppTheme.successColor,
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.successColor,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeDropdown(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textLightColor,
          ),
          items:
              items
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Outfit',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.home_work_rounded,
              color: AppTheme.successColor,
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.successColor,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? current,
    Function(DateTime) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: current ?? DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppTheme.successColor,
                      onPrimary: Colors.white,
                      onSurface: AppTheme.textDarkColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) onSelected(picked);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  current != null
                      ? DateFormat('dd MMM yyyy').format(current)
                      : 'Select Date',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Outfit',
                    color: AppTheme.textDarkColor,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textLightColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
