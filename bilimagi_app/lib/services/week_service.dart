import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../models/community.dart';
import 'profile_service.dart';

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
    );
  }
}

class WeekService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();

  // Get week by ID (stream for realtime phase updates)
  Stream<Week?> getWeek(String weekId) {
    return _db.collection('weeks').doc(weekId).snapshots().map((doc) {
      if (doc.exists) {
        return Week.fromFirestore(doc);
      }
      return null;
    });
  }

  // Get articles for a week (stream)
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

  // Get vote counts for all articles in a week (stream)
  Stream<Map<String, int>> getVoteCounts(String weekId) {
    // Listen to week document changes (triggered by lastVoteAt updates)
    return _db.collection('weeks').doc(weekId).snapshots().asyncMap((_) async {
      // Get all articles in this week
      final articlesSnapshot = await _db
          .collection('weeks')
          .doc(weekId)
          .collection('articles')
          .get();

      final Map<String, int> voteCounts = {};

      // Count votes for each article
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

  // Get user's current vote in a week
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

  // Cast a vote (removes previous vote if exists)
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

  // Change week phase (admin only)
  Future<void> changePhase(String weekId, WeekPhase newPhase) async {
    await _db.collection('weeks').doc(weekId).update({
      'phase': Week.phaseToString(newPhase),
    });
  }

  // Get winning article (most votes)
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

  // Get comments for an article (stream)
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

  // Add a comment
  Future<void> addComment(String weekId, String articleId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .add({
      'uid': user.uid,
      'displayName': user.displayName ?? user.email ?? 'Anonim',
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
  }

  // v2.0: Add reply to a comment
  Future<void> addReply(
    String weekId,
    String articleId,
    String parentCommentId,
    int parentDepth,
    String text,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final commentsRef = _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .collection('comments');

    // Add the reply
    await commentsRef.add({
      'uid': user.uid,
      'displayName': user.displayName ?? user.email ?? 'Anonim',
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
  }

  // v2.0: Get active discussions (for home feed)
  Stream<List<Map<String, dynamic>>> getActiveDiscussions() {
    return _db
        .collection('weeks')
        .where('phase', isEqualTo: 'discussion')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap((weeksSnapshot) async {
      final List<Map<String, dynamic>> results = [];

      for (final weekDoc in weeksSnapshot.docs) {
        final week = Week.fromFirestore(weekDoc);

        // Get community
        final communityDoc =
            await _db.collection('communities').doc(week.communityId).get();
        if (!communityDoc.exists) continue;
        final community = Community.fromFirestore(communityDoc);

        // Get winning article
        final article = await getWinningArticle(week.id);
        if (article == null) continue;

        results.add({
          'week': week,
          'community': community,
          'article': article,
        });
      }

      return results;
    });
  }

  // v2.0: Get voting weeks (for home feed)
  Stream<List<Map<String, dynamic>>> getVotingWeeks() {
    return _db
        .collection('weeks')
        .where('phase', isEqualTo: 'voting')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap((weeksSnapshot) async {
      final List<Map<String, dynamic>> results = [];

      for (final weekDoc in weeksSnapshot.docs) {
        final week = Week.fromFirestore(weekDoc);

        // Get community
        final communityDoc =
            await _db.collection('communities').doc(week.communityId).get();
        if (!communityDoc.exists) continue;
        final community = Community.fromFirestore(communityDoc);

        results.add({
          'week': week,
          'community': community,
        });
      }

      return results;
    });
  }

  // v2.0: Get week once (for saved articles navigation)
  Future<Week?> getWeekOnce(String weekId) async {
    final doc = await _db.collection('weeks').doc(weekId).get();
    if (!doc.exists) return null;
    return Week.fromFirestore(doc);
  }

  // v2.0: Get article once (for saved articles navigation)
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
}
