import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/image_upload.dart';

class PhotosStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const PhotosStep({super.key, required this.onContinue, this.initialData});

  @override
  State<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends State<PhotosStep> {
  final List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData?['image_urls'];
    if (data != null && data is List) {
      _imageUrls.addAll(data.cast<String>());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add high quality photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
          const SizedBox(height: 8),
          const Text('Add at least 5 photos for better visibility', style: TextStyle(fontSize: 12, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ImageUploadWidget(
                imageUrls: _imageUrls,
                onImageUploaded: (url) => setState(() => _imageUrls.add(url)),
                onImageRemoved: (index) => setState(() => _imageUrls.removeAt(index)),
                activeColor: AppTheme.successColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _imageUrls.length < 3 ? null : () {
                widget.onContinue({
                  'image_urls': _imageUrls,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                disabledBackgroundColor: AppTheme.successColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _imageUrls.length < 3 ? 'Upload at least 3 photos' : 'Continue', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit')
              ),
            ),
          ),
        ],
      ),
    );
  }
}
