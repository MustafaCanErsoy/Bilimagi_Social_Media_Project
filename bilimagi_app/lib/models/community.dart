import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int weekCount;
  final int totalArticles;

  const CommunityStats({
    this.memberCount = 0,
    this.weekCount = 0,
    this.totalArticles = 0,
  });

  factory CommunityStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const CommunityStats();
    return CommunityStats(
      memberCount: data['memberCount'] ?? 0,
      weekCount: data['weekCount'] ?? 0,
      totalArticles: data['totalArticles'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberCount': memberCount,
      'weekCount': weekCount,
      'totalArticles': totalArticles,
    };
  }

  CommunityStats copyWith({
    int? memberCount,
    int? weekCount,
    int? totalArticles,
  }) {
    return CommunityStats(
      memberCount: memberCount ?? this.memberCount,
      weekCount: weekCount ?? this.weekCount,
      totalArticles: totalArticles ?? this.totalArticles,
    );
  }
}

class Community {
  final String id;
  final String name;
  final String description;
  final String ownerUid;
  final String? currentWeekId;

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

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerUid,
    this.currentWeekId,
    this.category = CommunityCategory.other,
    this.customCategory,
    this.iconEmoji,
    this.colorIndex = 0,
    this.createdAt,
    this.isPublic = true,
    this.stats = const CommunityStats(),
    this.isDeleted = false,
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
      currentWeekId: data['currentWeekId'],
      category: data['category'] ?? CommunityCategory.other,
      customCategory: data['customCategory'],
      iconEmoji: data['iconEmoji'],
      colorIndex: data['colorIndex'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isPublic: data['isPublic'] ?? true,
      stats: CommunityStats.fromMap(data['stats']),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerUid': ownerUid,
      'currentWeekId': currentWeekId,
      'category': category,
      'customCategory': customCategory,
      'iconEmoji': iconEmoji,
      'colorIndex': colorIndex,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isPublic': isPublic,
      'stats': stats.toMap(),
    };
  }

  Community copyWith({
    String? name,
    String? description,
    String? currentWeekId,
    String? category,
    String? customCategory,
    String? iconEmoji,
    int? colorIndex,
    bool? isPublic,
    CommunityStats? stats,
  }) {
    return Community(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerUid: ownerUid,
      currentWeekId: currentWeekId ?? this.currentWeekId,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
      isPublic: isPublic ?? this.isPublic,
      stats: stats ?? this.stats,
    );
  }
}
