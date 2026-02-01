import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_activity.dart';

/// Service for recording and fetching user activities
class ActivityService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  // ==================== RECORD ACTIVITIES ====================

  /// Record a comment activity
  Future<void> recordCommentActivity({
    required String weekId,
    required String articleId,
    required String articleTitle,
    required String communityId,
    required String communityName,
    String? preview,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';
    final avatarColorIndex = userDoc.data()?['avatarColorIndex'] ?? 0;

    await _db.collection('users').doc(uid).collection('activities').add({
      'uid': uid,
      'displayName': displayName,
      'avatarColorIndex': avatarColorIndex,
      'type': 'comment',
      'targetType': 'article',
      'targetId': articleId,
      'targetName': articleTitle,
      'weekId': weekId,
      'communityId': communityId,
      'communityName': communityName,
      'preview': preview,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Record a vote activity
  Future<void> recordVoteActivity({
    required String weekId,
    required String articleId,
    required String articleTitle,
    required String communityId,
    required String communityName,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';
    final avatarColorIndex = userDoc.data()?['avatarColorIndex'] ?? 0;

    await _db.collection('users').doc(uid).collection('activities').add({
      'uid': uid,
      'displayName': displayName,
      'avatarColorIndex': avatarColorIndex,
      'type': 'vote',
      'targetType': 'article',
      'targetId': articleId,
      'targetName': articleTitle,
      'weekId': weekId,
      'communityId': communityId,
      'communityName': communityName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Record a community join activity
  Future<void> recordJoinActivity({
    required String communityId,
    required String communityName,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';
    final avatarColorIndex = userDoc.data()?['avatarColorIndex'] ?? 0;

    await _db.collection('users').doc(uid).collection('activities').add({
      'uid': uid,
      'displayName': displayName,
      'avatarColorIndex': avatarColorIndex,
      'type': 'join',
      'targetType': 'community',
      'targetId': communityId,
      'targetName': communityName,
      'communityId': communityId,
      'communityName': communityName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Record an article suggestion activity
  Future<void> recordSuggestionActivity({
    required String weekId,
    required String suggestionId,
    required String suggestionTitle,
    required String communityId,
    required String communityName,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';
    final avatarColorIndex = userDoc.data()?['avatarColorIndex'] ?? 0;

    await _db.collection('users').doc(uid).collection('activities').add({
      'uid': uid,
      'displayName': displayName,
      'avatarColorIndex': avatarColorIndex,
      'type': 'suggestion',
      'targetType': 'article',
      'targetId': suggestionId,
      'targetName': suggestionTitle,
      'weekId': weekId,
      'communityId': communityId,
      'communityName': communityName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== FETCH ACTIVITIES ====================

  /// Get activities for followed users (aggregated feed)
  Stream<List<UserActivity>> getFollowedUsersActivities({int limit = 50}) {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    // Listen to following list changes
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnapshot) async {
      final followingUids = followingSnapshot.docs.map((doc) => doc.id).toList();

      if (followingUids.isEmpty) return <UserActivity>[];

      // Fetch activities from each followed user
      final allActivities = <UserActivity>[];

      // Batch fetch activities (max 10 users at a time to avoid Firestore limits)
      final batches = _chunk(followingUids, 10);

      for (final batch in batches) {
        final futures = batch.map((followedUid) async {
          final activitiesSnapshot = await _db
              .collection('users')
              .doc(followedUid)
              .collection('activities')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get();

          return activitiesSnapshot.docs
              .map((doc) => UserActivity.fromFirestore(doc))
              .toList();
        });

        final results = await Future.wait(futures);
        for (final activities in results) {
          allActivities.addAll(activities);
        }
      }

      // Sort by time and limit
      allActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allActivities.take(limit).toList();
    });
  }

  /// Get activities for a specific user
  Stream<List<UserActivity>> getUserActivities(String uid, {int limit = 20}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserActivity.fromFirestore(doc)).toList());
  }

  // ==================== HELPERS ====================

  /// Split list into chunks
  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = (i + size < list.length) ? i + size : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
}
