import 'package:flutter/material.dart';
import '../models/contribution_score.dart';
import '../core/theme.dart';

/// Widget to display user's contribution level and progress (v8.0)
class ContributionLevelCard extends StatelessWidget {
  final ContributionScore score;
  final bool showDetails;
  final bool compact;

  const ContributionLevelCard({
    super.key,
    required this.score,
    this.showDetails = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final level = score.level;
    final nextLevel = level.nextLevel;
    final progress = score.progressToNextLevel;

    if (compact) {
      return _buildCompact(context, level);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      level.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Seviye ${level.levelNumber}',
                            style: TextStyle(
                              color: AppTheme.getTextTertiary(context),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${score.totalPoints} puan',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        level.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Progress bar
            if (nextLevel != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sonraki seviye: ${nextLevel.name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.getTextTertiary(context),
                              ),
                            ),
                            Text(
                              '${score.pointsToNextLevel} puan kaldi',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    nextLevel.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'Maksimum seviyeye ulastiniz!',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Stats breakdown
            if (showDetails) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Puan Dagilimi',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                context,
                icon: Icons.chat_bubble_outline,
                label: 'Yorumlar',
                value: '${score.totalComments} x ${ContributionScore.pointsPerComment}',
                points: score.totalComments * ContributionScore.pointsPerComment,
              ),
              _buildStatRow(
                context,
                icon: Icons.how_to_vote,
                label: 'Oylar',
                value: '${score.totalVotes} x ${ContributionScore.pointsPerVote}',
                points: score.totalVotes * ContributionScore.pointsPerVote,
              ),
              _buildStatRow(
                context,
                icon: Icons.lightbulb_outline,
                label: 'Oneriler',
                value: '${score.totalSuggestions} x ${ContributionScore.pointsPerSuggestion}',
                points: score.totalSuggestions * ContributionScore.pointsPerSuggestion,
              ),
              _buildStatRow(
                context,
                icon: Icons.check_circle_outline,
                label: 'Onaylanan Oneriler',
                value: '${score.approvedSuggestions} x ${ContributionScore.pointsPerApprovedSuggestion}',
                points: score.approvedSuggestions * ContributionScore.pointsPerApprovedSuggestion,
              ),
              _buildStatRow(
                context,
                icon: Icons.thumb_up_outlined,
                label: 'Alinan Upvote',
                value: '${score.receivedUpvotes} x ${ContributionScore.pointsPerReceivedUpvote}',
                points: score.receivedUpvotes * ContributionScore.pointsPerReceivedUpvote,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, ContributionLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(level.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            'Svye ${level.levelNumber}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required int points,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.getTextTertiary(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.getTextTertiary(context),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getTextTertiary(context),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '$points',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini level indicator for lists/cards
class LevelIndicator extends StatelessWidget {
  final int points;

  const LevelIndicator({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final level = ContributionLevel.fromPoints(points);

    return Tooltip(
      message: '${level.name} - $points puan',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          level.emoji,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
