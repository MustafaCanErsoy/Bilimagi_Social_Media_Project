import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/community_service.dart';
import '../models/community.dart';
import '../models/community_membership.dart';
import '../core/theme.dart';
import '../widgets/community_card.dart';
import 'week_screen.dart';
import 'admin_screen.dart';
import 'community_create_screen.dart';

class CommunitySelectScreen extends StatefulWidget {
  const CommunitySelectScreen({super.key});

  @override
  State<CommunitySelectScreen> createState() => _CommunitySelectScreenState();
}

class _CommunitySelectScreenState extends State<CommunitySelectScreen>
    with SingleTickerProviderStateMixin {
  final _communityService = CommunityService();
  final _auth = FirebaseAuth.instance;
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

  Future<void> _createCommunity() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CommunityCreateScreen()),
    );

    if (result == true) {
      // Refresh will happen automatically via stream
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluklar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Panel',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Keşfet'),
            Tab(text: 'Katıldıklarım'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllCommunitiesList(),
          _buildMyCommunities(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCommunity,
        icon: const Icon(Icons.add),
        label: const Text('Topluluk Oluştur'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAllCommunitiesList() {
    return StreamBuilder<List<Community>>(
      stream: _communityService.getPublicCommunities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final communities = snapshot.data ?? [];

        if (communities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 64,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz topluluk yok',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('İlk topluluğu siz oluşturun!'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            return _buildCommunityItem(community);
          },
        );
      },
    );
  }

  Widget _buildMyCommunities() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Giriş yapınız'));
    }

    return StreamBuilder<List<Community>>(
      stream: _communityService.getUserCommunities(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final communities = snapshot.data ?? [];

        if (communities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_add_outlined,
                  size: 64,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz bir topluluğa katılmadınız',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('Keşfet sekmesinden topluluklara katılabilirsiniz'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            return _buildCommunityItem(community, showManage: true);
          },
        );
      },
    );
  }

  Widget _buildCommunityItem(Community community, {bool showManage = false}) {
    return CommunityCard(
      community: community,
      showMembershipButton: !showManage,
      onTap: () async {
        // Check membership status
        final uid = _auth.currentUser?.uid;
        if (uid == null) return;

        final membership = await _communityService
            .getMembershipStatus(community.id)
            .first;

        if (membership != MemberStatus.approved && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu topluluğu görüntülemek için üye olmanız gerekiyor'),
            ),
          );
          return;
        }

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeekScreen(community: community),
            ),
          );
        }
      },
    );
  }
}
