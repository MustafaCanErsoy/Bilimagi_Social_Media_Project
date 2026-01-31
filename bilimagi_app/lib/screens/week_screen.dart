import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../services/week_service.dart';
import 'discussion_screen.dart';

class WeekScreen extends StatefulWidget {
  final Community community;

  const WeekScreen({super.key, required this.community});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  final _weekService = WeekService();
  String? _userVote;
  bool _loadingVote = true;

  @override
  void initState() {
    super.initState();
    _loadUserVote();
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

    if (weekId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.community.name),
        ),
        body: const Center(
          child: Text('Bu topluluk için aktif hafta bulunmuyor.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.community.name),
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
      color: phaseColor.withOpacity(0.1),
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
