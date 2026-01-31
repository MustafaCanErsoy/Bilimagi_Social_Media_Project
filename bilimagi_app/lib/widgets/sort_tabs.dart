import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Sorting tabs widget for comments (Popular/New)
class SortTabs extends StatelessWidget {
  final bool sortByScore;
  final ValueChanged<bool> onSortChanged;

  const SortTabs({
    super.key,
    required this.sortByScore,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildSortTab(
            context: context,
            icon: Icons.local_fire_department,
            label: 'Popüler',
            isSelected: sortByScore,
            onTap: () => onSortChanged(true),
          ),
          const SizedBox(width: 12),
          _buildSortTab(
            context: context,
            icon: Icons.access_time,
            label: 'Yeni',
            isSelected: !sortByScore,
            onTap: () => onSortChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSortTab({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.getTextTertiary(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.getTextSecondary(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
