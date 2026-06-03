import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/bookings_screen.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/screens/list_property/intro_screen.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/screens/list_property/my_property_info_screen.dart';
import 'package:triangle_home/screens/wishlist_screen.dart';
import 'package:triangle_home/screens/suggest_property/suggest_property_intro_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const HomeBottomNavBar({super.key, required this.selectedIndex});

  Future<void> _navigate(BuildContext context, int index) async {
    if (ModalRoute.of(context)?.settings.name == _routeName(index)) return;

    final user = FirebaseAuth.instance.currentUser;

    // Handle index 3 (List A Property) with verification check
    if (index == 3) {
      await _handleListPropertyNavigation(context);
      return;
    }

    if (user == null && (index == 1 || index == 2)) {
      Widget? targetScreen;
      bool isStudent = true;

      switch (index) {
        case 1:
          targetScreen = const WishlistScreen();
          break;
        case 2:
          targetScreen = BookingsScreen();
          break;
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => LoginScreen(
                  isStudent: isStudent,
                  onLoginNavigateTo: targetScreen,
                ),
          ),
        );
      }
      return;
    }

    Widget screen;
    switch (index) {
      case 0:
        screen = HomeScreen();
        break;
      case 1:
        screen = const WishlistScreen();
        break;
      case 2:
        screen = BookingsScreen();
        break;
      case 3:
        screen = await _resolvePropertyScreen();
        break;
      default:
        screen = HomeScreen();
    }

    if (!context.mounted) return;

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => screen,
          settings: RouteSettings(name: _routeName(index)),
        ),
        (route) => false,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => screen,
          settings: RouteSettings(name: _routeName(index)),
        ),
      );
    }
  }

  Future<Widget> _resolvePropertyScreen() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const ListPropertyScreen();

    final snapshot =
        await FirebaseFirestore.instance
            .collection('properties')
            .where('hoster_id', isEqualTo: uid)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      return const MyAddedPropertyScreen();
    } else {
      return const ListPropertyScreen();
    }
  }

  /// Handles navigation for "List A Property" with verification check
  Future<void> _handleListPropertyNavigation(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    // Not logged in → go to Intro Screen first
    if (user == null || user.isAnonymous) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ListPropertyIntroScreen(
                  onGetStarted: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => LoginScreen(
                              isStudent: false,
                              onLoginNavigateTo: const ListPropertyScreen(),
                            ),
                      ),
                    );
                  },
                ),
          ),
        );
      }
      return;
    }

    // Check if user is an approved hoster in the unified 'users' collection
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    Map<String, dynamic>? userData = userDoc.data();

    // Not a hoster at all → go to Suggest Property Intro
    if (userData == null || userData['role'] != 'hoster') {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SuggestPropertyIntroScreen()),
        );
      }
      return;
    }

    // Check approval status (legacy field 'status' or new logic)
    // Note: If you don't have a status field yet, you might want to default to 'approved'
    // or 'pending' depending on your requirements.
    final status = userData['status'] as String? ?? 'approved';

    if (status == 'approved') {
      // Approved hoster → resolve to appropriate screen
      final screen = await _resolvePropertyScreen();
      if (context.mounted) {
        if (screen is ListPropertyScreen) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => screen),
            (route) => false,
          );
        }
      }
    } else if (status == 'pending') {
      // Pending approval → show message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your hoster registration is pending approval. Please wait.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else if (status == 'rejected') {
      // Rejected → show message and offer to reapply
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your hoster registration was rejected. Please contact support.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Unknown status → treat as pending
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is under review'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _routeName(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/wishlist';
      case 2:
        return '/bookings';
      case 3:
        return '/listpg';
      default:
        return '/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _navigate(context, index),
          backgroundColor: AppTheme.primaryColor,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withValues(alpha: 0.6),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            fontFamily: 'Outfit',
          ),
          items: [
            _buildNavItem(
              iconPath: 'assets/images/Homeicon.svg',
              label: 'Home',
              isActive: selectedIndex == 0,
            ),
            _buildNavItem(
              iconPath: 'assets/images/mywishlisticon.svg',
              label: 'My Wishlist',
              isActive: selectedIndex == 1,
            ),
            _buildNavItem(
              iconPath: 'assets/images/mypgbookings.svg',
              label: 'My Bookings',
              isActive: selectedIndex == 2,
            ),
            _buildNavItem(
              iconPath: 'assets/images/listmyproperty.svg',
              label:
                  FirebaseAuth.instance.currentUser == null
                      ? 'List A Property'
                      : 'Suggest',
              isActive: selectedIndex == 3,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required String iconPath,
    required String label,
    required bool isActive,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SvgPicture.asset(
          iconPath,
          height: 20,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: isActive ? 1.0 : 0.6),
            BlendMode.srcIn,
          ),
        ),
      ),
      label: label,
    );
  }
}
