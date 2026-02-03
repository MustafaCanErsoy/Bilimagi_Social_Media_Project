import 'package:cloud_firestore/cloud_firestore.dart';

/// Activity types for user feed
enum ActivityType {
  comment,
  vote,
  join,
  suggestion;

  static ActivityType fromString(String value) {
    switch (value) {
      case 'comment':
        return ActivityType.comment;
      case 'vote':
        return ActivityType.vote;
      case 'join':
        return ActivityType.join;
      case 'suggestion':
        return ActivityType.suggestion;
      default:
        return ActivityType.comment;
    }
  }
}

/// Target types for activities
enum ActivityTargetType {
  article,
  community,
  user;

  static ActivityTargetType fromString(String value) {
    switch (value) {
      case 'article':
        return ActivityTargetType.article;
      case 'community':
        return ActivityTargetType.community;
      case 'user':
        return ActivityTargetType.user;
      default:
        return ActivityTargetType.article;
    }
  }
}

/// User activity model for following feed
class UserActivity {
  final String id;
  final String uid;
  final String displayName;
  final int avatarColorIndex;
  final ActivityType type;
  final ActivityTargetType targetType;
  final String targetId;
  final String? targetName;
  final String? periodId;
  final String? communityId;
  final String? communityName;
  final String? preview;
  final DateTime createdAt;

  const UserActivity({
    required this.id,
    required this.uid,
    required this.displayName,
    this.avatarColorIndex = 0,
    required this.type,
    required this.targetType,
    required this.targetId,
    this.targetName,
    this.periodId,
    this.communityId,
    this.communityName,
    this.preview,
    required this.createdAt,
  });

  factory UserActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserActivity(
      id: doc.id,
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? 'Anonim',
      avatarColorIndex: data['avatarColorIndex'] ?? 0,
      type: ActivityType.fromString(data['type'] ?? 'comment'),
      targetType: ActivityTargetType.fromString(data['targetType'] ?? 'article'),
      targetId: data['targetId'] ?? '',
      targetName: data['targetName'],
      periodId: data['periodId'],
      communityId: data['communityId'],
      communityName: data['communityName'],
      preview: data['preview'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'avatarColorIndex': avatarColorIndex,
      'type': type.name,
      'targetType': targetType.name,
      'targetId': targetId,
      'targetName': targetName,
      'periodId': periodId,
      'communityId': communityId,
      'communityName': communityName,
      'preview': preview,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Get icon data for this activity type
  String get actionText {
    switch (type) {
      case ActivityType.comment:
        return 'bir tartışmaya yorum yaptı';
      case ActivityType.vote:
        return 'bir makaleye oy verdi';
      case ActivityType.join:
        return 'bir topluluğa katıldı';
      case ActivityType.suggestion:
        return 'bir makale önerdi';
    }
  }
}
