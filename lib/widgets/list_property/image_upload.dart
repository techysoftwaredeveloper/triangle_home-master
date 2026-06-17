import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class ImageUploadWidget extends StatefulWidget {
  final List<String> imageUrls;
  final Function(String) onImageUploaded;
  final Function(int) onImageRemoved;
  final Color? activeColor;

  const ImageUploadWidget({
    super.key,
    required this.imageUrls,
    required this.onImageUploaded,
    required this.onImageRemoved,
    this.activeColor,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final Set<int> _uploadingIndices = {};

  Future<void> _pickImage() async {
    final status = Platform.isIOS 
        ? await Permission.photos.request() 
        : await Permission.storage.request();
        
    if (status.isDenied || status.isPermanentlyDenied) {
      if (Platform.isAndroid) {
        final photoStatus = await Permission.photos.request();
        if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gallery access is required to add property photos')),
            );
          }
          if (photoStatus.isPermanentlyDenied) openAppSettings();
          return;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery access is required to add property photos')),
          );
        }
        if (status.isPermanentlyDenied) openAppSettings();
        return;
      }
    }

    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      final firebaseService = FirebaseService();
      for (var xFile in images) {
        final index = widget.imageUrls.length + _uploadingIndices.length;
        setState(() => _uploadingIndices.add(index));

        try {
          final url = await firebaseService.uploadFile(File(xFile.path));
          widget.onImageUploaded(url);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
          }
        } finally {
          setState(() => _uploadingIndices.remove(index));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: widget.imageUrls.length + _uploadingIndices.length + 1,
          itemBuilder: (context, index) {
            if (index < widget.imageUrls.length) {
              return _buildImagePreview(index);
            } else if (index <
                widget.imageUrls.length + _uploadingIndices.length) {
              return _buildLoadingPreview();
            } else {
              return _buildAddButton();
            }
          },
        ),
        if (widget.imageUrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Text(
              '${widget.imageUrls.length} images uploaded',
              style: const TextStyle(
                color: AppTheme.textMutedColor,
                fontSize: 12,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    final color = widget.activeColor ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_a_photo_rounded, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.successColor,
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(widget.imageUrls[index]),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => widget.onImageRemoved(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppTheme.errorColor,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }
}
