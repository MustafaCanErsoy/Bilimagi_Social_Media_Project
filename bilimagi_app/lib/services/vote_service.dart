import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

enum VoteType { up, down }

class VoteService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _notificationService = NotificationService();

  /// Vote on a comment (upvote or downvote)
  Future<void> voteComment({
    required String weekId,
    required String articleId,
    required String commentId,
    required VoteType type,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final commentRef = _firestore
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId);

    final voteRef = commentRef.collection('votes').doc(uid);

    // Get current vote (if any)
    final currentVote = await voteRef.get();
    final currentType = currentVote.exists
        ? (currentVote.data()?['type'] == 'up' ? VoteType.up : VoteType.down)
        : null;

    final batch = _firestore.batch();

    if (currentType == type) {
      // User clicked the same vote - remove vote
      batch.delete(voteRef);

      // Decrement count
      if (type == VoteType.up) {
        batch.update(commentRef, {
          'upvoteCount': FieldValue.increment(-1),
          'score': FieldValue.increment(-1),
        });
      } else {
        batch.update(commentRef, {
          'downvoteCount': FieldValue.increment(-1),
          'score': FieldValue.increment(1),
        });
      }
    } else if (currentType != null) {
      // User is changing vote (up→down or down→up)
      batch.set(voteRef, {
        'type': type == VoteType.up ? 'up' : 'down',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (type == VoteType.up) {
        // Was down, now up: -1 down, +1 up, +2 score
        batch.update(commentRef, {
          'upvoteCount': FieldValue.increment(1),
          'downvoteCount': FieldValue.increment(-1),
          'score': FieldValue.increment(2),
        });
      } else {
        // Was up, now down: -1 up, +1 down, -2 score
        batch.update(commentRef, {
          'upvoteCount': FieldValue.increment(-1),
          'downvoteCount': FieldValue.increment(1),
          'score': FieldValue.increment(-2),
        });
      }
    } else {
      // First vote on this comment
      batch.set(voteRef, {
        'type': type == VoteType.up ? 'up' : 'down',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (type == VoteType.up) {
        batch.update(commentRef, {
          'upvoteCount': FieldValue.increment(1),
          'score': FieldValue.increment(1),
        });
      } else {
        batch.update(commentRef, {
          'downvoteCount': FieldValue.increment(1),
          'score': FieldValue.increment(-1),
        });
      }
    }

    await batch.commit();

    // Send upvote notification (only for new upvotes, not for removing or changing votes)
    if (currentType == null && type == VoteType.up) {
      try {
        final commentDoc = await commentRef.get();
        final commentAuthorUid = commentDoc.data()?['uid'] as String?;

        if (commentAuthorUid != null && commentAuthorUid != uid) {
          final userDoc = await _firestore.collection('users').doc(uid).get();
          final displayName = userDoc.data()?['displayName'] ?? 'Birisi';

          await _notificationService.createUpvoteNotification(
            targetUid: commentAuthorUid,
            fromDisplayName: displayName,
            weekId: weekId,
            articleId: articleId,
            commentId: commentId,
          );
        }
      } catch (e) {
        print('Upvote notification error: $e');
      }
    }
  }

  /// Get current user's vote on a comment
  Stream<VoteType?> getUserVote({
    required String weekId,
    required String articleId,
    required String commentId,
  }) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId)
        .collection('votes')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final type = doc.data()?['type'];
      return type == 'up' ? VoteType.up : VoteType.down;
    });
  }
}
