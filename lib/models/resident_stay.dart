import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class ResidentStayModel {
  final String id;
  final String residentId;
  final String bookingId;
  final String propertyId;
  final String roomId;
  final String bedId;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final StayStatus status;
  final DateTime createdAt;

  ResidentStayModel({
    required this.id,
    required this.residentId,
    required this.bookingId,
    required this.propertyId,
    required this.roomId,
    required this.bedId,
    required this.checkInDate,
    this.checkOutDate,
    required this.status,
    required this.createdAt,
  });

  factory ResidentStayModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResidentStayModel(
      id: doc.id,
      residentId: data['residentId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      roomId: data['roomId'] ?? '',
      bedId: data['bedId'] ?? '',
      checkInDate: (data['checkInDate'] as Timestamp).toDate(),
      checkOutDate: (data['checkOutDate'] as Timestamp?)?.toDate(),
      status: StayStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'active'),
        orElse: () => StayStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'residentId': residentId,
      'bookingId': bookingId,
      'propertyId': propertyId,
      'roomId': roomId,
      'bedId': bedId,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate':
          checkOutDate != null ? Timestamp.fromDate(checkOutDate!) : null,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
