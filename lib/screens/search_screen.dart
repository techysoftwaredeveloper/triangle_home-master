// // import 'package:flutter/material.dart';
// // import 'package:flutter_animate/flutter_animate.dart';

// // class SearchScreen extends StatefulWidget {
// //   const SearchScreen({super.key});

// //   @override
// //   State<SearchScreen> createState() => _SearchScreenState();
// // }

// // class _SearchScreenState extends State<SearchScreen> {
// //   final List<String> _cities = [
// //     'Chennai',
// //     'Mangalore',
// //     'Bangalore',
// //     'Kochi',
// //     'Hyderabad',
// //     'Pune',
// //   ];
// //   final Map<String, List<String>> _cityLocalities = {
// //     'Chennai': ['CIT Nagar', 'Alwarpet', 'T Nagar', 'Anna Nagar', 'Velachery'],
// //     'Mangalore': ['Deralakatte', 'City Center', 'Hampankatta', 'Bejai'],
// //     'Bangalore': ['Koramangala', 'HSR Layout', 'Indiranagar', 'Whitefield'],
// //     'Kochi': ['Kakkanad', 'Edappally', 'Fort Kochi', 'Palarivattom'],
// //   };

// //   String _selectedCity = 'Chennai';
// //   String _selectedSearchType = 'By Area';
// //   List<String> _selectedLocalities = ['CIT Nagar', 'Alwarpet'];
// //   String _selectedAccommodationType = 'Paying Guest Hostels';
// //   String _selectedTenantType = 'Anyone';
// //   String _selectedRoomType = 'Any';

// //   void _handleAddLocality() {
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.transparent,
// //       builder:
// //           (context) => Container(
// //             decoration: const BoxDecoration(
// //               color: Colors.white,
// //               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //             ),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Container(
// //                   padding: const EdgeInsets.all(16),
// //                   decoration: BoxDecoration(
// //                     border: Border(
// //                       bottom: BorderSide(color: Colors.grey.shade200),
// //                     ),
// //                   ),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       const Text(
// //                         'Select Locality',
// //                         style: TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.w600,
// //                         ),
// //                       ),
// //                       IconButton(
// //                         icon: const Icon(Icons.close),
// //                         onPressed: () => Navigator.pop(context),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: ListView.builder(
// //                     padding: const EdgeInsets.symmetric(vertical: 8),
// //                     itemCount: _cityLocalities[_selectedCity]?.length ?? 0,
// //                     itemBuilder: (context, index) {
// //                       final locality = _cityLocalities[_selectedCity]![index];
// //                       final isSelected = _selectedLocalities.contains(locality);

