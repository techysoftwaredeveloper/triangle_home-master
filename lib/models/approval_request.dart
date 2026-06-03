import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalType { hosterRequest, propertyListing, userVerification, other }

class ApprovalRequest {
  final String id;
  final ApprovalType type;
  final String title;
  final String requestedBy;
  final bool isUserVerified;
  final String? phone;
  final String? email;
  final String? location;
  final List<String> tags;
  final DateTime requestedAt;
  final String status;
  final String? image;
  final Map<String, dynamic> metadata;

  ApprovalRequest({
    required this.id,
    required this.type,
    required this.title,
    required this.requestedBy,
    this.isUserVerified = false,
    this.phone,
    this.email,
    this.location,
    this.tags = const [],
    required this.requestedAt,
    this.status = 'pending',
    this.image,
    this.metadata = const {},
  });

  factory ApprovalRequest.fromHosterRequest(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApprovalRequest(
      id: doc.id,
      type: ApprovalType.hosterRequest,
      title: data['businessName'] ?? data['name'] ?? 'Hoster Request',
      requestedBy: data['name'] ?? 'Unknown',
      isUserVerified: data['isPhoneVerified'] ?? false,
      phone: data['phoneNumber'] ?? data['phone'],
      email: data['email'],
      location:
          data['city'] != null
              ? "${data['city']}, ${data['state'] ?? ''}"
              : 'N/A',
      tags: ['Hoster', data['category'] ?? 'PG'],
      requestedAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      image: data['profileImage'],
      metadata: {'docsCount': '3/3'},
    );
  }

  factory ApprovalRequest.fromPropertyListing(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final basicInfo = data['basicInfo'] as Map? ?? {};
    return ApprovalRequest(
      id: doc.id,
      type: ApprovalType.propertyListing,
      title: basicInfo['collegeName'] ?? data['name'] ?? 'Property Listing',
      requestedBy: data['hosterName'] ?? 'Owner',
      isUserVerified: true,
      location:
          data['locality'] != null
              ? "${data['locality']}, ${data['city'] ?? ''}"
              : 'N/A',
      tags: [
        data['propertyType'] ?? 'PG',
        "${data['totalRooms'] ?? '0'} Rooms",
      ],
      requestedAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      image:
          (data['images'] as List?)?.isNotEmpty == true
              ? data['images'][0]
              : null,
      metadata: {'docsCount': '4/4'},
    );
  }
}
