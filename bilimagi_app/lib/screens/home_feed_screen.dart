import 'package:flutter/material.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../models/community.dart';
import '../services/week_service.dart';
import '../core/theme.dart';
import 'discussion_screen.dart';
import 'week_screen.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active Discussions Section
          _buildSectionHeader(
            icon: Icons.forum,
            title: 'Aktif Tartışmalar',
            subtitle: 'Şu anda tartışılan makaleler',
          ),
          const SizedBox(height: 12),
          _ActiveDiscussionsSection(),
          const SizedBox(height: 24),

          // Voting This Week Section
          _buildSectionHeader(
            icon: Icons.how_to_vote,
            title: 'Bu Hafta Oylama',
            subtitle: 'Oyunu kullan, kazananı belirle',
          ),
          const SizedBox(height: 12),
          _VotingWeeksSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveDiscussionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekService = WeekService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: weekService.getActiveDiscussions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final discussions = snapshot.data ?? [];

        if (discussions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline,
            message: 'Henüz aktif tartışma yok',
          );
        }

        return Column(
          children: discussions.map((data) {
            final week = data['week'] as Week;
            final article = data['article'] as Article;
            final community = data['community'] as Community;

            return _DiscussionCard(
              week: week,
              article: article,
              community: community,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppTheme.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VotingWeeksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekService = WeekService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: weekService.getVotingWeeks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final votingWeeks = snapshot.data ?? [];

        if (votingWeeks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.how_to_vote_outlined,
            message: 'Şu anda oylama yapılan topluluk yok',
          );
        }

        return Column(
          children: votingWeeks.map((data) {
            final community = data['community'] as Community;
            return _VotingWeekCard(community: community);
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppTheme.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  final Week week;
  final Article article;
  final Community community;

  const _DiscussionCard({
    required this.week,
    required this.article,
    required this.community,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscussionScreen(
                week: week,
                article: article,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      community.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chat_bubble,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Article title
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Article summary
              Text(
                article.summary,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Stats
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 16,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${article.voteCount} oy',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VotingWeekCard extends StatelessWidget {
  final Community community;

  const _VotingWeekCard({required this.community});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeekScreen(community: community),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.how_to_vote,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oylama devam ediyor',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
