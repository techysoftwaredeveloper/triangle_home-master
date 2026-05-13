import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/home_screen.dart';

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

  final List<String> _propertyTypes = [
    'Hostel',
    'PG Accommodation',
    'Apartment',
    'Villa',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF1E3A8A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Property Owner Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            'Full Name',
                            null,
                            Icons.person,
                            initialValue: widget.phoneNumber,
                          ).animate().fadeIn().slideX(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Business Name (Optional)',
                            _businessNameController,
                            Icons.business,
                            required: false,
                          ).animate().fadeIn().slideX(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Address',
                            _addressController,
                            Icons.location_on,
                            maxLines: 3,
                          ).animate().fadeIn().slideX(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Phone Number',
                            _phoneController,
                            Icons.phone,
                            keyboardType: TextInputType.phone,
                          ).animate().fadeIn().slideX(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Email',
                            _emailController,
                            Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ).animate().fadeIn().slideX(),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            'Property Type',
                            _selectedPropertyType,
                            _propertyTypes,
                            (value) =>
                                setState(() => _selectedPropertyType = value!),
                            Icons.home,
                          ).animate().fadeIn().slideX(),
                          const SizedBox(height: 24),
                          _buildTermsCheckbox().animate().fadeIn().slideX(),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isTermsAccepted ? _handleSubmit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ).animate().fadeIn().slideY(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController? controller,
    IconData icon, {
    bool required = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? initialValue,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator:
          required
              ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                if (keyboardType == TextInputType.emailAddress &&
                    !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                if (keyboardType == TextInputType.phone && value.length != 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              }
              : null,
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTermsCheckbox() {
    return CheckboxListTile(
      value: _isTermsAccepted,
      onChanged: (value) => setState(() => _isTermsAccepted = value!),
      title: const Text(
        'I agree to the terms and conditions and privacy policy',
        style: TextStyle(fontSize: 14),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
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
          'status': 'pending', // Default status for moderation
        };

        // ✅ FIX: Use UID as document ID to satisfy Firestore Rules [request.auth.uid == userId]
        await FirebaseFirestore.instance
            .collection('hoster')
            .doc(uid)
            .set({'info': hosterData}, SetOptions(merge: true));

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
            MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save data: $e')));
      }
    }
  }
}
