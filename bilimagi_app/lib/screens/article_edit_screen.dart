import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/article.dart';
import '../core/theme.dart';
import '../services/article_service.dart';
import '../services/storage_service.dart';
import '../widgets/markdown_editor.dart';

/// Screen for creating/editing articles (v8.0)
class ArticleEditScreen extends StatefulWidget {
  final String weekId;
  final String communityId;
  final Article? article; // null for new article

  const ArticleEditScreen({
    super.key,
    required this.weekId,
    required this.communityId,
    this.article,
  });

  @override
  State<ArticleEditScreen> createState() => _ArticleEditScreenState();
}

class _ArticleEditScreenState extends State<ArticleEditScreen> {
  final _articleService = ArticleService();
  final _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _linkController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _heroImageURL;
  bool _isUploadingImage = false;
  String? _savedArticleId;

  bool get _isEditing => widget.article != null;

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      _titleController.text = widget.article!.title;
      _summaryController.text = widget.article!.summary;
      _linkController.text = widget.article!.link;
      _contentController.text = widget.article!.content ?? '';
      _heroImageURL = widget.article!.heroImageURL;
      _savedArticleId = widget.article!.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _linkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickHeroImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final Uint8List imageBytes = await image.readAsBytes();

      // We need an article ID to upload the image
      // If editing, use existing ID; if creating, save as draft first
      String articleId;
      if (_savedArticleId != null) {
        articleId = _savedArticleId!;
      } else {
        // Save draft to get an ID
        articleId = await _articleService.saveDraft(
          weekId: widget.weekId,
          communityId: widget.communityId,
          title: _titleController.text.trim().isEmpty
              ? 'Adsiz Taslak'
              : _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          link: _linkController.text.trim(),
          content: _contentController.text,
        );
        _savedArticleId = articleId;
      }

      final downloadURL = await _storageService.uploadArticleHeroImage(
        widget.weekId,
        articleId,
        imageBytes,
      );

      await _articleService.updateArticle(
        weekId: widget.weekId,
        articleId: articleId,
        communityId: widget.communityId,
        heroImageURL: downloadURL,
      );

      setState(() {
        _heroImageURL = downloadURL;
        _hasChanges = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hero gorsel yuklendi')),
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
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _removeHeroImage() async {
    if (_heroImageURL == null || _savedArticleId == null) return;

    setState(() => _isLoading = true);

    try {
      await _storageService.deleteArticleHeroImage(
        widget.weekId,
        _savedArticleId!,
      );

      await _articleService.updateArticle(
        weekId: widget.weekId,
        articleId: _savedArticleId!,
        communityId: widget.communityId,
        clearHeroImage: true,
      );

      setState(() {
        _heroImageURL = null;
        _hasChanges = true;
      });
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

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);

    try {
      final articleId = await _articleService.saveDraft(
        weekId: widget.weekId,
        communityId: widget.communityId,
        articleId: _savedArticleId,
        title: _titleController.text.trim().isEmpty
            ? 'Adsiz Taslak'
            : _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        link: _linkController.text.trim(),
        heroImageURL: _heroImageURL,
        content: _contentController.text,
      );

      _savedArticleId = articleId;
      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Taslak kaydedildi')),
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
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_savedArticleId != null) {
        // Update existing and publish
        await _articleService.updateArticle(
          weekId: widget.weekId,
          articleId: _savedArticleId!,
          communityId: widget.communityId,
          title: _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          link: _linkController.text.trim(),
          content: _contentController.text,
        );
        await _articleService.publishArticle(
          weekId: widget.weekId,
          articleId: _savedArticleId!,
          communityId: widget.communityId,
        );
      } else {
        // Create and publish directly
        await _articleService.createArticle(
          weekId: widget.weekId,
          communityId: widget.communityId,
          title: _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          link: _linkController.text.trim(),
          heroImageURL: _heroImageURL,
          content: _contentController.text,
          status: ArticleStatus.published,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Makale yayinlandi')),
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_savedArticleId == null) return;

    setState(() => _isLoading = true);

    try {
      await _articleService.updateArticle(
        weekId: widget.weekId,
        articleId: _savedArticleId!,
        communityId: widget.communityId,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        link: _linkController.text.trim(),
        content: _contentController.text,
      );

      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Degisiklikler kaydedildi')),
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

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydedilmemis Degisiklikler'),
        content: const Text('Degisiklikleri kaydetmek ister misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0), // Discard
            child: const Text('Kaydetme'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 1), // Cancel
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 2), // Save draft
            child: const Text('Taslak Kaydet'),
          ),
        ],
      ),
    );

    if (result == 0) return true;
    if (result == 2) {
      await _saveDraft();
      return true;
    }
    return false;
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
          title: Text(_isEditing ? 'Makaleyi Duzenle' : 'Yeni Makale'),
          actions: [
            if (!_isEditing || widget.article?.status == ArticleStatus.draft) ...[
              // Save draft button
              TextButton(
                onPressed: _isSaving || _isLoading ? null : _saveDraft,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Taslak'),
              ),
              // Publish button
              FilledButton(
                onPressed: _isLoading ? null : _publish,
                child: const Text('Yayinla'),
              ),
              const SizedBox(width: 8),
            ] else ...[
              // Save changes button for published articles
              FilledButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kaydet'),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image
                _buildHeroImageSection(),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Makale Basligi',
                    hintText: 'Makale basligini girin',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 5) {
                      return 'En az 5 karakter giriniz';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
                const SizedBox(height: 16),

                // Summary
                TextFormField(
                  controller: _summaryController,
                  decoration: const InputDecoration(
                    labelText: 'Ozet',
                    hintText: 'Makale ozetini girin',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().length < 20) {
                      return 'En az 20 karakter giriniz';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
                const SizedBox(height: 16),

                // Link
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Kaynak Linki',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Link giriniz';
                    }
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return 'Gecerli bir URL giriniz';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
                const SizedBox(height: 24),

                // Content (Markdown)
                Text(
                  'Icerik (Opsiyonel)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 400,
                  child: MarkdownEditor(
                    controller: _contentController,
                    hintText: 'Makale icerigini Markdown formatinda yazabilirsiniz...',
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImageSection() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: _heroImageURL != null
                    ? Image.network(
                        _heroImageURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hero gorsel ekle',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (_isUploadingImage)
                Container(
                  height: 180,
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              // Action buttons
              Positioned(
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    if (_heroImageURL != null)
                      IconButton.filled(
                        onPressed: _isUploadingImage ? null : _removeHeroImage,
                        icon: const Icon(Icons.delete, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      onPressed: _isUploadingImage ? null : _pickHeroImage,
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
              'Hero Gorsel (Opsiyonel)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
