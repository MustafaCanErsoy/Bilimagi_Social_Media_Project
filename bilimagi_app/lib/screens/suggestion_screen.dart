import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/suggestion_service.dart';

/// Screen for submitting article suggestions
class SuggestionScreen extends StatefulWidget {
  final String weekId;

  const SuggestionScreen({
    super.key,
    required this.weekId,
  });

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _linkController = TextEditingController();
  final _suggestionService = SuggestionService();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  Future<void> _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _suggestionService.submitSuggestion(
        weekId: widget.weekId,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        link: _linkController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Makale öneriniz gönderildi! Moderatör onayı bekleniyor.'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Makale Öner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Card(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bilimsel bir makale önerisi yapın. Öneriniz moderatör onayından sonra oylamaya eklenecek.',
                          style: TextStyle(
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Makale Başlığı',
                  hintText: 'Örn: Yeni keşfedilen ekzogezegen',
                ),
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.trim().length < 5) {
                    return 'En az 5 karakter giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Summary field
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Özet',
                  hintText: 'Makalenin kısa bir özeti...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
                validator: (value) {
                  if (value == null || value.trim().length < 20) {
                    return 'En az 20 karakter giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Link field
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Makale Linki',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Link giriniz';
                  }
                  if (!_isValidUrl(value.trim())) {
                    return 'Geçerli bir URL giriniz (https://...)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Preview section
              if (_titleController.text.isNotEmpty ||
                  _summaryController.text.isNotEmpty) ...[
                Text(
                  'Önizleme',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _buildPreviewCard(),
                const SizedBox(height: 24),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitSuggestion,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Öner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titleController.text.isEmpty
                  ? 'Makale Başlığı'
                  : _titleController.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _summaryController.text.isEmpty
                  ? 'Makale özeti buraya gelecek...'
                  : _summaryController.text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (_linkController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _linkController.text,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
