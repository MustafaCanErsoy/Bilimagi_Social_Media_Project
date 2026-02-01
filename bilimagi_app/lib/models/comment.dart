import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a comment on an article
class Comment {
  final String id;
  final String uid;
  final String displayName;
  final String text;
  final DateTime createdAt;

  // v2.0: Nested comments fields
  final String? parentId; // null = top-level comment
  final int depth; // 0 = top-level, 1+ = nested
  final int replyCount; // number of direct replies

  // v2.0: Voting fields
  final int upvoteCount;
  final int downvoteCount;
  final int score; // upvoteCount - downvoteCount

  // v4.0: Edit fields
  final bool isEdited;
  final DateTime? editedAt;

  // v4.0: Delete field (soft delete)
  final bool isDeleted;

  // v6.0: Moderation fields
  final bool isHidden;
  final String? hiddenByUid;
  final DateTime? hiddenAt;
  final String? hiddenReason;

  Comment({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.depth = 0,
    this.replyCount = 0,
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.score = 0,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.isHidden = false,
    this.hiddenByUid,
    this.hiddenAt,
    this.hiddenReason,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? 'Anonim',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentId: data['parentId'],
      depth: data['depth'] ?? 0,
      replyCount: data['replyCount'] ?? 0,
      upvoteCount: data['upvoteCount'] ?? 0,
      downvoteCount: data['downvoteCount'] ?? 0,
      score: data['score'] ?? 0,
      isEdited: data['isEdited'] ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] ?? false,
      isHidden: data['isHidden'] ?? false,
      hiddenByUid: data['hiddenByUid'],
      hiddenAt: (data['hiddenAt'] as Timestamp?)?.toDate(),
      hiddenReason: data['hiddenReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentId': parentId,
      'depth': depth,
      'replyCount': replyCount,
      'upvoteCount': upvoteCount,
      'downvoteCount': downvoteCount,
      'score': score,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
      'isHidden': isHidden,
      'hiddenByUid': hiddenByUid,
      'hiddenAt': hiddenAt != null ? Timestamp.fromDate(hiddenAt!) : null,
      'hiddenReason': hiddenReason,
    };
  }
}
