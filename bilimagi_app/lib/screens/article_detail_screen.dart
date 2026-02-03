import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../models/period.dart';
import '../core/theme.dart';
import '../services/bookmark_service.dart';
import '../services/period_service.dart';
import '../services/comment_service.dart';
import '../widgets/markdown_viewer.dart';

/// Article detail screen with full content view (v10.0)
class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  final Period period;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.period,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _bookmarkService = BookmarkService();
  final _periodService = PeriodService();
  final _commentService = CommentService();

  Future<void> _openArticleLink() async {
    final url = Uri.parse(widget.article.link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link acilamadi')),
        );
      }
    }
  }

  Future<void> _shareArticle() async {
    final text =
        '${widget.article.title}\n\n${widget.article.summary}\n\nMakaleyi oku: ${widget.article.link}\n\n#Bilimagi ile paylasildi';
    await Share.share(text, subject: widget.article.title);
  }

  Future<void> _toggleBookmark(bool isSaved) async {
    try {
      if (isSaved) {
        await _bookmarkService.unsaveArticle(widget.article.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kaydedilenlerden cikarildi'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _bookmarkService.saveArticle(
          article: widget.article,
          period: widget.period,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kaydedildi!'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with hero image
          SliverAppBar(
            expandedHeight: widget.article.heroImageURL != null ? 250 : 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.article.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: widget.article.heroImageURL != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.article.heroImageURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        // Gradient overlay for readability
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black54,
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                    ),
            ),
            actions: [
              // Bookmark button
              StreamBuilder<bool>(
                stream: _bookmarkService.isSaved(widget.article.id),
                builder: (context, snapshot) {
                  final isSaved = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                    ),
                    onPressed: () => _toggleBookmark(isSaved),
                    tooltip: isSaved ? 'Kaydi kaldir' : 'Kaydet',
                  );
                },
              ),
              // Share button
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareArticle,
                tooltip: 'Paylas',
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.article.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Meta info row
                  _buildMetaInfo(context),
                  const SizedBox(height: 16),

                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.summarize,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ozet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.article.summary,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full content (if available)
                  if (widget.article.content != null &&
                      widget.article.content!.isNotEmpty) ...[
                    Text(
                      'Icerik',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    MarkdownViewer(
                      text: widget.article.content!,
                      selectable: true,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Author info (if available)
                  if (widget.article.authorDisplayName != null) ...[
                    _buildAuthorInfo(context),
                    const SizedBox(height: 24),
                  ],

                  // Suggested by info (if available)
                  if (widget.article.suggestedByUid != null) ...[
                    _buildSuggestionInfo(context),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        // Vote count
        StreamBuilder<int>(
          stream: _periodService.getArticleVoteCount(
            widget.period.id,
            widget.article.id,
          ),
          builder: (context, snapshot) {
            final count = snapshot.data ?? widget.article.voteCount;
            return _buildMetaChip(
              context,
              Icons.how_to_vote,
              '$count oy',
              Colors.blue,
            );
          },
        ),

        // Comment count
        StreamBuilder<int>(
          stream: _commentService.getCommentCount(
            widget.period.id,
            widget.article.id,
          ),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return _buildMetaChip(
              context,
              Icons.chat_bubble_outline,
              '$count yorum',
              Colors.green,
            );
          },
        ),

        // Eligibility status
        if (widget.article.isEligibleForDiscussion)
          _buildMetaChip(
            context,
            Icons.check_circle,
            'Tartismada',
            Colors.green,
          )
        else
          _buildMetaChip(
            context,
            Icons.pending,
            'Oylama',
            Colors.orange,
          ),

        // Published date
        if (widget.article.publishedAt != null)
          _buildMetaChip(
            context,
            Icons.calendar_today,
            _formatDate(widget.article.publishedAt!),
            Colors.grey,
          ),
      ],
    );
  }

  Widget _buildMetaChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              widget.article.authorDisplayName![0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yazar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  widget.article.authorDisplayName!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: Colors.purple.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Topluluk onerisi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade600,
                  ),
                ),
                const Text(
                  'Bu makale bir uye tarafindan onerildi',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Read original article
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openArticleLink,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Makaleyi Oku'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Share
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _shareArticle,
            icon: const Icon(Icons.share),
            label: const Text('Paylas'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
