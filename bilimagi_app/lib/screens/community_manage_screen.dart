import 'package:flutter/material.dart';
import '../models/community.dart';
import '../core/theme.dart';
import '../core/avatar_colors.dart';
import '../services/community_service.dart';
import '../widgets/community_icon_picker.dart';
import 'community_members_screen.dart';
import 'moderation_dashboard_screen.dart';

/// Screen for managing community settings (owner/moderator only)
class CommunityManageScreen extends StatefulWidget {
  final String communityId;

  const CommunityManageScreen({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityManageScreen> createState() => _CommunityManageScreenState();
}

class _CommunityManageScreenState extends State<CommunityManageScreen> {
  final _communityService = CommunityService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Community? _community;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCommunity();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunity() async {
    final community = await _communityService.getCommunityOnce(widget.communityId);
    if (community != null && mounted) {
      setState(() {
        _community = community;
        _nameController.text = community.name;
        _descriptionController.text = community.description;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _community == null) return;

    setState(() => _isLoading = true);

    try {
      await _communityService.updateCommunity(
        widget.communityId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değişiklikler kaydedildi')),
        );
        setState(() => _hasChanges = false);
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

  Future<void> _createNewWeek() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Hafta Oluştur'),
        content: const Text('Yeni bir oylama haftası başlatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _communityService.createNewWeek(widget.communityId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni hafta oluşturuldu')),
        );
        await _loadCommunity();
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
    if (_community == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CommunityIconPickerDialog(
        initialEmoji: _community!.iconEmoji,
        initialColorIndex: _community!.colorIndex,
      ),
    );

    if (result != null) {
      try {
        await _communityService.updateCommunity(
          widget.communityId,
          iconEmoji: result['emoji'] as String?,
          colorIndex: result['colorIndex'] as int,
        );
        await _loadCommunity();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_community == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Topluluk Yönetimi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final color = avatarColors[_community!.colorIndex % avatarColors.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluk Yönetimi'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: const Text('Kaydet'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community icon
              Center(
                child: GestureDetector(
                  onTap: _pickIcon,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: _community!.iconEmoji != null
                              ? Text(
                                  _community!.iconEmoji!,
                                  style: const TextStyle(fontSize: 40),
                                )
                              : Icon(Icons.groups, size: 40, color: color),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Topluluk Adı',
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'En az 3 karakter';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _hasChanges = true),
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'En az 10 karakter';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _hasChanges = true),
              ),
              const SizedBox(height: 24),

              // Stats section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İstatistikler',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.people,
                            '${_community!.stats.memberCount}',
                            'Üye',
                          ),
                          _buildStatItem(
                            Icons.calendar_today,
                            '${_community!.stats.weekCount}',
                            'Hafta',
                          ),
                          _buildStatItem(
                            Icons.article,
                            '${_community!.stats.totalArticles}',
                            'Makale',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Members management
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Üyeleri Yönet'),
                  subtitle: StreamBuilder<int>(
                    stream: _communityService.getPendingMemberCount(widget.communityId),
                    builder: (context, snapshot) {
                      final pending = snapshot.data ?? 0;
                      if (pending > 0) {
                        return Text('$pending bekleyen istek');
                      }
                      return const Text('Üyeleri görüntüle ve yönet');
                    },
                  ),
                  trailing: StreamBuilder<int>(
                    stream: _communityService.getPendingMemberCount(widget.communityId),
                    builder: (context, snapshot) {
                      final pending = snapshot.data ?? 0;
                      if (pending > 0) {
                        return Badge(
                          label: Text('$pending'),
                          child: const Icon(Icons.chevron_right),
                        );
                      }
                      return const Icon(Icons.chevron_right);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityMembersScreen(
                          communityId: widget.communityId,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // v6.0: Moderation dashboard
              Card(
                child: ListTile(
                  leading: Icon(Icons.shield, color: Colors.orange.shade600),
                  title: const Text('Moderasyon Paneli'),
                  subtitle: const Text('Yasaklılar ve işlem geçmişi'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (_community != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModerationDashboardScreen(
                            community: _community!,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Create new week button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _createNewWeek,
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Hafta Başlat'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              // Delete community (owner only)
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Tehlikeli Bölge',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _deleteCommunity,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Topluluğu Sil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
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

  Future<void> _deleteCommunity() async {
    // Show confirmation dialog with text input
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteCommunityDialog(
        communityName: _community!.name,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _communityService.deleteCommunity(widget.communityId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topluluk silindi')),
        );
        // Go back to community list
        Navigator.of(context).popUntil((route) => route.isFirst);
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

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Dialog for confirming community deletion
class _DeleteCommunityDialog extends StatefulWidget {
  final String communityName;

  const _DeleteCommunityDialog({required this.communityName});

  @override
  State<_DeleteCommunityDialog> createState() => _DeleteCommunityDialogState();
}

class _DeleteCommunityDialogState extends State<_DeleteCommunityDialog> {
  final _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _canDelete = _controller.text == widget.communityName;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red.shade700),
          const SizedBox(width: 8),
          const Text('Topluluğu Sil'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bu işlem geri alınamaz! Topluluk ve tüm içeriği (haftalar, makaleler, yorumlar) kalıcı olarak silinecek.',
          ),
          const SizedBox(height: 16),
          Text(
            'Onaylamak için topluluk adını yazın:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.communityName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Topluluk adını yazın',
              border: const OutlineInputBorder(),
              errorText: _controller.text.isNotEmpty && !_canDelete
                  ? 'Topluluk adı eşleşmiyor'
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Kalıcı Olarak Sil'),
        ),
      ],
    );
  }
}
