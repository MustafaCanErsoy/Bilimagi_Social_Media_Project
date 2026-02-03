import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/poll_service.dart';

/// Screen for creating a new poll (v8.0)
class PollCreateScreen extends StatefulWidget {
  final String communityId;

  const PollCreateScreen({
    super.key,
    required this.communityId,
  });

  @override
  State<PollCreateScreen> createState() => _PollCreateScreenState();
}

class _PollCreateScreenState extends State<PollCreateScreen> {
  final _pollService = PollService();
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isLoading = false;
  bool _allowMultiple = false;
  DateTime? _endsAt;

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 6 secenek ekleyebilirsiniz')),
      );
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 2 secenek olmalidir')),
      );
      return;
    }
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endsAt ?? now),
      );

      if (time != null && mounted) {
        setState(() {
          _endsAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    // Filter out empty options
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 2 secenek gereklidir')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _pollService.createPoll(
        communityId: widget.communityId,
        question: _questionController.text.trim(),
        options: options,
        endsAt: _endsAt,
        allowMultiple: _allowMultiple,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anket olusturuldu')),
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
        title: const Text('Anket Olustur'),
        actions: [
          FilledButton(
            onPressed: _isLoading ? null : _createPoll,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Olustur'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Question
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Soru',
                hintText: 'Anket sorusunu yazin...',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().length < 5) {
                  return 'En az 5 karakter giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Options header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Secenekler',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Secenek Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Options list
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Secenek ${index + 1}',
                          hintText: 'Secenegi yazin...',
                        ),
                        validator: (value) {
                          // At least 2 options must have text
                          final filledCount = _optionControllers
                              .where((c) => c.text.trim().isNotEmpty)
                              .length;
                          if (filledCount < 2 && (value == null || value.trim().isEmpty)) {
                            return 'En az 2 secenek gereklidir';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        onPressed: () => _removeOption(index),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Settings
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Ayarlar',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            // Allow multiple
            SwitchListTile(
              value: _allowMultiple,
              onChanged: (value) => setState(() => _allowMultiple = value),
              title: const Text('Coklu Secim'),
              subtitle: const Text('Kullanicilar birden fazla secenek secebilir'),
              contentPadding: EdgeInsets.zero,
            ),

            // End date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.timer_outlined, color: AppTheme.primaryColor),
              title: const Text('Bitis Tarihi'),
              subtitle: Text(
                _endsAt != null
                    ? '${_endsAt!.day}.${_endsAt!.month}.${_endsAt!.year} ${_endsAt!.hour}:${_endsAt!.minute.toString().padLeft(2, '0')}'
                    : 'Belirlenmedi (suressiz)',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endsAt != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endsAt = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickEndDate,
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
