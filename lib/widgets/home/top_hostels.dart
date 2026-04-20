import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/screens/room_details_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class TopHostels extends StatelessWidget {
  final List<Map<String, dynamic>> hostels;

  const TopHostels({super.key, required this.hostels});

  @override
  Widget build(BuildContext context) {
    if (hostels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Highest Rated Properties',
            style: TextStyle(
              fontSize: AppTheme.fontBase,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hostels.length,
            itemBuilder: (context, index) {
              final hostel = hostels[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomDetailsScreen(accommodation: hostel),
                    ),
                  );
                },
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: hostel['image'] ?? '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.home, size: 20),
                            ),
                      ),
                    ),
                    title: Text(
                      hostel['name'] ?? 'Property',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSM,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hostel['location'] ?? '',
                          style: const TextStyle(
                            fontSize: AppTheme.fontXS - 2,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hostel['rating'] != null)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 10,
                                color: AppTheme.warningColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${hostel['rating']?.toStringAsFixed(1) ?? '4.0'}',
                                style: const TextStyle(
                                  fontSize: AppTheme.fontXS - 2,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ).animate().fadeIn(delay: (600 + (index * 200)).ms);
            },
          ),
        ),
      ],
    );
  }
}
