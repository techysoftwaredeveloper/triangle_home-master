import 'package:cloud_firestore/cloud_firestore.dart';

enum ResidentType { student, professional }

enum LeadStatus {
  newLead,
  contacted,
  visitScheduled,
  visited,
  interested,
  bookingRequested,
  bookingPending,
  converted,
  notInterested,
  lost,
  closed
}

enum LeadPriority { high, medium, low }

class Lead {
  final String id;
  final String hosterId;
  final String name;
  final String phone;
  final String email;
  final ResidentType type;
  final LeadStatus status;
  final double leadScore; // 0.0 to 100.0
  final LeadPriority priority;
  final String? interestedPropertyId;
  final String? interestedPropertyName;
  final String? preferredSharing;
  final String? preferredGender;
  final DateTime? preferredMoveInDate;
  final String? budgetRange;
  final String? source;
  final DateTime? lastContactDate;
  final String? lastContactMethod;
  final DateTime? nextFollowupDate;
  final int interestLevel; // 1-5 stars
  final Map<String, dynamic>? studentInfo;
  final Map<String, dynamic>? professionalInfo;
  final List<Map<String, dynamic>> activityTimeline;
  final String? lastNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lead({
    required this.id,
    required this.hosterId,
    required this.name,
    required this.phone,
    required this.email,
    required this.type,
    required this.status,
    this.leadScore = 50.0,
    this.priority = LeadPriority.medium,
    this.interestedPropertyId,
    this.interestedPropertyName,
    this.preferredSharing,
    this.preferredGender,
    this.preferredMoveInDate,
    this.budgetRange,
    this.source,
    this.lastContactDate,
    this.lastContactMethod,
    this.nextFollowupDate,
    this.interestLevel = 3,
    this.studentInfo,
    this.professionalInfo,
    this.activityTimeline = const [],
    this.lastNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lead.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lead(
      id: doc.id,
      hosterId: data['hosterId'] ?? '',
      name: data['name'] ?? 'Unknown',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      type: ResidentType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'student'),
        orElse: () => ResidentType.student,
      ),
      status: LeadStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'newLead'),
        orElse: () => LeadStatus.newLead,
      ),
      leadScore: (data['leadScore'] ?? 50.0).toDouble(),
      priority: LeadPriority.values.firstWhere(
        (e) => e.name == (data['priority'] ?? 'medium'),
        orElse: () => LeadPriority.medium,
      ),
      interestedPropertyId: data['interestedPropertyId'],
      interestedPropertyName: data['interestedPropertyName'],
      preferredSharing: data['preferredSharing'],
      preferredGender: data['preferredGender'],
      preferredMoveInDate: (data['preferredMoveInDate'] as Timestamp?)?.toDate(),
      budgetRange: data['budgetRange'],
      source: data['source'],
      lastContactDate: (data['lastContactDate'] as Timestamp?)?.toDate(),
      lastContactMethod: data['lastContactMethod'],
      nextFollowupDate: (data['nextFollowupDate'] as Timestamp?)?.toDate(),
      interestLevel: (data['interestLevel'] ?? 3).toInt(),
      studentInfo: data['studentInfo'],
      professionalInfo: data['professionalInfo'],
      activityTimeline: List<Map<String, dynamic>>.from(data['activityTimeline'] ?? []),
      lastNote: data['lastNote'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hosterId': hosterId,
      'name': name,
      'phone': phone,
      'email': email,
      'type': type.name,
      'status': status.name,
      'leadScore': leadScore,
      'priority': priority.name,
      'interestedPropertyId': interestedPropertyId,
      'interestedPropertyName': interestedPropertyName,
      'preferredSharing': preferredSharing,
      'preferredGender': preferredGender,
      'preferredMoveInDate': preferredMoveInDate != null ? Timestamp.fromDate(preferredMoveInDate!) : null,
      'budgetRange': budgetRange,
      'source': source,
      'lastContactDate': lastContactDate != null ? Timestamp.fromDate(lastContactDate!) : null,
      'lastContactMethod': lastContactMethod,
      'nextFollowupDate': nextFollowupDate != null ? Timestamp.fromDate(nextFollowupDate!) : null,
      'interestLevel': interestLevel,
      'studentInfo': studentInfo,
      'professionalInfo': professionalInfo,
      'activityTimeline': activityTimeline,
      'lastNote': lastNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
