import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BookingSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> accommodation;
  final List<Map<String, dynamic>> tenantDetails;
  final List<dynamic> tenants;
  final int tenantCount;

  const BookingSummaryScreen({
    super.key,
    required this.accommodation,
    required this.tenantDetails,
    required this.tenants,
    required this.tenantCount,
  });

  @override
  Widget build(BuildContext context) {
    final double monthlyRent = (accommodation['monthlyRent'] as num?)?.toDouble() ?? 0.0;
    final double totalMonthlyRent = monthlyRent * tenantCount;
    final double securityDeposit = (accommodation['securityDeposit'] as num?)?.toDouble() ?? 0.0;
    final double totalAmount = totalMonthlyRent + securityDeposit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Summary'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Details
            Text(
              accommodation['title'] ?? 'Property',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              accommodation['location'] ?? 'Location',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 32),

            // Tenant Details
            const Text(
              'Tenant 1',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Name: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(tenantDetails.isNotEmpty ? (tenantDetails[0]['name'] ?? '-') : '-'),
              ],
            ),
            const Divider(height: 32),

            // Payment Summary
            const Text(
              'Payment Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Monthly Rent (per tenant)', monthlyRent),
            _buildInfoRow('Number of Tenants', tenantCount.toString()),
            _buildPriceRow('Total Monthly Rent', totalMonthlyRent),
            _buildPriceRow('Security Deposit', securityDeposit),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${totalAmount.toInt()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('₹${value.toInt()}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}
