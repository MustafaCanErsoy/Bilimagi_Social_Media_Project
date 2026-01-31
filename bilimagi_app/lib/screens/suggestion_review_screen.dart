import 'package:flutter/material.dart';
import '../models/article_suggestion.dart';
import '../core/theme.dart';
import '../services/suggestion_service.dart';
import '../widgets/suggestion_card.dart';

/// Screen for reviewing article suggestions (moderator/owner only)
class SuggestionReviewScreen extends StatefulWidget {
  final String weekId;

  const SuggestionReviewScreen({
    super.key,
    required this.weekId,
  });

  @override
  State<SuggestionReviewScreen> createState() => _SuggestionReviewScreenState();
}

class _SuggestionReviewScreenState extends State<SuggestionReviewScreen>
    with SingleTickerProviderStateMixin {
  final _suggestionService = SuggestionService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveSuggestion(ArticleSuggestion suggestion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öneriyi Onayla'),
        content: Text(
          '"${suggestion.title}" makalesini oylamaya eklemek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _suggestionService.approveSuggestion(widget.weekId, suggestion.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Öneri onaylandı ve makaleye dönüştürüldü')),
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

  Future<void> _rejectSuggestion(ArticleSuggestion suggestion) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öneriyi Reddet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${suggestion.title}" makalesini reddetmek üzeresiniz.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Red Sebebi (opsiyonel)',
                hintText: 'Neden reddedildiğini açıklayın...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await _suggestionService.rejectSuggestion(
        widget.weekId,
        suggestion.id,
        reason: result.isNotEmpty ? result : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Öneri reddedildi')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Makale Önerileri'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            StreamBuilder<int>(
              stream: _suggestionService.getPendingSuggestionCount(widget.weekId),
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
            const Tab(text: 'Onaylanan'),
            const Tab(text: 'Reddedilen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSuggestionList(SuggestionStatus.pending, isReviewer: true),
          _buildSuggestionList(SuggestionStatus.approved),
          _buildSuggestionList(SuggestionStatus.rejected),
        ],
      ),
    );
  }

  Widget _buildSuggestionList(SuggestionStatus status, {bool isReviewer = false}) {
    return StreamBuilder<List<ArticleSuggestion>>(
      stream: _suggestionService.getSuggestions(widget.weekId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allSuggestions = snapshot.data ?? [];
        final suggestions = allSuggestions
            .where((s) => s.status == status)
            .toList();

        if (suggestions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyIcon(status),
                  size: 64,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(status),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return SuggestionCard(
              suggestion: suggestion,
              isReviewer: isReviewer,
              onApprove: () => _approveSuggestion(suggestion),
              onReject: () => _rejectSuggestion(suggestion),
            );
          },
        );
      },
    );
  }

  IconData _getEmptyIcon(SuggestionStatus status) {
    switch (status) {
      case SuggestionStatus.pending:
        return Icons.inbox;
      case SuggestionStatus.approved:
        return Icons.check_circle_outline;
      case SuggestionStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _getEmptyMessage(SuggestionStatus status) {
    switch (status) {
      case SuggestionStatus.pending:
        return 'Bekleyen öneri yok';
      case SuggestionStatus.approved:
        return 'Henüz onaylanan öneri yok';
      case SuggestionStatus.rejected:
        return 'Henüz reddedilen öneri yok';
    }
  }
}
