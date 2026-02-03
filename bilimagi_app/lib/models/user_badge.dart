/// User badge types and their conditions (v8.0)
enum BadgeType {
  newMember,    // 0-7 days since joining
  active,       // 10+ comments
  senior,       // 30+ days
  topContrib,   // 50+ comments
  helpful,      // 10+ approved suggestions
  veteran;      // 1+ year

  String get id => name;

  String get label {
    switch (this) {
      case BadgeType.newMember:
        return 'Yeni Uye';
      case BadgeType.active:
        return 'Aktif Uye';
      case BadgeType.senior:
        return 'Kidemli Uye';
      case BadgeType.topContrib:
        return 'En Cok Katki';
      case BadgeType.helpful:
        return 'Yardimci';
      case BadgeType.veteran:
        return 'Veteran';
    }
  }

  String get description {
    switch (this) {
      case BadgeType.newMember:
        return 'Yeni katildi';
      case BadgeType.active:
        return '10+ yorum yapti';
      case BadgeType.senior:
        return '30+ gundur uye';
      case BadgeType.topContrib:
        return '50+ yorum yapti';
      case BadgeType.helpful:
        return '10+ onaylanan oneri';
      case BadgeType.veteran:
        return '1+ yildir uye';
    }
  }

  String get emoji {
    switch (this) {
      case BadgeType.newMember:
        return '🌱';
      case BadgeType.active:
        return '🔥';
      case BadgeType.senior:
        return '⭐';
      case BadgeType.topContrib:
        return '🏆';
      case BadgeType.helpful:
        return '🤝';
      case BadgeType.veteran:
        return '👑';
    }
  }

  /// Badge priority (higher = more important)
  int get priority {
    switch (this) {
      case BadgeType.veteran:
        return 6;
      case BadgeType.topContrib:
        return 5;
      case BadgeType.helpful:
        return 4;
      case BadgeType.senior:
        return 3;
      case BadgeType.active:
        return 2;
      case BadgeType.newMember:
        return 1;
    }
  }

  static BadgeType? fromString(String? value) {
    if (value == null) return null;
    try {
      return BadgeType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}

/// User badge with earned date
class UserBadge {
  final BadgeType type;
  final DateTime earnedAt;

  const UserBadge({
    required this.type,
    required this.earnedAt,
  });

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      type: BadgeType.fromString(map['type']) ?? BadgeType.newMember,
      earnedAt: map['earnedAt'] != null
          ? DateTime.parse(map['earnedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'earnedAt': earnedAt.toIso8601String(),
    };
  }

  String get emoji => type.emoji;
  String get label => type.label;
  String get description => type.description;
}

/// Helper to check badge eligibility
class BadgeChecker {
  /// Check if user qualifies for a badge
  static bool checkEligibility({
    required BadgeType badge,
    required DateTime joinedAt,
    required int totalComments,
    required int approvedSuggestions,
  }) {
    final daysSinceJoin = DateTime.now().difference(joinedAt).inDays;

    switch (badge) {
      case BadgeType.newMember:
        return daysSinceJoin <= 7;
      case BadgeType.active:
        return totalComments >= 10;
      case BadgeType.senior:
        return daysSinceJoin >= 30;
      case BadgeType.topContrib:
        return totalComments >= 50;
      case BadgeType.helpful:
        return approvedSuggestions >= 10;
      case BadgeType.veteran:
        return daysSinceJoin >= 365;
    }
  }

  /// Get all badges a user qualifies for
  static List<BadgeType> getEligibleBadges({
    required DateTime joinedAt,
    required int totalComments,
    required int approvedSuggestions,
  }) {
    final eligible = <BadgeType>[];

    for (final badge in BadgeType.values) {
      if (checkEligibility(
        badge: badge,
        joinedAt: joinedAt,
        totalComments: totalComments,
        approvedSuggestions: approvedSuggestions,
      )) {
        eligible.add(badge);
      }
    }

    // Sort by priority (highest first)
    eligible.sort((a, b) => b.priority.compareTo(a.priority));

    return eligible;
  }
}
