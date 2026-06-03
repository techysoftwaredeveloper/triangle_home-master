import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class ReviewSubmitStep extends StatelessWidget {
  final Map<String, dynamic> propertyData;
  final VoidCallback onSubmit;
  final Function(int) onEdit;
  final bool isSubmitting;

  const ReviewSubmitStep({
    super.key,
    required this.propertyData,
    required this.onSubmit,
    required this.onEdit,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final basics = propertyData['propertyBasics'] ?? {};
    final location = propertyData['location'] ?? {};
    final pricing = propertyData['pricing'] ?? {};

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Your Listing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Double check your details before submitting',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textLightColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 32),

          _buildSummaryCard(
            title: 'Property Info',
            icon: Icons.home_work_outlined,
            details: [
              'Name: ${basics['name'] ?? 'N/A'}',
              'Type: ${basics['type'] ?? 'N/A'}',
              'Manager: ${basics['wardenName'] ?? 'N/A'}',
            ],
            onEdit: () => onEdit(2),
          ),

          _buildSummaryCard(
            title: 'Location',
            icon: Icons.location_on_outlined,
            details: [
              '${location['locality'] ?? 'N/A'}, ${location['city'] ?? 'N/A'}',
              'Pincode: ${location['pincode'] ?? 'N/A'}',
            ],
            onEdit: () => onEdit(3),
          ),

          _buildSummaryCard(
            title: 'Pricing',
            icon: Icons.payments_outlined,
            details: [
              'Single Room: ₹${pricing['singleRent'] ?? 'N/A'}',
              'Double Sharing: ₹${pricing['doubleRent'] ?? 'N/A'}',
            ],
            onEdit: () => onEdit(7),
          ),

          _buildSummaryItem(
            Icons.person_outline_rounded,
            'Host Profile',
            true,
            onEdit: () => onEdit(0),
          ),
          _buildSummaryItem(
            Icons.verified_user_outlined,
            'Identity Verification',
            true,
            onEdit: () => onEdit(1),
          ),
          _buildSummaryItem(
            Icons.meeting_room_outlined,
            'Amenities & Rooms',
            true,
            onEdit: () => onEdit(4),
          ),
          _buildSummaryItem(
            Icons.photo_library_outlined,
            'Photos (${(propertyData['image_urls'] as List?)?.length ?? 0})',
            (propertyData['image_urls'] as List?)?.isNotEmpty == true,
            onEdit: () => onEdit(6),
          ),
          _buildSummaryItem(
            Icons.description_outlined,
            'Documents',
            (propertyData['documents'] as Map?)?['isCompleted'] == true,
            onEdit: () => onEdit(8),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child:
                  isSubmitting
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                      : const Text(
                        'Submit for Approval',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Outfit',
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppTheme.textMutedColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Your listing will be reviewed in 24-48 hours',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMutedColor.withValues(alpha: 0.8),
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required List<String> details,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Outfit',
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.successColor,
                  size: 18,
                ),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                detail,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textLightColor,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String title,
    bool isCompleted, {
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isCompleted ? AppTheme.successColor : AppTheme.textMutedColor,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.successColor,
                  size: 18,
                ),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else ...[
              Text(
                isCompleted ? 'Completed' : 'Pending',
                style: TextStyle(
                  color:
                      isCompleted
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCompleted ? Icons.check_circle : Icons.pending,
                color:
                    isCompleted ? AppTheme.successColor : AppTheme.warningColor,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
