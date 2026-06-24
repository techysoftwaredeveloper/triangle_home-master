import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/screens/hoster/hoster_profile_screen.dart';
import 'package:triangle_home/screens/hoster/partner_onboarding_screen.dart';
import 'package:triangle_home/screens/hoster/booking_detail_screen.dart';
import 'package:triangle_home/screens/hoster/lead_detail_screen.dart';
import 'package:triangle_home/screens/hoster/property_operational_center.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/services/booking_service.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/services/lead_service.dart';
import 'package:triangle_home/services/admin_api_service.dart';
import 'package:triangle_home/models/lead.dart';
import 'package:triangle_home/models/property_stats_model.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/hoster/hoster_bottom_nav.dart';
import 'package:triangle_home/widgets/hoster/hoster_property_card.dart';
import 'package:triangle_home/widgets/hoster/dashboard_property_card.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/core/extensions/string_extensions.dart';
import 'package:triangle_home/services/review_service.dart';
import 'package:triangle_home/models/review_model.dart';

num _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
  return 0;
}

class HosterDashboardScreen extends StatefulWidget {
  const HosterDashboardScreen({super.key});

  @override
  State<HosterDashboardScreen> createState() => _HosterDashboardScreenState();
}

class _HosterDashboardScreenState extends State<HosterDashboardScreen> {
  int _selectedIndex = 0;
  final PropertyService _propertyService = PropertyService();
  final BookingService _bookingService = BookingService();
  final HosterService _hosterService = HosterService();
  final AdminApiService _adminApiService = AdminApiService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _hosterService.getDetailedHosterStatsStream(_uid),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final accountStatus = data['accountStatus']?.toString() ?? 'pending';
        
        // Unified check for Hoster Approval from the data stream
        final isApproved = data['hosterVerified'] == true;
        final isPending = !isApproved;
        final isRejected = accountStatus == 'rejected';

        final tabs = [
          _DashboardTab(
            uid: _uid, 
            hosterService: _hosterService,
            onRefresh: _handleGlobalRefresh,
          ),
          _PropertiesTab(uid: _uid, propertyService: _propertyService),
          _BookingsTab(uid: _uid, bookingService: _bookingService),
          _LeadsTab(uid: _uid),
          const HosterProfileScreen(),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Stack(
            children: [
              tabs[_selectedIndex],
              if (isPending && (_selectedIndex > 0 && _selectedIndex < 4))
                _buildRestrictedOverlay(isRejected),
            ],
          ),
          bottomNavigationBar: HosterBottomNav(
            selectedIndex: _selectedIndex,
            onTap: _onNavTap,
            leadsCount: _parseNum(data['newLeadsCount']).toInt(),
          ),
          floatingActionButton: _selectedIndex == 2 && !isPending
              ? FloatingActionButton.extended(
                  onPressed: () {},
                  backgroundColor: AppTheme.forestGreen,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text(
                    'New Booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  elevation: 10,
                )
              : null,
        );
      },
    );
  }

  Widget _buildRestrictedOverlay(bool isRejected) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(
              isRejected ? Icons.gpp_bad_rounded : Icons.lock_person_rounded, 
              color: isRejected ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), 
              size: 40
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isRejected ? 'Application Rejected' : 'Features Restricted',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isRejected 
                  ? 'Your application was not approved. Please check the reason on your dashboard and resubmit.' 
                  : 'Your account is under verification. Please wait for admin approval to manage properties, bookings, or leads.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _selectedIndex = 0),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGlobalRefresh() async {
    try {
      // 1. Get properties
      final snapshot = await _propertyService.getHosterProperties(_uid).first;
      
      // 2. Trigger reconciliation for each property
      for (var doc in snapshot) {
        await _adminApiService.reconcileProperty(doc.id);
      }
      
      // 3. Force rebuild
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }
}

