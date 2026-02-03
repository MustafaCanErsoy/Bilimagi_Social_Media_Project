import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/period.dart';
import '../services/firestore_service.dart';
import '../services/period_service.dart';
import '../services/seed_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _firestoreService = FirestoreService();
  final _periodService = PeriodService();
  final _seedService = SeedService();
  String? _selectedCommunityId;
  bool _isSeeding = false;

  Widget _buildSeedButton() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_backup_restore, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Demo Verileri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Firebase\'e demo verilerini yükler (2 topluluk, makaleler, kullanıcılar)',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSeeding ? null : _seedDatabase,
                icon: _isSeeding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isSeeding ? 'Yükleniyor...' : 'Demo Verilerini Yükle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Verilerini Yükle'),
        content: const Text(
          'Bu işlem Firebase\'e demo verilerini yükleyecek. '
          'Mevcut veriler silinmeyecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSeeding = true);

    try {
      await _seedService.seedDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo verileri basariyla yuklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeedButton(),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Topluluk Seçin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCommunityDropdown(),
            const SizedBox(height: 32),
            if (_selectedCommunityId != null) _buildPhaseControl(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityDropdown() {
    return StreamBuilder<List<Community>>(
      stream: _firestoreService.getCommunities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final communities = snapshot.data ?? [];

        if (communities.isEmpty) {
          return const Text('Topluluk bulunamadı.');
        }

        // Ensure selected value exists in the list
        final communityIds = communities.map((c) => c.id).toList();
        final validSelectedId = _selectedCommunityId != null &&
                communityIds.contains(_selectedCommunityId)
            ? _selectedCommunityId
            : null;

        return DropdownButtonFormField<String>(
          value: validSelectedId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Topluluk',
          ),
          items: communities.map((community) {
            return DropdownMenuItem(
              value: community.id,
              child: Text(community.name),
            );
          }).toList(),
          onChanged: (communityId) {
            setState(() => _selectedCommunityId = communityId);
          },
        );
      },
    );
  }

  Widget _buildPhaseControl() {
    return StreamBuilder<Community?>(
      stream: _firestoreService.getCommunities().map((communities) {
        return communities.firstWhere(
          (c) => c.id == _selectedCommunityId,
          orElse: () => communities.first,
        );
      }),
      builder: (context, communitySnapshot) {
        final community = communitySnapshot.data;
        if (community == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Topluluk bulunamadı.'),
            ),
          );
        }

        final periodId = community.currentPeriodId;

        if (periodId == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bu topluluk için aktif dönem bulunmuyor.'),
            ),
          );
        }

        return StreamBuilder<Period?>(
          stream: _periodService.getPeriod(periodId),
          builder: (context, periodSnapshot) {
            if (periodSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final period = periodSnapshot.data;
            if (period == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Dönem bulunamadı.'),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dönem: ${period.title}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Mevcut Faz: ',
                          style: TextStyle(fontSize: 16),
                        ),
                        _buildPhaseChip(period.phase),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Faz Değiştir',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _PhaseButton(
                            label: 'Oylama',
                            icon: Icons.how_to_vote,
                            color: Colors.blue,
                            isActive: period.phase == PeriodPhase.voting,
                            onPressed: () => _changePhase(periodId, PeriodPhase.voting, period.communityId),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PhaseButton(
                            label: 'Tartışma',
                            icon: Icons.chat,
                            color: Colors.green,
                            isActive: period.phase == PeriodPhase.discussion,
                            onPressed: () => _changePhase(periodId, PeriodPhase.discussion, period.communityId),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PhaseButton(
                            label: 'Kapalı',
                            icon: Icons.lock,
                            color: Colors.grey,
                            isActive: period.phase == PeriodPhase.closed,
                            onPressed: () => _changePhase(periodId, PeriodPhase.closed, period.communityId),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPhaseChip(PeriodPhase phase) {
    Color color;
    String label;
    IconData icon;

    switch (phase) {
      case PeriodPhase.voting:
        color = Colors.blue;
        label = 'Oylama';
        icon = Icons.how_to_vote;
      case PeriodPhase.discussion:
        color = Colors.green;
        label = 'Tartışma';
        icon = Icons.chat;
      case PeriodPhase.closed:
        color = Colors.grey;
        label = 'Kapalı';
        icon = Icons.lock;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Future<void> _changePhase(String periodId, PeriodPhase newPhase, String communityId) async {
    try {
      await _periodService.changePhase(periodId, newPhase, communityId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faz "${newPhase.name}" olarak değiştirildi.')),
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
}

class _PhaseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onPressed;

  const _PhaseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : Colors.grey[200],
        foregroundColor: isActive ? Colors.white : Colors.grey[700],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isActive ? BorderSide.none : BorderSide(color: color, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
