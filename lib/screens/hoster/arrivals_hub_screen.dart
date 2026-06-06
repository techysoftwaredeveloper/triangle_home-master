import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/checkin_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ArrivalsHubScreen extends StatefulWidget {
  const ArrivalsHubScreen({super.key});

  @override
  State<ArrivalsHubScreen> createState() => _ArrivalsHubScreenState();
}

class _ArrivalsHubScreenState extends State<ArrivalsHubScreen> {
  final CheckInService _checkInService = CheckInService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Arrivals Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDarkColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('bookings')
                .where('hoster_id', isEqualTo: user.uid)
                .where('status', isEqualTo: BookingStatus.bookingConfirmed.name)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final arrivals = snapshot.data?.docs ?? [];

          if (arrivals.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: arrivals.length,
            itemBuilder: (context, index) {
              final data = arrivals[index].data();
              return _ArrivalCard(
                bookingId: arrivals[index].id,
                data: data,
                onCheckIn:
                    () => _showVerificationSheet(arrivals[index].id, data),
              );
            },
          );
        },
      ),
    );
  }

  void _showVerificationSheet(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    // Generate session first
    try {
      await _checkInService.generateCheckInSession(bookingId);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => _CheckInVerificationSheet(
              bookingId: bookingId,
              residentName: data['tenantDetails']?[0]?['name'] ?? 'Resident',
              checkInService: _checkInService,
            ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hail_rounded, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            'No pending arrivals',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Confirmed bookings will appear here',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ArrivalCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  final VoidCallback onCheckIn;

  const _ArrivalCard({
    required this.bookingId,
    required this.data,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final tenant = data['tenantDetails']?[0] ?? {};
    final property = data['propertyData'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant['name'] ?? 'Resident',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Bed ${data['bedId']} • ${property['title'] ?? "Property"}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CONFIRMED',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BOOKING ID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                  Text(
                    bookingId.substring(0, 8).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: onCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Verify Arrival',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckInVerificationSheet extends StatefulWidget {
  final String bookingId;
  final String residentName;
  final CheckInService checkInService;

  const _CheckInVerificationSheet({
    required this.bookingId,
    required this.residentName,
    required this.checkInService,
  });

  @override
  State<_CheckInVerificationSheet> createState() =>
      _CheckInVerificationSheetState();
}

class _CheckInVerificationSheetState extends State<_CheckInVerificationSheet> {
  bool _useOtp = false;
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Verify ${widget.residentName}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 32),

          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection('checkins')
                    .doc(widget.bookingId)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final data = snapshot.data!.data()!;

              if (data['status'] == CheckInStatus.verified.name) {
                return _buildSuccessState();
              }

              return Column(
                children: [
                  if (!_useOtp) ...[
                    QrImageView(
                      data: widget.bookingId,
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: AppTheme.textDarkColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ask the resident to scan this code',
                      style: TextStyle(color: AppTheme.textLightColor),
                    ),
                  ] else ...[
                    _buildOtpInput(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isVerifying ? null : _handleOtpVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _isVerifying
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Verify OTP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => setState(() => _useOtp = !_useOtp),
                    child: Text(
                      _useOtp
                          ? 'Show QR Code instead'
                          : 'Residental App not working? Use OTP',
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 45,
          child: TextField(
            controller: _otpControllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              if (val.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleOtpVerify() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() => _isVerifying = true);
    try {
      await widget.checkInService.verifyOtpCheckIn(widget.bookingId, otp);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
        const SizedBox(height: 24),
        const Text(
          'Check-In Verified!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Resident has been activated.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            minimumSize: const Size(200, 50),
          ),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
