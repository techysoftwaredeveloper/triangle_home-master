import 'package:cloud_firestore/cloud_firestore.dart';

enum SuggestionStatus {
  pending,
  underReview,
  contacted,
  approved,
  rejected
}

class PropertySuggestion {
  final String id;
  final String? suggesterId;
  final String suggesterName;
  final String suggesterPhone;
  final String businessName;
  final String businessAddress;
  final String category;
  final SuggestionStatus status;
  final String? statusText;
  final DateTime createdAt;

  PropertySuggestion({
    required this.id,
    this.suggesterId,
    required this.suggesterName,
    required this.suggesterPhone,
    required this.businessName,
    required this.businessAddress,
    required this.category,
    required this.status,
    this.statusText,
    required this.createdAt,
  });

  factory PropertySuggestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Map Firestore string status to Enum
    SuggestionStatus mappedStatus;
    final statusStr = data['status']?.toString().toLowerCase() ?? 'pending';

    switch (statusStr) {
      case 'approved':
        mappedStatus = SuggestionStatus.approved;
        break;
      case 'rejected':
        mappedStatus = SuggestionStatus.rejected;
        break;
      case 'contacted':
        mappedStatus = SuggestionStatus.contacted;
        break;
      case 'underreview':
      case 'under_review':
        mappedStatus = SuggestionStatus.underReview;
        break;
      default:
        mappedStatus = SuggestionStatus.pending;
    }

    return PropertySuggestion(
      id: doc.id,
      suggesterId: data['suggester_id'],
      suggesterName: data['suggester_name'] ?? 'N/A',
      suggesterPhone: data['suggester_phone'] ?? 'N/A',
      businessName: data['business_name'] ?? 'Unknown Property',
      businessAddress: data['business_address'] ?? 'No Address Provided',
      category: data['category'] ?? 'Accommodation',
      status: mappedStatus,
      statusText: data['status_text'] ?? _getDefaultStatusText(mappedStatus),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static String _getDefaultStatusText(SuggestionStatus status) {
    switch (status) {
      case SuggestionStatus.approved:
        return 'This property has been verified and added to our platform.';
      case SuggestionStatus.contacted:
        return 'We have contacted the owner and are waiting for a response.';
      case SuggestionStatus.underReview:
        return 'Our team is reviewing your suggestion.';
      case SuggestionStatus.rejected:
        return 'This property did not meet our guidelines.';
      default:
        return 'Your suggestion has been received and is waiting for review.';
    }
  }
}
