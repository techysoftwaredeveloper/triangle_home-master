import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  String _selectedYear = '1st Year';
  String _selectedGender = 'Male';
  bool _isSaving = false;

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
    super.dispose();
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
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Triangle Homes!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        color: AppTheme.textDarkColor,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 8),
                    const Text(
                      'Please provide your details to help us find the best accommodation for you.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLightColor,
                        fontFamily: 'Outfit',
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 32),

                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      hint: 'Enter your legal name',
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

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

                    _buildGenderSelection().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 24),
          const Text(
            'Student Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
          const Text(
            'Tell us about your student life',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Outfit',
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLightColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
            fontSize: 14,
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
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, color: AppTheme.textColor),
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

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLightColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenderOption('Male', Icons.male_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildGenderOption('Female', Icons.female_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return InkWell(
      onTap: () => setState(() => _selectedGender = gender),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textLightColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);
      try {
        final studentData = {
          'name': _nameController.text.trim(),
          'collegeName': _collegeController.text.trim(),
          'course': _courseController.text.trim(),
          'year': _selectedYear,
          'gender': _selectedGender,
          'phoneNumber': widget.phoneNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('student')
            .doc(widget.phoneNumber)
            .set({'info': studentData}, SetOptions(merge: true));

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }
}
