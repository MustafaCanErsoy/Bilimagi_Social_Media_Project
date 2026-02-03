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

  // v7.2 fields
  final List<String> interests;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.communityIds,
    this.photoURL,
    this.bio,
    UserStats? stats,
    List<String>? interests,
  })  : stats = stats ?? UserStats(),
        interests = interests ?? [];

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
      interests: List<String>.from(data['interests'] ?? []),
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
      'interests': interests,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    String? bio,
    List<String>? communityIds,
    UserStats? stats,
    List<String>? interests,
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
      interests: interests ?? this.interests,
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
  // v3.0 fields
  final int followersCount;
  final int followingCount;

  UserStats({
    this.totalVotes = 0,
    this.totalComments = 0,
    DateTime? joinedAt,
    this.followersCount = 0,
    this.followingCount = 0,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalVotes: map['totalVotes'] ?? 0,
      totalComments: map['totalComments'] ?? 0,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalVotes': totalVotes,
      'totalComments': totalComments,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }

  UserStats copyWith({
    int? totalVotes,
    int? totalComments,
    int? followersCount,
    int? followingCount,
  }) {
    return UserStats(
      totalVotes: totalVotes ?? this.totalVotes,
      totalComments: totalComments ?? this.totalComments,
      joinedAt: joinedAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}
