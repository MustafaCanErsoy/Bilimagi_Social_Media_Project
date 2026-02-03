import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/announcement.dart';
import '../models/community_membership.dart';

/// Service for community announcements (v8.0)
class AnnouncementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  // ==================== CRUD OPERATIONS ====================

  /// Create a new announcement
  Future<String> createAnnouncement({
    required String communityId,
    required String title,
    required String content,
    DateTime? expiresAt,
    bool isPinned = false,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final announcementRef = _db
        .collection('communities')
        .doc(communityId)
        .collection('announcements')
        .doc();

    final announcement = Announcement(
      id: announcementRef.id,
      communityId: communityId,
      title: title,
      content: content,
      authorUid: uid,
      authorDisplayName: displayName,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      isPinned: isPinned,
    );

    await announcementRef.set(announcement.toFirestore());

    return announcementRef.id;
  }

  /// Update an announcement
  Future<void> updateAnnouncement({
    required String communityId,
    required String announcementId,
    String? title,
    String? content,
    DateTime? expiresAt,
    bool? isPinned,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;
    if (expiresAt != null) updates['expiresAt'] = Timestamp.fromDate(expiresAt);
    if (isPinned != null) updates['isPinned'] = isPinned;

    if (updates.isNotEmpty) {
      await _db
          .collection('communities')
          .doc(communityId)
          .collection('announcements')
          .doc(announcementId)
          .update(updates);
    }
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String communityId, String announcementId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    await _checkPermission(communityId, uid);

    await _db
        .collection('communities')
        .doc(communityId)
        .collection('announcements')
        .doc(announcementId)
        .delete();
  }

  // ==================== QUERIES ====================

  /// Get active announcements for a community (stream)
  Stream<List<Announcement>> getActiveAnnouncements(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .where((a) => a.isActive)
          .toList();
    });
  }

  /// Get pinned announcements
  Stream<List<Announcement>> getPinnedAnnouncements(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('announcements')
        .where('isPinned', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .where((a) => a.isActive)
          .toList();
    });
  }

  /// Get all announcements (for management)
  Stream<List<Announcement>> getAllAnnouncements(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Announcement.fromFirestore(doc)).toList());
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
