import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/document_upload.dart';

class HostVerificationStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const HostVerificationStep({
    super.key,
    required this.onContinue,
    this.initialData,
  });

  @override
  State<HostVerificationStep> createState() => _HostVerificationStepState();
}

class _HostVerificationStepState extends State<HostVerificationStep> {
  String? _aadhaarUrl;
  String? _panUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null &&
        widget.initialData!['verification'] != null) {
      final verif = widget.initialData!['verification'] as Map<String, dynamic>;
      _aadhaarUrl = verif['aadhaarUrl'];
      _panUrl = verif['panUrl'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Help us verify your identity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This builds trust with tenants',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textLightColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 32),
          RealtimeDocumentUpload(
            title: 'Aadhaar Card',
            subtitle: 'Upload front side',
            initialUrl: _aadhaarUrl,
            onUploadComplete: (url) => setState(() => _aadhaarUrl = url),
          ),
          const SizedBox(height: 16),
          RealtimeDocumentUpload(
            title: 'PAN Card',
            subtitle: 'Upload PAN card',
            initialUrl: _panUrl,
            onUploadComplete: (url) => setState(() => _panUrl = url),
          ),
          const Spacer(),
          Container(
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
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Your information is secure and encrypted',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkColor,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You can add more documents later',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textLightColor,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_aadhaarUrl != null && _panUrl != null)
                      ? () {
                        widget.onContinue({
                          'verification': {
                            'aadhaarUrl': _aadhaarUrl,
                            'panUrl': _panUrl,
                            'isVerified': true,
                          },
                        });
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                disabledBackgroundColor: AppTheme.successColor.withValues(
                  alpha: 0.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
