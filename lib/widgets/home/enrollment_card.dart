// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class EnrollmentCard extends StatelessWidget {
//   const EnrollmentCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Enrolled In Yenepoya University?',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.green,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Now easily book your exclusive\nHostel Room in only 2 Simple Steps!',
//             style: TextStyle(
//               color: Colors.grey[600],
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     ).animate().fadeIn(delay: 1000.ms);
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EnrollmentCard extends StatelessWidget {
  const EnrollmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAFBF1), Color(0xFFF6FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Enrolled In ',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'outfit',
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                      ),
                      TextSpan(
                        text: 'Yenepoya University?',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'outfit',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50), // green
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Now easily book your exclusive\nHostel Room in only ',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'outfit',
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                      TextSpan(
                        text: '2 Simple Steps!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'outfit',
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 24, color: Colors.black45),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}
