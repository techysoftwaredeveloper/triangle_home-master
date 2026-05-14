import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class BecomeHosterScreen extends StatefulWidget {
  const BecomeHosterScreen({super.key});

  @override
  State<BecomeHosterScreen> createState() => _BecomeHosterScreenState();
}

class _BecomeHosterScreenState extends State<BecomeHosterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessNameController = TextEditingController();

  String _selectedPropertyType = 'PG Accommodation';
  bool _isTermsAccepted = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? _existingRequest;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;

  final List<String> _propertyTypes = [
    'College Hostel',
    'PG Accommodation',
    'Apartment',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingRequest();
    _listenToStatusChanges();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  void _listenToStatusChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _statusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['role'] == 'hoster' && data['status'] == 'approved') {
          // Navigate to Hoster Dashboard immediately upon approval
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HosterDashboardScreen()),
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Your hoster account has been approved! Welcome aboard.'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Future<void> _loadExistingRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

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
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final info = (data['info'] as Map?)?.cast<String, dynamic>() ?? {};
        if (mounted) {
          _nameController.text = info['name'] ?? data['name'] ?? '';
          _emailController.text = info['email'] ?? data['email'] ?? '';
        }
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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
      final phone = user.phoneNumber ?? '';

      await FirebaseFirestore.instance
          .collection('hoster_requests')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'name': _nameController.text.trim(),
            'phone': phone,
            'email': _emailController.text.trim(),
            'businessName': _businessNameController.text.trim(),
            'propertyType': _selectedPropertyType,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
            'reviewedAt': null,
            'reviewNote': '',
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted! Our team will review it soon.'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );

      await _loadExistingRequest();
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

  Future<void> _reApply() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('hoster_requests')
        .doc(user.uid)
        .delete();

    setState(() {
      _existingRequest = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
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
            'Become a Hoster',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
          const Text(
            'Start hosting your properties today',
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

  Widget _buildBody() {
    final status = _existingRequest?['status'] as String?;

    if (status == 'pending') return _buildPendingState();
    if (status == 'rejected') return _buildRejectedState();
    return _buildForm();
  }

  Widget _buildPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                size: 64,
                color: AppTheme.warningColor,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            const Text(
              'Application Pending',
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
    );
  }

  Widget _buildReviewInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _summaryRow(Icons.person_outline, 'Name', _existingRequest?['name'] ?? ''),
          const Divider(height: 24),
          _summaryRow(Icons.business_outlined, 'Type', _existingRequest?['propertyType'] ?? ''),
          const Divider(height: 24),
          _summaryRow(Icons.phone_android_outlined, 'Contact', _existingRequest?['phone'] ?? ''),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 13, color: AppTheme.textLightColor, fontFamily: 'Outfit'),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.textDarkColor),
        ),
      ],
    );
  }

  Widget _buildRejectedState() {
    final note = _existingRequest?['reviewNote'] as String? ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.errorColor),
          ),
          const SizedBox(height: 32),
          const Text(
            'Application Rejected',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 12),
          Text(
            'Unfortunately, your application was not approved at this time. Reason: ${note.isEmpty ? "Does not meet requirements." : note}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textLightColor, fontFamily: 'Outfit', height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _reApply,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Re-Apply Now', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your legal name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'yourname@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildReadOnlyField('Phone Number', phone, Icons.phone_android_rounded),

            const SizedBox(height: 32),
            _buildSectionTitle('Business Details'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _businessNameController,
              label: 'Business/Property Name',
              hint: 'e.g. Sunrise Hostels',
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 20),
            _buildDropdown('Property Category', _selectedPropertyType, _propertyTypes),

            const SizedBox(height: 32),
            _buildTermsCheckbox(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit', fontSize: 16)),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.textDarkColor),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9).withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 12),
              Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppTheme.textLightColor)),
            ],
          ),
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
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
          child: DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppTheme.textColor),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.primaryColor, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedPropertyType = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: CheckboxListTile(
        value: _isTermsAccepted,
        onChanged: (v) => setState(() => _isTermsAccepted = v!),
        title: const Text('I agree to the Terms & Conditions and Privacy Policy of Triangle Homes.', style: TextStyle(fontSize: 12, fontFamily: 'Outfit')),
        activeColor: AppTheme.primaryColor,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
