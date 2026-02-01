import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/community_ban.dart';
import '../models/moderation_log.dart';
import '../services/moderation_service.dart';
import '../core/theme.dart';
import '../core/time_utils.dart';

/// Dashboard screen for moderators to view bans, hidden comments, and audit log
class ModerationDashboardScreen extends StatefulWidget {
  final Community community;

  const ModerationDashboardScreen({
    super.key,
    required this.community,
  });

  @override
  State<ModerationDashboardScreen> createState() => _ModerationDashboardScreenState();
}

class _ModerationDashboardScreenState extends State<ModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _moderationService = ModerationService();

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
        title: const Text('Moderasyon Paneli'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Yasaklilar', icon: Icon(Icons.block, size: 18)),
            Tab(text: 'Islem Gecmisi', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BannedUsersTab(
            communityId: widget.community.id,
            moderationService: _moderationService,
          ),
          _AuditLogTab(
            communityId: widget.community.id,
            moderationService: _moderationService,
          ),
        ],
      ),
    );
  }
}

// ==================== BANNED USERS TAB ====================

class _BannedUsersTab extends StatelessWidget {
  final String communityId;
  final ModerationService moderationService;

  const _BannedUsersTab({
    required this.communityId,
    required this.moderationService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityBan>>(
      stream: moderationService.getBannedUsers(communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bans = snapshot.data ?? [];

        if (bans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Yasakli kullanici yok',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Topluluk kurallarina uyan herkes katilabilir',
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bans.length,
          itemBuilder: (context, index) {
            final ban = bans[index];
            return _BanCard(
              ban: ban,
              onUnban: () => _confirmUnban(context, ban),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmUnban(BuildContext context, CommunityBan ban) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yasagi Kaldir'),
        content: Text('${ban.bannedDisplayName} adli kullanicinin yasagini kaldirmak istediginize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yasagi Kaldir'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await moderationService.unbanUser(
          communityId: communityId,
          targetUid: ban.bannedUid,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${ban.bannedDisplayName} yasagi kaldirildi')),
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

class _BanCard extends StatelessWidget {
  final CommunityBan ban;
  final VoidCallback onUnban;

  const _BanCard({
    required this.ban,
    required this.onUnban,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.red.shade100,
                  child: Icon(Icons.block, color: Colors.red.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ban.bannedDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Yasaklayan: ${ban.bannedByDisplayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onUnban,
                  child: const Text('Kaldir'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ban.reason,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  formatRelativeTime(ban.bannedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ban.isPermanent ? 'Kalici' : 'Gecici',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== AUDIT LOG TAB ====================

class _AuditLogTab extends StatelessWidget {
  final String communityId;
  final ModerationService moderationService;

  const _AuditLogTab({
    required this.communityId,
    required this.moderationService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ModerationLog>>(
      stream: moderationService.getModerationLogs(communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henuz islem yok',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Moderasyon islemleri burada gorunecek',
                  style: TextStyle(color: AppTheme.getTextSecondary(context)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _LogCard(log: log);
          },
        );
      },
    );
  }
}

class _LogCard extends StatelessWidget {
  final ModerationLog log;

  const _LogCard({required this.log});

  IconData get _icon {
    switch (log.type) {
      case ModerationActionType.hideComment:
        return Icons.visibility_off;
      case ModerationActionType.unhideComment:
        return Icons.visibility;
      case ModerationActionType.banUser:
        return Icons.block;
      case ModerationActionType.unbanUser:
        return Icons.check_circle;
      case ModerationActionType.approveRequest:
        return Icons.person_add;
      case ModerationActionType.rejectRequest:
        return Icons.person_remove;
      case ModerationActionType.approveSuggestion:
        return Icons.article;
      case ModerationActionType.rejectSuggestion:
        return Icons.article_outlined;
      case ModerationActionType.setRole:
        return Icons.admin_panel_settings;
    }
  }

  Color get _iconColor {
    switch (log.type) {
      case ModerationActionType.hideComment:
      case ModerationActionType.banUser:
      case ModerationActionType.rejectRequest:
      case ModerationActionType.rejectSuggestion:
        return Colors.red.shade600;
      case ModerationActionType.unhideComment:
      case ModerationActionType.unbanUser:
      case ModerationActionType.approveRequest:
      case ModerationActionType.approveSuggestion:
        return Colors.green.shade600;
      case ModerationActionType.setRole:
        return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _iconColor.withValues(alpha: 0.1),
              child: Icon(_icon, size: 16, color: _iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: log.moderatorDisplayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: ' ${log.type.displayName.toLowerCase()}',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        if (log.targetDisplayName != null) ...[
                          TextSpan(
                            text: ': ${log.targetDisplayName}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (log.reason != null && log.reason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${log.reason}"',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    formatRelativeTime(log.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
