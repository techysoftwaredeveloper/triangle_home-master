import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/college_search_popup.dart';

class StudentInfoScreen extends StatefulWidget {
  final String phoneNumber;
  final Widget? onCompleteNavigateTo;
  const StudentInfoScreen({
    super.key,
    required this.phoneNumber,
    this.onCompleteNavigateTo,
  });

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _courseController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedYear = '1st Year';
  String _selectedGender = 'Male';
  bool _isSaving = false;
  File? _profileImage;

  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Final Year',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _courseController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_profileImage == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  void _showCollegePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollegeSearchPopup(
        colleges: const ['Yenepoya University', 'Anna University', 'St. Aloysius College', 'Madras Christian College'],
        onCollegeSelected: (college) {
          setState(() {
            _collegeController.text = college;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      hint: 'Enter your legal name',
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      hint: 'yourname@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Academic Details'),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'College/University',
                      controller: _collegeController,
                      icon: Icons.school_outlined,
                      hint: 'Select your institution',
                      readOnly: true,
                      onTap: _showCollegePicker,
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'Course',
                      controller: _courseController,
                      icon: Icons.book_outlined,
                      hint: 'e.g. B.Tech Computer Science',
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    _buildDropdown(
                      label: 'Year of Study',
                      value: _selectedYear,
                      items: _years,
                      onChanged: (value) => setState(() => _selectedYear = value!),
                      icon: Icons.calendar_today_outlined,
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Identity'),
                    const SizedBox(height: 16),
                    _buildGenderSelector().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Complete Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        fontFamily: 'Outfit',
        color: AppTheme.textDarkColor,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const Text(
                'Student Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(width: 40), // Balance
            ],
          ),
          const SizedBox(height: 24),
          _buildImagePicker(),
          const SizedBox(height: 16),
          const Text(
            'Tell us about your student life',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Outfit',
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
            child: _profileImage == null
                ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                : null,
          ),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
          ),
        ),
      ],
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLightColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly || onTap != null,
          onTap: onTap,
          keyboardType: keyboardType,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
            filled: true,
            fillColor: (readOnly || onTap != null) ? const Color(0xFFF1F5F9).withOpacity(0.5) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLightColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppTheme.textColor, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLightColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildGenderOption('Male', Icons.male_rounded),
            const SizedBox(width: 12),
            _buildGenderOption('Female', Icons.female_rounded),
            const SizedBox(width: 12),
            _buildGenderOption('Other', Icons.person_outline_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedGender = gender),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(
                gender,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not authenticated')));
      return;
    }

    final uid = user.uid;
    debugPrint('💾 Attempting to save student profile for UID: $uid');

    // 🔍 Diagnostic: Check App Check Token
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      debugPrint('🛡️ App Check Token Status: ${token != null ? 'Valid' : 'Missing'}');
    } catch (e) {
      debugPrint('🛡️ App Check Token Error: $e');
    }

    try {
      // 1. Upload Image if any
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await _uploadImage(uid);
      }

      // 2. Prepare Data
      final studentData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'collegeName': _collegeController.text.trim(),
        'course': _courseController.text.trim(),
        'year': _selectedYear,
        'gender': _selectedGender,
        'phoneNumber': widget.phoneNumber,
        'uid': uid,
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ✅ FIX: Use "users" collection and include required fields to satisfy Security Rules
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
            'role': 'student',
            'info': studentData,
            'permissions': {
              'is_admin': false,
            },
            'is_active': true,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint('✅ Write to "users" collection successful.');

      if (!mounted) return;

      if (widget.onCompleteNavigateTo != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => widget.onCompleteNavigateTo!),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      debugPrint('❌ Firestore Save Error: $e');

      String errorMessage = 'Failed to save profile: $e';
      bool isPermissionDenied = e.toString().contains('permission-denied');

      if (isPermissionDenied) {
        errorMessage = 'Access Denied: Please register your debug secret in the Firebase Console under App Check.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Report Info',
            onPressed: () => _showDetailedDiagnosticDialog(uid, e.toString()),
          ),
        ),
      );
    }
  }

  void _showDetailedDiagnosticDialog(String uid, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Diagnostic'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This device is blocked by Firebase Security.', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('1. Logged in UID:'),
              SelectableText(uid, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('2. Error:'),
              SelectableText(error, style: const TextStyle(fontSize: 12, color: Colors.red)),
              const SizedBox(height: 12),
              const Text('Fix Checklist:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('• Register Debug Token in Console'),
              const Text('• Ensure Firestore Rules allow write to /users/UID'),
              const Text('• Check if App Check Enforcement is ON'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
