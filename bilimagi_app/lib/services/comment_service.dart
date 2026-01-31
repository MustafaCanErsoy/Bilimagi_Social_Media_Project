import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';
import 'profile_service.dart';
import 'notification_service.dart';
import 'mention_service.dart';

/// Service for handling comment operations
class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();
  final _notificationService = NotificationService();

  /// Get comments for an article (stream)
  Stream<List<Comment>> getComments(String weekId, String articleId) {
    return _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  /// Add a top-level comment
  Future<void> addComment(String weekId, String articleId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get user's display name from profile
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final newCommentRef = await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .add({
      'uid': user.uid,
      'displayName': displayName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'depth': 0, // Top-level comment
      'replyCount': 0,
      'upvoteCount': 0,
      'downvoteCount': 0,
      'score': 0,
    });

    // Increment user comment stats
    await _profileService.incrementStats(comments: 1);

    // Send mention notifications
    await _sendMentionNotifications(
      text: text,
      fromUid: user.uid,
      fromDisplayName: displayName,
      weekId: weekId,
      articleId: articleId,
      commentId: newCommentRef.id,
    );
  }

  /// Add reply to a comment
  Future<void> addReply(
    String weekId,
    String articleId,
    String parentCommentId,
    int parentDepth,
    String text,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get user's display name from profile
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final commentsRef = _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments');

    // Add the reply
    final newCommentRef = await commentsRef.add({
      'uid': user.uid,
      'displayName': displayName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'parentId': parentCommentId,
      'depth': parentDepth + 1, // One level deeper than parent
      'replyCount': 0,
      'upvoteCount': 0,
      'downvoteCount': 0,
      'score': 0,
    });

    // Increment parent's reply count
    await commentsRef.doc(parentCommentId).update({
      'replyCount': FieldValue.increment(1),
    });

    // Increment user comment stats
    await _profileService.incrementStats(comments: 1);

    // Send reply notification to parent comment author
    await _sendReplyNotification(
      commentsRef: commentsRef,
      parentCommentId: parentCommentId,
      fromUid: user.uid,
      fromDisplayName: displayName,
      weekId: weekId,
      articleId: articleId,
      newCommentId: newCommentRef.id,
      text: text,
    );

    // Send mention notifications
    await _sendMentionNotifications(
      text: text,
      fromUid: user.uid,
      fromDisplayName: displayName,
      weekId: weekId,
      articleId: articleId,
      commentId: newCommentRef.id,
    );
  }

  /// Edit a comment
  Future<void> editComment(
    String weekId,
    String articleId,
    String commentId,
    String newText,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final commentRef = _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId);

    // Verify ownership
    final commentDoc = await commentRef.get();
    if (!commentDoc.exists) throw Exception('Comment not found');

    final commentUid = commentDoc.data()?['uid'] as String?;
    if (commentUid != user.uid) {
      throw Exception('Not authorized to edit this comment');
    }

    // Update the comment
    await commentRef.update({
      'text': newText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a comment (soft delete)
  Future<void> deleteComment(
    String weekId,
    String articleId,
    String commentId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final commentRef = _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId);

    // Verify ownership
    final commentDoc = await commentRef.get();
    if (!commentDoc.exists) throw Exception('Comment not found');

    final commentUid = commentDoc.data()?['uid'] as String?;
    if (commentUid != user.uid) {
      throw Exception('Not authorized to delete this comment');
    }

    // Soft delete - mark as deleted
    await commentRef.update({
      'isDeleted': true,
    });
  }

  // Private helper: Send mention notifications
  Future<void> _sendMentionNotifications({
    required String text,
    required String fromUid,
    required String fromDisplayName,
    required String weekId,
    required String articleId,
    required String commentId,
  }) async {
    try {
      final mentionedUids = MentionService.parseMentions(text);
      for (final mentionedUid in mentionedUids) {
        if (mentionedUid != fromUid) {
          await _notificationService.createMentionNotification(
            targetUid: mentionedUid,
            fromDisplayName: fromDisplayName,
            weekId: weekId,
            articleId: articleId,
            commentId: commentId,
            preview: MentionService.getDisplayText(
              text.length > 100 ? '${text.substring(0, 100)}...' : text,
            ),
          );
        }
      }
    } catch (e) {
      print('Mention notification error: $e');
    }
  }

  // Private helper: Send reply notification
  Future<void> _sendReplyNotification({
    required CollectionReference commentsRef,
    required String parentCommentId,
    required String fromUid,
    required String fromDisplayName,
    required String weekId,
    required String articleId,
    required String newCommentId,
    required String text,
  }) async {
    try {
      final parentDoc = await commentsRef.doc(parentCommentId).get();
      if (parentDoc.exists) {
        final parentUid = (parentDoc.data() as Map<String, dynamic>?)?['uid'] as String?;
        if (parentUid != null && parentUid != fromUid) {
          await _notificationService.createReplyNotification(
            targetUid: parentUid,
            fromDisplayName: fromDisplayName,
            weekId: weekId,
            articleId: articleId,
            commentId: newCommentId,
            preview: MentionService.getDisplayText(
              text.length > 100 ? '${text.substring(0, 100)}...' : text,
            ),
          );
        }
      }
    } catch (e) {
      print('Reply notification error: $e');
    }
  }
}
