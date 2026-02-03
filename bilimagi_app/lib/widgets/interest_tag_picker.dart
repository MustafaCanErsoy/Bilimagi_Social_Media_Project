import 'package:flutter/material.dart';
import '../core/interest_categories.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';

/// Multi-select interest tag picker
/// v7.2: Scientific interest selection with max 5 limit
class InterestTagPicker extends StatelessWidget {
  final List<String> selectedInterests;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  const InterestTagPicker({
    super.key,
    required this.selectedInterests,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allInterests = InterestCategory.allKeys;
    final maxReached = selectedInterests.length >= InterestCategory.maxSelection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ilgi Alanlari',
              style: AppTypography.h3.copyWith(
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const Spacer(),
            Text(
              '${selectedInterests.length}/${InterestCategory.maxSelection}',
              style: AppTypography.bodySmall.copyWith(
                color: maxReached ? AppColors.warning : AppColors.getTextMuted(context),
                fontWeight: maxReached ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Ilgilendigin bilim dallarini sec (en fazla ${InterestCategory.maxSelection})',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.getTextMuted(context),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allInterests.map((key) {
            final isSelected = selectedInterests.contains(key);
            final canSelect = isSelected || !maxReached;

            return FilterChip(
              label: Text(InterestCategory.getLabel(key)),
              selected: isSelected,
              onSelected: enabled && canSelect
                  ? (selected) {
                      final newList = List<String>.from(selectedInterests);
                      if (selected) {
                        if (newList.length < InterestCategory.maxSelection) {
                          newList.add(key);
                        }
                      } else {
                        newList.remove(key);
                      }
                      onChanged(newList);
                    }
                  : null,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              backgroundColor: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              disabledColor: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.5)
                  : AppColors.lightBorder.withValues(alpha: 0.5),
              labelStyle: AppTypography.body.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : (canSelect
                        ? AppColors.getTextPrimary(context)
                        : AppColors.getTextMuted(context)),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (canSelect
                        ? AppColors.getBorder(context)
                        : AppColors.getBorder(context).withValues(alpha: 0.5)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
