import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/community_membership.dart';
import '../core/avatar_colors.dart';
import '../core/theme.dart';
import '../services/community_service.dart';

/// Community card for listing communities
class CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;
  final bool showMembershipButton;

  const CommunityCard({
    super.key,
    required this.community,
    this.onTap,
    this.showMembershipButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final communityService = CommunityService();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Community icon/emoji
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: avatarColors[community.colorIndex % avatarColors.length]
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: community.iconEmoji != null
                      ? Text(
                          community.iconEmoji!,
                          style: const TextStyle(fontSize: 28),
                        )
                      : Icon(
                          Icons.groups,
                          size: 28,
                          color: avatarColors[community.colorIndex % avatarColors.length],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Community info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      community.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            community.displayCategory,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Member count
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: AppTheme.getTextTertiary(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${community.stats.memberCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getTextTertiary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Membership button
              if (showMembershipButton)
                StreamBuilder<MemberStatus?>(
                  stream: communityService.getMembershipStatus(community.id),
                  builder: (context, snapshot) {
                    final status = snapshot.data;
                    return _buildMembershipButton(context, status, communityService);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipButton(
    BuildContext context,
    MemberStatus? status,
    CommunityService service,
  ) {
    if (status == MemberStatus.approved) {
      return TextButton(
        onPressed: () => _showLeaveDialog(context, service),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.errorColor,
        ),
        child: const Text('Ayrıl'),
      );
    }

    if (status == MemberStatus.pending) {
      return TextButton(
        onPressed: null,
        child: Text(
          'Beklemede',
          style: TextStyle(color: AppTheme.getTextTertiary(context)),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _requestMembership(context, service),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('Katıl'),
    );
  }

  Future<void> _requestMembership(BuildContext context, CommunityService service) async {
    try {
      await service.requestMembership(community.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Katılma isteğiniz gönderildi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _showLeaveDialog(BuildContext context, CommunityService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Topluluktan Ayrıl'),
        content: Text('${community.name} topluluğundan ayrılmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await service.leaveCommunity(community.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topluluktan ayrıldınız')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }
}
