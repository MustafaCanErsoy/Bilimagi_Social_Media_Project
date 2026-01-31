import 'package:flutter/material.dart';
import '../core/avatar_colors.dart';
import '../core/theme.dart';

/// Emoji picker for community icons
class CommunityEmojiPicker extends StatelessWidget {
  final String? selectedEmoji;
  final ValueChanged<String> onEmojiSelected;

  const CommunityEmojiPicker({
    super.key,
    this.selectedEmoji,
    required this.onEmojiSelected,
  });

  static const List<String> scienceEmojis = [
    '🔬', '🧬', '⚗️', '🧪', '🔭', '🌌', '🧠', '💊',
    '🦠', '🧫', '🔋', '⚡', '🌡️', '🧲', '🛠️', '💻',
    '🤖', '🚀', '🌍', '🌱', '🧮', '📊', '📐', '🔢',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topluluk Simgesi',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scienceEmojis.map((emoji) {
            final isSelected = emoji == selectedEmoji;
            return InkWell(
              onTap: () => onEmojiSelected(emoji),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Color picker for community avatar
class CommunityColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onColorSelected;

  const CommunityColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topluluk Rengi',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(avatarColors.length, (index) {
            final color = avatarColors[index];
            final isSelected = index == selectedIndex;
            return InkWell(
              onTap: () => onColorSelected(index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.getTextPrimary(context)
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Combined icon picker dialog
class CommunityIconPickerDialog extends StatefulWidget {
  final String? initialEmoji;
  final int initialColorIndex;

  const CommunityIconPickerDialog({
    super.key,
    this.initialEmoji,
    this.initialColorIndex = 0,
  });

  @override
  State<CommunityIconPickerDialog> createState() => _CommunityIconPickerDialogState();
}

class _CommunityIconPickerDialogState extends State<CommunityIconPickerDialog> {
  late String? _selectedEmoji;
  late int _selectedColorIndex;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.initialEmoji;
    _selectedColorIndex = widget.initialColorIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Simge Seç'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommunityEmojiPicker(
              selectedEmoji: _selectedEmoji,
              onEmojiSelected: (emoji) {
                setState(() => _selectedEmoji = emoji);
              },
            ),
            const SizedBox(height: 24),
            CommunityColorPicker(
              selectedIndex: _selectedColorIndex,
              onColorSelected: (index) {
                setState(() => _selectedColorIndex = index);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'emoji': _selectedEmoji,
              'colorIndex': _selectedColorIndex,
            });
          },
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}
