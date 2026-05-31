import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:triangle_home/theme/app_theme.dart';

class ImageUploadWidget extends StatefulWidget {
  final List<File> selectedImages;
  final Function(File) onImageAdded;
  final Function(int) onImageRemoved;

  const ImageUploadWidget({
    super.key,
    required this.selectedImages,
    required this.onImageAdded,
    required this.onImageRemoved,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      widget.onImageAdded(File(image.path));
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
          itemCount: widget.selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.selectedImages.length) {
              return _buildAddButton();
            }
            return _buildImagePreview(index);
          },
        ),
        if (widget.selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Text(
              '${widget.selectedImages.length} images selected',
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
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add Photo',
              style: TextStyle(
                color: AppTheme.primaryColor,
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

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: FileImage(widget.selectedImages[index]),
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
              child: const Icon(Icons.close_rounded, color: AppTheme.errorColor, size: 16),
            ),
          ),
        ),
      ],
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }
}
