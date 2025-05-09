// import 'package:flutter/material.dart';

// class HomeBottomNavBar extends StatelessWidget {
//   final int selectedIndex;
//   final Function(int) onTap;

//   const HomeBottomNavBar({
//     super.key,
//     required this.selectedIndex,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: selectedIndex,
//       onTap: onTap,
//       type: BottomNavigationBarType.fixed,
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home),
//           label: 'Home',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.star),
//           label: 'My Wishlist',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.book),
//           label: 'My PG Bookings',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.add_business),
//           label: 'List A Property',
//         ),
//       ],
//     );
//   }
// }

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/screens/bookings_screen.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/screens/profile/profile_screen.dart';
import 'package:triangle_home/screens/wishlist_screen.dart';


class HomeBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const HomeBottomNavBar({
    super.key,
    required this.selectedIndex,
  });

void _navigate(BuildContext context, int index) {
  // Prevent re-navigating to the same screen
  if (ModalRoute.of(context)?.settings.name == _routeName(index)) return;

  Widget screen;
  switch (index) {
    case 0:
      screen = const HomeScreen();
      break;
    case 1:
      screen = const WishlistScreen();
      break;
    case 2:
      screen = BookingsScreen();
      break;
    case 3:
      screen = const ListPropertyScreen();
      break;
    case 4:
      screen = const ProfileScreen();
      break;
    default:
      screen = const HomeScreen();
  }

  if (index == 0) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen, settings: RouteSettings(name: _routeName(index))),
      (route) => false,
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen, settings: RouteSettings(name: _routeName(index))),
    );
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
    case 4:
      return '/profile';
    default:
      return '/home';
  }
}


  // void _navigate(BuildContext context, int index) {
  //   Widget screen;
  //   switch (index) {
  //     case 0:
  //       screen = const HomeScreen();
  //       break;
  //     case 1:
  //       screen = const WishlistScreen();
  //       break;
  //     case 2:
  //       screen = const BookingsScreen();
  //       break;
  //     case 3:
  //       screen = const ListpropertyScreen();
  //       break;
  //     case 4:
  //       screen = const ProfileScreen();
  //       break;
  //     default:
  //       screen = const HomeScreen();
  //   }

  //   if (index == 0) {
  //     // Replace for home to avoid stacking multiple home screens
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => HomeScreen()),
  //     );
  //   } else {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => screen),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return ConvexAppBar(
      style: TabStyle.titled,
      height: 50,
      backgroundColor: Theme.of(context).primaryColor,
      activeColor: Colors.white,
      color: Colors.white70,

      initialActiveIndex: selectedIndex,
      onTap: (index) => _navigate(context, index),
      items: const [
        TabItem(icon: Icons.home, title: 'Home'),
        TabItem(icon: Icons.star, title: 'Favourite'),
        TabItem(icon: Icons.book, title: 'Bookings'),
        TabItem(icon: Icons.add_business, title: 'Property'),
        TabItem(icon: Icons.person, title: 'Profile'),
      ],
    );
  }
}

