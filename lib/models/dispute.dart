import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class DisputeModel {
  final String id;
  final String bookingId;
  final String userId;
  final String hosterId;
  final DisputeStatus status;
  final String category;
  final String description;
  final List<DisputeEvidence> evidence;
  final String? decision;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  DisputeModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.hosterId,
    required this.status,
    required this.category,
    required this.description,
    required this.evidence,
    this.decision,
    required this.createdAt,
    this.resolvedAt,
  });

  factory DisputeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DisputeModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      hosterId: data['hosterId'] ?? '',
      status: DisputeStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DisputeStatus.open,
      ),
      category: data['category'] ?? 'OTHER',
      description: data['description'] ?? '',
      evidence: (data['evidence'] as List? ?? [])
          .map((e) => DisputeEvidence.fromMap(e as Map<String, dynamic>))
          .toList(),
      decision: data['decision'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'hosterId': hosterId,
      'status': status.name,
      'category': category,
      'description': description,
      'evidence': evidence.map((e) => e.toMap()).toList(),
      'decision': decision,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}

class DisputeEvidence {
  final String uploadedBy;
  final String fileType;
  final String storagePath;
  final String url;
  final DateTime timestamp;

  DisputeEvidence({
    required this.uploadedBy,
    required this.fileType,
    required this.storagePath,
    required this.url,
    required this.timestamp,
  });

  factory DisputeEvidence.fromMap(Map<String, dynamic> data) {
    return DisputeEvidence(
      uploadedBy: data['uploadedBy'] ?? '',
      fileType: data['fileType'] ?? 'image',
      storagePath: data['storagePath'] ?? '',
      url: data['url'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uploadedBy': uploadedBy,
      'fileType': fileType,
      'storagePath': storagePath,
      'url': url,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
