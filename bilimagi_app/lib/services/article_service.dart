import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article.dart';
import '../models/community_membership.dart';

/// Service for article CRUD operations (v8.0)
class ArticleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  // ==================== ARTICLE CRUD ====================

  /// Create a new article
  Future<String> createArticle({
    required String weekId,
    required String communityId,
    required String title,
    required String summary,
    required String link,
    String? heroImageURL,
    String? content,
    ArticleStatus status = ArticleStatus.published,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    // Check permission (owner or moderator)
    await _checkPermission(communityId, uid);

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final articleRef = _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc();

    final now = DateTime.now();
    final article = Article(
      id: articleRef.id,
      title: title,
      summary: summary,
      link: link,
      heroImageURL: heroImageURL,
      content: content,
      status: status,
      authorUid: uid,
      authorDisplayName: displayName,
      createdAt: now,
      updatedAt: now,
      publishedAt: status == ArticleStatus.published ? now : null,
    );

    await articleRef.set(article.toFirestore());

    // Update community stats
    if (status == ArticleStatus.published) {
      await _db.collection('communities').doc(communityId).update({
        'stats.totalArticles': FieldValue.increment(1),
      });
    }

    return articleRef.id;
  }

  /// Update an existing article
  Future<void> updateArticle({
    required String weekId,
    required String articleId,
    required String communityId,
    String? title,
    String? summary,
    String? link,
    String? heroImageURL,
    String? content,
    bool clearHeroImage = false,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    if (summary != null) updates['summary'] = summary;
    if (link != null) updates['link'] = link;
    if (heroImageURL != null) updates['heroImageURL'] = heroImageURL;
    if (content != null) updates['content'] = content;
    if (clearHeroImage) updates['heroImageURL'] = FieldValue.delete();

    await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .update(updates);
  }

  /// Publish a draft article
  Future<void> publishArticle({
    required String weekId,
    required String articleId,
    required String communityId,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .update({
      'status': ArticleStatus.published.name,
      'publishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update community stats
    await _db.collection('communities').doc(communityId).update({
      'stats.totalArticles': FieldValue.increment(1),
    });
  }

  /// Archive an article
  Future<void> archiveArticle({
    required String weekId,
    required String articleId,
    required String communityId,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .update({
      'status': ArticleStatus.archived.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an article
  Future<void> deleteArticle({
    required String weekId,
    required String articleId,
    required String communityId,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    // Get article first to check if it was published
    final articleDoc = await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .get();

    if (!articleDoc.exists) return;

    final article = Article.fromFirestore(articleDoc);

    // Delete article
    await articleDoc.reference.delete();

    // Update community stats if was published
    if (article.status == ArticleStatus.published) {
      await _db.collection('communities').doc(communityId).update({
        'stats.totalArticles': FieldValue.increment(-1),
      });
    }
  }

  // ==================== ARTICLE QUERIES ====================

  /// Get single article
  Future<Article?> getArticle(String weekId, String articleId) async {
    final doc = await _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .doc(articleId)
        .get();

    if (!doc.exists) return null;
    return Article.fromFirestore(doc);
  }

  /// Get articles for a week (stream)
  Stream<List<Article>> getArticles(String weekId, {bool includeDrafts = false}) {
    return _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .snapshots()
        .map((snapshot) {
      final articles = snapshot.docs
          .map((doc) => Article.fromFirestore(doc))
          .where((a) => includeDrafts || a.status == ArticleStatus.published)
          .toList();
      return articles;
    });
  }

  /// Get draft articles for a week
  Stream<List<Article>> getDraftArticles(String weekId) {
    return _db
        .collection('weeks')
        .doc(weekId)
        .collection('articles')
        .where('status', isEqualTo: 'draft')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList());
  }

  // ==================== DRAFT OPERATIONS ====================

  /// Save article as draft
  Future<String> saveDraft({
    required String weekId,
    required String communityId,
    String? articleId,
    required String title,
    required String summary,
    required String link,
    String? heroImageURL,
    String? content,
  }) async {
    if (articleId != null) {
      // Update existing draft
      await updateArticle(
        weekId: weekId,
        articleId: articleId,
        communityId: communityId,
        title: title,
        summary: summary,
        link: link,
        heroImageURL: heroImageURL,
        content: content,
      );
      return articleId;
    } else {
      // Create new draft
      return await createArticle(
        weekId: weekId,
        communityId: communityId,
        title: title,
        summary: summary,
        link: link,
        heroImageURL: heroImageURL,
        content: content,
        status: ArticleStatus.draft,
      );
    }
  }

  // ==================== PRIVATE HELPERS ====================

  Future<void> _checkPermission(String communityId, String uid) async {
    // Check if user is admin
    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.data()?['role'] == 'admin') return;

    // Check if user is owner or moderator
    final memberDoc = await _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(uid)
        .get();

    if (!memberDoc.exists) {
      throw Exception('Bu islemi yapma yetkiniz yok');
    }

    final membership = CommunityMembership.fromFirestore(memberDoc, communityId);
    if (!membership.canManageMembers) {
      throw Exception('Bu islemi yapma yetkiniz yok');
    }
  }
}
