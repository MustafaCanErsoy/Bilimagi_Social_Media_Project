import 'dart:async';
import 'package:flutter/material.dart';
import '../models/period.dart';
import '../models/community.dart';
import '../models/user_profile.dart';
import '../models/user_activity.dart';
import '../services/period_service.dart';
import '../services/follow_service.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value.toLowerCase().trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

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
          // v10.0: Search Field
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Donem veya topluluk ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Active Discussions Section
          const SectionHeader(
            icon: Icons.forum,
            title: 'Aktif Tartışmalar',
            subtitle: 'Şu anda tartışılan makaleler',
          ),
          const SizedBox(height: 12),
          _ActiveDiscussionsSection(searchQuery: _searchQuery),
          const SizedBox(height: 24),

          // Voting This Period Section
          const SectionHeader(
            icon: Icons.how_to_vote,
            title: 'Aktif Oylamalar',
            subtitle: 'Oyunu kullan, tartismayi belirle',
          ),
          const SizedBox(height: 12),
          _VotingPeriodsSection(searchQuery: _searchQuery),
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
      child: CustomScrollView(
        key: _refreshKey,
        slivers: [
          // Suggested Users - Horizontal at top
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SectionHeader(
                    icon: Icons.person_add,
                    title: 'Önerilen Kullanıcılar',
                    subtitle: 'Yeni kişiler keşfet',
                  ),
                ),
                _HorizontalSuggestedUsers(currentUid: currentUid),
                const SizedBox(height: 16),
                const Divider(height: 1),
              ],
            ),
          ),

          // Activity Feed Header + Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    icon: Icons.dynamic_feed,
                    title: 'Aktivite Akışı',
                    subtitle: 'Takip ettiğiniz kişilerin aktiviteleri',
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Activity Feed - Full width stream
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _ActivityFeedSliver(currentUid: currentUid),
          ),
        ],
      ),
    );
  }
}

// Horizontal suggested users widget
class _HorizontalSuggestedUsers extends StatelessWidget {
  final String currentUid;

  const _HorizontalSuggestedUsers({required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();

    return StreamBuilder<List<UserProfile>>(
      stream: followService.getSuggestedUsers(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final suggestions = snapshot.data ?? [];

        if (suggestions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Şimdilik öneri yok',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final user = suggestions[index];
              return _CompactUserCard(user: user);
            },
          ),
        );
      },
    );
  }
}

// Compact user card for horizontal list
class _CompactUserCard extends StatelessWidget {
  final UserProfile user;

