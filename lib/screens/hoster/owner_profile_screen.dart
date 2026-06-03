import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/screens/profile/verification_center_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  // State
  String? _selectedGender;
  DateTime? _dob;
  String? _selectedState;
  String? _profileImageUrl;
  File? _newImageFile;
  bool _isSaving = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Preferences
  String _prefTenant = 'Students';
  String _prefGender = 'Any';

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
          _selectedGender = info['gender'] ?? 'Male';
          if (info['dob'] != null) _dob = (info['dob'] as Timestamp).toDate();
          _profileImageUrl = info['profileImage'];

          _prefTenant = prefs['tenantType'] ?? 'Students';
          _prefGender = prefs['genderPreference'] ?? 'Any';

          _isLoading = false;
        });
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
          'tenantType': _prefTenant,
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
          msg: 'Profile saved successfully!',
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
              _buildHeader(),
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
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

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppTheme.successColor,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(color: AppTheme.successColor),
            Positioned(
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.3,
                child: Image.network(
                  'https://img.freepik.com/free-vector/city-skyline-concept-illustration_114360-892.jpg',
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Owner Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage your properties and hosts\nfrom one place',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDashboard() {
    final verif = _userData?['verification'] as Map? ?? {};
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      margin: const EdgeInsets.only(top: 20),
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
                const Text(
                  '78%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkColor,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 0.78,
                    minHeight: 6,
                    backgroundColor: Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(height: 60, width: 1, color: Colors.grey[200]),
          const SizedBox(width: 20),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildVerifMiniRow(
                  'Email Verified',
                  user?.emailVerified ?? false,
                ),
                _buildVerifMiniRow('Phone Verified', true),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle
                : (isPending
                    ? Icons.access_time_filled
                    : Icons.circle_outlined),
            size: 14,
            color:
                isDone
                    ? Colors.green
                    : (isPending ? Colors.orange : Colors.grey),
          ),
          const SizedBox(width: 6),
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
          if (!isDone && !isPending)
            const Icon(Icons.chevron_right, size: 12, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Photo',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
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
                    color: const Color(0xFFF1F5F9),
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
                                  size: 45,
                                  color: Color(0xFF94A3B8),
                                )),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 12,
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A clear photo helps build trust with tenants.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                  const Text(
                    'JPG, PNG up to 5MB',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: _pickImage,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.successColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Edit Photo',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildLabeledTextField(
                'Full Name *',
                _nameController,
                Icons.person_outline,
                'JIBIN N ANTONY',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gender *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children:
                        ['Male', 'Female', 'Other']
                            .map(
                              (g) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: InkWell(
                                    onTap:
                                        () =>
                                            setState(() => _selectedGender = g),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _selectedGender == g
                                                ? AppTheme.successColor
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              _selectedGender == g
                                                  ? AppTheme.successColor
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          g,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _selectedGender == g
                                                    ? Colors.white
                                                    : AppTheme.textLightColor,
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
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildLabeledDateField(
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
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildLabeledTextField(
                'Phone Number *',
                _phoneController,
                Icons.phone_android_outlined,
                '+91 89214 94013',
                isVerified: true,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledTextField(
                'Email Address *',
                _emailController,
                Icons.email_outlined,
                'jibinantony@gmail.com',
                isVerified: user?.emailVerified ?? false,
                readOnly: true,
              ),
            ),
          ],
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
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildLabeledTextField(
          'Address Line 1 *',
          _address1Controller,
          Icons.location_on_outlined,
          'Sunrise PG, Near Cochin University',
        ),
        const SizedBox(height: 16),
        _buildLabeledTextField(
          'Address Line 2 (Optional)',
          _address2Controller,
          Icons.location_on_outlined,
          'Pulinchodu, Kalamassery',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildLabeledTextField(
                'City *',
                _cityController,
                Icons.business_outlined,
                'Kochi',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLabeledDropdownField(
                'State *',
                _indianStates,
                _selectedState,
                (v) => setState(() => _selectedState = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabeledTextField(
          'Pincode *',
          _pincodeController,
          Icons.pin_drop_outlined,
          '682022',
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
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
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
              child: Row(
                children: const [
                  Text(
                    'View Documents',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Image.network(iconUrl, width: 28, height: 28),
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLightColor,
                    fontWeight: FontWeight.w600,
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
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
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
            const Text(
              'Host Preferences',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Edit Preferences',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
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
                _prefTenant,
                (v) => setState(() => _prefTenant = v),
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
                _prefGender,
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
    String current,
    Function(String) onTap,
    List<IconData> icons,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(options.length, (i) {
              final isSelected = current == options[i];
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
                                : const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icons[i],
                        size: 18,
                        color: isSelected ? AppTheme.successColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      options[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.successColor : Colors.grey,
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveProfile,
          icon:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Icon(
                    Icons.save_as_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
          label: Text(
            _isSaving ? 'Saving...' : 'Save Profile',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Outfit',
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
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
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Outfit',
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.successColor, size: 18),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
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
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildLabeledDropdownField(
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
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
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
                            fontWeight: FontWeight.w600,
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
                size: 18,
              ),
            ),
            validator: (v) => v == null ? 'Required' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledDateField(
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
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkColor,
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
              builder:
                  (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.successColor,
                      ),
                    ),
                    child: child!,
                  ),
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
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  current != null
                      ? DateFormat('dd MMM yyyy').format(current)
                      : 'Select Date',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
