// import 'package:flutter/material.dart';
// import 'package:triangle_home/screens/search_screen.dart';
// import 'package:triangle_home/theme/app_theme.dart';
// import 'package:triangle_home/widgets/home/accommodation_types.dart';
// import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
// import 'package:triangle_home/widgets/home/city_tags.dart';
// import 'package:triangle_home/widgets/home/enrollment_card.dart';
// import 'package:triangle_home/widgets/home/nearby_accommodations.dart';
// import 'package:triangle_home/widgets/home/top_hostels.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   //int _selectedIndex = 0;

//   final List<String> _cities = [
//     'Bangalore',
//     'Chennai',
//     'Kochi',
//     'Mangalore',
//   ];

//   final List<Map<String, String>> _topHostels = [
//     {
//       'name': 'Yenepoya University',
//       'location': 'Mangalore, Karnataka',
//       'image': 'https://demo3.chillipages.com/Yenepoya-2023/yenepoya-ayurveda-college/og.png',
//     },
//     {
//       'name': 'Yenepoya Medical',
//       'location': 'Bangalore, Karnataka',
//       'image': 'https://demo3.chillipages.com/Yenepoya-2023/yenepoya-ayurveda-college/og.png',
//     },
//     {
//       'name': 'S-Vyas University',
//       'location': 'chennai, Tamil Nadu',
//       'image': 'https://www.turiya.co/360/SVYASA/Assets/clientlogo1.png',
//     },
//   ];

//   final List<Map<String, dynamic>> _accommodations = [
//     {
//       'title': 'Aurora Paying Guest Accommodation',
//       'location': 'Anna Nagar, Chennai',
//       'type': 'Twin Sharing',
//       'price': 6500,
//       'image': 'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
//     },
//     {
//       'title': 'Aurora Deluxe PG',
//       'location': 'Anna Nagar, Chennai',
//       'type': 'Twin Sharing',
//       'price': 7500,
//       'image': 'https://images.pexels.com/photos/271618/pexels-photo-271618.jpeg',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: _buildAppBar(context),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             CityTags(cities: _cities),
//             const AccommodationTypes(),
//             TopHostels(hostels: _topHostels),
//             NearbyAccommodations(accommodations: _accommodations),
//             const EnrollmentCard(),
//           ],
//         ),
//       ),
//       bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 0),
//       // bottomNavigationBar: HomeBottomNavBar(
//       //   selectedIndex: _selectedIndex,
//       //   onTap: (index) => setState(() => _selectedIndex = index),
//       // ),
//     );
//   }

// PreferredSizeWidget _buildAppBar(BuildContext context) {
//   return PreferredSize(
//     preferredSize: const Size.fromHeight(150),
//     child: Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [AppTheme.primaryColor, AppTheme.accentColor],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(20),
//           bottomRight: Radius.circular(20),
//         ),
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Image.asset(
//                     'assets/images/logomain.png',
//                     height: 50,
//                     width: 50,
//                   ),
//                   const SizedBox(width: 8),
//                   const Text(
//                     'TRIANGLE HOMES',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: 1.2,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               // ⬇️ Wrapped with GestureDetector
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const SearchScreen()),
//                   );
//                 },
//                 child: Container(
//                   height: 45,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(30),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: IgnorePointer(
//                     child: TextField(
//                       controller: _searchController,
//                       decoration: InputDecoration(
//                         hintText: 'Search for Area/City/College',
//                         hintStyle: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 14,
//                         ),
//                         prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                         border: InputBorder.none,
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 12,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ).animate().fadeIn().slideY(begin: -0.2, end: 0),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }

//--------------------------------------------------------------------------

// PreferredSizeWidget _buildAppBar() {
//   return AppBar(
//     backgroundColor: Theme.of(context).primaryColor,
//     elevation: 0,
//     toolbarHeight: 150,

//     title: Column(

//       children: [
//         Row(
//           children: [
//           //  TriangleLogo(size: 24),
//            Image.asset(
//               'assets/images/logomain.png',
//               height: 50,
//               width: 50,
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               'TRIANGLE HOMES',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 letterSpacing: 1.2,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Container(
//           height: 45,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(30),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: 'Search for Area/City/College',
//               hintStyle: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//               prefixIcon: const Icon(Icons.search, color: Colors.grey),
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 20,
//                 vertical: 12,
//               ),
//             ),
//           ),
//         ).animate().fadeIn().slideY(begin: -0.2, end: 0),
//       ],
//     ),
//     // leading: IconButton(
//     //   icon: const Icon(Icons.menu, color: Colors.white),
//     //   onPressed: () {},
//     // ),
//   );
// }
//---------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/search_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/home/accommodation_types.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/home/city_tags.dart';
import 'package:triangle_home/widgets/home/enrollment_card.dart';
import 'package:triangle_home/widgets/home/nearby_accommodations.dart';
import 'package:triangle_home/widgets/home/top_hostels.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _cities = ['Bangalore', 'Chennai', 'Kochi', 'Mangalore'];

  final List<Map<String, String>> _topHostels = [
    {
      'name': 'Yenepoya University',
      'location': 'Mangalore, Karnataka',
      'image':
          'https://demo3.chillipages.com/Yenepoya-2023/yenepoya-ayurveda-college/og.png',
    },
    {
      'name': 'Yenepoya Medical',
      'location': 'Bangalore, Karnataka',
      'image':
          'https://demo3.chillipages.com/Yenepoya-2023/yenepoya-ayurveda-college/og.png',
    },
    {
      'name': 'S-Vyas University',
      'location': 'Chennai, Tamil Nadu',
      'image': 'https://www.turiya.co/360/SVYASA/Assets/clientlogo1.png',
    },
  ];

  List<Map<String, dynamic>> _accommodations = [];

  @override
  void initState() {
    super.initState();
    _fetchPropertiesFromFirestore();
  }

  Future<void> _fetchPropertiesFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('properties').get();
      final List<Map<String, dynamic>> properties =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'title': data['collegeName'] ?? 'Unnamed Property',
              'location':
                  "${data['addressLine1'] ?? ''}, ${data['city'] ?? ''}",
              'type': data['type'] ?? 'N/A',
              'price':
                  int.tryParse(data['price1']?.replaceAll(',', '') ?? '0') ?? 0,
              'image':
                  (data['imageUrls'] is List && data['imageUrls'].isNotEmpty)
                      ? data['imageUrls'][0]
                      : 'https://via.placeholder.com/150',
            };
          }).toList();

      setState(() {
        _accommodations = properties;
      });
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CityTags(cities: _cities),
            const AccommodationTypes(),
            TopHostels(hostels: _topHostels),
            NearbyAccommodations(accommodations: _accommodations),
            const EnrollmentCard(),
          ],
        ),
      ),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 0),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(150),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logomain.png',
                      height: 50,
                      width: 50,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'TRIANGLE HOMES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IgnorePointer(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for Area/City/College',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
