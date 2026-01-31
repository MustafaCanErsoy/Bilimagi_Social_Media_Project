import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../models/comment_tree.dart';
import '../services/week_service.dart';
import '../services/vote_service.dart';
import '../core/theme.dart';
import 'profile_screen.dart';

class DiscussionScreen extends StatefulWidget {
  final Week week;
  final Article article;

  const DiscussionScreen({
    super.key,
    required this.week,
    required this.article,
  });

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final _weekService = WeekService();
  final _commentController = TextEditingController();
  bool _sending = false;
  bool _sortByScore = true; // true = Popüler, false = Yeni

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      await _weekService.addComment(
        widget.week.id,
        widget.article.id,
        text,
      );
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  // Show reply dialog
  void _showReplyDialog(Comment parentComment) {
    final replyController = TextEditingController();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.reply, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${parentComment.displayName} kullanıcısına yanıt',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Original comment (quoted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  parentComment.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // Reply input
              TextField(
                controller: replyController,
                decoration: const InputDecoration(
                  hintText: 'Yanıtınızı yazın...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              // Send button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          final text = replyController.text.trim();
                          if (text.isEmpty) return;

                          setState(() => sending = true);

                          try {
                            await _weekService.addReply(
                              widget.week.id,
                              widget.article.id,
                              parentComment.id,
                              parentComment.depth,
                              text,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Yanıt gönderildi!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => sending = false);
                            }
                          }
                        },
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Gönder'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openArticleLink() async {
    final url = Uri.parse(widget.article.link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link açılamadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tartışma'),
      ),
      body: Column(
        children: [
          // Instagram-style article post card
          _buildArticlePostCard(),
          // Comments section
          Expanded(child: _buildCommentsSection()),
          // Comment input (only in discussion phase)
          if (widget.week.phase == WeekPhase.discussion) _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildArticlePostCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.2),
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
              widget.article.title,
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
              widget.article.summary,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Read article button
            OutlinedButton.icon(
              onPressed: _openArticleLink,
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
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.article.voteCount} Oy',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  widget.week.phase == WeekPhase.discussion
                      ? Icons.chat_bubble
                      : Icons.lock,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.week.phase == WeekPhase.discussion
                      ? 'Tartışma Açık'
                      : 'Kapatıldı',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
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

  Widget _buildCommentsSection() {
    return StreamBuilder<List<Comment>>(
      stream: _weekService.getComments(widget.week.id, widget.article.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final comments = snapshot.data ?? [];

        // Build comment tree with sorting
        final commentTree = CommentTree.buildTree(
          comments,
          sortByScore: _sortByScore,
        );
        final flattenedComments = CommentTree.flatten(commentTree);

        return CustomScrollView(
          slivers: [
            // Comments header
            SliverToBoxAdapter(
              child: _buildCommentsHeader(comments.length),
            ),
            // Sorting tabs
            SliverToBoxAdapter(
              child: _buildSortingTabs(),
            ),
            // Comments list
            if (flattenedComments.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final commentNode = flattenedComments[index];
                      return _CommentCard(
                        commentNode: commentNode,
                        week: widget.week,
                        articleId: widget.article.id,
                        onReply: () => _showReplyDialog(commentNode.comment),
                      );
                    },
                    childCount: flattenedComments.length,
                  ),
                ),
              ),
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentsHeader(int commentCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.comment,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$commentCount Yorum',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              height: 1,
              color: AppTheme.textTertiary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortingTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildSortTab(
            icon: Icons.local_fire_department,
            label: 'Popüler',
            isSelected: _sortByScore,
            onTap: () => setState(() => _sortByScore = true),
          ),
          const SizedBox(width: 12),
          _buildSortTab(
            icon: Icons.access_time,
            label: 'Yeni',
            isSelected: !_sortByScore,
            onTap: () => setState(() => _sortByScore = false),
          ),
        ],
      ),
    );
  }

  Widget _buildSortTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.textTertiary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz yorum yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk yorumu sen yap!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Yorumunuzu yazın...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _sendComment,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final CommentTree commentNode;
  final Week week;
  final String articleId;
  final VoidCallback onReply;

  const _CommentCard({
    required this.commentNode,
    required this.week,
    required this.articleId,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final comment = commentNode.comment;
    final depth = comment.depth;
    final leftPadding = depth * 20.0; // 20px per level
    final maxDepth = 5; // Limit indentation

    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: depth > maxDepth ? maxDepth * 20.0 : leftPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: _getAvatarColor(comment.uid),
            child: Text(
              comment.displayName.isNotEmpty
                  ? comment.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and time in one line
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(userId: comment.uid),
                            ),
                          );
                        },
                        child: Text(
                          comment.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Comment text
                Text(
                  comment.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                // Vote and reply buttons
                Row(
                  children: [
                    // Upvote/Downvote buttons
                    _VoteButtons(
                      weekId: week.id,
                      articleId: articleId,
                      comment: comment,
                    ),
                    const SizedBox(width: 16),
                    // Reply button (only in discussion phase)
                    if (week.phase == WeekPhase.discussion)
                      TextButton.icon(
                        onPressed: onReply,
                        icon: Icon(
                          Icons.reply,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        label: Text(
                          'Yanıtla',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    if (comment.replyCount > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${comment.replyCount} yanıt',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String uid) {
    // Generate a consistent color based on user ID
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF3498DB), // Blue
      const Color(0xFFE74C3C), // Red
      const Color(0xFF2ECC71), // Green
      const Color(0xFFF39C12), // Orange
      const Color(0xFF1ABC9C), // Turquoise
    ];

    final hash = uid.hashCode.abs();
    return colors[hash % colors.length];
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Az önce';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

// Vote buttons widget
class _VoteButtons extends StatelessWidget {
  final String weekId;
  final String articleId;
  final Comment comment;

  const _VoteButtons({
    required this.weekId,
    required this.articleId,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final voteService = VoteService();

    return StreamBuilder<VoteType?>(
      stream: voteService.getUserVote(
        weekId: weekId,
        articleId: articleId,
        commentId: comment.id,
      ),
      builder: (context, snapshot) {
        final userVote = snapshot.data;
        final hasUpvoted = userVote == VoteType.up;
        final hasDownvoted = userVote == VoteType.down;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upvote button
            InkWell(
              onTap: () {
                voteService.voteComment(
                  weekId: weekId,
                  articleId: articleId,
                  commentId: comment.id,
                  type: VoteType.up,
                );
              },
              child: Icon(
                hasUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
                size: 20,
                color: hasUpvoted
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            // Score
            Text(
              comment.score.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: hasUpvoted
                    ? AppTheme.primaryColor
                    : hasDownvoted
                        ? AppTheme.errorColor
                        : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            // Downvote button
            InkWell(
              onTap: () {
                voteService.voteComment(
                  weekId: weekId,
                  articleId: articleId,
                  commentId: comment.id,
                  type: VoteType.down,
                );
              },
              child: Icon(
                hasDownvoted
                    ? Icons.arrow_downward
                    : Icons.arrow_downward_outlined,
                size: 20,
                color: hasDownvoted
                    ? AppTheme.errorColor
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
