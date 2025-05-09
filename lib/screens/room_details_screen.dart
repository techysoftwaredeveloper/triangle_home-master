import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/widgets/room_details/amenities_section.dart';
import 'package:triangle_home/widgets/room_details/bottom_bar.dart';
import 'package:triangle_home/widgets/room_details/image_carousel.dart';
import 'package:triangle_home/widgets/room_details/owner_section.dart';
import 'package:triangle_home/widgets/room_details/room_info.dart';
import 'package:triangle_home/widgets/room_details/tenant_selector.dart';

class RoomDetailsScreen extends StatelessWidget {
  const RoomDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> images = [
      'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
      'https://images.pexels.com/photos/271618/pexels-photo-271618.jpeg',
      'https://images.pexels.com/photos/1457842/pexels-photo-1457842.jpeg',
    ];

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ImageCarousel(),
                const RoomInfo(),
                const TenantSelector(),
                const AmenitiesSection(),
                const OwnerSection(),
                // Extra space for bottom bar
                const SizedBox(height: 130),
              ].animate(interval: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomBar(),
          ),
        ],
      ),
    );
  }
}