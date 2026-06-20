import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class StickyBookingBar extends StatelessWidget {
  final Map<String, dynamic>? selectedRoom;
  final Map<String, dynamic>? selectedBed;
  final VoidCallback onBookPressed;
  final dynamic defaultRent;
  final dynamic defaultDeposit;

  const StickyBookingBar({
    super.key,
    this.selectedRoom,
    this.selectedBed,
    required this.onBookPressed,
    this.defaultRent,
    this.defaultDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBedSelected = selectedBed != null;
    final double rent = _parsePrice(selectedBed?['monthlyRent'] ?? defaultRent);
    final double deposit = _parsePrice(selectedBed?['securityDeposit'] ?? defaultDeposit);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: isBedSelected
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Room ${selectedRoom?['roomNumber']} | Bed ${selectedBed?['bedNumber']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹$rent',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select a bed to continue',
                          style: TextStyle(color: AppTheme.textLightColor, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        if (defaultRent != null)
                          Text(
                            'Starting from ₹$defaultRent',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: isBedSelected ? onBookPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey[300],
                minimumSize: const Size(140, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                elevation: 0,
              ),
              child: Text(
                isBedSelected ? 'Book Now' : 'Select Bed',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }
}
