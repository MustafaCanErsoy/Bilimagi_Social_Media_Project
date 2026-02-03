import 'package:flutter/material.dart';
import '../models/period.dart';
import '../models/comment.dart';
import '../models/comment_tree.dart';
import '../services/mention_service.dart';
import '../core/theme.dart';
import '../core/avatar_colors.dart';
import '../core/time_utils.dart';
import '../screens/profile_screen.dart';
import 'vote_buttons.dart';

/// Comment card widget for displaying a single comment
class CommentCard extends StatelessWidget {
  final CommentTree commentNode;
  final Period period;
  final String articleId;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isOwnComment;
  // v6.0: Moderation
  final bool isModerator;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;
  // v6.0: Report
  final VoidCallback? onReport;

  const CommentCard({
    super.key,
    required this.commentNode,
    required this.period,
    required this.articleId,
    required this.onReply,
    this.onEdit,
    this.onDelete,
    this.isOwnComment = false,
    this.isModerator = false,
    this.onHide,
    this.onUnhide,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final comment = commentNode.comment;
    final depth = comment.depth;
    final leftPadding = depth * 20.0; // 20px per level
    const maxDepth = 5; // Limit indentation

    // v4.0: Show deleted comment placeholder
    if (comment.isDeleted) {
      return _buildDeletedComment(context, depth, maxDepth, leftPadding);
    }

    // v6.0: Show hidden comment placeholder (unless moderator viewing)
    if (comment.isHidden && !isModerator) {
      return _buildHiddenComment(context, depth, maxDepth, leftPadding);
    }

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
            backgroundColor: getAvatarColor(comment.uid),
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
                // Name, time, and edit indicator
                _buildHeader(context, comment),
                const SizedBox(height: 4),
                // Comment text with mentions
                _buildCommentText(context, comment.text),
                const SizedBox(height: 6),
                // Vote and reply buttons
                _buildActions(context, comment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedComment(
    BuildContext context,
    int depth,
    int maxDepth,
    double leftPadding,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: depth > maxDepth ? maxDepth * 20.0 : leftPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.getTextTertiary(context),
            child: const Icon(Icons.person_off, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getTextTertiary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '[Bu yorum silindi]',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.getTextTertiary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenComment(
    BuildContext context,
    int depth,
    int maxDepth,
    double leftPadding,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: depth > maxDepth ? maxDepth * 20.0 : leftPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.orange.shade200,
            child: Icon(Icons.visibility_off, color: Colors.orange.shade800, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '[Bu yorum moderator tarafindan gizlendi]',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Comment comment) {
    return Row(
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: comment.uid),
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
          formatRelativeTime(comment.createdAt),
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getTextTertiary(context),
          ),
        ),
        // v4.0: Edited indicator
        if (comment.isEdited) ...[
          const SizedBox(width: 6),
          Text(
            '(düzenlendi)',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppTheme.getTextTertiary(context),
            ),
          ),
        ],
        const Spacer(),
        // v4.0: Edit button for own comments
        if (isOwnComment && period.phase == PeriodPhase.discussion && onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppTheme.getTextTertiary(context),
            ),
          ),
        // v4.0: Delete button for own comments
        if (isOwnComment && period.phase == PeriodPhase.discussion && onDelete != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline,
              size: 16,
              color: AppTheme.getTextTertiary(context),
            ),
          ),
        ],
        // v6.0: Mod actions
        if (isModerator && !isOwnComment) ...[
          const SizedBox(width: 8),
          _buildModMenu(context, comment),
        ],
      ],
    );
  }

  Widget _buildModMenu(BuildContext context, Comment comment) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.shield_outlined,
        size: 16,
        color: Colors.orange.shade600,
      ),
      padding: EdgeInsets.zero,
      iconSize: 16,
      tooltip: 'Moderasyon',
      onSelected: (value) {
        if (value == 'hide' && onHide != null) {
          onHide!();
        } else if (value == 'unhide' && onUnhide != null) {
          onUnhide!();
        }
      },
      itemBuilder: (context) => [
        if (!comment.isHidden && onHide != null)
          const PopupMenuItem(
            value: 'hide',
            child: Row(
              children: [
                Icon(Icons.visibility_off, size: 18),
                SizedBox(width: 8),
                Text('Yorumu Gizle'),
              ],
            ),
          ),
        if (comment.isHidden && onUnhide != null)
          const PopupMenuItem(
            value: 'unhide',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 18),
                SizedBox(width: 8),
                Text('Gizliligi Kaldir'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCommentText(BuildContext context, String text) {
    final segments = MentionService.parseTextSegments(text);

    // If no segments parsed, show display text (with userId stripped)
    if (segments.isEmpty) {
      return Text(
        MentionService.getDisplayText(text),
        style: TextStyle(
          fontSize: 15,
          color: AppTheme.getTextPrimary(context),
          height: 1.4,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15,
          color: AppTheme.getTextPrimary(context),
          height: 1.4,
        ),
        children: segments.map((segment) {
          if (segment.isMention) {
            return WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  if (segment.userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfileScreen(userId: segment.userId),
                      ),
                    );
                  }
                },
                child: Text(
                  segment.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            );
          } else {
            return TextSpan(text: segment.text);
          }
        }).toList(),
      ),
    );
  }

  Widget _buildActions(BuildContext context, Comment comment) {
    return Row(
      children: [
        // Upvote/Downvote buttons
        VoteButtons(
          periodId: period.id,
          articleId: articleId,
          comment: comment,
        ),
        const SizedBox(width: 16),
        // Reply button (only in discussion phase)
        if (period.phase == PeriodPhase.discussion)
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
              color: AppTheme.getTextTertiary(context),
            ),
          ),
        ],
        // v6.0: Report button (for non-own comments)
        if (!isOwnComment && onReport != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onReport,
            child: Icon(
              Icons.flag_outlined,
              size: 16,
              color: AppTheme.getTextTertiary(context),
            ),
          ),
        ],
      ],
    );
  }
}
