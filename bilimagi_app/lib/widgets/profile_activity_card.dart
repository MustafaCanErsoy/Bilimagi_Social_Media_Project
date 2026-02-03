import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';
import '../core/time_utils.dart' as time_utils;
import '../services/notification_service.dart';

/// User activity card showing recent actions
/// v7.2: Profile activity display
class ProfileActivityCard extends StatelessWidget {
  final String userId;
  final int maxItems;

  const ProfileActivityCard({
    super.key,
    required this.userId,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Son Aktiviteler',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<AppNotification>>(
              stream: notificationService.getNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return _buildEmptyState(context);
                }

                final displayedNotifications =
                    notifications.take(maxItems).toList();

                return Column(
                  children: displayedNotifications.map((notification) {
                    return _buildActivityItem(context, notification);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 40,
            color: AppColors.getTextMuted(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Henuz aktivite yok',
            style: AppTypography.body.copyWith(
              color: AppColors.getTextMuted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    AppNotification notification,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivityIcon(notification.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.message,
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time_utils.formatRelativeTime(notification.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.getTextMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.follow:
        icon = Icons.person_add;
        color = AppColors.primary;
      case NotificationType.mention:
        icon = Icons.alternate_email;
        color = AppColors.secondary;
      case NotificationType.reply:
        icon = Icons.reply;
        color = AppColors.info;
      case NotificationType.upvote:
        icon = Icons.thumb_up;
        color = AppColors.success;
      case NotificationType.membershipRequest:
        icon = Icons.person_add_alt;
        color = AppColors.warning;
      case NotificationType.membershipApproved:
        icon = Icons.check_circle;
        color = AppColors.success;
      case NotificationType.membershipRejected:
        icon = Icons.cancel;
        color = AppColors.error;
      case NotificationType.suggestionApproved:
        icon = Icons.article;
        color = AppColors.success;
      case NotificationType.suggestionRejected:
        icon = Icons.article;
        color = AppColors.error;
      case NotificationType.roleChanged:
        icon = Icons.admin_panel_settings;
        color = AppColors.warning;
      case NotificationType.memberRemoved:
        icon = Icons.person_remove;
        color = AppColors.error;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: color,
      ),
    );
  }
}
