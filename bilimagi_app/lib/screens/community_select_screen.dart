import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/community_service.dart';
import '../models/community.dart';
import '../models/community_membership.dart';
import '../core/theme.dart';
import '../widgets/community_card.dart';
import '../widgets/community_search_bar.dart';
import 'period_screen.dart';
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

  // Search & filter state
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = CommunityService.sortByPopular;

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

  String _getActiveFilterText() {
    final parts = <String>[];
    if (_selectedCategory != null) {
      parts.add(CommunityCategory.getLabel(_selectedCategory!));
    }
    if (_sortBy != CommunityService.sortByPopular) {
      final sortLabels = {
        CommunityService.sortByNewest: 'En Yeni',
        CommunityService.sortByName: 'Ada Göre',
      };
      parts.add(sortLabels[_sortBy] ?? '');
    }
    return parts.join(' • ');
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedSort: _sortBy,
        onApply: (category, sort) {
          setState(() {
            _selectedCategory = category;
            _sortBy = sort;
          });
        },
      ),
    );
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

        final allCommunities = snapshot.data ?? [];

        // Apply filters
        final communities = _communityService.filterCommunities(
          communities: allCommunities,
          searchQuery: _searchQuery,
          category: _selectedCategory,
          sortBy: _sortBy,
        );

        final hasActiveFilters = _selectedCategory != null || _sortBy != CommunityService.sortByPopular;

        return Column(
          children: [
            // Search bar with filter button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: CommunitySearchBar(
                      onSearch: (query) {
                        setState(() => _searchQuery = query);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter button
                  Badge(
                    isLabelVisible: hasActiveFilters,
                    child: IconButton.filledTonal(
                      onPressed: () => _showFilterSheet(context),
                      icon: const Icon(Icons.tune),
                      tooltip: 'Filtrele',
                    ),
                  ),
                ],
              ),
            ),
            // Active filter indicator
            if (hasActiveFilters)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _getActiveFilterText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _sortBy = CommunityService.sortByPopular;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Temizle', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            // Results
            Expanded(
              child: communities.isEmpty
                  ? _buildEmptyState(allCommunities.isEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: communities.length,
                      itemBuilder: (context, index) {
                        final community = communities[index];
                        return _buildCommunityItem(community);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool noCommunitiesExist) {
    if (noCommunitiesExist) {
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

    // No results for filters
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.getTextTertiary(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Sonuç bulunamadı',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Farklı bir arama veya filtre deneyin'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = null;
              });
            },
            child: const Text('Filtreleri Temizle'),
          ),
        ],
      ),
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
              builder: (context) => PeriodScreen(community: community),
            ),
          );
        }
      },
    );
  }
}

/// Bottom sheet for filter options
class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final String selectedSort;
  final void Function(String? category, String sort) onApply;

  const _FilterBottomSheet({
    required this.selectedCategory,
    required this.selectedSort,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _category;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _sort = widget.selectedSort;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.tune),
              const SizedBox(width: 8),
              Text(
                'Filtrele',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category section
          Text(
            'Kategori',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip(null, 'Tümü'),
              ...CommunityCategory.all.map((cat) =>
                _buildCategoryChip(cat, CommunityCategory.getLabel(cat)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sort section
          Text(
            'Sıralama',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip(CommunityService.sortByPopular, 'En Popüler'),
              _buildSortChip(CommunityService.sortByNewest, 'En Yeni'),
              _buildSortChip(CommunityService.sortByName, 'Ada Göre'),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _category = null;
                      _sort = CommunityService.sortByPopular;
                    });
                  },
                  child: const Text('Sıfırla'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_category, _sort);
                    Navigator.pop(context);
                  },
                  child: const Text('Uygula'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? value, String label) {
    final isSelected = _category == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _category = value),
      showCheckmark: false,
    );
  }

  Widget _buildSortChip(String value, String label) {
    final isSelected = _sort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _sort = value),
      showCheckmark: false,
    );
  }
}
