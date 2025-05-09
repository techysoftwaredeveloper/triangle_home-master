import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/widgets/property_managment/payment_history_card.dart';
import 'package:triangle_home/widgets/property_managment/property_card.dart';

class PropertyManagementScreen extends StatefulWidget {
  const 
  
  PropertyManagementScreen({super.key});

  @override
  State<PropertyManagementScreen> createState() => _PropertyManagementScreenState();
}

class _PropertyManagementScreenState extends State<PropertyManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      appBar: AppBar(
        title: const Text('My Properties'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Property History'),
            Tab(text: 'Payment History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPropertyHistory(),
          _buildPaymentHistory(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ListPropertyScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('List New Property'),
      ).animate().scale(),
    );
  }

  // Widget _buildPropertyHistory() {
  //   final properties = [
  //     {
  //       'title': 'Aurora PG Accommodation',
  //       'address': 'Anna Nagar, Chennai',
  //       'status': 'Active',
  //       'type': 'PG/Hostel',
  //       'rooms': 12,
  //       'listed': '15 Jan 2024',
  //       'image': 'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
  //     },
  //     {
  //       'title': 'Sunshine Apartments',
  //       'address': 'Velachery, Chennai',
  //       'status': 'Under Review',
  //       'type': 'Apartment',
  //       'rooms': 8,
  //       'listed': '10 Mar 2024',
  //       'image': 'https://images.pexels.com/photos/271618/pexels-photo-271618.jpeg',
  //     },
  //   ];

  //   return ListView.builder(
  //     padding: const EdgeInsets.all(16),
  //     itemCount: properties.length,
  //     itemBuilder: (context, index) {
  //       return PropertyCard(
  //         property: properties[index],
  //       ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
  //     },
  //   );
  // }

  // Widget _buildPaymentHistory() {
  //   final payments = [
  //     {
  //       'propertyName': 'Aurora PG Accommodation',
  //       'tenantName': 'John Doe',
  //       'amount': 15000,
  //       'date': '2024-03-01',
  //       'status': 'Completed',
  //       'type': 'Rent',
  //     },
  //     {
  //       'propertyName': 'Aurora PG Accommodation',
  //       'tenantName': 'Jane Smith',
  //       'amount': 20000,
  //       'date': '2024-02-28',
  //       'status': 'Pending',
  //       'type': 'Deposit',
  //     },
  //   ];

  //   return ListView.builder(
  //     padding: const EdgeInsets.all(16),
  //     itemCount: payments.length,
  //     itemBuilder: (context, index) {
  //       return PaymentHistoryCard(
  //         payment: payments[index],
  //       ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
  //     },
  //   );
  // }

  Widget _buildPropertyHistory() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('properties').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return const Center(child: Text('Failed to load properties.'));
      }

      final docs = snapshot.data?.docs ?? [];

      if (docs.isEmpty) {
        return const Center(child: Text('No properties listed yet.'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;

          final property = {
            'title': data['collegeName'] ?? 'Unnamed Property',
            'address': "${data['addressLine1'] ?? ''}, ${data['locality'] ?? ''}",
            'status': 'Active', // or dynamic field if available
            'type': data['type'] ?? 'Unknown',
            'rooms': data['rooms'] ?? 0,
            'listed': 'Today',  // Format if needed
            'image': data['imageUrl'] ?? 'https://via.placeholder.com/150',
          };

          return PropertyCard(property: property)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index));
        },
      );
    },
  );
}

Widget _buildPaymentHistory() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('payments').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return const Center(child: Text('Failed to load payments.'));
      }

      final docs = snapshot.data?.docs ?? [];

      if (docs.isEmpty) {
        return const Center(child: Text('No payment history found.'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;

          final payment = {
            'propertyName': data['propertyName'] ?? 'Unknown Property',
            'tenantName': data['tenantName'] ?? 'Tenant',
            'amount': data['amount'] ?? 0,
            'date': data['date'] ?? 'Unknown Date',
            'status': data['status'] ?? 'Pending',
            'type': data['type'] ?? 'Rent',
          };

          return PaymentHistoryCard(payment: payment)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index));
        },
      );
    },
  );
}

}