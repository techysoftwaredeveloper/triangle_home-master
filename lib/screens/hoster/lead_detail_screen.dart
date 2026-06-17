import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:triangle_home/models/lead.dart';

class LeadDetailScreen extends StatefulWidget {
  final Lead lead;
  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.lead.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lead Details',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileCard(statusColor),
            const SizedBox(height: 24),
            if (widget.lead.type == ResidentType.student)
              _buildSection('Student Information', _buildStudentInfo())
            else
              _buildSection('Professional Information', _buildProfessionalInfo()),
            const SizedBox(height: 24),
            _buildSection('Accommodation Requirements', _buildRequirements()),
            const SizedBox(height: 24),
            _buildSection('Activity Timeline', _buildTimeline()),
            const SizedBox(height: 24),
            _buildSection('Host Notes', _buildNotes()),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(),
    );
  }

  Widget _buildProfileCard(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey[100],
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.lead.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            widget.lead.status.name.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: ${widget.lead.id.substring(0, 8)}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _infoRow('Lead Type', widget.lead.type.name.toUpperCase()),
          _infoRow('Phone', widget.lead.phone),
          _infoRow('Email', widget.lead.email),
          _infoRow('Source', widget.lead.source ?? 'Triangle Homes Search'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _iconBtn(Icons.call_rounded, 'Call')),
              const SizedBox(width: 12),
              Expanded(child: _iconBtn(Icons.chat_rounded, 'WhatsApp')),
              const SizedBox(width: 12),
              Expanded(child: _iconBtn(Icons.calendar_today_rounded, 'Visit')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: content,
        ),
      ],
    );
  }

  Widget _buildStudentInfo() {
    final info = widget.lead.studentInfo ?? {};
    return Column(
      children: [
        _infoRow('Institution', info['college'] ?? 'Rajagiri College'),
        _infoRow('Course', info['course'] ?? 'BCA'),
        _infoRow('Year', info['year'] ?? '2nd Year'),
        _infoRow('Guardian', info['guardian'] ?? 'Suresh Nair'),
      ],
    );
  }

  Widget _buildProfessionalInfo() {
    final info = widget.lead.professionalInfo ?? {};
    return Column(
      children: [
        _infoRow('Company', info['company'] ?? 'Infosys'),
        _infoRow('Designation', info['designation'] ?? 'Software Engineer'),
        _infoRow('Office', info['office'] ?? 'TP Kochi'),
      ],
    );
  }

  Widget _buildRequirements() {
    return Column(
      children: [
        _infoRow('Preferred Property', widget.lead.interestedPropertyName ?? 'Sunrise PG', isPrimary: true),
        _infoRow('Budget Range', widget.lead.budgetRange ?? '₹7,000 - ₹9,000'),
        _infoRow('Move-in Date', _formatDate(widget.lead.preferredMoveInDate)),
        _infoRow('Sharing Preference', widget.lead.preferredSharing ?? 'Double Sharing'),
        _infoRow('Gender Preference', widget.lead.preferredGender ?? 'Male Only'),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: widget.lead.activityTimeline.reversed.map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['event'] ?? 'Activity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format((event['timestamp'] as Timestamp).toDate()),
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.lead.lastNote ?? 'No notes added yet', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 16),
        _iconBtn(Icons.add_comment_rounded, 'Add New Note'),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Mark as Lost', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showConversionDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Convert to Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showConversionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConversionFlow(lead: widget.lead),
    );
  }

  Widget _infoRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isPrimary ? const Color(0xFF16A34A) : const Color(0xFF475569),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead: return const Color(0xFFF59E0B);
      case LeadStatus.contacted: return const Color(0xFF3B82F6);
      case LeadStatus.visitScheduled: return const Color(0xFF10B981);
      case LeadStatus.converted: return const Color(0xFF8B5CF6);
      default: return const Color(0xFF64748B);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }
}

class _ConversionFlow extends StatelessWidget {
  final Lead lead;
  const _ConversionFlow({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Convert to Booking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Triangle Homes operates on bed-level inventory. Please select an available bed.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 24),
          _step('Select Property', lead.interestedPropertyName ?? 'Sunrise PG', true),
          _step('Select Floor', '3rd Floor', false),
          _step('Select Room', 'Room D-203', false),
          _step('Select Available Bed', 'D3-B02 (Available)', false),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead converted to booking successfully!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Confirm Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _step(String label, String value, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(completed ? Icons.check_circle : Icons.radio_button_unchecked, color: completed ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}
