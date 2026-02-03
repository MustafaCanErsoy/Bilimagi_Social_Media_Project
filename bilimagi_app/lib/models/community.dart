import 'package:cloud_firestore/cloud_firestore.dart';

/// Join type for communities (v8.0)
enum JoinType {
  open,     // Anyone can join without approval
  approval; // Requires owner/mod approval

  String get label {
    switch (this) {
      case JoinType.open:
        return 'Acik Katilim';
      case JoinType.approval:
        return 'Onay Gerekli';
    }
  }

  String get description {
    switch (this) {
      case JoinType.open:
        return 'Herkes onay beklemeden katilabilir';
      case JoinType.approval:
        return 'Katilim icin sahip/moderator onayi gerekir';
    }
  }

  static JoinType fromString(String? value) {
    switch (value) {
      case 'open':
        return JoinType.open;
      case 'approval':
      default:
        return JoinType.approval;
    }
  }
}

/// Community categories (hybrid: fixed list + "other")
class CommunityCategory {
  static const String physics = 'physics';
  static const String biology = 'biology';
  static const String chemistry = 'chemistry';
  static const String mathematics = 'mathematics';
  static const String medicine = 'medicine';
  static const String engineering = 'engineering';
  static const String psychology = 'psychology';
  static const String other = 'other';

  static const Map<String, String> labels = {
    physics: 'Fizik',
    biology: 'Biyoloji',
    chemistry: 'Kimya',
    mathematics: 'Matematik',
    medicine: 'Tıp',
    engineering: 'Mühendislik',
    psychology: 'Psikoloji',
    other: 'Diğer',
  };

  static String getLabel(String category) {
    return labels[category] ?? category;
  }

  static List<String> get all => labels.keys.toList();
}

/// Community statistics
class CommunityStats {
  final int memberCount;
  final int periodCount;
  final int totalArticles;

  const CommunityStats({
    this.memberCount = 0,
    this.periodCount = 0,
    this.totalArticles = 0,
  });

  factory CommunityStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const CommunityStats();
    return CommunityStats(
      memberCount: data['memberCount'] ?? 0,
      // Support both old 'weekCount' and new 'periodCount'
      periodCount: data['periodCount'] ?? data['weekCount'] ?? 0,
      totalArticles: data['totalArticles'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberCount': memberCount,
      'periodCount': periodCount,
      'totalArticles': totalArticles,
    };
  }

  CommunityStats copyWith({
    int? memberCount,
    int? periodCount,
    int? totalArticles,
  }) {
    return CommunityStats(
      memberCount: memberCount ?? this.memberCount,
      periodCount: periodCount ?? this.periodCount,
      totalArticles: totalArticles ?? this.totalArticles,
    );
  }
}

class Community {
  final String id;
  final String name;
  final String description;
  final String ownerUid;
  final String? currentPeriodId;

  // v5.0 new fields
  final String category;
  final String? customCategory;
  final String? iconEmoji;
  final int colorIndex;
  final DateTime? createdAt;
  final bool isPublic;
  final CommunityStats stats;

  // v6.0: Soft delete
  final bool isDeleted;

  // v8.0: New fields
  final String? coverPhotoURL;
  final String? rules;
  final JoinType joinType;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerUid,
    this.currentPeriodId,
    this.category = CommunityCategory.other,
    this.customCategory,
    this.iconEmoji,
    this.colorIndex = 0,
    this.createdAt,
    this.isPublic = true,
    this.stats = const CommunityStats(),
    this.isDeleted = false,
    // v8.0
    this.coverPhotoURL,
    this.rules,
    this.joinType = JoinType.approval,
  });

  /// Get display category (uses customCategory if category is "other")
  String get displayCategory {
    if (category == CommunityCategory.other && customCategory != null) {
      return customCategory!;
    }
    return CommunityCategory.getLabel(category);
  }

  factory Community.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Community(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      // Support both old 'currentWeekId' and new 'currentPeriodId'
      currentPeriodId: data['currentPeriodId'] ?? data['currentWeekId'],
      category: data['category'] ?? CommunityCategory.other,
      customCategory: data['customCategory'],
      iconEmoji: data['iconEmoji'],
      colorIndex: data['colorIndex'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isPublic: data['isPublic'] ?? true,
      stats: CommunityStats.fromMap(data['stats']),
      isDeleted: data['isDeleted'] ?? false,
      // v8.0
      coverPhotoURL: data['coverPhotoURL'],
      rules: data['rules'],
      joinType: JoinType.fromString(data['joinType']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerUid': ownerUid,
      'currentPeriodId': currentPeriodId,
      'category': category,
      'customCategory': customCategory,
      'iconEmoji': iconEmoji,
      'colorIndex': colorIndex,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isPublic': isPublic,
      'stats': stats.toMap(),
      // v8.0
      if (coverPhotoURL != null) 'coverPhotoURL': coverPhotoURL,
      if (rules != null) 'rules': rules,
      'joinType': joinType.name,
    };
  }

  Community copyWith({
    String? name,
    String? description,
    String? currentPeriodId,
    String? category,
    String? customCategory,
    String? iconEmoji,
    int? colorIndex,
    bool? isPublic,
    CommunityStats? stats,
    // v8.0
    String? coverPhotoURL,
    String? rules,
    JoinType? joinType,
  }) {
    return Community(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerUid: ownerUid,
      currentPeriodId: currentPeriodId ?? this.currentPeriodId,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
      isPublic: isPublic ?? this.isPublic,
      stats: stats ?? this.stats,
      // v8.0
      coverPhotoURL: coverPhotoURL ?? this.coverPhotoURL,
      rules: rules ?? this.rules,
      joinType: joinType ?? this.joinType,
    );
  }
}
