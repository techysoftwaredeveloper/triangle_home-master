import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/document_upload.dart';

class KycAadhaarStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> initialData;

  const KycAadhaarStep({super.key, required this.onContinue, required this.initialData});

  @override
  State<KycAadhaarStep> createState() => _KycAadhaarStepState();
}

class _KycAadhaarStepState extends State<KycAadhaarStep> {
  String? _aadhaarFrontUrl;
  String? _aadhaarBackUrl;

  @override
  void initState() {
    super.initState();
    _aadhaarFrontUrl = widget.initialData['aadhaarFront'];
    _aadhaarBackUrl = widget.initialData['aadhaarBack'];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aadhaar Verification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please upload a clear photo of your Aadhaar card.',
            style: TextStyle(color: AppTheme.textLightColor),
          ),
          const SizedBox(height: 32),
          RealtimeDocumentUpload(
            title: 'Front Side',
            subtitle: 'Ensure all 4 corners are visible',
            initialUrl: _aadhaarFrontUrl,
            onUploadComplete: (url) => setState(() => _aadhaarFrontUrl = url),
          ),
          const SizedBox(height: 16),
          RealtimeDocumentUpload(
            title: 'Back Side',
            subtitle: 'Ensure address is readable',
            initialUrl: _aadhaarBackUrl,
            onUploadComplete: (url) => setState(() => _aadhaarBackUrl = url),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_aadhaarFrontUrl != null && _aadhaarBackUrl != null)
                ? () => widget.onContinue({
                  'aadhaarFront': _aadhaarFrontUrl,
                  'aadhaarBack': _aadhaarBackUrl,
                })
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
