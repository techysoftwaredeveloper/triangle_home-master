// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class CityTags extends StatelessWidget {
//   final List<String> cities;

//   const CityTags({
//     super.key,
//     required this.cities,
//     required String selectedCity,
//     required void Function(String city) onCitySelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         children: [
//           Text(
//             'Jump To State:  ',
//             style: TextStyle(
//               color: Colors.grey[800],
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//               fontFamily: 'outfit',
//             ),
//           ),
//           ...List.generate(
//             cities.length,
//             (index) => Padding(
//               padding: const EdgeInsets.only(right: 8),
//               child: ActionChip(
//                 backgroundColor: Colors.white,
//                 side: const BorderSide(
//                   color: Color.fromARGB(255, 255, 255, 255),
//                   width: 0.9,
//                 ),
//                 labelStyle: TextStyle(
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                   fontSize: 10,
//                   fontFamily: 'outfit',
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 label: Text(cities[index]),
//                 onPressed: () {},
//               ),
//             ),
//           ),
//         ],
//       ),
//     ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0);
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class StateTags extends StatelessWidget {
//   final List<String> states;
//   final String selectedState;
//   final String currentLocation; // 👈 added separately
//   final void Function(String state) onStateSelected;

//   const StateTags({
//     super.key,
//     required this.states,
//     required this.selectedState,
//     required this.currentLocation,
//     required this.onStateSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         children: [
//           Text(
//             'Jump to State:  ',
//             style: TextStyle(
//               color: Colors.grey[800],
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//               fontFamily: 'outfit',
//             ),
//           ),

//           /// ➕ NEAR ME BUTTON
//           Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: TextButton.icon(
//               style: TextButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 0,
//                 ),
//                 backgroundColor: Colors.blue.shade50,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   side: BorderSide(color: Colors.blue.shade200),
//                 ),
//               ),
//               icon: const Icon(Icons.my_location, size: 16, color: Colors.blue),
//               label: Text(
//                 'Near Me: $currentLocation', // 👈 uses actual current location
//                 style: const TextStyle(
//                   fontSize: 10,
//                   color: Colors.blue,
//                   fontWeight: FontWeight.w500,
//                   fontFamily: 'outfit',
//                 ),
//               ),
//               onPressed: () => onStateSelected(currentLocation),
//             ),
//           ),

//           ...states.map((state) {
//             final bool isSelected = state == selectedState;
//             return Padding(
//               padding: const EdgeInsets.only(right: 8),
//               child: ActionChip(
//                 backgroundColor: isSelected ? Colors.blue[100] : Colors.white,
//                 side: BorderSide(
//                   color: isSelected ? Colors.blue : Colors.grey.shade300,
//                   width: 0.9,
//                 ),
//                 labelStyle: TextStyle(
//                   color: isSelected ? Colors.blue[800] : Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                   fontSize: 10,
//                   fontFamily: 'outfit',
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 label: Text(state),
//                 onPressed: () => onStateSelected(state),
//               ),
//             );
//           }).toList(),
//         ],
//       ),
//     ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0);
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';

class StateTags extends StatelessWidget {
  final List<String> states;
  final String selectedState;
  final String currentLocation;
  final void Function(String state) onStateSelected;

  const StateTags({
    super.key,
    required this.states,
    required this.selectedState,
    required this.currentLocation,
    required this.onStateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text('Jump to State:  ', style: _labelStyle(context)),

          /// ➕ NEAR ME BUTTON
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                backgroundColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
              ),
              icon: const Icon(Icons.my_location, size: 16, color: Colors.blue),
              label: Text(
                'Near Me: $currentLocation',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTheme.fontXS,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              onPressed: () => onStateSelected(currentLocation),
            ),
          ),

          /// ➕ STATE CHIPS
          ...states.map((state) {
            final bool isSelected = state == selectedState;
            return Padding(
              key: ValueKey(state),
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: isSelected ? Colors.blue[100] : Colors.white,
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: 0.9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                label: Text(
                  state,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected ? Colors.blue[800] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: AppTheme.fontXS,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                onPressed: () => onStateSelected(state),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0);
  }

  TextStyle _labelStyle(BuildContext context) {
    return TextStyle(
      color: Colors.grey[800],
      fontWeight: FontWeight.w600,
      fontSize: AppTheme.fontSM,
      fontFamily: AppTheme.fontFamily,
    );
  }
}
