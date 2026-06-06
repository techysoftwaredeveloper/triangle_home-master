import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffRole {
  owner,
  primaryHost,
  assistantHost,
  propertyManager
}

enum StaffStatus {
  active,
  suspended,
  inactive,
  invited
}

enum InvitationStatus {
  pending,
  accepted,
  expired,
  cancelled
}

class HostAssignment {
  final String id;
  final String propertyId;
  final String userId;
  final StaffRole role;
  final StaffStatus status;
  final DateTime assignedAt;
  final List<String> permissions;
  final Map<String, dynamic>? metadata;

  HostAssignment({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.role,
    required this.status,
    required this.assignedAt,
    this.permissions = const [],
    this.metadata,
  });

  factory HostAssignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HostAssignment(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      userId: data['userId'] ?? '',
      role: StaffRole.values.firstWhere((e) => e.name == data['role'], orElse: () => StaffRole.assistantHost),
      status: StaffStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => StaffStatus.active),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      permissions: List<String>.from(data['permissions'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'userId': userId,
      'role': role.name,
      'status': status.name,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'permissions': permissions,
      'metadata': metadata,
    };
  }
}

class HostInvitation {
  final String id;
  final String propertyId;
  final String email;
  final String? phone;
  final StaffRole role;
  final InvitationStatus status;
  final DateTime sentAt;
  final DateTime expiresAt;
  final String invitedBy;

  HostInvitation({
    required this.id,
    required this.propertyId,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.sentAt,
    required this.expiresAt,
    required this.invitedBy,
  });

  factory HostInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HostInvitation(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: StaffRole.values.firstWhere((e) => e.name == data['role'], orElse: () => StaffRole.assistantHost),
      status: InvitationStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => InvitationStatus.pending),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      invitedBy: data['invitedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'email': email,
      'phone': phone,
      'role': role.name,
      'status': status.name,
      'sentAt': Timestamp.fromDate(sentAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'invitedBy': invitedBy,
    };
  }
}

class StaffActivity {
  final String id;
  final String hostId;
  final String propertyId;
  final String actionType;
  final String entityType;
  final String entityId;
  final String description;
  final DateTime timestamp;

  StaffActivity({
    required this.id,
    required this.hostId,
    required this.propertyId,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.description,
    required this.timestamp,
  });

  factory StaffActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StaffActivity(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      actionType: data['actionType'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'propertyId': propertyId,
      'actionType': actionType,
      'entityType': entityType,
      'entityId': entityId,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
