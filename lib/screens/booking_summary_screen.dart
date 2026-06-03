import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/payment/payment_screen.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/services/inventory_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class BookingSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> accommodation;
  final List<Map<String, String>> tenantDetails;

  const BookingSummaryScreen({
    super.key,
    required this.accommodation,
    required this.tenantDetails,
    required List tenants,
    required int tenantCount,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _isCreatingBooking = false;

  int get basePrice => (widget.accommodation['price'] as num?)?.toInt() ?? 0;
  int get numberOfTenants => widget.tenantDetails.length;
  int get totalRent => basePrice * numberOfTenants;
  int get deposit => totalRent;
  int get total => totalRent + deposit;

  Future<void> _proceedToPayment(BuildContext context) async {
    setState(() => _isCreatingBooking = true);

    try {
      final firebaseService = FirebaseService();
      final inventoryService = InventoryService();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Please login to proceed')),
        );
        return;
      }

      final String? roomId = widget.accommodation['selectedRoomId'];
      final String? bedId = widget.accommodation['selectedBedId'];

      // 1. Lock the bed first if selected
      if (roomId != null && bedId != null) {
        await inventoryService.lockBedForUser(
          propertyId: widget.accommodation['id'] ?? '',
          roomId: roomId,
          bedId: bedId,
          userId: user.uid,
        );
      }

      // 2. Create a pending booking in Firestore
      final bookingId = await firebaseService.createBooking(
        propertyId: widget.accommodation['id'] ?? '',
        propertyData: widget.accommodation,
        price: total.toDouble(),
        type: widget.accommodation['type'] ?? '',
        tenantDetails: widget.tenantDetails,
        roomId: roomId,
        bedId: bedId,
      );

      if (!mounted) return;

      // Navigate to payment screen
      Navigator.push(
        this.context,
        MaterialPageRoute(
          builder:
              (_) => PaymentScreen(
                booking: {
                  'id': bookingId,
                  'title': widget.accommodation['title'],
                  'location': widget.accommodation['location'],
                  'type': widget.accommodation['type'],
                  'price': total,
                  'tenantCount': numberOfTenants,
                  'basePrice': basePrice,
                  'deposit': deposit,
                  'totalRent': totalRent,
                  'image': widget.accommodation['image'],
                  'propertyId': widget.accommodation['id'],
                  'roomId': roomId,
                  'bedId': bedId,
                  'lockExpiry': DateTime.now().add(const Duration(minutes: 15)),
                },
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          this.context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Summary'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertyDetails(),
              _buildTenantDetails(),
              _buildPaymentSummary(),
              _buildPaymentButton(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.accommodation['title'] ?? 'Property Details',
            style: const TextStyle(
              fontSize: AppTheme.fontLG,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.accommodation['location'] ?? '',
            style: const TextStyle(
              color: AppTheme.textLightColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.home, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                widget.accommodation['type'] ?? '',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildTenantDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tenant Details',
            style: TextStyle(
              fontSize: AppTheme.fontLG,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(widget.tenantDetails.length, (index) {
            final tenant = widget.tenantDetails[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tenant ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Name', tenant['name'] ?? ''),
                  _buildDetailRow('Phone', tenant['phone'] ?? ''),
                  _buildDetailRow('Email', tenant['email'] ?? ''),
                  _buildDetailRow('College', tenant['college'] ?? ''),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
          }),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: AppTheme.fontLG,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentRow('Monthly Rent (per tenant)', basePrice),
          _buildPaymentRow(
            'Number of Tenants',
            numberOfTenants,
            isAmount: false,
          ),
          _buildPaymentRow('Total Monthly Rent', totalRent),
          _buildPaymentRow('Security Deposit', deposit),
          const Divider(height: 32),
          _buildPaymentRow('Total Amount', total, isTotal: true),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildPaymentRow(
    String label,
    dynamic value, {
    bool isAmount = true,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            isAmount ? '₹$value' : value.toString(),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreatingBooking ? null : () => _proceedToPayment(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
        child:
            _isCreatingBooking
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: AppTheme.fontMD,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnPrimary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}
