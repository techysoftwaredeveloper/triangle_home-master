import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/models/lead.dart';

class LeadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Lead>> getHosterLeads(String hosterId) {
    return _firestore
        .collection('leads')
        .where('hosterId', isEqualTo: hosterId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Lead.fromFirestore(doc)).toList());
  }

  Stream<List<Lead>> getPropertyLeads(String propertyId) {
    return _firestore
        .collection('leads')
        .where('interestedPropertyId', isEqualTo: propertyId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Lead.fromFirestore(doc)).toList());
  }

  Future<void> updateLeadStatus(String leadId, LeadStatus newStatus) async {
    final activity = {
      'event': 'Status updated to ${newStatus.name}',
      'timestamp': Timestamp.now(),
      'type': 'status_change',
    };

    await _firestore.collection('leads').doc(leadId).update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'activityTimeline': FieldValue.arrayUnion([activity]),
    });
  }

  Future<void> addLeadNote(String leadId, String note) async {
    final activity = {
      'event': 'Note added: $note',
      'timestamp': Timestamp.now(),
      'type': 'note',
    };

    await _firestore.collection('leads').doc(leadId).update({
      'lastNote': note,
      'updatedAt': FieldValue.serverTimestamp(),
      'activityTimeline': FieldValue.arrayUnion([activity]),
    });
  }

  Future<void> scheduleVisit(String leadId, DateTime visitDate) async {
    final activity = {
      'event': 'Visit scheduled for ${visitDate.toString()}',
      'timestamp': Timestamp.now(),
      'type': 'visit_scheduled',
    };

    await _firestore.collection('leads').doc(leadId).update({
      'status': LeadStatus.visitScheduled.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'activityTimeline': FieldValue.arrayUnion([activity]),
    });
  }

  /// Get real-time lead analytics for a property
  Stream<Map<String, dynamic>> getPropertyLeadAnalytics(String propertyId) {
    return getPropertyLeads(propertyId).map((leads) {
      final total = leads.length;
      final newLeads = leads.where((l) => l.status == LeadStatus.newLead).length;
      final converted = leads.where((l) => l.status == LeadStatus.converted).length;
      final visits = leads.where((l) => l.status == LeadStatus.visitScheduled).length;
      final interested = leads.where((l) => l.status == LeadStatus.interested).length;
      final notConverted = leads.where((l) => l.status == LeadStatus.lost || l.status == LeadStatus.notInterested || l.status == LeadStatus.closed).length;

      return {
        'total': total,
        'new': newLeads,
        'converted': converted,
        'visits': visits,
        'interested': interested,
        'notConverted': notConverted,
        'conversionRate': total > 0 ? (converted / total * 100).round() : 0,
      };
    });
  }

  /// Log a structured activity for a lead
  Future<void> logLeadActivity({
    required String leadId,
    required String performedBy,
    required String activityType,
    String? notes,
  }) async {
    final activity = {
      'activityId': DateTime.now().millisecondsSinceEpoch.toString(),
      'leadId': leadId,
      'performedBy': performedBy,
      'timestamp': FieldValue.serverTimestamp(),
      'activityType': activityType,
      'notes': notes,
    };

    await _firestore.collection('leads').doc(leadId).update({
      'activityTimeline': FieldValue.arrayUnion([activity]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
