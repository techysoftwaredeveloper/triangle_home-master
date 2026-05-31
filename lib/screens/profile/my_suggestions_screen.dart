import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/models/property_suggestion.dart';

class MySuggestionsScreen extends StatefulWidget {
  const MySuggestionsScreen({super.key});

  @override
  State<MySuggestionsScreen> createState() => _MySuggestionsScreenState();
}

class _MySuggestionsScreenState extends State<MySuggestionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Newest First';
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Suggestions',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      body: _uid == null
          ? const Center(child: Text('Please log in to see your suggestions'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('property_suggestions')
                  .where('suggester_id', isEqualTo: _uid)
                  .orderBy('createdAt', descending: _selectedFilter == 'Newest First')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final suggestions = docs.map((doc) => PropertySuggestion.fromFirestore(doc)).toList();

                // Client-side search filtering
                final filteredSuggestions = suggestions.where((s) {
                  final query = _searchController.text.toLowerCase();
                  return s.businessName.toLowerCase().contains(query) ||
                         s.businessAddress.toLowerCase().contains(query);
                }).toList();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Track the status of properties you\'ve suggested',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPromoCard(),
                      const SizedBox(height: 16),
                      _buildStatsRow(suggestions),
                      const SizedBox(height: 24),
                      _buildSearchAndFilter(),
                      const SizedBox(height: 16),
                      if (filteredSuggestions.isEmpty)
                        _buildEmptyState()
                      else
                        _buildSuggestionsList(filteredSuggestions),
                      const SizedBox(height: 24),
                      _buildSupportFooter(),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
              ? 'No suggestions found'
              : 'No matches for "${_searchController.text}"',
            style: GoogleFonts.outfit(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_outlined, color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thank you for helping us grow!',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your suggestions help students and professionals find better places to stay.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: -10,
            child: Icon(Icons.location_on, color: Colors.blue.withValues(alpha: 0.1), size: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<PropertySuggestion> suggestions) {
    int total = suggestions.length;
    int review = suggestions.where((s) => s.status == SuggestionStatus.underReview || s.status == SuggestionStatus.pending).length;
    int contacted = suggestions.where((s) => s.status == SuggestionStatus.contacted).length;
    int approved = suggestions.where((s) => s.status == SuggestionStatus.approved).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(total.toString(), 'Total\nSuggestions', const Color(0xFF22C55E)),
          _buildStatItem(review.toString(), 'Under\nReview', const Color(0xFF3B82F6)),
          _buildStatItem(contacted.toString(), 'Contacted', const Color(0xFFF59E0B)),
          _buildStatItem(approved.toString(), 'Approved', const Color(0xFF22C55E)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label.contains('Review') ? Icons.access_time :
            label.contains('Contacted') ? Icons.check_circle_outline :
            label.contains('Approved') ? Icons.done_all : Icons.list_alt,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B), height: 1.2),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() {}),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  hintText: 'Search suggestions',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (v) => setState(() => _selectedFilter = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Newest First', child: Text('Newest First')),
              const PopupMenuItem(value: 'Oldest First', child: Text('Oldest First')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedFilter,
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF0F172A)),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(List<PropertySuggestion> suggestions) {
    return Column(
      children: suggestions.map((s) => _buildSuggestionCard(s)).toList(),
    );
  }

  Widget _buildSuggestionCard(PropertySuggestion s) {
    Color statusColor;
    IconData statusIcon;
    String statusBadgeText;
    Color badgeBg;
    String? actionText;

    switch (s.status) {
      case SuggestionStatus.approved:
        statusColor = const Color(0xFF22C55E);
        statusIcon = Icons.check_circle;
        statusBadgeText = 'Approved';
        badgeBg = const Color(0xFFF0FDF4);
        actionText = 'View Property';
        break;
      case SuggestionStatus.contacted:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.phone_in_talk;
        statusBadgeText = 'Contacted';
        badgeBg = const Color(0xFFFFFBEB);
        actionText = 'View Details';
        break;
      case SuggestionStatus.underReview:
      case SuggestionStatus.pending:
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.access_time_filled;
        statusBadgeText = s.status == SuggestionStatus.pending ? 'Pending' : 'Under Review';
        badgeBg = const Color(0xFFEFF6FF);
        break;
      case SuggestionStatus.rejected:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        statusBadgeText = 'Rejected';
        badgeBg = const Color(0xFFFEF2F2);
        actionText = 'View Reason';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF1F5F9),
                    child: Icon(
                      s.category.toLowerCase().contains('hostel') ? Icons.school :
                      s.category.toLowerCase().contains('apartment') ? Icons.apartment : Icons.home_work,
                      color: const Color(0xFFCBD5E1)
                    ),
                  ),
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
                              s.businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, color: statusColor, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  statusBadgeText,
                                  style: GoogleFonts.outfit(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.businessAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMiniInfo(Icons.sell_outlined, s.category),
                          const SizedBox(width: 12),
                          _buildMiniInfo(Icons.calendar_today_outlined, DateFormat('dd MMM yyyy').format(s.createdAt)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor.withValues(alpha: 0.5), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.statusText ?? '',
                    style: GoogleFonts.outfit(fontSize: 11, color: statusColor),
                  ),
                ),
                if (actionText != null)
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: Text(
                      actionText,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildSupportFooter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have questions about your suggestion?',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'We\'re here to help.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              side: const BorderSide(color: Color(0xFF2563EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Contact Support',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
