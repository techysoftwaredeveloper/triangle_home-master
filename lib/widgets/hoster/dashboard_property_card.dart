import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/core/extensions/string_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class DashboardPropertyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onViewDetails;
  final VoidCallback? onManageProperty;
  final VoidCallback? onMoreOptions;

  const DashboardPropertyCard({
    super.key,
    required this.data,
    this.onViewDetails,
    this.onManageProperty,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    final basic = data['basicInfo'] as Map? ?? {};
    final images = data['images'] as List? ?? [];
    
    final name = basic['collegeName']?.toString().isNotEmpty == true
        ? basic['collegeName'].toString()
        : (data['name'] ?? data['title'] ?? 'Property').toString();
    
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    
    final int activeResidents = _parseNum(data['activeResidents']).toInt();
    final int totalBeds = _parseNum(data['capacity']).toInt();
    final int vacantBeds = totalBeds - activeResidents;
    final int occupancyPercent = totalBeds > 0 ? (activeResidents / totalBeds * 100).round() : 0;
    
    final double revenue = _parseNum(data['monthlyRevenue']).toDouble();
    final int inquiries = _parseNum(data['inquiries']).toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 360;
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Hero Image
                  _buildHeroImage(images, status, occupancyPercent, isSmall),
                  
                  Padding(
                    padding: EdgeInsets.all(isSmall ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 2: Property Identity
                        _buildIdentity(name, basic, data, isSmall),
                        SizedBox(height: isSmall ? 12 : 20),
                        
                        // Section 3: Quick Metrics Grid
                        _buildQuickMetrics(totalBeds, activeResidents, vacantBeds, isSmall),
                        SizedBox(height: isSmall ? 12 : 16),
                        const Divider(color: Color(0xFFE2E8F0), height: 1),
                        SizedBox(height: isSmall ? 12 : 16),
                        
                        // Section 4: Performance Metrics
                        _buildPerformanceMetrics(revenue, inquiries, status, isSmall),
                        SizedBox(height: isSmall ? 16 : 24),
                        
                        // Section 5: Action Buttons
                        _buildActionButtons(isSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroImage(List images, String status, int occupancy, bool isSmall) {
    final double height = isSmall ? 140 : 170;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: images.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: images.first,
                  height: height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: height,
                    color: const Color(0xFFF1F5F9),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: height,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8), size: 40),
                  ),
                )
              : Container(
                  height: height,
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.home_work_outlined, color: Color(0xFF94A3B8), size: 40),
                ),
        ),
        // Top Left Badge
        Positioned(
          top: 16,
          left: 16,
          child: _buildStatusBadge(status),
        ),
        // Top Right Overflow
        Positioned(
          top: 12,
          right: 12,
          child: _buildFrostedButton(Icons.more_vert_rounded, onMoreOptions),
        ),
        // Bottom Right Occupancy
        Positioned(
          bottom: 12,
          right: 12,
          child: _buildOccupancyPill(occupancy),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
      case 'approved':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        label = 'LIVE';
        break;
      case 'pending':
      case 'under review':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        label = 'PENDING';
        break;
      case 'suspended':
      case 'rejected':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
        label = status.toUpperCase();
        break;
      case 'draft':
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        label = 'DRAFT';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFrostedButton(IconData icon, VoidCallback? onTap) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withValues(alpha: 0.2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOccupancyPill(int occupancy) {
    Color color;
    if (occupancy > 70) {
      color = const Color(0xFF16A34A);
    } else if (occupancy >= 40) {
      color = const Color(0xFFF97316);
    } else {
      color = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$occupancy% Occupied',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(String name, Map basic, Map data, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: isSmall ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            fontFamily: 'Outfit',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${data['locality'] ?? data['city'] ?? 'Location'}, Kerala',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (basic['type'] ?? 'PG ACCOMMODATION').toString().toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (data['createdAt'] != null) ...[
              const SizedBox(width: 12),
              Text(
                'Joined ${_joinedDate(data['createdAt'])}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _joinedDate(dynamic ts) {
    try {
      final date = (ts is Timestamp) ? ts.toDate() : (ts is DateTime ? ts : DateTime.now());
      return DateFormat('MMM yyyy').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildQuickMetrics(int total, int residents, int vacant, bool isSmall) {
    return Row(
      children: [
        _quickMetricItem(Icons.bed_rounded, total.toString(), 'Total Beds', isSmall),
        _verticalDivider(),
        _quickMetricItem(Icons.people_alt_rounded, residents.toString(), 'Residents', isSmall),
        _verticalDivider(),
        _quickMetricItem(Icons.bed_outlined, vacant.toString(), 'Vacant Beds', isSmall),
      ],
    );
  }

  Widget _quickMetricItem(IconData icon, String value, String label, bool isSmall) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: isSmall ? 16 : 18, color: const Color(0xFF64748B)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(height: 40, width: 1, color: const Color(0xFFE2E8F0));
  }

  Widget _buildPerformanceMetrics(double revenue, int inquiries, String status, bool isSmall) {
    final statusLabel = status == 'approved' || status == 'active' ? 'Approved' : status.capitalize();
    final statusColor = status == 'approved' || status == 'active' 
        ? const Color(0xFF16A34A) 
        : (status == 'pending' || status == 'under review' ? const Color(0xFFD97706) : const Color(0xFFEF4444));

    return Row(
      children: [
        _performanceItem(
          Icons.currency_rupee_rounded, 
          '₹${_formatRevenue(revenue)}', 
          'Revenue\n(This Month)', 
          const Color(0xFF2F5BEA),
          isSmall,
        ),
        const SizedBox(width: 12),
        _performanceItem(
          Icons.chat_bubble_outline_rounded, 
          inquiries.toString(), 
          'Inquiries', 
          const Color(0xFFF97316),
          isSmall,
        ),
        const SizedBox(width: 12),
        _performanceItem(
          Icons.check_circle_outline_rounded, 
          statusLabel, 
          'Status', 
          statusColor,
          isSmall,
        ),
      ],
    );
  }

  Widget _performanceItem(IconData icon, String value, String label, Color accent, bool isSmall) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isSmall ? 8 : 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRevenue(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildActionButtons(bool isSmall) {
    return Row(
      children: [
        Expanded(
          flex: 45,
          child: OutlinedButton.icon(
            onPressed: onViewDetails,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF16A34A),
              side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: TextStyle(fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 55,
          child: ElevatedButton.icon(
            onPressed: onManageProperty,
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text('Manage Property'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              textStyle: TextStyle(fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  num _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }
}
