import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/screens/profile/edit_profile_screen.dart';

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Profile not found')));
        }

        final userData = snapshot.data!.data()!;
        final info = userData['info'] as Map? ?? {};
        final role = userData['role'] ?? 'student';
        final verif = userData['verification'] as Map? ?? {};

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBgColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Profile Details',
              style: TextStyle(
                color: AppTheme.textColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSection(
                  'Personal Information',
                  [
                    _buildInfoTile(Icons.person_outline, 'Full Name', info['name'] ?? 'N/A'),
                    _buildInfoTile(Icons.email_outlined, 'Email', info['email'] ?? user.email ?? 'N/A'),
                    _buildInfoTile(Icons.phone_android_outlined, 'Phone', info['phoneNumber'] ?? 'N/A'),
                    _buildInfoTile(Icons.wc_outlined, 'Gender', info['gender'] ?? 'N/A'),
                    _buildInfoTile(
                      Icons.cake_outlined,
                      'Date of Birth',
                      info['dob'] != null ? DateFormat('dd MMM yyyy').format((info['dob'] as Timestamp).toDate()) : 'N/A',
                    ),
                    _buildInfoTile(Icons.location_on_outlined, 'Current Location', info['location'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 24),
                if (role == 'student')
                  _buildSection(
                    'Student Information',
                    [
                      _buildInfoTile(Icons.account_balance_outlined, 'College', (userData['student_info'] as Map?)?['college'] ?? 'N/A'),
                      _buildInfoTile(Icons.book_outlined, 'Course', (userData['student_info'] as Map?)?['course'] ?? 'N/A'),
                      _buildInfoTile(Icons.timer_outlined, 'Semester', (userData['student_info'] as Map?)?['semester'] ?? 'N/A'),
                      _buildInfoTile(Icons.badge_outlined, 'Student ID', (userData['student_info'] as Map?)?['studentId'] ?? 'N/A'),
                    ],
                  )
                else
                  _buildSection(
                    'Professional Information',
                    [
                      _buildInfoTile(Icons.business_outlined, 'Company', (userData['professional_info'] as Map?)?['companyName'] ?? 'N/A'),
                      _buildInfoTile(Icons.work_outline, 'Designation', (userData['professional_info'] as Map?)?['jobTitle'] ?? 'N/A'),
                      _buildInfoTile(Icons.location_on_outlined, 'Work Location', (userData['professional_info'] as Map?)?['workLocation'] ?? 'N/A'),
                      _buildInfoTile(Icons.history, 'Experience', (userData['professional_info'] as Map?)?['experience'] ?? 'N/A'),
                    ],
                  ),
                const SizedBox(height: 24),
                _buildSection(
                  'Housing Preferences',
                  [
                    _buildInfoTile(Icons.home_outlined, 'Looking For', (userData['housing_preferences'] as Map?)?['propertyType'] ?? 'N/A'),
                    _buildInfoTile(
                      Icons.payments_outlined,
                      'Monthly Budget',
                      '₹${(userData['housing_preferences'] as Map?)?['budgetMin'] ?? 0} - ₹${(userData['housing_preferences'] as Map?)?['budgetMax'] ?? 0}',
                    ),
                    _buildInfoTile(Icons.location_city_outlined, 'Preferred City', (userData['housing_preferences'] as Map?)?['preferredCity'] ?? 'N/A'),
                    _buildInfoTile(Icons.timer_outlined, 'Stay Duration', (userData['housing_preferences'] as Map?)?['stayDuration'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Emergency Contact',
                  [
                    _buildInfoTile(Icons.contact_phone_outlined, 'Name', (userData['emergency_contact'] as Map?)?['name'] ?? 'N/A'),
                    _buildInfoTile(Icons.people_outline, 'Relationship', (userData['emergency_contact'] as Map?)?['relationship'] ?? 'N/A'),
                    _buildInfoTile(Icons.phone_outlined, 'Phone', (userData['emergency_contact'] as Map?)?['phone'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textMutedColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLightColor,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
