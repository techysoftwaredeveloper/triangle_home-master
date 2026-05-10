import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _firebaseService = FirebaseService();

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.calendar_today_rounded;
      case 'payment':
        return Icons.account_balance_wallet_rounded;
      case 'property':
        return Icons.home_work_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'alert':
        return Icons.report_problem_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return AppTheme.accentColor;
      case 'payment':
        return AppTheme.successColor;
      case 'property':
        return AppTheme.primaryColor;
      case 'review':
        return AppTheme.warningColor;
      case 'alert':
        return AppTheme.errorColor;
      default:
        return AppTheme.textMutedColor;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 22),
            tooltip: 'Mark all as read',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firebaseService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(docs),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final isRead = data['isRead'] as bool? ?? false;
                    final type = data['type'] as String? ?? 'general';
                    final title = data['title'] as String? ?? 'Notification';
                    final body = data['body'] as String? ?? data['message'] as String? ?? '';
                    final timestamp = data['createdAt'];

                    return _buildNotificationCard(doc.id, isRead, type, title, body, timestamp, index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final unreadCount = docs.where((doc) => !(doc.data()['isRead'] as bool? ?? false)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Updates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.textDarkColor,
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount New Messages',
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String id, bool isRead, String type, String title, String body, dynamic timestamp, int index) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Remove',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 24),
          ],
        ),
      ),
      onDismissed: (_) => _deleteNotification(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: isRead ? 0 : 4,
          shadowColor: Colors.black.withOpacity(0.08),
          child: InkWell(
            onTap: () => _markAsRead(id, isRead),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isRead ? AppTheme.dividerColor.withOpacity(0.5) : AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branded Status Icon
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getIconColor(type).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(type),
                          color: _getIconColor(type),
                          size: 24,
                        ),
                      ),
                      if (!isRead)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
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
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: AppTheme.fontFamily,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: isRead ? AppTheme.textMutedColor : AppTheme.accentColor,
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 13,
                            color: isRead ? AppTheme.textLightColor : AppTheme.textColor.withOpacity(0.9),
                            fontFamily: AppTheme.fontFamily,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.textDarkColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'You have no new notifications.\nWe\'ll let you know when something pops up!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLightColor,
              fontFamily: AppTheme.fontFamily,
              height: 1.5,
            ),
          ),
        ],
      ).animate().fadeIn().scale(duration: 400.ms),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 20),
          const Text(
            'Connection lost',
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Please check your internet and try again.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(String docId, bool isRead) async {
    if (!isRead) {
      await _firebaseService.markNotificationRead(docId);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications marked as read.'),
            backgroundColor: AppTheme.textDarkColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteNotification(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();
    } catch (_) {}
  }
}