// â”€â”€ Dashboard Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DashboardTab extends StatelessWidget {
  final String uid;
  final HosterService hosterService;
  final Future<void> Function() onRefresh;
  const _DashboardTab({
    required this.uid, 
    required this.hosterService,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: hosterService.getDetailedHosterStatsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final properties = data['properties'] as List? ?? [];
        final recentActivity = data['recentActivity'] as List? ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildHeader(context, data),
          body: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  if (data['accountStatus'] == 'pending')
                    _buildPendingBanner()
                  else if (data['accountStatus'] == 'rejected')
                    _buildRejectedBanner(context, data['adminReviewNote'] ?? 'No reason provided'),
                  
                  _buildSectionHeader('Live Performance'),
                  const SizedBox(height: 16),
                  _buildOverviewGrid(data),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Today\'s Actions'),
                  _buildActionCards(data),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('My Properties', onViewAll: () {}),
                  const SizedBox(height: 16),
                  _buildPropertiesCarousel(context, properties, data),
                  
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRevenueInsight(data)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildHostManagement(data)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Recent Activity'),
                  _buildRecentActivity(recentActivity),

                  const SizedBox(height: 32),
                  _buildSectionHeader('Guest Reviews'),
                  _buildReviewsManagement(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsManagement(BuildContext context) {
    // In a real multi-property hoster dashboard, we'd need to aggregate reviews from all properties.
    // For now, let's show reviews for the hoster's properties.
    return StreamBuilder<List<ReviewModel>>(
      // This is a simplified implementation. A production one would have getReviewsByHoster(uid)
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .snapshots()
          .map((snap) => snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList()),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No reviews yet.', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Column(
          children: reviews.take(3).map((review) => _buildHosterReviewCard(context, review)).toList(),
        );
      },
    );
  }

  Widget _buildHosterReviewCard(BuildContext context, ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: review.userImage != null ? CachedNetworkImageProvider(review.userImage!) : null,
                child: review.userImage == null ? const Icon(Icons.person, size: 16) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(DateFormat('MMM dd, yyyy').format(review.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(review.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          const SizedBox(height: 12),
          if (review.hosterReply == null)
            TextButton.icon(
              onPressed: () => _showReplyDialog(context, review),
              icon: const Icon(Icons.reply, size: 16),
              label: const Text('Reply to review', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.forestGreen,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Reply:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.forestGreen)),
                  const SizedBox(height: 4),
                  Text(review.hosterReply!, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, ReviewModel review) {
    final TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Review'),
        content: TextField(
          controller: replyController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Type your response...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.isNotEmpty) {
                await ReviewService().replyToReview(review.id, replyController.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.forestGreen),
            child: const Text('Post Reply'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context, Map data) {
    final name = data['hosterName'] ?? 'Host';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'H';
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 70,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
        onPressed: () {},
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF0FDF4),
              backgroundImage: data['profileImage'] != null ? CachedNetworkImageProvider(data['profileImage']) : null,
              child: data['profileImage'] == null ? Text(
                initial,
                style: const TextStyle(
                  color: AppTheme.forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Good Morning, $name 👋',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      data['hosterRole'] ?? 'Host & Property Manager',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (data['hosterVerified'] == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 12),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF1E293B),
              ),
            ),
            if (_parseNum(data['unreadNotificationsCount']).toInt() > 0)
              Positioned(
                top: 18,
                right: 14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTopPropertyCarousel(List properties) {
    if (properties.isEmpty) return const SizedBox.shrink();

    // Filter for active/approved properties only for the top picker
    final activeProperties = properties.where((p) {
      final status = (p['status'] ?? 'pending').toString().toLowerCase();
      return status == 'active' || status == 'approved';
    }).toList();

    if (activeProperties.isEmpty) {
      // Fallback to show the first property if none are "active" yet
      return _buildPropertyStatusCard(properties.first);
    }

    return SizedBox(
      height: 140,
      child: PageView.builder(
        itemCount: activeProperties.length,
        controller: PageController(viewportFraction: 0.95),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildPropertyStatusCard(activeProperties[index]),
          );
        },
      ),
    );
  }

  Widget _buildPropertyStatusCard(Map? property) {
    if (property == null) return const SizedBox.shrink();
    final images = property['images'] as List? ?? [];
    final name = property['basicInfo']?['name'] ?? 'Property';
    final occupancy = 0; // Or calculate from data if available

    final propStatus = (property['status'] ?? 'pending').toString().toLowerCase();
    final isActive = propStatus == 'active' || propStatus == 'approved';
    final isUnderReview = propStatus == 'pending' || propStatus == 'under review';
    final isPaused = propStatus == 'paused';

    final statusLabel = isActive 
        ? 'Active' 
        : propStatus == 'under review'
            ? 'Under Review'
            : propStatus == 'pending'
                ? 'Pending'
                : propStatus.capitalize();
                
    final statusBg = isActive 
        ? const Color(0xFFDCFCE7) 
        : isUnderReview 
            ? const Color(0xFFFEF3C7) 
            : isPaused 
                ? const Color(0xFFDBEAFE) 
                : const Color(0xFFF1F5F9);
                
    final statusFg = isActive 
        ? const Color(0xFF16A34A) 
        : isUnderReview 
            ? const Color(0xFFD97706) 
            : isPaused 
                ? const Color(0xFF2563EB) 
                : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                images.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: images.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                    : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.apartment),
                    ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                fontFamily: 'Outfit',
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusFg,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${property['city'] ?? "Kochi"}, ${property['locality'] ?? "Kerala"}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${_joinedDate(property)}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildCircularOccupancy(occupancy),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  String _joinedDate(Map? property) {
    if (property == null) return 'â€”';
    final ts = property['createdAt'];
    if (ts is Timestamp) {
      final d = ts.toDate();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.year}';
    }
    return 'â€”';
  }

  Widget _buildCircularOccupancy(int value) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: value / 100,
            strokeWidth: 4,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Text(
              'Occupancy',
              style: TextStyle(
                fontSize: 6,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCards(Map data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _actionCard(
            'New Inquiries',
            data['newInquiries']?.toString() ?? '0',
            Icons.chat_bubble_rounded,
            const Color(0xFF3B82F6),
          ),
          _actionCard(
            'Pending Check-ins',
            data['pendingCheckins']?.toString() ?? '0',
            Icons.calendar_today_rounded,
            const Color(0xFFF59E0B),
          ),
          _actionCard(
            'Rent Payments Due',
            data['paymentsDue']?.toString() ?? '0',
            Icons.currency_rupee_rounded,
            const Color(0xFFF97316),
          ),
          _actionCard(
            'Bookings Confirmed',
            data['bookingsConfirmed']?.toString() ?? '0',
            Icons.check_circle_rounded,
            const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, String count, IconData icon, Color color) {
    return Container(
      width: 130,
      height: 160,
      margin: const EdgeInsets.only(right: 12, top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(Map data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4, // Decreased to provide more height
      children: [
        _overviewCard(
          'Active Residents',
          data['activeResidents']?.toString() ?? '0',
          Icons.people_outline_rounded,
          const Color(0xFF6366F1),
        ),
        _overviewCard(
          'Vacant Beds',
          data['vacantBeds']?.toString() ?? '0',
          Icons.bed_outlined,
          const Color(0xFF3B82F6),
        ),
        _overviewCard(
          'Occupancy',
          '${data['occupancy'] ?? 0}%',
          Icons.pie_chart_outline_rounded,
          const Color(0xFF10B981),
        ),
        _overviewCard(
          'Monthly Revenue',
          '₹${_formatRevenueAmount(data['monthlyRevenue'])}',
          Icons.account_balance_wallet_outlined,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  String _formatRevenueAmount(dynamic amount) {
    final num val = _parseNum(amount);
    if (val >= 100000) {
      return '${(val / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,##,###').format(val);
  }

  Widget _overviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Slightly smaller icon container
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFCBD5E1)),
            ],
          ),
          const Spacer(), // Use spacer for flexible middle area
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18, // Slightly smaller font
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Outfit',
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesCarousel(BuildContext context, List properties, Map data) {
    if (properties.isEmpty) {
      return Container(
        height: 240,
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home_work_outlined, size: 32, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No properties listed yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start earning by listing your first property',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ListPropertyScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('List Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 520, // Height for the premium DashboardPropertyCard
          child: PageView.builder(
            itemCount: properties.length,
            controller: PageController(viewportFraction: 0.9),
            itemBuilder: (context, index) {
              final p = properties[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('propertyStats')
                      .doc(p['id'])
                      .snapshots(),
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.hasData && statsSnapshot.data!.exists
                        ? PropertyStatsModel.fromFirestore(statsSnapshot.data!)
                        : null;

                    // Prepare accurate data for the card
                    final Map<String, dynamic> accurateData = Map.from(p);
                    if (stats != null) {
                      accurateData['totalBeds'] = stats.totalBeds;
                      accurateData['activeResidents'] = stats.occupiedBeds;
                      accurateData['occupancy'] = stats.totalBeds > 0 
                          ? (stats.occupiedBeds / stats.totalBeds * 100).round() 
                          : 0;
                    }

                    return DashboardPropertyCard(
                      data: accurateData,
                      onViewDetails: () {
                        final propertyId = p['id'] ?? '';
                        if (propertyId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PropertyOperationalCenter(
                                propertyId: propertyId,
                                propertyData: accurateData,
                              ),
                            ),
                          );
                        }
                      },
                      onManageProperty: () {
                        final propertyId = p['id'] ?? '';
                        if (propertyId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PropertyOperationalCenter(
                                propertyId: propertyId,
                                propertyData: accurateData,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            properties.length > 5 ? 5 : properties.length,
            (i) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i == 0 ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueInsight(Map data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Revenue This Month',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'View Report',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${(data['monthlyRevenue'] ?? 0).toString()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: _buildRevenueChart(data['chartData']),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthStart(),
                style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
              ),
              Text(
                _monthEnd(),
                style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthStart() {
    final now = DateTime.now();
    return '1 ${_monthName(now.month)}';
  }

  String _monthEnd() {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month + 1, 0).day;
    return '$last ${_monthName(now.month)}';
  }

  String _monthName(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[(m - 1).clamp(0, 11)];
  }

  Widget _buildRevenueChart(dynamic rawChart) {
    List<double> values;
    if (rawChart is List && rawChart.isNotEmpty) {
      values = rawChart.map((v) => (v as num).toDouble()).toList();
    } else {
      values = [1, 1, 1, 1, 1, 1, 1];
    }
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), maxVal > 0 ? values[i] : 1),
    );
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF16A34A),
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostManagement(Map data) {
    final totalProps = data['totalProperties'] as int? ?? 0;
    final activeListings = data['activeListings'] as int? ?? 0;
    final pendingInquiries = data['newInquiries'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Property Stats',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _mgmtRow(
            Icons.home_work_outlined,
            'Total Properties',
            '$totalProps',
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _mgmtRow(
            Icons.check_circle_outline_rounded,
            'Active Listings',
            '$activeListings',
            const Color(0xFF16A34A),
          ),
          const SizedBox(height: 12),
          _mgmtRow(
            Icons.chat_bubble_outline_rounded,
            'Open Inquiries',
            '$pendingInquiries',
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _mgmtRow(
            Icons.people_outline_rounded,
            'Active Residents',
            '${data['activeResidents'] ?? 0}',
            const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _mgmtRow(IconData i, String l, String v, Color c) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(i, size: 14, color: c),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          v,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Under Review',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF92400E),
                  ),
                ),
                Text(
                  'Admin is verifying your documents. Features will be unlocked once approved.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner(BuildContext context, String reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application Rejected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    Text(
                      'Reason: $reason',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartnerOnboardingScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Edit & Resubmit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List activities) {
    return Column(
      children:
          activities
              .map(
                (a) => Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              (a['type'] == 'booking'
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFFF7ED)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          a['type'] == 'booking'
                              ? Icons.calendar_today_rounded
                              : Icons.currency_rupee_rounded,
                          size: 16,
                          color:
                              (a['type'] == 'booking'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFF59E0B)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a['title'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a['time'],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontFamily: 'Outfit',
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }
}

// â”€â”€ Properties Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PropertiesTab extends StatefulWidget {
  final String uid;
  final PropertyService propertyService;
  const _PropertiesTab({required this.uid, required this.propertyService});

  @override
  State<_PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<_PropertiesTab> {
  String _selectedStatus = 'All Properties';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns true if a property doc should be shown under the current filter.
  bool _matchesStatus(Map<String, dynamic> d) {
    final status = (d['status'] ?? 'pending').toString().toLowerCase();
    switch (_selectedStatus) {
      case 'Active':
        return status == 'active' || status == 'approved';
      case 'Under Review':
        return status == 'pending' || status == 'under review';
      case 'Draft':
        return status == 'draft';
      case 'Inactive':
        return status == 'inactive' || status == 'suspended' || status == 'rejected';
      default:
        return true; // 'All Properties'
    }
  }

  bool _matchesSearch(Map<String, dynamic> d) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final basic = d['basicInfo'] as Map? ?? {};
    final name = (d['name'] ?? basic['collegeName'] ?? d['title'] ?? '').toString().toLowerCase();
    final location = (d['locality'] ?? d['city'] ?? d['address'] ?? '').toString().toLowerCase();
    return name.contains(query) || location.contains(query);
  }

  final List<String> _statuses = [
    'All Properties',
    'Active',
    'Under Review',
    'Draft',
    'Inactive',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Properties',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF16A34A)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListPropertyScreen()),
              );
            },
            tooltip: 'Add Property',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: widget.propertyService.getHosterProperties(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data ?? [];

          // Calculate counts for summary cards (always from full list)
          int activeCount = 0;
          int underReviewCount = 0;
          int draftCount = 0;

          for (var doc in allDocs) {
            final status = (doc.data()['status'] ?? 'pending').toString().toLowerCase();
            if (status == 'active' || status == 'approved') {
              activeCount++;
            } else if (status == 'pending' || status == 'under review') {
              underReviewCount++;
            } else if (status == 'draft') {
              draftCount++;
            }
          }

          // Apply status + search filters
          final filteredDocs = allDocs.where((doc) {
            final d = {'id': doc.id, ...doc.data()};
            return _matchesStatus(d) && _matchesSearch(d);
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(activeCount, underReviewCount, draftCount),
                      const SizedBox(height: 24),
                      _buildSearchAndFilter(),
                      const SizedBox(height: 20),
                      _buildStatusTabs(),
                    ],
                  ),
                ),
              ),
              if (filteredDocs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Inject the Firestore doc ID so propertyId is never empty
                        final doc = filteredDocs[index];
                        final data = {'id': doc.id, ...doc.data()};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('propertyStats')
                                .doc(doc.id)
                                .snapshots(),
                            builder: (context, statsSnapshot) {
                              final stats = statsSnapshot.hasData && statsSnapshot.data!.exists
                                  ? PropertyStatsModel.fromFirestore(statsSnapshot.data!)
                                  : null;

                              // Prepare accurate data for the card
                              final Map<String, dynamic> accurateData = Map.from(data);
                              if (stats != null) {
                                accurateData['capacity'] = stats.totalBeds;
                                accurateData['activeResidents'] = stats.occupiedBeds;
                              }

                              return HosterPropertyCard(
                                data: accurateData,
                                onViewDetails: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PropertyOperationalCenter(
                                        propertyId: doc.id,
                                        propertyData: accurateData,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                      childCount: filteredDocs.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int active, int review, int draft) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 350;
        return GridView.count(
          crossAxisCount: isNarrow ? 2 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isNarrow ? 1.4 : 1.1,
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedStatus = 'Active'),
              child: _summaryCard('Active', active, const Color(0xFF16A34A), Icons.home_rounded, const Color(0xFFDCFCE7), _selectedStatus == 'Active'),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedStatus = 'Under Review'),
              child: _summaryCard('Under Review', review, const Color(0xFFD97706), Icons.access_time_filled_rounded, const Color(0xFFFEF3C7), _selectedStatus == 'Under Review'),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedStatus = 'Draft'),
              child: _summaryCard('Draft', draft, const Color(0xFF2563EB), Icons.description_rounded, const Color(0xFFDBEAFE), _selectedStatus == 'Draft'),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(String label, int count, Color color, IconData icon, Color bgColor, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFF1F5F9),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showText = constraints.maxWidth > 380;
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search properties...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
                  if (showText) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Filter',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _statuses.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = status),
              child: Column(
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isSelected)
                    Container(
                      height: 2,
                      width: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildEmptyState() {
    final isFiltered = _selectedStatus != 'All Properties' || _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off_rounded : Icons.home_work_outlined,
            size: 64,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No properties match "$_selectedStatus"'
                : 'No properties listed yet',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try selecting a different filter or clear your search.'
                : 'Start earning by listing your first property',
            style: const TextStyle(color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (isFiltered)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _selectedStatus = 'All Properties';
                _searchController.clear();
              }),
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: const Text('Clear Filter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ListPropertyScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bookings Tab ──────────────────────────────────────────────────────────────
class _BookingsTab extends StatefulWidget {
  final String uid;
  final BookingService bookingService;
  const _BookingsTab({required this.uid, required this.bookingService});

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  String _selectedStatus = 'All Bookings';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = [
    'All Bookings',
    'Upcoming',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bookings',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                fontSize: 20,
              ),
            ),
            Text(
              'Manage all property bookings',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1E293B),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '4',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: widget.bookingService.getHosterBookings(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data ?? [];
          
          // Calculate metrics
          int total = allDocs.length;
          int upcoming = allDocs.where((d) => (d.data()['status'] ?? '').toString().toLowerCase() == 'pending').length;
          int confirmed = allDocs.where((d) => (d.data()['status'] ?? '').toString().toLowerCase() == 'confirmed').length;
          int cancelled = allDocs.where((d) => (d.data()['status'] ?? '').toString().toLowerCase() == 'cancelled').length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildSummaryMetrics(total, upcoming, confirmed, cancelled),
                      const SizedBox(height: 24),
                      _buildSearchAndFilter(),
                      const SizedBox(height: 20),
                      _buildStatusTabs(),
                    ],
                  ),
                ),
              ),
              if (allDocs.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No bookings received yet')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == allDocs.length) {
                          return _buildNewBookingBanner();
                        }
                        final data = allDocs[index].data();
                        return _EnhancedBookingCard(data: data, bookingId: allDocs[index].id);
                      },
                      childCount: allDocs.length + 1,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryMetrics(int total, int upcoming, int confirmed, int cancelled) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _metricCard('Total Bookings', total, Icons.calendar_today_outlined, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
          const SizedBox(width: 12),
          _metricCard('Upcoming', upcoming, Icons.access_time_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          const SizedBox(width: 12),
          _metricCard('Confirmed', confirmed, Icons.check_circle_outline_rounded, const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
          const SizedBox(width: 12),
          _metricCard('Cancelled', cancelled, Icons.cancel_outlined, const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
        ],
      ),
    );
  }

  Widget _metricCard(String label, int count, IconData icon, Color color, Color bgColor) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label, 
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showText = constraints.maxWidth > 380;
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by tenant, property or phone...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
                  if (showText) ...[
                    const SizedBox(width: 8),
                    const Text('Filter', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _statuses.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = status),
              child: Column(
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isSelected)
                    Container(
                      height: 2,
                      width: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewBookingBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.event_available_rounded, color: Color(0xFF16A34A), size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Booking',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Add a new booking manually for a tenant.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, size: 16),
                SizedBox(width: 4),
                Text('New Booking', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedBookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  const _EnhancedBookingCard({required this.data, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final isConfirmed = status == 'confirmed';
    final isUpcoming = status == 'pending';
    final isCompleted = status == 'completed';

    final statusLabel = status.toUpperCase();
    final statusColor = isConfirmed ? const Color(0xFF2563EB) : isUpcoming ? const Color(0xFFD97706) : isCompleted ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final statusBg = isConfirmed ? const Color(0xFFDBEAFE) : isUpcoming ? const Color(0xFFFEF3C7) : isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);

    final String propertyName = data['propertyName'] ?? 'Property';
    final String residentName = data['studentName'] ?? 'Resident';
    final double rent = _parseNum(data['price']).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(bookingId: bookingId, bookingData: data),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.apartment_rounded, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              propertyName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(residentName, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(data['studentPhone'] ?? '+91 98765 43210', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              Row(
                children: [
                  _infoItem(Icons.calendar_today_outlined, 'Check-in', _formatDate(data['createdAt'])),
                  const Spacer(),
                  _infoItem(Icons.bed_outlined, data['roomName'] ?? 'Room D-203', data['roomType'] ?? 'Double Room'),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('â‚¹${(rent / 1000).toStringAsFixed(1)}k', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      const Text('Monthly Rent', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _actionBtn(Icons.call_outlined, 'Call')),
                  const SizedBox(width: 8),
                  Expanded(child: _actionBtn(Icons.chat_outlined, 'WhatsApp')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'View Details',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF16A34A)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy').format(date);
    }
    return 'N/A';
  }
}

class _LeadsTab extends StatefulWidget {
  final String uid;
  const _LeadsTab({required this.uid});

  @override
  State<_LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<_LeadsTab> {
  final LeadService _leadService = LeadService();
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = [
    'All',
    'New',
    'Contacted',
    'Follow-Up',
    'Visit Scheduled',
    'Interested',
    'Converted',
    'Lost',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leads',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                fontSize: 20,
              ),
            ),
            Text(
              'Manage inquiries and booking prospects',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF1E293B)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Lead>>(
        stream: _leadService.getHosterLeads(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLeads = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildLeadMetrics(allLeads),
                      const SizedBox(height: 24),
                      _buildSearchAndFilter(),
                      const SizedBox(height: 20),
                      _buildQuickFilters(),
                      const SizedBox(height: 20),
                      _buildStatusTabs(),
                    ],
                  ),
                ),
              ),
              if (allLeads.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No leads found yet')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == allLeads.length) {
                          return const SizedBox(height: 100);
                        }
                        return _LeadCard(lead: allLeads[index]);
                      },
                      childCount: allLeads.length + 1,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.successColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLeadMetrics(List<Lead> leads) {
    final total = leads.length;
    final newLeads = leads.where((l) => l.status == LeadStatus.newLead).length;
    final followUp = leads.where((l) => l.nextFollowupDate != null && DateFormat('yyyy-MM-dd').format(l.nextFollowupDate!) == DateFormat('yyyy-MM-dd').format(DateTime.now())).length;
    final converted = leads.where((l) => l.status == LeadStatus.converted).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _metricCard('Total Leads', total, Icons.group_outlined, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
          const SizedBox(width: 12),
          _metricCard('New Leads', newLeads, Icons.auto_awesome_outlined, const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
          const SizedBox(width: 12),
          _metricCard('Follow-ups', followUp, Icons.calendar_today_outlined, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          const SizedBox(width: 12),
          _metricCard('Converted', converted, Icons.check_circle_outline_rounded, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF)),
        ],
      ),
    );
  }

  Widget _metricCard(String label, int count, IconData icon, Color color, Color bgColor) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label, 
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Text('View all', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search by name, phone or college...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterChip('Property', Icons.keyboard_arrow_down_rounded),
          _filterChip('Lead Status', Icons.keyboard_arrow_down_rounded),
          _filterChip('Type', Icons.keyboard_arrow_down_rounded),
          _filterChip('Source', Icons.keyboard_arrow_down_rounded),
        ],
      ),
    );
  }

  Widget _filterChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(width: 4),
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _statuses.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = status),
              child: Column(
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isSelected)
                    Container(
                      height: 2,
                      width: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  const _LeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(lead.status);
    final statusBg = statusColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeadDetailScreen(lead: lead),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.apartment_rounded, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(Icons.person, size: 14, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lead.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                _getStatusLabel(lead.status),
                                style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                lead.type.name.capitalize(),
                                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.verified_user_outlined, size: 12, color: Color(0xFF16A34A)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lead.studentInfo?['college'] ?? lead.professionalInfo?['company'] ?? 'Interested in PG',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          lead.phone,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _leadInfoItem('Interested Property', lead.interestedPropertyName ?? 'Sunrise PG', isPrimary: true),
                  _leadInfoItem('Move-in Date', _formatDate(lead.preferredMoveInDate)),
                  _leadInfoItem('Lead Source', lead.source ?? 'Triangle Homes'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _leadInfoItem('Sharing Preference', lead.preferredSharing ?? 'Double Sharing'),
                  _leadInfoItem('Budget Range', lead.budgetRange ?? 'â‚¹7,000 - â‚¹9,000'),
                  const SizedBox(width: 80), // Placeholder
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _actionBtn(Icons.call_outlined, 'Call')),
                  const SizedBox(width: 8),
                  Expanded(child: _actionBtn(Icons.chat_outlined, 'WhatsApp')),
                  const SizedBox(width: 8),
                  Expanded(child: _actionBtn(Icons.calendar_today_outlined, 'Schedule Visit', color: const Color(0xFF3B82F6))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leadInfoItem(String label, String value, {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isPrimary ? const Color(0xFF16A34A) : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, {Color color = const Color(0xFF16A34A)}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return const Color(0xFFF59E0B);
      case LeadStatus.contacted:
        return const Color(0xFF3B82F6);
      case LeadStatus.visitScheduled:
        return const Color(0xFF10B981);
      case LeadStatus.converted:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return 'NEW LEAD';
      case LeadStatus.visitScheduled:
        return 'VISIT SCHEDULED';
      default:
        return status.name.toUpperCase();
    }
  }
}
