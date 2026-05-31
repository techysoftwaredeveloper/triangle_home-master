import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StayInfoScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const StayInfoScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final propertyData = booking['propertyData'] as Map? ?? {};
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Branded Header with Curve
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Stay Details',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'stay_image',
                    child: Image.network(
                      propertyData['image'] ?? 'https://via.placeholder.com/400x280',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryColor, child: const Icon(Icons.business, size: 40, color: Colors.white)),
                    ),
                  ),
                  // Dark gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          propertyData['title'] ?? 'Sunrise Residency',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(propertyData['location'] ?? 'Kozhikode, Kerala', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                children: [
                  // Stay Info Card
                  _buildSectionCard(
                    title: 'Stay Information',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _buildInfoRow('Check-In Date', _formatDate(booking['checkIn'])),
                      _buildInfoRow('Check-Out Date', _formatDate(booking['checkOut'])),
                      _buildInfoRow('Duration', '${booking['duration'] ?? 1} Month'),
                      _buildInfoRow('Room / Bed', booking['roomNumber'] ?? 'A-203'),
                      _buildInfoRow('Monthly Rent', format.format(booking['price'] ?? 0)),
                    ],
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 24),

                  // Hoster Info Card
                  _buildSectionCard(
                    title: 'Hoster Information',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _buildHosterProfile(
                        name: booking['hosterName'] ?? 'Rajesh Kumar',
                        role: 'Property Manager',
                        phone: '+91 98765 43210',
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 24),

                  // Payment Details Card
                  _buildSectionCard(
                    title: 'Payment Details',
                    icon: Icons.payments_outlined,
                    children: [
                      _buildInfoRow('Total Amount', format.format(booking['price'] ?? 0)),
                      _buildInfoRow(
                        'Payment Status', 
                        (booking['paymentStatus'] ?? 'Pending').toString().toUpperCase(), 
                        valueColor: booking['paymentStatus'] == 'paid' ? AppTheme.successColor : AppTheme.warningColor
                      ),
                      _buildInfoRow('Next Due Date', _formatDate(booking['nextDueDate'] ?? Timestamp.fromDate(DateTime.now().add(const Duration(days: 15))))),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 40),

                  // Action Button
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                    ),
                    child: const Text('Pay Monthly Rent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ).animate().fadeIn(delay: 400.ms).scale(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, letterSpacing: 0.5, fontFamily: 'Outfit')),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor ?? AppTheme.textColor, fontFamily: 'Outfit')),
        ],
      ),
    );
  }

  Widget _buildHosterProfile({required String name, required String role, required String phone}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor, fontFamily: 'Outfit')),
              Text(role, style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.successColor),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(10),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) return DateFormat('dd MMM yyyy').format(date.toDate());
    return date.toString();
  }
}
