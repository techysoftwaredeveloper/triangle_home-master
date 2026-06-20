import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/screens/payment/secure_checkout_page.dart';
import 'package:triangle_home/services/booking_service.dart';
import 'package:triangle_home/services/inventory_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final Map<String, dynamic> accommodation;
  final List<Map<String, String>> tenantDetails;

  const ConfirmBookingScreen({
    super.key,
    required this.accommodation,
    required this.tenantDetails,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  bool _isCreatingBooking = false;

  int get basePrice => _parseToInt(widget.accommodation['price'] ?? widget.accommodation['monthlyRent']);
  int get numberOfTenants => widget.tenantDetails.isNotEmpty ? widget.tenantDetails.length : 1;
  int get totalRent => basePrice * numberOfTenants;
  int get deposit => basePrice * 2;
  
  int get gst => ((totalRent + deposit) * 0.18).round();
  
  int get totalAmount => totalRent + deposit + gst;

  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.replaceAll(',', '')) ?? 0;
    return 0;
  }

  Future<void> _proceedToPayment() async {
    setState(() => _isCreatingBooking = true);

    try {
      final bookingService = BookingService();
      final inventoryService = InventoryService();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to proceed')),
        );
        return;
      }

      final String? roomId = widget.accommodation['selectedRoomId'];
      final String? bedId = widget.accommodation['selectedBedId'];
      final String propertyId = widget.accommodation['id'] ?? widget.accommodation['propertyId'] ?? '';

      if (propertyId.isEmpty) {
        throw 'Critical Error: Property identifier is missing.';
      }

      // 1. Lock the bed first if selected
      if (roomId != null && bedId != null) {
        try {
          await inventoryService.lockBedForUser(
            propertyId: propertyId,
            roomId: roomId,
            bedId: bedId,
            userId: user.uid,
          );
        } catch (e) {
          debugPrint('Reservation Transaction Error: $e');
          throw 'Reservation Failed: The selected bed could not be locked. Please try again.';
        }
      }

      // 2. Create a pending booking via backend API
      final String bookingId;
      try {
        final breakdown = {
          'rent': totalRent,
          'deposit': deposit,
          'gst': gst,
          'total': totalAmount,
        };

        bookingId = await bookingService.requestBooking(
          propertyId: propertyId,
          studentId: user.uid,
          requestId: DateTime.now().millisecondsSinceEpoch.toString(),
          roomId: roomId,
          bedId: bedId,
          breakdown: breakdown,
          moveInDate: widget.accommodation['moveInDate'] ?? DateTime.now().toIso8601String(),
          floor: widget.accommodation['selectedFloor']?.toString(),
          roomName: widget.accommodation['selectedRoomName']?.toString(),
          bedName: widget.accommodation['selectedBedName']?.toString(),
          bookingData: {
            'price': totalAmount.toDouble(),
            'type': widget.accommodation['type'] ?? '',
            'tenantDetails': widget.tenantDetails,
          },
        );
      } catch (e) {
        debugPrint('Booking Creation Error: $e');
        throw 'Checkout Failed: Could not create booking record. $e';
      }

      if (!mounted) return;

      // Navigate to secure checkout page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => SecureCheckoutPage(
                booking: {
                  'id': bookingId,
                  'title': widget.accommodation['title'],
                  'location': widget.accommodation['location'],
                  'type': widget.accommodation['type'],
                  'price': totalAmount,
                  'tenantCount': numberOfTenants,
                  'basePrice': basePrice,
                  'deposit': deposit,
                  'totalRent': totalRent,
                  'image': widget.accommodation['image'],
                  'propertyId': propertyId,
                  'roomId': roomId,
                  'bedId': bedId,
                  'floor': widget.accommodation['selectedFloor'],
                  'roomName': widget.accommodation['selectedRoomName'],
                  'bedName': widget.accommodation['selectedBedName'],
                  'lockExpiry': DateTime.now().add(const Duration(minutes: 15)),
                },
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF2F5BEA)),
            onPressed: () {},
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Text(
                'Help',
                style: TextStyle(color: Color(0xFF2F5BEA), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPropertyCard(),
                const SizedBox(height: 16),
                _buildTenantCard(),
                const SizedBox(height: 16),
                _buildPaymentCard(),
                const SizedBox(height: 16),
                _buildTrustCard(),
                const SizedBox(height: 16),
                _buildPolicyCard(),
                const SizedBox(height: 120), // Spacing for sticky bar
              ],
            ),
          ),
          _buildStickyBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPropertyCard() {
    final images = widget.accommodation['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images.first : widget.accommodation['image'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Property & Room Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : Container(width: 100, height: 100, color: Colors.grey[200], child: const Icon(Icons.apartment)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.accommodation['title'] ?? 'Property', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(width: 8),
                        _buildBadge('VERIFIED', const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(widget.accommodation['location'] ?? 'Location', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildIconLabel(Icons.layers_outlined, 'Floor ${widget.accommodation['selectedFloor'] ?? '1'}  •  Room ${widget.accommodation['selectedRoomName'] ?? 'R2'}  •  Bed ${widget.accommodation['selectedBedName'] ?? 'B1'}'),
                    const SizedBox(height: 4),
                    _buildIconLabel(Icons.people_outline, widget.accommodation['type'] ?? 'Double Sharing'),
                    const SizedBox(height: 4),
                    _buildIconLabel(Icons.calendar_today_outlined, 'Move-in Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard() {
    final tenant = widget.tenantDetails.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline, color: Color(0xFF2F5BEA), size: 20),
                  SizedBox(width: 8),
                  Text('Tenant Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 16)),
                ],
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Edit', style: TextStyle(color: Color(0xFF2F5BEA), fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTenantInfo('Name', tenant['name'] ?? 'ALBIN SHAJI', hasCheck: true)),
              Expanded(child: _buildTenantInfo('Phone', tenant['phone'] ?? '+91 89214 94013', isIcon: true, icon: Icons.phone_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTenantInfo('Email', tenant['email'] ?? 'albinsimonshaji@gmail.com', isIcon: true, icon: Icons.mail_outline),
          const SizedBox(height: 16),
          _buildTenantInfo('College / Company', tenant['college'] ?? 'Your college', isIcon: true, icon: Icons.account_balance_outlined),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: Color(0xFF2F5BEA), size: 20),
                  SizedBox(width: 8),
                  Text('Payment Breakdown', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 16)),
                ],
              ),
              Text('All amounts in INR ⓘ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 20),
          _buildPaymentRow(Icons.account_balance_wallet_outlined, 'Security Deposit (2 months) ⓘ', deposit),
          _buildPaymentRow(Icons.home_outlined, 'Monthly Rent', totalRent),
          _buildPaymentRow(Icons.account_balance_outlined, 'GST (18%)', gst),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF1F5F9))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text('₹${NumberFormat('#,##,###').format(totalAmount)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2F5BEA))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure Escrow Payment', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 14)),
                SizedBox(height: 2),
                Text('Your payment is securely held in escrow. Host receives payment only after check-in verification.', style: TextStyle(color: Color(0xFF15803D), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 40),
        ],
      ),
    );
  }

  Widget _buildPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.policy_outlined, color: Color(0xFF64748B), size: 20),
                  SizedBox(width: 8),
                  Text('Booking Policies', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15)),
                ],
              ),
              Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPolicyItem(Icons.history_rounded, 'Refundable Deposit\nAs per policy'),
              _buildPolicyItem(Icons.event_busy_outlined, 'Free Cancellation\nBefore check-in'),
              _buildPolicyItem(Icons.help_outline, 'Need Help?\n24x7 Support'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Payable', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('₹${NumberFormat('#,##,###').format(totalAmount)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const Text('View Details ⌃', style: TextStyle(color: Color(0xFF2F5BEA), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isCreatingBooking ? null : _proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F5BEA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isCreatingBooking
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_outline, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Pay Now Securely', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                                Text('Razorpay Secured', style: TextStyle(fontSize: 10, color: Colors.white70)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _trustItem(Icons.verified_user_outlined, '100% Secure'),
                  _trustItem(Icons.payment_outlined, 'Razorpay Protected'),
                  _trustItem(Icons.support_agent_outlined, '24x7 Support'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildIconLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildTenantInfo(String label, String value, {bool hasCheck = false, bool isIcon = false, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isIcon) ...[Icon(icon, size: 14, color: const Color(0xFF94A3B8)), const SizedBox(width: 6)],
            Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13), overflow: TextOverflow.ellipsis)),
            if (hasCheck) ...[const SizedBox(width: 4), const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 12)],
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentRow(IconData icon, String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: const Color(0xFF64748B))),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500))),
          Text('₹${NumberFormat('#,##,###').format(value)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(IconData icon, String text) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), shape: BoxShape.circle), child: Icon(icon, size: 20, color: const Color(0xFF64748B))),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.2)),
      ],
    );
  }

  static Widget _trustItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF16A34A)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
