import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/mention_service.dart';
import '../core/theme.dart';
import '../core/avatar_colors.dart';

/// Mention autocomplete controller for managing mention state
class MentionAutocompleteController {
  final TextEditingController textController;
  final Map<String, String> mentionedUsers = {};

  bool showSuggestions = false;
  List<UserProfile> suggestions = [];
  String query = '';
  int mentionStartIndex = -1;

  final MentionService _mentionService = MentionService();
  VoidCallback? _onStateChanged;

  MentionAutocompleteController({required this.textController}) {
    textController.addListener(_onTextChanged);
  }

  void setStateCallback(VoidCallback callback) {
    _onStateChanged = callback;
  }

  void dispose() {
    textController.removeListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = textController.text;
    final selection = textController.selection;

    if (!selection.isValid || selection.start != selection.end) {
      _hideSuggestions();
      return;
    }

    final cursorPos = selection.start;
    final textBeforeCursor = text.substring(0, cursorPos);

    // Find last @ before cursor
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) {
      _hideSuggestions();
      return;
    }

    // Check if there's a space between @ and cursor
    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
      _hideSuggestions();
      return;
    }

    // We have a potential mention
    mentionStartIndex = lastAtIndex;
    query = textAfterAt;
    _searchMentions(textAfterAt);
  }

  Future<void> _searchMentions(String searchQuery) async {
    if (searchQuery.isEmpty) {
      showSuggestions = true;
      suggestions = [];
      _onStateChanged?.call();
      return;
    }

    try {
      final results = await _mentionService.searchUsers(searchQuery);
      if (query == searchQuery) {
        showSuggestions = true;
        suggestions = results;
        _onStateChanged?.call();
      }
    } catch (e) {
      // Ignore search errors
    }
  }

  void _hideSuggestions() {
    if (showSuggestions) {
      showSuggestions = false;
      suggestions = [];
      mentionStartIndex = -1;
      _onStateChanged?.call();
    }
  }

  void insertMention(UserProfile user) {
    final text = textController.text;
    final cursorPos = textController.selection.start;

    // Store the mention mapping
    mentionedUsers[user.displayName] = user.uid;

    // Replace @query with @displayName
    final beforeMention = text.substring(0, mentionStartIndex);
    final afterMention = text.substring(cursorPos);
    final displayMention = '@${user.displayName}';

    final newText = '$beforeMention$displayMention $afterMention';
    textController.text = newText;

    // Move cursor after the mention
    final newCursorPos = beforeMention.length + displayMention.length + 1;
    textController.selection = TextSelection.collapsed(offset: newCursorPos);

    _hideSuggestions();
  }

  /// Convert display mentions to storage format before sending
  String convertToStorageFormat(String text) {
    String result = text;
    for (final entry in mentionedUsers.entries) {
      final displayFormat = '@${entry.key}';
      final storageFormat = MentionService.formatMention(entry.key, entry.value);
      result = result.replaceAll(displayFormat, storageFormat);
    }
    return result;
  }

  void clear() {
    textController.clear();
    mentionedUsers.clear();
  }
}

/// Mention suggestions widget
class MentionSuggestions extends StatelessWidget {
  final MentionAutocompleteController controller;

  const MentionSuggestions({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.showSuggestions) {
      return const SizedBox.shrink();
    }

    if (controller.suggestions.isEmpty && controller.query.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          border: Border(
            top: BorderSide(
              color: AppTheme.getTextTertiary(context).withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Text(
          'Kullanıcı bulunamadı',
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
            fontSize: 14,
          ),
        ),
      );
    }

    if (controller.suggestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          border: Border(
            top: BorderSide(
              color: AppTheme.getTextTertiary(context).withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Text(
          'Etiketlemek için yazmaya başlayın...',
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.getTextTertiary(context).withValues(alpha: 0.2),
          ),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: controller.suggestions.length,
        itemBuilder: (context, index) {
          final user = controller.suggestions[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: getAvatarColor(user.uid),
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              user.email,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            dense: true,
            onTap: () => controller.insertMention(user),
          );
        },
      ),
    );
  }
}
