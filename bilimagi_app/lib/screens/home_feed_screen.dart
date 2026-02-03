import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/period.dart';
import '../models/article.dart';
import '../models/community.dart';
import '../models/user_profile.dart';
import '../models/user_activity.dart';
import '../services/period_service.dart';
import '../services/follow_service.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/comment_service.dart';
import '../core/theme.dart';
import '../core/avatar_colors.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/activity_feed_card.dart';
import 'discussion_screen.dart';
import 'period_screen.dart';
import 'profile_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Keşfet', icon: Icon(Icons.explore, size: 20)),
            Tab(text: 'Takip', icon: Icon(Icons.people, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExploreTab(),
          _FollowingTab(),
        ],
      ),
    );
  }
}

// ==================== EXPLORE TAB ====================

class _ExploreTab extends StatefulWidget {
  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  Key _refreshKey = UniqueKey();

  Future<void> _onRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
    // Görsel geri bildirim için kısa bekleme
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        key: _refreshKey,
        padding: const EdgeInsets.all(16),
        children: [
          // Active Discussions Section
          const SectionHeader(
            icon: Icons.forum,
            title: 'Aktif Tartışmalar',
            subtitle: 'Şu anda tartışılan makaleler',
          ),
          const SizedBox(height: 12),
          _ActiveDiscussionsSection(),
          const SizedBox(height: 24),

          // Voting This Period Section
          const SectionHeader(
            icon: Icons.how_to_vote,
            title: 'Aktif Oylamalar',
            subtitle: 'Oyunu kullan, tartismayi belirle',
          ),
          const SizedBox(height: 12),
          _VotingPeriodsSection(),
        ],
      ),
    );
  }
}

// ==================== FOLLOWING TAB ====================

class _FollowingTab extends StatefulWidget {
  @override
  State<_FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends State<_FollowingTab> {
  Key _refreshKey = UniqueKey();

  Future<void> _onRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUid = authService.currentUser?.uid;

    if (currentUid == null) {
      return const EmptyStateScreen(
        icon: Icons.login,
        title: 'Giriş yapın',
        message: 'Takip ettiğiniz kişilerin aktivitelerini görmek için giriş yapın',
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        key: _refreshKey,
        padding: const EdgeInsets.all(16),
        children: [
          // Activity Feed Section
          const SectionHeader(
            icon: Icons.dynamic_feed,
            title: 'Aktivite Akışı',
            subtitle: 'Takip ettiğiniz kişilerin aktiviteleri',
          ),
          const SizedBox(height: 12),
          _ActivityFeedSection(currentUid: currentUid),
          const SizedBox(height: 24),

          // Suggested Users
          const SectionHeader(
            icon: Icons.person_add,
            title: 'Önerilen Kullanıcılar',
            subtitle: 'Yeni kişiler keşfet',
          ),
          const SizedBox(height: 12),
          _SuggestedUsersSection(currentUid: currentUid),
        ],
      ),
    );
  }
}

// ==================== ACTIVITY FEED SECTION ====================

class _ActivityFeedSection extends StatelessWidget {
  final String currentUid;

  const _ActivityFeedSection({required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final activityService = ActivityService();

    return StreamBuilder<List<UserActivity>>(
      stream: activityService.getFollowedUsersActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              3,
              (index) => const UserCardSkeleton(),
            ),
          );
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.feed_outlined,
            message: 'Henüz aktivite yok',
            submessage: 'Takip ettiğiniz kullanıcıların aktiviteleri burada görünecek',
          );
        }

        return Column(
          children: activities.map((activity) {
            return ActivityFeedCard(
              activity: activity,
              onTap: () => _navigateToTarget(context, activity),
              onUserTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: activity.uid),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _navigateToTarget(BuildContext context, UserActivity activity) async {
    switch (activity.type) {
      case ActivityType.comment:
      case ActivityType.vote:
      case ActivityType.suggestion:
        // Navigate to discussion or period screen
        if (activity.periodId != null && activity.targetId.isNotEmpty) {
          final periodService = PeriodService();
          final period = await periodService.getPeriodOnce(activity.periodId!);
          final article = await periodService.getArticleOnce(activity.periodId!, activity.targetId);
          if (period != null && article != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiscussionScreen(
                  period: period,
                  article: article,
                ),
              ),
            );
          }
        }
        break;
      case ActivityType.join:
        // Navigate to community (period screen)
        if (activity.communityId != null && context.mounted) {
          // For now, navigate to profile - community navigation would need community object
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: activity.uid),
            ),
          );
        }
        break;
    }
  }
}

