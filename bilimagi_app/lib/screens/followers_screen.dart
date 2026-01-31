import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/follow_service.dart';
import '../core/theme.dart';
import 'profile_screen.dart';

class FollowersScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();

    return Scaffold(
      appBar: AppBar(
        title: Text('$userName - Takipçiler'),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: followService.getFollowers(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final followers = snapshot.data ?? [];

          if (followers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz takipçi yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final follower = followers[index];
              return _buildUserTile(context, follower);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserProfile user) {
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

    final color = avatarColors[user.avatarColorIndex];

    return ListTile(
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
      subtitle: Text(user.email),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: user.uid),
          ),
        );
      },
    );
  }
}
