import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/screens/property_detail_screen_v2.dart';
import 'package:triangle_home/models/property_stats_model.dart';
import 'package:triangle_home/theme/app_theme.dart';

class PremiumPropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final double width;

  const PremiumPropertyCard({
    super.key,
    required this.property,
    this.width = 320,
  });

  @override
  Widget build(BuildContext context) {
    final propertyId = property['id']?.toString() ?? '';
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('propertyStats').doc(propertyId).snapshots(),
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.hasData && statsSnapshot.data!.exists
            ? PropertyStatsModel.fromFirestore(statsSnapshot.data!)
            : null;

        final imageUrl = _getImageUrl();
        final bool hasValidImage = imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreenV2(property: property),
              ),
            );
          },
          child: Container(
            width: width,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image Section
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: !hasValidImage
                          ? Container(
                              height: 220,
                              color: Colors.grey[300],
                              width: double.infinity,
                              child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                            )
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 220,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 220,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                              ),
                            ),
                    ),

                    // Wishlist Button (Real-time)
                    if (user != null)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _WishlistButton(propertyId: propertyId, propertyData: property),
                      ),

                    // Verification Badge
                    if (property['verification']?['isVerified'] == true || property['status'] == 'approved')
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Property Type Badge
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (property['propertyType'] ?? property['type'] ?? 'PG').toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _AvailabilityBadge(stats: stats),
                        ],
                      ),
                    ),
                  ],
                ),

                // 2. Content Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (property['name'] ?? property['title'] ?? 'Unnamed Property').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.fontFamily,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ),
                          _RatingDisplay(property: property),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textLightColor),
                          const SizedBox(width: 4),
                          Text(
                            _formatLocation(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textLightColor,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Pricing
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${property['monthlyRent'] ?? property['price'] ?? '0'}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const Text(
                            '/month',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textLightColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if ((property['availableBeds'] as num? ?? 0) > 0)
                        const Text(
                          'Starting From',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor, fontWeight: FontWeight.w500),
                        ),

                      const SizedBox(height: 16),

                      // Occupancy Stats
                      _OccupancyStats(stats: stats, propertyData: property),

                      const SizedBox(height: 16),

                      // Amenities
                      _AmenitiesRow(amenities: property['amenities'] as List?),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Verified Property',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getImageUrl() {
    String url = '';
    if (property['image'] != null && property['image'].toString().isNotEmpty) {
      url = property['image'].toString();
    } else {
      final images = property['images'] as List?;
      if (images != null && images.isNotEmpty) {
        url = images[0].toString();
      } else {
        final imageUrls = property['image_urls'] as List?;
        if (imageUrls != null && imageUrls.isNotEmpty) {
          url = imageUrls[0].toString();
        }
      }
    }

    // Clean URL (remove whitespace, etc.)
    url = url.trim();

    // Basic validation
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return '';
    }

    return url;
  }

  String _formatLocation() {
    final locality = (property['locality'] ?? '').toString();
    final city = (property['city'] ?? '').toString();
    if (locality.isNotEmpty && city.isNotEmpty) {
      return '$locality, $city';
    }
    return city.isNotEmpty ? city : (locality.isNotEmpty ? locality : 'Location N/A');
  }
}

class _WishlistButton extends StatelessWidget {
  final String propertyId;
  final Map<String, dynamic> propertyData;

  const _WishlistButton({required this.propertyId, required this.propertyData});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(propertyId)
          .snapshots(),
      builder: (context, snapshot) {
        final bool isFavorite = snapshot.hasData && snapshot.data!.exists;

        return GestureDetector(
          onTap: () async {
            final docRef = FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('wishlist')
                .doc(propertyId);

            if (isFavorite) {
              await docRef.delete();
            } else {
              await docRef.set({
                'propertyId': propertyId,
                'addedAt': FieldValue.serverTimestamp(),
                'propertyData': propertyData,
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : AppTheme.textLightColor,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final PropertyStatsModel? stats;

  const _AvailabilityBadge({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    final int total = stats!.totalBeds;
    final int occupied = stats!.occupiedBeds;
    final int available = total - occupied;

    String label = 'Available Now';
    Color color = AppTheme.successColor;

    if (available == 0) {
      label = 'Currently Full';
      color = AppTheme.errorColor;
    } else if (available <= 3) {
      label = 'Limited Availability';
      color = AppTheme.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  final Map<String, dynamic> property;

  const _RatingDisplay({required this.property});

  @override
  Widget build(BuildContext context) {
    final double rating = (property['rating'] as num? ?? 0).toDouble();
    final int count = (property['reviewCount'] as num? ?? 0).toInt();

    if (count == 0) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          ' ($count)',
          style: const TextStyle(color: AppTheme.textMutedColor, fontSize: 12),
        ),
      ],
    );
  }
}

class _OccupancyStats extends StatelessWidget {
  final PropertyStatsModel? stats;
  final Map<String, dynamic> propertyData;

  const _OccupancyStats({required this.stats, required this.propertyData});

  @override
  Widget build(BuildContext context) {
    final int total = stats?.totalBeds ?? (propertyData['totalBeds'] as num? ?? propertyData['beds'] ?? 0).toInt();
    final int occupied = stats?.occupiedBeds ?? (propertyData['currentOccupancy'] as num? ?? 0).toInt();
    final int available = stats?.availableBeds ?? (total - occupied);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(Icons.bed_outlined, total.toString(), 'Total Beds'),
          _buildStat(Icons.people_outline, occupied.toString(), 'Occupied'),
          _buildStat(Icons.circle, available.toString(), 'Available', iconColor: AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, {Color? iconColor}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor ?? AppTheme.textLightColor),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMutedColor)),
      ],
    );
  }
}

class _AmenitiesRow extends StatelessWidget {
  final List? amenities;

  const _AmenitiesRow({this.amenities});

  @override
  Widget build(BuildContext context) {
    if (amenities == null || amenities!.isEmpty) return const SizedBox.shrink();

    final List<String> primary = ['WiFi', 'AC', 'Food', 'Laundry'];
    final List<String> displayed = [];
    int extra = 0;

    for (var a in amenities!) {
      if (primary.contains(a.toString()) && displayed.length < 4) {
        displayed.add(a.toString());
      }
    }
    
    // Add others if we have space
    if (displayed.length < 4) {
      for (var a in amenities!) {
        if (!primary.contains(a.toString()) && displayed.length < 4) {
          displayed.add(a.toString());
        }
      }
    }
    
    extra = amenities!.length - displayed.length;

    return Row(
      children: [
        ...displayed.map((a) => _AmenityChip(label: a)),
        if (extra > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$extra',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textLightColor),
            ),
          ),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;

  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.check;
    if (label == 'WiFi') icon = Icons.wifi;
    if (label == 'AC') icon = Icons.ac_unit;
    if (label == 'Food') icon = Icons.restaurant;
    if (label == 'Laundry') icon = Icons.local_laundry_service;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppTheme.textLightColor),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textLightColor)),
        ],
      ),
    );
  }
}
