import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../models/community.dart';
import '../models/comment.dart';
import 'profile_service.dart';

// Re-export Comment for backward compatibility
export '../models/comment.dart' show Comment;

class WeekService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();

  // ==================== WEEK OPERATIONS ====================

  /// Get week by ID (stream for realtime phase updates)
  Stream<Week?> getWeek(String weekId) {
    return _db.collection('weeks').doc(weekId).snapshots().map((doc) {
      if (doc.exists) {
        return Week.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get week once (for saved articles navigation)
  Future<Week?> getWeekOnce(String weekId) async {
    final doc = await _db.collection('weeks').doc(weekId).get();
    if (!doc.exists) return null;
    return Week.fromFirestore(doc);
  }

  /// Change week phase (admin only)
  Future<void> changePhase(String weekId, WeekPhase newPhase) async {
    await _db.collection('weeks').doc(weekId).update({
      'phase': Week.phaseToString(newPhase),
    });
  }

  // ==================== ARTICLE OPERATIONS ====================

  /// Get articles for a week (stream)
  Stream<List<Article>> getArticles(String weekId) {
    return _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
    });
  }

  /// Get article once (for saved articles navigation)
  Future<Article?> getArticleOnce(String weekId, String articleId) async {
    final doc = await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .get();
    if (!doc.exists) return null;
    return Article.fromFirestore(doc);
  }

  /// Get single article vote count as stream
  Stream<int> getArticleVoteCount(String weekId, String articleId) {
    return _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('votes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get winning article (most votes)
  Future<Article?> getWinningArticle(String weekId) async {
    final articlesSnapshot = await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .get();

    Article? winner;
    int maxVotes = -1;

    for (final articleDoc in articlesSnapshot.docs) {
      final votesSnapshot = await _db
          .collection('weeks')
          .doc(weekId)
          .collection('articles')
          .doc(articleDoc.id)
          .collection('votes')
          .get();

      final voteCount = votesSnapshot.docs.length;
      if (voteCount > maxVotes) {
        maxVotes = voteCount;
        winner = Article.fromFirestore(articleDoc);
        winner.voteCount = voteCount;
      }
    }

    return winner;
  }

  // ==================== VOTING OPERATIONS ====================

  /// Get vote counts for all articles in a week (stream)
  Stream<Map<String, int>> getVoteCounts(String weekId) {
    return _db.collection('weeks').doc(weekId).snapshots().asyncMap((_) async {
      final articlesSnapshot = await _db
          .collection('weeks')
          .doc(weekId)
          .collection('articles')
          .get();

      final Map<String, int> voteCounts = {};

      for (final articleDoc in articlesSnapshot.docs) {
        final votesSnapshot = await _db
            .collection('weeks')
            .doc(weekId)
            .collection('articles')
            .doc(articleDoc.id)
            .collection('votes')
            .get();
        voteCounts[articleDoc.id] = votesSnapshot.docs.length;
      }

      return voteCounts;
    });
  }

  /// Get user's current vote in a week
  Future<String?> getUserVote(String weekId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final articlesSnapshot = await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .get();

    for (final articleDoc in articlesSnapshot.docs) {
      final voteDoc = await _db
          .collection('weeks')
          .doc(weekId)
          .collection('articles')
          .doc(articleDoc.id)
          .collection('votes')
          .doc(uid)
          .get();

      if (voteDoc.exists) {
        return articleDoc.id;
      }
    }
    return null;
  }

  /// Cast a vote (removes previous vote if exists)
  Future<void> castVote(String weekId, String articleId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    // First, remove any existing votes by this user in this week
    final articlesSnapshot = await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .get();

    final batch = _db.batch();

    for (final articleDoc in articlesSnapshot.docs) {
      final voteRef = _db
          .collection('weeks')
          .doc(weekId)
          .collection('articles')
          .doc(articleDoc.id)
          .collection('votes')
          .doc(uid);
      batch.delete(voteRef);
    }

    // Add new vote
    final newVoteRef = _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('votes')
        .doc(uid);

    batch.set(newVoteRef, {
      'choice': articleId,
      'weekId': weekId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update week document to trigger vote count stream
    final weekRef = _db.collection('weeks').doc(weekId);
    batch.update(weekRef, {
      'lastVoteAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Increment user vote stats
    await _profileService.incrementStats(votes: 1);
  }

  // ==================== FEED QUERIES ====================

  /// Get active discussions (for home feed)
  Stream<List<Map<String, dynamic>>> getActiveDiscussions() {
    return _db
        .collection('weeks')
        .where('phase', isEqualTo: 'discussion')
        .limit(20)
        .snapshots()
        .asyncMap((weeksSnapshot) async {
      final List<Map<String, dynamic>> results = [];

      for (final weekDoc in weeksSnapshot.docs) {
        final week = Week.fromFirestore(weekDoc);

        // Get community (skip deleted)
        final communityDoc =
            await _db.collection('communities').doc(week.communityId).get();
        if (!communityDoc.exists) continue;
        final community = Community.fromFirestore(communityDoc);
        if (community.isDeleted) continue;

        // Get winning article
        final article = await getWinningArticle(week.id);
        if (article == null) continue;

        results.add({
          'week': week,
          'community': community,
          'article': article,
        });
      }

      // Sort by createdAt in memory (descending - newest first)
      results.sort((a, b) {
        final weekA = a['week'] as Week;
        final weekB = b['week'] as Week;
        return weekB.createdAt.compareTo(weekA.createdAt);
      });

      return results.take(10).toList();
    });
  }

  /// Get voting weeks (for home feed)
  Stream<List<Map<String, dynamic>>> getVotingWeeks() {
    return _db
        .collection('weeks')
        .where('phase', isEqualTo: 'voting')
        .limit(20)
        .snapshots()
        .asyncMap((weeksSnapshot) async {
      final List<Map<String, dynamic>> results = [];

      for (final weekDoc in weeksSnapshot.docs) {
        final week = Week.fromFirestore(weekDoc);

        // Get community (skip deleted)
        final communityDoc =
            await _db.collection('communities').doc(week.communityId).get();
        if (!communityDoc.exists) continue;
        final community = Community.fromFirestore(communityDoc);
        if (community.isDeleted) continue;

        results.add({
          'week': week,
          'community': community,
        });
      }

      // Sort by createdAt in memory (descending - newest first)
      results.sort((a, b) {
        final weekA = a['week'] as Week;
        final weekB = b['week'] as Week;
        return weekB.createdAt.compareTo(weekA.createdAt);
      });

      return results.take(10).toList();
    });
  }

  // ==================== COMMENT OPERATIONS (Delegated to CommentService) ====================
  // These methods are kept for backward compatibility but delegate to CommentService

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

  /// Add a comment - delegates to CommentService
  Future<void> addComment(String weekId, String articleId, String text) async {
    // Import and use CommentService inline to avoid circular dependency
    final commentService = _CommentServiceDelegate();
    await commentService.addComment(weekId, articleId, text);
  }

  /// Add reply - delegates to CommentService
  Future<void> addReply(
    String weekId,
    String articleId,
    String parentCommentId,
    int parentDepth,
    String text,
  ) async {
    final commentService = _CommentServiceDelegate();
    await commentService.addReply(weekId, articleId, parentCommentId, parentDepth, text);
  }

  /// Edit comment - delegates to CommentService
  Future<void> editComment(
    String weekId,
    String articleId,
    String commentId,
    String newText,
  ) async {
    final commentService = _CommentServiceDelegate();
    await commentService.editComment(weekId, articleId, commentId, newText);
  }

  /// Delete comment - delegates to CommentService
  Future<void> deleteComment(
    String weekId,
    String articleId,
    String commentId,
  ) async {
    final commentService = _CommentServiceDelegate();
    await commentService.deleteComment(weekId, articleId, commentId);
  }
}

// Private delegate class to avoid circular import
// This replicates CommentService logic inline
class _CommentServiceDelegate {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();

  Future<void> addComment(String weekId, String articleId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    await _db
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
      'depth': 0,
      'replyCount': 0,
      'upvoteCount': 0,
      'downvoteCount': 0,
      'score': 0,
    });

    await _profileService.incrementStats(comments: 1);
  }

  Future<void> addReply(
    String weekId,
    String articleId,
    String parentCommentId,
    int parentDepth,
    String text,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final commentsRef = _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments');

    await commentsRef.add({
      'uid': user.uid,
      'displayName': displayName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'parentId': parentCommentId,
      'depth': parentDepth + 1,
      'replyCount': 0,
      'upvoteCount': 0,
      'downvoteCount': 0,
      'score': 0,
    });

    await commentsRef.doc(parentCommentId).update({
      'replyCount': FieldValue.increment(1),
    });

    await _profileService.incrementStats(comments: 1);
  }

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

    final commentDoc = await commentRef.get();
    if (!commentDoc.exists) throw Exception('Comment not found');

    final commentUid = commentDoc.data()?['uid'] as String?;
    if (commentUid != user.uid) {
      throw Exception('Not authorized to edit this comment');
    }

    await commentRef.update({
      'text': newText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

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

    final commentDoc = await commentRef.get();
    if (!commentDoc.exists) throw Exception('Comment not found');

    final commentUid = commentDoc.data()?['uid'] as String?;
    if (commentUid != user.uid) {
      throw Exception('Not authorized to delete this comment');
    }

    await commentRef.update({
      'isDeleted': true,
    });
  }
}