// //                       return ListTile(
// //                         title: Text(locality),
// //                         trailing:
// //                             isSelected
// //                                 ? const Icon(
// //                                   Icons.check_circle,
// //                                   color: Color(0xFF1E3A8A),
// //                                 )
// //                                 : null,
// //                         onTap: () {
// //                           if (!isSelected && _selectedLocalities.length < 5) {
// //                             setState(() {
// //                               _selectedLocalities.add(locality);
// //                             });
// //                             Navigator.pop(context);
// //                           } else if (isSelected) {
// //                             setState(() {
// //                               _selectedLocalities.remove(locality);
// //                             });
// //                             Navigator.pop(context);
// //                           } else {
// //                             ScaffoldMessenger.of(context).showSnackBar(
// //                               const SnackBar(
// //                                 content: Text(
// //                                   'You can select up to 5 localities',
// //                                 ),
// //                                 duration: Duration(seconds: 2),
// //                               ),
// //                             );
// //                           }
// //                         },
// //                       );
// //                     },
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.grey[50],
// //       appBar: AppBar(
// //         backgroundColor: const Color(0xFF1E3A8A),
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: Colors.white),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         title: const Text(
// //           'Search For Hostels/PGs or Apartments',
// //           style: TextStyle(color: Colors.white, fontSize: 16),
// //         ),
// //         elevation: 0,
// //       ),
// //       body: SingleChildScrollView(
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.all(5),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   const Text(
// //                     'Where are you planning to move into?',
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.w600,
// //                       color: Color(0xFF1E293B),
// //                     ),
// //                   ).animate().fadeIn().slideX(begin: -0.2, end: 0),

// //                   const SizedBox(height: 16),

// //                   const Text(
// //                     'Select City:',
// //                     style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
// //                   ),

// //                   const SizedBox(height: 8),

// //                   SingleChildScrollView(
// //                     scrollDirection: Axis.horizontal,
// //                     child: Wrap(
// //                       spacing: 8,
// //                       children:
// //                           _cities.map((city) {
// //                             final isSelected = city == _selectedCity;
// //                             return ChoiceChip(
// //                               label: Text(city),
// //                               selected: isSelected,
// //                               onSelected: (selected) {
// //                                 if (selected) {
// //                                   setState(() {
// //                                     _selectedCity = city;
// //                                     _selectedLocalities.clear();
// //                                   });
// //                                 }
// //                               },
// //                               backgroundColor: Colors.white,
// //                               selectedColor: const Color(0xFF1E3A8A),
// //                               labelStyle: TextStyle(
// //                                 color:
// //                                     isSelected ? Colors.white : Colors.black87,
// //                               ),
// //                             );
// //                           }).toList(),
// //                     ),
// //                   ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),

// //                   // Wrap(
// //                   //   spacing: 0,
// //                   //   children: _cities.map((city) {
// //                   //     final isSelected = city == _selectedCity;
// //                   //     return ChoiceChip(
// //                   //       label: Text(city),
// //                   //       selected: isSelected,
// //                   //       onSelected: (selected) {
// //                   //         if (selected) {
// //                   //           setState(() {
// //                   //             _selectedCity = city;
// //                   //             _selectedLocalities.clear();
// //                   //           });
// //                   //         }
// //                   //       },
// //                   //       backgroundColor: Colors.white,
// //                   //       selectedColor: const Color(0xFF1E3A8A),
// //                   //       labelStyle: TextStyle(
// //                   //         color: isSelected ? Colors.white : Colors.black87,
// //                   //       ),
// //                   //     );
// //                   //   }).toList(),
// //                   // ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
// //                   const SizedBox(height: 16),

// //                   Row(
// //                     children: [
// //                       Expanded(
// //                         child: _buildOptionButton(
// //                           'By Area',
// //                           _selectedSearchType == 'By Area',
// //                           () => setState(() => _selectedSearchType = 'By Area'),
// //                         ),
// //                       ),
// //                       const SizedBox(width: 16),
// //                       Expanded(
// //                         child: _buildOptionButton(
// //                           'By College',
// //                           _selectedSearchType == 'By College',
// //                           () => setState(
// //                             () => _selectedSearchType = 'By College',
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),

// //                   const SizedBox(height: 16),

// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       const Text(
// //                         'Locality Filters:',
// //                         style: TextStyle(
// //                           fontSize: 14,
// //                           color: Color(0xFF64748B),
// //                         ),
// //                       ),
// //                       TextButton(
// //                         onPressed: _handleAddLocality,
// //                         child: const Text(
// //                           'Add More',
// //                           style: TextStyle(
// //                             color: Color(0xFF1E3A8A),
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
                 
// //                   Row(
// //                     spacing: 8,
// //                     //spacing: 8,
// //                     children:
// //                         _selectedLocalities.map((locality) {
// //                           return Chip(
// //                             label: Text(locality),
// //                             deleteIcon: const Icon(Icons.close, size: 18),
// //                             onDeleted: () {
// //                               setState(() {
// //                                 _selectedLocalities.remove(locality);
// //                               });
// //                             },
// //                             backgroundColor: const Color(
// //                               0xFF1E3A8A,
// //                             ).withOpacity(0.1),
// //                             labelStyle: const TextStyle(
// //                               color: Color(0xFF1E3A8A),
// //                             ),
// //                           );
// //                         }).toList(),
// //                   ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),
// //                 ],
// //               ),
// //             ),

// //             Container(
// //               margin: const EdgeInsets.symmetric(horizontal: 16),
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(12),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.black.withOpacity(0.05),
// //                     blurRadius: 10,
// //                     offset: const Offset(0, 2),
// //                   ),
// //                 ],
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   const Text(
// //                     'Do you have any additional preferences?',
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.w600,
// //                       color: Color(0xFF1E293B),
// //                     ),
// //                   ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2, end: 0),

// //                   const SizedBox(height: 16),

// //                   const Text(
// //                     'Looking For:',
// //                     style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
// //                   ),

// //                   const SizedBox(height: 8),

// //                   Row(
// //                         children: [
// //                           Expanded(
// //                             child: _buildOptionButton(
// //                               'Paying Guest Hostels',
// //                               _selectedAccommodationType ==
// //                                   'Paying Guest Hostels',
// //                               () => setState(
// //                                 () =>
// //                                     _selectedAccommodationType =
// //                                         'Paying Guest Hostels',
// //                               ),
// //                             ),
// //                           ),
// //                           const SizedBox(width: 16),
// //                           Expanded(
// //                             child: _buildOptionButton(
// //                               'Apartments',
// //                               _selectedAccommodationType == 'Apartments',
// //                               () => setState(
// //                                 () => _selectedAccommodationType = 'Apartments',
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       )
// //                       .animate()
// //                       .fadeIn(delay: 1000.ms)
// //                       .slideX(begin: -0.2, end: 0),

// //                   const SizedBox(height: 16),

// //                   const Text(
// //                     'Tenant Type:',
// //                     style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
// //                   ),

// //                   const SizedBox(height: 8),

// //                   Column(
// //                         children: [
// //                           Row(
// //                             children: [
// //                               Expanded(
// //                                 child: _buildOptionButton(
// //                                   'Man',
// //                                   _selectedTenantType == 'Man',
// //                                   () => setState(
// //                                     () => _selectedTenantType = 'Man',
// //                                   ),
// //                                 ),
// //                               ),
// //                               const SizedBox(width: 16),
// //                               Expanded(
// //                                 child: _buildOptionButton(
// //                                   'Woman',
// //                                   _selectedTenantType == 'Woman',
// //                                   () => setState(
// //                                     () => _selectedTenantType = 'Woman',
// //                                   ),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                           const SizedBox(height: 8),
// //                           _buildOptionButton(
// //                             'Anyone',
// //                             _selectedTenantType == 'Anyone',
// //                             () =>
// //                                 setState(() => _selectedTenantType = 'Anyone'),
// //                           ),
// //                         ],
// //                       )
// //                       .animate()
// //                       .fadeIn(delay: 1200.ms)
// //                       .slideX(begin: -0.2, end: 0),

// //                   const SizedBox(height: 16),

// //                   const Text(
// //                     'Room Type:',
// //                     style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
// //                   ),

// //                   const SizedBox(height: 8),

// //                   Wrap(
// //                         spacing: 8,
// //                         runSpacing: 8,
// //                         children:
// //                             [
// //                               'Any',
// //                               'Single',
// //                               '2 Sharing',
// //                               '3 Sharing',
// //                               '4 Sharing',
// //                             ].map((type) {
// //                               return SizedBox(
// //                                 width:
// //                                     (MediaQuery.of(context).size.width - 80) /
// //                                     3,
// //                                 child: _buildOptionButton(
// //                                   type,
// //                                   _selectedRoomType == type,
// //                                   () =>
// //                                       setState(() => _selectedRoomType = type),
// //                                 ),
// //                               );
// //                             }).toList(),
// //                       )
// //                       .animate()
// //                       .fadeIn(delay: 1400.ms)
// //                       .slideX(begin: -0.2, end: 0),
// //                 ],
// //               ),
// //             ),

// //            // const SizedBox(height: 100),
           
// //           ],
// //         ),
// //       ),
// //       bottomNavigationBar: Container(
// //         height: 150,
// //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.black.withOpacity(0.1),
// //               blurRadius: 10,
// //               offset: const Offset(0, -5),
// //             ),
// //           ],
// //         ),
// //         child: ElevatedButton(
// //           onPressed: () {
// //             // Implement search functionality
// //             print('Search with:');
// //             print('City: $_selectedCity');
// //             print('Search Type: $_selectedSearchType');
// //             print('Localities: $_selectedLocalities');
// //             print('Accommodation Type: $_selectedAccommodationType');
// //             print('Tenant Type: $_selectedTenantType');
// //             print('Room Type: $_selectedRoomType');
// //           },
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: const Color(0xFF1E3A8A),
// //             foregroundColor: Colors.white,
// //             padding: const EdgeInsets.symmetric(vertical: 16),
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //           ),
// //           child: const Text(
// //             'Search',
// //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
// //           ),
// //         ),
// //       ).animate().fadeIn(delay: 1600.ms).slideY(begin: 0.2, end: 0),
// //     );
// //   }

// //   Widget _buildOptionButton(String text, bool isSelected, VoidCallback onTap) {
// //     return InkWell(
// //       onTap: onTap,
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(vertical: 12),
// //         decoration: BoxDecoration(
// //           color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
// //           borderRadius: BorderRadius.circular(8),
// //           border: Border.all(
// //             color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
// //           ),
// //         ),
// //         child: Center(
// //           child: Text(
// //             text,
// //             style: TextStyle(
// //               color: isSelected ? Colors.white : Colors.black87,
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }


// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});

//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   final List<String> _cities = [
//     'Chennai',
//     'Mangalore',
//     'Bangalore',
//     'Kochi',
//     'Hyderabad',
//     'Pune',
//   ];
//   final Map<String, List<String>> _cityLocalities = {
//     'Chennai': ['CIT Nagar', 'Alwarpet', 'T Nagar', 'Anna Nagar', 'Velachery'],
//     'Mangalore': ['Deralakatte', 'City Center', 'Hampankatta', 'Bejai'],
//     'Bangalore': ['Koramangala', 'HSR Layout', 'Indiranagar', 'Whitefield'],
//     'Kochi': ['Kakkanad', 'Edappally', 'Fort Kochi', 'Palarivattom'],
//   };

//   String _selectedCity = 'Chennai';
//   String _selectedSearchType = 'By Area';
//   final List<String> _selectedLocalities = ['CIT Nagar', 'Alwarpet'];
//   String _selectedAccommodationType = 'Paying Guest Hostels';
//   String _selectedTenantType = 'Anyone';
//   String _selectedRoomType = 'Any';


// void _handleAddLocality() {
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: Colors.transparent,
//     isScrollControlled: true,
//     builder: (context) => _selectedSearchType == 'By College'
//         ? buildCollegeBottomSheet()
//         : buildAreaBottomSheet(),
//   );
// }

