import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../core/theme.dart';
import '../services/poll_service.dart';

/// Card widget for displaying and voting on polls (v8.0)
class PollCard extends StatefulWidget {
  final Poll poll;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final bool showActions;

  const PollCard({
    super.key,
    required this.poll,
    this.onClose,
    this.onDelete,
    this.showActions = false,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  final _pollService = PollService();
  PollVote? _userVote;
  Set<String> _selectedOptions = {};
  bool _isVoting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserVote();
  }

  Future<void> _loadUserVote() async {
    final vote = await _pollService.getUserVote(
      widget.poll.communityId,
      widget.poll.id,
    );
    if (mounted) {
      setState(() {
        _userVote = vote;
        _selectedOptions = vote?.optionIds.toSet() ?? {};
        _isLoading = false;
      });
    }
  }

  Future<void> _submitVote() async {
    if (_selectedOptions.isEmpty) return;

    setState(() => _isVoting = true);

    try {
      await _pollService.vote(
        communityId: widget.poll.communityId,
        pollId: widget.poll.id,
        optionIds: _selectedOptions.toList(),
      );
      await _loadUserVote();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  void _toggleOption(String optionId) {
    if (!widget.poll.isActive) return;

    setState(() {
      if (widget.poll.allowMultiple) {
        if (_selectedOptions.contains(optionId)) {
          _selectedOptions.remove(optionId);
        } else {
          _selectedOptions.add(optionId);
        }
      } else {
        _selectedOptions = {optionId};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasVoted = _userVote != null;
    final showResults = hasVoted || !widget.poll.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.poll,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anket',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (!widget.poll.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Kapali',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Question
            Text(
              widget.poll.question,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Options
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ...widget.poll.options.map((option) => _buildOption(
                    context,
                    option,
                    showResults,
                  )),

            // Vote button
            if (widget.poll.isActive && !hasVoted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedOptions.isEmpty || _isVoting
                      ? null
                      : _submitVote,
                  child: _isVoting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Oy Ver'),
                ),
              ),
            ],

            // Footer
            const SizedBox(height: 12),
            Row(
              children: [
                // Total votes
                Icon(
                  Icons.how_to_vote_outlined,
                  size: 14,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.poll.totalVotes} oy',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextTertiary(context),
                  ),
                ),
                const SizedBox(width: 12),

                // Time
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppTheme.getTextTertiary(context),
                ),
                const SizedBox(width: 4),
                Text(
                  _getRelativeTime(widget.poll.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextTertiary(context),
                  ),
                ),

                // Expiry
                if (widget.poll.endsAt != null && widget.poll.isActive) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppTheme.getTextTertiary(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatExpiry(widget.poll.endsAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getTextTertiary(context),
                    ),
                  ),
                ],

                const Spacer(),

                // Actions
                if (widget.showActions) ...[
                  if (widget.poll.isActive && widget.onClose != null)
                    IconButton(
                      icon: const Icon(Icons.stop_circle_outlined, size: 20),
                      onPressed: widget.onClose,
                      tooltip: 'Anketi Kapat',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: widget.onDelete,
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, PollOption option, bool showResults) {
    final isSelected = _selectedOptions.contains(option.id);
    final percentage = widget.poll.totalVotes > 0
        ? (option.voteCount / widget.poll.totalVotes * 100)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: widget.poll.isActive && _userVote == null
            ? () => _toggleOption(option.id)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Progress bar background
              if (showResults)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Radio/Checkbox
                    if (!showResults)
                      widget.poll.allowMultiple
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleOption(option.id),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            )
                          : Radio<String>(
                              value: option.id,
                              groupValue: _selectedOptions.isEmpty
                                  ? null
                                  : _selectedOptions.first,
                              onChanged: (_) => _toggleOption(option.id),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),

                    // Option text
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),

                    // Results
                    if (showResults) ...[
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.getTextTertiary(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${option.voteCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextTertiary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatExpiry(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.isNegative) return 'Suresi doldu';
    if (diff.inDays > 0) return '${diff.inDays} gun kaldi';
    if (diff.inHours > 0) return '${diff.inHours} saat kaldi';
    return '${diff.inMinutes} dk kaldi';
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} gun once';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} saat once';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} dk once';
    }
    return 'Az once';
  }
}
