import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/interest_tags_display.dart';
import '../widgets/profile_activity_card.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';
import 'profile_edit_screen.dart';
import 'saved_articles_screen.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import 'settings_screen.dart';

/// Profile screen with animations and modern design
/// v7.2: Redesigned with CustomScrollView and staggered animations
class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _profileService = ProfileService();
  final _followService = FollowService();
  final _authService = AuthService();

  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _headerScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _headerController.forward().then((_) {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _authService.currentUser?.uid;
    final isCurrentUser = widget.userId == null || widget.userId == currentUid;
    final targetUid = widget.userId ?? currentUid;

    return Scaffold(
      body: StreamBuilder<UserProfile?>(
        stream: isCurrentUser
            ? _profileService.getCurrentUserProfile()
            : _profileService.getUserProfile(widget.userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Profil bulunamadi'));
          }

          return _buildContent(context, profile, isCurrentUser, targetUid);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserProfile profile,
    bool isCurrentUser,
    String? targetUid,
  ) {
    return CustomScrollView(
      slivers: [
        // Collapsing header
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: FadeTransition(
              opacity: _headerFadeAnimation,
              child: ScaleTransition(
                scale: _headerScaleAnimation,
                child: ProfileHeader(
                  profile: profile,
                  isCurrentUser: isCurrentUser,
                  onFollowersPressed: () => _navigateToFollowers(profile),
                  onFollowingPressed: () => _navigateToFollowing(profile),
                ),
              ),
            ),
          ),
          actions: [
            if (isCurrentUser && widget.userId == null)
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Ayarlar',
                onPressed: () => _navigateToSettings(),
              ),
          ],
        ),

        // Action buttons
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _contentSlideAnimation,
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isCurrentUser
                    ? _buildEditButton(context, profile)
                    : _buildFollowButton(context, profile.uid),
              ),
            ),
          ),
        ),

        // Interests section
        if (profile.interests.isNotEmpty)
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _contentSlideAnimation,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildInterestsSection(context, profile),
                ),
              ),
            ),
          ),

        // Stats section
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _contentSlideAnimation,
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStatsCard(context, profile),
              ),
            ),
          ),
        ),

        // Bio section
        if (profile.bio != null && profile.bio!.isNotEmpty)
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _contentSlideAnimation,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBioCard(context, profile),
                ),
              ),
            ),
          ),

        // Activity section (only for current user)
        if (isCurrentUser)
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _contentSlideAnimation,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProfileActivityCard(userId: profile.uid),
                ),
              ),
            ),
          ),

        // Saved articles (only for current user)
        if (isCurrentUser)
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _contentSlideAnimation,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSavedArticlesCard(context),
                ),
              ),
            ),
          ),

        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, UserProfile profile) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _navigateToEditProfile(profile),
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Profili Duzenle'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, String targetUid) {
    return StreamBuilder<bool>(
      stream: _followService.isFollowing(targetUid),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (isFollowing) {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => _unfollowUser(targetUid),
              icon: const Icon(Icons.person_remove, size: 18),
              label: const Text('Takipten Cik'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () => _followUser(targetUid),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Takip Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildInterestsSection(BuildContext context, UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.interests, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ilgi Alanlari',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InterestTagsDisplay(interests: profile.interests),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Istatistikler',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  Icons.how_to_vote,
                  'Oylar',
                  profile.stats.totalVotes.toString(),
                ),
                _buildStatItem(
                  context,
                  Icons.comment,
                  'Yorumlar',
                  profile.stats.totalComments.toString(),
                ),
                _buildStatItem(
                  context,
                  Icons.calendar_today,
                  'Uyelik',
                  _formatJoinDate(profile.stats.joinedAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.h3.copyWith(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.getTextMuted(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBioCard(BuildContext context, UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Hakkinda',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              profile.bio!,
              style: AppTypography.body.copyWith(
                color: AppColors.getTextPrimary(context),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedArticlesCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bookmark,
            color: AppColors.accent,
            size: 24,
          ),
        ),
        title: Text(
          'Kaydedilen Makaleler',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        subtitle: Text(
          'Favori makalelerine goz at',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.getTextMuted(context),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.getTextMuted(context),
        ),
        onTap: () => _navigateToSavedArticles(),
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays < 30) {
      return '${diff.inDays} gun';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} ay';
    } else {
      return '${(diff.inDays / 365).floor()} yil';
    }
  }

  // Navigation methods
  void _navigateToFollowers(UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersScreen(
          userId: profile.uid,
          userName: profile.displayName,
        ),
      ),
    );
  }

  void _navigateToFollowing(UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowingScreen(
          userId: profile.uid,
          userName: profile.displayName,
        ),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _navigateToEditProfile(UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(profile: profile),
      ),
    );
  }

  void _navigateToSavedArticles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavedArticlesScreen(),
      ),
    );
  }

  // Follow actions
  Future<void> _followUser(String targetUid) async {
    try {
      await _followService.followUser(targetUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takip edildi!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _unfollowUser(String targetUid) async {
    try {
      await _followService.unfollowUser(targetUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takipten cikildi'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
