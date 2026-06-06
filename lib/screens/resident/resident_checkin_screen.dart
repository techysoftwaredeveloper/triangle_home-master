import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/checkin_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResidentCheckInScreen extends StatefulWidget {
  final String bookingId;

  const ResidentCheckInScreen({super.key, required this.bookingId});

  @override
  State<ResidentCheckInScreen> createState() => _ResidentCheckInScreenState();
}

class _ResidentCheckInScreenState extends State<ResidentCheckInScreen> {
  final CheckInService _checkInService = CheckInService();
  bool _isProcessing = false;
  bool _showOtp = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue == widget.bookingId) {
        setState(() => _isProcessing = true);
        try {
          final user = FirebaseAuth.instance.currentUser!;
          await _checkInService.verifyQrCheckIn(widget.bookingId, user.uid);
          // UI will auto-update via StreamBuilder success state
        } catch (e) {
          setState(() => _isProcessing = false);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Verification Failed: $e')));
          }
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Check-In Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('checkins')
                .doc(widget.bookingId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(
              child: Text(
                'Check-in session not active',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (data['status'] == CheckInStatus.verified.name) {
            return _buildSuccessState();
          }

          return Stack(
            children: [
              if (!_showOtp) ...[
                MobileScanner(onDetect: _onDetect),
                _buildScannerOverlay(),
              ] else
                _buildOtpFallback(data['otpCode'] ?? '------'),

              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),

              _buildBottomControls(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.successColor, width: 4),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildOtpFallback(String otp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.vpn_key_rounded,
            color: AppTheme.successColor,
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Check-In OTP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share this code with the property manager',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              otp,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            _showOtp ? 'Scanning not working?' : 'Can\'t scan the code?',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _showOtp = !_showOtp),
            child: Text(
              _showOtp ? 'Try Scanning Again' : 'Show Backup OTP',
              style: const TextStyle(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 100,
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome Home!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your check-in is verified and your residency is now active.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 64),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Go to Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
