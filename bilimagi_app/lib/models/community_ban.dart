import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a banned user in a community
class CommunityBan {
  final String communityId;
  final String bannedUid;
  final String bannedDisplayName;
  final String bannedByUid;
  final String bannedByDisplayName;
  final DateTime bannedAt;
  final DateTime? expiresAt; // null = permanent ban
  final String reason;

  const CommunityBan({
    required this.communityId,
    required this.bannedUid,
    required this.bannedDisplayName,
    required this.bannedByUid,
    required this.bannedByDisplayName,
    required this.bannedAt,
    this.expiresAt,
    required this.reason,
  });

  /// Check if ban is still active
  bool get isActive {
    if (expiresAt == null) return true; // Permanent ban
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Check if ban is permanent
  bool get isPermanent => expiresAt == null;

  factory CommunityBan.fromFirestore(DocumentSnapshot doc, String communityId) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityBan(
      communityId: communityId,
      bannedUid: doc.id,
      bannedDisplayName: data['bannedDisplayName'] ?? 'Bilinmeyen',
      bannedByUid: data['bannedByUid'] ?? '',
      bannedByDisplayName: data['bannedByDisplayName'] ?? 'Bilinmeyen',
      bannedAt: (data['bannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      reason: data['reason'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bannedDisplayName': bannedDisplayName,
      'bannedByUid': bannedByUid,
      'bannedByDisplayName': bannedByDisplayName,
      'bannedAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'reason': reason,
    };
  }
}
