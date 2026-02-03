import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/period.dart';
import '../models/article.dart';
import '../core/theme.dart';
import '../services/comment_service.dart';
import '../services/period_service.dart';

/// Instagram-style article post card for discussion screen
class ArticlePostCard extends StatelessWidget {
  final Period period;
  final Article article;

  const ArticlePostCard({
    super.key,
    required this.period,
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

  Future<void> _shareArticle() async {
    final text = '${article.title}\n\n${article.summary}\n\nMakaleyi oku: ${article.link}\n\n#Bilimagi ile paylaşıldı';
    await Share.share(text, subject: article.title);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image (v8.0)
          if (article.heroImageURL != null)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                article.heroImageURL!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          Padding(
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
            // Action buttons row
            Row(
              children: [
                // Read article button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openArticleLink(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Makaleyi Oku'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Share button
                OutlinedButton(
                  onPressed: _shareArticle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Icon(Icons.share, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Footer info
            Row(
              children: [
                // Vote count (stream)
                StreamBuilder<int>(
                  stream: PeriodService().getArticleVoteCount(period.id, article.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? article.voteCount;
                    return Row(
                      children: [
                        Icon(
                          Icons.how_to_vote,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$count Oy',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Comment count (stream)
                StreamBuilder<int>(
                  stream: CommentService().getCommentCount(period.id, article.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$count Yorum',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
                Icon(
                  period.phase == PeriodPhase.discussion
                      ? Icons.lock_open
                      : Icons.lock,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  period.phase == PeriodPhase.discussion
                      ? 'Acik'
                      : 'Kapali',
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
        ],
      ),
    );
  }
}