class _SuggestedUsersSection extends StatelessWidget {
  final String currentUid;

  const _SuggestedUsersSection({required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();

    return StreamBuilder<List<UserProfile>>(
      stream: followService.getSuggestedUsers(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              3,
              (index) => const UserCardSkeleton(),
            ),
          );
        }

        final suggestions = snapshot.data ?? [];

        if (suggestions.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.check_circle,
            message: 'Şimdilik öneri yok',
          );
        }

        return Column(
          children: suggestions.map((user) => _SuggestedUserCard(user: user)).toList(),
        );
      },
    );
  }
}

class _SuggestedUserCard extends StatelessWidget {
  final UserProfile user;

  const _SuggestedUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();
    final color = avatarColors[user.avatarColorIndex];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user.bio ?? '${user.stats.totalComments} yorum',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: StreamBuilder<bool>(
          stream: followService.isFollowing(user.uid),
          builder: (context, snapshot) {
            final isFollowing = snapshot.data ?? false;

            return TextButton(
              onPressed: () async {
                try {
                  if (isFollowing) {
                    await followService.unfollowUser(user.uid);
                  } else {
                    await followService.followUser(user.uid);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e')),
                    );
                  }
                }
              },
              child: Text(isFollowing ? 'Takipte' : 'Takip Et'),
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: user.uid),
            ),
          );
        },
      ),
    );
  }
}

// ==================== EXISTING SECTIONS ====================

class _ActiveDiscussionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final periodService = PeriodService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: periodService.getActiveDiscussions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              2,
              (index) => const ArticleCardSkeleton(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final discussions = snapshot.data ?? [];

        if (discussions.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.chat_bubble_outline,
            message: 'Henuz aktif tartisma yok',
          );
        }

        return Column(
          children: discussions.map((data) {
            final period = data['period'] as Period;
            final community = data['community'] as Community;
            final eligibleCount = data['eligibleArticleCount'] as int;

            return _DiscussionPeriodCard(
              period: period,
              community: community,
              eligibleArticleCount: eligibleCount,
            );
          }).toList(),
        );
      },
    );
  }
}

class _VotingPeriodsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final periodService = PeriodService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: periodService.getVotingPeriods(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              2,
              (index) => const UserCardSkeleton(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final votingPeriods = snapshot.data ?? [];

        if (votingPeriods.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.how_to_vote_outlined,
            message: 'Su anda oylama yapilan topluluk yok',
          );
        }

        return Column(
          children: votingPeriods.map((data) {
            final period = data['period'] as Period;
            final community = data['community'] as Community;
            final articleCount = data['articleCount'] as int;
            return _VotingPeriodCard(
              period: period,
              community: community,
              articleCount: articleCount,
            );
          }).toList(),
        );
      },
    );
  }
}

class _DiscussionPeriodCard extends StatelessWidget {
  final Period period;
  final Community community;
  final int eligibleArticleCount;

  const _DiscussionPeriodCard({
    required this.period,
    required this.community,
    required this.eligibleArticleCount,
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
              builder: (context) => PeriodScreen(community: community),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community badge and phase
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
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
                  Text(period.phaseEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chat_bubble,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Period title
              Text(
                period.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (period.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  period.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // Stats
              Row(
                children: [
                  Icon(
                    Icons.article,
                    size: 16,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$eligibleArticleCount makale tartisiliyor',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (period.dateRangeDisplay != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period.dateRangeDisplay!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VotingPeriodCard extends StatelessWidget {
  final Period period;
  final Community community;
  final int articleCount;

  const _VotingPeriodCard({
    required this.period,
    required this.community,
    required this.articleCount,
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
              builder: (context) => PeriodScreen(community: community),
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                    const SizedBox(height: 2),
                    Text(
                      period.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$articleCount makale - oylama devam ediyor',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
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
