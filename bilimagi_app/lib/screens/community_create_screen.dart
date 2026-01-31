import 'package:flutter/material.dart';
import '../models/community.dart';
import '../core/theme.dart';
import '../core/avatar_colors.dart';
import '../services/community_service.dart';
import '../widgets/community_icon_picker.dart';

/// Screen for creating a new community
class CommunityCreateScreen extends StatefulWidget {
  const CommunityCreateScreen({super.key});

  @override
  State<CommunityCreateScreen> createState() => _CommunityCreateScreenState();
}

class _CommunityCreateScreenState extends State<CommunityCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _communityService = CommunityService();

  String _selectedCategory = CommunityCategory.physics;
  String? _selectedEmoji;
  int _selectedColorIndex = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _communityService.createCommunity(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        customCategory: _selectedCategory == CommunityCategory.other
            ? _customCategoryController.text.trim()
            : null,
        iconEmoji: _selectedEmoji,
        colorIndex: _selectedColorIndex,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topluluk oluşturuldu!')),
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

  Future<void> _pickIcon() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CommunityIconPickerDialog(
        initialEmoji: _selectedEmoji,
        initialColorIndex: _selectedColorIndex,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedEmoji = result['emoji'] as String?;
        _selectedColorIndex = result['colorIndex'] as int;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluk Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview card
              _buildPreviewCard(),
              const SizedBox(height: 24),

              // Icon picker button
              Center(
                child: TextButton.icon(
                  onPressed: _pickIcon,
                  icon: const Icon(Icons.emoji_emotions),
                  label: const Text('Simge ve Renk Seç'),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Topluluk Adı',
                  hintText: 'Örn: Kuantum Fiziği',
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'En az 3 karakter giriniz';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Topluluğunuzu tanımlayın...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'En az 10 karakter giriniz';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                ),
                items: CommunityCategory.all.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(CommunityCategory.getLabel(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? CommunityCategory.other;
                  });
                },
              ),

              // Custom category field (if "other" selected)
              if (_selectedCategory == CommunityCategory.other) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Özel Kategori',
                    hintText: 'Kategori adını girin',
                  ),
                  validator: (value) {
                    if (_selectedCategory == CommunityCategory.other &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Kategori adı giriniz';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCommunity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Topluluk Oluştur'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final color = avatarColors[_selectedColorIndex % avatarColors.length];
    final name = _nameController.text.trim().isEmpty
        ? 'Topluluk Adı'
        : _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? 'Topluluk açıklaması buraya gelecek...'
        : _descriptionController.text.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _selectedEmoji != null
                    ? Text(
                        _selectedEmoji!,
                        style: const TextStyle(fontSize: 28),
                      )
                    : Icon(
                        Icons.groups,
                        size: 28,
                        color: color,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
