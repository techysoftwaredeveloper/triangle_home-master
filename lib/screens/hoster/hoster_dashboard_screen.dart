import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/screens/profile/profile_screen.dart' as sub;
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/hoster/hoster_bottom_nav.dart';

class HosterDashboardScreen extends StatefulWidget {
  const HosterDashboardScreen({super.key});

  @override
  State<HosterDashboardScreen> createState() => _HosterDashboardScreenState();
}

class _HosterDashboardScreenState extends State<HosterDashboardScreen> {
  int _selectedIndex = 0;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _DashboardTab(uid: _uid),
      _PropertiesTab(uid: _uid),
      _BookingsTab(uid: _uid),
      const sub.ProfileScreen(showBottomNav: false),
    ];

    final titles = [
      'Dashboard',
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
                title: Text(
                  titles[_selectedIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.fontLG,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                actions:
                    _selectedIndex == 1
                        ? [
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ListPropertyScreen(),
                                  ),
                                ),
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
      floatingActionButton:
          _selectedIndex == 1
              ? FloatingActionButton.extended(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ListPropertyScreen(),
                      ),
                    ),
                backgroundColor: AppTheme.primaryColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'List Property',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().scale(delay: 300.ms)
              : null,
    );
  }
}

// ── Dashboard Tab ────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final String uid;
  const _DashboardTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          _WelcomeCard(uid: uid),
          const SizedBox(height: AppTheme.spaceMD),

          // Stats row
          Row(
            children: [
              Expanded(child: _StatCard(uid: uid, type: 'properties')),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(child: _StatCard(uid: uid, type: 'bookings')),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(child: _StatCard(uid: uid, type: 'earnings')),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),

          // Recent bookings
          const Text(
            'Recent Bookings',
            style: TextStyle(
              fontSize: AppTheme.fontLG,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          _RecentBookings(uid: uid),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String uid;
  const _WelcomeCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('hoster').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final info = data?['info'] as Map<String, dynamic>? ?? {};
        final name = info['name'] as String? ?? 'Hoster';

        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'H',
                  style: const TextStyle(
                    fontSize: AppTheme.font2XL,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name!',
                      style: const TextStyle(
                        fontSize: AppTheme.fontLG,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage your properties and bookings',
                      style: TextStyle(
                        fontSize: AppTheme.fontSM,
                        color: Colors.white70,
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

class _StatCard extends StatelessWidget {
  final String uid;
  final String type; // 'properties' | 'bookings' | 'earnings'
  const _StatCard({required this.uid, required this.type});

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> stream;
    String label;
    IconData icon;
    Color color;

    switch (type) {
      case 'bookings':
        stream =
            FirebaseFirestore.instance
                .collection('bookings')
                .where('hosterId', isEqualTo: uid)
                .snapshots();
        label = 'Bookings';
        icon = Icons.book_rounded;
        color = AppTheme.accentColor;
        break;
      case 'earnings':
        stream =
            FirebaseFirestore.instance
                .collection('payments')
                .where('hosterId', isEqualTo: uid)
                .snapshots();
        label = 'Earnings';
        icon = Icons.currency_rupee_rounded;
        color = AppTheme.successColor;
        break;
      default: // 'properties'
        stream =
            FirebaseFirestore.instance
                .collection('properties')
                .where('hosterId', isEqualTo: uid)
                .snapshots();
        label = 'Properties';
        icon = Icons.apartment_rounded;
        color = AppTheme.primaryColor;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String value = '...';
        if (snapshot.hasData) {
          if (type == 'earnings') {
            final total = snapshot.data!.docs.fold<num>(0, (acc, doc) {
              final d = doc.data() as Map<String, dynamic>;
              return acc + ((d['amount'] as num?) ?? 0);
            });
            value = '₹$total';
          } else {
            value = snapshot.data!.docs.length.toString();
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spaceMD,
            horizontal: AppTheme.spaceSM,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppTheme.fontLG,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppTheme.fontXS,
                  color: AppTheme.textMutedColor,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
      },
    );
  }
}

class _RecentBookings extends StatelessWidget {
  final String uid;
  const _RecentBookings({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('bookings')
              .where('hosterId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spaceLG),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: const Center(
              child: Text(
                'No bookings yet',
                style: TextStyle(
                  color: AppTheme.textMutedColor,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          );
        }

        return Column(
          children:
              docs.asMap().entries.map((entry) {
                final i = entry.key;
                final data = entry.value.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? 'pending';
                final studentName = data['studentName'] as String? ?? 'Student';
                final propertyName =
                    data['propertyName'] as String? ?? 'Property';
                final amount = data['amount'];

                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
                  padding: const EdgeInsets.all(AppTheme.spaceMD),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            studentName.isNotEmpty
                                ? studentName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: AppTheme.fontBase,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDarkColor,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                            Text(
                              propertyName,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSM,
                                color: AppTheme.textLightColor,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (amount != null)
                            Text(
                              '₹$amount',
                              style: const TextStyle(
                                fontSize: AppTheme.fontBase,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          _StatusChip(status: status),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * i));
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
    switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: AppTheme.fontXS,
          color: color,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}

// ── Properties Tab ────────────────────────────────────────────────────────────
class _PropertiesTab extends StatelessWidget {
  final String uid;
  const _PropertiesTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('properties')
              .where('hosterId', isEqualTo: uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.apartment_outlined,
                    size: 64,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  const Text(
                    'No properties listed yet',
                    style: TextStyle(
                      fontSize: AppTheme.fontLG,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDarkColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  const Text(
                    'Tap the + button to list your first property',
                    style: TextStyle(
                      fontSize: AppTheme.fontBase,
                      color: AppTheme.textLightColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final basic = data['basicInfo'] as Map<String, dynamic>? ?? {};
            final property =
                data['propertyInfo'] as Map<String, dynamic>? ?? {};
            final name =
                basic['collegeName'] as String? ??
                data['collegeName'] as String? ??
                'Unnamed Property';
            final address =
                basic['addressLine1'] as String? ??
                data['addressLine1'] as String? ??
                '';
            final type =
                basic['type'] as String? ??
                data['type'] as String? ??
                'Property';
            final imageUrl =
                (property['images'] as List?)?.firstOrNull as String?;

            return _PropertyCard(
              name: name,
              address: address,
              type: type,
              imageUrl: imageUrl,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final String name;
  final String address;
  final String type;
  final String? imageUrl;
  final int index;

  const _PropertyCard({
    required this.name,
    required this.address,
    required this.type,
    this.imageUrl,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLG),
                  bottomLeft: Radius.circular(AppTheme.radiusLG),
                ),
                child:
                    imageUrl != null
                        ? Image.network(
                          imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                        : _placeholder(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: AppTheme.fontBase,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (address.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppTheme.textMutedColor,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                address,
                                style: const TextStyle(
                                  fontSize: AppTheme.fontXS,
                                  color: AppTheme.textLightColor,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            fontSize: AppTheme.fontXS,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 80 * index))
        .slideX(begin: 0.05, end: 0);
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 100,
      color: AppTheme.primaryColor.withValues(alpha: 0.08),
      child: const Icon(
        Icons.apartment_outlined,
        color: AppTheme.primaryColor,
        size: 32,
      ),
    );
  }
}

// ── Bookings Tab ──────────────────────────────────────────────────────────────
class _BookingsTab extends StatelessWidget {
  final String uid;
  const _BookingsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('bookings')
              .where('hosterId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No bookings received yet',
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontSize: AppTheme.fontBase,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'pending';
            final studentName = data['studentName'] as String? ?? 'Student';
            final propertyName = data['propertyName'] as String? ?? 'Property';
            final amount = data['amount'];
            final checkIn = data['checkIn'] as String? ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: AppTheme.fontBase,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    propertyName,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSM,
                      color: AppTheme.textLightColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      if (checkIn.isNotEmpty) ...[
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppTheme.textMutedColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Check-in: $checkIn',
                          style: const TextStyle(
                            fontSize: AppTheme.fontXS,
                            color: AppTheme.textMutedColor,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMD),
                      ],
                      if (amount != null) ...[
                        const Icon(
                          Icons.currency_rupee,
                          size: 14,
                          color: AppTheme.successColor,
                        ),
                        Text(
                          '$amount',
                          style: const TextStyle(
                            fontSize: AppTheme.fontSM,
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 80 * index));
          },
        );
      },
    );
  }
}
