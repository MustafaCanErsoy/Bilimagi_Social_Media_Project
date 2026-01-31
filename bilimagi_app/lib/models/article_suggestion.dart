import 'package:cloud_firestore/cloud_firestore.dart';

/// Suggestion status
enum SuggestionStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case SuggestionStatus.pending:
        return 'Beklemede';
      case SuggestionStatus.approved:
        return 'Onaylandı';
      case SuggestionStatus.rejected:
        return 'Reddedildi';
    }
  }

  static SuggestionStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return SuggestionStatus.approved;
      case 'rejected':
        return SuggestionStatus.rejected;
      default:
        return SuggestionStatus.pending;
    }
  }
}

class ArticleSuggestion {
  final String id;
  final String weekId;
  final String title;
  final String summary;
  final String link;
  final String submitterUid;
  final String submitterDisplayName;
  final DateTime createdAt;
  final SuggestionStatus status;
  final int interestScore;
  final String? reviewerUid;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  ArticleSuggestion({
    required this.id,
    required this.weekId,
    required this.title,
    required this.summary,
    required this.link,
    required this.submitterUid,
    required this.submitterDisplayName,
    required this.createdAt,
    this.status = SuggestionStatus.pending,
    this.interestScore = 0,
    this.reviewerUid,
    this.reviewedAt,
    this.rejectionReason,
  });

  bool get isPending => status == SuggestionStatus.pending;
  bool get isApproved => status == SuggestionStatus.approved;
  bool get isRejected => status == SuggestionStatus.rejected;

  factory ArticleSuggestion.fromFirestore(DocumentSnapshot doc, String weekId) {
    final data = doc.data() as Map<String, dynamic>;
    return ArticleSuggestion(
      id: doc.id,
      weekId: weekId,
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      link: data['link'] ?? '',
      submitterUid: data['submitterUid'] ?? '',
      submitterDisplayName: data['submitterDisplayName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: SuggestionStatus.fromString(data['status'] ?? 'pending'),
      interestScore: data['interestScore'] ?? 0,
      reviewerUid: data['reviewerUid'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'summary': summary,
      'link': link,
      'submitterUid': submitterUid,
      'submitterDisplayName': submitterDisplayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'interestScore': interestScore,
      if (reviewerUid != null) 'reviewerUid': reviewerUid,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  ArticleSuggestion copyWith({
    SuggestionStatus? status,
    int? interestScore,
    String? reviewerUid,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return ArticleSuggestion(
      id: id,
      weekId: weekId,
      title: title,
      summary: summary,
      link: link,
      submitterUid: submitterUid,
      submitterDisplayName: submitterDisplayName,
      createdAt: createdAt,
      status: status ?? this.status,
      interestScore: interestScore ?? this.interestScore,
      reviewerUid: reviewerUid ?? this.reviewerUid,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