  const _CompactUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();
    final color = avatarColors[user.avatarColorIndex];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: user.uid),
          ),
        );
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            StreamBuilder<bool>(
              stream: followService.isFollowing(user.uid),
              builder: (context, snapshot) {
                final isFollowing = snapshot.data ?? false;
                return SizedBox(
                  height: 24,
                  child: TextButton(
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: isFollowing
                          ? Colors.grey.shade200
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      isFollowing ? 'Takipte' : 'Takip Et',
                      style: TextStyle(
                        fontSize: 10,
                        color: isFollowing ? Colors.grey.shade700 : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// v10.0: Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

// v10.0: Sliver-based Activity Feed for full-screen scrolling
class _ActivityFeedSliver extends StatefulWidget {
  final String currentUid;

  const _ActivityFeedSliver({required this.currentUid});

  @override
  State<_ActivityFeedSliver> createState() => _ActivityFeedSliverState();
}

class _ActivityFeedSliverState extends State<_ActivityFeedSliver> {
  ActivityType? _selectedFilter;
  int _currentLimit = 20;

  void _loadMore() {
    setState(() => _currentLimit += 20);
  }

  void _navigateToTarget(BuildContext context, UserActivity activity) async {
    switch (activity.type) {
      case ActivityType.comment:
      case ActivityType.vote:
      case ActivityType.suggestion:
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
        if (activity.communityId != null && context.mounted) {
          final communityService = CommunityService();
          final community = await communityService.getCommunityOnce(activity.communityId!);
          if (community != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PeriodScreen(community: community),
              ),
            );
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityService = ActivityService();

    return StreamBuilder<List<UserActivity>>(
      stream: activityService.getFollowedUsersActivities(),
      builder: (context, snapshot) {
        // Filter chips first
        final filterChips = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tümü',
                  isSelected: _selectedFilter == null,
                  onSelected: () => setState(() => _selectedFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Yorumlar',
                  isSelected: _selectedFilter == ActivityType.comment,
                  onSelected: () => setState(() => _selectedFilter = ActivityType.comment),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Oylar',
                  isSelected: _selectedFilter == ActivityType.vote,
                  onSelected: () => setState(() => _selectedFilter = ActivityType.vote),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Katılımlar',
                  isSelected: _selectedFilter == ActivityType.join,
                  onSelected: () => setState(() => _selectedFilter = ActivityType.join),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Öneriler',
                  isSelected: _selectedFilter == ActivityType.suggestion,
                  onSelected: () => setState(() => _selectedFilter = ActivityType.suggestion),
                ),
              ],
            ),
          ),
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildListDelegate([
              filterChips,
              const UserCardSkeleton(),
              const UserCardSkeleton(),
              const UserCardSkeleton(),
            ]),
          );
        }

        var activities = snapshot.data ?? [];

        // Apply filter
        if (_selectedFilter != null) {
          activities = activities.where((a) => a.type == _selectedFilter).toList();
        }

        // Apply pagination
        final hasMore = activities.length > _currentLimit;
        final displayedActivities = activities.take(_currentLimit).toList();

        if (displayedActivities.isEmpty) {
          return SliverList(
            delegate: SliverChildListDelegate([
              filterChips,
              EmptyStateCard(
                icon: Icons.feed_outlined,
                message: _selectedFilter != null
                    ? 'Bu filtreyle aktivite bulunamadı'
                    : 'Henüz aktivite yok',
                submessage: _selectedFilter == null
                    ? 'Takip ettiğiniz kullanıcıların aktiviteleri burada görünecek'
                    : null,
              ),
            ]),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // First item is filter chips
              if (index == 0) return filterChips;

              // Last item might be "Load More" button
              if (index == displayedActivities.length + 1) {
                if (hasMore) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: _loadMore,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Daha Fazla Yükle'),
                      ),
                    ),
                  );
                }
                return const SizedBox(height: 32);
              }

              // Activity cards
              final activity = displayedActivities[index - 1];
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
                showCommunityHint: activity.type == ActivityType.join,
              );
            },
            childCount: displayedActivities.length + 2, // chips + activities + load more/spacer
          ),
        );
      },
    );
  }
}

// ==================== EXISTING SECTIONS ====================

class _ActiveDiscussionsSection extends StatelessWidget {
  final String searchQuery; // v10.0: Search filter

  const _ActiveDiscussionsSection({this.searchQuery = ''});

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

        var discussions = snapshot.data ?? [];

        // v10.0: Apply search filter
        if (searchQuery.isNotEmpty) {
          discussions = discussions.where((data) {
            final period = data['period'] as Period;
            final community = data['community'] as Community;
            return period.title.toLowerCase().contains(searchQuery) ||
                community.name.toLowerCase().contains(searchQuery);
          }).toList();
        }

        if (discussions.isEmpty) {
          return EmptyStateCard(
            icon: Icons.chat_bubble_outline,
            message: searchQuery.isNotEmpty
                ? 'Aramayla eslesen tartisma bulunamadi'
                : 'Henuz aktif tartisma yok',
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
  final String searchQuery; // v10.0: Search filter

  const _VotingPeriodsSection({this.searchQuery = ''});

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

        var votingPeriods = snapshot.data ?? [];

        // v10.0: Apply search filter
        if (searchQuery.isNotEmpty) {
          votingPeriods = votingPeriods.where((data) {
            final period = data['period'] as Period;
            final community = data['community'] as Community;
            return period.title.toLowerCase().contains(searchQuery) ||
                community.name.toLowerCase().contains(searchQuery);
          }).toList();
        }

        if (votingPeriods.isEmpty) {
          return EmptyStateCard(
            icon: Icons.how_to_vote_outlined,
            message: searchQuery.isNotEmpty
                ? 'Aramayla eslesen oylama bulunamadi'
                : 'Su anda oylama yapilan topluluk yok',
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
