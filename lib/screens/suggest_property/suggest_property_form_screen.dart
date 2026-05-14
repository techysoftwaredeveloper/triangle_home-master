import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/suggest_property/suggest_property_success_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class SuggestPropertyFormScreen extends StatefulWidget {
  const SuggestPropertyFormScreen({super.key});

  @override
  State<SuggestPropertyFormScreen> createState() => _SuggestPropertyFormScreenState();
}

class _SuggestPropertyFormScreenState extends State<SuggestPropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0; // 0, 1, 2
  String _userRole = 'student';

  // Suggester Details
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Suggested Owner Details
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();

  // Suggested Business/Property Details
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  String _selectedCategory = 'PG Accommodation';

  final List<String> _categories = [
    'PG Accommodation',
    'College Hostel',
    'Apartment',
    'Villa',
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserDefaultData();
  }

  void _loadUserDefaultData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _phoneController.text = user.phoneNumber ?? '';

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final info = data['info'] as Map<String, dynamic>? ?? {};
        setState(() {
          _nameController.text = info['name'] ?? '';
          _emailController.text = info['email'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOutCubic);
    } else {
      _handleSubmit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: 400.ms, curve: Curves.easeInOutCubic);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final suggestionData = {
        'suggester_id': user?.uid,
        'suggester_role': _userRole,
        'suggester_name': _nameController.text.trim(),
        'suggester_email': _emailController.text.trim(),
        'suggester_phone': _phoneController.text.trim(),
        'owner_name': _ownerNameController.text.trim(),
        'owner_phone': _ownerPhoneController.text.trim(),
        'owner_email': _ownerEmailController.text.trim(),
        'business_name': _businessNameController.text.trim(),
        'business_address': _businessAddressController.text.trim(),
        'category': _selectedCategory,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('property_suggestions').add(suggestionData);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuggestPropertySuccessScreen(suggestionData: suggestionData),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDarkColor, size: 20),
          onPressed: _previousStep,
        ),
        title: const Text(
          'Suggest a Property',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.primaryColor),
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentStep + 1} of 3',
            style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ).animate(key: ValueKey(_currentStep)).fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 4),
          const Text(
            'Help others find a great place to live or stay.',
            style: TextStyle(fontSize: 13, color: AppTheme.textLightColor, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentStep = page),
                children: [
                  _buildSuggesterStep(),
                  _buildOwnerStep(),
                  _buildBusinessStep(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          _buildStepCircle(0, 'Suggester'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Owner'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Property'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
            border: Border.all(color: isActive ? AppTheme.primaryColor : const Color(0xFFE2E8F0), width: 2),
            boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textLightColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppTheme.primaryColor : AppTheme.textLightColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    bool isPassed = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(left: 8, right: 8, bottom: 18),
        color: isPassed ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildSuggesterStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Who are you?'),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildRoleOption('student', 'Student', 'Suggesting as a student', Icons.school_outlined),
              const SizedBox(width: 16),
              _buildRoleOption('professional', 'Professional', 'Suggesting as a professional', Icons.business_center_outlined),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Your Details (Suggester)'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(controller: _nameController, label: 'Full Name', hint: 'Your name', icon: Icons.person_outline)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(controller: _emailController, label: 'Email Address', hint: 'email@gmail.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(controller: _phoneController, label: 'Phone Number', hint: '+91 00000 00000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOwnerStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Suggested Business Owner Details'),
          const SizedBox(height: 24),
          _buildTextField(controller: _ownerNameController, label: 'Owner Full Name', hint: 'e.g. John Doe', icon: Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField(controller: _ownerPhoneController, label: 'Owner Phone Number', hint: '+91 98765 43210', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(controller: _ownerEmailController, label: 'Owner Email (Optional)', hint: 'johndoe@gmail.com', icon: Icons.email_outlined, required: false, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBusinessStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Suggested Business Name & Address'),
          const SizedBox(height: 24),
          _buildTextField(controller: _businessNameController, label: 'Business / Property Name', hint: 'e.g. Sunrise Hostels', icon: Icons.business_outlined),
          const SizedBox(height: 16),
          _buildTextField(controller: _businessAddressController, label: 'Business Address', hint: 'e.g. Kozhikode, Kerala', icon: Icons.location_on_outlined, maxLines: 2),
          const SizedBox(height: 16),
          _buildDropdown('Property Category', _selectedCategory, _categories),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String role, String title, String subtitle, IconData icon) {
    bool isSelected = _userRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _userRole = role),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC), shape: BoxShape.circle),
                    child: Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.textLightColor, size: 20),
                  ),
                  if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20).animate().scale(),
                ],
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.textDarkColor),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: AppTheme.primaryColor.withValues(alpha: 0.6), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppTheme.textDarkColor, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primaryColor.withValues(alpha: 0.6), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_currentStep == 2 ? 'Submit Suggestion' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                        const SizedBox(width: 12),
                        Icon(_currentStep == 2 ? Icons.check_circle_outline : Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.textLightColor.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                'Your information is safe and secure',
                style: TextStyle(fontSize: 12, color: AppTheme.textLightColor.withValues(alpha: 0.6), fontFamily: 'Outfit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
