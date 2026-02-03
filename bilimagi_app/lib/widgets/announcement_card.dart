import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../core/theme.dart';

/// Card widget for displaying announcements (v8.0)
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showActions;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
    this.onDelete,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pin indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: announcement.isPinned
                    ? Colors.amber.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  Icon(
                    announcement.isPinned ? Icons.push_pin : Icons.campaign,
                    size: 20,
                    color: announcement.isPinned
                        ? Colors.amber.shade700
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Duyuru',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: announcement.isPinned
                            ? Colors.amber.shade700
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  if (announcement.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Sabitlendi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Content preview
                  Text(
                    announcement.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Footer
                  Row(
                    children: [
                      // Author
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        announcement.authorDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextTertiary(context),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Time
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.getTextTertiary(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getRelativeTime(announcement.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextTertiary(context),
                        ),
                      ),

                      // Expiry
                      if (announcement.expiresAt != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppTheme.getTextTertiary(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatExpiry(announcement.expiresAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getTextTertiary(context),
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Actions
                      if (showActions && onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: onDelete,
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatExpiry(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.isNegative) return 'Suresi doldu';
    if (diff.inDays > 0) return '${diff.inDays} gun kaldi';
    if (diff.inHours > 0) return '${diff.inHours} saat kaldi';
    return '${diff.inMinutes} dk kaldi';
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} gun once';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} saat once';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} dk once';
    }
    return 'Az once';
  }
}

/// Mini announcement banner for top of screens
class AnnouncementBanner extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AnnouncementBanner({
    super.key,
    required this.announcement,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.campaign,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (announcement.content.isNotEmpty)
                    Text(
                      announcement.content,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
