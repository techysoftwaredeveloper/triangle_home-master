import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/screens/profile/verification_center_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';

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
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _businessNameController = TextEditingController();

  // State Variables
  String? _selectedGender = 'Male';
  DateTime? _dob = DateTime(1988, 5, 12);
  String? _selectedState = 'Kerala';
  String _selectedPropertyType = 'Hostel';
  bool _isSaving = false;
  
  // Preferences
  List<String> _preferredTenants = ['Students'];
  String? _prefGender = 'Any';

  final List<String> _propertyTypes = [
    'Hostel',
    'PG Accommodation',
    'Apartment',
    'Guest House',
  ];

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Assam', 'Bihar', 'Goa', 'Gujarat', 'Karnataka', 
    'Kerala', 'Maharashtra', 'Punjab', 'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'West Bengal'
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.phoneNumber;
    // Mocking some data for the "Partner" look as per design
    _nameController.text = 'JIBIN N ANTONY';
    _emailController.text = 'jibinnantony@gmail.com';
    _address1Controller.text = 'Sunrise PG, Near Cochin University';
    _address2Controller.text = 'Pulinchodu, Kalamassery';
    _cityController.text = 'Kochi';
    _pincodeController.text = '682022';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  double _calculateCompletion() => 0.78;

  @override
  Widget build(BuildContext context) {
    final completion = _calculateCompletion();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildStatusDashboard(completion).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                          const SizedBox(height: 32),
                          _buildPhotoSection().animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildBasicInfoSection().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildContactSection().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildAddressSection().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildBusinessSection().animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildIdentitySection().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 32),
                          _buildPreferencesSection().animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 160), // Space for bottom button
                        ],
                      ),
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

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.successColor,
      automaticallyImplyLeading: false,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: const Text(
          'Owner Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.successColor, const Color(0xFF10B981)],
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Partner with\nTriangle Homes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage properties & reach tenants',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),
            ),
            Positioned(
              right: -30,
              bottom: 20,
              child: Opacity(
                opacity: 0.3,
                child: Image.network(
                  'https://img.freepik.com/free-vector/city-skyline-concept-illustration_114360-892.jpg',
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDashboard(double completion) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: Colors.grey[50]!),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 70, width: 70,
                    child: CircularProgressIndicator(
                      value: completion,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                    ),
                  ),
                  Text(
                    '${(completion * 100).toInt()}%',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit'),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile Completion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
                    const SizedBox(height: 4),
                    Text(
                      completion == 1.0 ? 'Your profile is ready!' : 'Complete your profile to start hosting',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor, fontFamily: 'Outfit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVerifIndicator('Email', true),
              _buildVerifIndicator('Phone', true), 
              _buildVerifIndicator('Identity', false, isPending: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifIndicator(String label, bool isDone, {bool isPending = false}) {
    final Color color = isDone ? Colors.green : (isPending ? Colors.orange : Colors.grey[400] ?? Colors.grey);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check_circle : (isPending ? Icons.pending : Icons.circle_outlined), 
            size: 18, 
            color: color
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'Outfit')),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text('Profile Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2), width: 2),
                    ),
                    child: const Center(child: Icon(Icons.person, size: 48, color: Color(0xFF4CAF50))),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6), 
                    decoration: BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14)
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add your photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
                    const SizedBox(height: 4),
                    const Text('A clear photo builds trust with tenants.', style: TextStyle(fontSize: 12, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  side: const BorderSide(color: AppTheme.successColor), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                ),
                child: const Text('Edit Photo', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 20),
          child: Text('Basic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
        ),
        _buildTextField('Full Name *', _nameController, Icons.person_outline_rounded),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text('Gender *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
            ),
            Row(
              children: ['Male', 'Female', 'Other'].map((g) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedGender = g),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedGender == g ? AppTheme.successColor : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _selectedGender == g ? AppTheme.successColor : Colors.grey[200]!),
                        boxShadow: _selectedGender == g ? [BoxShadow(color: AppTheme.successColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
                      ),
                      child: Center(
                        child: Text(
                          g, 
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: _selectedGender == g ? Colors.white : AppTheme.textLightColor,
                            fontFamily: 'Outfit'
                          )
                        )
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildDateField('Date of Birth *', _dob, (d) => setState(() => _dob = d)),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 20),
          child: Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
        ),
        _buildTextField('Phone Number *', _phoneController, Icons.phone_android_outlined, isVerified: true, readOnly: true),
        const SizedBox(height: 24),
        _buildTextField('Email Address *', _emailController, Icons.email_outlined, isVerified: true, readOnly: true),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 20),
          child: Text('Address Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
        ),
        _buildTextField('Address Line 1 *', _address1Controller, Icons.location_on_rounded),
        const SizedBox(height: 20),
        _buildTextField('Address Line 2 (Optional)', _address2Controller, Icons.location_on_rounded, isRequired: false),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('City *', _cityController, Icons.apartment_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdownField('State *', _indianStates, _selectedState, (v) => setState(() => _selectedState = v!))),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField('Pincode *', _pincodeController, Icons.pin_drop_rounded, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildBusinessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 20),
          child: Text('Business Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
        ),
        _buildTextField('Business Name (Optional)', _businessNameController, Icons.business_center_rounded, isRequired: false),
        const SizedBox(height: 20),
        _buildDropdownField('Primary Property Type', _propertyTypes, _selectedPropertyType, (v) => setState(() => _selectedPropertyType = v!)),
      ],
    );
  }

  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('Identity Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationCenterScreen())),
              child: const Row(children: [Text('Details', style: TextStyle(fontSize: 12, color: AppTheme.successColor, fontWeight: FontWeight.bold, fontFamily: 'Outfit')), Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.successColor)]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildIdentityTile('Aadhaar Card', 'XXXX XXXX 1234', 'Pending Review', Colors.orange, 'https://cdn-icons-png.flaticon.com/512/11104/11104118.png'),
        const SizedBox(height: 12),
        _buildIdentityTile('PAN Card', 'ABCDE1234F', 'Verified', Colors.green, 'https://cdn-icons-png.flaticon.com/512/10703/10703478.png'),
      ],
    );
  }

  Widget _buildIdentityTile(String title, String subtitle, String status, Color color, String iconUrl) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationCenterScreen())),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Image.network(iconUrl, width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.badge, size: 24, color: Colors.grey)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(status == 'Verified' ? Icons.check_circle_rounded : Icons.pending_rounded, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                ],
              ),
            ),
          ],
        ),
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
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('Host Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
            ),
            TextButton(
              onPressed: () {}, 
              child: const Row(children: [Text('Settings', style: TextStyle(fontSize: 12, color: AppTheme.successColor, fontWeight: FontWeight.bold, fontFamily: 'Outfit')), Icon(Icons.settings_rounded, size: 14, color: AppTheme.successColor)])
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPreferenceCard(
                'Tenants',
                ['Students', 'Pros', 'Families'],
                _preferredTenants,
                (v) => setState(() {
                  if (_preferredTenants.contains(v)) {
                    _preferredTenants.remove(v);
                  } else {
                    _preferredTenants.add(v);
                  }
                }),
                [Icons.school_rounded, Icons.work_rounded, Icons.people_rounded],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPreferenceCard(
                'Gender',
                ['Male', 'Female', 'Any'],
                _prefGender != null ? [_prefGender!] : [],
                (v) => setState(() => _prefGender = v),
                [Icons.person_rounded, Icons.person_pin_rounded, Icons.people_alt_rounded],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferenceCard(String title, List<String> options, List<String> current, Function(String) onTap, List<IconData> icons) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(options.length, (i) {
              final isSelected = current.contains(options[i]);
              return InkWell(
                onTap: () => onTap(options[i]),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.successColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC), 
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: AppTheme.successColor.withValues(alpha: 0.2)) : null,
                      ),
                      child: Icon(icons[i], size: 20, color: isSelected ? AppTheme.successColor : Colors.grey[400]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      options[i], 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
                        color: isSelected ? AppTheme.successColor : AppTheme.textLightColor,
                        fontFamily: 'Outfit'
                      )
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
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white, 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -10))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor, 
            minimumSize: const Size(double.infinity, 60), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 8,
            shadowColor: AppTheme.successColor.withValues(alpha: 0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSaving)
                const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              else
                const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(
                _isSaving ? 'Saving...' : 'Save Profile', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Outfit')
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 800.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isVerified = false, bool readOnly = false, TextInputType? keyboardType, bool isRequired = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
        ),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Outfit', color: AppTheme.textDarkColor),
          validator: (v) => (isRequired && (v == null || v.isEmpty)) ? 'Required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.successColor, size: 22),
            suffixIcon: isVerified ? Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Verified', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)), SizedBox(width: 4), Icon(Icons.check_circle, color: Colors.green, size: 14)]),
            ) : null,
            filled: true, 
            fillColor: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.successColor, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1)),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
        const SizedBox(height: 8),
        Container(
          height: 56, padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: value, items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Outfit')))).toList(), onChanged: onChanged,
            decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.map_outlined, color: AppTheme.successColor, size: 20)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? current, Function(DateTime) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: current ?? DateTime(1990), firstDate: DateTime(1950), lastDate: DateTime.now());
            if (picked != null) onSelected(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppTheme.successColor, size: 20),
                const SizedBox(width: 12),
                Text(current != null ? DateFormat('dd MMM yyyy').format(current) : 'Select Date', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.textDarkColor)),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _isSaving = false); return; }
    try {
      final hosterData = {
        'name': _nameController.text.trim(), 'phone': _phoneController.text.trim(), 'email': _emailController.text.trim(),
        'gender': _selectedGender, 'dob': _dob != null ? Timestamp.fromDate(_dob!) : null,
        'addressLine1': _address1Controller.text.trim(), 'addressLine2': _address2Controller.text.trim(),
        'city': _cityController.text.trim(), 'state': _selectedState, 'pincode': _pincodeController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'hoster', 'status': 'approved', 'info': hosterData,
        'host_preferences': { 'tenantTypes': _preferredTenants, 'genderPreference': _prefGender },
        'permissions': { 'is_admin': false }, 'is_active': true, 'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      if (widget.onCompleteNavigateTo != null) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => widget.onCompleteNavigateTo!), (route) => false);
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => ListPropertyScreen()), (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}
