import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 24),
            _buildResidentProfile(),
            const SizedBox(height: 24),
            _buildBookingInfo(),
            const SizedBox(height: 24),
            _buildStayInformation(),
            const SizedBox(height: 24),
            _buildFinancialInformation(),
            const SizedBox(height: 24),
            _buildPaymentHistory(),
            const SizedBox(height: 24),
            _buildDocumentsSection(),
            const SizedBox(height: 24),
            _buildEmergencyContact(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(),
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookingData['propertyName'] ?? 'Sunrise PG',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const Text('Kochi, Kerala', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
              SizedBox(width: 6),
              Text('95% Occupancy', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResidentProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, size: 32, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookingData['studentName'] ?? 'Resident',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'Active Resident',
                        style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _profileRow('Student', '21 • Male'),
          _profileRow('College', 'Rajagiri College'),
          _profileRow('Course', 'BCA'),
          _profileRow('Phone', bookingData['studentPhone'] ?? 'N/A'),
          _profileRow('Email', 'rahulnair@gmail.com'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _iconBtn(Icons.call_rounded, 'Call')),
              const SizedBox(width: 8),
              Expanded(child: _iconBtn(Icons.chat_rounded, 'WhatsApp')),
              const SizedBox(width: 8),
              Expanded(child: _iconBtn(Icons.person_outline_rounded, 'Profile')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          Text(value, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildBookingInfo() {
    return _infoCard(
      'Booking Information',
      [
        _infoRow('Booking ID', 'BK-2026-00124'),
        _infoRow('Property', bookingData['propertyName'] ?? 'Sunrise PG'),
        _infoRow('Room', 'Dormitory Room D3'),
        _infoRow('Bed', 'D3-B02'),
        _infoRow('Room Type', 'Dormitory'),
        _infoRow('Floor', '3rd Floor'),
      ],
    );
  }

  Widget _buildStayInformation() {
    return _infoCard(
      'Stay Information',
      [
        _infoRow('Check-in Date', _formatTimestamp(bookingData['createdAt'])),
        _infoRow('Expected Checkout', '12 Dec 2026'),
        _infoRow('Stay Duration', '151 Days'),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Stay Progress', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                Text('${(151/365*100).round()}%', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 151/365,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialInformation() {
    return _infoCard(
      'Financial Information',
      [
        _infoRow('Monthly Rent', '₹5,500'),
        _infoRow('Security Deposit', '₹3,000'),
        _infoRow('Total Paid', '₹33,000', valueColor: const Color(0xFF16A34A)),
        _infoRow('Pending Amount', '₹0', valueColor: const Color(0xFF16A34A)),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Payment History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ),
        _historyRow('June 2026', 'Paid on 01 Jun 2026'),
        _historyRow('May 2026', 'Paid on 01 May 2026'),
        _historyRow('April 2026', 'Paid on 01 Apr 2026'),
      ],
    );
  }

  Widget _historyRow(String month, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                Text(date, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ),
        _docRow('Aadhaar Card', 'Verified', true),
        _docRow('College ID', 'Verified', true),
        _docRow('Agreement', 'Signed', true),
      ],
    );
  }

  Widget _docRow(String name, String status, bool verified) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: Icon(verified ? Icons.description_rounded : Icons.warning_amber_rounded, size: 20, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                Text(status, style: TextStyle(color: verified ? const Color(0xFF16A34A) : Colors.orange, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Icon(verified ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: verified ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1), size: 20),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact() {
    return _infoCard(
      'Emergency Contact',
      [
        _infoRow('Contact Name', 'Suresh Nair'),
        _infoRow('Relationship', 'Father'),
        _infoRow('Phone', '+91 XXXXX XXXXX'),
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _actionFullBtn('Transfer Bed', const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _actionFullBtn('Renew Stay', const Color(0xFF8B5CF6))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _actionFullBtn('Generate Receipt', const Color(0xFF16A34A))),
              const SizedBox(width: 12),
              Expanded(child: _actionFullBtn('Check-out Resident', const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionFullBtn(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy').format(ts.toDate());
    }
    return 'N/A';
  }
}
