import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final details = propertyData['propertyDetails'] ?? {};
    final amenities = propertyData['amenities'] as List? ?? [];
    final imageUrls = propertyData['image_urls'] as List? ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          
          // 1. Image Preview Header
          _buildImagePreview(imageUrls),
          const SizedBox(height: 32),

          // 2. Property Info Section
          _buildSectionHeader('Basic Information', () => onEdit(0)),
          _buildInfoCard(
            [
              _InfoRow('Name', basics['name'] ?? 'N/A'),
              _InfoRow('Type', basics['type'] ?? 'N/A'),
              _InfoRow('Manager', basics['wardenName'] ?? 'N/A'),
              _InfoRow('Contact', basics['wardenPhone'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Location Section
          _buildSectionHeader('Location', () => onEdit(1)),
          _buildInfoCard(
            [
              _InfoRow('Address', '${location['locality'] ?? 'N/A'}, ${location['city'] ?? 'N/A'}'),
              _InfoRow('Pincode', location['pincode'] ?? 'N/A'),
              _InfoRow('State', location['state'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Pricing Grid
          _buildSectionHeader('Pricing & Sharing', () => onEdit(5)),
          _buildPricingGrid(pricing),
          const SizedBox(height: 24),

          // 5. Property Details
          _buildSectionHeader('Property Details', () => onEdit(2)),
          _buildInfoCard(
            [
              _InfoRow('Gender Preference', details['gender'] ?? details['genderRestriction'] ?? 'Anyone'),
              _InfoRow('Total Capacity', '${details['totalCapacity'] ?? 0} Residents'),
              _InfoRow('Floors', details['floorsCount']?.toString() ?? '1'),
              _InfoRow('Rooms (S/D/T)', '${details['singleRooms'] ?? 0} / ${details['doubleRooms'] ?? 0} / ${details['tripleRooms'] ?? 0}'),
              if ((details['dormitoryBeds'] ?? 0) > 0)
                _InfoRow('Dormitory Beds', details['dormitoryBeds'].toString()),
            ],
          ),
          const SizedBox(height: 24),

          // 6. Amenities
          _buildSectionHeader('Amenities', () => onEdit(3)),
          _buildAmenitiesChips(amenities),
          const SizedBox(height: 24),

          // 7. Checklists
          _buildStatusItem(
            'Documents & Compliance',
            (propertyData['documents'] as Map?)?['isCompleted'] == true,
            Icons.description_outlined,
            () => onEdit(6),
          ),
          _buildStatusItem(
            'Host Profile & Identity',
            propertyData['hostProfile'] != null,
            Icons.person_outline_rounded,
            () => onEdit(7),
          ),

          const SizedBox(height: 48),
          
          // Submit Button
          _buildSubmitButton(),
          
          const SizedBox(height: 24),
          _buildVerificationNote(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Listing',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontFamily,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ensure all details are accurate before submitting for verification.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textLightColor.withValues(alpha: 0.8),
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(List images) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.grey[200],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: images.isEmpty
            ? const Center(child: Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey))
            : CachedNetworkImage(
                imageUrl: images[0].toString(),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.textMutedColor,
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.successColor,
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  row.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  row.value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPricingGrid(Map pricing) {
    final sharingTypes = [
      {'label': 'Single', 'key': 'singleRent'},
      {'label': 'Double', 'key': 'doubleRent'},
      {'label': 'Triple', 'key': 'tripleRent'},
      {'label': '4-Sharing', 'key': 'fourSharingRent'},
      {'label': '6-Sharing', 'key': 'sixSharingRent'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: sharingTypes.where((t) => pricing[t['key']]?.toString().isNotEmpty == true).map((t) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t['label']!,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${pricing[t['key']]}',
                  style: const TextStyle(fontSize: 16, color: AppTheme.textColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAmenitiesChips(List amenities) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((a) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.successColor),
            const SizedBox(width: 8),
            Text(
              a.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildStatusItem(String title, bool isCompleted, IconData icon, VoidCallback onEdit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCompleted ? AppTheme.successColor.withValues(alpha: 0.3) : AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCompleted ? AppTheme.successColor : Colors.grey).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isCompleted ? AppTheme.successColor : Colors.grey, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  isCompleted ? 'Information Verified' : 'Action Required',
                  style: TextStyle(
                    fontSize: 11,
                    color: isCompleted ? AppTheme.successColor : AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.chevron_right, color: AppTheme.textMutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : const Text(
                'Submit for Approval',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildVerificationNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_outlined, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your listing will be reviewed by our team within 24-48 hours. You\'ll be notified once it\'s live.',
              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}
