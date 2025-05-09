import 'package:flutter/material.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Your profile details go here')),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 4),
    );
  }
}
