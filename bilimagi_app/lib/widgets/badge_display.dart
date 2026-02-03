import 'package:flutter/material.dart';
import '../models/user_badge.dart';
import '../core/theme.dart';

/// Widget to display user badges (v8.0)
class BadgeDisplay extends StatelessWidget {
  final List<UserBadge> badges;
  final int maxDisplay;
  final bool showLabels;
  final double size;

  const BadgeDisplay({
    super.key,
    required this.badges,
    this.maxDisplay = 3,
    this.showLabels = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    // Sort by priority
    final sortedBadges = List<UserBadge>.from(badges)
      ..sort((a, b) => b.type.priority.compareTo(a.type.priority));

    final displayBadges = sortedBadges.take(maxDisplay).toList();
    final remaining = sortedBadges.length - maxDisplay;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayBadges.map((badge) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: BadgeChip(
                badge: badge,
                size: size,
                showLabel: showLabels,
              ),
            )),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

/// Single badge chip widget
class BadgeChip extends StatelessWidget {
  final UserBadge badge;
  final double size;
  final bool showLabel;
  final VoidCallback? onTap;

  const BadgeChip({
    super.key,
    required this.badge,
    this.size = 32,
    this.showLabel = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Tooltip(
      message: '${badge.label}\n${badge.description}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(size * 0.15),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                badge.emoji,
                style: TextStyle(fontSize: size * 0.6),
              ),
              if (showLabel) ...[
                const SizedBox(width: 4),
                Text(
                  badge.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return chip;
  }
}

/// Full badge list (for profile/modal)
class BadgeList extends StatelessWidget {
  final List<UserBadge> badges;
  final bool showEarnedDate;

  const BadgeList({
    super.key,
    required this.badges,
    this.showEarnedDate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 48,
              color: AppTheme.getTextTertiary(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Henuz rozet kazanilmadi',
              style: TextStyle(
                color: AppTheme.getTextTertiary(context),
              ),
            ),
          ],
        ),
      );
    }

    // Sort by priority
    final sortedBadges = List<UserBadge>.from(badges)
      ..sort((a, b) => b.type.priority.compareTo(a.type.priority));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedBadges.length,
      itemBuilder: (context, index) {
        final badge = sortedBadges[index];
        return _BadgeListTile(
          badge: badge,
          showEarnedDate: showEarnedDate,
        );
      },
    );
  }
}

class _BadgeListTile extends StatelessWidget {
  final UserBadge badge;
  final bool showEarnedDate;

  const _BadgeListTile({
    required this.badge,
    required this.showEarnedDate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            badge.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      title: Text(
        badge.label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(badge.description),
          if (showEarnedDate)
            Text(
              'Kazanildi: ${_formatDate(badge.earnedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextTertiary(context),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Badge showcase for showing primary badge
class PrimaryBadgeShowcase extends StatelessWidget {
  final BadgeType? badgeType;

  const PrimaryBadgeShowcase({
    super.key,
    this.badgeType,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeType == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.secondaryColor.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badgeType!.emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 6),
          Text(
            badgeType!.label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
