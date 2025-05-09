import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/widgets/bookingscreen/booking_card.dart';
import 'package:triangle_home/widgets/bookingscreen/booking_tabs.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';


class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _confirmedBookings = [
    {
      'image': 'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
      'price': 6500,
      'type': 'Twin Sharing',
      'title': 'Aurora Paying Guest Accommodation',
      'location': 'Anna Nagar, Mangalore',
      'status': 'confirmed',
    },
    {
      'image': 'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
      'price': 4500,
      'type': 'Twin Sharing',
      'title': 'Aurora Paying Guest Accommodation',
      'location': 'Anna Nagar, Mangalore',
      'status': 'confirmed',
    },
  ];

  final List<Map<String, dynamic>> _pendingBookings = [
    {
      'image': 'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
      'price': 6500,
      'type': 'Twin Sharing',
      'title': 'Aurora Paying Guest Accommodation',
      'location': 'Anna Nagar, Mangalore',
      'status': 'pending',
    },
    {
      'image': 'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
      'price': 4500,
      'type': 'Twin Sharing',
      'title': 'Aurora Paying Guest Accommodation',
      'location': 'Anna Nagar, Mangalore',
      'status': 'pending',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Paying Guest Bookings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: BookingTabs(controller: _tabController),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Confirmed Bookings Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _confirmedBookings.length,
            itemBuilder: (context, index) {
              return BookingCard(
                booking: _confirmedBookings[index],
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
            },
          ),
          
          // Pending Bookings Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pendingBookings.length,
            itemBuilder: (context, index) {
              return BookingCard(
                booking: _pendingBookings[index],
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
            },
          ),
        ],
      ),
       bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 2),
      // bottomNavigationBar: const HomeBottomNavBar(
      //   selectedIndex: 2,
      //   onTap: null,
      // ),
    );
  }
}