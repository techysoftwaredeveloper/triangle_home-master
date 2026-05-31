import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class HosterInfoScreen extends StatefulWidget {
  final String phoneNumber;
  final Widget? onCompleteNavigateTo;
  const HosterInfoScreen({
    super.key,
    required this.phoneNumber,
    this.onCompleteNavigateTo,
  });

  @override
  State<HosterInfoScreen> createState() => _HosterInfoScreenState();
}

class _HosterInfoScreenState extends State<HosterInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedPropertyType = 'Hostel';
  bool _isTermsAccepted = false;
  bool _isSaving = false;

  final List<String> _propertyTypes = [
    'Hostel',
    'PG Accommodation',
    'Apartment',
    'Villa',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
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
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone_android_outlined,
                      hint: '10 digit number',
                      keyboardType: TextInputType.phone,
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Business Details'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Business Name (Optional)',
                      controller: _businessNameController,
                      icon: Icons.business_outlined,
                      hint: 'e.g. Sunrise Properties',
                      required: false,
                    ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      label: 'Primary Property Type',
                      value: _selectedPropertyType,
                      items: _propertyTypes,
                      onChanged: (value) => setState(() => _selectedPropertyType = value!),
                      icon: Icons.home_work_outlined,
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Office/Business Address',
                      controller: _addressController,
                      icon: Icons.location_on_outlined,
                      hint: 'Full business address',
                      maxLines: 2,
                    ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 32),
                    _buildTermsCheckbox().animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isSaving || !_isTermsAccepted) ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Complete Registration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
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
        color: AppTheme.successColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Owner Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Partner with Triangle Homes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          const Text(
            'Manage your properties and reach more tenants',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool required = true,
    TextInputType? keyboardType,
    int maxLines = 1,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.successColor, size: 22),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (keyboardType == TextInputType.emailAddress && !value.contains('@')) return 'Invalid email';
                  if (keyboardType == TextInputType.phone && value.length < 10) return 'Invalid phone';
                  return null;
                }
              : null,
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
            initialValue: value,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppTheme.textColor, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.successColor, size: 22),
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

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CheckboxListTile(
        value: _isTermsAccepted,
        onChanged: (value) => setState(() => _isTermsAccepted = value!),
        title: const Text(
          'I agree to the terms and conditions and privacy policy of Triangle Homes.',
          style: TextStyle(fontSize: 12, fontFamily: 'Outfit'),
        ),
        activeColor: AppTheme.successColor,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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

    try {
      final hosterData = {
        'name': _nameController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'propertyType': _selectedPropertyType,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'hoster',
        'info': hosterData,
        'permissions': {
          'is_admin': false,
        },
        'is_active': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save data: $e')));
    }
  }
}