// Widget buildAreaBottomSheet() {
//   return DraggableScrollableSheet(
//     expand: false,
//     builder: (_, controller) => Container(
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Select Locality',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               controller: controller,
//               itemCount: _cityLocalities[_selectedCity]?.length ?? 0,
//               itemBuilder: (context, index) {
//                 final locality = _cityLocalities[_selectedCity]![index];
//                 final isSelected = _selectedLocalities.contains(locality);

//                 return ListTile(
//                   title: Text(locality),
//                   trailing: isSelected
//                       ? const Icon(Icons.check_circle, color: Color(0xFF1E3A8A))
//                       : null,
//                   onTap: () {
//                     setState(() {
//                       if (isSelected) {
//                         _selectedLocalities.remove(locality);
//                       } else if (_selectedLocalities.length < 5) {
//                         _selectedLocalities.add(locality);
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('You can select up to 5 localities'),
//                           ),
//                         );
//                       }
//                     });
//                     Navigator.pop(context);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

//   // void _handleAddLocality() {
//   //   showModalBottomSheet(
//   //     context: context,
//   //     backgroundColor: Colors.transparent,
//   //     isScrollControlled: true,
//   //     builder: (context) => DraggableScrollableSheet(
//   //       expand: false,
//   //       builder: (_, controller) => Container(
//   //         decoration: const BoxDecoration(
//   //           color: Colors.white,
//   //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//   //         ),
//   //         child: Column(
//   //           children: [
//   //             Container(
//   //               padding: const EdgeInsets.all(16),
//   //               child: Row(
//   //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //                 children: [
//   //                   const Text(
//   //                     'Select Locality',
//   //                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//   //                   ),
//   //                   IconButton(
//   //                     icon: const Icon(Icons.close),
//   //                     onPressed: () => Navigator.pop(context),
//   //                   ),
//   //                 ],
//   //               ),
//   //             ),
//   //             Expanded(
//   //               child: ListView.builder(
//   //                 controller: controller,
//   //                 itemCount: _cityLocalities[_selectedCity]?.length ?? 0,
//   //                 itemBuilder: (context, index) {
//   //                   final locality = _cityLocalities[_selectedCity]![index];
//   //                   final isSelected = _selectedLocalities.contains(locality);

