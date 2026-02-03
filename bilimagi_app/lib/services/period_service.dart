import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/period.dart';
import '../models/article.dart';
import '../models/community.dart';
import '../models/comment.dart';
import 'profile_service.dart';

// Re-export Comment for backward compatibility
export '../models/comment.dart' show Comment;

/// Period Service (v8.0 - replaces WeekService)
///
/// Key differences from WeekService:
/// - Flexible periods with custom titles and date ranges
/// - Multi-vote support (users can vote for multiple articles)
/// - minVotesForDiscussion threshold for eligibility
class PeriodService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();

  // ==================== PERIOD OPERATIONS ====================

  /// Create a new period
  Future<String> createPeriod({
    required String communityId,
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int minVotesForDiscussion = 1,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    final periodRef = _db.collection('periods').doc();
    final period = Period(
      id: periodRef.id,
      communityId: communityId,
      title: title,
      description: description,
      phase: PeriodPhase.voting,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      minVotesForDiscussion: minVotesForDiscussion,
    );

    await periodRef.set(period.toFirestore());

    // Update community with currentPeriodId and increment periodCount
    await _db.collection('communities').doc(communityId).update({
      'currentPeriodId': periodRef.id,
      'stats.periodCount': FieldValue.increment(1),
    });

    return periodRef.id;
  }

  /// Get period by ID (stream for realtime phase updates)
  Stream<Period?> getPeriod(String periodId) {
    return _db.collection('periods').doc(periodId).snapshots().map((doc) {
      if (doc.exists) {
        return Period.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get period once (for navigation)
  Future<Period?> getPeriodOnce(String periodId) async {
    final doc = await _db.collection('periods').doc(periodId).get();
    if (!doc.exists) return null;
    return Period.fromFirestore(doc);
  }

  /// Get all periods for a community
  Stream<List<Period>> getCommunityPeriods(String communityId) {
    return _db
        .collection('periods')
        .where('communityId', isEqualTo: communityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Period.fromFirestore(doc)).toList();
    });
  }

  /// Change period phase with authorization check
  Future<void> changePhase(
    String periodId,
    PeriodPhase newPhase,
    String communityId,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    // Check if user is admin
    final userDoc = await _db.collection('users').doc(uid).get();
    final isAdmin = userDoc.data()?['role'] == 'admin';

    if (!isAdmin) {
      // Check if user is owner or moderator of the community
      final memberDoc = await _db
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(uid)
          .get();

      if (!memberDoc.exists) {
        throw Exception('Bu islemi yapma yetkiniz yok');
      }

      final role = memberDoc.data()?['role'] as String?;
      final status = memberDoc.data()?['status'] as String?;

      if (status != 'approved' || (role != 'owner' && role != 'moderator')) {
        throw Exception('Bu islemi yapma yetkiniz yok');
      }
    }

    // If transitioning to discussion, mark eligible articles
    if (newPhase == PeriodPhase.discussion) {
      await _markEligibleArticles(periodId);
    }

    // Update the phase
    await _db.collection('periods').doc(periodId).update({
      'phase': Period.phaseToString(newPhase),
      'phaseChangedAt': FieldValue.serverTimestamp(),
      'phaseChangedByUid': uid,
    });
  }

  /// Mark articles eligible for discussion based on vote threshold
  Future<void> _markEligibleArticles(String periodId) async {
    final periodDoc = await _db.collection('periods').doc(periodId).get();
    if (!periodDoc.exists) return;

    final period = Period.fromFirestore(periodDoc);
    final threshold = period.minVotesForDiscussion;

    final articlesSnapshot = await _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .get();

    final batch = _db.batch();

    for (final articleDoc in articlesSnapshot.docs) {
      final votesSnapshot = await _db
          .collection('periods')
          .doc(periodId)
          .collection('articles')
          .doc(articleDoc.id)
          .collection('votes')
          .get();

      final voteCount = votesSnapshot.docs.length;
      final isEligible = voteCount >= threshold;

      batch.update(articleDoc.reference, {
        'voteCount': voteCount,
        'isEligibleForDiscussion': isEligible,
      });
    }

    await batch.commit();
  }

  /// Update period details
  Future<void> updatePeriod({
    required String periodId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? minVotesForDiscussion,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
    if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);
    if (minVotesForDiscussion != null) {
      updates['minVotesForDiscussion'] = minVotesForDiscussion;
    }

    if (updates.isNotEmpty) {
      await _db.collection('periods').doc(periodId).update(updates);
    }
  }

  // ==================== ARTICLE OPERATIONS ====================

  /// Get articles for a period (stream)
  Stream<List<Article>> getArticles(String periodId) {
    return _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
    });
  }

  /// Get article once
  Future<Article?> getArticleOnce(String periodId, String articleId) async {
    final doc = await _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .doc(articleId)
        .get();
    if (!doc.exists) return null;
    return Article.fromFirestore(doc);
  }

  /// Add article to period
  Future<String> addArticle({
    required String periodId,
    required String title,
    required String summary,
    required String link,
    String? heroImageURL,
    String? content,
    String? suggestedByUid,
    String? suggestionId,
  }) async {
    final articleRef = _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .doc();

    await articleRef.set({
      'title': title,
      'summary': summary,
      'link': link,
      'voteCount': 0,
      'isEligibleForDiscussion': false,
      'status': 'published',
      'createdAt': FieldValue.serverTimestamp(),
      if (heroImageURL != null) 'heroImageURL': heroImageURL,
      if (content != null) 'content': content,
      if (suggestedByUid != null) 'suggestedByUid': suggestedByUid,
      if (suggestionId != null) 'suggestionId': suggestionId,
    });

    // Update community total articles count
    final periodDoc = await _db.collection('periods').doc(periodId).get();
    if (periodDoc.exists) {
      final period = Period.fromFirestore(periodDoc);
      await _db.collection('communities').doc(period.communityId).update({
        'stats.totalArticles': FieldValue.increment(1),
      });
    }

    return articleRef.id;
  }

  /// Get single article vote count as stream
  Stream<int> getArticleVoteCount(String periodId, String articleId) {
    return _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .doc(articleId)
        .collection('votes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get articles eligible for discussion
  Future<List<Article>> getEligibleArticles(String periodId) async {
    final snapshot = await _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .where('isEligibleForDiscussion', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
  }

  /// Get articles NOT eligible for discussion (below threshold)
  Future<List<Article>> getIneligibleArticles(String periodId) async {
    final snapshot = await _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .where('isEligibleForDiscussion', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
  }

  // ==================== MULTI-VOTE OPERATIONS ====================

  /// Get vote counts for all articles in a period (stream)
  Stream<Map<String, int>> getVoteCounts(String periodId) {
    return _db.collection('periods').doc(periodId).snapshots().asyncMap((_) async {
      final articlesSnapshot = await _db
          .collection('periods')
          .doc(periodId)
          .collection('articles')
          .get();

      final Map<String, int> voteCounts = {};

      for (final articleDoc in articlesSnapshot.docs) {
        final votesSnapshot = await _db
            .collection('periods')
            .doc(periodId)
            .collection('articles')
            .doc(articleDoc.id)
            .collection('votes')
            .get();
        voteCounts[articleDoc.id] = votesSnapshot.docs.length;
      }

      return voteCounts;
    });
  }

  /// Get user's votes in a period (multi-vote: returns set of article IDs)
  Future<Set<String>> getUserVotes(String periodId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    final articlesSnapshot = await _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .get();

    final Set<String> votedArticleIds = {};

    for (final articleDoc in articlesSnapshot.docs) {
      final voteDoc = await _db
          .collection('periods')
          .doc(periodId)
          .collection('articles')
          .doc(articleDoc.id)
          .collection('votes')
          .doc(uid)
          .get();

      if (voteDoc.exists) {
        votedArticleIds.add(articleDoc.id);
      }
    }

    return votedArticleIds;
  }

  /// Stream user's votes in a period
  Stream<Set<String>> getUserVotesStream(String periodId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value({});

    return _db
        .collection('periods')
        .doc(periodId)
        .snapshots()
        .asyncMap((_) => getUserVotes(periodId));
  }

  /// Toggle vote on an article (multi-vote system)
  /// Returns true if vote was added, false if removed
  Future<bool> toggleVote(String periodId, String articleId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    final voteRef = _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .doc(articleId)
        .collection('votes')
        .doc(uid);

    final voteDoc = await voteRef.get();

    if (voteDoc.exists) {
      // Remove vote
      await voteRef.delete();

      // Update period document to trigger vote count stream
      await _db.collection('periods').doc(periodId).update({
        'lastVoteAt': FieldValue.serverTimestamp(),
      });

      return false;
    } else {
      // Add vote
      await voteRef.set({
        'articleId': articleId,
        'periodId': periodId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update period document to trigger vote count stream
      await _db.collection('periods').doc(periodId).update({
        'lastVoteAt': FieldValue.serverTimestamp(),
      });

      // Increment user vote stats
      await _profileService.incrementStats(votes: 1);

      return true;
    }
  }

  // ==================== FEED QUERIES ====================

  /// Get active discussions (for home feed)
  Stream<List<Map<String, dynamic>>> getActiveDiscussions() {
    return _db
        .collection('periods')
        .where('phase', isEqualTo: 'discussion')
        .limit(20)
        .snapshots()
        .asyncMap((periodsSnapshot) async {
      final List<Map<String, dynamic>> results = [];

      for (final periodDoc in periodsSnapshot.docs) {
        final period = Period.fromFirestore(periodDoc);

        // Get community (skip deleted)
        final communityDoc =
            await _db.collection('communities').doc(period.communityId).get();
        if (!communityDoc.exists) continue;
        final community = Community.fromFirestore(communityDoc);
        if (community.isDeleted) continue;

        // Get eligible articles count
        final eligibleSnapshot = await _db
            .collection('periods')
            .doc(period.id)
            .collection('articles')
            .where('isEligibleForDiscussion', isEqualTo: true)
            .get();

        final eligibleCount = eligibleSnapshot.docs.length;
        if (eligibleCount == 0) continue;

        results.add({
          'period': period,
          'community': community,
          'eligibleArticleCount': eligibleCount,
        });
      }

      // Sort by createdAt in memory (descending - newest first)
      results.sort((a, b) {
        final periodA = a['period'] as Period;
        final periodB = b['period'] as Period;
        return periodB.createdAt.compareTo(periodA.createdAt);
      });

      return results.take(10).toList();
    });
  }

  /// Get voting periods (for home feed)
  Stream<List<Map<String, dynamic>>> getVotingPeriods() {
    return _db
        .collection('periods')
        .where('phase', isEqualTo: 'voting')
        .limit(20)
        .snapshots()
        .asyncMap((periodsSnapshot) async {
      final List<Map<String, dynamic>> results = [];

      for (final periodDoc in periodsSnapshot.docs) {
        final period = Period.fromFirestore(periodDoc);

        // Get community (skip deleted)
        final communityDoc =
            await _db.collection('communities').doc(period.communityId).get();
        if (!communityDoc.exists) continue;
        final community = Community.fromFirestore(communityDoc);
        if (community.isDeleted) continue;

        // Get article count
        final articlesSnapshot = await _db
            .collection('periods')
            .doc(period.id)
            .collection('articles')
            .get();

        results.add({
          'period': period,
          'community': community,
          'articleCount': articlesSnapshot.docs.length,
        });
      }

      // Sort by createdAt in memory (descending - newest first)
      results.sort((a, b) {
        final periodA = a['period'] as Period;
        final periodB = b['period'] as Period;
        return periodB.createdAt.compareTo(periodA.createdAt);
      });

      return results.take(10).toList();
    });
  }

  // ==================== COMMENT OPERATIONS ====================

  /// Get comments for an article (stream)
  Stream<List<Comment>> getComments(String periodId, String articleId) {
    return _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  /// Add a comment
  Future<String> addComment(String periodId, String articleId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanici oturumu acik degil');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final commentRef = await _db
        .collection('periods')
        .doc(periodId)
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

    return commentRef.id;
  }

  /// Add reply
  Future<String> addReply(
    String periodId,
    String articleId,
    String parentCommentId,
    int parentDepth,
    String text,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanici oturumu acik degil');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final commentsRef = _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .doc(articleId)
        .collection('comments');

    final replyRef = await commentsRef.add({
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

    return replyRef.id;
  }

  /// Edit comment
  Future<void> editComment(
    String periodId,
    String articleId,
    String commentId,
    String newText,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanici oturumu acik degil');

    final commentRef = _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId);

    final commentDoc = await commentRef.get();
    if (!commentDoc.exists) throw Exception('Yorum bulunamadi');

    final commentUid = commentDoc.data()?['uid'] as String?;
    if (commentUid != user.uid) {
      throw Exception('Bu yorumu duzenleme yetkiniz yok');
    }

    await commentRef.update({
      'text': newText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete comment (soft delete)
  Future<void> deleteComment(
    String periodId,
    String articleId,
    String commentId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanici oturumu acik degil');

    final commentRef = _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .doc(articleId)
        .collection('comments')
        .doc(commentId);

    final commentDoc = await commentRef.get();
    if (!commentDoc.exists) throw Exception('Yorum bulunamadi');

    final commentUid = commentDoc.data()?['uid'] as String?;
    if (commentUid != user.uid) {
      throw Exception('Bu yorumu silme yetkiniz yok');
    }

    await commentRef.update({
      'isDeleted': true,
    });
  }
}
