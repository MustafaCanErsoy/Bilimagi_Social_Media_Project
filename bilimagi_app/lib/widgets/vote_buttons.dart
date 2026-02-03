import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/vote_service.dart';
import '../core/theme.dart';

/// Vote buttons widget for comments (upvote/downvote)
class VoteButtons extends StatelessWidget {
  final String periodId;
  final String articleId;
  final Comment comment;

  const VoteButtons({
    super.key,
    required this.periodId,
    required this.articleId,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final voteService = VoteService();

    return StreamBuilder<VoteType?>(
      stream: voteService.getUserVote(
        periodId: periodId,
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
                  periodId: periodId,
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
                    : AppTheme.getTextSecondary(context),
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
                        : AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(width: 6),
            // Downvote button
            InkWell(
              onTap: () {
                voteService.voteComment(
                  periodId: periodId,
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
                    : AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
