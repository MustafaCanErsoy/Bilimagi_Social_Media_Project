import 'package:flutter/material.dart';
import '../models/community_membership.dart';
import '../core/avatar_colors.dart';
import '../core/theme.dart';

/// Member list tile for community members screen
class MemberListTile extends StatelessWidget {
  final CommunityMembership membership;
  final bool isCurrentUserOwner;
  final VoidCallback? onTap;
  final VoidCallback? onFollowToggle;
  final bool isFollowing;
  final ValueChanged<MemberRole>? onRoleChange;
  final VoidCallback? onRemove;

  const MemberListTile({
    super.key,
    required this.membership,
    this.isCurrentUserOwner = false,
    this.onTap,
    this.onFollowToggle,
    this.isFollowing = false,
    this.onRoleChange,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = getAvatarColor(membership.uid);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: avatarColor.withValues(alpha: 0.2),
        child: Text(
          membership.displayName.isNotEmpty
              ? membership.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: avatarColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              membership.displayName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _buildRoleBadge(context),
        ],
      ),
      subtitle: membership.isPending
          ? Text(
              MemberStatus.pending.label,
              style: TextStyle(color: AppTheme.accentColor),
            )
          : null,
      trailing: _buildTrailing(context),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    if (membership.role == MemberRole.member) {
      return const SizedBox.shrink();
    }

    final Color badgeColor;
    switch (membership.role) {
      case MemberRole.owner:
        badgeColor = AppTheme.accentColor;
        break;
      case MemberRole.moderator:
        badgeColor = AppTheme.secondaryColor;
        break;
      default:
        badgeColor = AppTheme.getTextTertiary(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        membership.role.label,
        style: TextStyle(
          fontSize: 11,
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    // For pending members, show approve/reject
    if (membership.isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: AppTheme.secondaryColor),
            onPressed: () => _showApproveDialog(context),
            tooltip: 'Onayla',
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
            onPressed: () => _showRejectDialog(context),
            tooltip: 'Reddet',
          ),
        ],
      );
    }

    // For approved members
    if (!isCurrentUserOwner) {
      // Regular view - show follow button
      if (onFollowToggle != null) {
        return TextButton(
          onPressed: onFollowToggle,
          child: Text(isFollowing ? 'Takibi Bırak' : 'Takip Et'),
        );
      }
      return null;
    }

    // Owner view - show menu
    if (membership.isOwner) {
      return null; // Can't modify owner
    }

    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        if (membership.role == MemberRole.member)
          const PopupMenuItem(
            value: 'make_mod',
            child: ListTile(
              leading: Icon(Icons.shield),
              title: Text('Moderator Yap'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (membership.role == MemberRole.moderator)
          const PopupMenuItem(
            value: 'remove_mod',
            child: ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Moderatorluktan Al'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: 'remove',
          child: ListTile(
            leading: Icon(Icons.person_remove, color: AppTheme.errorColor),
            title: Text('Topluluktan Çıkar', style: TextStyle(color: AppTheme.errorColor)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'make_mod':
        onRoleChange?.call(MemberRole.moderator);
        break;
      case 'remove_mod':
        onRoleChange?.call(MemberRole.member);
        break;
      case 'remove':
        _showRemoveDialog(context);
        break;
    }
  }

  void _showApproveDialog(BuildContext context) {
    // This would be handled by parent widget
  }

  void _showRejectDialog(BuildContext context) {
    // This would be handled by parent widget
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üyeyi Çıkar'),
        content: Text('${membership.displayName} topluluktan çıkarılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
  }
}
