import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  String _selectedPropertyType = 'Hostel';
  bool _isTermsAccepted = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // null = no request; Map = existing request doc data
  Map<String, dynamic>? _existingRequest;

  final List<String> _propertyTypes = [
    'Hostel',
    'PG Accommodation',
    'Apartment',
    'Villa',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingRequest();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    super.dispose();
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
      // Pre-fill name/phone from existing profile if available
      final collections = ['student', 'guest'];
      for (final col in collections) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection(col)
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          final info =
              (userDoc.data()?['info'] as Map?)?.cast<String, dynamic>() ?? {};
          if (mounted) {
            _nameController.text = info['name'] ?? '';
            _emailController.text = info['email'] ?? '';
          }
          break;
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
          content: Text('Request submitted! We will review it shortly.'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Reload to show pending state
      await _loadExistingRequest();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit request: $e')));
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
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Become a Hoster',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppTheme.fontLG,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final status = _existingRequest?['status'] as String?;

    if (status == 'pending') return _buildPendingState();
    if (status == 'rejected') return _buildRejectedState();
    return _buildForm();
  }

  // ── Pending State ────────────────────────────────────────────────────────────
  Widget _buildPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 64,
                color: AppTheme.warningColor,
              ),
            ).animate().scale(duration: 600.ms),
            const SizedBox(height: AppTheme.spaceLG),
            const Text(
              'Request Under Review',
              style: TextStyle(
                fontSize: AppTheme.font2XL,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textDarkColor,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: AppTheme.spaceMD),
            const Text(
              'Your request to become a hoster has been submitted. Our team will review it and notify you within 24–48 hours.',
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                color: AppTheme.textLightColor,
                fontFamily: AppTheme.fontFamily,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppTheme.spaceXL),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    Icons.person_outline,
                    'Name',
                    _existingRequest?['name'] ?? '',
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    Icons.phone_outlined,
                    'Phone',
                    _existingRequest?['phone'] ?? '',
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    Icons.home_outlined,
                    'Property Type',
                    _existingRequest?['propertyType'] ?? '',
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: AppTheme.spaceSM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: AppTheme.fontXS,
                color: AppTheme.textMutedColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: AppTheme.fontBase,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDarkColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Rejected State ───────────────────────────────────────────────────────────
  Widget _buildRejectedState() {
    final note = _existingRequest?['reviewNote'] as String? ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_outlined,
                size: 64,
                color: AppTheme.errorColor,
              ),
            ).animate().scale(duration: 600.ms),
            const SizedBox(height: AppTheme.spaceLG),
            const Text(
              'Request Rejected',
              style: TextStyle(
                fontSize: AppTheme.font2XL,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textDarkColor,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: AppTheme.spaceMD),
            if (note.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  note,
                  style: const TextStyle(
                    fontSize: AppTheme.fontBase,
                    color: AppTheme.textDarkColor,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: AppTheme.spaceLG),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child: const Text(
                  'Re-Apply',
                  style: TextStyle(
                    fontSize: AppTheme.fontMD,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  // ── Form State ───────────────────────────────────────────────────────────────
  Widget _buildForm() {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.08),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_business_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join as a Hoster',
                          style: TextStyle(
                            fontSize: AppTheme.fontLG,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fill in your details. Our team will review and approve your request.',
                          style: TextStyle(
                            fontSize: AppTheme.fontSM,
                            color: AppTheme.textLightColor,
                            fontFamily: AppTheme.fontFamily,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: AppTheme.spaceMD),

            // Form fields
            _buildLabel('Full Name'),
            _buildTextField(
              controller: _nameController,
              hint: 'Your full name',
              icon: Icons.person_outline,
              validator:
                  (v) =>
                      (v == null || v.isEmpty)
                          ? 'Please enter your name'
                          : null,
            ),
            const SizedBox(height: AppTheme.spaceMD),

            _buildLabel('Phone Number'),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    color: AppTheme.textMutedColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spaceSM),
                  Text(
                    phone.isEmpty ? 'Not available' : phone,
                    style: const TextStyle(
                      fontSize: AppTheme.fontBase,
                      color: AppTheme.textLightColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),

            _buildLabel('Email Address'),
            _buildTextField(
              controller: _emailController,
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMD),

            _buildLabel('Business Name (Optional)'),
            _buildTextField(
              controller: _businessNameController,
              hint: 'e.g. Sunrise PG & Hostel',
              icon: Icons.business_outlined,
              required: false,
            ),
            const SizedBox(height: AppTheme.spaceMD),

            _buildLabel('Property Type'),
            DropdownButtonFormField<String>(
              value: _selectedPropertyType,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(
                  Icons.home_outlined,
                  color: AppTheme.primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  borderSide: BorderSide.none,
                ),
              ),
              items:
                  _propertyTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
              onChanged: (v) => setState(() => _selectedPropertyType = v!),
            ),
            const SizedBox(height: AppTheme.spaceMD),

            // Terms
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: CheckboxListTile(
                value: _isTermsAccepted,
                onChanged: (v) => setState(() => _isTermsAccepted = v!),
                title: const Text(
                  'I agree to the Terms & Conditions and Privacy Policy',
                  style: TextStyle(
                    fontSize: AppTheme.fontSM,
                    color: AppTheme.textDarkColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                activeColor: AppTheme.primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSM,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: AppTheme.fontMD,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                            color: Colors.white,
                          ),
                        ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: AppTheme.spaceLG),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppTheme.fontSM,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDarkColor,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: AppTheme.fontBase,
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.textDarkColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
      validator:
          validator ??
          (required
              ? (v) =>
                  (v == null || v.isEmpty) ? 'This field is required' : null
              : null),
    );
  }
}
