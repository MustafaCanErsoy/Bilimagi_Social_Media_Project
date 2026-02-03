import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poll.dart';
import '../models/community_membership.dart';

/// Service for community polls (v8.0)
class PollService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  // ==================== CRUD OPERATIONS ====================

  /// Create a new poll
  Future<String> createPoll({
    required String communityId,
    required String question,
    required List<String> options,
    DateTime? endsAt,
    bool allowMultiple = false,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final pollRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('polls')
        .doc();

    // Create poll options with unique IDs
    final pollOptions = options.asMap().entries.map((e) {
      return PollOption(
        id: 'option_${e.key}',
        text: e.value,
        voteCount: 0,
      );
    }).toList();

    final poll = Poll(
      id: pollRef.id,
      communityId: communityId,
      question: question,
      options: pollOptions,
      authorUid: uid,
      authorDisplayName: displayName,
      createdAt: DateTime.now(),
      endsAt: endsAt,
      allowMultiple: allowMultiple,
    );

    await pollRef.set(poll.toFirestore());

    return pollRef.id;
  }

  /// Close a poll
  Future<void> closePoll(String communityId, String pollId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    await _db
        .collection('communities')
        .doc(communityId)
        .collection('polls')
        .doc(pollId)
        .update({'status': PollStatus.closed.name});
  }

  /// Delete a poll
  Future<void> deletePoll(String communityId, String pollId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    // Delete all votes first
    final votesSnapshot = await _db
        .collection('communities')
        .doc(communityId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .get();

    final batch = _db.batch();
    for (final doc in votesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the poll
    batch.delete(_db
        .collection('communities')
        .doc(communityId)
        .collection('polls')
        .doc(pollId));

    await batch.commit();
  }

  // ==================== VOTING ====================

  /// Vote on a poll
  Future<void> vote({
    required String communityId,
    required String pollId,
    required List<String> optionIds,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    // Check if user is a member
    final memberDoc = await _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(uid)
        .get();

    if (!memberDoc.exists || memberDoc.data()?['status'] != 'approved') {
      throw Exception('Sadece uyeler oy kullanabilir');
    }

    final pollRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('polls')
        .doc(pollId);

    final pollDoc = await pollRef.get();
    if (!pollDoc.exists) throw Exception('Anket bulunamadi');

    final poll = Poll.fromFirestore(pollDoc);

    if (!poll.isActive) {
      throw Exception('Anket kapali');
    }

    if (!poll.allowMultiple && optionIds.length > 1) {
      throw Exception('Bu ankette sadece bir secenek secilebilir');
    }

    // Check for existing vote
    final voteRef = pollRef.collection('votes').doc(uid);
    final existingVote = await voteRef.get();

    final batch = _db.batch();

    if (existingVote.exists) {
      // Remove old vote counts
      final oldOptionIds = List<String>.from(existingVote.data()?['optionIds'] ?? []);
      final newOptions = poll.options.map((option) {
        if (oldOptionIds.contains(option.id)) {
          return option.copyWith(voteCount: option.voteCount - 1);
        }
        return option;
      }).toList();

      // Add new vote counts
      final updatedOptions = newOptions.map((option) {
        if (optionIds.contains(option.id)) {
          return option.copyWith(voteCount: option.voteCount + 1);
        }
        return option;
      }).toList();

      batch.update(pollRef, {
        'options': updatedOptions.map((o) => o.toMap()).toList(),
      });
    } else {
      // New vote
      final updatedOptions = poll.options.map((option) {
        if (optionIds.contains(option.id)) {
          return option.copyWith(voteCount: option.voteCount + 1);
        }
        return option;
      }).toList();

      batch.update(pollRef, {
        'options': updatedOptions.map((o) => o.toMap()).toList(),
        'totalVotes': FieldValue.increment(1),
      });
    }

    // Save vote
    batch.set(voteRef, PollVote(
      odUid: uid,
      optionIds: optionIds,
      votedAt: DateTime.now(),
    ).toFirestore());

    await batch.commit();
  }

  /// Get user's vote on a poll
  Future<PollVote?> getUserVote(String communityId, String pollId) async {
    final uid = _currentUid;
    if (uid == null) return null;

    final voteDoc = await _db
        .collection('communities')
        .doc(communityId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(uid)
        .get();

    if (!voteDoc.exists) return null;
    return PollVote.fromFirestore(voteDoc);
  }

  // ==================== QUERIES ====================

  /// Get active polls for a community (stream)
  Stream<List<Poll>> getActivePolls(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('polls')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Poll.fromFirestore(doc))
          .where((p) => p.isActive)
          .toList();
    });
  }

  /// Get all polls (for management)
  Stream<List<Poll>> getAllPolls(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList());
  }

  /// Get single poll (stream)
  Stream<Poll?> getPoll(String communityId, String pollId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('polls')
        .doc(pollId)
        .snapshots()
        .map((doc) => doc.exists ? Poll.fromFirestore(doc) : null);
  }

  // ==================== HELPERS ====================

  Future<void> _checkPermission(String communityId, String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.data()?['role'] == 'admin') return;

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
