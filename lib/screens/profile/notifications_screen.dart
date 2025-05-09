import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _newListings = true;
  bool _bookingUpdates = true;
  bool _paymentReminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notification Channels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive updates via email'),
          ).animate().fadeIn().slideX(),
          SwitchListTile(
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive instant notifications on your device'),
          ).animate().fadeIn().slideX(),
          SwitchListTile(
            value: _smsNotifications,
            onChanged: (value) => setState(() => _smsNotifications = value),
            title: const Text('SMS Notifications'),
            subtitle: const Text('Receive updates via SMS'),
          ).animate().fadeIn().slideX(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notification Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            value: _newListings,
            onChanged: (value) => setState(() => _newListings = value),
            title: const Text('New Listings'),
            subtitle: const Text('Get notified about new properties'),
          ).animate().fadeIn().slideX(),
          SwitchListTile(
            value: _bookingUpdates,
            onChanged: (value) => setState(() => _bookingUpdates = value),
            title: const Text('Booking Updates'),
            subtitle: const Text('Status updates for your bookings'),
          ).animate().fadeIn().slideX(),
          SwitchListTile(
            value: _paymentReminders,
            onChanged: (value) => setState(() => _paymentReminders = value),
            title: const Text('Payment Reminders'),
            subtitle: const Text('Reminders for upcoming payments'),
          ).animate().fadeIn().slideX(),
        ],
      ),
    );
  }
}