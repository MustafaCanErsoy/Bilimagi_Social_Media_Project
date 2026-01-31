import 'package:flutter/material.dart';
import '../models/community_membership.dart';
import '../core/theme.dart';
import '../services/community_service.dart';
import '../widgets/member_list_tile.dart';

/// Screen for viewing and managing community members
class CommunityMembersScreen extends StatefulWidget {
  final String communityId;

  const CommunityMembersScreen({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen>
    with SingleTickerProviderStateMixin {
  final _communityService = CommunityService();
  late TabController _tabController;
  MemberRole? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    _communityService.getUserRole(widget.communityId).listen((role) {
      if (mounted) {
        setState(() => _currentUserRole = role);
      }
    });
  }

  Future<void> _approveMember(String uid) async {
    try {
      await _communityService.approveMembership(widget.communityId, uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Üyelik onaylandı')),
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

  Future<void> _rejectMember(String uid) async {
    try {
      await _communityService.rejectMembership(widget.communityId, uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Üyelik reddedildi')),
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

  Future<void> _changeRole(String uid, MemberRole newRole) async {
    try {
      await _communityService.setMemberRole(widget.communityId, uid, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol ${newRole.label} olarak değiştirildi')),
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

  Future<void> _removeMember(String uid) async {
    try {
      await _communityService.removeMember(widget.communityId, uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Üye çıkarıldı')),
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

  @override
  Widget build(BuildContext context) {
    final isOwner = _currentUserRole == MemberRole.owner;
    final canManage = _currentUserRole == MemberRole.owner ||
        _currentUserRole == MemberRole.moderator;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Üyeler'),
        bottom: canManage
            ? TabBar(
                controller: _tabController,
                tabs: [
                  StreamBuilder<int>(
                    stream: _communityService.getPendingMemberCount(widget.communityId),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Bekleyen'),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Badge(
                                label: Text('$count'),
                                backgroundColor: AppTheme.accentColor,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const Tab(text: 'Üyeler'),
                ],
              )
            : null,
      ),
      body: canManage
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildPendingList(),
                _buildMembersList(isOwner),
              ],
            )
          : _buildMembersList(false),
    );
  }

  Widget _buildPendingList() {
    return StreamBuilder<List<CommunityMembership>>(
      stream: _communityService.getPendingMembers(widget.communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pending = snapshot.data ?? [];

        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bekleyen istek yok',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final member = pending[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(member.displayName),
                subtitle: const Text('Onay bekliyor'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AppTheme.secondaryColor),
                      onPressed: () => _approveMember(member.uid),
                      tooltip: 'Onayla',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.errorColor),
                      onPressed: () => _rejectMember(member.uid),
                      tooltip: 'Reddet',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMembersList(bool isOwner) {
    return StreamBuilder<List<CommunityMembership>>(
      stream: _communityService.getMembers(widget.communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz üye yok',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // Sort: owner first, then moderators, then members
        members.sort((a, b) {
          final roleOrder = {
            MemberRole.owner: 0,
            MemberRole.moderator: 1,
            MemberRole.member: 2,
          };
          return roleOrder[a.role]!.compareTo(roleOrder[b.role]!);
        });

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return MemberListTile(
              membership: member,
              isCurrentUserOwner: isOwner,
              onRoleChange: isOwner && !member.isOwner
                  ? (newRole) => _changeRole(member.uid, newRole)
                  : null,
              onRemove: isOwner && !member.isOwner
                  ? () => _removeMember(member.uid)
                  : null,
            );
          },
        );
      },
    );
  }
}
