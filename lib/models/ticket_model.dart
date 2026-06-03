import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class TicketModel {
  final String id;
  final String residentId;
  final String stayId;
  final String propertyId;
  final String roomId;
  final String bedId;
  final String hostId;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final String title;
  final String description;
  final List<TicketAttachment> attachments;
  final String? assignedTo;
  final DateTime slaDueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final String? resolutionNote;
  final bool isEscalated;
  final bool isSlaBreached;
  final int reopenCount;

  TicketModel({
    required this.id,
    required this.residentId,
    required this.stayId,
    required this.propertyId,
    required this.roomId,
    required this.bedId,
    required this.hostId,
    required this.category,
    required this.priority,
    required this.status,
    required this.title,
    required this.description,
    required this.attachments,
    this.assignedTo,
    required this.slaDueAt,
    required this.createdAt,
    required this.updatedAt,
    this.assignedAt,
    this.resolvedAt,
    this.closedAt,
    this.resolutionNote,
    this.isEscalated = false,
    this.isSlaBreached = false,
    this.reopenCount = 0,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TicketModel(
      id: doc.id,
      residentId: data['residentId'] ?? '',
      stayId: data['stayId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      roomId: data['roomId'] ?? '',
      bedId: data['bedId'] ?? '',
      hostId: data['hostId'] ?? '',
      category: TicketCategory.values.firstWhere(
        (e) => e.name == (data['category'] ?? 'other'),
        orElse: () => TicketCategory.other,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.name == (data['priority'] ?? 'medium'),
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'open'),
        orElse: () => TicketStatus.open,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      attachments:
          (data['attachments'] as List? ?? [])
              .map((e) => TicketAttachment.fromMap(e as Map<String, dynamic>))
              .toList(),
      assignedTo: data['assignedTo'],
      slaDueAt: (data['slaDueAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      resolutionNote: data['resolutionNote'],
      isEscalated: data['isEscalated'] ?? false,
      isSlaBreached: data['isSlaBreached'] ?? false,
      reopenCount: data['reopenCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'residentId': residentId,
      'stayId': stayId,
      'propertyId': propertyId,
      'roomId': roomId,
      'bedId': bedId,
      'hostId': hostId,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'title': title,
      'description': description,
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'assignedTo': assignedTo,
      'slaDueAt': Timestamp.fromDate(slaDueAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'resolutionNote': resolutionNote,
      'isEscalated': isEscalated,
      'isSlaBreached': isSlaBreached,
      'reopenCount': reopenCount,
    };
  }
}

class TicketAttachment {
  final String url;
  final AttachmentType type;
  final DateTime uploadedAt;

  TicketAttachment({
    required this.url,
    required this.type,
    required this.uploadedAt,
  });

  factory TicketAttachment.fromMap(Map<String, dynamic> data) {
    return TicketAttachment(
      url: data['url'] ?? '',
      type: AttachmentType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'image'),
        orElse: () => AttachmentType.image,
      ),
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type.name,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

class TicketEvent {
  final String action;
  final String performedBy;
  final DateTime timestamp;
  final String? note;

  TicketEvent({
    required this.action,
    required this.performedBy,
    required this.timestamp,
    this.note,
  });

  factory TicketEvent.fromMap(Map<String, dynamic> data) {
    return TicketEvent(
      action: data['action'] ?? '',
      performedBy: data['performedBy'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'performedBy': performedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }
}
