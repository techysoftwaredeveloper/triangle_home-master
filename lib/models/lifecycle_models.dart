import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class RentCycle {
  final String id;
  final String stayId;
  final String residentId;
  final String propertyId;
  final String month;
  final double rentAmount;
  final DateTime dueDate;
  final RentStatus status;
  final DateTime? paidAt;
  final String? paymentTransactionId;
  final DateTime createdAt;

  RentCycle({
    required this.id,
    required this.stayId,
    required this.residentId,
    required this.propertyId,
    required this.month,
    required this.rentAmount,
    required this.dueDate,
    required this.status,
    this.paidAt,
    this.paymentTransactionId,
    required this.createdAt,
  });

  factory RentCycle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentCycle(
      id: doc.id,
      stayId: data['stayId'] ?? '',
      residentId: data['residentId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      month: data['month'] ?? '',
      rentAmount: (data['rentAmount'] ?? 0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: RentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RentStatus.pending,
      ),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      paymentTransactionId: data['paymentTransactionId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'stayId': stayId,
      'residentId': residentId,
      'propertyId': propertyId,
      'month': month,
      'rentAmount': rentAmount,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status.name,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paymentTransactionId': paymentTransactionId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class NoticeRequest {
  final String id;
  final String stayId;
  final DateTime noticeDate;
  final DateTime requestedMoveOutDate;
  final NoticeStatus status;
  final String? reviewedBy;
  final String? rejectionReason;
  final DateTime createdAt;

  NoticeRequest({
    required this.id,
    required this.stayId,
    required this.noticeDate,
    required this.requestedMoveOutDate,
    required this.status,
    this.reviewedBy,
    this.rejectionReason,
    required this.createdAt,
  });

  factory NoticeRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoticeRequest(
      id: doc.id,
      stayId: data['stayId'] ?? '',
      noticeDate: (data['noticeDate'] as Timestamp).toDate(),
      requestedMoveOutDate:
          (data['requestedMoveOutDate'] as Timestamp).toDate(),
      status: NoticeStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => NoticeStatus.pending,
      ),
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'stayId': stayId,
      'noticeDate': Timestamp.fromDate(noticeDate),
      'requestedMoveOutDate': Timestamp.fromDate(requestedMoveOutDate),
      'status': status.name,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class InspectionModel {
  final String id;
  final String stayId;
  final InspectionCondition condition;
  final String damageNotes;
  final List<String> photos;
  final bool keysReturned;
  final bool assetsVerified;
  final DateTime completedAt;
  final String completedBy;

  InspectionModel({
    required this.id,
    required this.stayId,
    required this.condition,
    required this.damageNotes,
    required this.photos,
    required this.keysReturned,
    required this.assetsVerified,
    required this.completedAt,
    required this.completedBy,
  });

  factory InspectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InspectionModel(
      id: doc.id,
      stayId: data['stayId'] ?? '',
      condition: InspectionCondition.values.firstWhere(
        (e) => e.name == data['condition'],
        orElse: () => InspectionCondition.good,
      ),
      damageNotes: data['damageNotes'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      keysReturned: data['keysReturned'] ?? false,
      assetsVerified: data['assetsVerified'] ?? false,
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      completedBy: data['completedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'stayId': stayId,
      'condition': condition.name,
      'damageNotes': damageNotes,
      'photos': photos,
      'keysReturned': keysReturned,
      'assetsVerified': assetsVerified,
      'completedAt': Timestamp.fromDate(completedAt),
      'completedBy': completedBy,
    };
  }
}

class DepositDeduction {
  final String type;
  final double amount;
  final String reason;

  DepositDeduction({
    required this.type,
    required this.amount,
    required this.reason,
  });

  factory DepositDeduction.fromMap(Map<String, dynamic> map) {
    return DepositDeduction(
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      reason: map['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'amount': amount,
    'reason': reason,
  };
}

class DepositRecord {
  final String id;
  final String stayId;
  final double originalDeposit;
  final List<DepositDeduction> deductions;
  final double refundAmount;
  final DepositStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;

  DepositRecord({
    required this.id,
    required this.stayId,
    required this.originalDeposit,
    required this.deductions,
    required this.refundAmount,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  factory DepositRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepositRecord(
      id: doc.id,
      stayId: data['stayId'] ?? '',
      originalDeposit: (data['originalDeposit'] ?? 0).toDouble(),
      deductions:
          (data['deductions'] as List? ?? [])
              .map((e) => DepositDeduction.fromMap(e as Map<String, dynamic>))
              .toList(),
      refundAmount: (data['refundAmount'] ?? 0).toDouble(),
      status: DepositStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DepositStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'stayId': stayId,
      'originalDeposit': originalDeposit,
      'deductions': deductions.map((e) => e.toMap()).toList(),
      'refundAmount': refundAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }
}
