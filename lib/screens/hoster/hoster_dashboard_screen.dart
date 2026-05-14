import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/screens/profile/profile_screen.dart' as sub;
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/services/booking_service.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/hoster/hoster_bottom_nav.dart';

class HosterDashboardScreen extends StatefulWidget {
  const HosterDashboardScreen({super.key});

  @override
  State<HosterDashboardScreen> createState() => _HosterDashboardScreenState();
}

class _HosterDashboardScreenState extends State<HosterDashboardScreen> {
  int _selectedIndex = 0;
  final PropertyService _propertyService = PropertyService();
  final BookingService _bookingService = BookingService();
  final HosterService _hosterService = HosterService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  Future<void> _handleNewListing(BuildContext context) async {
    // 1. Get current approval status from Firestore
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final data = doc.data();
      final status = data?['status'] ?? 'pending';

      if (data?['role'] != 'hoster' || status != HosterStatus.approved.name) {
        if (!context.mounted) return;
        _showNotApprovedDialog(context);
        return;
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ListPropertyScreen()),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying approval: $e')),
        );
      }
    }
  }

  void _showNotApprovedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: Colors.orange),
            SizedBox(width: 10),
            Text('Verification Pending', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your hoster account is currently under review. You can start listing properties once an administrator approves your profile.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _DashboardTab(uid: _uid, hosterService: _hosterService, bookingService: _bookingService),
      _PropertiesTab(uid: _uid, propertyService: _propertyService),
      _BookingsTab(uid: _uid, bookingService: _bookingService),
      const sub.ProfileScreen(showBottomNav: false),
    ];

    final titles = [
      'Hoster Dashboard',
      'My Properties',
      'Bookings Received',
      'Profile',
    ];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar:
          _selectedIndex == 3
              ? null
              : AppBar(
                backgroundColor: AppTheme.primaryColor,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  titles[_selectedIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.fontMD,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                actions:
                    _selectedIndex == 1
                        ? [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                            onPressed: () => _handleNewListing(context),
                            tooltip: 'List New Property',
                          ),
                        ]
                        : null,
              ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: HosterBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ── Dashboard Tab ────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final String uid;
  final HosterService hosterService;
  final BookingService bookingService;
  const _DashboardTab({
    required this.uid,
    required this.hosterService,
    required this.bookingService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: hosterService.getHosterStats(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {
          'totalProperties': 0,
          'totalBookings': 0,
          'totalEarnings': 0.0,
          'pendingBookings': 0,
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeCard(uid: uid),
              const SizedBox(height: 24),

              Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.textDarkColor,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('Properties', stats['totalProperties'].toString(), Icons.home_work_rounded, Colors.blue),
                  _buildStatCard('Total Bookings', stats['totalBookings'].toString(), Icons.book_rounded, Colors.green),
                  _buildStatCard('Earnings', '₹${stats['totalEarnings'].toStringAsFixed(0)}', Icons.payments_rounded, Colors.purple),
                  _buildStatCard('Pending', stats['pendingBookings'].toString(), Icons.pending_actions_rounded, Colors.orange),
                ],
              ),

              const SizedBox(height: 32),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.textDarkColor,
                ),
              ),
              const SizedBox(height: 16),
              _RecentBookings(uid: uid, bookingService: bookingService),
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textLightColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }
}

class _WelcomeCard extends StatelessWidget {
  final String uid;
  const _WelcomeCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final info = data?['info'] as Map<String, dynamic>? ?? {};
        final name = info['name'] as String? ?? 'Hoster';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'H',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to manage your properties today?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.1, end: 0);
      },
    );
  }
}

class _RecentBookings extends StatelessWidget {
  final String uid;
  final BookingService bookingService;
  const _RecentBookings({required this.uid, required this.bookingService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: bookingService.getHosterBookings(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs.take(3).toList() ?? [];

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'No recent activity',
                style: TextStyle(color: AppTheme.textMutedColor),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final status = data['status'] as String? ?? 'pending';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                title: Text(
                  data['studentName'] ?? 'Guest Student',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(data['propertyName'] ?? 'Property'),
                trailing: _StatusChip(status: status),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppTheme.successColor;
        break;
      case 'rejected':
      case 'cancelled':
        color = AppTheme.errorColor;
        break;
      default:
        color = AppTheme.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}

// ── Properties Tab ────────────────────────────────────────────────────────────
class _PropertiesTab extends StatelessWidget {
  final String uid;
  final PropertyService propertyService;
  const _PropertiesTab({required this.uid, required this.propertyService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: propertyService.getHosterProperties(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_work_outlined, size: 64, color: AppTheme.primaryColor.withOpacity(0.2)),
                const SizedBox(height: 16),
                const Text('No properties listed yet', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListPropertyScreen())),
                  child: const Text('Add Your First Property'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final basic = data['basicInfo'] as Map<String, dynamic>? ?? {};
            final images = data['images'] as List? ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                onTap: () {},
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: images.isNotEmpty
                            ? Image.network(images.first, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported, size: 40),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              basic['type'] ?? 'PG',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  basic['collegeName'] ?? 'Unnamed Property',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textMutedColor),
                                    const SizedBox(width: 4),
                                    Text(data['city'] ?? 'Location', style: const TextStyle(color: AppTheme.textMutedColor, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Bookings Tab ──────────────────────────────────────────────────────────────
class _BookingsTab extends StatelessWidget {
  final String uid;
  final BookingService bookingService;
  const _BookingsTab({required this.uid, required this.bookingService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: bookingService.getHosterBookings(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No bookings received yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final status = data['status'] as String? ?? 'pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.bookmark_rounded, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['propertyName'] ?? 'Property', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('For: ${data['studentName'] ?? 'Student'}', style: const TextStyle(color: AppTheme.textMutedColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount: ₹${data['price'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
