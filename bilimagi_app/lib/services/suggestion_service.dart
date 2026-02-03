import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article_suggestion.dart';
import 'notification_service.dart';

class SuggestionService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _notificationService = NotificationService();

  String? get _currentUid => _auth.currentUser?.uid;

  // ==================== SUGGESTION OPERATIONS ====================

  /// Submit a new article suggestion
  Future<String> submitSuggestion({
    required String periodId,
    required String title,
    required String summary,
    required String link,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final suggestionRef = _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .doc();

    final suggestion = ArticleSuggestion(
      id: suggestionRef.id,
      periodId: periodId,
      title: title,
      summary: summary,
      link: link,
      submitterUid: uid,
      submitterDisplayName: displayName,
      createdAt: DateTime.now(),
    );

    await suggestionRef.set(suggestion.toFirestore());
    return suggestionRef.id;
  }

  /// Get all suggestions for a week
  Stream<List<ArticleSuggestion>> getSuggestions(String periodId) {
    return _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .orderBy('interestScore', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ArticleSuggestion.fromFirestore(doc, periodId))
            .toList());
  }

  /// Get pending suggestions for a week
  Stream<List<ArticleSuggestion>> getPendingSuggestions(String periodId) {
    return _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .where('status', isEqualTo: 'pending')
        .orderBy('interestScore', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ArticleSuggestion.fromFirestore(doc, periodId))
            .toList());
  }

  /// Get pending suggestion count (for badge)
  Stream<int> getPendingSuggestionCount(String periodId) {
    return _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get single suggestion
  Future<ArticleSuggestion?> getSuggestion(String periodId, String suggestionId) async {
    final doc = await _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .doc(suggestionId)
        .get();

    if (!doc.exists) return null;
    return ArticleSuggestion.fromFirestore(doc, periodId);
  }

  // ==================== APPROVAL / REJECTION ====================

  /// Approve suggestion and convert to article
  Future<void> approveSuggestion(String periodId, String suggestionId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    final suggestionDoc = await _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .doc(suggestionId)
        .get();

    if (!suggestionDoc.exists) throw Exception('Suggestion not found');

    final suggestion = ArticleSuggestion.fromFirestore(suggestionDoc, periodId);
    if (!suggestion.isPending) throw Exception('Suggestion already reviewed');

    final batch = _db.batch();

    // Update suggestion status
    batch.update(suggestionDoc.reference, {
      'status': 'approved',
      'reviewerUid': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    // Create article from suggestion
    final articleRef = _db
        .collection('periods')
        .doc(periodId)
        .collection('articles')
        .doc();

    batch.set(articleRef, {
      'title': suggestion.title,
      'summary': suggestion.summary,
      'link': suggestion.link,
      'suggestedByUid': suggestion.submitterUid,
      'suggestedByDisplayName': suggestion.submitterDisplayName,
      'suggestionId': suggestionId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update community stats
    final weekDoc = await _db.collection('periods').doc(periodId).get();
    final communityId = weekDoc.data()?['communityId'];
    if (communityId != null) {
      batch.update(_db.collection('communities').doc(communityId), {
        'stats.totalArticles': FieldValue.increment(1),
      });
    }

    await batch.commit();

    // Notify submitter
    await _notificationService.createSuggestionApprovedNotification(
      targetUid: suggestion.submitterUid,
      suggestionTitle: suggestion.title,
      periodId: periodId,
    );
  }

  /// Reject suggestion
  Future<void> rejectSuggestion(String periodId, String suggestionId, {String? reason}) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    final suggestionDoc = await _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .doc(suggestionId)
        .get();

    if (!suggestionDoc.exists) throw Exception('Suggestion not found');

    final suggestion = ArticleSuggestion.fromFirestore(suggestionDoc, periodId);
    if (!suggestion.isPending) throw Exception('Suggestion already reviewed');

    await suggestionDoc.reference.update({
      'status': 'rejected',
      'reviewerUid': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      if (reason != null) 'rejectionReason': reason,
    });

    // Notify submitter
    await _notificationService.createSuggestionRejectedNotification(
      targetUid: suggestion.submitterUid,
      suggestionTitle: suggestion.title,
      periodId: periodId,
      reason: reason,
    );
  }

  // ==================== INTEREST VOTES ====================

  /// Toggle interest for a suggestion
  Future<void> toggleInterest(String periodId, String suggestionId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    final interestRef = _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .doc(suggestionId)
        .collection('interests')
        .doc(uid);

    final suggestionRef = _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .doc(suggestionId);

    final existing = await interestRef.get();

    final batch = _db.batch();

    if (existing.exists) {
      // Remove interest
      batch.delete(interestRef);
      batch.update(suggestionRef, {
        'interestScore': FieldValue.increment(-1),
      });
    } else {
      // Add interest
      batch.set(interestRef, {
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(suggestionRef, {
        'interestScore': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  /// Check if current user has expressed interest
  Stream<bool> hasExpressedInterest(String periodId, String suggestionId) {
    final uid = _currentUid;
    if (uid == null) return Stream.value(false);

    return _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .doc(suggestionId)
        .collection('interests')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get interest count for a suggestion
  Stream<int> getInterestCount(String periodId, String suggestionId) {
    return _db
        .collection('periods')
        .doc(periodId)
        .collection('suggestions')
        .doc(suggestionId)
        .collection('interests')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
