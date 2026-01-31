import 'package:cloud_firestore/cloud_firestore.dart';

/// Member role in a community
enum MemberRole {
  owner,
  moderator,
  member;

  String get label {
    switch (this) {
      case MemberRole.owner:
        return 'Sahip';
      case MemberRole.moderator:
        return 'Moderatör';
      case MemberRole.member:
        return 'Üye';
    }
  }

  static MemberRole fromString(String value) {
    switch (value) {
      case 'owner':
        return MemberRole.owner;
      case 'moderator':
        return MemberRole.moderator;
      default:
        return MemberRole.member;
    }
  }
}

/// Membership status
enum MemberStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case MemberStatus.pending:
        return 'Onay Bekliyor';
      case MemberStatus.approved:
        return 'Onaylandı';
      case MemberStatus.rejected:
        return 'Reddedildi';
    }
  }

  static MemberStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return MemberStatus.approved;
      case 'rejected':
        return MemberStatus.rejected;
      default:
        return MemberStatus.pending;
    }
  }
}

class CommunityMembership {
  final String communityId;
  final String uid;
  final String displayName;
  final MemberRole role;
  final MemberStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final String? approvedByUid;

  CommunityMembership({
    required this.communityId,
    required this.uid,
    required this.displayName,
    required this.role,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.approvedByUid,
  });

  bool get isApproved => status == MemberStatus.approved;
  bool get isPending => status == MemberStatus.pending;
  bool get isOwner => role == MemberRole.owner;
  bool get isModerator => role == MemberRole.moderator;
  bool get canManageMembers => role == MemberRole.owner || role == MemberRole.moderator;

  factory CommunityMembership.fromFirestore(DocumentSnapshot doc, String communityId) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityMembership(
      communityId: communityId,
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      role: MemberRole.fromString(data['role'] ?? 'member'),
      status: MemberStatus.fromString(data['status'] ?? 'pending'),
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      approvedByUid: data['approvedByUid'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,  // Store uid as field for collectionGroup queries
      'displayName': displayName,
      'role': role.name,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (approvedByUid != null) 'approvedByUid': approvedByUid,
    };
  }

  CommunityMembership copyWith({
    MemberRole? role,
    MemberStatus? status,
    DateTime? approvedAt,
    String? approvedByUid,
  }) {
    return CommunityMembership(
      communityId: communityId,
      uid: uid,
      displayName: displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      requestedAt: requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedByUid: approvedByUid ?? this.approvedByUid,
    );
  }
}
