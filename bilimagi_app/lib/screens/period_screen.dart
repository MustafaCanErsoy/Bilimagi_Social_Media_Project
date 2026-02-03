import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/community_membership.dart';
import '../models/period.dart';
import '../models/article.dart';
import '../core/theme.dart';
import '../services/period_service.dart';
import '../services/community_service.dart';
import '../services/suggestion_service.dart';
import 'discussion_screen.dart';
import 'suggestion_screen.dart';
import 'suggestion_review_screen.dart';
import 'community_manage_screen.dart';
import 'community_members_screen.dart';
import 'period_create_screen.dart';

class PeriodScreen extends StatefulWidget {
  final Community community;

  const PeriodScreen({super.key, required this.community});

  @override
  State<PeriodScreen> createState() => _PeriodScreenState();
}

class _PeriodScreenState extends State<PeriodScreen> {
  final _periodService = PeriodService();
  final _communityService = CommunityService();
  final _suggestionService = SuggestionService();
  Set<String> _userVotes = {};
  bool _loadingVotes = true;
  MemberRole? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserVotes();
    _loadUserRole();
  }

  void _loadUserRole() {
    _communityService.getUserRole(widget.community.id).listen((role) {
      if (mounted) {
        setState(() => _userRole = role);
      }
    });
  }

  Future<void> _loadUserVotes() async {
    if (widget.community.currentPeriodId != null) {
      final votes = await _periodService.getUserVotes(widget.community.currentPeriodId!);
      if (mounted) {
        setState(() {
          _userVotes = votes;
          _loadingVotes = false;
        });
      }
    } else {
      setState(() => _loadingVotes = false);
    }
  }

  Future<void> _toggleVote(String articleId) async {
    if (widget.community.currentPeriodId == null) return;

    try {
      final added = await _periodService.toggleVote(
        widget.community.currentPeriodId!,
        articleId,
      );

      setState(() {
        if (added) {
          _userVotes.add(articleId);
        } else {
          _userVotes.remove(articleId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(added ? 'Oy verildi!' : 'Oy geri alindi!'),
            duration: const Duration(seconds: 1),
          ),
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

  void _goToDiscussion(Period period, Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscussionScreen(
          period: period,
          article: article,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodId = widget.community.currentPeriodId;
    final canManage = _userRole == MemberRole.owner || _userRole == MemberRole.moderator;

    if (periodId == null) {
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
                  'Bu topluluk icin aktif donem bulunmuyor.',
                  textAlign: TextAlign.center,
                ),
                if (canManage) ...[
                  const SizedBox(height: 32),
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
                              ? 'Uye Istekleri ($pendingCount bekleyen)'
                              : 'Uyeleri Yonet'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PeriodCreateScreen(
                              communityId: widget.community.id,
                            ),
                          ),
                        );
                        if (created == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Yeni donem olusturuldu!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Donem Baslat'),
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
      body: StreamBuilder<Period?>(
        stream: _periodService.getPeriod(periodId),
        builder: (context, periodSnapshot) {
          if (periodSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final period = periodSnapshot.data;
          if (period == null) {
            return const Center(child: Text('Donem bulunamadi.'));
          }

          return Column(
            children: [
              _buildPeriodHeader(period),
              if (period.phase == PeriodPhase.voting)
                _buildSuggestionButtons(period),
              Expanded(
                child: _buildArticleList(period),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodHeader(Period period) {
    Color phaseColor;
    IconData phaseIcon;

    switch (period.phase) {
      case PeriodPhase.voting:
        phaseColor = Colors.blue;
        phaseIcon = Icons.how_to_vote;
        break;
      case PeriodPhase.discussion:
        phaseColor = Colors.green;
        phaseIcon = Icons.chat;
        break;
      case PeriodPhase.closed:
        phaseColor = Colors.grey;
        phaseIcon = Icons.lock;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: phaseColor.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(period.phaseEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                period.phaseDisplayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: phaseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            period.title,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (period.dateRangeDisplay != null) ...[
            const SizedBox(height: 4),
            Text(
              period.dateRangeDisplay!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (period.phase == PeriodPhase.voting) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Text(
                'En az ${period.minVotesForDiscussion} oy alan makaleler tartismaya acilacak',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionButtons(Period period) {
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
                    builder: (_) => SuggestionScreen(periodId: period.id),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Makale Oner'),
            ),
          ),
          if (canManage) ...[
            const SizedBox(width: 12),
            StreamBuilder<int>(
              stream: _suggestionService.getPendingSuggestionCount(period.id),
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
                          builder: (_) => SuggestionReviewScreen(periodId: period.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Onerileri Incele'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleList(Period period) {
    return StreamBuilder<List<Article>>(
      stream: _periodService.getArticles(period.id),
      builder: (context, articlesSnapshot) {
        if (articlesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final articles = articlesSnapshot.data ?? [];

        if (articles.isEmpty) {
          return const Center(child: Text('Makale bulunamadi.'));
        }

        return StreamBuilder<Map<String, int>>(
          stream: _periodService.getVoteCounts(period.id),
          builder: (context, votesSnapshot) {
            final voteCounts = votesSnapshot.data ?? {};
            final totalVotes = voteCounts.values.fold(0, (a, b) => a + b);

            // Separate eligible and ineligible articles for discussion phase
            List<Article> eligibleArticles = [];
            List<Article> ineligibleArticles = [];

            if (period.phase == PeriodPhase.discussion || period.phase == PeriodPhase.closed) {
              for (final article in articles) {
                if (article.isEligibleForDiscussion) {
                  eligibleArticles.add(article);
                } else {
                  ineligibleArticles.add(article);
                }
              }
              // Sort by vote count
              eligibleArticles.sort((a, b) =>
                  (voteCounts[b.id] ?? 0).compareTo(voteCounts[a.id] ?? 0));
              ineligibleArticles.sort((a, b) =>
                  (voteCounts[b.id] ?? 0).compareTo(voteCounts[a.id] ?? 0));
            } else {
              // Voting phase - show all
              eligibleArticles = List.from(articles);
              eligibleArticles.sort((a, b) =>
                  (voteCounts[b.id] ?? 0).compareTo(voteCounts[a.id] ?? 0));
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (period.phase != PeriodPhase.voting && eligibleArticles.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Tartisilan Makaleler',
                    Icons.chat_bubble,
                    Colors.green,
                    eligibleArticles.length,
                  ),
                  const SizedBox(height: 8),
                ],
                ...eligibleArticles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final article = entry.value;
                  final voteCount = voteCounts[article.id] ?? 0;
                  final isUserVote = _userVotes.contains(article.id);
                  final isTopVoted = index == 0 && voteCount > 0;

                  return _ArticleCard(
                    article: article,
                    voteCount: voteCount,
                    totalVotes: totalVotes,
                    phase: period.phase,
                    isUserVote: isUserVote,
                    isTopVoted: isTopVoted,
                    isEligible: article.isEligibleForDiscussion || period.phase == PeriodPhase.voting,
                    minVotesThreshold: period.minVotesForDiscussion,
                    onVote: period.phase == PeriodPhase.voting && !_loadingVotes
                        ? () => _toggleVote(article.id)
                        : null,
                    onDiscuss: period.phase == PeriodPhase.discussion &&
                            article.isEligibleForDiscussion
                        ? () => _goToDiscussion(period, article)
                        : null,
                  );
                }),
                if (period.phase != PeriodPhase.voting && ineligibleArticles.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Diger Makaleler',
                    Icons.article_outlined,
                    Colors.grey,
                    ineligibleArticles.length,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Esik altinda kaldi (min ${period.minVotesForDiscussion} oy)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ...ineligibleArticles.map((article) {
                    final voteCount = voteCounts[article.id] ?? 0;
                    return _ArticleCard(
                      article: article,
                      voteCount: voteCount,
                      totalVotes: totalVotes,
                      phase: period.phase,
                      isUserVote: _userVotes.contains(article.id),
                      isTopVoted: false,
                      isEligible: false,
                      minVotesThreshold: period.minVotesForDiscussion,
                      onVote: null,
                      onDiscuss: null,
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final int voteCount;
  final int totalVotes;
  final PeriodPhase phase;
  final bool isUserVote;
  final bool isTopVoted;
  final bool isEligible;
  final int minVotesThreshold;
  final VoidCallback? onVote;
  final VoidCallback? onDiscuss;

  const _ArticleCard({
    required this.article,
    required this.voteCount,
    required this.totalVotes,
    required this.phase,
    required this.isUserVote,
    required this.isTopVoted,
    required this.isEligible,
    required this.minVotesThreshold,
    this.onVote,
    this.onDiscuss,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalVotes > 0 ? voteCount / totalVotes : 0.0;
    final isDimmed = !isEligible && phase != PeriodPhase.voting;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTopVoted && phase != PeriodPhase.voting ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTopVoted && phase != PeriodPhase.voting
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Opacity(
        opacity: isDimmed ? 0.6 : 1.0,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isTopVoted && phase != PeriodPhase.voting)
                    const Tooltip(
                      message: 'En cok oy alan',
                      child: Icon(Icons.emoji_events, color: Colors.amber),
                    ),
                  if (isUserVote)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Tooltip(
                        message: 'Oy verdiniz',
                        child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                article.summary,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Vote progress
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
                      if (totalVotes > 0)
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isTopVoted && phase != PeriodPhase.voting
                          ? Colors.amber
                          : isEligible
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (phase == PeriodPhase.voting && onVote != null)
                    ElevatedButton.icon(
                      onPressed: onVote,
                      icon: Icon(
                        isUserVote ? Icons.check : Icons.how_to_vote,
                        size: 18,
                      ),
                      label: Text(isUserVote ? 'Oylandi' : 'Oy Ver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUserVote ? Colors.green : null,
                        foregroundColor: isUserVote ? Colors.white : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  if (phase == PeriodPhase.discussion && isEligible && onDiscuss != null)
                    ElevatedButton.icon(
                      onPressed: onDiscuss,
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Tartismaya Katil'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
