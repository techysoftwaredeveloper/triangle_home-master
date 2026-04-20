// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:triangle_home/screens/list_property/banking_info_screen.dart';
// import 'package:triangle_home/screens/list_property/basic_info_screen.dart';
// import 'package:triangle_home/screens/list_property/pricing_info_screen.dart';
// import 'package:triangle_home/screens/list_property/property_info_screen.dart';
// import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
// import 'package:triangle_home/widgets/list_property/progress_bar.dart';

// class ListPropertyScreen extends StatefulWidget {
//   const ListPropertyScreen({super.key});

//   @override
//   State<ListPropertyScreen> createState() => _ListPropertyScreenState();
// }

// class _ListPropertyScreenState extends State<ListPropertyScreen> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   final Map<String, dynamic> _propertyData = {};

//   void _nextPage(Map<String, dynamic> data) {
//     _propertyData.addAll(data);
//     if (_currentPage < 3) {
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   void _previousPage() {
//     if (_currentPage > 0) {
//       _pageController.previousPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     } else {
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E3A8A),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: _previousPage,
//         ),
//         title: const Text(
//           'List My Property',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           ProgressBar(currentStep: _currentPage),
//           Expanded(
//             child: PageView(
//               controller: _pageController,
//               physics: const NeverScrollableScrollPhysics(),
//               onPageChanged: (page) => setState(() => _currentPage = page),
//               children: [
//                 BasicInfoScreen(onContinue: _nextPage),
//                 BankingInfoScreen(onContinue: _nextPage),
//                 PropertyInfoScreen(onContinue: (data) => _nextPage(data)),
//                 PricingInfoScreen(
//                   onContinue: (data) async {
//                     _propertyData.addAll(data);
//                     try {
//                       // add property to database
//                       await FirebaseFirestore.instance
//                           .collection('properties')
//                           .add(_propertyData);

//                       if (mounted) {
//                         Navigator.popUntil(context, (route) => route.isFirst);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('Property listed successfully!'),
//                           ),
//                         );
//                       }
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                             'An error occurred while listing the property: $e',
//                           ),
//                         ),
//                       );
//                     }
//                   }, propertyData: {},
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 3),
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:triangle_home/screens/list_property/banking_info_screen.dart';
// import 'package:triangle_home/screens/list_property/basic_info_screen.dart';
// import 'package:triangle_home/screens/list_property/pricing_info_screen.dart';
// import 'package:triangle_home/screens/list_property/property_info_screen.dart';
// import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
// import 'package:triangle_home/widgets/list_property/progress_bar.dart';

// class ListPropertyScreen extends StatefulWidget {
//   const ListPropertyScreen({super.key});

//   @override
//   State<ListPropertyScreen> createState() => _ListPropertyScreenState();
// }

// class _ListPropertyScreenState extends State<ListPropertyScreen> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   final Map<String, dynamic> _propertyData = {};

//   void _nextPage(Map<String, dynamic> data) {
//     setState(() {
//       _propertyData.addAll(data);

//       // Print data for debugging
//       debugPrint('Current Property Data: $_propertyData');

//       if (_currentPage < 3) {
//         _pageController.nextPage(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//       }
//     });
//   }

//   void _previousPage() {
//     if (_currentPage > 0) {
//       _pageController.previousPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     } else {
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E3A8A),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: _previousPage,
//         ),
//         title: const Text(
//           'List My Property',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           ProgressBar(currentStep: _currentPage),
//           Expanded(
//             child: PageView(
//               controller: _pageController,
//               physics: const NeverScrollableScrollPhysics(),
//               onPageChanged: (page) => setState(() => _currentPage = page),
//               children: [
//                 BasicInfoScreen(
//                   onContinue: (data) {
//                     _nextPage({'basicInfo': data, ...data});
//                   },
//                 ),
//                 BankingInfoScreen(
//                   onContinue: (data) {
//                     _nextPage({'bankingInfo': data, ...data});
//                   },
//                 ),
//                 PropertyInfoScreen(
//                   onContinue: (data) {
//                     _nextPage({'propertyInfo': data, ...data});
//                   },
//                 ),
//                 PricingInfoScreen(
//                   propertyData: _propertyData,
//                   onContinue: (data) async {
//                     final finalData = {
//                       ..._propertyData,
//                       'hosterPhoneNumber': '+91${_propertyData['phone']}',
//                       'createdAt': DateTime.now(),
//                     };

//                     try {
//                       // Add property to database
//                       await FirebaseFirestore.instance
//                           .collection('properties')
//                           .add(finalData);

//                       if (mounted) {
//                         Navigator.popUntil(context, (route) => route.isFirst);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('Property listed successfully!'),
//                           ),
//                         );
//                       }
//                     } catch (e) {
//                       if (mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'An error occurred while listing the property: $e',
//                             ),
//                           ),
//                         );
//                       }
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 3),
//     );
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:triangle_home/screens/list_property/banking_info_screen.dart';
// import 'package:triangle_home/screens/list_property/basic_info_screen.dart';
// import 'package:triangle_home/screens/list_property/pricing_info_screen.dart';
// import 'package:triangle_home/screens/list_property/property_info_screen.dart';
// import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
// import 'package:triangle_home/widgets/list_property/progress_bar.dart';

