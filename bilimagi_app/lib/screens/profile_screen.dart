import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../core/theme.dart';
import 'profile_edit_screen.dart';
import 'saved_articles_screen.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId; // null = current user, string = other user

  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();
    final followService = FollowService();
    final authService = AuthService();
    final currentUid = authService.currentUser?.uid;
    final isCurrentUser = userId == null || userId == currentUid;
    final targetUid = userId ?? currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (isCurrentUser && userId == null)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Ayarlar',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: isCurrentUser
            ? profileService.getCurrentUserProfile()
            : profileService.getUserProfile(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Profil bulunamadı'));
          }

          return _buildProfileContent(
            context,
            profile,
            isCurrentUser,
            followService,
            targetUid,
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    UserProfile profile,
    bool isCurrentUser,
    FollowService followService,
    String? targetUid,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with avatar and name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              children: [
                // Avatar
                _buildAvatar(profile),
                const SizedBox(height: 16),
                // Display name
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  profile.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Followers / Following counts
                _buildFollowStats(context, profile),
                const SizedBox(height: 16),
                if (isCurrentUser) ...[
                  // Edit button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileEditScreen(profile: profile),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Profili Düzenle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ] else ...[
                  // Follow/Unfollow button for other users
                  _buildFollowButton(context, followService, profile.uid),
                ],
              ],
            ),
          ),

          // Stats section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İstatistikler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.how_to_vote,
                          'Oylar',
                          profile.stats.totalVotes.toString(),
                        ),
                        _buildStatItem(
                          Icons.comment,
                          'Yorumlar',
                          profile.stats.totalComments.toString(),
                        ),
                        _buildStatItem(
                          Icons.calendar_today,
                          'Üyelik',
                          _formatJoinDate(profile.stats.joinedAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bio section
          if (profile.bio != null && profile.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hakkında',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.bio!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Saved Articles (only for current user)
          if (isCurrentUser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    Icons.bookmark,
                    color: AppTheme.accentColor,
                  ),
                  title: const Text('Kaydedilen Makaleler'),
                  subtitle: const Text('Favori makalelerine göz at'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedArticlesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfile profile) {
    final avatarColors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF3498DB), // Blue
      const Color(0xFFE74C3C), // Red
      const Color(0xFF2ECC71), // Green
      const Color(0xFFF39C12), // Orange
      const Color(0xFF1ABC9C), // Turquoise
    ];

    final color = avatarColors[profile.avatarColorIndex];

    return CircleAvatar(
      radius: 50,
      backgroundColor: color,
      child: Text(
        profile.displayName.isNotEmpty
            ? profile.displayName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays < 30) {
      return '${diff.inDays} gün';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} ay';
    } else {
      return '${(diff.inDays / 365).floor()} yıl';
    }
  }

  Widget _buildFollowStats(BuildContext context, UserProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Followers
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowersScreen(
                  userId: profile.uid,
                  userName: profile.displayName,
                ),
              ),
            );
          },
          child: Column(
            children: [
              Text(
                profile.stats.followersCount.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Takipçi',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Following
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowingScreen(
                  userId: profile.uid,
                  userName: profile.displayName,
                ),
              ),
            );
          },
          child: Column(
            children: [
              Text(
                profile.stats.followingCount.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Takip',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    FollowService followService,
    String targetUid,
  ) {
    return StreamBuilder<bool>(
      stream: followService.isFollowing(targetUid),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (isFollowing) {
          return OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () async {
                    try {
                      await followService.unfollowUser(targetUid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Takipten çıkıldı'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e')),
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.person_remove, size: 18),
            label: const Text('Takipten Çık'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
          );
        } else {
          return ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () async {
                    try {
                      await followService.followUser(targetUid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Takip edildi!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e')),
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Takip Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
          );
        }
      },
    );
  }
}
