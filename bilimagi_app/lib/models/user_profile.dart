import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final List<String> communityIds;

  // v2.0 fields
  final String? photoURL;
  final String? bio;
  final UserStats stats;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.communityIds,
    this.photoURL,
    this.bio,
    UserStats? stats,
  }) : stats = stats ?? UserStats();

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'member',
      communityIds: List<String>.from(data['communityIds'] ?? []),
      photoURL: data['photoURL'],
      bio: data['bio'],
      stats: data['stats'] != null
          ? UserStats.fromMap(data['stats'] as Map<String, dynamic>)
          : UserStats(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'communityIds': communityIds,
      if (photoURL != null) 'photoURL': photoURL,
      if (bio != null) 'bio': bio,
      'stats': stats.toMap(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    String? bio,
    List<String>? communityIds,
    UserStats? stats,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role,
      communityIds: communityIds ?? this.communityIds,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      stats: stats ?? this.stats,
    );
  }

  // Get avatar color based on UID (consistent color per user)
  int get avatarColorIndex {
    return uid.hashCode.abs() % 8;
  }
}

class UserStats {
  final int totalVotes;
  final int totalComments;
  final DateTime joinedAt;

  UserStats({
    this.totalVotes = 0,
    this.totalComments = 0,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalVotes: map['totalVotes'] ?? 0,
      totalComments: map['totalComments'] ?? 0,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalVotes': totalVotes,
      'totalComments': totalComments,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  UserStats copyWith({
    int? totalVotes,
    int? totalComments,
  }) {
    return UserStats(
      totalVotes: totalVotes ?? this.totalVotes,
      totalComments: totalComments ?? this.totalComments,
      joinedAt: joinedAt,
    );
  }
}
