import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/wishlist/wishlist_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> wishlistItems = [
      {
        'image':
            'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
        'price': 6500,
        'type': 'Twin Sharing',
        'title': 'Aurora Paying Guest Accommodation',
        'location': 'Anna Nagar, Mangalore',
        'isBooked': false,
      },
      {
        'image':
            'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
        'price': 4500,
        'type': 'Twin Sharing',
        'title': 'Aurora Paying Guest Accommodation',
        'location': 'Anna Nagar, Mangalore',
        'isBooked': true,
      },
      {
        'image':
            'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
        'price': 5500,
        'type': 'Twin Sharing',
        'title': 'Aurora Paying Guest Accommodation',
        'location': 'Anna Nagar, Mangalore',
        'isBooked': false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          // onPressed: () => Navigator.pop(context),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: wishlistItems.length,
        itemBuilder: (context, index) {
          return WishlistCard(
            item: wishlistItems[index],
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
        },
      ),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 1),
      // bottomNavigationBar: HomeBottomNavBar(
      //   selectedIndex: 1,
      //   onTap: (index) {},
      // ),
    );
  }
}
