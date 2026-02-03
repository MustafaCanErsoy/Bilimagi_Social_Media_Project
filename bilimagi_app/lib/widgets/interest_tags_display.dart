import 'package:flutter/material.dart';
import '../core/interest_categories.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';

/// Display interest tags as chips
/// v7.2: Profile interest display widget
class InterestTagsDisplay extends StatelessWidget {
  final List<String> interests;
  final bool compact;

  const InterestTagsDisplay({
    super.key,
    required this.interests,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: interests.map((key) {
        final label = InterestCategory.getLabel(key);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.15),
                AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForInterest(key),
                size: compact ? 12 : 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: (compact ? AppTypography.caption : AppTypography.bodySmall)
                    .copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForInterest(String key) {
    switch (key) {
      case 'physics':
        return Icons.rocket_launch;
      case 'biology':
        return Icons.biotech;
      case 'chemistry':
        return Icons.science;
      case 'mathematics':
        return Icons.functions;
      case 'medicine':
        return Icons.medical_services;
      case 'engineering':
        return Icons.engineering;
      case 'psychology':
        return Icons.psychology;
      case 'astronomy':
        return Icons.public;
      case 'ecology':
        return Icons.eco;
      case 'computer_science':
        return Icons.computer;
      case 'neuroscience':
        return Icons.memory;
      case 'genetics':
        return Icons.bubble_chart;
      case 'climate':
        return Icons.cloud;
      case 'artificial_intelligence':
        return Icons.smart_toy;
      case 'quantum':
        return Icons.blur_on;
      default:
        return Icons.interests;
    }
  }
}
