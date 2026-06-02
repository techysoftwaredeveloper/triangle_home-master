import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/services/booking_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/bookingscreen/booking_card.dart';
import 'package:triangle_home/widgets/bookingscreen/booking_tabs.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';

class BookingsScreen extends StatefulWidget {
  final Map<String, dynamic>? newBooking;

  const BookingsScreen({super.key, this.newBooking});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();

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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'My Paying Guest Bookings',
          style: TextStyle(
            color: AppTheme.textOnPrimary,
            fontSize: AppTheme.fontLG,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        bottom: BookingTabs(controller: _tabController),
      ),
      body:
          user == null
              ? _buildEmptyState('Please login to view your bookings')
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(status: BookingStatus.bookingConfirmed),
                  _buildBookingsList(status: BookingStatus.inquiryCreated),
                ],
              ),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildBookingsList({required BookingStatus status}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildEmptyState('Please login');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _bookingService.getStudentBookings(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allDocs = snapshot.data?.docs ?? [];

        // Filter by status
        final filteredDocs =
            allDocs.where((doc) {
              final data = doc.data();
              return data['status'] == status.name;
            }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(
            status == BookingStatus.bookingConfirmed
                ? 'No confirmed bookings'
                : 'No pending bookings',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data();
            final propertyData =
                data['propertyData'] as Map<String, dynamic>? ?? {};

            // Safely get image from property data
            String imageUrl = '';
            if (propertyData['images'] is List &&
                (propertyData['images'] as List).isNotEmpty) {
              imageUrl = propertyData['images'][0].toString();
            } else if (propertyData['image'] is String) {
              imageUrl = propertyData['image'];
            }

            final booking = {
              'id': doc.id,
              'propertyId': data['propertyId'],
              'image': imageUrl,
              'price': data['price'] ?? 0,
              'type': data['type'] ?? '',
              'title': propertyData['title'] ?? 'Property',
              'location':
                  propertyData['address'] ??
                  propertyData['location'] ??
                  'Unknown location',
              'status': data['status'],
              'paymentStatus': data['paymentStatus'],
              'tenantDetails': data['tenantDetails'],
              'createdAt': data['createdAt'],
            };

            return BookingCard(
              booking: booking,
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textLightColor,
              fontSize: AppTheme.fontMD,
              fontFamily: AppTheme.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
