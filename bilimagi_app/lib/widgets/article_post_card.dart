import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../core/theme.dart';

/// Instagram-style article post card for discussion screen
class ArticlePostCard extends StatelessWidget {
  final Week week;
  final Article article;

  const ArticlePostCard({
    super.key,
    required this.week,
    required this.article,
  });

  Future<void> _openArticleLink(BuildContext context) async {
    final url = Uri.parse(article.link);
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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trophy badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Kazanan Makale',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // Summary
            Text(
              article.summary,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Read article button
            OutlinedButton.icon(
              onPressed: () => _openArticleLink(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Makaleyi Oku'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Footer info
            Row(
              children: [
                Icon(
                  Icons.how_to_vote,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${article.voteCount} Oy',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  week.phase == WeekPhase.discussion
                      ? Icons.chat_bubble
                      : Icons.lock,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  week.phase == WeekPhase.discussion
                      ? 'Tartışma Açık'
                      : 'Kapatıldı',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
