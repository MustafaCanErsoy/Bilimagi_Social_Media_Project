import 'package:flutter/material.dart';
import '../models/community.dart';

/// Horizontal scrollable category filter chips
class CategoryFilterChips extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allCategories = [null, ...CommunityCategory.all];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = selectedCategory == category;
          final label = category == null
              ? 'Tümü'
              : CommunityCategory.getLabel(category);

          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(category),
            selectedColor: colorScheme.primaryContainer,
            checkmarkColor: colorScheme.onPrimaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}

/// Sort dropdown for communities
class CommunitySortDropdown extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const CommunitySortDropdown({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  static const Map<String, String> sortLabels = {
    'popular': 'En Popüler',
    'newest': 'En Yeni',
    'name': 'Ada Göre',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            'Sırala:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedSort,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(8),
            items: sortLabels.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onSortChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
