import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of moderation actions
enum ModerationActionType {
  hideComment,
  unhideComment,
  banUser,
  unbanUser,
  approveRequest,
  rejectRequest,
  approveSuggestion,
  rejectSuggestion,
  setRole;

  static ModerationActionType fromString(String value) {
    switch (value) {
      case 'hideComment':
        return ModerationActionType.hideComment;
      case 'unhideComment':
        return ModerationActionType.unhideComment;
      case 'banUser':
        return ModerationActionType.banUser;
      case 'unbanUser':
        return ModerationActionType.unbanUser;
      case 'approveRequest':
        return ModerationActionType.approveRequest;
      case 'rejectRequest':
        return ModerationActionType.rejectRequest;
      case 'approveSuggestion':
        return ModerationActionType.approveSuggestion;
      case 'rejectSuggestion':
        return ModerationActionType.rejectSuggestion;
      case 'setRole':
        return ModerationActionType.setRole;
      default:
        return ModerationActionType.hideComment;
    }
  }

  String get displayName {
    switch (this) {
      case ModerationActionType.hideComment:
        return 'Yorum gizlendi';
      case ModerationActionType.unhideComment:
        return 'Yorum gizliliği kaldırıldı';
      case ModerationActionType.banUser:
        return 'Kullanıcı yasaklandı';
      case ModerationActionType.unbanUser:
        return 'Kullanıcı yasağı kaldırıldı';
      case ModerationActionType.approveRequest:
        return 'Üyelik isteği onaylandı';
      case ModerationActionType.rejectRequest:
        return 'Üyelik isteği reddedildi';
      case ModerationActionType.approveSuggestion:
        return 'Makale önerisi onaylandı';
      case ModerationActionType.rejectSuggestion:
        return 'Makale önerisi reddedildi';
      case ModerationActionType.setRole:
        return 'Rol değiştirildi';
    }
  }
}

/// Represents a moderation action log entry
class ModerationLog {
  final String id;
  final String communityId;
  final ModerationActionType type;
  final String moderatorUid;
  final String moderatorDisplayName;
  final String? targetUid;
  final String? targetDisplayName;
  final String? targetId; // commentId, suggestionId, etc.
  final String? details;
  final String? reason;
  final DateTime createdAt;

  const ModerationLog({
    required this.id,
    required this.communityId,
    required this.type,
    required this.moderatorUid,
    required this.moderatorDisplayName,
    this.targetUid,
    this.targetDisplayName,
    this.targetId,
    this.details,
    this.reason,
    required this.createdAt,
  });

  factory ModerationLog.fromFirestore(DocumentSnapshot doc, String communityId) {
    final data = doc.data() as Map<String, dynamic>;
    return ModerationLog(
      id: doc.id,
      communityId: communityId,
      type: ModerationActionType.fromString(data['type'] ?? 'hideComment'),
      moderatorUid: data['moderatorUid'] ?? '',
      moderatorDisplayName: data['moderatorDisplayName'] ?? 'Bilinmeyen',
      targetUid: data['targetUid'],
      targetDisplayName: data['targetDisplayName'],
      targetId: data['targetId'],
      details: data['details'],
      reason: data['reason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'moderatorUid': moderatorUid,
      'moderatorDisplayName': moderatorDisplayName,
      'targetUid': targetUid,
      'targetDisplayName': targetDisplayName,
      'targetId': targetId,
      'details': details,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
