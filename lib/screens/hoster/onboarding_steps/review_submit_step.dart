import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/services/onboarding_service.dart';
import '../hoster_dashboard_screen.dart';

class ReviewSubmitStep extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onBack;

  const ReviewSubmitStep({super.key, required this.onboardingData, required this.onBack});

  @override
  State<ReviewSubmitStep> createState() => _ReviewSubmitStepState();
}

class _ReviewSubmitStepState extends State<ReviewSubmitStep> {
  bool _isSubmitting = false;
  final OnboardingService _onboardingService = OnboardingService();

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);
    try {
      await _onboardingService.submitHosterApplication(widget.onboardingData);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Application Submitted'),
            content: const Text('Your partner application is under review. We will notify you once approved.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => HosterDashboardScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting application: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.onboardingData;
    final String role = (data['role']?.toString().toUpperCase() ?? 'NOT SELECTED');
    final List tenants = data['preferredTenants'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review your application',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please verify all details before final submission.',
            style: TextStyle(color: AppTheme.textLightColor, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Profile Header
          _buildProfileHeader(data),
          const SizedBox(height: 24),

          _buildSummaryCard(
            title: 'Owner Details',
            icon: Icons.person_outline_rounded,
            items: [
              'Gender: ${data['gender'] ?? '—'}',
              'DOB: ${data['dob'] != null ? _formatDate(data['dob']) : '—'}',
            ],
          ),

          _buildSummaryCard(
            title: 'Partnership Role',
            icon: Icons.business_center_outlined,
            items: [
              'Role: $role',
            ],
          ),

          _buildSummaryCard(
            title: 'Contact Information',
            icon: Icons.contact_mail_outlined,
            items: [
              'Email: ${data['email'] ?? '—'}',
              'Phone: ${data['phone'] ?? '—'}',
            ],
          ),

          _buildSummaryCard(
            title: 'Address Details',
            icon: Icons.location_on_outlined,
            items: [
              '${data['address1'] ?? '—'}',
              if (data['address2']?.toString().isNotEmpty == true) '${data['address2']}',
              '${data['city'] ?? '—'}, ${data['state'] ?? '—'} - ${data['pincode'] ?? '—'}',
            ],
          ),

          _buildSummaryCard(
            title: 'Verification IDs',
            icon: Icons.verified_user_outlined,
            items: [
              'Aadhaar: ${data['aadhaarNumber'] ?? '—'}',
              'PAN: ${data['panNumber'] ?? '—'}',
            ],
          ),

          _buildSummaryCard(
            title: 'Host Preferences',
            icon: Icons.tune_rounded,
            items: [
              'Tenants: ${tenants.isEmpty ? 'Any' : tenants.join(', ')}',
              'Gender Pref: ${data['preferredGender'] ?? 'Any'}',
            ],
          ),

          _buildSummaryCard(
            title: 'Banking & Payouts',
            icon: Icons.account_balance_outlined,
            items: [
              'Account Name: ${data['bankAccName'] ?? '—'}',
              'Acc No: ${data['bankAccNo'] ?? '—'}',
              'IFSC: ${data['bankIfsc'] ?? '—'}',
              if (data['upiId']?.toString().isNotEmpty == true) 'UPI: ${data['upiId']}',
            ],
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: widget.onBack,
              child: const Text('Go back and edit details', style: TextStyle(color: AppTheme.textLightColor, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey[200],
            backgroundImage: data['profileImage'] != null ? NetworkImage(data['profileImage']) : null,
            child: data['profileImage'] == null ? const Icon(Icons.person, size: 35, color: Colors.grey) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Owner Name',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Partner Application',
                  style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required IconData icon, required List<String> items}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDarkColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(item, style: const TextStyle(fontSize: 15, color: Color(0xFF475569))),
          )),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.day} ${_getMonth(dt.month)} ${dt.year}";
    } catch (e) {
      return isoDate;
    }
  }

  String _getMonth(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
