import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HostProfileSection extends StatelessWidget {
  final Map<String, dynamic>? host;

  const HostProfileSection({super.key, required this.host});

  @override
  Widget build(BuildContext context) {
    if (host == null || host!.isEmpty) return const SizedBox.shrink();

    final info = host!['info'] as Map? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Host Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text('View Profile', style: TextStyle(color: AppTheme.successColor))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: info['profileImage'] != null 
                  ? CachedNetworkImageProvider(info['profileImage']) 
                  : null,
                child: info['profileImage'] == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          info['name'] ?? 'Host Name',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (host!['status'] == 'approved')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified, color: AppTheme.successColor, size: 10),
                                SizedBox(width: 4),
                                Text('Verified Host', style: TextStyle(color: AppTheme.successColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.home_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${host!['totalProperties'] ?? 0} Properties', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text('Responds in 15 mins', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildActionButton(Icons.call, Colors.green, () {}),
                  const SizedBox(width: 8),
                  _buildActionButton(Icons.chat_bubble_outline, AppTheme.successColor, () {}),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
