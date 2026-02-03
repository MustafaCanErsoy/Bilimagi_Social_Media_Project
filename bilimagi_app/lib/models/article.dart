import 'package:cloud_firestore/cloud_firestore.dart';

/// Article status (v8.0)
enum ArticleStatus {
  draft,
  published,
  archived;

  String get label {
    switch (this) {
      case ArticleStatus.draft:
        return 'Taslak';
      case ArticleStatus.published:
        return 'Yayinda';
      case ArticleStatus.archived:
        return 'Arsivlendi';
    }
  }

  static ArticleStatus fromString(String? value) {
    switch (value) {
      case 'draft':
        return ArticleStatus.draft;
      case 'archived':
        return ArticleStatus.archived;
      case 'published':
      default:
        return ArticleStatus.published;
    }
  }
}

class Article {
  final String id;
  final String title;
  final String summary;
  final String link;
  int voteCount;

  // v8.0: New fields
  final String? heroImageURL;
  final String? content; // Markdown content
  final ArticleStatus status;
  final String? authorUid;
  final String? authorDisplayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  // v8.0 Period system: Set on phase change to discussion
  final bool isEligibleForDiscussion;

  // Suggestion tracking (v5.0)
  final String? suggestedByUid;
  final String? suggestionId;

  Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.link,
    this.voteCount = 0,
    // v8.0
    this.heroImageURL,
    this.content,
    this.status = ArticleStatus.published,
    this.authorUid,
    this.authorDisplayName,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.isEligibleForDiscussion = false,
    // v5.0
    this.suggestedByUid,
    this.suggestionId,
  });

  factory Article.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Article(
      id: doc.id,
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      link: data['link'] ?? '',
      voteCount: data['voteCount'] ?? 0,
      // v8.0
      heroImageURL: data['heroImageURL'],
      content: data['content'],
      status: ArticleStatus.fromString(data['status']),
      authorUid: data['authorUid'],
      authorDisplayName: data['authorDisplayName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      isEligibleForDiscussion: data['isEligibleForDiscussion'] ?? false,
      // v5.0
      suggestedByUid: data['suggestedByUid'],
      suggestionId: data['suggestionId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'summary': summary,
      'link': link,
      'voteCount': voteCount,
      // v8.0
      if (heroImageURL != null) 'heroImageURL': heroImageURL,
      if (content != null) 'content': content,
      'status': status.name,
      if (authorUid != null) 'authorUid': authorUid,
      if (authorDisplayName != null) 'authorDisplayName': authorDisplayName,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      'isEligibleForDiscussion': isEligibleForDiscussion,
      // v5.0
      if (suggestedByUid != null) 'suggestedByUid': suggestedByUid,
      if (suggestionId != null) 'suggestionId': suggestionId,
    };
  }

  Article copyWith({
    String? title,
    String? summary,
    String? link,
    int? voteCount,
    String? heroImageURL,
    String? content,
    ArticleStatus? status,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool? isEligibleForDiscussion,
  }) {
    return Article(
      id: id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      link: link ?? this.link,
      voteCount: voteCount ?? this.voteCount,
      heroImageURL: heroImageURL ?? this.heroImageURL,
      content: content ?? this.content,
      status: status ?? this.status,
      authorUid: authorUid,
      authorDisplayName: authorDisplayName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      isEligibleForDiscussion: isEligibleForDiscussion ?? this.isEligibleForDiscussion,
      suggestedByUid: suggestedByUid,
      suggestionId: suggestionId,
    );
  }
}
