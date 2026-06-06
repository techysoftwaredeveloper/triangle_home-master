import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class StickyBookingBar extends StatelessWidget {
  final Map<String, dynamic>? selectedRoom;
  final Map<String, dynamic>? selectedBed;
  final VoidCallback onBookPressed;

  const StickyBookingBar({
    super.key,
    this.selectedRoom,
    this.selectedBed,
    required this.onBookPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBedSelected = selectedBed != null;

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
                          Text(
                            'Room ${selectedRoom?['roomNumber']} - Bed ${selectedBed?['bedNumber']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text('Change', style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${selectedBed?['monthlyRent']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const Text('/Month', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 12),
                          Text(
                            'Deposit ₹${selectedBed?['securityDeposit']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  )
                : const Text(
                    'Select a Bed to Continue',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: isBedSelected ? onBookPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              disabledBackgroundColor: Colors.grey[300],
              minimumSize: const Size(140, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Book This Bed',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
