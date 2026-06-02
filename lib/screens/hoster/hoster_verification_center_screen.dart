import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:triangle_home/widgets/document_capture_camera.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:triangle_home/theme/app_theme.dart';

class HosterVerificationCenterScreen extends StatefulWidget {
  const HosterVerificationCenterScreen({super.key});

  @override
  State<HosterVerificationCenterScreen> createState() => _HosterVerificationCenterScreenState();
}

class _HosterVerificationCenterScreenState extends State<HosterVerificationCenterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  final Color _successGreen = AppTheme.successColor;
  final Color _accentBlue = const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please login first')));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = snapshot.data?.data();
        final verif = userData?['verification'] as Map? ?? {};
        final info = userData?['info'] as Map? ?? {};

        if (user.emailVerified && verif['emailVerified'] != true) {
          _updateVerification('emailVerified', true);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDarkColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Partner Verification',
              style: TextStyle(color: AppTheme.textDarkColor, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHeader(verif),
                    const SizedBox(height: 32),
                    
                    _buildSectionTitle('Contact Verification'),
                    _buildVerificationTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Mobile Number',
                      subtitle: info['phone'] ?? user.phoneNumber ?? 'Not provided',
                      isVerified: true, // Phone is verified during login usually
                      onTap: null,
                    ),
                    _buildVerificationTile(
                      icon: Icons.email_rounded,
                      title: 'Email Address',
                      subtitle: user.email ?? 'Not provided',
                      isVerified: user.emailVerified,
                      onTap: user.emailVerified ? null : () => _verifyEmail(user.email),
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle('Identity Documents'),
                    
                    _buildDocumentUploadCard(
                      title: 'Aadhaar Card',
                      subtitle: 'Front and Back side of your Aadhaar',
                      fieldPrefix: 'govId',
                      verifData: verif,
                      icon: Icons.assignment_ind_rounded,
                    ),
                    
                    _buildDocumentUploadCard(
                      title: 'PAN Card',
                      subtitle: 'Front side of your PAN Card',
                      fieldPrefix: 'pan',
                      verifData: verif,
                      icon: Icons.credit_card_rounded,
                      showBackSide: false,
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle('Business & Property Proof'),
                    
                    _buildDocumentUploadCard(
                      title: 'Business Proof',
                      subtitle: 'GST, Trade License or Shop Act',
                      fieldPrefix: 'businessProof',
                      verifData: verif,
                      icon: Icons.business_center_rounded,
                      showBackSide: false,
                      onTypeTap: () => _showBusinessProofOptions(),
                      selectedType: verif['businessProofType'],
                    ),
                    
                    _buildDocumentUploadCard(
                      title: 'Property Ownership',
                      subtitle: 'Electricity Bill, Tax Receipt or Lease',
                      fieldPrefix: 'propertyProof',
                      verifData: verif,
                      icon: Icons.home_work_rounded,
                      showBackSide: false,
                      onTypeTap: () => _showPropertyProofOptions(),
                      selectedType: verif['propertyProofType'],
                    ),

                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.verified_user_rounded, color: _successGreen.withValues(alpha: 0.5), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Verified Partner Badge',
                            style: TextStyle(color: _successGreen, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Earn trust from potential tenants',
                            style: TextStyle(color: AppTheme.textLightColor, fontSize: 12, fontFamily: 'Outfit'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: const Center(child: CircularProgressIndicator(color: AppTheme.successColor)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit'),
      ),
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required String fieldPrefix,
    required Map verifData,
    required IconData icon,
    bool showBackSide = true,
    VoidCallback? onTypeTap,
    String? selectedType,
  }) {
    final status = verifData['${fieldPrefix}Status'];
    final isVerified = verifData['${fieldPrefix}Verified'] == true;
    final rejectReason = verifData['${fieldPrefix}RejectReason'] as String?;
    
    Color statusColor = AppTheme.warningColor;
    String statusText = 'Pending';

    if (isVerified) {
      statusColor = _successGreen;
      statusText = 'Verified';
    } else if (status == 'pending') {
      statusColor = const Color(0xFF2563EB);
      statusText = 'In Review';
    } else if (status == 'rejected') {
      statusColor = AppTheme.errorColor;
      statusText = 'Rejected';
    } else if (verifData['${fieldPrefix}FrontUrl'] == null) {
      statusColor = Colors.grey;
      statusText = 'Not Started';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: (isVerified ? _successGreen : _accentBlue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: isVerified ? _successGreen : _accentBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
                    Text(selectedType ?? subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
              ),
            ],
          ),
          if (!isVerified && status == 'rejected' && rejectReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.1))),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Reason: $rejectReason', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Outfit'))),
                ],
              ),
            ),
          ],
          if (onTypeTap != null && !isVerified) ...[
            const SizedBox(height: 16),
            Material(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTypeTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: Colors.grey[200]!)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(selectedType ?? 'Select Document Type', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSideUpload('Front View', fieldPrefix, 'Front', verifData['${fieldPrefix}FrontUrl'], isVerified)),
              if (showBackSide) ...[
                const SizedBox(width: 16),
                Expanded(child: _buildSideUpload('Back View', fieldPrefix, 'Back', verifData['${fieldPrefix}BackUrl'], isVerified)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideUpload(String label, String fieldPrefix, String side, String? url, bool isDisabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
        const SizedBox(height: 10),
        Material(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isDisabled ? null : () => _uploadDocument(fieldPrefix, side),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
              ),
              child: url == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, color: isDisabled ? Colors.grey : AppTheme.successColor, size: 28),
                        const SizedBox(height: 6),
                        Text('Upload', style: TextStyle(fontSize: 11, color: isDisabled ? Colors.grey : AppTheme.successColor, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                      ],
                    )
                  : Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.check_circle_rounded, color: _successGreen, size: 18),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(Map verif) {
    int totalSteps = 6; // Phone, Email, Aadhaar, PAN, Business, Property
    int verifiedCount = 1; // Assuming phone is verified
    
    if (_auth.currentUser?.emailVerified == true) verifiedCount++;
    if (verif['govIdVerified'] == true) verifiedCount++;
    if (verif['panVerified'] == true) verifiedCount++;
    if (verif['businessProofVerified'] == true) verifiedCount++;
    if (verif['propertyProofVerified'] == true) verifiedCount++;

    double progress = verifiedCount / totalSteps;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.successColor, Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppTheme.successColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76, height: 76,
                child: CircularProgressIndicator(
                  value: progress, strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Outfit')),
            ],
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trust Score', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                SizedBox(height: 6),
                Text('Complete these steps to become a Verified Partner.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Outfit')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (isVerified ? _successGreen : _accentBlue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: isVerified ? _successGreen : _accentBlue, size: 24),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDarkColor, fontFamily: 'Outfit')),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
          trailing: Icon(
            isVerified ? Icons.check_circle_rounded : Icons.pending_rounded, 
            color: isVerified ? _successGreen : AppTheme.warningColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Future<void> _verifyEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    try {
      await _auth.currentUser?.sendEmailVerification();
      Fluttertoast.showToast(msg: 'Verification email sent to $email');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> _showBusinessProofOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Proof Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
            const SizedBox(height: 8),
            const Text('Select one document to verify your professional status', style: TextStyle(fontSize: 14, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
            const SizedBox(height: 24),
            _buildOptionTile('GST Certificate', 'businessProof', 'GST Certificate'),
            _buildOptionTile('Trade License', 'businessProof', 'Trade License'),
            _buildOptionTile('Shop Act / MSME', 'businessProof', 'Shop Act / MSME'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showPropertyProofOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Property Ownership Proof', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
            const SizedBox(height: 8),
            const Text('Select one document to verify property control', style: TextStyle(fontSize: 14, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
            const SizedBox(height: 24),
            _buildOptionTile('Electricity Bill', 'propertyProof', 'Electricity Bill'),
            _buildOptionTile('Property Tax Receipt', 'propertyProof', 'Property Tax'),
            _buildOptionTile('Lease / Rent Agreement', 'propertyProof', 'Lease Agreement'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String title, String fieldPrefix, String type) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () async {
          Navigator.pop(context);
          await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
            'verification': { '${fieldPrefix}Type': type }
          }, SetOptions(merge: true));
        },
      ),
    );
  }

  Future<void> _uploadDocument(String fieldPrefix, String side) async {
    final userDoc = await _firestore.collection('users').doc(_auth.currentUser?.uid).get();
    final verif = userDoc.data()?['verification'] as Map? ?? {};
    
    if ((fieldPrefix == 'businessProof' || fieldPrefix == 'propertyProof') && verif['${fieldPrefix}Type'] == null) {
      Fluttertoast.showToast(msg: 'Please select document type first');
      return;
    }

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: AppTheme.successColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: AppTheme.successColor, size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
    if (source == null) return;

    XFile? image;
    if (source == ImageSource.camera) {
      image = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(builder: (context) => DocumentCaptureCamera(title: 'Scan $side Side')),
      );
    } else {
      image = await picker.pickImage(source: source, imageQuality: 80);
    }

    if (image == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 2),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Align Document',
          toolbarColor: AppTheme.successColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.ratio3x2,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
      ],
    );

    if (croppedFile == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Upload', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Is the document clearly readable?', style: TextStyle(fontSize: 14, fontFamily: 'Outfit')),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(croppedFile.path), height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retake', style: TextStyle(color: AppTheme.errorColor, fontFamily: 'Outfit'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
            child: const Text('Confirm & Upload', style: TextStyle(color: Colors.white, fontFamily: 'Outfit'))
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final File file = File(croppedFile.path);
      final userId = _auth.currentUser!.uid;
      
      final ref = FirebaseStorage.instance.ref().child('verifications/$userId/${fieldPrefix}_${side}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).set({
        'verification': {
          '$fieldPrefix${side}Url': url,
          '${fieldPrefix}Status': 'pending',
          '${fieldPrefix}Timestamp': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      Fluttertoast.showToast(msg: 'Document uploaded!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Upload failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVerification(String field, dynamic value) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore.collection('users').doc(userId).set({
      'verification': { field: value, '${field}Timestamp': FieldValue.serverTimestamp() }
    }, SetOptions(merge: true));
  }
}
