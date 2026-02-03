import 'package:flutter/material.dart';
import '../services/community_service.dart';

class PeriodCreateScreen extends StatefulWidget {
  final String communityId;

  const PeriodCreateScreen({super.key, required this.communityId});

  @override
  State<PeriodCreateScreen> createState() => _PeriodCreateScreenState();
}

class _PeriodCreateScreenState extends State<PeriodCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _communityService = CommunityService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int _topArticlesCount = 3; // v10.0: Default to top 3 articles
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        // If end date is before start date, reset it
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _createPeriod() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _communityService.createNewPeriod(
        communityId: widget.communityId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        topArticlesCount: _topArticlesCount, // v10.0
      );

      if (mounted) {
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
        title: const Text('Yeni Donem Olustur'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Donem Basligi *',
                hintText: 'Ornegin: Ocak 2026 Tartismasi',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Baslik gerekli';
                }
                if (value.trim().length < 3) {
                  return 'Baslik en az 3 karakter olmali';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Aciklama (Opsiyonel)',
                hintText: 'Bu donemin amaci veya konusu',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Date Range Section
            Text(
              'Tarih Araligi (Opsiyonel)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tarihler sadece bilgi amaclidir, otomatik gecis yapmaz.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_startDate != null
                        ? _formatDate(_startDate!)
                        : 'Baslangic'),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_endDate != null
                        ? _formatDate(_endDate!)
                        : 'Bitis'),
                  ),
                ),
              ],
            ),
            if (_startDate != null || _endDate != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Tarihleri Temizle'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Top N Articles (v10.0)
            Text(
              'Tartismaya Alinacak Makale Sayisi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tartisma fazina gecildiginde, en cok oy alan bu kadar makale tartismaya acilir.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _topArticlesCount > 1
                      ? () => setState(() => _topArticlesCount--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_topArticlesCount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _topArticlesCount < 20
                      ? () => setState(() => _topArticlesCount++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(width: 8),
                const Text('makale'),
              ],
            ),
            const SizedBox(height: 8),
            // Quick select chips
            Wrap(
              spacing: 8,
              children: [1, 3, 5, 10].map((value) {
                final isSelected = _topArticlesCount == value;
                return ChoiceChip(
                  label: Text('$value'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _topArticlesCount = value);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPeriod,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Donem Olustur'),
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Donem Nasil Calisir?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('1.', 'Oylama Fazi: Uyeler makalelere oy verir'),
                    _buildInfoRow('2.', 'Tartisma Fazi: En cok oy alan N makale tartismaya acilir'),
                    _buildInfoRow('3.', 'Kapali Faz: Donem arsivlenir'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue[800], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
