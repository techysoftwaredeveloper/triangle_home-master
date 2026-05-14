import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class SuggestPropertySuccessScreen extends StatelessWidget {
  final Map<String, dynamic> suggestionData;
  const SuggestPropertySuccessScreen({super.key, required this.suggestionData});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(now);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Success',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.primaryColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 140,
                        width: 220,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(Icons.home_work_rounded, size: 80, color: AppTheme.primaryColor),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 32),
                        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Suggestion Submitted!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.primaryColor),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),
                  const Text(
                    'Thank you for helping us grow our community.\nYour suggestion has been received successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textLightColor, fontFamily: 'Outfit', height: 1.6),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What happens next?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.textDarkColor),
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 24),
            _buildTimelineItem(
              icon: Icons.search_rounded,
              title: 'We\'ll review your suggestion',
              subtitle: 'Our team will carefully review the details.',
              badge: '1-2 Days',
              color: Colors.green,
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.05, end: 0),
            _buildTimelineItem(
              icon: Icons.phone_outlined,
              title: 'We may contact you',
              subtitle: 'If needed, we\'ll reach out via email or phone.',
              badge: 'If Required',
              color: Colors.blue,
            ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.05, end: 0),
            _buildTimelineItem(
              icon: Icons.notifications_none_rounded,
              title: 'You\'ll get notified',
              subtitle: 'We\'ll update you about the status.',
              badge: 'Stay Tuned',
              color: Colors.orange,
              isLast: true,
            ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.05, end: 0),

            const SizedBox(height: 32),
            _buildSummaryCard(formattedDate),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 12),
                    Text('Suggest Another Property', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.primaryColor)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 14, color: AppTheme.textLightColor.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  'Your information is safe and secure',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLightColor.withValues(alpha: 0.6), fontFamily: 'Outfit'),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFF1F5F9), margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit'))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textLightColor, fontFamily: 'Outfit', height: 1.4)),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String date) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              const Text('Suggestion Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
              const Spacer(),
              Icon(Icons.more_horiz_rounded, color: AppTheme.textLightColor.withValues(alpha: 0.4)),
            ],
          ),
          const SizedBox(height: 24),
          _summaryRow(Icons.business_outlined, 'Property Name', suggestionData['business_name'] ?? ''),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _summaryRow(Icons.location_on_outlined, 'Location', suggestionData['business_address'] ?? ''),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _summaryRow(Icons.category_outlined, 'Category', suggestionData['category'] ?? ''),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _summaryRow(Icons.calendar_today_outlined, 'Submitted On', date),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textLightColor.withValues(alpha: 0.5)),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textLightColor, fontFamily: 'Outfit')),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.textDarkColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
