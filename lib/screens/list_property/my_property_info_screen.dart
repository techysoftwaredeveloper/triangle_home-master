// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class MyAddedPropertyScreen extends StatelessWidget {
//   const MyAddedPropertyScreen({super.key});

//   Future<QuerySnapshot> _fetchProperties() {
//     final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
//     return FirebaseFirestore.instance
//         .collection('properties')
//         .where('hosterPhone', isEqualTo: phone)
//         .get();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('My Added Properties')),
//       body: FutureBuilder<QuerySnapshot>(
//         future: _fetchProperties(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No properties added yet.'));
//           }

//           final properties = snapshot.data!.docs;

//           return ListView.builder(
//             itemCount: properties.length,
//             itemBuilder: (context, index) {
//               final property = properties[index].data() as Map<String, dynamic>;
//               final title =
//                   property['basicInfo']?['propertyName'] ?? 'Property';
//               final address = property['basicInfo']?['address'] ?? 'No address';
//               final images = property['images'] as List<dynamic>? ?? [];

//               return Card(
//                 margin: const EdgeInsets.all(12),
//                 child: ListTile(
//                   leading:
//                       images.isNotEmpty
//                           ? Image.network(
//                             images.first,
//                             width: 60,
//                             fit: BoxFit.cover,
//                           )
//                           : const Icon(Icons.home, size: 40),
//                   title: Text(
//                     title,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(address),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class MyAddedPropertyScreen extends StatelessWidget {
//   const MyAddedPropertyScreen({super.key});

//   Future<QuerySnapshot> _fetchProperties() {
//     final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
//     return FirebaseFirestore.instance
//         .collection('properties')
//         .where('hosterPhoneNumber', isEqualTo: phone)
//         .get();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('My Added Properties')),
//       body: FutureBuilder<QuerySnapshot>(
//         future: _fetchProperties(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return const Center(child: Text('Something went wrong'));
//           } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No properties added yet.'));
//           }

//           final properties = snapshot.data!.docs;

//           return ListView.builder(
//             itemCount: properties.length,
//             itemBuilder: (context, index) {
//               final data = properties[index].data() as Map<String, dynamic>;

//               final title = data['basicInfo']?['wardenName'] ?? 'Unnamed PG';
//               final address =
//                   "${data['pricingInfo']?['addressLine1'] ?? ''}, ${data['pricingInfo']?['locality'] ?? ''}";

//               final images =
//                   (data['images'] as List?) ??
//                   (data['propertyInfo']?['images'] as List?) ??
//                   [];

//               return Card(
//                 margin: const EdgeInsets.all(12),
//                 child: ListTile(
//                   leading:
//                       images.isNotEmpty
//                           ? ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.network(
//                               images.first,
//                               width: 60,
//                               height: 60,
//                               fit: BoxFit.cover,
//                             ),
//                           )
//                           : const Icon(Icons.home, size: 40),
//                   title: Text(
//                     title,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(address),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart'; // Ensure this file contains the ListPropertyScreen class
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/property_managment/property_card.dart';
import 'package:triangle_home/widgets/property_managment/payment_history_card.dart';

class MyAddedPropertyScreen extends StatefulWidget {
  const MyAddedPropertyScreen({super.key});

  @override
  State<MyAddedPropertyScreen> createState() => _MyAddedPropertyScreenState();
}

class _MyAddedPropertyScreenState extends State<MyAddedPropertyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String? _phone;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _phone = FirebaseAuth.instance.currentUser?.phoneNumber;
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
        children: [_buildPropertyHistory(), _buildPaymentHistory()],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListPropertyScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('List New Property'),
          ).animate().scale(),
           bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 3),
    );
  }

  Widget _buildPropertyHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('properties')
              .where('hosterPhoneNumber', isEqualTo: _phone)
              .snapshots(),
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
              'title': data['basicInfo']?['collegeName'] ?? 'Unnamed Property',
              'address':
                  "${data['pricingInfo']?['addressLine1'] ?? ''}, ${data['pricingInfo']?['locality'] ?? ''}",
              'status': 'Active',
              'type': data['basicInfo']?['type'] ?? 'PG/Hostel',
              'rooms': data['rooms'] ?? 0,
              'listed': 'Recently',
              'image':
                  (data['propertyInfo']?['images'] as List?)?.first ??
                  'https://via.placeholder.com/150',
            };

            return PropertyCard(
              property: property,
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
          },
        );
      },
    );
  }

  Widget _buildPaymentHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('payments')
              .where('hosterPhone', isEqualTo: _phone)
              .snapshots(),
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

            return PaymentHistoryCard(
              payment: payment,
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
          },
        );
      },
    );
  }
}
