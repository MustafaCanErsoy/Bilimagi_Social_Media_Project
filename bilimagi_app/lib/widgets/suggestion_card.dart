import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article_suggestion.dart';
import '../core/theme.dart';
import '../core/avatar_colors.dart';
import '../services/suggestion_service.dart';

/// Card for displaying article suggestions
class SuggestionCard extends StatelessWidget {
  final ArticleSuggestion suggestion;
  final bool showActions;
  final bool isReviewer;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    this.showActions = true,
    this.isReviewer = false,
    this.onApprove,
    this.onReject,
  });

  Future<void> _openLink(BuildContext context) async {
    final url = Uri.parse(suggestion.link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link açılamadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestionService = SuggestionService();
    final avatarColor = getAvatarColor(suggestion.submitterUid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Submitter info + Status badge
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor.withValues(alpha: 0.2),
                  child: Text(
                    suggestion.submitterDisplayName.isNotEmpty
                        ? suggestion.submitterDisplayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.submitterDisplayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        _formatDate(suggestion.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              suggestion.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // Summary
            Text(
              suggestion.summary,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Link button
            InkWell(
              onTap: () => _openLink(context),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.link,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (showActions) ...[
              const Divider(height: 24),
              // Actions row
              Row(
                children: [
                  // Interest button
                  StreamBuilder<bool>(
                    stream: suggestionService.hasExpressedInterest(
                      suggestion.weekId,
                      suggestion.id,
                    ),
                    builder: (context, snapshot) {
                      final hasInterest = snapshot.data ?? false;
                      return TextButton.icon(
                        onPressed: () => suggestionService.toggleInterest(
                          suggestion.weekId,
                          suggestion.id,
                        ),
                        icon: Icon(
                          hasInterest ? Icons.star : Icons.star_outline,
                          color: hasInterest
                              ? AppTheme.accentColor
                              : AppTheme.getTextSecondary(context),
                        ),
                        label: Text(
                          '${suggestion.interestScore} ilgi',
                          style: TextStyle(
                            color: hasInterest
                                ? AppTheme.accentColor
                                : AppTheme.getTextSecondary(context),
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // Reviewer actions
                  if (isReviewer && suggestion.isPending) ...[
                    TextButton(
                      onPressed: onReject,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('Reddet'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Onayla'),
                    ),
                  ],
                ],
              ),
            ],
            // Rejection reason if rejected
            if (suggestion.isRejected && suggestion.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Red sebebi: ${suggestion.rejectionReason}',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (suggestion.status) {
      case SuggestionStatus.pending:
        color = AppTheme.accentColor;
        label = 'Beklemede';
        icon = Icons.hourglass_empty;
        break;
      case SuggestionStatus.approved:
        color = AppTheme.secondaryColor;
        label = 'Onaylandı';
        icon = Icons.check_circle;
        break;
      case SuggestionStatus.rejected:
        color = AppTheme.errorColor;
        label = 'Reddedildi';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${date.day}/${date.month}/${date.year}';
  }
}