// class ListPropertyScreen extends StatefulWidget {
//   const ListPropertyScreen({super.key});

//   @override
//   State<ListPropertyScreen> createState() => _ListPropertyScreenState();
// }

// class _ListPropertyScreenState extends State<ListPropertyScreen> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   final Map<String, dynamic> _propertyData = {};

//   void _nextPage(Map<String, dynamic> data) {
//     _propertyData.addAll(data);
//     debugPrint('Current Property Data: $_propertyData');

//     if (_currentPage < 3) {
//       setState(() {
//         _currentPage++;
//         _pageController.nextPage(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//       });
//     }
//   }

//   void _previousPage() {
//     if (_currentPage > 0) {
//       setState(() {
//         _currentPage--;
//         _pageController.previousPage(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//       });
//     } else {
//       Navigator.pop(context);
//     }
//   }

//   Future<void> _submitFinalData(Map<String, dynamic> pricingData) async {
//     final finalData = {
//       ..._propertyData,
//       'hosterPhoneNumber': '+91${_propertyData['phone']}',
//       'createdAt': DateTime.now(),
//     };

//     try {
//       await FirebaseFirestore.instance.collection('properties').add(finalData);
//       if (mounted) {
//         Navigator.popUntil(context, (route) => route.isFirst);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Property listed successfully!')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error while listing the property: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E3A8A),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: _previousPage,
//         ),
//         title: const Text(
//           'List My Property',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           ProgressBar(currentStep: _currentPage),
//           Expanded(
//             child: PageView(
//               controller: _pageController,
//               physics: const NeverScrollableScrollPhysics(),
//               onPageChanged: (page) => setState(() => _currentPage = page),
//               children: [
//                 BasicInfoScreen(
//                   onContinue: (data) => _nextPage({'basicInfo': data, ...data}),
//                 ),
//                 BankingInfoScreen(
//                   onContinue:
//                       (data) => _nextPage({'bankingInfo': data, ...data}),
//                 ),
//                 PropertyInfoScreen(
//                   onContinue:
//                       (data) => _nextPage({'propertyInfo': data, ...data}),
//                 ),
//                 // PricingInfoScreen(
//                 //   propertyData: _propertyData,
//                 //   onContinue: _submitFinalData,
//                 // ),
//               PricingInfoScreen(
//                   propertyData: _propertyData,
//                   onContinue: (data) async {
//                     final finalData = {
//                       ..._propertyData,
//                       'pricingInfo': data,
//                       ...data,

//      };
//                   },
//               )
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 3),
//     );
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:triangle_home/screens/list_property/banking_info_screen.dart';
import 'package:triangle_home/screens/list_property/basic_info_screen.dart';
import 'package:triangle_home/screens/list_property/pricing_info_screen.dart';
import 'package:triangle_home/screens/list_property/property_info_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/list_property/progress_bar.dart';

class ListPropertyScreen extends StatefulWidget {
  const ListPropertyScreen({super.key});

  @override
  State<ListPropertyScreen> createState() => _ListPropertyScreenState();
}

class _ListPropertyScreenState extends State<ListPropertyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Holds merged property data from each step
  final Map<String, dynamic> _propertyData = {};

  void _nextPage(Map<String, dynamic> newData) {
    _propertyData.addAll(newData); // Merge new data
    debugPrint('Current Property Data: $_propertyData');

    if (_currentPage < 3) {
      setState(() {
        _currentPage++;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitFinalData(Map<String, dynamic> pricingData) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final finalData = {
      ..._propertyData,
      'pricingInfo': pricingData,
      ...pricingData,
      'hosterPhoneNumber': '+91${_propertyData['basicInfo']?['phone'] ?? ''}',
      'hosterId': uid,
      'createdAt': DateTime.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('properties').add(finalData);

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Property listed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: _previousPage,
        // ),
        leading: IconButton(
          icon: SvgPicture.asset('assets/images/backicon.svg'),
          onPressed: _previousPage,
        ),
        title: const Text(
          'List My Property',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          ProgressBar(currentStep: _currentPage),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                BasicInfoScreen(
                  onContinue: (data) => _nextPage({'basicInfo': data}),
                ),
                BankingInfoScreen(
                  onContinue: (data) => _nextPage({'bankingInfo': data}),
                ),
                PropertyInfoScreen(
                  onContinue: (data) => _nextPage({'propertyInfo': data}),
                ),
                PricingInfoScreen(
                  propertyData: _propertyData,
                  pricingInfo: _propertyData['pricingInfo'] ?? {},
                  onContinue: _submitFinalData,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 3),
    );
  }
}
