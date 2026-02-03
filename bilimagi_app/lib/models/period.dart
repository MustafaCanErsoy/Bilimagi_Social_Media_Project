import 'package:cloud_firestore/cloud_firestore.dart';

/// Period phase enum (v8.0 - replaces WeekPhase)
enum PeriodPhase { voting, discussion, closed }

/// Period model (v10.0 - Top N articles system)
///
/// Represents a flexible discussion period within a community.
/// Unlike the old Week model, periods are not tied to calendar weeks
/// and support multiple articles for discussion.
///
/// v10.0: Changed from minVotesForDiscussion (threshold-based) to
/// topArticlesCount (top N articles become eligible for discussion).
class Period {
  final String id;
  final String communityId;
  final String title;
  final String? description;
  final PeriodPhase phase;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final int topArticlesCount; // v10.0: Top N articles for discussion (default: 3)
  final DateTime? phaseChangedAt;
  final String? phaseChangedByUid;

  Period({
    required this.id,
    required this.communityId,
    required this.title,
    this.description,
    required this.phase,
    this.startDate,
    this.endDate,
    required this.createdAt,
    this.topArticlesCount = 3, // v10.0: Default to top 3 articles
    this.phaseChangedAt,
    this.phaseChangedByUid,
  });

  factory Period.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Period(
      id: doc.id,
      communityId: data['communityId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      phase: _parsePhase(data['phase']),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // v10.0: Support both old (minVotesForDiscussion) and new (topArticlesCount) fields
      topArticlesCount: data['topArticlesCount'] ?? data['minVotesForDiscussion'] ?? 3,
      phaseChangedAt: (data['phaseChangedAt'] as Timestamp?)?.toDate(),
      phaseChangedByUid: data['phaseChangedByUid'],
    );
  }

  static PeriodPhase _parsePhase(String? phase) {
    switch (phase) {
      case 'voting':
        return PeriodPhase.voting;
      case 'discussion':
        return PeriodPhase.discussion;
      case 'closed':
        return PeriodPhase.closed;
      default:
        return PeriodPhase.voting;
    }
  }

  static String phaseToString(PeriodPhase phase) {
    switch (phase) {
      case PeriodPhase.voting:
        return 'voting';
      case PeriodPhase.discussion:
        return 'discussion';
      case PeriodPhase.closed:
        return 'closed';
    }
  }

  String get phaseDisplayName {
    switch (phase) {
      case PeriodPhase.voting:
        return 'Oylama';
      case PeriodPhase.discussion:
        return 'Tartisma';
      case PeriodPhase.closed:
        return 'Kapali';
    }
  }

  String get phaseEmoji {
    switch (phase) {
      case PeriodPhase.voting:
        return '🗳️';
      case PeriodPhase.discussion:
        return '💬';
      case PeriodPhase.closed:
        return '🔒';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'communityId': communityId,
      'title': title,
      if (description != null) 'description': description,
      'phase': phaseToString(phase),
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'createdAt': Timestamp.fromDate(createdAt),
      'topArticlesCount': topArticlesCount, // v10.0: Top N articles
      if (phaseChangedAt != null) 'phaseChangedAt': Timestamp.fromDate(phaseChangedAt!),
      if (phaseChangedByUid != null) 'phaseChangedByUid': phaseChangedByUid,
    };
  }

  Period copyWith({
    String? title,
    String? description,
    PeriodPhase? phase,
    DateTime? startDate,
    DateTime? endDate,
    int? topArticlesCount,
    DateTime? phaseChangedAt,
    String? phaseChangedByUid,
  }) {
    return Period(
      id: id,
      communityId: communityId,
      title: title ?? this.title,
      description: description ?? this.description,
      phase: phase ?? this.phase,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
      topArticlesCount: topArticlesCount ?? this.topArticlesCount,
      phaseChangedAt: phaseChangedAt ?? this.phaseChangedAt,
      phaseChangedByUid: phaseChangedByUid ?? this.phaseChangedByUid,
    );
  }

  /// Check if the period has date constraints
  bool get hasDateRange => startDate != null || endDate != null;

  /// Get formatted date range string
  String? get dateRangeDisplay {
    if (startDate == null && endDate == null) return null;

    final start = startDate != null
        ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
        : '...';
    final end = endDate != null
        ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
        : '...';

    return '$start - $end';
  }
}
