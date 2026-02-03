import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community.dart';
import '../models/community_membership.dart';
import 'notification_service.dart';

class CommunityService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _notificationService = NotificationService();

  String? get _currentUid => _auth.currentUser?.uid;

  // ==================== COMMUNITY CRUD ====================

  /// Create a new community
  Future<String> createCommunity({
    required String name,
    required String description,
    required String category,
    String? customCategory,
    String? iconEmoji,
    int colorIndex = 0,
    JoinType joinType = JoinType.approval,
    String? coverPhotoURL,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final communityRef = _db.collection('communities').doc();
    final community = Community(
      id: communityRef.id,
      name: name,
      description: description,
      ownerUid: uid,
      category: category,
      customCategory: customCategory,
      iconEmoji: iconEmoji,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
      isPublic: true,
      stats: const CommunityStats(memberCount: 1),
      joinType: joinType,
      coverPhotoURL: coverPhotoURL,
    );

    final batch = _db.batch();

    // Create community
    batch.set(communityRef, community.toFirestore());

    // Add owner as first member (auto-approved)
    final memberRef = communityRef.collection('members').doc(uid);
    batch.set(memberRef, CommunityMembership(
      communityId: communityRef.id,
      uid: uid,
      displayName: displayName,
      role: MemberRole.owner,
      status: MemberStatus.approved,
      requestedAt: DateTime.now(),
      approvedAt: DateTime.now(),
    ).toFirestore());

    await batch.commit();
    return communityRef.id;
  }

  /// Update community details
  Future<void> updateCommunity(String communityId, {
    String? name,
    String? description,
    String? category,
    String? customCategory,
    String? iconEmoji,
    int? colorIndex,
    // v8.0 fields
    JoinType? joinType,
    String? coverPhotoURL,
    String? rules,
    bool clearCoverPhoto = false,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Check permission (owner or moderator)
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.canManageMembers) {
      throw Exception('Not authorized');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (category != null) updates['category'] = category;
    if (customCategory != null) updates['customCategory'] = customCategory;
    if (iconEmoji != null) updates['iconEmoji'] = iconEmoji;
    if (colorIndex != null) updates['colorIndex'] = colorIndex;
    // v8.0
    if (joinType != null) updates['joinType'] = joinType.name;
    if (coverPhotoURL != null) updates['coverPhotoURL'] = coverPhotoURL;
    if (clearCoverPhoto) updates['coverPhotoURL'] = FieldValue.delete();
    if (rules != null) updates['rules'] = rules;

    if (updates.isNotEmpty) {
      await _db.collection('communities').doc(communityId).update(updates);
    }
  }

  /// Delete community (soft delete)
  Future<void> deleteCommunity(String communityId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Only owner can delete
    final community = await getCommunityOnce(communityId);
    if (community == null || community.ownerUid != uid) {
      throw Exception('Not authorized');
    }

    await _db.collection('communities').doc(communityId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== COMMUNITY QUERIES ====================

  /// Get single community (stream) - returns null if deleted
  Stream<Community?> getCommunity(String communityId) {
    return _db.collection('communities').doc(communityId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final community = Community.fromFirestore(doc);
      if (community.isDeleted) return null;
      return community;
    });
  }

  /// Get single community once - returns null if deleted
  Future<Community?> getCommunityOnce(String communityId) async {
    final doc = await _db.collection('communities').doc(communityId).get();
    if (!doc.exists) return null;
    final community = Community.fromFirestore(doc);
    if (community.isDeleted) return null;
    return community;
  }

  /// Get all public communities (excludes deleted)
  Stream<List<Community>> getPublicCommunities() {
    return _db
        .collection('communities')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Community.fromFirestore(doc))
            .where((c) => c.isPublic && !c.isDeleted)
            .toList());
  }

  /// Get communities where user is a member (excludes deleted)
  Stream<List<Community>> getUserCommunities(String uid) {
    return _db
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .asyncMap((snapshot) async {
      final communities = <Community>[];
      for (final doc in snapshot.docs) {
        final communityId = doc.reference.parent.parent?.id;
        if (communityId != null) {
          final communityDoc = await _db.collection('communities').doc(communityId).get();
          if (communityDoc.exists) {
            final community = Community.fromFirestore(communityDoc);
            // Filter out deleted communities
            if (!community.isDeleted) {
              communities.add(community);
            }
          }
        }
      }
      return communities;
    });
  }

  // ==================== SEARCH & FILTER ====================

  /// Sort options for communities
  static const String sortByPopular = 'popular';
  static const String sortByNewest = 'newest';
  static const String sortByName = 'name';

  /// Filter and sort communities (client-side)
  List<Community> filterCommunities({
    required List<Community> communities,
    String? searchQuery,
    String? category,
    String sortBy = sortByPopular,
  }) {
    var filtered = communities.toList();

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query) ||
            c.displayCategory.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filter
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((c) => c.category == category).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case sortByPopular:
        filtered.sort((a, b) => b.stats.memberCount.compareTo(a.stats.memberCount));
        break;
      case sortByNewest:
        filtered.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(2000);
          final bDate = b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
      case sortByName:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return filtered;
  }

  // ==================== MEMBERSHIP OPERATIONS ====================

  /// Request membership (creates pending or approved entry based on JoinType)
  Future<void> requestMembership(String communityId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    final userDoc = await _db.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'Anonim';

    final memberRef = _db.collection('communities').doc(communityId).collection('members').doc(uid);
    final existing = await memberRef.get();

    if (existing.exists) {
      final status = existing.data()?['status'];
      if (status == 'approved') throw Exception('Already a member');
      if (status == 'pending') throw Exception('Request already pending');
    }

    // Check community join type (v8.0)
    final community = await getCommunityOnce(communityId);
    if (community == null) throw Exception('Community not found');

    final isOpenJoin = community.joinType == JoinType.open;

    if (isOpenJoin) {
      // Direct join without approval
      final batch = _db.batch();

      batch.set(memberRef, CommunityMembership(
        communityId: communityId,
        uid: uid,
        displayName: displayName,
        role: MemberRole.member,
        status: MemberStatus.approved,
        requestedAt: DateTime.now(),
        approvedAt: DateTime.now(),
      ).toFirestore());

      // Increment member count
      batch.update(_db.collection('communities').doc(communityId), {
        'stats.memberCount': FieldValue.increment(1),
      });

      await batch.commit();
    } else {
      // Requires approval
      await memberRef.set(CommunityMembership(
        communityId: communityId,
        uid: uid,
        displayName: displayName,
        role: MemberRole.member,
        status: MemberStatus.pending,
        requestedAt: DateTime.now(),
      ).toFirestore());

      // Notify owner and moderators
      await _notifyMembershipRequest(communityId, displayName);
    }
  }

  /// Approve membership request
  Future<void> approveMembership(String communityId, String targetUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Check permission
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.canManageMembers) {
      throw Exception('Not authorized');
    }

    final batch = _db.batch();

    // Update member status
    final memberRef = _db.collection('communities').doc(communityId).collection('members').doc(targetUid);
    batch.update(memberRef, {
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedByUid': uid,
    });

    // Increment member count
    final communityRef = _db.collection('communities').doc(communityId);
    batch.update(communityRef, {
      'stats.memberCount': FieldValue.increment(1),
    });

    await batch.commit();

    // Notify the user
    final community = await getCommunityOnce(communityId);
    if (community != null) {
      await _notificationService.createMembershipApprovedNotification(
        targetUid: targetUid,
        communityId: communityId,
        communityName: community.name,
      );
    }
  }

  /// Reject membership request
  Future<void> rejectMembership(String communityId, String targetUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Check permission
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.canManageMembers) {
      throw Exception('Not authorized');
    }

    await _db.collection('communities').doc(communityId).collection('members').doc(targetUid).update({
      'status': 'rejected',
    });

    // Notify the user
    final community = await getCommunityOnce(communityId);
    if (community != null) {
      await _notificationService.createMembershipRejectedNotification(
        targetUid: targetUid,
        communityId: communityId,
        communityName: community.name,
      );
    }
  }

  /// Leave community
  Future<void> leaveCommunity(String communityId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    final membership = await _getMembership(communityId, uid);
    if (membership == null) throw Exception('Not a member');
    if (membership.isOwner) throw Exception('Owner cannot leave');

    final batch = _db.batch();

    // Remove member
    final memberRef = _db.collection('communities').doc(communityId).collection('members').doc(uid);
    batch.delete(memberRef);

    // Decrement member count if was approved
    if (membership.isApproved) {
      final communityRef = _db.collection('communities').doc(communityId);
      batch.update(communityRef, {
        'stats.memberCount': FieldValue.increment(-1),
      });
    }

    await batch.commit();
  }

  /// Remove a member (owner/mod only)
  Future<void> removeMember(String communityId, String targetUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Check permission
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.canManageMembers) {
      throw Exception('Not authorized');
    }

    // Cannot remove owner
    final targetMembership = await _getMembership(communityId, targetUid);
    if (targetMembership?.isOwner == true) {
      throw Exception('Cannot remove owner');
    }

    final batch = _db.batch();

    final memberRef = _db.collection('communities').doc(communityId).collection('members').doc(targetUid);
    batch.delete(memberRef);

    if (targetMembership?.isApproved == true) {
      final communityRef = _db.collection('communities').doc(communityId);
      batch.update(communityRef, {
        'stats.memberCount': FieldValue.increment(-1),
      });
    }

    await batch.commit();

    // Notify the removed user
    final community = await getCommunityOnce(communityId);
    if (community != null) {
      await _notificationService.createMemberRemovedNotification(
        targetUid: targetUid,
        communityId: communityId,
        communityName: community.name,
      );
    }
  }

  /// Set member role (owner only)
  Future<void> setMemberRole(String communityId, String targetUid, MemberRole newRole) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Only owner can change roles
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.isOwner) {
      throw Exception('Only owner can change roles');
    }

    // Cannot change owner's role (transfer ownership not implemented yet)
    final targetMembership = await _getMembership(communityId, targetUid);
    if (targetMembership?.isOwner == true) {
      throw Exception('Cannot change owner role');
    }

    await _db.collection('communities').doc(communityId).collection('members').doc(targetUid).update({
      'role': newRole.name,
    });

    // Notify the user about role change
    final community = await getCommunityOnce(communityId);
    if (community != null) {
      await _notificationService.createRoleChangedNotification(
        targetUid: targetUid,
        communityId: communityId,
        communityName: community.name,
        newRole: newRole.name,
      );
    }
  }

  // ==================== MEMBERSHIP QUERIES ====================

  /// Get approved members
  Stream<List<CommunityMembership>> getMembers(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityMembership.fromFirestore(doc, communityId))
            .toList());
  }

  /// Get pending membership requests
  Stream<List<CommunityMembership>> getPendingMembers(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CommunityMembership.fromFirestore(doc, communityId))
          .toList();
      // Sort in memory instead of Firestore (avoids index requirement)
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  /// Get current user's role in community
  Stream<MemberRole?> getUserRole(String communityId) {
    final uid = _currentUid;
    if (uid == null) return Stream.value(null);

    return _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final status = doc.data()?['status'];
      if (status != 'approved') return null;
      return MemberRole.fromString(doc.data()?['role'] ?? 'member');
    });
  }

  /// Get current user's membership status
  Stream<MemberStatus?> getMembershipStatus(String communityId) {
    final uid = _currentUid;
    if (uid == null) return Stream.value(null);

    return _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return MemberStatus.fromString(doc.data()?['status'] ?? 'pending');
    });
  }

  /// Get pending member count (for badge)
  Stream<int> getPendingMemberCount(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==================== PERIOD MANAGEMENT ====================

  /// Create a new period for community (v8.0 - replaces createNewWeek)
  Future<String> createNewPeriod({
    required String communityId,
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int minVotesForDiscussion = 1,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not logged in');

    // Check permission
    final membership = await _getMembership(communityId, uid);
    if (membership == null || !membership.canManageMembers) {
      throw Exception('Not authorized');
    }

    final periodRef = _db.collection('periods').doc();
    final batch = _db.batch();

    batch.set(periodRef, {
      'communityId': communityId,
      'title': title,
      if (description != null) 'description': description,
      'phase': 'voting',
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate),
      'minVotesForDiscussion': minVotesForDiscussion,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('communities').doc(communityId), {
      'currentPeriodId': periodRef.id,
      'stats.periodCount': FieldValue.increment(1),
    });

    await batch.commit();
    return periodRef.id;
  }

  // ==================== PRIVATE HELPERS ====================

  Future<CommunityMembership?> _getMembership(String communityId, String uid) async {
    final doc = await _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return CommunityMembership.fromFirestore(doc, communityId);
  }

  Future<void> _notifyMembershipRequest(String communityId, String fromDisplayName) async {
    // Get owner and moderators
    final members = await _db
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('status', isEqualTo: 'approved')
        .where('role', whereIn: ['owner', 'moderator'])
        .get();

    final community = await getCommunityOnce(communityId);

    for (final doc in members.docs) {
      final targetUid = doc.id;
      await _notificationService.createMembershipRequestNotification(
        targetUid: targetUid,
        fromDisplayName: fromDisplayName,
        communityId: communityId,
        communityName: community?.name ?? '',
      );
    }
  }
}
