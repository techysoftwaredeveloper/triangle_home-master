import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/core/extensions/string_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/property_service.dart';
import 'dart:math';

class HosterPropertyCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onViewDetails;

  const HosterPropertyCard({
    super.key,
    required this.data,
    this.onViewDetails,
  });

  @override
  State<HosterPropertyCard> createState() => _HosterPropertyCardState();
}

class _HosterPropertyCardState extends State<HosterPropertyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;
  final PropertyService _propertyService = PropertyService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  Future<void> _handleAction(PropertyStatus status) async {
    final propertyId = widget.data['id'] ?? '';
    if (propertyId.isEmpty) return;

    try {
      await _propertyService.requestPropertyAction(propertyId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property status updated to ${status.name}'),
            backgroundColor: AppTheme.forestGreen,
          ),
        );
        _flipCard(); // Flip back after action
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 300) {
          _flipCard();
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle < pi / 2
                ? _buildFront()
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    final basic = widget.data['basicInfo'] as Map? ?? {};
    final images = widget.data['images'] as List? ?? [];
    
    final name = basic['collegeName']?.toString().isNotEmpty == true
        ? basic['collegeName'].toString()
        : (widget.data['name'] ?? widget.data['title'] ?? 'Property').toString();
    
    final status = (widget.data['status'] ?? 'pending').toString().toLowerCase();
    final isActive = status == 'active' || status == 'approved';
    final isUnderReview = status == 'pending' || status == 'under review';
    
    final statusLabel = isActive ? 'Active' : isUnderReview ? 'Under Review' : status.capitalize();
    final statusColor = _getStatusColor(status);
    final statusBg = _getStatusBg(status);

    final int activeResidents = _parseNum(widget.data['activeResidents']).toInt();
    final int totalBeds = _parseNum(widget.data['capacity']).toInt();
    final int vacantBeds = totalBeds - activeResidents;
    final int occupancyPercent = _parseNum(widget.data['occupancy']).toInt();
    
    final double monthlyRent = _parseNum(widget.data['monthlyRent'] ?? widget.data['price']).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: images.first,
                              height: 110,
                              width: 110,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            )
                          : Container(
                              height: 110,
                              width: 110,
                              color: Colors.grey[200],
                              child: const Icon(Icons.home_work_outlined, color: Colors.grey),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          fontFamily: 'Outfit',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${widget.data['locality'] ?? widget.data['city'] ?? 'Location'}, Kerala',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        basic['type'] ?? 'Double & Triple Sharing',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _miniStat('$occupancyPercent%', 'Occupancy', const Color(0xFF16A34A)),
                          _miniStat('$vacantBeds', 'Vacant Beds', const Color(0xFF1E293B)),
                          _miniStat('$activeResidents', 'Residents', const Color(0xFF1E293B)),
                          _miniStat(
                            '₹${(monthlyRent / 1000).toStringAsFixed(1)}k',
                            'Rent',
                            const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUnderReview)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Review in progress',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                        ),
                        Text(
                          'Submitted on ${_formatDate(widget.data['createdAt'])}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF9A3412)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF9A3412)),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onViewDetails,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text(
                              'View Details',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.swipe_rounded, size: 16, color: Color(0xFFCBD5E1)),
                  const Text(
                    ' Swipe for Actions',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Outfit',
                  ),
                ),
                GestureDetector(
                  onTap: _flipCard,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _quickActionBtn(
                            Icons.check_circle_rounded,
                            'Active',
                            const Color(0xFF16A34A),
                            () => _handleAction(PropertyStatus.active),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickActionBtn(
                            Icons.block_rounded,
                            'Temp Block',
                            const Color(0xFFF59E0B),
                            () => _handleAction(PropertyStatus.blocked),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _quickActionBtn(
                            Icons.build_rounded,
                            'Under Renewal',
                            const Color(0xFF3B82F6),
                            () => _handleAction(PropertyStatus.renewal),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickActionBtn(
                            Icons.visibility_off_rounded,
                            'Disable',
                            const Color(0xFF94A3B8),
                            () => _handleAction(PropertyStatus.disabled),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _quickActionBtn(
                            Icons.delete_forever_rounded,
                            'Delete Request',
                            const Color(0xFFEF4444),
                            () => _handleAction(PropertyStatus.deleteRequested),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe_rounded, color: Colors.white.withValues(alpha: 0.3), size: 12),
                const SizedBox(width: 6),
                Text(
                  'Scroll or Swipe to return',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 38, // Fixed height for consistency in rows
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
      case 'approved':
        return const Color(0xFF16A34A);
      case 'pending':
      case 'under review':
        return const Color(0xFFD97706);
      case 'blocked':
      case 'suspended':
        return const Color(0xFFEF4444);
      case 'renewal':
        return const Color(0xFF3B82F6);
      case 'disabled':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'active':
      case 'approved':
        return const Color(0xFFDCFCE7);
      case 'pending':
      case 'under review':
        return const Color(0xFFFEF3C7);
      case 'blocked':
      case 'suspended':
        return const Color(0xFFFEE2E2);
      case 'renewal':
        return const Color(0xFFDBEAFE);
      case 'disabled':
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Widget _miniStat(String val, String label, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valColor)),
        Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy').format(date);
    }
    return 'N/A';
  }

  num _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }
}
