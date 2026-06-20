import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:triangle_home/core/app_config.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/payment_service.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/services/inventory_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/screens/payment/payment_success_page.dart';

enum CheckoutPaymentType {
  completePayment,
  securityDeposit,
}

class SecureCheckoutPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;

  const SecureCheckoutPage({super.key, required this.booking});

  @override
  ConsumerState<SecureCheckoutPage> createState() => _SecureCheckoutPageState();
}

class _SecureCheckoutPageState extends ConsumerState<SecureCheckoutPage> {
  late Razorpay _razorpay;
  CheckoutPaymentType _selectedPaymentType = CheckoutPaymentType.completePayment;
  late Timer _timer;
  late Duration _remaining;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _remaining = widget.booking['lockExpiry'] != null
        ? (widget.booking['lockExpiry'] as DateTime).difference(DateTime.now())
        : const Duration(minutes: 15);
    
    _startTimer();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 0) {
        timer.cancel();
        _onTimerExpired();
      } else {
        if (mounted) {
          setState(() {
            _remaining = _remaining - const Duration(seconds: 1);
          });
        }
      }
    });
  }

  void _onTimerExpired() {
    // Release bed lock
    final inventoryService = InventoryService();
    inventoryService.releaseBedLock(
      propertyId: widget.booking['propertyId'] ?? '',
      roomId: widget.booking['roomId'] ?? '',
      bedId: widget.booking['bedId'] ?? '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reservation Expired'),
        content: const Text('Your bed reservation has expired. Please start again to select an available bed.'),
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

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "${minutes}m ${seconds}s";
  }

  double get _monthlyRent {
    if (_selectedPaymentType == CheckoutPaymentType.securityDeposit) {
      return 0.0;
    }
    return (widget.booking['totalRent'] ?? 0).toDouble();
  }

  double get _securityDeposit => (widget.booking['deposit'] ?? 0).toDouble();
  double get _gst => (_monthlyRent + _securityDeposit) * 0.18;
  double get _totalAmount => _monthlyRent + _securityDeposit + _gst;

  void _openRazorpay() {
    if (_remaining.inSeconds <= 0) return;

    setState(() => _isProcessing = true);

    final options = {
      'key': AppConfig.razorpayKey,
      'amount': (_totalAmount * 100).toInt(), // in paise
      'name': 'Triangle Homes',
      'description': 'Security Deposit Payment',
      'prefill': {
        'contact': '', // Should be fetched from user profile
        'email': '',   // Should be fetched from user profile
      },
      'theme': {'color': '#2F5BEA'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // 1. Verify payment via backend (in a real app)
    // 2. Store payment in Firestore
    final paymentService = PaymentService();
    try {
      await paymentService.recordProcessedPayment(
        bookingId: widget.booking['id'] ?? '',
        propertyId: widget.booking['propertyId'] ?? '',
        roomId: widget.booking['roomId'] ?? '',
        bedId: widget.booking['bedId'] ?? '',
        paymentType: _selectedPaymentType == CheckoutPaymentType.completePayment ? 'completePayment' : 'securityDeposit',
        rent: _monthlyRent,
        securityDeposit: _securityDeposit,
        gst: _gst,
        totalAmount: _totalAmount,
      );

      // Also create a record in the main payments collection for history/admin
      await paymentService.createPayment(
        bookingId: widget.booking['id'] ?? '',
        propertyId: widget.booking['propertyId'] ?? '',
        amount: _totalAmount,
        paymentMethod: 'razorpay',
        paymentType: 'securityDeposit',
        razorpayPaymentId: response.paymentId,
      );

      // 3. Mark booking paid
      final firebaseService = FirebaseService();
      await firebaseService.updateBookingStatus(
        bookingId: widget.booking['id'] ?? '',
        status: 'confirmed',
        paymentStatus: 'paid',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              paymentId: response.paymentId ?? '',
              amount: _totalAmount,
              bookingId: widget.booking['id'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error after payment success: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Failed'),
          content: Text(response.message ?? 'Unknown error occurred. Try again before reservation expires.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              return _buildTabletLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBookingSummaryCard(),
                      const SizedBox(height: 24),
                      _buildPaymentTypeSelection(),
                      const SizedBox(height: 24),
                      _buildPaymentBreakdownCard(),
                      const SizedBox(height: 24),
                      _buildSecurityTrustCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildStickyBottomPaymentBar(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildBookingSummaryCard(),
                const SizedBox(height: 24),
                _buildSecurityTrustCard(),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, color: Colors.grey[300]),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildPaymentTypeSelection(),
                      const SizedBox(height: 24),
                      _buildPaymentBreakdownCard(),
                    ],
                  ),
                ),
              ),
              _buildStickyBottomPaymentBar(),
            ],
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2F5BEA),
      elevation: 0,
      toolbarHeight: 72,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Secure Checkout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${widget.booking['id'] ?? ''})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Text(
            'Complete payment to confirm booking',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: const [
              Icon(Icons.shield_outlined, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text(
                'Secure',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSummaryCard() {
    final images = widget.booking['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images.first : widget.booking['image'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey[200],
                        child: const Icon(Icons.apartment),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.booking['title'] ?? 'Property',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildBadge('Verified', const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.booking['location'] ?? 'Location',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem('Booking ID', widget.booking['id']?.toString() ?? '-'),
                        _buildSummaryItem('Tenants', widget.booking['tenantCount']?.toString() ?? '1'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          Text(
            'Floor ${widget.booking['floor'] ?? '1'}  •  Room ${widget.booking['roomName'] ?? 'R2'}  •  Bed ${widget.booking['bedName'] ?? 'B1'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          _buildTimerCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTimerCard() {
    Color cardColor;
    Color textColor;

    if (_remaining.inMinutes >= 10) {
      cardColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
    } else if (_remaining.inMinutes >= 3) {
      cardColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
    } else {
      cardColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                    children: [
                      const TextSpan(text: 'Bed reserved for '),
                      TextSpan(
                        text: _formatDuration(_remaining),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Complete payment before timer ends',
                  style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const Text(
          'Choose how you want to pay',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPaymentOptionCard(
                type: CheckoutPaymentType.completePayment,
                title: 'Complete Payment',
                subtitle: 'Pay full deposit now',
                icon: Icons.shield_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentOptionCard(
                type: CheckoutPaymentType.securityDeposit,
                title: 'Security Deposit',
                subtitle: 'Pay deposit only',
                icon: Icons.shield_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required CheckoutPaymentType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2F5BEA) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2F5BEA).withOpacity(0.1) : const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? const Color(0xFF2F5BEA) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF2F5BEA), size: 20)
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? const Color(0xFF2F5BEA) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Payment Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                'All amounts in INR',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBreakdownRow('Security Deposit', _securityDeposit),
          _buildBreakdownRow('Monthly Rent', _monthlyRent),
          _buildBreakdownRow('GST (18%)', _gst),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(_totalAmount),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2F5BEA)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500),
          ),
          Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTrustCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Payment is 100% Secure',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrustItem(Icons.check_circle_outline, 'Secured by Razorpay'),
          _buildTrustItem(Icons.lock_outline, '256-bit SSL encryption'),
          _buildTrustItem(Icons.payment_outlined, 'Supports UPI / Cards / Net Banking / Wallets'),
          _buildTrustItem(Icons.history_outlined, 'Payment held in escrow'),
          _buildTrustItem(Icons.verified_user_outlined, 'Released after verified check-in'),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF16A34A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomPaymentBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Payable',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(_totalAmount),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const Text(
                    'View Details ⌃',
                    style: TextStyle(color: Color(0xFF2F5BEA), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _openRazorpay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F5BEA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Pay Securely',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          Text(
                            'Powered by Razorpay',
                            style: TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
