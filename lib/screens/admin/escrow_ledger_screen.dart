import 'package:flutter/material.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/escrow_record.dart';
import 'package:triangle_home/services/admin/admin_payout_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EscrowLedgerScreen extends StatefulWidget {
  const EscrowLedgerScreen({super.key});

  @override
  State<EscrowLedgerScreen> createState() => _EscrowLedgerScreenState();
}

class _EscrowLedgerScreenState extends State<EscrowLedgerScreen> {
  final AdminPayoutService _payoutService = AdminPayoutService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Financial Control Center', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDarkColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(child: _buildLedgerList()),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search by Booking ID...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildLedgerList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('escrow').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRecords = snapshot.data?.docs.map((doc) => EscrowRecord.fromFirestore(doc.data())).toList() ?? [];
        final filteredRecords = allRecords.where((r) => r.bookingId.toLowerCase().contains(_searchQuery)).toList();

        if (filteredRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No financial records found', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredRecords.length,
          itemBuilder: (context, index) => _EscrowCard(record: filteredRecords[index], payoutService: _payoutService),
        );
      },
    );
  }
}

class _EscrowCard extends StatefulWidget {
  final EscrowRecord record;
  final AdminPayoutService payoutService;

  const _EscrowCard({required this.record, required this.payoutService});

  @override
  State<_EscrowCard> createState() => _EscrowCardState();
}

class _EscrowCardState extends State<_EscrowCard> {
  PayoutValidationResult? _validation;
  bool _isValidating = true;
  bool _isReleasing = false;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final result = await widget.payoutService.validatePayoutEligibility(widget.record.bookingId);
    if (mounted) {
      setState(() {
        _validation = result;
        _isValidating = false;
      });
    }
  }

  Future<void> _handleRelease() async {
    setState(() => _isReleasing = true);
    try {
      await widget.payoutService.releasePayout(
        bookingId: widget.record.bookingId,
        adminId: 'ADMIN_001',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout released successfully')));
        _checkEligibility();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isReleasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final statusColor = _getStatusColor(r.status);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BOOKING ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMutedColor)),
                  Text(r.bookingId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(r.status.name.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 32),
          _amountRow('Gross Collected', r.grossAmount, isBold: true),
          _amountRow('Triangle Commission (${r.commissionRate}%)', r.commissionAmount, color: Colors.blue),
          _amountRow('Hoster Share', r.hosterAmount, color: AppTheme.successColor),
          const SizedBox(height: 20),
          if (r.status != EscrowStatus.payoutReleased)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_validation?.canRelease == true && !_isReleasing) ? _handleRelease : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  disabledBackgroundColor: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isReleasing 
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _validation?.canRelease == true ? 'Release Payout' : (_validation?.reason ?? 'Validating...'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: _validation?.canRelease == true ? Colors.white : Colors.grey[400]
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor)),
          Text('₹${NumberFormat('#,##,###').format(value)}', 
            style: TextStyle(
              fontSize: 14, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600, 
              color: color ?? AppTheme.textDarkColor
            )),
        ],
      ),
    );
  }

  Color _getStatusColor(EscrowStatus status) {
    switch (status) {
      case EscrowStatus.payoutReleased: return Colors.green;
      case EscrowStatus.disputed: return Colors.red;
      case EscrowStatus.readyForPayout: return Colors.blue;
      default: return Colors.orange;
    }
  }
}
