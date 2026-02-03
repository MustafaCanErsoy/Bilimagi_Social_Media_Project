import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/community.dart';
import '../models/period.dart';
import '../core/theme.dart';
import '../core/avatar_colors.dart';
import '../services/community_service.dart';
import '../services/period_service.dart';
import '../services/storage_service.dart';
import '../widgets/community_icon_picker.dart';
import 'community_members_screen.dart';
import 'moderation_dashboard_screen.dart';
import 'community_rules_screen.dart';
import 'period_create_screen.dart';

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
  final _periodService = PeriodService();
  final _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Community? _community;
  Period? _currentPeriod;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isUploadingCover = false;

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
      // Load current period if exists
      if (community.currentPeriodId != null) {
        final period = await _periodService.getPeriodOnce(community.currentPeriodId!);
        if (mounted) {
          setState(() => _currentPeriod = period);
        }
      }
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

  Future<void> _changePhase(PeriodPhase newPhase) async {
    if (_currentPeriod == null || _community == null) return;
    if (_currentPeriod!.phase == newPhase) return;

    final phaseNames = {
      PeriodPhase.voting: 'Oylama',
      PeriodPhase.discussion: 'Tartisma',
      PeriodPhase.closed: 'Kapali',
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fazi Degistir'),
        content: Text(
          'Mevcut donem "${phaseNames[newPhase]}" fazina gecirmek istediginize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Degistir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _periodService.changePhase(
        _currentPeriod!.id,
        newPhase,
        widget.communityId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faz "${phaseNames[newPhase]}" olarak degistirildi')),
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

  Future<void> _createNewPeriod() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PeriodCreateScreen(communityId: widget.communityId),
      ),
    );

    if (result == true) {
      await _loadCommunity();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni donem olusturuldu')),
        );
      }
    }
  }

  Future<void> _pickCoverPhoto() async {
    if (_community == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingCover = true);

    try {
      final Uint8List imageBytes = await image.readAsBytes();
      final downloadURL = await _storageService.uploadCommunityCover(
        widget.communityId,
        imageBytes,
      );

      await _communityService.updateCommunity(
        widget.communityId,
        coverPhotoURL: downloadURL,
      );

      await _loadCommunity();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kapak fotografı yuklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingCover = false);
      }
    }
  }

  Future<void> _removeCoverPhoto() async {
    if (_community == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kapak Fotografini Kaldir'),
        content: const Text('Kapak fotografini kaldirmak istediginize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaldir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _storageService.deleteCommunityCover(widget.communityId);
      await _communityService.updateCommunity(
        widget.communityId,
        clearCoverPhoto: true,
      );
      await _loadCommunity();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kapak fotografı kaldirildi')),
        );
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

  Future<void> _changeJoinType(JoinType newType) async {
    if (_community == null || _community!.joinType == newType) return;

    setState(() => _isLoading = true);

    try {
      await _communityService.updateCommunity(
        widget.communityId,
        joinType: newType,
      );
      await _loadCommunity();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Katilim tipi "${newType.label}" olarak degistirildi')),
        );
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
              // Cover photo section (v8.0)
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover image or placeholder
                    Stack(
                      children: [
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                          ),
                          child: _community!.coverPhotoURL != null
                              ? Image.network(
                                  _community!.coverPhotoURL!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(Icons.image, size: 48, color: color),
                                  ),
                                )
                              : Center(
                                  child: Icon(Icons.add_photo_alternate, size: 48, color: color),
                                ),
                        ),
                        if (_isUploadingCover)
                          Container(
                            height: 120,
                            color: Colors.black45,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Row(
                            children: [
                              if (_community!.coverPhotoURL != null)
                                IconButton.filled(
                                  onPressed: _isUploadingCover ? null : _removeCoverPhoto,
                                  icon: const Icon(Icons.delete, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              const SizedBox(width: 4),
                              IconButton.filled(
                                onPressed: _isUploadingCover ? null : _pickCoverPhoto,
                                icon: const Icon(Icons.camera_alt, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Kapak Fotografı',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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

              // Phase control section (v8.0)
              if (_currentPeriod != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mevcut Donem',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    _currentPeriod!.title,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _PhaseButton(
                                phase: PeriodPhase.voting,
                                currentPhase: _currentPeriod!.phase,
                                onTap: _isLoading ? null : () => _changePhase(PeriodPhase.voting),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PhaseButton(
                                phase: PeriodPhase.discussion,
                                currentPhase: _currentPeriod!.phase,
                                onTap: _isLoading ? null : () => _changePhase(PeriodPhase.discussion),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PhaseButton(
                                phase: PeriodPhase.closed,
                                currentPhase: _currentPeriod!.phase,
                                onTap: _isLoading ? null : () => _changePhase(PeriodPhase.closed),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Stats section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Istatistikler',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.people,
                            '${_community!.stats.memberCount}',
                            'Uye',
                          ),
                          _buildStatItem(
                            Icons.calendar_today,
                            '${_community!.stats.periodCount}',
                            'Donem',
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

              // Join type card (v8.0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group_add, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Katilim Tipi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...JoinType.values.map((type) => RadioListTile<JoinType>(
                            title: Text(type.label),
                            subtitle: Text(type.description),
                            value: type,
                            groupValue: _community!.joinType,
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    if (value != null) {
                                      _changeJoinType(value);
                                    }
                                  },
                            contentPadding: EdgeInsets.zero,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rules card (v8.0)
              Card(
                child: ListTile(
                  leading: Icon(Icons.rule, color: Colors.orange.shade600),
                  title: const Text('Topluluk Kurallari'),
                  subtitle: Text(
                    _community!.rules?.isNotEmpty == true
                        ? 'Kurallar tanimlanmis'
                        : 'Henuz kural tanimlanmamis',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityRulesScreen(
                          communityId: widget.communityId,
                          initialRules: _community!.rules,
                        ),
                      ),
                    );
                    if (result == true) {
                      await _loadCommunity();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Members management
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Uyeleri Yonet'),
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

              // Create new period button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _createNewPeriod,
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Donem Baslat'),
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

/// Phase button widget for phase control
class _PhaseButton extends StatelessWidget {
  final PeriodPhase phase;
  final PeriodPhase currentPhase;
  final VoidCallback? onTap;

  const _PhaseButton({
    required this.phase,
    required this.currentPhase,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = phase == currentPhase;
    final phaseInfo = _getPhaseInfo();

    return Material(
      color: isActive ? phaseInfo.color.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? phaseInfo.color : Colors.grey.shade300,
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                phaseInfo.icon,
                color: isActive ? phaseInfo.color : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                phaseInfo.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? phaseInfo.color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({IconData icon, String label, Color color}) _getPhaseInfo() {
    switch (phase) {
      case PeriodPhase.voting:
        return (icon: Icons.how_to_vote, label: 'Oylama', color: Colors.blue);
      case PeriodPhase.discussion:
        return (icon: Icons.forum, label: 'Tartisma', color: Colors.green);
      case PeriodPhase.closed:
        return (icon: Icons.lock, label: 'Kapali', color: Colors.grey);
    }
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
