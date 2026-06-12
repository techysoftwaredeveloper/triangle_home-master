import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';
import 'package:triangle_home/widgets/list_property/document_upload.dart';

class HostProfileStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const HostProfileStep({
    super.key,
    required this.onContinue,
    this.initialData,
  });

  @override
  State<HostProfileStep> createState() => _HostProfileStepState();
}

class _HostProfileStepState extends State<HostProfileStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedHostType = 'Property Owner';

  // Verification state
  bool _isHostVerified = false;
  String? _aadhaarUrl;
  String? _panUrl;
  String? _registrationCertificateUrl;
  String? _agencyLicenseUrl;

  final List<Map<String, dynamic>> _hostTypes = [
    {'label': 'Property Owner', 'icon': Icons.home_rounded},
    {'label': 'Hostel Operator', 'icon': Icons.business_rounded},
    {'label': 'PG Owner', 'icon': Icons.apartment_rounded},
    {'label': 'Property Manager', 'icon': Icons.person_pin_rounded},
    {'label': 'Real Estate Agency', 'icon': Icons.corporate_fare_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData?['hostProfile'] ?? {};
    _nameController = TextEditingController(text: data['name'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _selectedHostType = data['hostType'] ?? 'Property Owner';

    final verif = widget.initialData?['verification'] as Map<String, dynamic>? ?? {};
    _aadhaarUrl = verif['aadhaarUrl'];
    _panUrl = verif['panUrl'];
    _registrationCertificateUrl = verif['registrationCertificateUrl'];
    _agencyLicenseUrl = verif['agencyLicenseUrl'];
    _isHostVerified = widget.initialData?['isHostVerified'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildVerificationSection() {
    if (_selectedHostType == 'Property Owner') {
      if (_isHostVerified) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Account Identity Verified',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDarkColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your Aadhaar and PAN cards are already verified and securely stored in your hoster profile.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please verify your identity to list properties. This builds trust with residents.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLightColor,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 16),
            RealtimeDocumentUpload(
              title: 'Aadhaar Card',
              subtitle: 'Upload Aadhaar front side',
              initialUrl: _aadhaarUrl,
              onUploadComplete: (url) => setState(() => _aadhaarUrl = url),
            ),
            const SizedBox(height: 16),
            RealtimeDocumentUpload(
              title: 'PAN Card',
              subtitle: 'Upload PAN card front side',
              initialUrl: _panUrl,
              onUploadComplete: (url) => setState(() => _panUrl = url),
            ),
          ],
        );
      }
    } else if (_selectedHostType == 'Hostel Operator' || _selectedHostType == 'PG Owner') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please upload your PG / Hostel Registration Certificate as compliance proof.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLightColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 16),
          RealtimeDocumentUpload(
            title: 'PG / Hostel Registration Certificate',
            subtitle: 'Upload registration/license certificate',
            initialUrl: _registrationCertificateUrl,
            onUploadComplete: (url) => setState(() => _registrationCertificateUrl = url),
            icon: Icons.corporate_fare_rounded,
          ),
        ],
      );
    } else {
      // Property Manager or Real Estate Agency
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please upload your Agency License or Owner Authorization Letter.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLightColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 16),
          RealtimeDocumentUpload(
            title: 'Agency License / Authorization Letter',
            subtitle: 'Upload legal document proving authorization',
            initialUrl: _agencyLicenseUrl,
            onUploadComplete: (url) => setState(() => _agencyLicenseUrl = url),
            icon: Icons.description_outlined,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 20),
            InputField(
              label: 'Full Name',
              controller: _nameController,
              required: true,
              hintText: 'Enter your legal name',
            ),
            InputField(
              label: 'Email Address',
              controller: _emailController,
              required: true,
              keyboardType: TextInputType.emailAddress,
              hintText: 'yourname@example.com',
            ),
            InputField(
              label: 'Phone Number',
              controller: _phoneController,
              required: true,
              keyboardType: TextInputType.phone,
              prefix: '+91 ',
            ),
            const SizedBox(height: 24),
            const Text(
              'Host Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _hostTypes.length,
              itemBuilder: (context, index) {
                final type = _hostTypes[index];
                final isSelected = _selectedHostType == type['label'];
                return InkWell(
                  onTap: () => setState(() => _selectedHostType = type['label']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.successColor.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.successColor
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          type['icon'],
                          color: isSelected
                              ? AppTheme.successColor
                              : AppTheme.textMutedColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            type['label'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.successColor
                                  : AppTheme.textDarkColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Verification Documents',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 12),
            _buildVerificationSection(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;

                  // Document validation
                  if (_selectedHostType == 'Property Owner') {
                    if (!_isHostVerified && (_aadhaarUrl == null || _panUrl == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please upload both Aadhaar and PAN cards.')),
                      );
                      return;
                    }
                  } else if (_selectedHostType == 'Hostel Operator' || _selectedHostType == 'PG Owner') {
                    if (_registrationCertificateUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please upload your PG / Hostel Registration Certificate.')),
                      );
                      return;
                    }
                  } else if (_selectedHostType == 'Property Manager' || _selectedHostType == 'Real Estate Agency') {
                    if (_agencyLicenseUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please upload your Agency License or Authorization Letter.')),
                      );
                      return;
                    }
                  }

                  // Store data and proceed
                  final Map<String, dynamic> verificationData = {
                    'isVerified': _isHostVerified,
                  };
                  if (_selectedHostType == 'Property Owner') {
                    if (!_isHostVerified) {
                      verificationData['aadhaarUrl'] = _aadhaarUrl;
                      verificationData['panUrl'] = _panUrl;
                    }
                  } else if (_selectedHostType == 'Hostel Operator' || _selectedHostType == 'PG Owner') {
                    verificationData['registrationCertificateUrl'] = _registrationCertificateUrl;
                  } else if (_selectedHostType == 'Property Manager' || _selectedHostType == 'Real Estate Agency') {
                    verificationData['agencyLicenseUrl'] = _agencyLicenseUrl;
                  }

                  widget.onContinue({
                    'hostProfile': {
                      'name': _nameController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                      'hostType': _selectedHostType,
                    },
                    'verification': verificationData,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
