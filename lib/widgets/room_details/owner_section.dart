// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:url_launcher/url_launcher.dart';

// class OwnerSection extends StatelessWidget {
//   final String owner;
//   final String phone;
//   const OwnerSection({super.key, required this.owner, required  this.phone,});

//   void _launchDialer(String phoneNumber) async {
//     print('Phone Number: $phoneNumber');
//     final Uri url = Uri(scheme: 'tel', path: phoneNumber);
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url);
//     } else {
//       throw 'Could not launch $url';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 "Owner’s Profile",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Outfit',
//                   color: Colors.white,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {},
//                 style: TextButton.styleFrom(
//                   padding: EdgeInsets.zero,
//                   minimumSize: const Size(0, 0),
//                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 ),
//                 child: const Text(
//                   "View All Listings",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     fontFamily: 'Outfit',
//                     color: Color(0xFF007BFF),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           // Owner Card
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.05),
//                   blurRadius: 8,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Top section: Avatar and owner info
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const CircleAvatar(
//                       radius: 30,
//                       backgroundImage: NetworkImage(
//                         'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                             Text(
//                           //   'Aravind Pradeep Kumar',
//                           owner,
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               fontFamily: 'Outfit',
//                               color: Color(0xFF2D2D2D),
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF1ABC5C),
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: const Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   Icons.verified,
//                                   color: Colors.white,
//                                   size: 14,
//                                 ),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'Property owner since September 2007',
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Colors.white,
//                                     fontFamily: 'Outfit',
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
//                 const SizedBox(height: 12),
//                 // Buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton.icon(
//                        // onPressed: () {},
//                        onPressed: () => _launchDialer(phone),
//                         icon: const Icon(Icons.call,
//                             color: Color(0xFF001F5B), size: 20),
//                         label: const Text(
//                           'Enquire Over Call',
//                           style: TextStyle(
//                             color: Color(0xFF001F5B),
//                             fontSize: 12,
//                             fontFamily: 'Outfit',
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         style: TextButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: TextButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.share,
//                             color: Color(0xFF001F5B), size: 20),
//                         label: const Text(
//                           'Share This Listing',
//                           style: TextStyle(
//                             color: Color(0xFF001F5B),
//                             fontSize: 12,
//                             fontFamily: 'Outfit',
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         style: TextButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class OwnerSection extends StatelessWidget {
  final String owner;
  final String phone;

  const OwnerSection({super.key, required this.owner, required this.phone});

  void _launchDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('⚠️ Cannot launch dialer for: $phoneNumber');
      }
    } catch (e) {
      debugPrint('❌ Error launching dialer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Owner’s Profile",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                  color: AppTheme.textLightColor,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "View All Listings",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Outfit',
                    color: Color(0xFF007BFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Owner card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar and info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            owner,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Outfit',
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1ABC5C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Property owner since September 2007',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE0E0E0),
                ),
                const SizedBox(height: 12),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _launchDialer(phone),
                        icon: const Icon(
                          Icons.call,
                          color: Color(0xFF001F5B),
                          size: 20,
                        ),
                        label: const Text(
                          'Enquire Over Call',
                          style: TextStyle(
                            color: Color(0xFF001F5B),
                            fontSize: 12,
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.share,
                          color: Color(0xFF001F5B),
                          size: 20,
                        ),
                        label: const Text(
                          'Share This Listing',
                          style: TextStyle(
                            color: Color(0xFF001F5B),
                            fontSize: 12,
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
