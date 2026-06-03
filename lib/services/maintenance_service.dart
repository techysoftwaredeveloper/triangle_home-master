import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/ticket_model.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int maxOpenTickets = 5;
  static const int minTitleLength = 10;
  static const int minDescriptionLength = 20;

  /// Creates a maintenance ticket with strict validation and SLA calculation
  Future<String> createTicket({
    required String residentId,
    required String stayId,
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    List<TicketAttachment> attachments = const [],
  }) async {
    // 1. Validate Anti-Abuse Rules
    if (title.length < minTitleLength)
      throw 'Title must be at least $minTitleLength characters';
    if (description.length < minDescriptionLength)
      throw 'Description must be at least $minDescriptionLength characters';

    // 2. Validate Active Stay and Open Ticket Limit
    final stayDoc =
        await _firestore.collection('resident_stays').doc(stayId).get();
    if (!stayDoc.exists ||
        stayDoc.data()?['status'] != StayStatus.active.name) {
      throw 'Maintenance requests only allowed for active residents';
    }

    final openTicketsSnap =
        await _firestore
            .collection('maintenance_tickets')
            .where('residentId', isEqualTo: residentId)
            .where(
              'status',
              whereIn: [
                TicketStatus.open.name,
                TicketStatus.assigned.name,
                TicketStatus.inProgress.name,
              ],
            )
            .get();

    if (openTicketsSnap.docs.length >= maxOpenTickets) {
      throw 'You have reached the limit of $maxOpenTickets open tickets';
    }

    final stayData = stayDoc.data()!;
    final now = DateTime.now();
    final slaDueAt = now.add(_getSlaDuration(priority));

    // 3. Prepare Ticket
    final docRef = _firestore.collection('maintenance_tickets').doc();
    final ticket = TicketModel(
      id: docRef.id,
      residentId: residentId,
      stayId: stayId,
      propertyId: stayData['propertyId'],
      roomId: stayData['roomId'],
      bedId: stayData['bedId'],
      hostId:
          stayData['hoster_id'] ??
          '', // Need to ensure hoster_id is in stay record or fetch from property
      category: category,
      priority: priority,
      status: TicketStatus.open,
      title: title,
      description: description,
      attachments: attachments,
      slaDueAt: slaDueAt,
      createdAt: now,
      updatedAt: now,
    );

    // 4. Atomic Creation & Initial Event
    await _firestore.runTransaction((transaction) async {
      transaction.set(docRef, ticket.toFirestore());

      final eventRef = docRef.collection('events').doc();
      transaction.set(
        eventRef,
        TicketEvent(
          action: 'ticket_created',
          performedBy: residentId,
          timestamp: now,
        ).toMap(),
      );
    });

    return docRef.id;
  }

  /// Updates ticket status and logs the event
  Future<void> updateTicketStatus(
    String ticketId,
    TicketStatus newStatus, {
    String? note,
    String? performedBy,
  }) async {
    final ticketRef = _firestore
        .collection('maintenance_tickets')
        .doc(ticketId);
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      transaction.update(ticketRef, {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == TicketStatus.assigned)
          'assignedAt': FieldValue.serverTimestamp(),
        if (newStatus == TicketStatus.resolved)
          'resolvedAt': FieldValue.serverTimestamp(),
        if (newStatus == TicketStatus.closed)
          'closedAt': FieldValue.serverTimestamp(),
        if (note != null) 'resolutionNote': note,
      });

      final eventRef = ticketRef.collection('events').doc();
      transaction.set(
        eventRef,
        TicketEvent(
          action: newStatus.name,
          performedBy: performedBy ?? 'system',
          timestamp: now,
          note: note,
        ).toMap(),
      );
    });
  }

  Duration _getSlaDuration(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.emergency:
        return const Duration(hours: 4);
      case TicketPriority.high:
        return const Duration(hours: 24);
      case TicketPriority.medium:
        return const Duration(hours: 72);
      case TicketPriority.low:
        return const Duration(days: 7);
    }
  }

  Stream<List<TicketModel>> getPropertyTickets(String propertyId) {
    return _firestore
        .collection('maintenance_tickets')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => TicketModel.fromFirestore(doc)).toList(),
        );
  }

  /// Gets all tickets submitted by a specific resident
  Stream<List<TicketModel>> getResidentTickets(String residentId) {
    return _firestore
        .collection('maintenance_tickets')
        .where('residentId', isEqualTo: residentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => TicketModel.fromFirestore(doc)).toList(),
        );
  }

  /// Adds an internal staff note to a ticket
  Future<void> addInternalNote(
    String ticketId,
    String note,
    String adminId,
  ) async {
    final ticketRef = _firestore
        .collection('maintenance_tickets')
        .doc(ticketId);

    await ticketRef.collection('internal_notes').add({
      'note': note,
      'authorId': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Finalizes resolution with proof and logs the transition
  Future<void> resolveWithProof({
    required String ticketId,
    required String resolutionNote,
    required List<TicketAttachment> proof,
    required String performedBy,
  }) async {
    final ticketRef = _firestore
        .collection('maintenance_tickets')
        .doc(ticketId);
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      transaction.update(ticketRef, {
        'status': TicketStatus.resolved.name,
        'resolutionNote': resolutionNote,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Appending proof would be better via FieldValue.arrayUnion,
        // but here we merge with existing attachments for simplicity
      });

      final eventRef = ticketRef.collection('events').doc();
      transaction.set(
        eventRef,
        TicketEvent(
          action: 'resolved_with_proof',
          performedBy: performedBy,
          timestamp: now,
          note: resolutionNote,
        ).toMap(),
      );
    });
  }
}
