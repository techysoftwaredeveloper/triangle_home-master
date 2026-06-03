import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:triangle_home/screens/profile/verification_center_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OwnerProfileEditScreen extends StatefulWidget {
  const OwnerProfileEditScreen({super.key});

  @override
  State<OwnerProfileEditScreen> createState() => _OwnerProfileEditScreenState();
}

class _OwnerProfileEditScreenState extends State<OwnerProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  // State Variables
  String? _selectedGender;
  DateTime? _dob;
  String? _selectedState;
  String? _profileImageUrl;
  File? _newImageFile;
  bool _isSaving = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Preferences
  List<String> _preferredTenants = [];
  String? _prefGender;

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
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        _userData = doc.data();
        final info = _userData?['info'] as Map? ?? {};
        final prefs = _userData?['host_preferences'] as Map? ?? {};

        setState(() {
          _nameController.text = info['name'] ?? '';
          _emailController.text = info['email'] ?? user.email ?? '';
          _phoneController.text = info['phone'] ?? user.phoneNumber ?? '';
          _address1Controller.text = info['addressLine1'] ?? '';
          _address2Controller.text = info['addressLine2'] ?? '';
          _cityController.text = info['city'] ?? '';
          _pincodeController.text = info['pincode'] ?? '';
          _selectedState = info['state'];
          _selectedGender = info['gender'];
          if (info['dob'] != null) {
            try {
              if (info['dob'] is Timestamp) {
                _dob = (info['dob'] as Timestamp).toDate();
              } else if (info['dob'] is String) {
                _dob = DateTime.tryParse(info['dob']);
              }
            } catch (e) {
              debugPrint('Error parsing DOB: $e');
            }
          }
          _profileImageUrl = info['profileImage'];

          _preferredTenants = List<String>.from(prefs['tenantTypes'] ?? []);
          _prefGender = prefs['genderPreference'];

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading owner profile: $e');
      setState(() => _isLoading = false);
    }
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
    if (_userData == null) return 0.0;
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      String? imageUrl = _profileImageUrl;
      if (_newImageFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_images/${user!.uid}.jpg',
        );
        await ref.putFile(_newImageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final updateData = {
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
        'host_preferences': {
          'tenantTypes': _preferredTenants,
          'genderPreference': _prefGender,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update(updateData);

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Profile updated successfully!',
          backgroundColor: AppTheme.successColor,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving owner profile: $e');
      Fluttertoast.showToast(
        msg: 'Failed to save profile',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusDashboard(),
                        const SizedBox(height: 32),
                        _buildPhotoSection(),
                        const SizedBox(height: 32),
                        _buildBasicInfoSection(),
                        const SizedBox(height: 32),
                        _buildContactSection(),
                        const SizedBox(height: 32),
                        _buildAddressSection(),
                        const SizedBox(height: 32),
                        _buildIdentitySection(),
                        const SizedBox(height: 32),
                        _buildPreferencesSection(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.successColor,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: const Text(
        'Owner Profile',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8),
        child: GestureDetector(
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
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Partner with Triangle Homes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your properties and reach more tenants',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.4,
                child: Image.network(
                  'https://img.freepik.com/free-vector/city-skyline-concept-illustration_114360-892.jpg',
                  height: 140,
                  fit: BoxFit.contain,
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
    final verif = _userData?['verification'] as Map? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Completion',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(completion * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkColor,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: completion,
                    minHeight: 4,
                    backgroundColor: Colors.grey[100],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(height: 80, width: 1, color: Colors.grey[200]),
          const SizedBox(width: 20),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Verification Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                _buildVerifMiniRow(
                  'Email Verified',
                  _userData?['status'] == 'approved',
                ),
                const SizedBox(height: 8),
                _buildVerifMiniRow('Phone Verified', true),
                const SizedBox(height: 8),
                _buildVerifMiniRow(
                  'Identity Verification',
                  verif['govIdVerified'] == true,
                  isPending: verif['govIdStatus'] == 'pending',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifMiniRow(
    String label,
    bool isDone, {
    bool isPending = false,
  }) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.access_time_filled,
          size: 16,
          color:
              isDone ? Colors.green : (isPending ? Colors.orange : Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDarkColor,
            ),
          ),
        ),
        if (isPending)
          const Text(
            'Pending',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
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
                                : const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Color(0xFF4CAF50),
                                )),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add your photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A clear photo helps build trust with tenants.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const Text(
                    'JPG, PNG up to 5MB',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: _pickImage,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.successColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Edit Photo',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField('Full Name *', _nameController, Icons.person_outline),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gender *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLightColor,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children:
                    ['Male', 'Female', 'Other'].map((g) {
                      final isSelected = _selectedGender == g;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = g),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppTheme.successColor
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                g,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : AppTheme.textLightColor,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildDateField(
          'Date of Birth *',
          _dob,
          (d) => setState(() => _dob = d),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Phone Number *',
          _phoneController,
          Icons.phone_android_outlined,
          isVerified: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Email Address *',
          _emailController,
          Icons.email_outlined,
          isVerified: user?.emailVerified ?? false,
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Address Line 1 *',
          _address1Controller,
          Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Address Line 2 (Optional)',
          _address2Controller,
          Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'City *',
                _cityController,
                Icons.business_outlined,
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
        const SizedBox(height: 16),
        _buildTextField(
          'Pincode *',
          _pincodeController,
          Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildIdentitySection() {
    final verif = _userData?['verification'] as Map? ?? {};
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Identity Verification',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
                fontFamily: 'Outfit',
              ),
            ),
            TextButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerificationCenterScreen(),
                    ),
                  ),
              child: const Row(
                children: [
                  Text(
                    'View Documents',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppTheme.successColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildIdentityTile(
          'Aadhaar Card',
          verif['aadhaarNumber'] ?? 'XXXX XXXX 1234',
          verif['govIdStatus'] == 'pending'
              ? 'Pending Review'
              : (verif['govIdVerified'] == true ? 'Verified' : 'Not Uploaded'),
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
          verif['panNumber'] ?? 'ABCDE1234F',
          verif['panVerified'] == true ? 'Verified' : 'Not Uploaded',
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
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerificationCenterScreen()),
          ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textLightColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'Verified'
                        ? Icons.check_circle
                        : Icons.access_time_filled,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Host Preferences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
                fontFamily: 'Outfit',
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Row(
                children: [
                  Text(
                    'Edit Preferences',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
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
                'Preferred Tenant Type',
                ['Students', 'Professionals', 'Families'],
                _preferredTenants,
                (v) => setState(() {
                  if (_preferredTenants.contains(v)) {
                    _preferredTenants.remove(v);
                  } else {
                    _preferredTenants.add(v);
                  }
                }),
                [
                  Icons.school_outlined,
                  Icons.work_outline,
                  Icons.people_outline,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPreferenceCard(
                'Gender Preference',
                ['Male', 'Female', 'Any'],
                _prefGender != null ? [_prefGender!] : [],
                (v) => setState(() => _prefGender = v),
                [
                  Icons.person_outline,
                  Icons.person_pin_outlined,
                  Icons.people_alt_outlined,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLightColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(options.length, (i) {
              final isSelected = current.contains(options[i]);
              return InkWell(
                onTap: () => onTap(options[i]),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : Colors.grey[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icons[i],
                        size: 18,
                        color: isSelected ? AppTheme.successColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      options[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.successColor : Colors.grey,
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

  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSaving)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else ...[
                const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Save Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLightColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: AppTheme.textDarkColor,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.successColor, size: 20),
            suffixIcon:
                isVerified
                    ? Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 12,
                          ),
                        ],
                      ),
                    )
                    : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.successColor,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLightColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: value,
            items:
                items
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.map_outlined,
                color: AppTheme.successColor,
                size: 20,
              ),
            ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLightColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: current ?? DateTime(1990),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null) onSelected(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  current != null
                      ? DateFormat('dd MMM yyyy').format(current)
                      : 'Select Date',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
