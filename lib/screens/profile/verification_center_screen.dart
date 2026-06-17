import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:triangle_home/widgets/document_capture_camera.dart';
import 'dart:io';
import 'package:triangle_home/screens/profile/verification_otp_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

class VerificationCenterScreen extends StatefulWidget {
  const VerificationCenterScreen({super.key});

  @override
  State<VerificationCenterScreen> createState() =>
      _VerificationCenterScreenState();
}

class _VerificationCenterScreenState extends State<VerificationCenterScreen> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  final Color _primaryBlue = const Color(0xFF0F172A);
  final Color _accentBlue = const Color(0xFF2563EB);
  final Color _bgGray = const Color(0xFFF8FAFC);
  final Color _successGreen = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reloadAndSyncStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadAndSyncStatus();
    }
  }

  Future<void> _reloadAndSyncStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null) return;

      Map<String, dynamic> updates = {};
      
      if (refreshed.emailVerified) {
        updates['emailVerified'] = true;
      }
      
      if (refreshed.phoneNumber != null) {
        updates['phoneVerified'] = true;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(refreshed.uid).set({
          'verification': updates,
        }, SetOptions(merge: true));
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data();
        final verif = userData?['verification'] as Map? ?? {};
        final info = userData?['info'] as Map? ?? {};
        final role = userData?['role'] ?? 'student';

        if (user.emailVerified && verif['emailVerified'] != true) {
          _updateVerification('emailVerified', true);
        }

        if (user.phoneNumber != null && verif['phoneVerified'] != true) {
          _updateVerification('phoneVerified', true);
        }

        return Scaffold(
          backgroundColor: _bgGray,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _primaryBlue),
              onPressed: () {
                if (!mounted) return;
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Verification Center',
              style: TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: _primaryBlue),
                onPressed: () async {
                  await user.reload();
                  setState(() {});
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHeader(verif),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Communication Verification'),
                    _buildVerificationTile(
                      icon: Icons.phone_android_outlined,
                      title: 'Mobile Number',
                      subtitle: info['phoneNumber'] ?? user.phoneNumber ?? 'Not provided',
                      isVerified: verif['phoneVerified'] == true,
                      onTap:
                          verif['phoneVerified'] == true
                              ? null
                              : () => _verifyPhone(info['phoneNumber'] ?? user.phoneNumber),
                    ),
                    _buildVerificationTile(
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      subtitle: user.email ?? 'Not provided',
                      isVerified: verif['emailVerified'] == true,
                      onTap:
                          verif['emailVerified'] == true
                              ? null
                              : () => _verifyEmail(user.email),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Document Verification'),

                    _buildDocumentUploadCard(
                      title:
                          role == 'student' ? 'Student ID' : 'Professional ID',
                      subtitle: 'Front and Back side of your ID',
                      fieldPrefix: 'roleId',
                      verifData: verif,
                      icon: Icons.school_outlined,
                    ),

                    _buildDocumentUploadCard(
                      title: 'Government ID',
                      subtitle: 'Aadhar, Voter ID or Driving License',
                      fieldPrefix: 'govId',
                      verifData: verif,
                      icon: Icons.assignment_ind_outlined,
                      onTypeTap: () => _showGovIdOptions(),
                      selectedType: verif['govIdType'],
                    ),

                    _buildDocumentUploadCard(
                      title: 'Address Verification',
                      subtitle: 'Aadhar or Voter ID Proof',
                      fieldPrefix: 'address',
                      verifData: verif,
                      icon: Icons.location_on_outlined,
                      onTypeTap: () => _showAddressOptions(),
                      selectedType: verif['addressType'],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Identity Verification'),
                    _buildVerificationTile(
                      icon: Icons.face_retouching_natural,
                      title: 'Selfie Verification',
                      subtitle: 'Take a clear photo of your face',
                      isVerified: verif['selfieVerified'] == true,
                      onTap:
                          verif['selfieVerified'] == true
                              ? null
                              : () => _uploadSelfie(),
                      status: verif['selfieStatus'],
                    ),

                    const SizedBox(height: 32),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: _successGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verified by Triangle Homes',
                            style: TextStyle(
                              color: _successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _primaryBlue,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required String fieldPrefix,
    required Map verifData,
    required IconData icon,
    VoidCallback? onTypeTap,
    String? selectedType,
  }) {
    final status = verifData['${fieldPrefix}Status'];
    final isVerified = verifData['${fieldPrefix}Verified'] == true;

    Color statusColor = const Color(0xFFF59E0B);
    String statusText = 'Pending';

    if (isVerified) {
      statusColor = _successGreen;
      statusText = 'Verified';
    } else if (status == 'pending') {
      statusColor = _accentBlue;
      statusText = 'In Review';
    } else if (status == 'rejected') {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Rejected';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isVerified ? _successGreen : _accentBlue).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isVerified ? _successGreen : _accentBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      selectedType ?? subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (onTypeTap != null && !isVerified) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onTypeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedType ?? 'Select ID Type',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSideUpload(
                  'Front Side',
                  fieldPrefix,
                  'Front',
                  verifData['${fieldPrefix}FrontUrl'],
                  isVerified,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSideUpload(
                  'Back Side',
                  fieldPrefix,
                  'Back',
                  verifData['${fieldPrefix}BackUrl'],
                  isVerified,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideUpload(
    String label,
    String fieldPrefix,
    String side,
    String? url,
    bool isDisabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isDisabled ? null : () => _uploadDocument(fieldPrefix, side),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                style: BorderStyle.solid,
              ),
              image:
                  url != null
                      ? DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                url == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: isDisabled ? Colors.grey : _accentBlue,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDisabled ? Colors.grey : _accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                    : Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: _successGreen,
                          size: 16,
                        ),
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(Map verif) {
    final user = _auth.currentUser;
    int totalSteps = 6;
    int verifiedCount = 0;
    if (verif['phoneVerified'] == true || user?.phoneNumber != null) verifiedCount++;
    if (verif['emailVerified'] == true || user?.emailVerified == true) verifiedCount++;
    if (verif['roleIdVerified'] == true) verifiedCount++;
    if (verif['govIdVerified'] == true) verifiedCount++;
    if (verif['addressVerified'] == true) verifiedCount++;
    if (verif['selfieVerified'] == true) verifiedCount++;

    double progress = verifiedCount / totalSteps;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(_successGreen),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complete all steps to build trust and unlock features.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
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
    String? status,
    VoidCallback? onTap,
  }) {
    Color statusColor = const Color(0xFFF59E0B);
    String statusText = 'Pending';

    if (isVerified) {
      statusColor = _successGreen;
      statusText = 'Verified';
    } else if (status == 'pending') {
      statusColor = _accentBlue;
      statusText = 'In Review';
    } else if (status == 'rejected') {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Rejected';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isVerified ? _successGreen : _accentBlue).withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isVerified ? _successGreen : _accentBlue,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPhone(String? phone) async {
    if (phone == null || phone.isEmpty) {
      Fluttertoast.showToast(msg: 'Please add phone number in profile first');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone.startsWith('+') ? phone : '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.currentUser?.linkWithCredential(credential);
          await _updateVerification('phoneVerified', true);
        },
        verificationFailed: (FirebaseAuthException e) {
          Fluttertoast.showToast(msg: e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => VerificationOtpScreen(
                    verificationId: verificationId,
                    phoneNumber: phone,
                  ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    try {
      await _auth.currentUser?.sendEmailVerification();
      Fluttertoast.showToast(msg: 'Verification email sent to $email');
      await _updateVerification('emailStatus', 'pending');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> _showGovIdOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Government ID Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildOptionTile('Aadhar Card', 'govId', 'Aadhar'),
                _buildOptionTile('Voter ID', 'govId', 'Voter'),
                _buildOptionTile('Driving License', 'govId', 'Driving License'),
              ],
            ),
          ),
    );
  }

  Future<void> _showAddressOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Address Proof Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildOptionTile('Aadhar Card', 'address', 'Aadhar'),
                _buildOptionTile('Voter ID', 'address', 'Voter'),
              ],
            ),
          ),
    );
  }

  Widget _buildOptionTile(String title, String fieldPrefix, String type) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          Navigator.pop(context);
          await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
            'verification': {'${fieldPrefix}Type': type},
          }, SetOptions(merge: true));
        },
      ),
    );
  }

  Future<void> _uploadDocument(String fieldPrefix, String side) async {
    // Check if ID type is selected for Gov and Address IDs
    final userDoc =
        await _firestore.collection('users').doc(_auth.currentUser?.uid).get();
    final verif = userDoc.data()?['verification'] as Map? ?? {};

    if ((fieldPrefix == 'govId' || fieldPrefix == 'address') &&
        verif['${fieldPrefix}Type'] == null) {
      Fluttertoast.showToast(
        msg: 'Please select ID type first',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final picker = ImagePicker();
    if (!mounted) return;
    final source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Upload $side Side'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text('Camera'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text('Gallery'),
              ),
            ],
          ),
    );
    if (source == null) return;

    // Check permissions
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Fluttertoast.showToast(msg: 'Camera permission is required');
        if (status.isPermanentlyDenied) openAppSettings();
        return;
      }
    } else {
      // For gallery, check photos or storage depending on OS
      final status = Platform.isIOS 
          ? await Permission.photos.request() 
          : await Permission.storage.request();
          
      if (status.isDenied || status.isPermanentlyDenied) {
        // storage is sometimes always denied on Android 13+, photos is better
        if (Platform.isAndroid) {
          final photoStatus = await Permission.photos.request();
          if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
            Fluttertoast.showToast(msg: 'Gallery access is required');
            if (photoStatus.isPermanentlyDenied) openAppSettings();
            return;
          }
        } else {
          Fluttertoast.showToast(msg: 'Gallery access is required');
          if (status.isPermanentlyDenied) openAppSettings();
          return;
        }
      }
    }

    XFile? image;
    if (source == ImageSource.camera) {
      if (!mounted) return;
      image = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentCaptureCamera(title: 'Scan $side Side'),
        ),
      );
    } else {
      image = await picker.pickImage(source: source, imageQuality: 80);
    }

    if (image == null) {
      debugPrint('No image selected/captured');
      return;
    }

    // --- CROP IMAGE TO FIT ---
    if (!mounted) return;
    CroppedFile? croppedFile;
    try {
      croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(
          ratioX: 3,
          ratioY: 2,
        ), // Standard ID Card Ratio
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Align ID Card',
            toolbarColor: _primaryBlue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio3x2,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Align ID Card',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Cropping error: $e');
      Fluttertoast.showToast(msg: 'Error opening cropper: $e');
      return;
    }

    if (croppedFile == null) {
      debugPrint('Cropping cancelled');
      return;
    }

    // --- NEW: CONFIRMATION STEP ---
    if (!mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Confirm Upload',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Is the text clear and all corners visible?',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(croppedFile!.path),
                      height: 200,
                      width: 280,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Retake',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: _accentBlue),
                child: const Text('Confirm & Upload'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    Fluttertoast.showToast(msg: 'Uploading document...');
    
    try {
      final File file = File(croppedFile.path);
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated. Please login again.';

      final String userId = user.uid;
      final ref = FirebaseStorage.instance.ref().child(
        'verifications/$userId/${fieldPrefix}_${side}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).set({
        'verification': {
          '$fieldPrefix${side}Url': url,
          '${fieldPrefix}Status': 'pending',
          '${fieldPrefix}Timestamp': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      
      Fluttertoast.showToast(msg: '$side side uploaded successfully!');
    } catch (e) {
      debugPrint('Upload error: $e');
      Fluttertoast.showToast(msg: 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadSelfie() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      Fluttertoast.showToast(
        msg: 'Camera permission is required to capture a selfie',
        backgroundColor: Colors.red,
      );
      if (status.isPermanentlyDenied) openAppSettings();
      return;
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );
    if (image == null) return;

    if (!mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Confirm Selfie',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ensure your face is clearly visible without glasses or masks.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 80,
                  backgroundImage: FileImage(File(image.path)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Retake',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: _accentBlue),
                child: const Text('Confirm & Upload'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    Fluttertoast.showToast(msg: 'Uploading selfie...');

    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated.';

      final ref = FirebaseStorage.instance.ref().child(
        'verifications/${user.uid}/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      final uploadTask = await ref.putFile(File(image.path));
      final url = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).set({
        'verification': {
          'selfieUrl': url,
          'selfieStatus': 'pending',
          'selfieTimestamp': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      
      Fluttertoast.showToast(msg: 'Selfie uploaded for review!');
    } catch (e) {
      debugPrint('Selfie upload error: $e');
      Fluttertoast.showToast(msg: 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVerification(String field, dynamic value) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore.collection('users').doc(userId).set({
      'verification': {
        field: value,
        '${field}Timestamp': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }
}
