import 'package:flutter/material.dart';

class BookingTabs extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;

  const BookingTabs({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tabs: const [
        Tab(text: 'Confirmed Booking'),
        Tab(text: 'Pending Confirmation'),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}


