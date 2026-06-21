import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';

class SettingsTab extends StatefulWidget {
  final AdminService adminService;
  final bool isNarrow;

  const SettingsTab({
    super.key,
    required this.adminService,
    required this.isNarrow,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  int _activeSettingsIndex = 0;

  final List<Map<String, dynamic>> _settingsNavItems = [
    {
      'icon': Icons.settings_outlined,
      'label': 'General',
      'sub': 'Platform information & preferences',
    },
    {
      'icon': Icons.people_outline_rounded,
      'label': 'User Management',
      'sub': 'Roles, permissions & access',
    },
    {
      'icon': Icons.business_outlined,
      'label': 'Listing & Booking',
      'sub': 'Rules and configurations',
    },
    {
      'icon': Icons.payments_outlined,
      'label': 'Payment & Payouts',
      'sub': 'Commission, fees & payouts',
    },
    {
      'icon': Icons.verified_user_outlined,
      'label': 'Verification',
      'sub': 'KYC, documents & verification',
    },
    {
      'icon': Icons.notifications_none_rounded,
      'label': 'Notifications',
      'sub': 'Email, SMS & in-app alerts',
    },
    {
      'icon': Icons.security_outlined,
      'label': 'Security',
      'sub': 'Security settings & policies',
    },
    {
      'icon': Icons.palette_outlined,
      'label': 'Appearance',
      'sub': 'Branding & customization',
    },
    {
      'icon': Icons.integration_instructions_outlined,
      'label': 'Integrations',
      'sub': 'Third-party services',
    },
    {
      'icon': Icons.dns_outlined,
      'label': 'System',
      'sub': 'System info & maintenance',
    },
    {
      'icon': Icons.history_edu_rounded,
      'label': 'Audit Logs',
      'sub': 'Activity & changes history',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.isNarrow) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TabHeader(
              title: 'Settings',
              subtitle: 'Manage platform configuration and preferences',
              isNarrow: true,
            ),
            const SizedBox(height: 24),
            if (_activeSettingsIndex == 0)
              _buildGeneralSettings()
            else
              ..._settingsNavItems.map((item) => _buildMobileNavCard(item)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
          child: TabHeader(
            title: 'Settings',
            subtitle: 'Manage platform configuration and preferences',
            isNarrow: false,
            actions: [
              _buildHeaderAction(
                'Export',
                Icons.file_download_outlined,
                isOutline: true,
              ),
              const SizedBox(width: 12),
              _buildHeaderAction(
                'Filters',
                Icons.tune_rounded,
                hasDropdown: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Internal Sidebar
              Container(
                width: 280,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _settingsNavItems.length,
                  itemBuilder: (context, index) {
                    final item = _settingsNavItems[index];
                    final bool isActive = _activeSettingsIndex == index;
                    return _buildSettingsNavItem(index, item, isActive);
                  },
                ),
              ),

              // Main Settings Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activeSettingsIndex == 0)
                        _buildGeneralSettings()
                      else
                        Center(
                          child: Text(
                            "Settings for \${_settingsNavItems[_activeSettingsIndex]['label']} coming soon",
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderAction(
    String label,
    IconData icon, {
    bool isOutline = false,
    bool hasDropdown = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOutline ? Colors.white : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(10),
        border: isOutline ? Border.all(color: const Color(0xFFE2E8F0)) : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isOutline ? const Color(0xFF64748B) : Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            widget.isNarrow && label == 'Add New User' ? 'Add' : label,
            style: TextStyle(
              color: isOutline ? const Color(0xFF1E293B) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: isOutline ? const Color(0xFF64748B) : Colors.white,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsNavItem(
    int index,
    Map<String, dynamic> item,
    bool isActive,
  ) {
    return InkWell(
      onTap: () => setState(() => _activeSettingsIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF1F5F9) : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              item['icon'],
              size: 20,
              color:
                  isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['label'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          isActive
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF475569),
                    ),
                  ),
                  Text(
                    item['sub'],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(item['icon'], color: const Color(0xFF2563EB), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item['label'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Platform Information', 'Edit Information'),
        const SizedBox(height: 24),
        _buildPlatformInfoCard(),
        const SizedBox(height: 48),
        _buildSectionHeader('Stay Policy', 'Edit Policy'),
        const SizedBox(height: 24),
        _buildStayPolicyGrid(),
        const SizedBox(height: 48),
        _buildSectionHeader('Payment & Revenue Settings', 'Edit Settings'),
        const SizedBox(height: 24),
        _buildPaymentRevenueCard(),
        const SizedBox(height: 48),
        _buildSectionHeader('Notification Preferences', 'Edit Preferences'),
        const SizedBox(height: 24),
        _buildNotificationPreferencesCard(),
        const SizedBox(height: 48),
        if (!widget.isNarrow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSecuritySettingsCard(),
                    const SizedBox(height: 24),
                    _buildMigrationCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildSystemStatusCard()),
            ],
          )
        else
          Column(
            children: [
              _buildSecuritySettingsCard(),
              const SizedBox(height: 16),
              _buildSystemStatusCard(),
              const SizedBox(height: 16),
              _buildMigrationCard(),
            ],
          ),
      ],
    );
  }

  Widget _buildMigrationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_fix_high_rounded, size: 18, color: Color(0xFFD97706)),
              SizedBox(width: 12),
              Text(
                'Data Migration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Migrate existing properties to the new 2-month security deposit standard. This will update properties without specified deposits.',
            style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting security deposit migration...')));
              try {
                await widget.adminService.migratePropertySecurityDeposits();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Migration completed successfully!'), backgroundColor: Colors.green));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Migration failed: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white, elevation: 0),
            child: const Text('Run Security Deposit Migration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildSmallBtn(widget.isNarrow ? '' : action, Icons.edit_outlined),
      ],
    );
  }

  Widget _buildSmallBtn(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: label.isEmpty ? 8 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2563EB)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformInfoCard() {
    return Container(
      padding: EdgeInsets.all(widget.isNarrow ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child:
          widget.isNarrow
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogoBox(),
                  const SizedBox(height: 24),
                  _buildInfoGrid(1),
                ],
              )
              : Row(
                children: [
                  _buildLogoBox(),
                  const SizedBox(width: 48),
                  Expanded(child: _buildInfoGrid(2)),
                ],
              ),
    );
  }

  Widget _buildLogoBox() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.change_history_rounded,
            color: Color(0xFF8B5CF6),
            size: 40,
          ),
          const SizedBox(height: 8),
          const Text(
            'Triangle Homes',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(int columns) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      childAspectRatio: columns == 1 ? 6 : 4,
      children: [
        _infoItem('Platform Name', 'Triangle Homes'),
        _infoItem('Support Email', 'support@trianglehomes.com'),
        _infoItem('Support Phone', '+91 70254 77997'),
        _infoItem('Timezone', '(GMT +05:30) Asia/Kolkata'),
        _infoItem('Currency', 'INR (₹)'),
        _infoItem('Date Format', '18 May 2025'),
        _infoItem('Time Format', '10:30 AM'),
      ],
    );
  }

  Widget _infoItem(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildStayPolicyGrid() {
    if (widget.isNarrow) {
      return Column(
        children: [
          _buildPolicyCard(
            'Students',
            '1 Month',
            'Students can book properties for a minimum duration of 1 month.',
            '15 Days',
            const Color(0xFFEFF6FF),
            const Color(0xFF2563EB),
            Icons.school_outlined,
          ),
          const SizedBox(height: 16),
          _buildPolicyCard(
            'Professionals',
            '3 Days',
            'Professionals can book properties for a minimum duration of 3 days.',
            '3 Days',
            const Color(0xFFF0FDF4),
            const Color(0xFF16A34A),
            Icons.work_outline_rounded,
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: _buildPolicyCard(
            'Students',
            '1 Month',
            'Students can book properties for a minimum duration of 1 month.',
            '15 Days',
            const Color(0xFFEFF6FF),
            const Color(0xFF2563EB),
            Icons.school_outlined,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildPolicyCard(
            'Professionals',
            '3 Days',
            'Professionals can book properties for a minimum duration of 3 days.',
            '3 Days',
            const Color(0xFFF0FDF4),
            const Color(0xFF16A34A),
            Icons.work_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyCard(
    String title,
    String minStay,
    String desc,
    String notice,
    Color bg,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Minimum Stay',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  minStay,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notice Period',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              Text(
                notice,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _settingsRow(
            'Payment Collection',
            'Paid to Triangle Homes (Platform collects payment)',
            true,
            valueColor: const Color(0xFF2563EB),
          ),
          _settingsRow(
            'Payout Mode',
            'Direct to Hoster (Bank Transfer / UPI)',
            true,
            valueColor: const Color(0xFF16A34A),
          ),
          _settingsRow('Platform Commission', '10% of Booking Amount', false),
          _settingsRow('GST on Commission', '18%', false),
          _settingsRow('Host Payout Schedule', 'Every 2 Days', true),
        ],
      ),
    );
  }

  Widget _settingsRow(
    String label,
    String value,
    bool hasChevron, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: widget.isNarrow ? 1 : 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (label == 'Payment Collection' && !widget.isNarrow)
                  const Text(
                    'Choose how payments are collected on the platform',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: widget.isNarrow ? 1 : 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? const Color(0xFF475569),
                    ),
                    maxLines: widget.isNarrow ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasChevron) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesCard() {
    return Container(
      padding: EdgeInsets.all(widget.isNarrow ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _prefRow(
            Icons.mail_outline_rounded,
            'Email Notifications',
            widget.isNarrow ? 'Email updates' : 'Receive updates via email',
            'Bookings, Payments...',
            true,
          ),
          _prefRow(
            Icons.sms_outlined,
            'SMS Notifications',
            widget.isNarrow
                ? 'SMS updates'
                : 'Receive important updates via SMS',
            'Bookings, Payments...',
            true,
          ),
          _prefRow(
            Icons.notifications_active_outlined,
            'In-App Notifications',
            widget.isNarrow
                ? 'App alerts'
                : 'Receive notifications in the platform',
            'All Notifications',
            true,
          ),
          _prefRow(
            Icons.campaign_outlined,
            'Marketing',
            'Receive tips and updates',
            'Email Only',
            false,
          ),
        ],
      ),
    );
  }

  Widget _prefRow(
    IconData icon,
    String title,
    String sub,
    String desc,
    bool val,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!widget.isNarrow)
            Expanded(
              flex: 2,
              child: Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Switch(
            value: val,
            onChanged: (v) {},
            activeThumbColor: const Color(0xFF2563EB),
            activeTrackColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.security_outlined, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 12),
              Text(
                'Security Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _securityItem(
            'Two-Factor Authentication (2FA)',
            'Enabled',
            true,
            valueColor: const Color(0xFF16A34A),
          ),
          _securityItem(
            'Session Timeout',
            '30 Minutes',
            true,
            valueColor: const Color(0xFF2563EB),
          ),
          _securityItem(
            'Password Policy',
            'Enabled',
            true,
            valueColor: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Manage Security Settings →',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityItem(String l, String v, bool c, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              l,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (valueColor ?? Colors.blue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              v,
              style: TextStyle(
                color: valueColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (c) ...[
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.monitor_heart_outlined,
                size: 18,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 12),
              Text(
                'System Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _statusItem('Current Version', 'v2.4.1'),
          _statusItem('Last Updated', '18 May 2025, 11:30 AM'),
          _statusItem(
            'System Status',
            'All Systems Operational',
            isHealth: true,
          ),
          _statusItem('Server Uptime', '99.98% (Last 30 Days)'),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'View System Status →',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusItem(String l, String v, {bool isHealth = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Row(
            children: [
              if (isHealth) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                v,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      isHealth
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
