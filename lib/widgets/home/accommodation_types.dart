// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class AccommodationTypes extends StatefulWidget {
//   const AccommodationTypes({super.key});

//   @override
//   State<AccommodationTypes> createState() => _AccommodationTypesState();
// }

// class _AccommodationTypesState extends State<AccommodationTypes> {
//   int selectedIndex = 0;

//   final List<String> tabs = [
//     'College Hostels',
//     'PG Accommodation',
//     'Apartments',
//   ];

//   final List<List<Map<String, dynamic>>> content = [
//     [
//       {'title': 'College Hostels For Men', 'icon': Icons.man},
//       {'title': 'College Hostels For Women', 'icon': Icons.woman},
//     ],
//     [
//       {'title': 'PG Accommodation for Men', 'icon': Icons.boy},
//       {'title': 'PG Accommodation for Women', 'icon': Icons.girl},
//     ],
//     [
//       {'title': 'Near My College/University', 'icon': Icons.apartment},
//       {'title': 'Around My City/Area', 'icon': Icons.home},
//     ],
//   ];

//   Widget _buildTab(String label, int index) {
//     final isSelected = selectedIndex == index;
//     return GestureDetector(
//       onTap: () => setState(() => selectedIndex = index),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: const Color.fromARGB(255, 255, 255, 255),
//               fontSize: 12,
//               fontFamily:  'outfit',

//               fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//             ),
//           ),
//           if (isSelected)
//             Container(
//               margin: const EdgeInsets.only(top: 6),
//               height: 2,
//               width: 70,
//               decoration: BoxDecoration(
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.9),
//                     blurRadius: 10,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//                 color: const Color.fromARGB(255, 255, 255, 255),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             )
//         ],
//       ),
//     );
//   }

//   Widget _buildTypeCard(String title, IconData icon) {
//     return Card(
//       elevation: 4,
//       margin: EdgeInsets.zero,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: ListTile(
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
//         leading: Icon(icon, size: 28, color: const Color.fromARGB(255, 5, 155, 224)),
//         title: Text(
//           title,
//           style: const TextStyle(
//             fontSize: 12,
//             fontFamily:  'outfit',
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         trailing: const Icon(Icons.chevron_right, color: Colors.black45),
//         onTap: () {},
//       ),
//     )
//         .animate()
//         .fadeIn(duration: 300.ms)
//         .slideY(begin: 0.1, end: 0);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(10),
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)], // Blue gradient
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Tab Row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: List.generate(tabs.length, (i) => _buildTab(tabs[i], i)),
//           ),
//           const SizedBox(height: 24),

//           // Animated Content Cards
//           ...content[selectedIndex].map((item) => Padding(
//                 padding: const EdgeInsets.only(bottom: 14),
//                 child: _buildTypeCard(item['title'], item['icon']),
//               )),
//         ],
//       ),
//     )
//         .animate()
//         .fadeIn(delay: 300.ms)
//         .slideY(begin: 0.1, end: 0);
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:triangle_home/AccommodationSearchScreen.dart';
// import 'package:triangle_home/ApartmentSearchScreen.dart';
// import 'package:triangle_home/screens/college_search_screen.dart';
// import 'package:triangle_home/theme/app_theme.dart';

// class AccommodationTypes extends StatefulWidget {
//   const AccommodationTypes({super.key});

//   @override
//   State<AccommodationTypes> createState() => _AccommodationTypesState();
// }

// class _AccommodationTypesState extends State<AccommodationTypes> {
//   int selectedIndex = 0;

//   final List<String> tabs = [
//     'College Hostels',
//     'PG Accommodation',
//     'Apartments',
//   ];

//   final List<List<Map<String, dynamic>>> content = [
//     [
//       {'title': 'College Hostels For Men', 'icon': 'assets/images/Boyface.svg'},
//       {
//         'title': 'College Hostels For Women',
//         'icon': 'assets/images/Girlface.svg',
//       },
//     ],
//     [
//       {'title': '.modation for Men', 'icon': 'assets/images/Boyface.svg'},
//       {
//         'title': 'PG Accommodation for Women',
//         'icon': 'assets/images/Girlface.svg',
//       },
//     ],
//     [
//       {
//         'title': 'Near My College/University',
//         'icon': 'assets/images/school.svg',
//       },
//       {'title': 'Around My City/Area', 'icon': 'assets/images/home_work.svg'},
//     ],
//   ];

//   void _handleCardTap(int tabIndex, int cardIndex) {
//     switch (tabIndex) {
//       case 0: // College Hostels
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const CollegeSearchScreen()),
//         );
//         break;
//       case 1: // PG Accommodation
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const AccommodationSearchScreen()),
//         );
//         break;
//       case 2: // Apartments
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const ApartmentSearchScreen()),
//         );
//         break;
//     }
//   }

