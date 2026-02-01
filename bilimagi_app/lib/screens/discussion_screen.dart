import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../models/comment_tree.dart';
import '../services/week_service.dart';
import '../services/bookmark_service.dart';
import '../services/report_service.dart';
import '../core/theme.dart';
import '../widgets/article_post_card.dart';
import '../widgets/comment_card.dart';
import '../widgets/sort_tabs.dart';
import '../widgets/discussion_dialogs.dart';
import '../widgets/mention_autocomplete.dart';
import '../widgets/report_dialog.dart';

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
  final _reportService = ReportService();
  final _commentController = TextEditingController();
  late MentionAutocompleteController _mentionController;
  bool _sending = false;
  bool _sortByScore = true; // true = Popüler, false = Yeni

  @override
  void initState() {
    super.initState();
    _mentionController = MentionAutocompleteController(
      textController: _commentController,
    );
    _mentionController.setStateCallback(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _mentionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _reportComment(Comment comment) async {
    final result = await ReportDialog.show(
      context,
      title: 'Yorumu Raporla',
      targetName: comment.displayName,
    );

    if (result == null || !mounted) return;

    try {
      await _reportService.reportComment(
        communityId: widget.week.communityId,
        weekId: widget.week.id,
        articleId: widget.article.id,
        commentId: comment.id,
        commentUid: comment.uid,
        commentDisplayName: comment.displayName,
        reason: result['reason']!,
        details: result['details'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapor gönderildi. Teşekkürler!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      // Convert @displayName to @[displayName](userId) format
      final formattedText = _mentionController.convertToStorageFormat(text);

      await _weekService.addComment(
        widget.week.id,
        widget.article.id,
        formattedText,
      );
      _mentionController.clear();
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

  @override
  Widget build(BuildContext context) {
    final bookmarkService = BookmarkService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tartışma'),
        actions: [
          // Bookmark button
          StreamBuilder<bool>(
            stream: bookmarkService.isSaved(widget.article.id),
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: isSaved ? AppTheme.accentColor : null,
                ),
                tooltip: isSaved ? 'Kayıttan kaldır' : 'Kaydet',
                onPressed: () async {
                  try {
                    if (isSaved) {
                      await bookmarkService.unsaveArticle(widget.article.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kayıt kaldırıldı')),
                        );
                      }
                    } else {
                      await bookmarkService.saveArticle(
                        article: widget.article,
                        week: widget.week,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Makale kaydedildi!')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Instagram-style article post card
          ArticlePostCard(week: widget.week, article: widget.article),
          // Comments section
          Expanded(child: _buildCommentsSection()),
          // Comment input (only in discussion phase)
          if (widget.week.phase == WeekPhase.discussion) _buildCommentInput(),
        ],
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
              child: SortTabs(
                sortByScore: _sortByScore,
                onSortChanged: (value) => setState(() => _sortByScore = value),
              ),
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
                      final currentUid = FirebaseAuth.instance.currentUser?.uid;
                      final isOwnComment = commentNode.comment.uid == currentUid;
                      return CommentCard(
                        commentNode: commentNode,
                        week: widget.week,
                        articleId: widget.article.id,
                        onReply: () => DiscussionDialogs.showReplyDialog(
                          context: context,
                          parentComment: commentNode.comment,
                          weekId: widget.week.id,
                          articleId: widget.article.id,
                          weekService: _weekService,
                        ),
                        isOwnComment: isOwnComment,
                        onEdit: isOwnComment
                            ? () => DiscussionDialogs.showEditDialog(
                                  context: context,
                                  comment: commentNode.comment,
                                  weekId: widget.week.id,
                                  articleId: widget.article.id,
                                  weekService: _weekService,
                                )
                            : null,
                        onDelete: isOwnComment
                            ? () => DiscussionDialogs.showDeleteDialog(
                                  context: context,
                                  comment: commentNode.comment,
                                  weekId: widget.week.id,
                                  articleId: widget.article.id,
                                  weekService: _weekService,
                                )
                            : null,
                        onReport: !isOwnComment
                            ? () => _reportComment(commentNode.comment)
                            : null,
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
            color: AppTheme.getTextSecondary(context),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$commentCount Yorum',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              height: 1,
              color: AppTheme.getTextTertiary(context).withValues(alpha: 0.3),
            ),
          ),
        ],
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
            color: AppTheme.getTextTertiary(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz yorum yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk yorumu sen yap!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextTertiary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mention suggestions
        MentionSuggestions(controller: _mentionController),
        // Comment input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                      hintText: 'Yorumunuzu yazın... (@ile etiketle)',
                      hintStyle: TextStyle(color: AppTheme.getTextTertiary(context)),
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
        ),
      ],
    );
  }
}
