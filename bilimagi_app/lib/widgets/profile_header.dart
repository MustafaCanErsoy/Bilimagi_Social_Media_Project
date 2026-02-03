import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';
import '../core/theme.dart';

/// Profile header widget with gradient, avatar, and stats
/// v7.2: Animated gradient header with photo support
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isCurrentUser;
  final bool isEditable;
  final VoidCallback? onEditPhoto;
  final VoidCallback? onFollowersPressed;
  final VoidCallback? onFollowingPressed;
  final Animation<double>? fadeAnimation;
  final Animation<double>? scaleAnimation;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    this.isEditable = false,
    this.onEditPhoto,
    this.onFollowersPressed,
    this.onFollowingPressed,
    this.fadeAnimation,
    this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = _buildContent(context);

    if (fadeAnimation != null && scaleAnimation != null) {
      content = FadeTransition(
        opacity: fadeAnimation!,
        child: ScaleTransition(
          scale: scaleAnimation!,
          child: content,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.splashGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatar(context),
        const SizedBox(height: 16),
        _buildName(),
        const SizedBox(height: 4),
        _buildEmail(),
        const SizedBox(height: 20),
        _buildFollowStats(context),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatarColors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      const Color(0xFF9B59B6),
      const Color(0xFF3498DB),
      const Color(0xFFE74C3C),
      const Color(0xFF2ECC71),
      const Color(0xFFF39C12),
      const Color(0xFF1ABC9C),
    ];

    final color = avatarColors[profile.avatarColorIndex];
    final hasPhoto = profile.photoURL != null && profile.photoURL!.isNotEmpty;

    Widget avatar;
    if (hasPhoto) {
      avatar = CircleAvatar(
        radius: 55,
        backgroundColor: color,
        backgroundImage: NetworkImage(profile.photoURL!),
        onBackgroundImageError: (e, s) {},
        child: null,
      );
    } else {
      avatar = CircleAvatar(
        radius: 55,
        backgroundColor: color,
        child: Text(
          profile.displayName.isNotEmpty
              ? profile.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (isEditable && onEditPhoto != null) {
      return GestureDetector(
        onTap: onEditPhoto,
        child: Stack(
          children: [
            avatar,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return avatar;
  }

  Widget _buildName() {
    return Text(
      profile.displayName,
      style: AppTypography.h2.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmail() {
    return Text(
      profile.email,
      style: AppTypography.body.copyWith(
        color: Colors.white.withValues(alpha: 0.8),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFollowStats(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFollowItem(
          count: profile.stats.followersCount,
          label: 'Takipci',
          onTap: onFollowersPressed,
        ),
        Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          color: Colors.white.withValues(alpha: 0.3),
        ),
        _buildFollowItem(
          count: profile.stats.followingCount,
          label: 'Takip',
          onTap: onFollowingPressed,
        ),
      ],
    );
  }

  Widget _buildFollowItem({
    required int count,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
