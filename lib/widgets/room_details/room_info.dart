// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class RoomInfo extends StatelessWidget {
//   const RoomInfo({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Aurora Paying Guest Accommodation',
//             style: TextStyle(
//               fontSize: 18,
//               fontFamily: 'outfit',
//               fontWeight: FontWeight.w900,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   '14/21, 17th Avenue, Deralakatte,\nMangaluru, Karnataka - 575018',
//                   style: TextStyle(
//                     color: Colors.white,
//                     height: 1.5,
//                     fontSize: 12,
//                     fontFamily: 'outfit',
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ),
//               TextButton.icon(
//                 onPressed: () {},
//                 icon: const Icon(Icons.location_on),
//                 label: const Text('View On Map'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Number of Tenants In Room:',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: List.generate(4, (index) {
//               return Padding(
//                 padding: const EdgeInsets.only(right: 8),
//                 child: ChoiceChip(
//                   label: Text('${index + 1}'),
//                   selected: index == 0,
//                   onSelected: (bool selected) {},
//                 ),
//               );
//             }),
//           ),
//         ],
//       ),
//     ).animate().fadeIn().slideY(begin: 0.2, end: 0);
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoomInfo extends StatelessWidget {
  const RoomInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E4373), // blue background
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Aurora Paying Guest Accommodation',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Address and Map Button Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address
              Expanded(
                child: Text(
                  '14/21, 17th Avenue, Deralakatte,\nMangaluru, Karnataka - 575018',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Vertical divider
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              // Button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: const [
                    Icon(Icons.location_on, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'View On Map',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}
