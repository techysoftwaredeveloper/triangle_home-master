import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/document_upload.dart';

class KycPanStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> initialData;

  const KycPanStep({super.key, required this.onContinue, required this.initialData});

  @override
  State<KycPanStep> createState() => _KycPanStepState();
}

class _KycPanStepState extends State<KycPanStep> {
  String? _panUrl;

  @override
  void initState() {
    super.initState();
    _panUrl = widget.initialData['panUrl'];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAN Card Verification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          const Text(
            'PAN is required for financial compliance and payouts.',
            style: TextStyle(color: AppTheme.textLightColor),
          ),
          const SizedBox(height: 32),
          RealtimeDocumentUpload(
            title: 'PAN Card Photo',
            subtitle: 'Upload the front side of your PAN',
            initialUrl: _panUrl,
            onUploadComplete: (url) => setState(() => _panUrl = url),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _panUrl != null
                ? () => widget.onContinue({'panUrl': _panUrl})
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
