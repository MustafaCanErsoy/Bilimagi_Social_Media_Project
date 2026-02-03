/// Contribution level system (v8.0)
enum ContributionLevel {
  level1,
  level2,
  level3,
  level4,
  level5,
  level6;

  int get minPoints {
    switch (this) {
      case ContributionLevel.level1:
        return 0;
      case ContributionLevel.level2:
        return 50;
      case ContributionLevel.level3:
        return 150;
      case ContributionLevel.level4:
        return 350;
      case ContributionLevel.level5:
        return 700;
      case ContributionLevel.level6:
        return 1500;
    }
  }

  int? get maxPoints {
    switch (this) {
      case ContributionLevel.level1:
        return 49;
      case ContributionLevel.level2:
        return 149;
      case ContributionLevel.level3:
        return 349;
      case ContributionLevel.level4:
        return 699;
      case ContributionLevel.level5:
        return 1499;
      case ContributionLevel.level6:
        return null; // No limit
    }
  }

  String get name {
    switch (this) {
      case ContributionLevel.level1:
        return 'Baslangic';
      case ContributionLevel.level2:
        return 'Merakli';
      case ContributionLevel.level3:
        return 'Kesfedici';
      case ContributionLevel.level4:
        return 'Uzman';
      case ContributionLevel.level5:
        return 'Usta';
      case ContributionLevel.level6:
        return 'Bilge';
    }
  }

  String get emoji {
    switch (this) {
      case ContributionLevel.level1:
        return '🌱';
      case ContributionLevel.level2:
        return '🔍';
      case ContributionLevel.level3:
        return '🧭';
      case ContributionLevel.level4:
        return '🎯';
      case ContributionLevel.level5:
        return '🌟';
      case ContributionLevel.level6:
        return '🧠';
    }
  }

  int get levelNumber {
    return index + 1;
  }

  /// Get next level (null if max)
  ContributionLevel? get nextLevel {
    if (index < ContributionLevel.values.length - 1) {
      return ContributionLevel.values[index + 1];
    }
    return null;
  }

  /// Get level from points
  static ContributionLevel fromPoints(int points) {
    for (int i = ContributionLevel.values.length - 1; i >= 0; i--) {
      if (points >= ContributionLevel.values[i].minPoints) {
        return ContributionLevel.values[i];
      }
    }
    return ContributionLevel.level1;
  }
}

/// Contribution score calculator
class ContributionScore {
  /// Points per action
  static const int pointsPerComment = 5;
  static const int pointsPerVote = 1;
  static const int pointsPerSuggestion = 10;
  static const int pointsPerApprovedSuggestion = 25;
  static const int pointsPerReceivedUpvote = 2;

  final int totalComments;
  final int totalVotes;
  final int totalSuggestions;
  final int approvedSuggestions;
  final int receivedUpvotes;

  const ContributionScore({
    this.totalComments = 0,
    this.totalVotes = 0,
    this.totalSuggestions = 0,
    this.approvedSuggestions = 0,
    this.receivedUpvotes = 0,
  });

  /// Calculate total contribution points
  int get totalPoints {
    return (totalComments * pointsPerComment) +
        (totalVotes * pointsPerVote) +
        (totalSuggestions * pointsPerSuggestion) +
        (approvedSuggestions * pointsPerApprovedSuggestion) +
        (receivedUpvotes * pointsPerReceivedUpvote);
  }

  /// Get current level
  ContributionLevel get level => ContributionLevel.fromPoints(totalPoints);

  /// Get progress to next level (0.0 - 1.0)
  double get progressToNextLevel {
    final currentLevel = level;
    final nextLevel = currentLevel.nextLevel;

    if (nextLevel == null) {
      return 1.0; // Max level reached
    }

    final currentMin = currentLevel.minPoints;
    final nextMin = nextLevel.minPoints;
    final progress = (totalPoints - currentMin) / (nextMin - currentMin);

    return progress.clamp(0.0, 1.0);
  }

  /// Points needed for next level
  int? get pointsToNextLevel {
    final nextLevel = level.nextLevel;
    if (nextLevel == null) return null;
    return nextLevel.minPoints - totalPoints;
  }

  factory ContributionScore.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ContributionScore();
    return ContributionScore(
      totalComments: map['totalComments'] ?? 0,
      totalVotes: map['totalVotes'] ?? 0,
      totalSuggestions: map['totalSuggestions'] ?? 0,
      approvedSuggestions: map['approvedSuggestions'] ?? 0,
      receivedUpvotes: map['receivedUpvotes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalComments': totalComments,
      'totalVotes': totalVotes,
      'totalSuggestions': totalSuggestions,
      'approvedSuggestions': approvedSuggestions,
      'receivedUpvotes': receivedUpvotes,
    };
  }

  ContributionScore copyWith({
    int? totalComments,
    int? totalVotes,
    int? totalSuggestions,
    int? approvedSuggestions,
    int? receivedUpvotes,
  }) {
    return ContributionScore(
      totalComments: totalComments ?? this.totalComments,
      totalVotes: totalVotes ?? this.totalVotes,
      totalSuggestions: totalSuggestions ?? this.totalSuggestions,
      approvedSuggestions: approvedSuggestions ?? this.approvedSuggestions,
      receivedUpvotes: receivedUpvotes ?? this.receivedUpvotes,
    );
  }
}
