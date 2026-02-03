import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_badge.dart';
import '../models/contribution_score.dart';

/// Service for badge and contribution management (v8.0)
class BadgeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  // ==================== BADGE OPERATIONS ====================

  /// Get user's badges
  Future<List<UserBadge>> getUserBadges(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return [];

    final data = userDoc.data()!;
    final badgesData = data['badges'] as List<dynamic>? ?? [];

    return badgesData
        .map((b) => UserBadge.fromMap(b as Map<String, dynamic>))
        .toList();
  }

  /// Update user badges based on current stats
  /// Called after actions that could earn new badges
  Future<List<BadgeType>> updateUserBadges(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return [];

    final data = userDoc.data()!;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final contribution = ContributionScore.fromMap(data['contribution']);

    final joinedAt = (stats['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final totalComments = stats['totalComments'] ?? 0;
    final approvedSuggestions = contribution.approvedSuggestions;

    // Get current badges
    final currentBadgesData = data['badges'] as List<dynamic>? ?? [];
    final currentBadgeTypes = currentBadgesData
        .map((b) => BadgeType.fromString((b as Map<String, dynamic>)['type']))
        .whereType<BadgeType>()
        .toSet();

    // Get eligible badges
    final eligibleBadges = BadgeChecker.getEligibleBadges(
      joinedAt: joinedAt,
      totalComments: totalComments,
      approvedSuggestions: approvedSuggestions,
    );

    // Find new badges
    final newBadges = <BadgeType>[];
    final updatedBadgesList = <Map<String, dynamic>>[];

    for (final badge in eligibleBadges) {
      if (currentBadgeTypes.contains(badge)) {
        // Keep existing badge
        final existingBadge = currentBadgesData.firstWhere(
          (b) => (b as Map<String, dynamic>)['type'] == badge.name,
        );
        updatedBadgesList.add(existingBadge as Map<String, dynamic>);
      } else {
        // New badge earned
        newBadges.add(badge);
        updatedBadgesList.add(UserBadge(
          type: badge,
          earnedAt: DateTime.now(),
        ).toMap());
      }
    }

    // Update in Firestore if there are changes
    if (newBadges.isNotEmpty || updatedBadgesList.length != currentBadgesData.length) {
      await _db.collection('users').doc(uid).update({
        'badges': updatedBadgesList,
      });
    }

    return newBadges;
  }

  /// Get user's primary badge (highest priority)
  Future<BadgeType?> getPrimaryBadge(String uid) async {
    final badges = await getUserBadges(uid);
    if (badges.isEmpty) return null;

    badges.sort((a, b) => b.type.priority.compareTo(a.type.priority));
    return badges.first.type;
  }

  // ==================== CONTRIBUTION OPERATIONS ====================

  /// Get user's contribution score
  Future<ContributionScore> getContributionScore(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return const ContributionScore();

    final data = userDoc.data()!;
    return ContributionScore.fromMap(data['contribution']);
  }

  /// Increment contribution stats
  Future<void> incrementContribution({
    int comments = 0,
    int votes = 0,
    int suggestions = 0,
    int approvedSuggestions = 0,
    int receivedUpvotes = 0,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;

    final updates = <String, dynamic>{};
    if (comments > 0) updates['contribution.totalComments'] = FieldValue.increment(comments);
    if (votes > 0) updates['contribution.totalVotes'] = FieldValue.increment(votes);
    if (suggestions > 0) updates['contribution.totalSuggestions'] = FieldValue.increment(suggestions);
    if (approvedSuggestions > 0) {
      updates['contribution.approvedSuggestions'] = FieldValue.increment(approvedSuggestions);
    }
    if (receivedUpvotes > 0) {
      updates['contribution.receivedUpvotes'] = FieldValue.increment(receivedUpvotes);
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);

      // Check for new badges
      await updateUserBadges(uid);
    }
  }

  /// Get user's level info
  Future<({ContributionLevel level, int points, double progress})> getLevelInfo(String uid) async {
    final score = await getContributionScore(uid);
    return (
      level: score.level,
      points: score.totalPoints,
      progress: score.progressToNextLevel,
    );
  }

  // ==================== REALTIME STREAMS ====================

  /// Stream user's contribution score
  Stream<ContributionScore> streamContributionScore(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return const ContributionScore();
      return ContributionScore.fromMap(doc.data()?['contribution']);
    });
  }

  /// Stream user's badges
  Stream<List<UserBadge>> streamUserBadges(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      final badgesData = doc.data()?['badges'] as List<dynamic>? ?? [];
      return badgesData
          .map((b) => UserBadge.fromMap(b as Map<String, dynamic>))
          .toList();
    });
  }
}
