import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../widgets/interest_tag_picker.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';
import '../core/theme.dart';

/// Profile edit screen with photo upload and interests
/// v7.2: Complete profile editing with photo and interests
class ProfileEditScreen extends StatefulWidget {
  final UserProfile profile;

  const ProfileEditScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late List<String> _selectedInterests;

  int _selectedColorIndex = 0;
  bool _saving = false;
  bool _uploadingPhoto = false;
  Uint8List? _newPhotoBytes;
  String? _currentPhotoURL;

  final _avatarColors = [
    AppTheme.primaryColor,
    AppTheme.secondaryColor,
    const Color(0xFF9B59B6),
    const Color(0xFF3498DB),
    const Color(0xFFE74C3C),
    const Color(0xFF2ECC71),
    const Color(0xFFF39C12),
    const Color(0xFF1ABC9C),
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _selectedColorIndex = widget.profile.avatarColorIndex;
    _selectedInterests = List<String>.from(widget.profile.interests);
    _currentPhotoURL = widget.profile.photoURL;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newPhotoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotograf secilemedi: $e')),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_currentPhotoURL != null || _newPhotoBytes != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Fotografı Kaldir',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _newPhotoBytes = null;
                    _currentPhotoURL = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      String? photoURL = _currentPhotoURL;

      // Upload new photo if selected
      if (_newPhotoBytes != null) {
        setState(() => _uploadingPhoto = true);
        photoURL = await _storageService.uploadProfilePhoto(_newPhotoBytes!);
        await _profileService.updateProfilePhoto(photoURL);
      } else if (_currentPhotoURL == null && widget.profile.photoURL != null) {
        // Photo was removed
        await _storageService.deleteProfilePhoto();
        await _profileService.removeProfilePhoto();
      }

      // Update profile data
      await _profileService.updateProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // Update interests
      await _profileService.updateInterests(_selectedInterests);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil guncellendi!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Duzenle'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo section
            _buildPhotoSection(),
            const SizedBox(height: 24),

            // Display name
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Isim',
                hintText: 'Gorunen isminiz',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Isim bos olamaz';
                }
                if (value.trim().length < 2) {
                  return 'Isim en az 2 karakter olmali';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Hakkinda',
                hintText: 'Kendinizi kisaca tanitin',
                prefixIcon: Icon(Icons.info_outline),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 200,
              validator: (value) {
                if (value != null && value.length > 200) {
                  return 'Hakkinda bolumu en fazla 200 karakter olabilir';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Interests section
            InterestTagPicker(
              selectedInterests: _selectedInterests,
              onChanged: (interests) {
                setState(() {
                  _selectedInterests = interests;
                });
              },
            ),
            const SizedBox(height: 24),

            // Color picker
            Text(
              'Avatar Rengi',
              style: AppTypography.h3.copyWith(
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fotograf olmadıginda kullanilacak renk',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.getTextMuted(context),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_avatarColors.length, (index) {
                final isSelected = index == _selectedColorIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColorIndex = index);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _avatarColors[index],
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    _avatarColors[index].withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Info text
            Card(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Profiliniz diger kullanicilar tarafindan gorulebilir',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final color = _avatarColors[_selectedColorIndex];

    return Center(
      child: GestureDetector(
        onTap: _showPhotoOptions,
        child: Stack(
          children: [
            // Avatar
            if (_newPhotoBytes != null)
              CircleAvatar(
                radius: 55,
                backgroundColor: color,
                backgroundImage: MemoryImage(_newPhotoBytes!),
              )
            else if (_currentPhotoURL != null && _currentPhotoURL!.isNotEmpty)
              CircleAvatar(
                radius: 55,
                backgroundColor: color,
                backgroundImage: NetworkImage(_currentPhotoURL!),
              )
            else
              CircleAvatar(
                radius: 55,
                backgroundColor: color,
                child: Text(
                  _displayNameController.text.isNotEmpty
                      ? _displayNameController.text[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

            // Camera icon overlay
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _uploadingPhoto
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
