import 'package:flutter/material.dart';
import 'package:triangle_home/screens/profile/profile_screen.dart' as sub;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const sub.ProfileScreen(showBottomNav: true);
  }
}
