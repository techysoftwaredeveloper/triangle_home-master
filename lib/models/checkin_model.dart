import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class CheckInModel {
  final String id;
  final String bookingId;
  final String propertyId;
  final String roomId;
  final String bedId;
  final String residentId;
  final String hostId;
  final CheckInMethod method;
  final CheckInStatus status;
  final String? otpCode;
  final DateTime? scheduledAt;
  final DateTime? verifiedAt;
  final DateTime expiresAt;
  final DateTime createdAt;

  CheckInModel({
    required this.id,
    required this.bookingId,
    required this.propertyId,
    required this.roomId,
    required this.bedId,
    required this.residentId,
    required this.hostId,
    required this.method,
    required this.status,
    this.otpCode,
    this.scheduledAt,
    this.verifiedAt,
    required this.expiresAt,
    required this.createdAt,
  });

  factory CheckInModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckInModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      roomId: data['roomId'] ?? '',
      bedId: data['bedId'] ?? '',
      residentId: data['residentId'] ?? '',
      hostId: data['hostId'] ?? '',
      method: CheckInMethod.values.firstWhere(
        (e) => e.name == (data['method'] ?? 'qr'),
        orElse: () => CheckInMethod.qr,
      ),
      status: CheckInStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => CheckInStatus.pending,
      ),
      otpCode: data['otpCode'],
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'propertyId': propertyId,
      'roomId': roomId,
      'bedId': bedId,
      'residentId': residentId,
      'hostId': hostId,
      'method': method.name,
      'status': status.name,
      'otpCode': otpCode,
      'scheduledAt':
          scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