//   Widget _buildTab(String label, int index) {
//     final isSelected = selectedIndex == index;
//     return GestureDetector(
//       onTap: () => setState(() => selectedIndex = index),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: const Color.fromARGB(255, 255, 255, 255),
//               fontSize: 12,
//               fontFamily: 'outfit',
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//             ),
//           ),
//           if (isSelected)
//             Container(
//               margin: const EdgeInsets.only(top: 6),
//               height: 2,
//               width: 70,
//               decoration: BoxDecoration(
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.9),
//                     blurRadius: 10,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//                 color: const Color.fromARGB(255, 255, 255, 255),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTypeCard(String title, String svgAssetPath, VoidCallback onTap) {
//     return Card(
//       elevation: 4,
//       margin: EdgeInsets.zero,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),

//         // ✅ SVG icon instead of IconData
//         leading: SvgPicture.asset(
//           svgAssetPath,
//           height: 28,
//           width: 28,
//           // Optional, remove if SVG has its own color
//         ),

//         title: Text(
//           title,
//           style: const TextStyle(
//             fontSize: 12,
//             fontFamily: 'outfit',
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         trailing: const Icon(Icons.chevron_right, color: Colors.black45),
//         onTap: onTap,
//       ),
//     ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(10),
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [AppTheme.primaryColor, AppTheme.primaryColor],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: List.generate(tabs.length, (i) => _buildTab(tabs[i], i)),
//           ),
//           const SizedBox(height: 24),
//           ...content[selectedIndex].asMap().entries.map((entry) {
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 14),
//               child: _buildTypeCard(
//                 entry.value['title'],
//                 entry.value['icon'],
//                 () => _handleCardTap(selectedIndex, entry.key),
//               ),
//             );
//           }),
//         ],
//       ),
//     ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:triangle_home/apartment_search_screen.dart';
import 'package:triangle_home/screens/college_search_screen.dart';
import 'package:triangle_home/screens/search_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AccommodationTypes extends StatefulWidget {
  const AccommodationTypes({super.key});

  @override
  State<AccommodationTypes> createState() => _AccommodationTypesState();
}

class _AccommodationTypesState extends State<AccommodationTypes> {
  int selectedIndex = 0;

  final List<String> tabs = [
    'College Hostels',
    'PG Accommodation',
    'Apartments',
  ];

  final List<List<Map<String, dynamic>>> content = [
    [
      {
        'title': 'College Hostels For Men',
        'icon': 'assets/images/Boyface.svg',
        'isCollege': true,
        'gender': 'Men',
      },
      {
        'title': 'College Hostels For Women',
        'icon': 'assets/images/Girlface.svg',
        'isCollege': true,
        'gender': 'Women',
      },
    ],
    [
      {
        'title': 'PG Accommodation for Men',
        'icon': 'assets/images/Boyface.svg',
        'searchType': 'By Area',
        'accommodationType': 'Paying Guest Hostels',
        'tenantType': 'Man',
      },
      {
        'title': 'PG Accommodation for Women',
        'icon': 'assets/images/Girlface.svg',
        'searchType': 'By Area',
        'accommodationType': 'Paying Guest Hostels',
        'tenantType': 'Woman',
      },
    ],
    [
      {
        'title': 'Near My College/University',
        'icon': 'assets/images/school.svg',
        'isApartment': true,
        'isByArea': false,
      },
      {
        'title': 'Around My City/Area',
        'icon': 'assets/images/home_work.svg',
        'isApartment': true,
        'isByArea': true,
      },
    ],
  ];

  void _handleCardTap(Map<String, dynamic> params) {
    if (params['isCollege'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CollegeSearchScreen(gender: params['gender']),
        ),
      );
    } else if (params['isApartment'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApartmentSearchScreen(isByArea: params['isByArea']),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchScreen(
            initialSearchType: params['searchType'],
            initialAccommodationType: params['accommodationType'],
            initialTenantType: params['tenantType'],
          ),
        ),
      );
    }
  }

  Widget _buildTab(String label, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color.fromARGB(255, 255, 255, 255),
              fontSize: AppTheme.fontSM,
              fontFamily: AppTheme.fontFamily,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 6),
              height: 2,
              width: 70,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.9),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String title, String svgAssetPath, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
          leading: SvgPicture.asset(svgAssetPath, height: 28, width: 28),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSM,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDarkColor,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.black45),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) => _buildTab(tabs[i], i)),
          ),
          const SizedBox(height: 24),
          ...content[selectedIndex].asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildTypeCard(
                entry.value['title'],
                entry.value['icon'],
                () => _handleCardTap(entry.value),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
