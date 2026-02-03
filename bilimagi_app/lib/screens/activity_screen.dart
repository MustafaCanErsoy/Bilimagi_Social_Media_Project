import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/community_service.dart';
import '../core/theme.dart';
import '../widgets/skeleton_loading.dart';
import 'profile_screen.dart';
import 'period_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _notificationService = NotificationService();
  final _communityService = CommunityService();
  Key _refreshKey = UniqueKey();
  NotificationType? _selectedFilter;
  String? _selectedCategory; // v10.0: Category filter (social, community, suggestions)

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında görünen bildirimleri okundu işaretle
    _markVisibleAsRead();
  }

  Future<void> _markVisibleAsRead() async {
    // Kısa bir gecikme ile bildirimleri okundu işaretle
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      await _notificationService.markAllAsRead();
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  PopupMenuItem<String> _buildStringFilterMenuItem(
    String value,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? AppTheme.primaryColor : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 18, color: AppTheme.primaryColor),
          ],
        ],
      ),
    );
  }

  /// v10.0: Filter notifications by category
  List<AppNotification> _filterByCategory(List<AppNotification> notifications) {
    if (_selectedCategory == null) return notifications;

    switch (_selectedCategory) {
      case 'social':
        return notifications.where((n) =>
          n.type == NotificationType.follow ||
          n.type == NotificationType.mention ||
          n.type == NotificationType.reply ||
          n.type == NotificationType.upvote
        ).toList();
      case 'community':
        return notifications.where((n) =>
          n.type == NotificationType.membershipRequest ||
          n.type == NotificationType.membershipApproved ||
          n.type == NotificationType.membershipRejected ||
          n.type == NotificationType.roleChanged ||
          n.type == NotificationType.memberRemoved
        ).toList();
      case 'suggestions':
        return notifications.where((n) =>
          n.type == NotificationType.suggestionApproved ||
          n.type == NotificationType.suggestionRejected
        ).toList();
      default:
        return notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: Badge(
              isLabelVisible: _selectedFilter != null || _selectedCategory != null,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filtrele',
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  _selectedFilter = null;
                  _selectedCategory = null;
                } else if (value.startsWith('cat_')) {
                  _selectedCategory = value.substring(4);
                  _selectedFilter = null;
                } else {
                  _selectedFilter = NotificationType.values.firstWhere(
                    (e) => e.name == value,
                    orElse: () => NotificationType.follow,
                  );
                  _selectedCategory = null;
                }
              });
            },
            itemBuilder: (context) => [
              _buildStringFilterMenuItem('all', 'Tümü', Icons.notifications, _selectedFilter == null && _selectedCategory == null),
              const PopupMenuDivider(),
              // Category filters (v10.0)
              _buildStringFilterMenuItem('cat_social', 'Sosyal', Icons.people, _selectedCategory == 'social'),
              _buildStringFilterMenuItem('cat_community', 'Topluluk', Icons.groups, _selectedCategory == 'community'),
              _buildStringFilterMenuItem('cat_suggestions', 'Öneriler', Icons.lightbulb, _selectedCategory == 'suggestions'),
              const PopupMenuDivider(),
              // Type filters
              _buildStringFilterMenuItem(NotificationType.follow.name, 'Takip', Icons.person_add, _selectedFilter == NotificationType.follow),
              _buildStringFilterMenuItem(NotificationType.mention.name, 'Bahsetme', Icons.alternate_email, _selectedFilter == NotificationType.mention),
              _buildStringFilterMenuItem(NotificationType.reply.name, 'Yanıt', Icons.reply, _selectedFilter == NotificationType.reply),
              _buildStringFilterMenuItem(NotificationType.upvote.name, 'Beğeni', Icons.thumb_up, _selectedFilter == NotificationType.upvote),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tümünü okundu işaretle',
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tüm bildirimler okundu olarak işaretlendi'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => const NotificationSkeleton(),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          var notifications = snapshot.data ?? [];

          // v10.0: Apply category or type filter
          if (_selectedCategory != null) {
            notifications = _filterByCategory(notifications);
          } else if (_selectedFilter != null) {
            notifications = notifications
                .where((n) => n.type == _selectedFilter)
                .toList();
          }

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // Bildirimleri zaman gruplarına ayır
          final grouped = _groupNotifications(notifications);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              key: _refreshKey,
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final item = grouped[index];
                if (item is String) {
                  // Section header
                  return _SectionHeader(title: item);
                } else {
                  final notification = item as AppNotification;
                  return _NotificationTile(
                    notification: notification,
                    onTap: () => _handleNotificationTap(
                      context,
                      notification,
                      _notificationService,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  List<dynamic> _groupNotifications(List<AppNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    final List<AppNotification> todayList = [];
    final List<AppNotification> yesterdayList = [];
    final List<AppNotification> thisWeekList = [];
    final List<AppNotification> thisMonthList = [];
    final List<AppNotification> olderList = [];

    for (final n in notifications) {
      final nDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (nDate.isAtSameMomentAs(today)) {
        todayList.add(n);
      } else if (nDate.isAtSameMomentAs(yesterday)) {
        yesterdayList.add(n);
      } else if (nDate.isAfter(thisWeekStart) || nDate.isAtSameMomentAs(thisWeekStart)) {
        thisWeekList.add(n);
      } else if (nDate.isAfter(thisMonthStart) || nDate.isAtSameMomentAs(thisMonthStart)) {
        thisMonthList.add(n);
      } else {
        olderList.add(n);
      }
    }

    final List<dynamic> result = [];

    if (todayList.isNotEmpty) {
      result.add('Bugün');
      result.addAll(todayList);
    }
    if (yesterdayList.isNotEmpty) {
      result.add('Dün');
      result.addAll(yesterdayList);
    }
    if (thisWeekList.isNotEmpty) {
      result.add('Bu Hafta');
      result.addAll(thisWeekList);
    }
    if (thisMonthList.isNotEmpty) {
      result.add('Bu Ay');
      result.addAll(thisMonthList);
    }
    if (olderList.isNotEmpty) {
      result.add('Daha Eski');
      result.addAll(olderList);
    }

    return result;
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: isDark ? Colors.grey[600] : AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz bildirim yok',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Etkileşimler burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
    NotificationService service,
  ) {
    // Mark as read
    service.markAsRead(notification.id);

    // Navigate based on type
    switch (notification.type) {
      case NotificationType.follow:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: notification.fromUid),
          ),
        );
        break;
      case NotificationType.mention:
      case NotificationType.reply:
      case NotificationType.upvote:
        // For now, navigate to the user's profile
        // TODO: Navigate to the specific comment when discussion screen supports deep linking
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: notification.fromUid),
          ),
        );
        break;
      case NotificationType.membershipRequest:
      case NotificationType.membershipApproved:
      case NotificationType.membershipRejected:
      case NotificationType.roleChanged:
      case NotificationType.memberRemoved:
        // v10.0: Navigate to community
        if (notification.communityId != null) {
          _navigateToCommunity(notification.communityId!);
        }
        break;
      case NotificationType.suggestionApproved:
      case NotificationType.suggestionRejected:
        // v10.0: Navigate to community if available
        if (notification.communityId != null) {
          _navigateToCommunity(notification.communityId!);
        }
        break;
    }
  }

  /// v10.0: Navigate to community
  Future<void> _navigateToCommunity(String communityId) async {
    try {
      final community = await _communityService.getCommunityOnce(communityId);
      if (community != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PeriodScreen(community: community),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Topluluk bulunamadı: $e')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: isDark ? Colors.grey[900] : Colors.grey[100],
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: notification.read
          ? Colors.transparent
          : (isDark
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.primaryColor.withValues(alpha: 0.05)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getIconBackgroundColor(),
          child: Icon(
            _getIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.preview != null) ...[
              const SizedBox(height: 4),
              Text(
                notification.preview!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
        trailing: notification.read
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: onTap,
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.reply:
        return Icons.reply;
      case NotificationType.upvote:
        return Icons.thumb_up;
      case NotificationType.membershipRequest:
        return Icons.person_add_alt;
      case NotificationType.membershipApproved:
        return Icons.check_circle;
      case NotificationType.membershipRejected:
        return Icons.cancel;
      case NotificationType.suggestionApproved:
      case NotificationType.suggestionRejected:
        return Icons.article;
      case NotificationType.roleChanged:
        return Icons.admin_panel_settings;
      case NotificationType.memberRemoved:
        return Icons.person_remove;
    }
  }

  Color _getIconBackgroundColor() {
    switch (notification.type) {
      case NotificationType.follow:
        return AppTheme.primaryColor;
      case NotificationType.mention:
        return const Color(0xFF3498DB);
      case NotificationType.reply:
        return const Color(0xFF2ECC71);
      case NotificationType.upvote:
        return const Color(0xFFF39C12);
      case NotificationType.membershipRequest:
        return AppTheme.primaryColor;
      case NotificationType.membershipApproved:
        return AppTheme.secondaryColor;
      case NotificationType.membershipRejected:
        return AppTheme.errorColor;
      case NotificationType.suggestionApproved:
        return AppTheme.secondaryColor;
      case NotificationType.suggestionRejected:
        return AppTheme.errorColor;
      case NotificationType.roleChanged:
        return Colors.purple;
      case NotificationType.memberRemoved:
        return Colors.red.shade700;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Az önce';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
