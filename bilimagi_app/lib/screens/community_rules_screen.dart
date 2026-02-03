import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/community_service.dart';

/// Screen for editing community rules (v8.0)
class CommunityRulesScreen extends StatefulWidget {
  final String communityId;
  final String? initialRules;

  const CommunityRulesScreen({
    super.key,
    required this.communityId,
    this.initialRules,
  });

  @override
  State<CommunityRulesScreen> createState() => _CommunityRulesScreenState();
}

class _CommunityRulesScreenState extends State<CommunityRulesScreen> {
  final _communityService = CommunityService();
  final _rulesController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _rulesController.text = widget.initialRules ?? '';
    _rulesController.addListener(() {
      final hasChanges = _rulesController.text != (widget.initialRules ?? '');
      if (hasChanges != _hasChanges) {
        setState(() => _hasChanges = hasChanges);
      }
    });
  }

  @override
  void dispose() {
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _saveRules() async {
    setState(() => _isLoading = true);

    try {
      await _communityService.updateCommunity(
        widget.communityId,
        rules: _rulesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kurallar kaydedildi')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydedilmemis Degisiklikler'),
        content: const Text('Degisiklikler kaydedilmedi. Cikmak istediginize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cik'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Topluluk Kurallari'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveRules,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
          ],
        ),
        body: Column(
          children: [
            // Tips card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Markdown formatini kullanabilirsiniz:\n'
                      '**kalin**, *italik*, - liste, # baslik',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            // Rules editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _rulesController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Topluluk kurallarini buraya yazin...\n\n'
                        'Ornek:\n'
                        '# Kurallar\n\n'
                        '1. Saygi cercevesinde tartisma\n'
                        '2. Kaynak gosterin\n'
                        '3. Spam yapmayin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Character count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_rulesController.text.length} / 5000 karakter',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _rulesController.text.length > 5000
                              ? Colors.red
                              : Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
