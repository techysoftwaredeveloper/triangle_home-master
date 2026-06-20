import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PropertyOverviewCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final Map<String, dynamic> stats;
  final double? calculatedDeposit;

  const PropertyOverviewCard({
    super.key, 
    required this.property, 
    required this.stats,
    this.calculatedDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final depositValue = _getValue(property, ['deposit', 'securityDeposit', 'security_deposit', 'baseDeposit', 'initialDeposit', 'depositAmount', 'deposit_amount', 'basicInfo.deposit', 'basicInfo.securityDeposit', 'propertyDetails.deposit', 'basicInfo.security_deposit']);
    final displayDeposit = depositValue != 'N/A' ? '₹$depositValue' : (calculatedDeposit != null && calculatedDeposit! > 0 ? '₹${calculatedDeposit!.toStringAsFixed(0)}' : '₹N/A');

    final double rating = stats['rating']?.toDouble() ?? (property['rating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount = stats['reviewCount']?.toInt() ?? (property['reviewCount'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  property['title'] ?? 'Property Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              if (property['verified'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.successColor, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (reviewCount > 0) ...[
                Icon(Icons.star, color: Colors.amber[700], size: 18),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '($reviewCount Reviews)',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                const Text(
                  'New Listing',
                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 4),
                const Text(
                  '• Be first to review',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getGeneralizedLocation(property['location'] ?? 'Location'),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(Icons.bed_outlined, stats['availableBeds']?.toString() ?? '0', 'Beds Left'),
                  _buildStatItem(Icons.door_front_door_outlined, stats['availableRooms']?.toString() ?? '0', 'Rooms'),
                  _buildStatItem(
                    Icons.account_balance_wallet_outlined,
                    displayDeposit,
                    'Deposit',
                  ),
                  _buildStatItem(
                    _getGenderIcon(
                      _getValue(property, ['gender', 'basicInfo.gender', 'propertyDetails.gender', 'basicInfo.tenantType']),
                      property['title'] ?? property['name'] ?? '',
                    ),
                    _getGenderLabel(
                      _getValue(property, ['gender', 'basicInfo.gender', 'propertyDetails.gender', 'basicInfo.tenantType']),
                      property['title'] ?? property['name'] ?? '',
                    ),
                    'Gender',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getValue(Map<String, dynamic> map, List<String> keys) {
    for (var key in keys) {
      if (key.contains('.')) {
        final parts = key.split('.');
        dynamic current = map;
        for (var part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            current = null;
            break;
          }
        }
        if (current != null && current.toString().isNotEmpty) return current.toString();
      } else {
        if (map.containsKey(key) && map[key] != null && map[key].toString().isNotEmpty) {
          return map[key].toString();
        }
      }
    }
    return 'N/A';
  }

  IconData _getGenderIcon(String gender, String title) {
    final g = gender.toLowerCase();
    final t = title.toLowerCase();
    
    // Check title first as it's often more descriptive in "MIX PG" cases
    if (t.contains('mix') || t.contains('unisex') || t.contains('co-ed')) return Icons.group_outlined;
    
    if (g.contains('girl') || g.contains('female') || g.contains('women')) return Icons.female;
    if (g.contains('boy') || g.contains('male') || g.contains('men')) return Icons.male;
    return Icons.group_outlined;
  }

  String _getGenderLabel(String gender, String title) {
    final g = gender.toLowerCase();
    final t = title.toLowerCase();

    if (t.contains('mix') || t.contains('unisex') || t.contains('co-ed')) return 'Unisex';

    if (g == 'n/a') return 'Anyone';
    if (g.contains('girl') || g.contains('female') || g.contains('women')) return 'Girls Only';
    if (g.contains('boy') || g.contains('male') || g.contains('men')) return 'Boys Only';
    if (g.contains('unisex') || g.contains('anyone') || g.contains('both') || g.contains('mix')) return 'Unisex';
    return gender;
  }

  String _getGeneralizedLocation(String fullLocation) {
    if (fullLocation.isEmpty) return 'Location';
    // Logic to generalize: e.g., "Near Chingavanam Junction, Kottayam"
    // For now, let's assume if it contains a comma, we take the last two parts
    final parts = fullLocation.split(',').map((e) => e.trim()).toList();
    if (parts.length > 1) {
      return 'Near ${parts[parts.length - 2]}, ${parts[parts.length - 1]}';
    }
    return fullLocation;
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor.withValues(alpha: 0.7), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
