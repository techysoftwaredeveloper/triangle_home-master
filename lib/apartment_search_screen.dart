// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:triangle_home/search_results_screen.dart';

// class ApartmentSearchScreen extends StatefulWidget {
//   const ApartmentSearchScreen({super.key});

//   @override
//   State<ApartmentSearchScreen> createState() => _ApartmentSearchScreenState();
// }

// class _ApartmentSearchScreenState extends State<ApartmentSearchScreen> {
//   String _selectedCity = 'Chennai';
//   String _selectedRoomType = '';
//   final TextEditingController _collegeSearchController = TextEditingController();

//   final List<String> _cities = ['Chennai', 'Mangalore', 'Bangalore', 'Kochi'];
//   final List<String> _roomTypes = [
//     'Any',
//     '1 RK',
//     '1 BHK',
//     '2 BHK',
//     '3 BHK',
//     '4 BHK',
//     '4+ BHK'
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E3A8A),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Search Apartments Near College/University',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Where are you planning to move into?',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[800],
//                     ),
//                   ).animate().fadeIn().slideY(begin: -0.2, end: 0),
//                   const SizedBox(height: 24),
//                   Text(
//                     'Select City:',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildCitySelector(),
//                   const SizedBox(height: 24),
//                   _buildCollegeSearch(),
//                   const SizedBox(height: 32),
//                   Text(
//                     'Please select your room type:',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey[800],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildRoomTypeSelector(),
//                 ],
//               ),
//             ),
//           ),
//           _buildSearchButton(),
//         ],
//       ),
//     );
//   }

//   Widget _buildCitySelector() {
//     return Wrap(
//       spacing: 12,
//       runSpacing: 12,
//       children: _cities.map((city) {
//         final isSelected = city == _selectedCity;
//         return InkWell(
//           onTap: () => setState(() => _selectedCity = city),
//           child: Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 24,
//               vertical: 12,
//             ),
//             decoration: BoxDecoration(
//               color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(
//                 color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
//               ),
//             ),
//             child: Text(
//               city,
//               style: TextStyle(
//                 color: isSelected ? Colors.white : Colors.grey[700],
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     ).animate().fadeIn().slideX(begin: -0.2, end: 0);
//   }

//   Widget _buildCollegeSearch() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TextField(
//         controller: _collegeSearchController,
//         decoration: InputDecoration(
//           hintText: 'Search for the name of your College',
//           hintStyle: TextStyle(color: Colors.grey[600]),
//           border: InputBorder.none,
//           prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 12,
//           ),
//         ),
//       ),
//     ).animate().fadeIn().slideX(begin: -0.2, end: 0);
//   }

//   Widget _buildRoomTypeSelector() {
//     return Wrap(
//       spacing: 12,
//       runSpacing: 12,
//       children: _roomTypes.map((type) {
//         final isSelected = type == _selectedRoomType;
//         return InkWell(
//           onTap: () => setState(() => _selectedRoomType = type),
//           child: Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 24,
//               vertical: 12,
//             ),
//             decoration: BoxDecoration(
//               color: isSelected ? const Color(0xFF1E3A8A).withValues(alpha: 0.1) : Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(
//                 color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
//               ),
//             ),
//             child: Text(
//               type,
//               style: TextStyle(
//                 color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[700],
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     ).animate().fadeIn().slideX(begin: -0.2, end: 0);
//   }

//   Widget _buildSearchButton() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => SearchResultsScreen(
//                 searchQuery: _collegeSearchController.text.isNotEmpty
//                     ? _collegeSearchController.text
//                     : 'Apartments in $_selectedCity',
//                 selectedCity: _selectedCity,
//                 searchType: 'Apartment',
//                 selectedLocalities: const [],
//               ),
//             ),
//           );
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF1E3A8A),
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: const Text(
//           'Search',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     ).animate().fadeIn().slideY(begin: 0.2, end: 0);
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/search_results_screen.dart';

class ApartmentSearchScreen extends StatefulWidget {
  const ApartmentSearchScreen({super.key});

  @override
  State<ApartmentSearchScreen> createState() => _ApartmentSearchScreenState();
}

class _ApartmentSearchScreenState extends State<ApartmentSearchScreen> {
  String _selectedCity = 'Chennai';
  String _selectedRoomType = '';
  final TextEditingController _collegeSearchController =
      TextEditingController();

  final List<String> _cities = ['Chennai', 'Mangalore', 'Bangalore', 'Kochi'];
  final List<String> _roomTypes = [
    'Any',
    '1 RK',
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4 BHK',
    '4+ BHK',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search Apartments Near College/University',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where are you planning to move into?',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 24),
                  Text(
                    'Select City:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCitySelector(),
                  const SizedBox(height: 24),
                  _buildCollegeSearch(),
                  const SizedBox(height: 32),
                  Text(
                    'Please select your room type:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRoomTypeSelector(),
                ],
              ),
            ),
          ),
          _buildSearchButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          _cities.map((city) {
            final isSelected = city == _selectedCity;
            return InkWell(
              onTap: () => setState(() => _selectedCity = city),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  city,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  Widget _buildCollegeSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _collegeSearchController,
        decoration: InputDecoration(
          hintText: 'Search for the name of your College',
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  Widget _buildRoomTypeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          _roomTypes.map((type) {
            final isSelected = type == _selectedRoomType;
            return InkWell(
              onTap: () => setState(() => _selectedRoomType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isSelected ? const Color(0xFF1E3A8A) : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  Widget _buildSearchButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => SearchResultsScreen(
                    searchQuery:
                        _collegeSearchController.text.isNotEmpty
                            ? _collegeSearchController.text
                            : 'Apartments in $_selectedCity',
                    selectedCity: _selectedCity,
                    selectedState:
                        '', // TODO: Replace '' with the actual selected state value if available
                    searchType: 'Apartment',
                    selectedLocalities: const [],
                  ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Search',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

