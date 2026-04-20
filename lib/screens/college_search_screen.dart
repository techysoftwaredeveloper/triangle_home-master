// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:triangle_home/search_results_screen.dart';

// class CollegeSearchScreen extends StatefulWidget {
//   const CollegeSearchScreen({super.key});

//   @override
//   State<CollegeSearchScreen> createState() => _CollegeSearchScreenState();
// }

// class _CollegeSearchScreenState extends State<CollegeSearchScreen> {
//   String _selectedCollege = '';
//   String _selectedSharing = '';

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
//           'Search College Hostels For Men',
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
//           _buildCollegeSelector(),
//           const SizedBox(height: 24),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Text(
//               'Please select your room sharing type:',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildSharingOptions(),
//           const Spacer(),
//           _buildHelpCard(),
//           const SizedBox(height: 16),
//           _buildSearchButton(),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }

//   Widget _buildCollegeSelector() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E3A8A),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: _showCollegeSelection,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     _selectedCollege.isEmpty
//                         ? 'Select College/University'
//                         : _selectedCollege,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//                 const Icon(Icons.close, color: Colors.white),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ).animate().fadeIn().slideY(begin: -0.2, end: 0);
//   }

//   Widget _buildSharingOptions() {
//     final options = ['Any', 'Single', '2 Sharing', '3 Sharing', '4 Sharing'];
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Wrap(
//         spacing: 12,
//         runSpacing: 12,
//         children: options.map((option) {
//           final isSelected = _selectedSharing == option;
//           return InkWell(
//             onTap: () => setState(() => _selectedSharing = option),
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 24,
//                 vertical: 12,
//               ),
//               decoration: BoxDecoration(
//                 color: isSelected ? const Color(0xFF1E3A8A).withValues(alpha: 0.1) : Colors.white,
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(
//                   color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
//                 ),
//               ),
//               child: Text(
//                 option,
//                 style: TextStyle(
//                   color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[700],
//                   fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     ).animate().fadeIn().slideX(begin: -0.2, end: 0);
//   }

//   Widget _buildHelpCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: Border.all(color: const Color(0xFF1E3A8A)),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Need Help With Hostel Fee Payments?',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF1E3A8A),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'We\'re here for you. Tap here to know more!',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     ).animate().fadeIn().slideY(begin: 0.2, end: 0);
//   }

//   Widget _buildSearchButton() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed: _selectedCollege.isNotEmpty
//               ? () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => SearchResultsScreen(
//                         searchQuery: _selectedCollege,
//                         selectedCity: 'Mangalore',
//                         searchType: 'College',
//                         selectedLocalities: const [],
//                       ),
//                     ),
//                   );
//                 }
//               : null,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF1E3A8A),
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           child: const Text(
//             'Search',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     ).animate().fadeIn().slideY(begin: 0.2, end: 0);
//   }

//   void _showCollegeSelection() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.7,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Select College/University',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search for College Name',
//                   prefixIcon: const Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: 1,
//                 itemBuilder: (context, index) {
//                   return ListTile(
//                     title: const Text('Yenepoya University'),
//                     onTap: () {
//                       setState(() => _selectedCollege = 'Yenepoya University');
//                       Navigator.pop(context);
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:triangle_home/search_results_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class CollegeSearchScreen extends StatefulWidget {
  const CollegeSearchScreen({super.key});

  @override
  State<CollegeSearchScreen> createState() => _CollegeSearchScreenState();
}

class _CollegeSearchScreenState extends State<CollegeSearchScreen> {
  String _selectedCollege = '';
  String _selectedSharing = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => Navigator.pop(context),
        // ),
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/images/backicon.svg',
            // color: Colors.white, // optional, for tinting
            // height: 24, // adjust size if needed
            // width: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search College Hostels For Men',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCollegeSelector(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Please select your room sharing type:',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSharingOptions(),
          // const Spacer(),
          const SizedBox(height: 50),
          _buildHelpCard(),
          const SizedBox(height: 16),
          _buildSearchButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCollegeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showCollegeSelection,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCollege.isEmpty
                        ? 'Search for the name of your college/university'
                        : _selectedCollege,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.close, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildSharingOptions() {
    final options = ['Any', 'Single', '2 Sharing', '3 Sharing', '4 Sharing'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            options.map((option) {
              final isSelected = _selectedSharing == option;
              return InkWell(
                onTap: () => setState(() => _selectedSharing = option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isSelected ? AppTheme.primaryColor : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  Widget _buildHelpCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need Help With Hostel Fee Payments?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We\'re here for you. Tap here to know more!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              _selectedCollege.isNotEmpty
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SearchResultsScreen(
                              searchQuery: _selectedCollege,
                              selectedCity: 'Mangalore',
                              searchType: 'College',
                              selectedLocalities: const [],
                              selectedState:
                                  '', // TODO: Replace '' with the actual state value if available
                            ),
                      ),
                    );
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
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
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  void _showCollegeSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select College/University',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for College Name',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: const Text('Yenepoya University'),
                        onTap: () {
                          setState(
                            () => _selectedCollege = 'Yenepoya University',
                          );
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
}

