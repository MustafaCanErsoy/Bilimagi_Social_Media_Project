import 'package:flutter/material.dart';
import '../models/week.dart';
import '../models/article.dart';
import '../services/week_service.dart';

class DiscussionScreen extends StatefulWidget {
  final Week week;
  final Article article;

  const DiscussionScreen({
    super.key,
    required this.week,
    required this.article,
  });

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final _weekService = WeekService();
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      await _weekService.addComment(
        widget.week.id,
        widget.article.id,
        text,
      );
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tartışma'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Article header
          _buildArticleHeader(),
          // Phase indicator
          _buildPhaseIndicator(),
          // Comments list
          Expanded(child: _buildCommentsList()),
          // Comment input (only in discussion phase)
          if (widget.week.phase == WeekPhase.discussion) _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildArticleHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.amber.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'Kazanan Makale',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.article.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.article.summary,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    final isClosed = widget.week.phase == WeekPhase.closed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isClosed ? Colors.grey.withOpacity(0.1) : Colors.green.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isClosed ? Icons.lock : Icons.chat,
            size: 16,
            color: isClosed ? Colors.grey : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            isClosed ? 'Bu hafta kapatıldı (salt okunur)' : 'Tartışma açık',
            style: TextStyle(
              color: isClosed ? Colors.grey : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<List<Comment>>(
      stream: _weekService.getComments(widget.week.id, widget.article.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final comments = snapshot.data ?? [];

        if (comments.isEmpty) {
          return const Center(
            child: Text(
              'Henüz yorum yok.\nİlk yorumu sen yaz!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return _CommentCard(comment: comment);
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Yorumunuzu yazın...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _sendComment,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final Comment comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    comment.displayName.isNotEmpty
                        ? comment.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatTime(comment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.text),
          ],
        ),
      ),
    );
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
    } else {
      return '${diff.inDays} gün önce';
    }
  }
}
