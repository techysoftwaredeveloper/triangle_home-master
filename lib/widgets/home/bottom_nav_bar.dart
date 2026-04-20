import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/bookings_screen.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/screens/hoster/become_hoster_screen.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/screens/list_property/my_property_info_screen.dart';
import 'package:triangle_home/screens/wishlist_screen.dart';

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
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;

    if (phone == null) return const ListPropertyScreen();

    final snapshot =
        await FirebaseFirestore.instance
            .collection('properties')
            .where('hosterPhoneNumber', isEqualTo: phone)
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

    // Not logged in → go to login
    if (user == null) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              isStudent: false,
              onLoginNavigateTo: const ListPropertyScreen(),
            ),
          ),
        );
      }
      return;
    }

    // Check if user is an approved hoster
    final hosterDoc =
        await FirebaseFirestore.instance
            .collection('hoster')
            .doc(user.uid)
            .get();

    // If not found by uid, try by phone number
    Map<String, dynamic>? hosterData;
    if (!hosterDoc.exists) {
      final phone = user.phoneNumber;
      if (phone != null) {
        final phoneDoc =
            await FirebaseFirestore.instance
                .collection('hoster')
                .doc(phone)
                .get();

        if (phoneDoc.exists) {
          hosterData = phoneDoc.data();
        }
      }
    } else {
      hosterData = hosterDoc.data();
    }

    // Not a hoster at all → go to become hoster screen
    if (hosterData == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please register as a hoster first'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BecomeHosterScreen(),
          ),
        );
      }
      return;
    }

    // Check approval status
    final status = hosterData['status'] as String?;

    if (status == 'approved') {
      // Approved hoster → resolve to appropriate screen
      final screen = await _resolvePropertyScreen();
      if (context.mounted) {
        if (screen is ListPropertyScreen) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
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
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => _navigate(context, index),
      backgroundColor: Theme.of(context).primaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
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
          label: 'List A Property',
          isActive: selectedIndex == 3,
        ),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required String iconPath,
    required String label,
    required bool isActive,
  }) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        iconPath,
        height: 22,
        colorFilter: ColorFilter.mode(Colors.white70, BlendMode.srcIn),
      ),
      activeIcon: SvgPicture.asset(
        iconPath,
        height: 24,
        colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
      label: label,
    );
  }
}
