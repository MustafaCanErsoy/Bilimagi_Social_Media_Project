import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/community_membership.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../core/theme.dart';
import '../services/week_service.dart';
import '../services/community_service.dart';
import '../services/suggestion_service.dart';
import 'discussion_screen.dart';
import 'suggestion_screen.dart';
import 'suggestion_review_screen.dart';
import 'community_manage_screen.dart';
import 'community_members_screen.dart';

class WeekScreen extends StatefulWidget {
  final Community community;

  const WeekScreen({super.key, required this.community});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  final _weekService = WeekService();
  final _communityService = CommunityService();
  final _suggestionService = SuggestionService();
  String? _userVote;
  bool _loadingVote = true;
  MemberRole? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserVote();
    _loadUserRole();
  }

  void _loadUserRole() {
    _communityService.getUserRole(widget.community.id).listen((role) {
      if (mounted) {
        setState(() => _userRole = role);
      }
    });
  }

  Future<void> _loadUserVote() async {
    if (widget.community.currentWeekId != null) {
      final vote = await _weekService.getUserVote(widget.community.currentWeekId!);
      if (mounted) {
        setState(() {
          _userVote = vote;
          _loadingVote = false;
        });
      }
    } else {
      setState(() => _loadingVote = false);
    }
  }

  Future<void> _castVote(String articleId) async {
    if (widget.community.currentWeekId == null) return;

    try {
      await _weekService.castVote(widget.community.currentWeekId!, articleId);
      setState(() => _userVote = articleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oyunuz kaydedildi!')),
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

  void _goToDiscussion(Week week, Article winningArticle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscussionScreen(
          week: week,
          article: winningArticle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekId = widget.community.currentWeekId;
    final canManage = _userRole == MemberRole.owner || _userRole == MemberRole.moderator;

    if (weekId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.community.name),
          actions: [
            if (canManage)
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Topluluk Yönetimi',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityManageScreen(communityId: widget.community.id),
                    ),
                  );
                },
              ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bu topluluk için aktif hafta bulunmuyor.',
                  textAlign: TextAlign.center,
                ),
                if (canManage) ...[
                  const SizedBox(height: 32),
                  // Üye Yönetimi butonu
                  StreamBuilder<int>(
                    stream: _communityService.getPendingMemberCount(widget.community.id),
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.data ?? 0;
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommunityMembersScreen(
                                  communityId: widget.community.id,
                                ),
                              ),
                            );
                          },
                          icon: Badge(
                            isLabelVisible: pendingCount > 0,
                            label: Text('$pendingCount'),
                            child: const Icon(Icons.people),
                          ),
                          label: Text(pendingCount > 0
                              ? 'Üye İstekleri ($pendingCount bekleyen)'
                              : 'Üyeleri Yönet'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Yeni Hafta butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _communityService.createNewWeek(widget.community.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Yeni hafta oluşturuldu!')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Hafta Başlat'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.community.name),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Topluluk Yönetimi',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommunityManageScreen(communityId: widget.community.id),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<Week?>(
        stream: _weekService.getWeek(weekId),
        builder: (context, weekSnapshot) {
          if (weekSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final week = weekSnapshot.data;
          if (week == null) {
            return const Center(child: Text('Hafta bulunamadı.'));
          }

          return Column(
            children: [
              _buildPhaseIndicator(week),
              if (week.phase == WeekPhase.voting)
                _buildSuggestionButtons(week),
              Expanded(
                child: _buildArticleList(week),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhaseIndicator(Week week) {
    Color phaseColor;
    IconData phaseIcon;

    switch (week.phase) {
      case WeekPhase.voting:
        phaseColor = Colors.blue;
        phaseIcon = Icons.how_to_vote;
        break;
      case WeekPhase.discussion:
        phaseColor = Colors.green;
        phaseIcon = Icons.chat;
        break;
      case WeekPhase.closed:
        phaseColor = Colors.grey;
        phaseIcon = Icons.lock;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: phaseColor.withValues(alpha:0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(phaseIcon, color: phaseColor),
          const SizedBox(width: 8),
          Text(
            'Mevcut Faz: ${week.phaseDisplayName}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: phaseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButtons(Week week) {
    final canManage = _userRole == MemberRole.owner || _userRole == MemberRole.moderator;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SuggestionScreen(weekId: week.id),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Makale Öner'),
            ),
          ),
          if (canManage) ...[
            const SizedBox(width: 12),
            StreamBuilder<int>(
              stream: _suggestionService.getPendingSuggestionCount(week.id),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: AppTheme.accentColor,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SuggestionReviewScreen(weekId: week.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Önerileri İncele'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleList(Week week) {
    return StreamBuilder<List<Article>>(
      stream: _weekService.getArticles(week.id),
      builder: (context, articlesSnapshot) {
        if (articlesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final articles = articlesSnapshot.data ?? [];

        if (articles.isEmpty) {
          return const Center(child: Text('Makale bulunamadı.'));
        }

        return StreamBuilder<Map<String, int>>(
          stream: _weekService.getVoteCounts(week.id),
          builder: (context, votesSnapshot) {
            final voteCounts = votesSnapshot.data ?? {};
            final totalVotes = voteCounts.values.fold(0, (a, b) => a + b);

            // Find winning article for discussion phase
            String? winningArticleId;
            int maxVotes = -1;
            for (final entry in voteCounts.entries) {
              if (entry.value > maxVotes) {
                maxVotes = entry.value;
                winningArticleId = entry.key;
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                final voteCount = voteCounts[article.id] ?? 0;
                final isWinner = article.id == winningArticleId && maxVotes > 0;
                final isUserVote = _userVote == article.id;

                return _ArticleCard(
                  article: article,
                  voteCount: voteCount,
                  totalVotes: totalVotes,
                  phase: week.phase,
                  isUserVote: isUserVote,
                  isWinner: isWinner,
                  onVote: week.phase == WeekPhase.voting && !_loadingVote
                      ? () => _castVote(article.id)
                      : null,
                  onDiscuss: week.phase == WeekPhase.discussion && isWinner
                      ? () => _goToDiscussion(week, article)
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final int voteCount;
  final int totalVotes;
  final WeekPhase phase;
  final bool isUserVote;
  final bool isWinner;
  final VoidCallback? onVote;
  final VoidCallback? onDiscuss;

  const _ArticleCard({
    required this.article,
    required this.voteCount,
    required this.totalVotes,
    required this.phase,
    required this.isUserVote,
    required this.isWinner,
    this.onVote,
    this.onDiscuss,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalVotes > 0 ? voteCount / totalVotes : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isWinner && phase != WeekPhase.voting ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isWinner && phase != WeekPhase.voting
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isWinner && phase != WeekPhase.voting)
                  const Icon(Icons.emoji_events, color: Colors.amber),
                if (isUserVote)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle, color: Colors.green),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              article.summary,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            // Vote progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$voteCount oy',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isWinner && phase != WeekPhase.voting
                        ? Colors.amber
                        : Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (phase == WeekPhase.voting && onVote != null)
                  ElevatedButton.icon(
                    onPressed: onVote,
                    icon: Icon(isUserVote ? Icons.check : Icons.how_to_vote),
                    label: Text(isUserVote ? 'Oylandı' : 'Oy Ver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUserVote ? Colors.green : null,
                      foregroundColor: isUserVote ? Colors.white : null,
                    ),
                  ),
                if (phase == WeekPhase.discussion && isWinner && onDiscuss != null)
                  ElevatedButton.icon(
                    onPressed: onDiscuss,
                    icon: const Icon(Icons.chat),
                    label: const Text('Tartışmaya Katıl'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
