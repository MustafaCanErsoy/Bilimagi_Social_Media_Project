import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article.dart';
import '../models/week.dart';

class SavedArticle {
  final String articleId;
  final String weekId;
  final String communityId;
  final String title;
  final String summary;
  final DateTime savedAt;

  SavedArticle({
    required this.articleId,
    required this.weekId,
    required this.communityId,
    required this.title,
    required this.summary,
    required this.savedAt,
  });

  factory SavedArticle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedArticle(
      articleId: data['articleId'] ?? '',
      weekId: data['weekId'] ?? '',
      communityId: data['communityId'] ?? '',
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class BookmarkService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Save an article
  Future<void> saveArticle({
    required Article article,
    required Week week,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savedArticles')
        .doc(article.id)
        .set({
      'articleId': article.id,
      'weekId': week.id,
      'communityId': week.communityId,
      'title': article.title,
      'summary': article.summary,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unsave an article
  Future<void> unsaveArticle(String articleId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savedArticles')
        .doc(articleId)
        .delete();
  }

  /// Check if article is saved
  Stream<bool> isSaved(String articleId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedArticles')
        .doc(articleId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get all saved articles
  Stream<List<SavedArticle>> getSavedArticles() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedArticles')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SavedArticle.fromFirestore(doc))
          .toList();
    });
  }
}
