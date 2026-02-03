import 'package:cloud_firestore/cloud_firestore.dart';

/// Community announcement model (v8.0)
class Announcement {
  final String id;
  final String communityId;
  final String title;
  final String content;
  final String authorUid;
  final String authorDisplayName;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isPinned;

  const Announcement({
    required this.id,
    required this.communityId,
    required this.title,
    required this.content,
    required this.authorUid,
    required this.authorDisplayName,
    required this.createdAt,
    this.expiresAt,
    this.isPinned = false,
  });

  /// Check if announcement is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if announcement is active (not expired)
  bool get isActive => !isExpired;

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      communityId: data['communityId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorUid: data['authorUid'] ?? '',
      authorDisplayName: data['authorDisplayName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'communityId': communityId,
      'title': title,
      'content': content,
      'authorUid': authorUid,
      'authorDisplayName': authorDisplayName,
      'createdAt': Timestamp.fromDate(createdAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'isPinned': isPinned,
    };
  }

  Announcement copyWith({
    String? title,
    String? content,
    DateTime? expiresAt,
    bool? isPinned,
  }) {
    return Announcement(
      id: id,
      communityId: communityId,
      title: title ?? this.title,
      content: content ?? this.content,
      authorUid: authorUid,
      authorDisplayName: authorDisplayName,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
