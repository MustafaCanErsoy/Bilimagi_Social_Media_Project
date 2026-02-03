import 'package:flutter/material.dart';
import '../models/user_activity.dart';
import '../core/avatar_colors.dart';
import '../core/time_utils.dart';

/// Card widget for displaying user activity in feed
class ActivityFeedCard extends StatelessWidget {
  final UserActivity activity;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;
  final bool showCommunityHint; // v10.0: Show hint for join activities

  const ActivityFeedCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onUserTap,
    this.showCommunityHint = false,
  });

  IconData get _activityIcon {
    switch (activity.type) {
      case ActivityType.comment:
        return Icons.chat_bubble;
      case ActivityType.vote:
        return Icons.how_to_vote;
      case ActivityType.join:
        return Icons.group_add;
      case ActivityType.suggestion:
        return Icons.lightbulb;
    }
  }

  Color _getIconColor(ColorScheme colorScheme) {
    switch (activity.type) {
      case ActivityType.comment:
        return colorScheme.primary;
      case ActivityType.vote:
        return Colors.amber.shade700;
      case ActivityType.join:
        return Colors.green.shade600;
      case ActivityType.suggestion:
        return Colors.purple.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarColor = avatarColors[activity.avatarColorIndex % avatarColors.length];
    final iconColor = _getIconColor(colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar with activity icon overlay
              Stack(
                children: [
                  GestureDetector(
                    onTap: onUserTap,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: avatarColor,
                      child: Text(
                        activity.displayName.isNotEmpty
                            ? activity.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _activityIcon,
                        size: 12,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name and action
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: activity.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' ${activity.actionText}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Target name if available
                    if (activity.targetName != null)
                      Text(
                        activity.targetName!,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Preview if available
                    if (activity.preview != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${activity.preview}"',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Community and time
                    Row(
                      children: [
                        if (activity.communityName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              activity.communityName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          formatRelativeTime(activity.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // v10.0: Show community hint for join activities
                        if (showCommunityHint && activity.type == ActivityType.join) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.open_in_new,
                                  size: 10,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Topluluğu gör',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Navigation arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
