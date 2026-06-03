import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/document_upload.dart';

class DocumentsStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const DocumentsStep({super.key, required this.onContinue, this.initialData});

  @override
  State<DocumentsStep> createState() => _DocumentsStepState();
}

class _DocumentsStepState extends State<DocumentsStep> {
  String? _ownershipUrl;
  String? _utilityUrl;
  String? _additionalUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null &&
        widget.initialData!['documents'] != null) {
      final docs = widget.initialData!['documents'] as Map<String, dynamic>;
      _ownershipUrl = docs['ownershipUrl'];
      _utilityUrl = docs['utilityUrl'];
      _additionalUrl = docs['additionalUrl'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload necessary proofs to verify ownership',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textLightColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 32),
          RealtimeDocumentUpload(
            title: 'Property Ownership Proof *',
            subtitle: 'Property tax receipt / Ownership proof',
            initialUrl: _ownershipUrl,
            onUploadComplete: (url) => setState(() => _ownershipUrl = url),
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 16),
          RealtimeDocumentUpload(
            title: 'Utility Bill / Address Proof *',
            subtitle: 'Recent bill (Within last 3 months)',
            initialUrl: _utilityUrl,
            onUploadComplete: (url) => setState(() => _utilityUrl = url),
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 16),
          RealtimeDocumentUpload(
            title: 'Additional Documents (Optional)',
            subtitle: 'Rental Agreement / NOC',
            initialUrl: _additionalUrl,
            onUploadComplete: (url) => setState(() => _additionalUrl = url),
            icon: Icons.note_add_outlined,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_ownershipUrl != null && _utilityUrl != null)
                      ? () {
                        widget.onContinue({
                          'documents': {
                            'ownershipUrl': _ownershipUrl,
                            'utilityUrl': _utilityUrl,
                            'additionalUrl': _additionalUrl,
                            'isCompleted': true,
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
                'Review & Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