//   //                   return ListTile(
//   //                     title: Text(locality),
//   //                     trailing: isSelected
//   //                         ? const Icon(Icons.check_circle, color: Color(0xFF1E3A8A))
//   //                         : null,
//   //                     onTap: () {
//   //                       setState(() {
//   //                         if (isSelected) {
//   //                           _selectedLocalities.remove(locality);
//   //                         } else if (_selectedLocalities.length < 5) {
//   //                           _selectedLocalities.add(locality);
//   //                         } else {
//   //                           ScaffoldMessenger.of(context).showSnackBar(
//   //                             const SnackBar(
//   //                               content: Text('You can select up to 5 localities'),
//   //                             ),
//   //                           );
//   //                         }
//   //                       });
//   //                       Navigator.pop(context);
//   //                     },
//   //                   );
//   //                 },
//   //               ),
//   //             ),
//   //           ],
//   //         ),
//   //       ),
//   //     ),
//   //   );
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E3A8A),
//         title: const Text(
//           'Search For Hostels/PGs or Apartments',
//           style: TextStyle(color: Colors.white, fontSize: 16),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Where are you planning to move into?',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
//               ).animate().fadeIn().slideX(begin: -0.2, end: 0),

//               const SizedBox(height: 16),

//               const Text('Select City:', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),

//               const SizedBox(height: 8),

//               Wrap(
//                 spacing: 8,
//                 children: _cities.map((city) {
//                   final isSelected = city == _selectedCity;
//                   return ChoiceChip(
//                     label: Text(city),
//                     selected: isSelected,
//                     onSelected: (selected) {
//                       if (selected) {
//                         setState(() {
//                           _selectedCity = city;
//                           _selectedLocalities.clear();
//                         });
//                       }
//                     },
//                     backgroundColor: Colors.white,
//                     selectedColor: const Color(0xFF1E3A8A),
//                     labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
//                   );
//                 }).toList(),
//               ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),

//               const SizedBox(height: 16),

//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildOptionButton(
//                       'By Area',
//                       _selectedSearchType == 'By Area',
//                       () => setState(() => _selectedSearchType = 'By Area'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildOptionButton(
//                       'By College',
//                       _selectedSearchType == 'By College',
//                       () => setState(() => _selectedSearchType = 'By College'),
//                     ),
//                   ),
//                 ],
//               ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),

//               const SizedBox(height: 16),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Locality Filters:', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
//                   TextButton(
//                     onPressed: _handleAddLocality,
//                     child: const Text('Add More', style: TextStyle(color: Color(0xFF1E3A8A))),
//                   ),
//                 ],
//               ),

