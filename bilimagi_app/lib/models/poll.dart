import 'package:cloud_firestore/cloud_firestore.dart';

/// Poll option
class PollOption {
  final String id;
  final String text;
  final int voteCount;

  const PollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      voteCount: map['voteCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'voteCount': voteCount,
    };
  }

  PollOption copyWith({int? voteCount}) {
    return PollOption(
      id: id,
      text: text,
      voteCount: voteCount ?? this.voteCount,
    );
  }
}

/// Poll status
enum PollStatus {
  active,
  closed;

  static PollStatus fromString(String? value) {
    switch (value) {
      case 'closed':
        return PollStatus.closed;
      case 'active':
      default:
        return PollStatus.active;
    }
  }
}

/// Community poll model (v8.0)
class Poll {
  final String id;
  final String communityId;
  final String question;
  final List<PollOption> options;
  final String authorUid;
  final String authorDisplayName;
  final DateTime createdAt;
  final DateTime? endsAt;
  final PollStatus status;
  final bool allowMultiple;
  final int totalVotes;

  const Poll({
    required this.id,
    required this.communityId,
    required this.question,
    required this.options,
    required this.authorUid,
    required this.authorDisplayName,
    required this.createdAt,
    this.endsAt,
    this.status = PollStatus.active,
    this.allowMultiple = false,
    this.totalVotes = 0,
  });

  /// Check if poll is expired (auto-close)
  bool get isExpired {
    if (endsAt == null) return false;
    return DateTime.now().isAfter(endsAt!);
  }

  /// Check if poll is active (can vote)
  bool get isActive => status == PollStatus.active && !isExpired;

  /// Get winning option(s)
  List<PollOption> get winningOptions {
    if (options.isEmpty) return [];
    final maxVotes = options.map((o) => o.voteCount).reduce((a, b) => a > b ? a : b);
    return options.where((o) => o.voteCount == maxVotes).toList();
  }

  factory Poll.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final optionsData = data['options'] as List<dynamic>? ?? [];

    return Poll(
      id: doc.id,
      communityId: data['communityId'] ?? '',
      question: data['question'] ?? '',
      options: optionsData.map((o) => PollOption.fromMap(o as Map<String, dynamic>)).toList(),
      authorUid: data['authorUid'] ?? '',
      authorDisplayName: data['authorDisplayName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate(),
      status: PollStatus.fromString(data['status']),
      allowMultiple: data['allowMultiple'] ?? false,
      totalVotes: data['totalVotes'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'communityId': communityId,
      'question': question,
      'options': options.map((o) => o.toMap()).toList(),
      'authorUid': authorUid,
      'authorDisplayName': authorDisplayName,
      'createdAt': Timestamp.fromDate(createdAt),
      if (endsAt != null) 'endsAt': Timestamp.fromDate(endsAt!),
      'status': status.name,
      'allowMultiple': allowMultiple,
      'totalVotes': totalVotes,
    };
  }

  Poll copyWith({
    List<PollOption>? options,
    PollStatus? status,
    int? totalVotes,
  }) {
    return Poll(
      id: id,
      communityId: communityId,
      question: question,
      options: options ?? this.options,
      authorUid: authorUid,
      authorDisplayName: authorDisplayName,
      createdAt: createdAt,
      endsAt: endsAt,
      status: status ?? this.status,
      allowMultiple: allowMultiple,
      totalVotes: totalVotes ?? this.totalVotes,
    );
  }
}

/// User's vote on a poll
class PollVote {
  final String odUid;
  final List<String> optionIds;
  final DateTime votedAt;

  const PollVote({
    required this.odUid,
    required this.optionIds,
    required this.votedAt,
  });

  factory PollVote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PollVote(
      odUid: doc.id,
      optionIds: List<String>.from(data['optionIds'] ?? []),
      votedAt: (data['votedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'optionIds': optionIds,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }
}
