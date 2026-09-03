import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/models.dart';
import '../../../core/services/supabase_service.dart';

class AdminBlogEditorScreen extends StatefulWidget {
  final CmsBlogPostModel? postToEdit;
  final List<CmsBlogCategoryModel> categories;

  const AdminBlogEditorScreen({
    super.key,
    this.postToEdit,
    this.categories = const [],
  });

  @override
  State<AdminBlogEditorScreen> createState() => _AdminBlogEditorScreenState();
}

class _AdminBlogEditorScreenState extends State<AdminBlogEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _contentController;
  late TextEditingController _excerptController;
  late TextEditingController _authorController;
  late TextEditingController _tagsController;
  late TextEditingController _readTimeController;
  late TextEditingController _featuredImageController;
  late TextEditingController _seoTitleController;
  late TextEditingController _metaDescController;
  late TextEditingController _canonicalUrlController;
  late TextEditingController _ogTitleController;
  late TextEditingController _ogDescController;
  late TextEditingController _ogImageController;
  late TextEditingController _twitterTitleController;
  late TextEditingController _twitterDescController;
  late TextEditingController _twitterImageController;
  late TextEditingController _schemaJsonLdController;

  bool _robotsIndex = true;
  bool _robotsFollow = true;
  String? _selectedCategoryId;
  String _status = 'draft';
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _showLivePreview = false;
  late List<CmsBlogCategoryModel> _localCategories;

  @override
  void initState() {
    super.initState();
    _localCategories = List.from(widget.categories);
    final p = widget.postToEdit;

    _titleController = TextEditingController(text: p?.title ?? '');
    _slugController = TextEditingController(text: p?.slug ?? '');
    _contentController = TextEditingController(text: p?.content ?? '');
    _excerptController = TextEditingController(text: p?.excerpt ?? '');
    _authorController = TextEditingController(text: p?.authorName ?? 'Cosmyra Academic Team');
    _tagsController = TextEditingController(text: p != null ? p.tags.join(', ') : '');
    _readTimeController = TextEditingController(text: (p?.readTimeMinutes ?? 5).toString());
    _featuredImageController = TextEditingController(text: p?.featuredImageUrl ?? '');
    _seoTitleController = TextEditingController(text: p?.seoTitle ?? '');
    _metaDescController = TextEditingController(text: p?.metaDescription ?? '');
    _canonicalUrlController = TextEditingController(text: p?.canonicalUrl ?? '');
    _ogTitleController = TextEditingController(text: p?.ogTitle ?? '');
    _ogDescController = TextEditingController(text: p?.ogDescription ?? '');
    _ogImageController = TextEditingController(text: p?.ogImageUrl ?? '');
    _twitterTitleController = TextEditingController(text: p?.twitterTitle ?? '');
    _twitterDescController = TextEditingController(text: p?.twitterDescription ?? '');
    _twitterImageController = TextEditingController(text: p?.twitterImageUrl ?? '');
    _schemaJsonLdController = TextEditingController(text: p?.schemaJsonLd ?? '');
    _robotsIndex = p?.robotsIndex ?? true;
    _robotsFollow = p?.robotsFollow ?? true;

    _selectedCategoryId = p?.categoryId;
    if (_selectedCategoryId == null && _localCategories.isNotEmpty) {
      _selectedCategoryId = _localCategories.first.id;
    }
    _status = p?.status ?? 'draft';

    if (widget.postToEdit == null) {
      _titleController.addListener(_onTitleChanged);
    }
    _seoTitleController.addListener(() => setState(() {}));
    _metaDescController.addListener(() => setState(() {}));
  }

  void _onTitleChanged() {
    if (widget.postToEdit == null) {
      final autoSlug = _titleController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '-');
      _slugController.text = autoSlug;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _slugController.dispose();
    _contentController.dispose();
    _excerptController.dispose();
    _authorController.dispose();
    _tagsController.dispose();
    _readTimeController.dispose();
    _featuredImageController.dispose();
    _seoTitleController.dispose();
    _metaDescController.dispose();
    _canonicalUrlController.dispose();
    _ogTitleController.dispose();
    _ogDescController.dispose();
    _ogImageController.dispose();
    _twitterTitleController.dispose();
    _twitterDescController.dispose();
    _twitterImageController.dispose();
    _schemaJsonLdController.dispose();
    super.dispose();
  }

  void _insertMarkdown(String before, [String after = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final selectedText = text.substring(start, end);

    final replacement = '$before$selectedText$after';
    final newText = text.replaceRange(start, end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + before.length + selectedText.length),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        setState(() => _isUploadingImage = true);
        final file = result.files.first;
        final url = await SupabaseService.uploadCmsImage(file.bytes!, file.name);

        if (mounted) {
          setState(() => _isUploadingImage = false);
          if (url != null) {
            _featuredImageController.text = url;
            _insertMarkdown('![${file.name}]($url)\n');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded and inserted!'), backgroundColor: Color(0xFF10B981)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image.'), backgroundColor: Color(0xFFDC2626)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _createNewCategoryDialog() async {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();

    nameCtrl.addListener(() {
      slugCtrl.text = nameCtrl.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '-');
    });

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Blog Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Exam Updates'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slugCtrl,
              decoration: const InputDecoration(labelText: 'Slug', hintText: 'e.g. exam-updates'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty && slugCtrl.text.trim().isNotEmpty) {
                final cat = CmsBlogCategoryModel(
                  id: '',
                  name: nameCtrl.text.trim(),
                  slug: slugCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                final saved = await SupabaseService.saveBlogCategory(cat);
                if (saved != null) {
                  setState(() {
                    _localCategories.add(saved);
                    _selectedCategoryId = saved.id;
                  });
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx, true);
                }
              }
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category created successfully!'), backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  Future<void> _savePost({bool? publishNow}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final finalStatus = publishNow != null
        ? (publishNow ? 'published' : 'draft')
        : _status;

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final readTime = int.tryParse(_readTimeController.text.trim()) ?? 5;

    final post = CmsBlogPostModel(
      id: widget.postToEdit?.id ?? '',
      title: _titleController.text.trim(),
      slug: _slugController.text.trim().toLowerCase(),
      content: _contentController.text,
      excerpt: _excerptController.text.trim().isNotEmpty ? _excerptController.text.trim() : null,
      featuredImageUrl: _featuredImageController.text.trim().isNotEmpty ? _featuredImageController.text.trim() : null,
      status: finalStatus,
      categoryId: _selectedCategoryId,
      tags: tags,
      authorName: _authorController.text.trim().isNotEmpty ? _authorController.text.trim() : 'Cosmyra Academic Team',
      seoTitle: _seoTitleController.text.trim().isNotEmpty ? _seoTitleController.text.trim() : null,
      metaDescription: _metaDescController.text.trim().isNotEmpty ? _metaDescController.text.trim() : null,
      canonicalUrl: _canonicalUrlController.text.trim().isNotEmpty ? _canonicalUrlController.text.trim() : null,
      robotsIndex: _robotsIndex,
      robotsFollow: _robotsFollow,
      ogTitle: _ogTitleController.text.trim().isNotEmpty ? _ogTitleController.text.trim() : null,
      ogDescription: _ogDescController.text.trim().isNotEmpty ? _ogDescController.text.trim() : null,
      ogImageUrl: _ogImageController.text.trim().isNotEmpty ? _ogImageController.text.trim() : null,
      twitterTitle: _twitterTitleController.text.trim().isNotEmpty ? _twitterTitleController.text.trim() : null,
      twitterDescription: _twitterDescController.text.trim().isNotEmpty ? _twitterDescController.text.trim() : null,
      twitterImageUrl: _twitterImageController.text.trim().isNotEmpty ? _twitterImageController.text.trim() : null,
      schemaJsonLd: _schemaJsonLdController.text.trim().isNotEmpty ? _schemaJsonLdController.text.trim() : null,
      readTimeMinutes: readTime,
      viewsCount: widget.postToEdit?.viewsCount ?? 0,
      createdAt: widget.postToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      publishedAt: finalStatus == 'published' ? (widget.postToEdit?.publishedAt ?? DateTime.now()) : null,
    );

    final saved = await SupabaseService.saveBlogPost(post);

    if (mounted) {
      setState(() => _isSaving = false);
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finalStatus == 'published'
                  ? 'Blog post successfully published live!'
                  : 'Blog post saved as draft.',
            ),
            backgroundColor: finalStatus == 'published' ? const Color(0xFF059669) : const Color(0xFF4F46E5),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving blog post. Please check that slug is unique.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.postToEdit != null;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Blog Post' : 'Create Blog Post',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showLivePreview = !_showLivePreview),
            icon: Icon(_showLivePreview ? Icons.edit_note_rounded : Icons.visibility_outlined, size: 18, color: const Color(0xFF4F46E5)),
            label: Text(_showLivePreview ? 'Editor' : 'Preview', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _isSaving ? null : () => _savePost(publishNow: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Draft'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _savePost(publishNow: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.rocket_launch_rounded, size: 16),
            label: const Text('Publish Live', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _showLivePreview
          ? _buildFullPreview()
          : Form(
              key: _formKey,
              child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Left Content (65%)
        Expanded(
          flex: 65,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicDetailsCard(),
                const SizedBox(height: 20),
                _buildContentEditorCard(),
              ],
            ),
          ),
        ),

        // Sidebar Settings (35%)
        Expanded(
          flex: 35,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPublishCard(),
                  const SizedBox(height: 20),
                  _buildCategorizationCard(),
                  const SizedBox(height: 20),
                  _buildFeaturedImageCard(),
                  const SizedBox(height: 20),
                  _buildSeoCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicDetailsCard(),
          const SizedBox(height: 16),
          _buildContentEditorCard(),
          const SizedBox(height: 16),
          _buildPublishCard(),
          const SizedBox(height: 16),
          _buildCategorizationCard(),
          const SizedBox(height: 16),
          _buildFeaturedImageCard(),
          const SizedBox(height: 16),
          _buildSeoCard(),
        ],
      ),
    );
  }

  Widget _buildBasicDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Article Title & Slug', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Article Title *',
              hintText: 'e.g. Top 10 High-Yield Biology Chapters for NEET 2026',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _slugController,
            decoration: InputDecoration(
              labelText: 'URL Slug *',
              prefixText: '/blog/',
              prefixStyle: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Slug is required';
              if (!RegExp(r'^[a-z0-9-]+$').hasMatch(val.trim())) {
                return 'Only lowercase letters, numbers, and hyphens allowed';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _excerptController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Short Excerpt / Teaser',
              hintText: 'Brief summary displayed on the blog card and social previews...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentEditorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _toolbarBtn('H1', () => _insertMarkdown('# ')),
                _toolbarBtn('H2', () => _insertMarkdown('## ')),
                _toolbarBtn('H3', () => _insertMarkdown('### ')),
                const SizedBox(width: 8),
                _toolbarIcon(Icons.format_bold_rounded, 'Bold', () => _insertMarkdown('**', '**')),
                _toolbarIcon(Icons.format_italic_rounded, 'Italic', () => _insertMarkdown('*', '*')),
                _toolbarIcon(Icons.format_list_bulleted_rounded, 'Bullet List', () => _insertMarkdown('- ')),
                _toolbarIcon(Icons.format_list_numbered_rounded, 'Numbered List', () => _insertMarkdown('1. ')),
                _toolbarIcon(Icons.format_quote_rounded, 'Quote', () => _insertMarkdown('> ')),
                _toolbarIcon(Icons.code_rounded, 'Code', () => _insertMarkdown('```\n', '\n```')),
                _toolbarIcon(Icons.functions_rounded, 'LaTeX Formula', () => _insertMarkdown(r'$$', r'$$')),
                _toolbarIcon(Icons.link_rounded, 'Link', () => _insertMarkdown('[Link](', ')')),
                _toolbarIcon(
                  Icons.image_rounded,
                  'Upload Image',
                  _isUploadingImage ? null : _pickAndUploadImage,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _contentController,
              maxLines: 22,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13.5, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Write article content in Markdown...\n\n# Introduction\nShare tips, formulas, diagrams...',
                border: InputBorder.none,
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Content cannot be empty' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Publish Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Status:', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              const Spacer(),
              DropdownButton<String>(
                value: _status,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'published', child: Text('Published')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _readTimeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Est. Read Time (Minutes)',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorizationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Category & Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF4F46E5)),
                tooltip: 'Add New Category',
                onPressed: _createNewCategoryDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Category',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            items: _localCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Author Name',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (Comma separated)',
              hintText: 'NEET 2026, Biology, High Yield',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedImageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Featured Cover Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _featuredImageController,
            decoration: InputDecoration(
              labelText: 'Image URL',
              hintText: 'https://...',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                icon: const Icon(Icons.upload_file_rounded, size: 20, color: Color(0xFF4F46E5)),
                tooltip: 'Upload Image',
                onPressed: _pickAndUploadImage,
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          if (_featuredImageController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _featuredImageController.text,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeoCard() {
    final displayTitle = _seoTitleController.text.trim().isNotEmpty
        ? _seoTitleController.text.trim()
        : (_titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Blog Title | Cosmyra NEET JEE Blog');
    final displaySlug = _slugController.text.trim().isNotEmpty ? _slugController.text.trim() : 'sample-blog-post';
    final displayDesc = _metaDescController.text.trim().isNotEmpty
        ? _metaDescController.text.trim()
        : (_excerptController.text.trim().isNotEmpty
            ? _excerptController.text.trim()
            : 'Read our high-yield medical and engineering entrance prep guide, strategy breakdowns, and exam analysis on Cosmyra.');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Search Engine Optimization (SEO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Google Live Preview', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Google SERP Snippet Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0F172A),
                      ),
                      child: const Center(
                        child: Text('C', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cosmyra NEET JEE Blog', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF202124))),
                          Text('https://neet-jee.in/blog/$displaySlug', style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  displayTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A0DAB)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  displayDesc,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF4D5156), height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SEO Title Field
          TextFormField(
            controller: _seoTitleController,
            decoration: InputDecoration(
              labelText: 'SEO Meta Title',
              hintText: 'Defaults to blog title if empty',
              helperText: '${_seoTitleController.text.length}/60 characters (Optimal: 50-60)',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 14),

          // Meta Description Field
          TextFormField(
            controller: _metaDescController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Meta Description',
              hintText: 'Brief summary for Google search result snippets...',
              helperText: '${_metaDescController.text.length}/160 characters (Optimal: 150-160)',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 14),

          // Canonical URL
          TextFormField(
            controller: _canonicalUrlController,
            decoration: InputDecoration(
              labelText: 'Canonical URL (Optional)',
              hintText: 'https://neet-jee.in/blog/...',
              helperText: 'Leave blank to use default canonical URL',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 14),

          // Robots Directives
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Index Article', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Allow Google to index', style: TextStyle(fontSize: 11)),
                  value: _robotsIndex,
                  activeColor: const Color(0xFF059669),
                  onChanged: (v) => setState(() => _robotsIndex = v),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Follow Links', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Allow crawlers to follow links', style: TextStyle(fontSize: 11)),
                  value: _robotsFollow,
                  activeColor: const Color(0xFF059669),
                  onChanged: (v) => setState(() => _robotsFollow = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Social Share Cover
          TextFormField(
            controller: _ogImageController,
            decoration: InputDecoration(
              labelText: 'Social Share Image (Open Graph / Twitter)',
              hintText: 'https://...',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 14),

          // Custom Schema JSON-LD
          TextFormField(
            controller: _schemaJsonLdController,
            maxLines: 4,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              labelText: 'Custom JSON-LD Schema (Optional)',
              hintText: '{\n  "@context": "https://schema.org",\n  "@type": "BlogPosting"\n}',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_featuredImageController.text.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _featuredImageController.text,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                _titleController.text.isNotEmpty ? _titleController.text : 'Untitled Blog Post',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('By ${_authorController.text}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(width: 14),
                  Text('${_readTimeController.text} min read', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                ],
              ),
              const Divider(height: 32),
              MarkdownBody(
                data: _contentController.text.isNotEmpty ? _contentController.text : '*No content yet.*',
                selectable: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF334155))),
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, String tooltip, VoidCallback? onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: const Color(0xFF475569)),
        ),
      ),
    );
  }
}
