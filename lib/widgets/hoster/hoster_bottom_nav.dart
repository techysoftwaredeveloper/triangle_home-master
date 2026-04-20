import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class HosterBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const HosterBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textMutedColor,
      selectedLabelStyle: const TextStyle(
        fontSize: AppTheme.fontXS,
        fontWeight: FontWeight.w600,
        fontFamily: AppTheme.fontFamily,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: AppTheme.fontXS,
        fontFamily: AppTheme.fontFamily,
      ),
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apartment_outlined),
          activeIcon: Icon(Icons.apartment_rounded),
          label: 'Properties',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book_rounded),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
