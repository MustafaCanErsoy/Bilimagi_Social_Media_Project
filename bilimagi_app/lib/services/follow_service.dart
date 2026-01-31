import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class FollowService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _notificationService = NotificationService();

  String? get _currentUid => _auth.currentUser?.uid;

  /// Check if current user is following target user
  Stream<bool> isFollowing(String targetUid) {
    final uid = _currentUid;
    if (uid == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Follow a user
  Future<void> followUser(String targetUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not logged in');
    if (uid == targetUid) throw Exception('Cannot follow yourself');

    final batch = _firestore.batch();

    // Add to current user's following list
    final followingRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid);

    batch.set(followingRef, {
      'followedAt': FieldValue.serverTimestamp(),
    });

    // Add to target user's followers list
    final followersRef = _firestore
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(uid);

    batch.set(followersRef, {
      'followedAt': FieldValue.serverTimestamp(),
    });

    // Increment counts
    final currentUserRef = _firestore.collection('users').doc(uid);
    batch.update(currentUserRef, {
      'stats.followingCount': FieldValue.increment(1),
    });

    final targetUserRef = _firestore.collection('users').doc(targetUid);
    batch.update(targetUserRef, {
      'stats.followersCount': FieldValue.increment(1),
    });

    await batch.commit();

    // Send follow notification (don't await to avoid blocking)
    try {
      final currentUserDoc = await _firestore.collection('users').doc(uid).get();
      final displayName = currentUserDoc.data()?['displayName'] ?? 'Birisi';

      await _notificationService.createFollowNotification(
        targetUid: targetUid,
        fromDisplayName: displayName,
        fromUid: uid,
      );
    } catch (e) {
      print('Follow notification error: $e');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String targetUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not logged in');

    final batch = _firestore.batch();

    // Remove from current user's following list
    final followingRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid);

    batch.delete(followingRef);

    // Remove from target user's followers list
    final followersRef = _firestore
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(uid);

    batch.delete(followersRef);

    // Decrement counts
    final currentUserRef = _firestore.collection('users').doc(uid);
    batch.update(currentUserRef, {
      'stats.followingCount': FieldValue.increment(-1),
    });

    final targetUserRef = _firestore.collection('users').doc(targetUid);
    batch.update(targetUserRef, {
      'stats.followersCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// Get followers list for a user
  Stream<List<UserProfile>> getFollowers(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('followers')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final followerUids = snapshot.docs.map((doc) => doc.id).toList();
      if (followerUids.isEmpty) return <UserProfile>[];

      // Fetch user profiles for each follower
      final profiles = <UserProfile>[];
      for (final followerUid in followerUids) {
        final userDoc =
            await _firestore.collection('users').doc(followerUid).get();
        if (userDoc.exists) {
          profiles.add(UserProfile.fromFirestore(userDoc));
        }
      }
      return profiles;
    });
  }

  /// Get following list for a user
  Stream<List<UserProfile>> getFollowing(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final followingUids = snapshot.docs.map((doc) => doc.id).toList();
      if (followingUids.isEmpty) return <UserProfile>[];

      // Fetch user profiles for each following
      final profiles = <UserProfile>[];
      for (final followingUid in followingUids) {
        final userDoc =
            await _firestore.collection('users').doc(followingUid).get();
        if (userDoc.exists) {
          profiles.add(UserProfile.fromFirestore(userDoc));
        }
      }
      return profiles;
    });
  }

  /// Get follower count for a user
  Stream<int> getFollowerCount(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 0;
      final data = doc.data();
      return (data?['stats']?['followersCount'] ?? 0) as int;
    });
  }

  /// Get following count for a user
  Stream<int> getFollowingCount(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 0;
      final data = doc.data();
      return (data?['stats']?['followingCount'] ?? 0) as int;
    });
  }

  /// v3.0: Get suggested users to follow (users not already followed)
  Stream<List<UserProfile>> getSuggestedUsers(String currentUid) {
    // Listen to current user's following list to react to changes
    return _firestore
        .collection('users')
        .doc(currentUid)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnapshot) async {
      // Get list of users already being followed
      final followingUids = followingSnapshot.docs.map((doc) => doc.id).toSet();
      followingUids.add(currentUid); // Don't suggest self

      // Get all users (limit to avoid loading too many)
      final usersSnapshot = await _firestore
          .collection('users')
          .limit(50)
          .get();

      // Filter out users already followed
      final suggestions = <UserProfile>[];
      for (final doc in usersSnapshot.docs) {
        if (!followingUids.contains(doc.id)) {
          suggestions.add(UserProfile.fromFirestore(doc));
        }
      }

      // Sort by follower count (most popular first), then limit
      suggestions.sort((a, b) =>
          b.stats.followersCount.compareTo(a.stats.followersCount));

      return suggestions.take(10).toList();
    });
  }
}
