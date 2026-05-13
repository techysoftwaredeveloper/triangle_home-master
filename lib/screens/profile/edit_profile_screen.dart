import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/college_search_popup.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _collegeController = TextEditingController();

  String? _selectedGender;
  String? _profileImageUrl;
  File? _newImageFile;
  bool _isSaving = false;
  bool _isStudent = false;
  String _userCollection = 'guest';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final phone = user.phoneNumber;
    final collections = ['student', 'hoster', 'guest'];

    for (final collection in collections) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(uid)
          .get();

      if (!doc.exists && phone != null) {
        doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(phone)
            .get();
      }

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final info = data['info'] as Map<String, dynamic>? ?? {};
        setState(() {
          _userCollection = collection;
          _isStudent = collection == 'student';
          _nameController.text = info['name'] ?? data['name'] ?? '';
          _emailController.text = info['email'] ?? data['email'] ?? '';
          _phoneController.text = phone ?? uid;
          _collegeController.text = info['college'] ?? info['collegeName'] ?? data['college'] ?? '';
          _selectedGender = info['gender'] ?? data['gender'];
          _profileImageUrl = info['profileImage'] ?? data['profileImage'];
        });
        break;
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _newImageFile = File(pickedImage.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile, String identifier) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/$identifier.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final uid = user.uid;
    final phone = user.phoneNumber;
    final identifier = phone ?? uid;
    String? imageUrl = _profileImageUrl;

    if (_newImageFile != null) {
      imageUrl = await _uploadImage(_newImageFile!, identifier);
    }

    final docRef = FirebaseFirestore.instance.collection(_userCollection).doc(uid);
    var doc = await docRef.get();

    String targetDocId = uid;
    if (!doc.exists && phone != null) {
      final phoneDoc = await FirebaseFirestore.instance.collection(_userCollection).doc(phone).get();
      if (phoneDoc.exists) {
        targetDocId = phone;
        doc = phoneDoc;
      }
    }

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'profileImage': imageUrl,
        'gender': _selectedGender,
        'collegeName': _collegeController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (data.containsKey('info')) {
        final nestedUpdate = {};
        updateData.forEach((key, value) {
          nestedUpdate['info.$key'] = value;
        });
        await FirebaseFirestore.instance.collection(_userCollection).doc(targetDocId).update(Map<String, dynamic>.from(nestedUpdate));
      } else {
        await FirebaseFirestore.instance.collection(_userCollection).doc(targetDocId).update(updateData);
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
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
                    _buildSectionTitle('Basic Account Information'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      hint: 'Enter your name',
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      hint: 'yourname@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone_android_rounded,
                      hint: '',
                      readOnly: true,
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Identity & Preferences'),
                    const SizedBox(height: 16),
                    _buildGenderSelector().animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

                    if (_isStudent) ...[
                      const SizedBox(height: 32),
                      _buildSectionTitle('Academic Information'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'College/University',
                        controller: _collegeController,
                        icon: Icons.school_outlined,
                        hint: 'Select your institution',
                        readOnly: true,
                        onTap: _showCollegePicker,
                      ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),
                    ],

                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
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
                                'Update Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(width: 40), // Balance the back button
            ],
          ),
          const SizedBox(height: 32),
          _buildImagePicker(),
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
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.textDarkColor,
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildImagePicker() {
    ImageProvider image;
    if (_newImageFile != null) {
      image = FileImage(_newImageFile!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      image = NetworkImage(_profileImageUrl!);
    } else {
      image = const NetworkImage('https://ui-avatars.com/api/?name=U&background=random');
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: image,
          ),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 20,
              color: Colors.white,
            ),
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
    String? Function(String?)? validator,
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
            labelStyle: const TextStyle(fontFamily: 'Outfit'),
          ),
          validator: validator,
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
}
