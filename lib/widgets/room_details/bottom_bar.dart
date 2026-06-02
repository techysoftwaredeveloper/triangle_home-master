import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/booking_summary_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

import 'package:triangle_home/widgets/inventory/bed_selection_sheet.dart';
import 'package:triangle_home/models/room_model.dart';
import 'package:triangle_home/models/bed_model.dart';

/// CTA flow for Hostel/PG:
///   Step 0 (no selection)  → "Check Availability" (disabled, or shows picker prompt)
///   Step 1 (selection made, not confirmed) → "Check Availability" (enabled)
///   Step 2 (after tapping Check Availability) → secondary row with "Schedule Visit" + "Contact"
///                                              + primary "Apply Now" button
///
/// For Apartments:
///   Same flow but final CTA = "Book Now" instead of "Apply Now"

enum _CtaStep { initial, availabilityConfirmed }

class BottomBar extends StatefulWidget {
  final int price;
  final int deposit;
  final int maintenanceCharge;
  final int additionalCosts;
  final Map<String, dynamic> accommodation;
  final int selectedTenantCount;
  final List<Map<String, String>> tenantDetails;
  final String propertyType;

  const BottomBar({
    super.key,
    required this.price,
    required this.accommodation,
    required this.selectedTenantCount,
    required this.tenantDetails,
    this.deposit = 0,
    this.maintenanceCharge = 0,
    this.additionalCosts = 0,
    this.propertyType = '',
  });

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  _CtaStep _step = _CtaStep.initial;
  bool _showBreakdown = false;

  bool get _isApartment =>
      widget.propertyType.toLowerCase().contains('apartment') ||
      widget.propertyType.toLowerCase().contains('flat');

  bool get _hasSelection => widget.selectedTenantCount > 0;

  @override
  void didUpdateWidget(BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to initial step when selection changes
    if (oldWidget.selectedTenantCount != widget.selectedTenantCount) {
      setState(() => _step = _CtaStep.initial);
    }
  }