//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: _selectedLocalities.map((locality) {
//                   return Chip(
//                     label: Text(locality),
//                     deleteIcon: const Icon(Icons.close, size: 18),
//                     onDeleted: () {
//                       setState(() {
//                         _selectedLocalities.remove(locality);
//                       });
//                     },
//                     backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
//                     labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
//                   );
//                 }).toList(),
//               ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

//               const SizedBox(height: 20),

//               _buildSectionTitle('Do you have any additional preferences?'),

//               const SizedBox(height: 16),

//               _buildSubtitle('Looking For:'),

//               const SizedBox(height: 8),

//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildOptionButton(
//                       'Paying Guest Hostels',
//                       _selectedAccommodationType == 'Paying Guest Hostels',
//                       () => setState(() => _selectedAccommodationType = 'Paying Guest Hostels'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildOptionButton(
//                       'Apartments',
//                       _selectedAccommodationType == 'Apartments',
//                       () => setState(() => _selectedAccommodationType = 'Apartments'),
//                     ),
//                   ),
//                 ],
//               ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2, end: 0),

//               const SizedBox(height: 16),

//               _buildSubtitle('Tenant Type:'),

//               const SizedBox(height: 8),

//               Column(
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildOptionButton(
//                           'Man',
//                           _selectedTenantType == 'Man',
//                           () => setState(() => _selectedTenantType = 'Man'),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _buildOptionButton(
//                           'Woman',
//                           _selectedTenantType == 'Woman',
//                           () => setState(() => _selectedTenantType = 'Woman'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   _buildOptionButton(
//                     'Anyone',
//                     _selectedTenantType == 'Anyone',
//                     () => setState(() => _selectedTenantType = 'Anyone'),
//                   ),
//                 ],
//               ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.2, end: 0),

//               const SizedBox(height: 16),

//               _buildSubtitle('Room Type:'),

//               const SizedBox(height: 8),

//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: ['Any', 'Single', '2 Sharing', '3 Sharing', '4 Sharing'].map((type) {
//                   return SizedBox(
//                     width: (width - 64) / 3,
//                     child: _buildOptionButton(
//                       type,
//                       _selectedRoomType == type,
//                       () => setState(() => _selectedRoomType = type),
//                     ),
//                   );
//                 }).toList(),
//               ).animate().fadeIn(delay: 1200.ms).slideX(begin: -0.2, end: 0),

//               const SizedBox(height: 24),

//               ElevatedButton(
//                 onPressed: () {
//                   print('Search with:');
//                   print('City: $_selectedCity');
//                   print('Search Type: $_selectedSearchType');
//                   print('Localities: $_selectedLocalities');
//                   print('Accommodation Type: $_selectedAccommodationType');
//                   print('Tenant Type: $_selectedTenantType');
//                   print('Room Type: $_selectedRoomType');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1E3A8A),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Center(
//                   child: Text(
//                     'Search',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.2, end: 0),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildOptionButton(String text, bool isSelected, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
//           ),
//         ),
//         child: Center(
//           child: Text(
//             text,
//             style: TextStyle(
//               color: isSelected ? Colors.white : Colors.black87,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
//     );
//   }

//   Widget _buildSubtitle(String subtitle) {
//     return Text(
//       subtitle,
//       style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
//     );
//   }
// }

// Widget buildCollegeBottomSheet() {
//   final List<Map<String, String>> popularInstitutions = [
//     {
//       'name': 'Yenepoya University',
//       'location': 'Mangaluru, Karnataka',
//       'logo': 'assets/yenepoya.png', // Add your asset path here
//     },
//     {
//       'name': 'Madras Christian College',
//       'location': 'Chennai, Tamil Nadu',
//       'logo': 'assets/mcc.png', // Add your asset path here
//     },
//   ];

//   BuildContext context;
//   return DraggableScrollableSheet(
//     expand: false,
//     builder: (_, controller) => Container(
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header with title and close button
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Search for Your College/Institution',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               // IconButton(
//               //   icon: const Icon(Icons.close),
//               //   onPressed: () => Navigator.pop(context), // Use context here instead if you pass it in
//               // ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           // Search field
//           TextField(
//             decoration: InputDecoration(
//               hintText: 'Search for College Name',
//               prefixIcon: const Icon(Icons.search),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//             ),
//           ),

//           const SizedBox(height: 20),

//           const Text(
//             'Our Popular Institutions',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),

//           const SizedBox(height: 12),

//           // Horizontal list of popular colleges
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: popularInstitutions.map((college) {
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 16),
//                   child: Column(
//                     children: [
//                       CircleAvatar(
//                         radius: 24,
//                         backgroundImage: AssetImage(college['logo']!),
//                         backgroundColor: Colors.grey[200],
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         college['name']!,
//                         style: const TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                       Text(
//                         college['location']!,
//                         style: const TextStyle(fontSize: 12, color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // Widget buildCollegeBottomSheet() {
 
// //   return DraggableScrollableSheet(
// //     expand: false,
// //     builder: (_, controller) => Container(
// //       decoration: const BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       child: Column(
// //         children: [
// //           Container(
// //             padding: const EdgeInsets.all(16),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 const Text(
// //                   'Select College',
// //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
// //                 ),
// //                 // IconButton(
// //                 //   icon: const Icon(Icons.close),
// //                 //   onPressed: () => Navigator.pop(context),
// //                 // ),
// //               ],
// //             ),
// //           ),
// //           Expanded(
// //             child: ListView(
// //               controller: controller,
// //               children: const [
// //                 ListTile(title: Text('Anna University')),
// //                 ListTile(title: Text('IIT Madras')),
// //                 ListTile(title: Text('Loyola College')),
// //                 ListTile(title: Text('SRM University')),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     ),
// //   );
// // }



// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/widgets/search/city_selector.dart';
import 'package:triangle_home/widgets/search/college_search_sheet.dart';
import 'package:triangle_home/widgets/search/locality_filters.dart';
import 'package:triangle_home/widgets/search/search_type_selector.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<String> _cities = ['Chennai', 'Mangalore', 'Bangalore', 'Kochi'];
  String _selectedCity = 'Chennai';
  String _selectedSearchType = 'By Area';
  final List<String> _selectedLocalities = ['CIT Nagar', 'Alwarpet'];
  final String _selectedAccommodationType = 'Paying Guest Hostels';
  final String _selectedTenantType = 'Anyone';
  final String _selectedRoomType = 'Any';

  void _handleSearchTypeChange(String type) {
    setState(() {
      _selectedSearchType = type;
      if (type == 'By College') {
        _showCollegeSearch();
      }
    });
  }

  void _showCollegeSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CollegeSearchSheet(),
    );
  }

  void _handleAddLocality() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Locality',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: 5,
                itemBuilder: (context, index) {
                  final locality = 'Locality ${index + 1}';
                  final isSelected = _selectedLocalities.contains(locality);
                  
                  return ListTile(
                    title: Text(locality),
                    trailing: isSelected 
                      ? const Icon(Icons.check_circle, color: Color(0xFF1E3A8A))
                      : null,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedLocalities.remove(locality);
                        } else {
                          _selectedLocalities.add(locality);
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Search For Hostels/PGs or Apartments',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where are you planning to move into?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),

            const SizedBox(height: 16),

            CitySelector(
              cities: _cities,
              selectedCity: _selectedCity,
              onCitySelected: (city) => setState(() => _selectedCity = city),
            ),

            const SizedBox(height: 16),

            SearchTypeSelector(
              selectedType: _selectedSearchType,
              onTypeSelected: _handleSearchTypeChange,
            ),

            if (_selectedSearchType == 'By Area') ...[
              const SizedBox(height: 16),
              LocalityFilters(
                selectedLocalities: _selectedLocalities,
                onLocalityRemoved: (locality) {
                  setState(() => _selectedLocalities.remove(locality));
                },
                onAddMore: _handleAddLocality,
              ),
            ],

            // Additional preferences section
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Do you have any additional preferences?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  // Add your additional preferences UI here
                ],
              ),
            ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
