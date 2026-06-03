import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class PricingInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> propertyData;

  const PricingInfoScreen({
    super.key,
    required this.onContinue,
    required this.propertyData,
  });

  @override
  State<PricingInfoScreen> createState() => _PricingInfoScreenState();
}

class _PricingInfoScreenState extends State<PricingInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _rentController;
  late TextEditingController _depositController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _localityController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rentController = TextEditingController(
      text: widget.propertyData['monthlyRent'] ?? '',
    );
    _depositController = TextEditingController(
      text: widget.propertyData['securityDeposit'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.propertyData['address'] ?? '',
    );
    _cityController = TextEditingController(
      text: widget.propertyData['city'] ?? '',
    );
    _localityController = TextEditingController(
      text: widget.propertyData['locality'] ?? '',
    );
  }

  @override
  void dispose() {
    _rentController.dispose();
    _depositController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _localityController.dispose();
    super.dispose();
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User session expired. Please login again.';

      final firebaseService = FirebaseService();

      // 1. Upload Images to Firebase Storage
      final List<dynamic> imageFiles =
          widget.propertyData['temp_image_files'] ?? [];
      final List<String> imageUrls = await firebaseService.uploadImages(
        imageFiles.cast(),
      );

      // 2. Prepare Final Data
      final finalData = {
        ...widget.propertyData,
        'monthlyRent': _rentController.text,
        'securityDeposit': _depositController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'locality': _localityController.text,
        'images': imageUrls,
        'hosterId': user.uid,
        'hosterPhone': user.phoneNumber,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Cleanup temp files before firestore write
      finalData.remove('temp_image_files');

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('properties').add(finalData);

      // 4. Clear local draft
      await IsarService().clearPropertyDraft(user.uid);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Listing Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your property has been sent for admin approval. You will be notified once it goes live.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textLightColor),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Back to Dashboard',
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
              'Final Steps',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textDarkColor,
              ),
            ).animate().fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 8),
            const Text(
              'Set your pricing and physical location.',
              style: TextStyle(color: AppTheme.textLightColor, fontSize: 14),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Monthly Rent',
                    controller: _rentController,
                    required: true,
                    keyboardType: TextInputType.number,
                    prefix: '₹ ',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InputField(
                    label: 'Security Deposit',
                    controller: _depositController,
                    required: true,
                    keyboardType: TextInputType.number,
                    prefix: '₹ ',
                  ),
                ),
              ],
            ),

            InputField(
              label: 'Full Address',
              controller: _addressController,
              required: true,
              maxLines: 3,
              hintText: 'Building No, Street Name...',
            ),

            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Locality',
                    controller: _localityController,
                    required: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InputField(
                    label: 'City',
                    controller: _cityController,
                    required: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProperty,
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
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Submit for Approval',
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
      ),
    );
  }
}