  void _handleCheckAvailability() {
    if (!_hasSelection) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BedSelectionSheet(
        propertyId: widget.accommodation['id'] ?? '',
        onSelected: (room, bed) {
          Navigator.pop(context);
          setState(() {
            _step = _CtaStep.availabilityConfirmed;
            // Store selection in accommodation map for flow continuity
            widget.accommodation['selectedRoomId'] = room.id;
            widget.accommodation['selectedBedId'] = bed.id;
            widget.accommodation['selectedRoomNumber'] = room.roomNumber;
            widget.accommodation['selectedBedNumber'] = bed.bedNumber;
          });
        },
      ),
    );
  }

  void _handleApply(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bookingSummary = BookingSummaryScreen(
      accommodation: widget.accommodation,
      tenantCount: widget.selectedTenantCount,
      tenantDetails: widget.tenantDetails,
      tenants: const [],
    );
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            isStudent: true,
            onLoginNavigateTo: bookingSummary,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => bookingSummary),
      );
    }
  }

  void _handleScheduleVisit(BuildContext context) {
    // Placeholder — can be connected to a calendar/visit booking screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule visit — coming soon')),
    );
  }

  void _handleContact(BuildContext context) {
    // Placeholder — can open chat or phone
    final phone = widget.accommodation['phone'] as String?;
    if (phone != null && phone.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact: $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDeposit = widget.deposit > 0
        ? widget.deposit
        : (() {
            final d = widget.accommodation['deposit'] ??
                widget.accommodation['initialDeposit'];
            if (d is int) return d;
            if (d is double) return d.toInt();
            if (d is String) return int.tryParse(d.replaceAll(',', '')) ?? 0;
            return widget.price > 0 ? widget.price + 1500 : 0;
          })();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Price breakdown panel (expandable) ──
            if (_showBreakdown)
              _PriceBreakdown(
                price: widget.price,
                deposit: effectiveDeposit,
                maintenanceCharge: widget.maintenanceCharge,
                additionalCosts: widget.additionalCosts,
              ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),

            // ── Secondary CTA row (Step 2 only) ──
            if (_step == _CtaStep.availabilityConfirmed)
              _SecondaryActions(
                onScheduleVisit: () => _handleScheduleVisit(context),
                onContact: () => _handleContact(context),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.15, end: 0),

            // ── Main row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Price + breakdown toggle
                  GestureDetector(
                    onTap: widget.price > 0
                        ? () => setState(() => _showBreakdown = !_showBreakdown)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              widget.price > 0 ? '₹${widget.price}' : '—',
                              style: const TextStyle(
                                fontSize: AppTheme.font2XL,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTheme.fontFamily,
                                color: AppTheme.textColor,
                              ),
                            ),
                            if (widget.price > 0) ...[
                              const SizedBox(width: 4),
                              const Text(
                                '/Month',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSM,
                                  fontFamily: AppTheme.fontFamily,
                                  color: AppTheme.textLightColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _showBreakdown
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                                color: AppTheme.textLightColor,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Initial Deposit: ₹$effectiveDeposit',
                          style: const TextStyle(
                            color: AppTheme.textLightColor,
                            fontSize: AppTheme.fontSM,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Primary CTA
                  Expanded(
                    child: _step == _CtaStep.initial
                        ? _CheckAvailabilityButton(
                            enabled: _hasSelection,
                            onTap: _handleCheckAvailability,
                          )
                        : _ApplyButton(
                            label: _isApartment ? 'Book Now' : 'Apply Now',
                            onTap: () => _handleApply(context),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.3, end: 0);
  }
}

// ── Check Availability button ──
class _CheckAvailabilityButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _CheckAvailabilityButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? const Color(0xFF1ABC5C) : null,
        disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.7),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            enabled ? 'Check Availability' : 'Select Room First',
            style: TextStyle(
              fontSize: AppTheme.fontMD,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
              color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Final Apply / Book Now button ──
class _ApplyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ApplyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTheme.fontMD,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.fontFamily,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Secondary actions row (Schedule Visit + Contact) ──
class _SecondaryActions extends StatelessWidget {
  final VoidCallback onScheduleVisit;
  final VoidCallback onContact;

  const _SecondaryActions({required this.onScheduleVisit, required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FB),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _OutlineAction(
              icon: Icons.calendar_today_outlined,
              label: 'Schedule Visit',
              onTap: onScheduleVisit,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _OutlineAction(
              icon: Icons.chat_bubble_outline,
              label: 'Contact',
              onTap: onContact,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price breakdown panel ──
class _PriceBreakdown extends StatelessWidget {
  final int price;
  final int deposit;
  final int maintenanceCharge;
  final int additionalCosts;

  const _PriceBreakdown({
    required this.price,
    required this.deposit,
    this.maintenanceCharge = 0,
    this.additionalCosts = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FB),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Breakdown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          _Row(label: 'Monthly Rent', value: '₹$price'),
          _Row(label: 'Initial Deposit (refundable)', value: '₹$deposit'),
          if (maintenanceCharge > 0)
            _Row(label: 'Maintenance Charges', value: '₹$maintenanceCharge', isSmall: true),
          if (additionalCosts > 0)
            _Row(label: 'Additional Costs', value: '₹$additionalCosts', isSmall: true),
          _Row(label: 'Included', value: 'See amenities', isHighlight: false, isSmall: true),
          const Divider(height: 16),
          _Row(label: 'Due at move-in', value: '₹${price + deposit}', isBold: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isHighlight;
  final bool isSmall;

  const _Row({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isHighlight = true,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 11 : 13,
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.textLightColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 11 : 13,
              fontFamily: AppTheme.fontFamily,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight ? AppTheme.textColor : AppTheme.textLightColor,
            ),
          ),
        ],
      ),
    );
  }
}
