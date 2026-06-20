import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SavedPaymentsScreen extends StatefulWidget {
  const SavedPaymentsScreen({super.key});

  @override
  State<SavedPaymentsScreen> createState() => _SavedPaymentsScreenState();
}

class _SavedPaymentsScreenState extends State<SavedPaymentsScreen> {
  // Mock data for saved payment methods
  final List<Map<String, dynamic>> _savedCards = [
    {
      'id': 'card_1',
      'type': 'Visa',
      'last4': '4242',
      'expiry': '12/26',
      'cardHolder': 'John Bravo',
      'color': const Color(0xFF1E293B),
    },
    {
      'id': 'card_2',
      'type': 'Mastercard',
      'last4': '8890',
      'expiry': '08/25',
      'cardHolder': 'John Bravo',
      'color': const Color(0xFF4F46E5),
    },
  ];

  final List<Map<String, dynamic>> _upiIds = [
    {'id': 'upi_1', 'id_name': 'johnbravo@okaxis', 'bank': 'HDFC Bank'},
    {
      'id': 'upi_2',
      'id_name': '9876543210@paytm',
      'bank': 'Paytm Payments Bank',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Branded Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            automaticallyImplyLeading: false,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Saved Payments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage your cards and UPI IDs',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildHeaderBadge(Icons.shield_outlined, 'Secure'),
                        const SizedBox(width: 8),
                        _buildHeaderBadge(Icons.bolt, 'Fast Checkout'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Saved Cards Section ---
                  _buildSectionTitle('Credit & Debit Cards'),
                  const SizedBox(height: 16),
                  ..._savedCards.asMap().entries.map((entry) {
                    return _buildDismissibleCard(entry.value, entry.key);
                  }),
                  _buildAddButton(Icons.add_card_rounded, 'Add New Card'),

                  const SizedBox(height: 32),

                  // --- UPI Section ---
                  _buildSectionTitle('Saved UPI IDs'),
                  const SizedBox(height: 16),
                  ..._upiIds.asMap().entries.map((entry) {
                    return _buildUPIItem(entry.value, entry.key);
                  }),
                  _buildAddButton(
                    Icons.account_balance_wallet_outlined,
                    'Add New UPI ID',
                  ),

                  const SizedBox(height: 40),

                  // --- Security Note ---
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: AppTheme.textMutedColor,
                          size: 20,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your payment details are encrypted\nand stored securely by Triangle Homes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textMutedColor,
                            fontSize: 11,
                            fontFamily: 'Outfit',
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'Outfit',
        color: AppTheme.textDarkColor,
      ),
    );
  }

  Widget _buildDismissibleCard(Map<String, dynamic> card, int index) {
    return Dismissible(
      key: Key(card['id']),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      onDismissed: (direction) {
        setState(() => _savedCards.removeAt(index));
      },
      child: Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: card['color'],
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: card['color'].withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FaIcon(
                      card['type'] == 'Visa'
                          ? FontAwesomeIcons.ccVisa
                          : FontAwesomeIcons.ccMastercard,
                      color: Colors.white,
                      size: 32,
                    ),
                    const Icon(
                      Icons.contactless_outlined,
                      color: Colors.white60,
                      size: 24,
                    ),
                  ],
                ),
                Text(
                  '****  ****  ****  ${card['last4']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card['cardHolder'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPIRES',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card['expiry'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 100 * index))
          .slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildUPIItem(Map<String, dynamic> upi, int index) {
    return Dismissible(
      key: Key(upi['id']),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      onDismissed: (direction) {
        setState(() => _upiIds.removeAt(index));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(
                color: AppTheme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppTheme.successGreen,
                  size: 20,
                ),
              ),
              title: Text(
                upi['id_name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Outfit',
                ),
              ),
              subtitle: Text(
                upi['bank'],
                style: TextStyle(color: AppTheme.textLightColor, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.more_vert,
                color: AppTheme.textMutedColor,
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 300 + (50 * index)))
          .slideX(begin: 0.05, end: 0),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
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
              fontFamily: 'Outfit',
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.delete_outline_rounded,
            color: AppTheme.errorColor,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.accentColor,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
