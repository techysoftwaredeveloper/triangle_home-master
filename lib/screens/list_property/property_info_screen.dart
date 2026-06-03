import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/image_upload.dart';
import 'package:triangle_home/widgets/list_property/toggle_buttons.dart';

class PropertyInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const PropertyInfoScreen({
    super.key,
    required this.onContinue,
    this.initialData,
  });

  @override
  State<PropertyInfoScreen> createState() => _PropertyInfoScreenState();
}

class _PropertyInfoScreenState extends State<PropertyInfoScreen> {
  String _selectedGender = 'Men';
  String _selectedSharing = 'Double';
  final List<String> _selectedImageUrls = [];

  @override
  void initState() {
    super.initState();
    final prefs = widget.initialData?['preferences'] ?? {};
    _selectedGender = prefs['gender'] ?? 'Men';
    _selectedSharing = prefs['sharing'] ?? 'Double';
    final images = widget.initialData?['image_urls'] as List?;
    if (images != null) {
      _selectedImageUrls.addAll(images.cast<String>());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.textDarkColor,
            ),
          ).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: 8),
          const Text(
            'Help us categorize your accommodation for the right students.',
            style: TextStyle(color: AppTheme.textLightColor, fontSize: 14),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),

          const Text(
            'GENDER PREFERENCE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMutedColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          CustomToggleButtons(
            options: const ['Men', 'Women', 'Anyone'],
            selectedOption: _selectedGender,
            onOptionSelected: (val) => setState(() => _selectedGender = val),
          ),

          const SizedBox(height: 24),
          const Text(
            'ROOM CATEGORY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMutedColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          CustomToggleButtons(
            options: const ['Single', 'Double', 'Triple', 'Others'],
            selectedOption: _selectedSharing,
            onOptionSelected: (val) => setState(() => _selectedSharing = val),
          ),

          const SizedBox(height: 32),
          const Text(
            'PREMISES IMAGES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMutedColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ImageUploadWidget(
            imageUrls: _selectedImageUrls,
            onImageUploaded:
                (url) => setState(() => _selectedImageUrls.add(url)),
            onImageRemoved:
                (index) => setState(() => _selectedImageUrls.removeAt(index)),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _selectedImageUrls.isEmpty
                      ? null
                      : () {
                        widget.onContinue({
                          'preferences': {
                            'gender': _selectedGender,
                            'sharing': _selectedSharing,
                          },
                          'image_urls': _selectedImageUrls,
                        });
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text(
                'Continue to Pricing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
