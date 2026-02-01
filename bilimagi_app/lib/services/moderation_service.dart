import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_ban.dart';
import '../models/moderation_log.dart';
import '../models/comment.dart';
import '../models/community_membership.dart';

/// Central service for moderation operations
class ModerationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  // ==================== COMMENT MODERATION ====================

  /// Hide a comment (mod/owner only)
  Future<void> hideComment({
    required String communityId,
    required String weekId,
    required String articleId,
    required String commentId,
    String? reason,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Check permission
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.canManageMembers) {
      throw Exception('Not authorized to moderate comments');
    }

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Moderatör';

    // Get comment author info for log
    final commentDoc = await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId)
        .get();

    final commentData = commentDoc.data();
    final commentAuthorUid = commentData?['uid'] as String?;
    final commentAuthorName = commentData?['displayName'] as String?;

    final batch = _db.batch();

    // Update comment
    final commentRef = _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId);

    batch.update(commentRef, {
      'isHidden': true,
      'hiddenByUid': uid,
      'hiddenAt': FieldValue.serverTimestamp(),
      'hiddenReason': reason,
    });

    // Log action
    final logRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('moderationLogs')
        .doc();

    batch.set(logRef, {
      'type': ModerationActionType.hideComment.name,
      'moderatorUid': uid,
      'moderatorDisplayName': displayName,
      'targetUid': commentAuthorUid,
      'targetDisplayName': commentAuthorName,
      'targetId': commentId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Unhide a comment (mod/owner only)
  Future<void> unhideComment({
    required String communityId,
    required String weekId,
    required String articleId,
    required String commentId,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Check permission
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.canManageMembers) {
      throw Exception('Not authorized to moderate comments');
    }

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Moderatör';

    final batch = _db.batch();

    // Update comment
    final commentRef = _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId);

    batch.update(commentRef, {
      'isHidden': false,
      'hiddenByUid': null,
      'hiddenAt': null,
      'hiddenReason': null,
    });

    // Log action
    final logRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('moderationLogs')
        .doc();

    batch.set(logRef, {
      'type': ModerationActionType.unhideComment.name,
      'moderatorUid': uid,
      'moderatorDisplayName': displayName,
      'targetId': commentId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Get hidden comments for a community's weeks
  Stream<List<Comment>> getHiddenComments(String communityId) {
    // This requires knowing weekId - for now return empty
    // In a real implementation, you'd query across all weeks for this community
    return Stream.value([]);
  }

  // ==================== BAN MANAGEMENT ====================

  /// Ban a user from community (mod/owner only)
  Future<void> banUser({
    required String communityId,
    required String targetUid,
    required String reason,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Check permission
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.canManageMembers) {
      throw Exception('Not authorized to ban users');
    }

    // Cannot ban owner
    final targetMembership = await _getMembership(communityId, targetUid);
    if (targetMembership?.isOwner == true) {
      throw Exception('Cannot ban the owner');
    }

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Moderatör';

    final targetUserDoc = await _db.collection('users').doc(targetUid).get();
    final targetDisplayName = targetUserDoc.data()?['displayName'] ?? 'Bilinmeyen';

    final batch = _db.batch();

    // Add ban record
    final banRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('bans')
        .doc(targetUid);

    batch.set(banRef, {
      'bannedDisplayName': targetDisplayName,
      'bannedByUid': uid,
      'bannedByDisplayName': displayName,
      'bannedAt': FieldValue.serverTimestamp(),
      'expiresAt': null, // Permanent ban
      'reason': reason,
    });

    // Remove from members if exists
    final memberRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(targetUid);

    batch.delete(memberRef);

    // Decrement member count if was approved member
    if (targetMembership?.isApproved == true) {
      final communityRef = _db.collection('communities').doc(communityId);
      batch.update(communityRef, {
        'stats.memberCount': FieldValue.increment(-1),
      });
    }

    // Log action
    final logRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('moderationLogs')
        .doc();

    batch.set(logRef, {
      'type': ModerationActionType.banUser.name,
      'moderatorUid': uid,
      'moderatorDisplayName': displayName,
      'targetUid': targetUid,
      'targetDisplayName': targetDisplayName,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Unban a user from community (mod/owner only)
  Future<void> unbanUser({
    required String communityId,
    required String targetUid,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Check permission
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.canManageMembers) {
      throw Exception('Not authorized to unban users');
    }

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Moderatör';

    // Get banned user's name
    final banDoc = await _db
        .collection('communities')
        .doc(communityId)
        .collection('bans')
        .doc(targetUid)
        .get();

    final targetDisplayName = banDoc.data()?['bannedDisplayName'] ?? 'Bilinmeyen';

    final batch = _db.batch();

    // Remove ban record
    final banRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('bans')
        .doc(targetUid);

    batch.delete(banRef);

    // Log action
    final logRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('moderationLogs')
        .doc();

    batch.set(logRef, {
      'type': ModerationActionType.unbanUser.name,
      'moderatorUid': uid,
      'moderatorDisplayName': displayName,
      'targetUid': targetUid,
      'targetDisplayName': targetDisplayName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Get banned users for a community
  Stream<List<CommunityBan>> getBannedUsers(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('bans')
        .orderBy('bannedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityBan.fromFirestore(doc, communityId))
            .where((ban) => ban.isActive)
            .toList());
  }

  /// Check if user is banned from community
  Future<bool> isUserBanned(String communityId, String uid) async {
    final banDoc = await _db
        .collection('communities')
        .doc(communityId)
        .collection('bans')
        .doc(uid)
        .get();

    if (!banDoc.exists) return false;

    final ban = CommunityBan.fromFirestore(banDoc, communityId);
    return ban.isActive;
  }

  // ==================== AUDIT LOG ====================

  /// Get moderation logs for a community
  Stream<List<ModerationLog>> getModerationLogs(String communityId, {int limit = 50}) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('moderationLogs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModerationLog.fromFirestore(doc, communityId))
            .toList());
  }

  /// Log a moderation action
  Future<void> logAction({
    required String communityId,
    required ModerationActionType type,
    String? targetUid,
    String? targetDisplayName,
    String? targetId,
    String? details,
    String? reason,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Moderatör';

    await _db
        .collection('communities')
        .doc(communityId)
        .collection('moderationLogs')
        .add({
      'type': type.name,
      'moderatorUid': uid,
      'moderatorDisplayName': displayName,
      'targetUid': targetUid,
      'targetDisplayName': targetDisplayName,
      'targetId': targetId,
      'details': details,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== HELPERS ====================

  Future<CommunityMembership?> _getMembership(String communityId, String uid) async {
    final doc = await _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return CommunityMembership.fromFirestore(doc, communityId);
  }
}
