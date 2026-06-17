import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:triangle_home/widgets/college_search_popup.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:triangle_home/services/location_api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  // Student controllers
  final _collegeController = TextEditingController();
  final _courseController = TextEditingController();
  final _semesterController = TextEditingController();
  final _studentIdController = TextEditingController();

  // Professional controllers
  final _companyController = TextEditingController();
  final _designationController = TextEditingController();
  final _workLocationController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _experienceController = TextEditingController();

  // Emergency controllers
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // State Variables
  String? _selectedGender;
  DateTime? _dob;
  String _userRole = 'student'; // 'student' or 'professional'
  String? _profileImageUrl;
  File? _newImageFile;
  bool _isSaving = false;
  bool _isLoading = true;
  Map<String, dynamic>? _verificationData;
  List<String> _allColleges = [];

  // Preferences
  String _preferredCity = 'Bangalore';
  RangeValues _budgetRange = const RangeValues(6000, 12000);
  List<String> _lookingFor = ['PG'];
  DateTime? _moveInDate;
  String _stayDuration = '6 Months';
  int _familySize = 1;

  final Color _primaryBlue = AppTheme.primaryColor;
  final Color _accentBlue = AppTheme.accentColor;
  final Color _bgGray = AppTheme.scaffoldBgColor;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Add listeners for real-time readiness updates
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _collegeController.addListener(_onFieldChanged);
    _courseController.addListener(_onFieldChanged);
    _semesterController.addListener(_onFieldChanged);
    _studentIdController.addListener(_onFieldChanged);
    _companyController.addListener(_onFieldChanged);
    _designationController.addListener(_onFieldChanged);
    _workLocationController.addListener(_onFieldChanged);
    _employeeIdController.addListener(_onFieldChanged);
    _experienceController.addListener(_onFieldChanged);
    _emergencyNameController.addListener(_onFieldChanged);
    _emergencyRelationController.addListener(_onFieldChanged);
    _emergencyPhoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _collegeController.dispose();
    _courseController.dispose();
    _semesterController.dispose();
    _studentIdController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    _workLocationController.dispose();
    _employeeIdController.dispose();
    _experienceController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load colleges from Firestore
      final collegesSnapshot =
          await FirebaseFirestore.instance.collection('properties').get();
      final collegesSet = <String>{};
      for (var doc in collegesSnapshot.docs) {
        final name = doc.data()['basicInfo']?['collegeName'] as String?;
        if (name != null && name.isNotEmpty) collegesSet.add(name);
      }
      _allColleges = collegesSet.toList()..sort();
      if (_allColleges.isEmpty) {
        _allColleges = [
          'Yenepoya University',
          'Madras Christian College',
          'IIT Bombay',
          'IIT Delhi',
          'NIT Calicut',
        ];
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        final info = data['info'] as Map? ?? {};
        final prefs = data['housing_preferences'] as Map? ?? {};
        final emergency = data['emergency_contact'] as Map? ?? {};

        setState(() {
          _verificationData =
              (data['verification'] as Map?)?.cast<String, dynamic>();
          _userRole = data['role'] ?? 'student';
          _nameController.text = info['name'] ?? user.displayName ?? '';
          _emailController.text = info['email'] ?? user.email ?? '';
          _phoneController.text = info['phoneNumber'] ?? user.phoneNumber ?? '';
          _locationController.text = info['location'] ?? 'Bangalore, India';
          _selectedGender = info['gender'];
          if (info['dob'] != null) _dob = (info['dob'] as Timestamp).toDate();
          _profileImageUrl = info['profileImage'] ?? user.photoURL;

          if (_userRole == 'student') {
            final sInfo = data['student_info'] as Map? ?? {};
            _collegeController.text = sInfo['college'] ?? '';
            _courseController.text = sInfo['course'] ?? '';
            _semesterController.text = sInfo['semester'] ?? '';
            _studentIdController.text = sInfo['studentId'] ?? '';
          } else {
            final pInfo = data['professional_info'] as Map? ?? {};
            _companyController.text = pInfo['companyName'] ?? '';
            _designationController.text = pInfo['jobTitle'] ?? '';
            _workLocationController.text = pInfo['workLocation'] ?? '';
            _employeeIdController.text = pInfo['employeeId'] ?? '';
            _experienceController.text = pInfo['experience'] ?? '';
          }

          _preferredCity = prefs['preferredCity'] ?? 'Bangalore';
          _budgetRange = RangeValues(
            (prefs['budgetMin'] ?? 6000).toDouble(),
            (prefs['budgetMax'] ?? 12000).toDouble(),
          );
          _lookingFor = List<String>.from(prefs['lookingFor'] ?? ['PG']);
          if (prefs['moveInDate'] != null) {
            _moveInDate = (prefs['moveInDate'] as Timestamp).toDate();
          }
          _stayDuration = prefs['stayDuration'] ?? '6 Months';
          _familySize = prefs['familySize'] ?? 1;

          _emergencyNameController.text = emergency['name'] ?? '';
          _emergencyRelationController.text = emergency['relationship'] ?? '';
          _emergencyPhoneController.text = emergency['phone'] ?? '';

          _isLoading = false;
        });
      } else {
        setState(() {
          _nameController.text = user.displayName ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = user.phoneNumber ?? '';
          _profileImageUrl = user.photoURL;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final status = Platform.isIOS 
        ? await Permission.photos.request() 
        : await Permission.storage.request();
        
    if (status.isDenied || status.isPermanentlyDenied) {
      if (Platform.isAndroid) {
        final photoStatus = await Permission.photos.request();
        if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
          Fluttertoast.showToast(msg: 'Gallery access is required to pick a profile photo');
          if (photoStatus.isPermanentlyDenied) openAppSettings();
          return;
        }
      } else {
        Fluttertoast.showToast(msg: 'Gallery access is required to pick a profile photo');
        if (status.isPermanentlyDenied) openAppSettings();
        return;
      }
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newImageFile = File(picked.path));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: 'Please correct errors in the form',
        backgroundColor: Colors.orange,
      );
      return;
    }
    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      Fluttertoast.showToast(
        msg: 'User not authenticated',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      String? imageUrl = _profileImageUrl;
      if (_newImageFile != null) {
        try {
          final ref = FirebaseStorage.instance.ref().child(
            'profile_images/${user.uid}.jpg',
          );
          await ref.putFile(_newImageFile!);
          imageUrl = await ref.getDownloadURL();
        } catch (storageError) {
          debugPrint('Storage error: $storageError');
          // Continue saving profile data even if image upload fails
        }
      }

      final profileData = {
        'info': {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'gender': _selectedGender,
          'dob': _dob != null ? Timestamp.fromDate(_dob!) : null,
          'profileImage': imageUrl,
        },
        'emergency_contact': {
          'name': _emergencyNameController.text.trim(),
          'relationship': _emergencyRelationController.text.trim(),
          'phone': _emergencyPhoneController.text.trim(),
        },
        'housing_preferences': {
          'preferredCity': _preferredCity,
          'preferredLocations': [_preferredCity],
          'budgetMin': _budgetRange.start.toInt(),
          'budgetMax': _budgetRange.end.toInt(),
          'lookingFor': _lookingFor,
          'propertyType': _lookingFor.isNotEmpty ? _lookingFor.first : 'PG',
          'moveInDate':
              _moveInDate != null ? Timestamp.fromDate(_moveInDate!) : null,
          'stayDuration': _stayDuration,
          'familySize': _familySize,
        },
        'bookingReadiness': _calculateBookingReadiness(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (_userRole == 'student') {
        profileData['student_info'] = {
          'college': _collegeController.text.trim(),
          'course': _courseController.text.trim(),
          'semester': _semesterController.text.trim(),
          'studentId': _studentIdController.text.trim(),
        };
      } else {
        profileData['professional_info'] = {
          'companyName': _companyController.text.trim(),
          'jobTitle': _designationController.text.trim(),
          'workLocation': _workLocationController.text.trim(),
          'employeeId': _employeeIdController.text.trim(),
          'experience': _experienceController.text.trim(),
        };
      }

      // Check if document exists and get current role to avoid unnecessary role updates
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        // New user: must provide role
        profileData['role'] = _userRole;
        await docRef.set(profileData);
      } else {
        // Existing user: only update role if it changed (and rules allow)
        final currentRole = docSnap.data()?['role'];
        if (currentRole != _userRole) {
          profileData['role'] = _userRole;
        }
        await docRef.update(profileData);
      }

      // Register preferred location to backend
      final userCity = _preferredCity.trim();
      final userLocality = _locationController.text.trim();
      if (userCity.isNotEmpty) {
        LocationApiService().addLocation(city: userCity, locality: userLocality);
      }

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Profile updated!',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to update: ${e.toString()}',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                children: [
                  _buildHeaderCard(),
                  if (_calculateBookingReadiness() < 1.0) ...[
                    const SizedBox(height: 24),
                    _buildBookingReadinessIndicator(),
                  ],
                  const SizedBox(height: 24),
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildUserTypeSection(),
                  const SizedBox(height: 24),
                  _buildRoleSpecificSection(),
                  const SizedBox(height: 24),
                  _buildHousingPreferencesSection(),
                  const SizedBox(height: 24),
                  _buildEmergencyContactSection(),
                ],
              ),
            ),
          ),
          _buildStickyBottomCTA(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                backgroundImage:
                    _newImageFile != null
                        ? FileImage(_newImageFile!)
                        : (_profileImageUrl != null
                            ? CachedNetworkImageProvider(_profileImageUrl!)
                            : null),
                child:
                    (_profileImageUrl == null && _newImageFile == null)
                        ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        )
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: _primaryBlue,
                      size: 14,
                    ),
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
                Text(
                  _nameController.text.isEmpty
                      ? 'User Name'
                      : _nameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _userRole.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _locationController.text,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionCard(
      title: '1. Basic Information',
      child: Column(
        children: [
          _buildInputField('Full Name', _nameController, Icons.person_outline),
          _buildInputField(
            'Email Address',
            _emailController,
            Icons.email_outlined,
          ),
          _buildInputField(
            'Phone Number',
            _phoneController,
            Icons.phone_android_outlined,
          ),
          _buildDropdownField(
            'Gender',
            ['Male', 'Female', 'Other'],
            _selectedGender,
            (v) => setState(() => _selectedGender = v),
          ),
          _buildDateField(
            'Date of Birth',
            _dob,
            (d) => setState(() => _dob = d),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSection() {
    return _buildSectionCard(
      title: '2. I Am (User Type)',
      child: Row(
        children: [
          Expanded(
            child: _buildRoleCard(
              'Student',
              Icons.school_outlined,
              _userRole == 'student',
              () => setState(() => _userRole = 'student'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildRoleCard(
              'Professional',
              Icons.work_outline,
              _userRole == 'professional',
              () => setState(() => _userRole = 'professional'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificSection() {
    if (_userRole == 'student') {
      return _buildSectionCard(
        title: '3A. Student Information',
        child: Column(
          children: [
            _buildInputField(
              'College / University',
              _collegeController,
              Icons.account_balance_outlined,
              readOnly: true,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder:
                      (context) => CollegeSearchPopup(
                        colleges: _allColleges,
                        onCollegeSelected:
                            (name) =>
                                setState(() => _collegeController.text = name),
                      ),
                );
              },
            ),
            _buildInputField('Course', _courseController, Icons.book_outlined),
            _buildInputField(
              'Year / Semester',
              _semesterController,
              Icons.timer_outlined,
            ),
            _buildInputField(
              'Student ID Number',
              _studentIdController,
              Icons.badge_outlined,
            ),
          ],
        ),
      );
    } else {
      return _buildSectionCard(
        title: '3B. Professional Information',
        child: Column(
          children: [
            _buildInputField(
              'Company Name',
              _companyController,
              Icons.business_outlined,
            ),
            _buildInputField(
              'Designation',
              _designationController,
              Icons.work_outline,
            ),
            _buildInputField(
              'Work Location',
              _workLocationController,
              Icons.location_on_outlined,
            ),
            _buildInputField(
              'Employee ID',
              _employeeIdController,
              Icons.badge_outlined,
            ),
            _buildInputField(
              'Experience',
              _experienceController,
              Icons.history,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHousingPreferencesSection() {
    return _buildSectionCard(
      title: '4. Housing Preferences',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownField(
            'Preferred City',
            ['Bangalore', 'Kochi', 'Calicut', 'Mumbai'],
            _preferredCity,
            (v) => setState(() => _preferredCity = v!),
          ),
          const SizedBox(height: 16),
          const Text(
            'Monthly Budget Range',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_budgetRange.start.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${_budgetRange.end.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          RangeSlider(
            values: _budgetRange,
            min: 2000,
            max: 100000,
            divisions: 98,
            activeColor: _accentBlue,
            onChanged: (v) => setState(() => _budgetRange = v),
          ),
          const SizedBox(height: 16),
          const Text(
            'Looking For',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children:
                [
                  'PG',
                  'Hostel',
                  'Shared Room',
                  'Private Room',
                  'Apartment',
                ].map((type) {
                  final isSelected = _lookingFor.contains(type);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _lookingFor.remove(type);
                        } else {
                          _lookingFor.add(type);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _accentBlue : Colors.white,
                        border: Border.all(
                          color:
                              isSelected
                                  ? _accentBlue
                                  : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),
          _buildDateField(
            'Estimated Move-in Date',
            _moveInDate,
            (d) => setState(() => _moveInDate = d),
          ),
          _buildDropdownField(
            'Stay Duration',
            ['1 Month', '6 Months', '1 Year', '2 Years+'],
            _stayDuration,
            (v) => setState(() => _stayDuration = v!),
          ),
          _buildDropdownField(
            'Family Size',
            ['1', '2', '3', '4', '5+'],
            _familySize == 5 ? '5+' : _familySize.toString(),
            (v) {
              setState(() {
                if (v == '5+') {
                  _familySize = 5;
                } else {
                  _familySize = int.parse(v!);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickContact() async {
    try {
      // First try to just show the picker (native picker often doesn't need explicit permission)
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone},
      );
      if (contact != null) {
        setState(() {
          _emergencyNameController.text = contact.displayName ?? '';
          if (contact.phones.isNotEmpty) {
            // Remove any spaces or special characters from phone number
            _emergencyPhoneController.text = contact.phones.first.number
                .replaceAll(RegExp(r'[^0-9+]'), '');
          }
        });
        return;
      }
    } catch (e) {
      debugPrint('Native picker error: $e');
      // If native picker fails, try requesting permission
      if (await Permission.contacts.request().isGranted) {
        final contact = await FlutterContacts.native.showPicker(
          properties: {ContactProperty.phone},
        );
        if (contact != null) {
          setState(() {
            _emergencyNameController.text = contact.displayName ?? '';
            if (contact.phones.isNotEmpty) {
              _emergencyPhoneController.text = contact.phones.first.number
                  .replaceAll(RegExp(r'[^0-9+]'), '');
            }
          });
        }
      } else if (await Permission.contacts.isPermanentlyDenied) {
        Fluttertoast.showToast(
          msg: 'Please enable contacts permission in settings',
          backgroundColor: Colors.orange,
        );
        openAppSettings();
      } else {
        Fluttertoast.showToast(
          msg: 'Contacts permission denied',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Widget _buildEmergencyContactSection() {
    return _buildSectionCard(
      title: '5. Emergency Contact',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  'Contact Name',
                  _emergencyNameController,
                  Icons.person_outline,
                  readOnly: true,
                  onTap: _pickContact,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.contact_page_outlined,
                  color: Color(0xFF2563EB),
                ),
                onPressed: _pickContact,
                tooltip: 'Pick from contacts',
              ),
            ],
          ),
          _buildInputField(
            'Relationship',
            _emergencyRelationController,
            Icons.people_outline,
          ),
          _buildInputField(
            'Phone Number',
            _emergencyPhoneController,
            Icons.phone_android_outlined,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomCTA() {
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
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
          ),
          child:
              _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
        ),
      ),
    );
  }

  // Helpers
  double _calculateBookingReadiness() {
    double score = 0;

    // 1. Profile Completion (30% weight)
    double profileScore = 0;
    if (_nameController.text.trim().isNotEmpty) profileScore += 10;
    if (_dob != null && _selectedGender != null) profileScore += 10;
    if (_userRole == 'student') {
      if (_collegeController.text.isNotEmpty) profileScore += 10;
      if (_courseController.text.isNotEmpty) profileScore += 10;
    } else {
      if (_companyController.text.isNotEmpty) profileScore += 10;
      if (_designationController.text.isNotEmpty) profileScore += 10;
    }
    if (_emergencyNameController.text.isNotEmpty) profileScore += 10;
    if (_emergencyPhoneController.text.isNotEmpty) profileScore += 10;
    if (_preferredCity.isNotEmpty) profileScore += 10;
    if (_lookingFor.isNotEmpty) profileScore += 10;
    if (_profileImageUrl != null || _newImageFile != null) profileScore += 20;

    score += (profileScore / 100) * 30;

    // 2. Communication Verification (20% weight)
    if (_verificationData != null) {
      if (_verificationData!['phoneVerified'] == true) score += 10;
      if (_verificationData!['emailVerified'] == true) score += 10;
    }

    // 3. Document & Identity Verification (50% weight)
    if (_verificationData != null) {
      // Gov ID (15 pts)
      if (_verificationData!['govIdVerified'] == true) {
        score += 15;
      } else if (_verificationData!['govIdFrontUrl'] != null &&
          _verificationData!['govIdBackUrl'] != null) {
        score += 8;
      }

      // Role ID (10 pts)
      if (_verificationData!['roleIdVerified'] == true) {
        score += 10;
      } else if (_verificationData!['roleIdFrontUrl'] != null ||
          _verificationData!['roleIdBackUrl'] != null) {
        score += 5;
      }

      // Address Proof (10 pts)
      if (_verificationData!['addressVerified'] == true) {
        score += 10;
      } else if (_verificationData!['addressFrontUrl'] != null &&
          _verificationData!['addressBackUrl'] != null) {
        score += 5;
      }

      // Selfie (15 pts)
      if (_verificationData!['selfieVerified'] == true) {
        score += 15;
      } else if (_verificationData!['selfieUrl'] != null) {
        score += 8;
      }
    }

    return (score / 100).clamp(0.0, 1.0);
  }

  Widget _buildBookingReadinessIndicator() {
    final readiness = _calculateBookingReadiness();
    final percentage = (readiness * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Readiness',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete your profile to start booking',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            child: LinearProgressIndicator(
              value: readiness,
              minHeight: 10,
              backgroundColor: AppTheme.secondaryColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            if (label.contains('Name') ||
                label.contains('Email') ||
                label.contains('Phone') ||
                label.contains('College')) {
              return 'This field is required';
            }
          }
          if (label.contains('Email') && value != null && value.isNotEmpty) {
            if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Enter a valid email';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppTheme.textMutedColor),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.dividerColor),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.dividerColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.accentColor),
          ),
          filled: true,
          fillColor: readOnly ? AppTheme.secondaryColor : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> options,
    String? current,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(current) ? current : null,
        items:
            options
                .map(
                  (o) => DropdownMenuItem(
                    value: o,
                    child: Text(
                      o,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            Icons.list,
            size: 20,
            color: AppTheme.textMutedColor,
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.dividerColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? current,
    Function(DateTime) onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate:
                (current != null &&
                        current.isAfter(DateTime(1950)) &&
                        current.isBefore(
                          DateTime.now().add(const Duration(days: 365)),
                        ))
                    ? current
                    : (label.contains('Birth')
                        ? DateTime(2000)
                        : DateTime.now()),
            firstDate: DateTime(1950),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            locale: const Locale('en', 'IN'),
          );
          if (picked != null) onSelected(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(
              Icons.calendar_today,
              size: 20,
              color: AppTheme.textMutedColor,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
          ),
          child: Text(
            current != null
                ? DateFormat('dd MMM yyyy').format(current)
                : 'Select Date',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              active
                  ? AppTheme.accentColor.withValues(alpha: 0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: active ? AppTheme.accentColor : AppTheme.dividerColor,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: active ? AppTheme.accentColor : AppTheme.textMutedColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.accentColor : AppTheme.textLightColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
