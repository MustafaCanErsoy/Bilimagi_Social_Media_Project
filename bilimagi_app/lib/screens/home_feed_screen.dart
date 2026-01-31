import 'package:flutter/material.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../models/community.dart';
import '../models/user_profile.dart';
import '../services/week_service.dart';
import '../services/follow_service.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';
import '../core/avatar_colors.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state_card.dart';
import 'discussion_screen.dart';
import 'week_screen.dart';
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

class _ExploreTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
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

        // Voting This Week Section
        const SectionHeader(
          icon: Icons.how_to_vote,
          title: 'Bu Hafta Oylama',
          subtitle: 'Oyunu kullan, kazananı belirle',
        ),
        const SizedBox(height: 12),
        _VotingWeeksSection(),
      ],
    );
  }
}

// ==================== FOLLOWING TAB ====================

class _FollowingTab extends StatelessWidget {
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Following Activity
        const SectionHeader(
          icon: Icons.people,
          title: 'Takip Edilenler',
          subtitle: 'Takip ettiğiniz kişiler',
        ),
        const SizedBox(height: 12),
        _FollowingListSection(currentUid: currentUid),
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
    );
  }
}

class _FollowingListSection extends StatelessWidget {
  final String currentUid;

  const _FollowingListSection({required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();

    return StreamBuilder<List<UserProfile>>(
      stream: followService.getFollowing(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final following = snapshot.data ?? [];

        if (following.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.person_search,
            message: 'Henüz kimseyi takip etmiyorsunuz',
            submessage: 'Topluluklardaki tartışmalara katılın ve ilginç kullanıcıları keşfedin!',
          );
        }

        return Column(
          children: following.map((user) => _FollowingUserCard(user: user)).toList(),
        );
      },
    );
  }
}

class _FollowingUserCard extends StatelessWidget {
  final UserProfile user;

  const _FollowingUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
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
          '${user.stats.totalComments} yorum · ${user.stats.totalVotes} oy',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
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
          return const EmptyStateCard(
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
          return const EmptyStateCard(
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
