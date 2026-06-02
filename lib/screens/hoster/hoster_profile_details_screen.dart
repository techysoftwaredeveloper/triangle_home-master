import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/screens/hoster/hoster_profile_extra_screens.dart';
import 'package:triangle_home/theme/app_theme.dart';

class HosterProfileDetailsScreen extends StatelessWidget {
  const HosterProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDarkColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Hoster Profile',
          style: TextStyle(color: AppTheme.textDarkColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textDarkColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildHostInfoSection(),
            const SizedBox(height: 24),
            _buildPerformanceSection(),
            const SizedBox(height: 24),
            _buildTrustScoreSection(context),
            const SizedBox(height: 24),
            _buildRecentReviewsSection(context),
            const SizedBox(height: 24),
            _buildIdentitySection(context),
            const SizedBox(height: 24),
            _buildBankingSection(),
            const SizedBox(height: 24),
            _buildPropertyManagementSection(),
            const SizedBox(height: 24),
            _buildPreferencesSection(),
            const SizedBox(height: 24),
            _buildEmergencyContactSection(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onEdit, String? actionText, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor),
        ),
        if (onEdit != null || actionText != null || onAction != null)
          TextButton(
            onPressed: onAction ?? onEdit ?? () {},
            child: Text(
              actionText ?? 'Edit',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Basic Information'),
          _buildDetailRow(Icons.person_outline_rounded, 'Rahul Sharma'),
          _buildDetailRow(Icons.cake_outlined, 'Male • 15 Mar 1988'),
          _buildDetailRow(Icons.phone_android_outlined, '+91 98765 43210'),
          _buildDetailRow(Icons.email_outlined, 'rahul.sharma@gmail.com'),
          _buildDetailRow(Icons.location_on_outlined, '123, Green Park Road, Koramangala, Bangalore, Karnataka - 560001'),
        ],
      ),
    );
  }

  Widget _buildHostInfoSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Host Information'),
          _buildDetailRow(Icons.person_pin_outlined, 'Host Type', value: 'Individual Owner'),
          _buildDetailRow(Icons.star_outline_rounded, 'Experience', value: '3-5 Years'),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat('Total Properties', '8', const Color(0xFFF1F5FF), const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _buildMiniStat('Total Rooms', '42', const Color(0xFFF0FDF4), const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _buildMiniStat('Active Listings', '7', const Color(0xFFFFF7ED), const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Performance Overview', actionText: 'View All'),
          _buildPerformanceRow(Icons.chat_bubble_outline_rounded, 'Response Rate', '98%', Colors.green),
          _buildPerformanceRow(Icons.timer_outlined, 'Avg. Response Time', '12 mins', Colors.blue),
          _buildPerformanceRow(Icons.check_circle_outline_rounded, 'Acceptance Rate', '95%', Colors.green),
          _buildPerformanceRow(Icons.cancel_outlined, 'Cancellation Rate', '3%', Colors.red),
        ],
      ),
    );
  }

  Widget _buildTrustScoreSection(BuildContext context) {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Trust Score', actionText: 'View Details', onAction: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HosterTrustScoreScreen()));
          }),
          const SizedBox(height: 16),
          // Half gauge implementation simplified with a stack or custom painter
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 60,
                  child: CustomPaint(
                    painter: HalfGaugePainter(score: 0.91),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Column(
                    children: [
                      const Text('91', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('/100', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Excellent Host', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 20)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, color: Colors.green, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "You're doing great! Keep providing excellent service.",
                    style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviewsSection(BuildContext context) {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Recent Reviews', actionText: 'View All', onAction: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HosterReviewsScreen()));
          }),
          _buildReviewItem(
            'Amit Verma',
            '12 May 2024',
            5.0,
            'Stayed in Green Park House',
            'Great place, very clean and exactly as shown in photos. Host was very responsive and helpful.',
            'https://randomuser.me/api/portraits/men/32.jpg',
          ),
          const Divider(height: 32),
          _buildReviewItem(
            'Neha Iyer',
            '2 May 2024',
            4.0,
            'Stayed in Sunrise PG',
            'Safe and comfortable stay. Food is excellent and the host is cooperative.',
            'https://randomuser.me/api/portraits/women/44.jpg',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String date, double rating, String stay, String comment, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(imageUrl)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            Row(
              children: [
                Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(stay, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
        const SizedBox(height: 4),
        Text(
          comment,
          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
        ),
      ],
    );
  }

  Widget _buildIdentitySection(BuildContext context) {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Identity & Compliance', actionText: 'View All', onAction: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HosterIdentityScreen()));
          }),
          _buildDocRow(Icons.badge_outlined, 'Aadhaar Card', 'Verified', Colors.green),
          _buildDocRow(Icons.credit_card_rounded, 'PAN Card', 'Verified', Colors.green),
          _buildDocRow(Icons.drive_eta_rounded, 'Driving License', 'Under Review', Colors.orange),
          _buildDocRow(Icons.assignment_ind_outlined, 'Passport (Optional)', 'Not Uploaded', Colors.grey),
          const Divider(height: 32),
          InkWell(
            onTap: () {},
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Property Documents (12)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankingSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Banking & Payouts'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryColor),
            ),
            title: const Text('HDFC Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text('**** 5678', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSmallBadge(Icons.check_circle_rounded, 'Bank Verified', Colors.green),
              const SizedBox(width: 12),
              _buildSmallBadge(Icons.check_circle_rounded, 'UPI Verified', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyManagementSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Property Management Summary', actionText: 'View All'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildGridStat('Total Properties', '8', Colors.blue),
              _buildGridStat('Active Listings', '7', Colors.green),
              _buildGridStat('Occupied Rooms', '35', Colors.purple),
              _buildGridStat('Vacant Rooms', '7', Colors.orange),
              _buildGridStat('Monthly Revenue', '₹2,45,000', Colors.indigo),
              _buildGridStat('Total Bookings', '128', Colors.teal),
              _buildGridStat('Completed Bookings', '110', Colors.blue),
              _buildGridStat('Cancellations', '8', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Host Preferences'),
          _buildPrefRow('Booking Type', 'Approval Required'),
          _buildPrefRow('Preferred Tenants', 'Students, Professionals'),
          _buildPrefRow('Preferred Gender', 'Any'),
          _buildPrefRow('Preferred Duration', 'Long Term, Short Term'),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildSectionHeader('Emergency Contact'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Suresh Sharma (Brother)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text('+91 91234 56789', style: TextStyle(fontSize: 13)),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.phone_rounded, color: Colors.blue, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildActionTile(Icons.add_home_work_rounded, 'Add New Property', Colors.blue),
        _buildActionTile(Icons.list_alt_rounded, 'Manage Listings', Colors.green),
        _buildActionTile(Icons.calendar_month_rounded, 'View Bookings', Colors.purple),
        _buildActionTile(Icons.payments_rounded, 'Payout History', Colors.orange),
        _buildActionTile(Icons.dashboard_customize_rounded, 'Host Dashboard', Colors.indigo, isLast: true),
      ],
    );
  }

  // --- UI Component Helpers ---

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, {String? value}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (value != null) ...[
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
                ] else
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: textColor.withOpacity(0.7), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textLightColor))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDocRow(IconData icon, String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildGridStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildPrefRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textLightColor)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor)),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, Color color, {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () {},
      ),
    );
  }
}

class HalfGaugePainter extends CustomPainter {
  final double score;
  HalfGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    
    final paintBase = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintScore = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // start at PI
      3.14159, // sweep PI
      false,
      paintBase,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159 * score,
      false,
      paintScore,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
