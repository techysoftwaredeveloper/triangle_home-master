import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentType = 'rent';
  bool _isProcessing = false;
  late Razorpay _razorpay;
  final _firebaseService = FirebaseService();
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining =
        widget.booking['lockExpiry'] != null
            ? (widget.booking['lockExpiry'] as DateTime).difference(
              DateTime.now(),
            )
            : const Duration(minutes: 15);

    _startTimer();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _timer.cancel();
    _razorpay.clear();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 0) {
        timer.cancel();
        _handleLockExpiry();
      } else {
        setState(() {
          _remaining = _remaining - const Duration(seconds: 1);
        });
      }
    });
  }

  void _handleLockExpiry() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Reservation Expired'),
              content: const Text(
                'Your bed reservation has expired. Please start again to select an available bed.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Return to Home'),
                ),
              ],
            ),
      );
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  int get _amount {
    final price = (widget.booking['price'] as num?)?.toInt() ?? 0;
    return _selectedPaymentType == 'rent' ? price : price;
  }

  void _openRazorpay() {
    setState(() => _isProcessing = true);

    final options = {
      'key': 'rzp_test_YourKeyHere', // Replace with your Razorpay Key
      'amount': _amount * 100, // Razorpay expects amount in paise
      'name': 'Triangle Homes',
      'description':
          _selectedPaymentType == 'rent'
              ? 'Monthly Rent - ${widget.booking['title'] ?? ''}'
              : 'Security Deposit - ${widget.booking['title'] ?? ''}',
      'prefill': {'contact': '', 'email': ''},
      'theme': {'color': '#1E3A8A'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening payment: $e')));
      }
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final bookingId = widget.booking['id'] as String?;

      // Store payment in Firestore
      await _firebaseService.createPayment(
        bookingId: bookingId ?? '',
        propertyId: widget.booking['propertyId'] as String? ?? '',
        amount: _amount.toDouble(),
        paymentMethod: 'razorpay',
        paymentType: _selectedPaymentType,
        razorpayPaymentId: response.paymentId,
      );

      // Update booking status to confirmed
      if (bookingId != null && bookingId.isNotEmpty) {
        await _firebaseService.updateBookingStatus(
          bookingId: bookingId,
          status: 'confirmed',
          paymentStatus: 'paid',
        );
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment ID: ${response.paymentId}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount Paid: ₹$_amount',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // back to booking summary
                    Navigator.pop(context); // back to room details
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment recorded but error updating: $e')),
        );
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${response.message ?? 'Unknown error'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External wallet: ${response.walletName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[200],
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Booking Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.booking['title'] ?? 'Unnamed Booking',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.booking['location'] ?? 'Unknown Location',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Booking ID',
                      widget.booking['id']?.toString() ?? '-',
                    ),
                    _buildInfoRow(
                      'Tenants',
                      widget.booking['tenantCount']?.toString() ?? '1',
                    ),
                    _buildInfoRow(
                      'Monthly Rent',
                      '₹${widget.booking['totalRent'] ?? widget.booking['price'] ?? 0}',
                    ),
                    _buildInfoRow(
                      'Security Deposit',
                      '₹${widget.booking['deposit'] ?? 0}',
                    ),
                    if (widget.booking['bedId'] != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Assigned Bed',
                        '${widget.booking['selectedRoomNumber'] ?? ''} - Bed ${widget.booking['selectedBedNumber'] ?? ''}',
                      ),
                      _buildInfoRow(
                        'Hold Expires In',
                        _formatDuration(_remaining),
                        valueColor:
                            _remaining.inMinutes < 2
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),

            const SizedBox(height: 20),

            // Payment Type Selection
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Payment Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentTypeCard(
                            label: 'Monthly Rent',
                            value: 'rent',
                            amount:
                                widget.booking['totalRent'] ??
                                widget.booking['price'] ??
                                0,
                            icon: Icons.home,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPaymentTypeCard(
                            label: 'Security Deposit',
                            value: 'deposit',
                            amount: widget.booking['deposit'] ?? 0,
                            icon: Icons.shield,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),

            const SizedBox(height: 20),

            // Amount Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount to Pay:',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    '₹$_amount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // Payment info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secure payment powered by Razorpay. Supports UPI, cards, net banking & wallets.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _openRazorpay,
                icon:
                    _isProcessing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.payment),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Pay ₹$_amount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textDarkColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeCard({
    required String label,
    required String value,
    required dynamic amount,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentType == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentType = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹$amount',
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
