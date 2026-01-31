import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class MentionService {
  final _firestore = FirebaseFirestore.instance;

  /// Search users by display name (for @autocomplete)
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    // Get all users and filter client-side (simple approach)
    // For production, use Algolia or Firebase Extensions
    final snapshot = await _firestore
        .collection('users')
        .limit(50)
        .get();

    final queryLower = query.toLowerCase();

    return snapshot.docs
        .map((doc) => UserProfile.fromFirestore(doc))
        .where((user) =>
            user.displayName.toLowerCase().contains(queryLower))
        .take(5)
        .toList();
  }

  /// Parse mentions from text (returns list of userIds)
  /// Format: @[displayName](userId)
  static List<String> parseMentions(String text) {
    final regex = RegExp(r'@\[([^\]]+)\]\(([^)]+)\)');
    final matches = regex.allMatches(text);

    return matches.map((m) => m.group(2)!).toList();
  }

  /// Convert display format to storage format
  /// Input: "@Ahmet Yılmaz" with userId
  /// Output: "@[Ahmet Yılmaz](userId)"
  static String formatMention(String displayName, String userId) {
    return '@[$displayName]($userId)';
  }

  /// Get display text from storage format (for rendering)
  /// Converts "@[Ahmet Yılmaz](userId)" to "@Ahmet Yılmaz"
  static String getDisplayText(String text) {
    final regex = RegExp(r'@\[([^\]]+)\]\([^)]+\)');
    return text.replaceAllMapped(regex, (match) => '@${match.group(1)}');
  }

  /// Parse text and return segments for rich rendering
  /// Returns list of MentionSegment for building RichText
  static List<MentionSegment> parseTextSegments(String text) {
    final segments = <MentionSegment>[];
    final regex = RegExp(r'@\[([^\]]+)\]\(([^)]+)\)');

    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before mention
      if (match.start > lastEnd) {
        segments.add(MentionSegment(
          text: text.substring(lastEnd, match.start),
          isMention: false,
        ));
      }

      // Add mention
      segments.add(MentionSegment(
        text: '@${match.group(1)}',
        isMention: true,
        userId: match.group(2),
        displayName: match.group(1),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      segments.add(MentionSegment(
        text: text.substring(lastEnd),
        isMention: false,
      ));
    }

    return segments;
  }
}

class MentionSegment {
  final String text;
  final bool isMention;
  final String? userId;
  final String? displayName;

  MentionSegment({
    required this.text,
    required this.isMention,
    this.userId,
    this.displayName,
  });
}
