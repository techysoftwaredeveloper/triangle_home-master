import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class RealtimeDocumentUpload extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? initialUrl;
  final Function(String) onUploadComplete;
  final IconData? icon;

  const RealtimeDocumentUpload({
    super.key,
    required this.title,
    required this.subtitle,
    this.initialUrl,
    required this.onUploadComplete,
    this.icon,
  });

  @override
  State<RealtimeDocumentUpload> createState() => _RealtimeDocumentUploadState();
}

class _RealtimeDocumentUploadState extends State<RealtimeDocumentUpload> {
  bool _isUploading = false;
  String? _currentUrl;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
  }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.1; // Starting
        });

        final file = File(result.files.single.path!);
        final firebaseService = FirebaseService();

        // Use specialized upload for verification documents
        final url = await firebaseService.uploadVerificationFile(file);

        setState(() {
          _currentUrl = url;
          _isUploading = false;
          _uploadProgress = 1.0;
        });

        widget.onUploadComplete(url);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploaded = _currentUrl != null;

    return InkWell(
      onTap: _isUploading ? null : _pickAndUpload,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon ?? Icons.badge_outlined,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUploaded
                        ? (_currentUrl!.toLowerCase().contains('.pdf')
                            ? 'PDF Document uploaded'
                            : 'Image uploaded successfully')
                        : widget.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isUploaded
                              ? AppTheme.successColor
                              : AppTheme.textLightColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
            if (_isUploading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.successColor,
                ),
              )
            else if (isUploaded)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successColor,
                size: 24,
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.file_upload_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
