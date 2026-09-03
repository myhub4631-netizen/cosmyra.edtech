import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/models.dart';
import '../../../core/services/supabase_service.dart';

class AdminPageEditorScreen extends StatefulWidget {
  final CmsPageModel? pageToEdit;

  const AdminPageEditorScreen({super.key, this.pageToEdit});

  @override
  State<AdminPageEditorScreen> createState() => _AdminPageEditorScreenState();
}

class _AdminPageEditorScreenState extends State<AdminPageEditorScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _contentController;
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
  late TextEditingController _featuredImageController;

  bool _robotsIndex = true;
  bool _robotsFollow = true;
  String _status = 'draft';
  bool _isSystem = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _showLivePreview = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pageToEdit;
    _titleController = TextEditingController(text: p?.title ?? '');
    _slugController = TextEditingController(text: p?.slug ?? '');
    _contentController = TextEditingController(text: p?.content ?? '');
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
    _featuredImageController = TextEditingController(text: p?.featuredImageUrl ?? '');
    _robotsIndex = p?.robotsIndex ?? true;
    _robotsFollow = p?.robotsFollow ?? true;
    _status = p?.status ?? 'draft';
    _isSystem = p?.isSystem ?? false;

    // Auto-generate slug from title if new
    if (widget.pageToEdit == null) {
      _titleController.addListener(_onTitleChanged);
    }
    _seoTitleController.addListener(() => setState(() {}));
    _metaDescController.addListener(() => setState(() {}));
  }

  void _onTitleChanged() {
    if (widget.pageToEdit == null) {
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
    _featuredImageController.dispose();
    super.dispose();
  }

  void _insertMarkdown(String before, [String after = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, '$before$after');
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + before.length),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _isUploadingImage = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final name = result.files.single.name;
        final url = await SupabaseService.uploadCmsImage(bytes, name);
        if (url != null) {
          _insertMarkdown('![$name]($url)');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded and inserted!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _savePage({bool? publishNow}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final finalStatus = publishNow != null
        ? (publishNow ? 'published' : 'draft')
        : _status;

    final page = CmsPageModel(
      id: widget.pageToEdit?.id ?? '',
      slug: _slugController.text.trim().toLowerCase(),
      title: _titleController.text.trim(),
      content: _contentController.text,
      contentFormat: 'markdown',
      status: finalStatus,
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
      featuredImageUrl: _featuredImageController.text.trim().isNotEmpty ? _featuredImageController.text.trim() : null,
      isSystem: _isSystem,
      authorName: widget.pageToEdit?.authorName ?? 'Cosmyra Admin',
      createdAt: widget.pageToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      publishedAt: finalStatus == 'published' ? (widget.pageToEdit?.publishedAt ?? DateTime.now()) : null,
    );

    final saved = await SupabaseService.saveCmsPage(page);

    if (mounted) {
      setState(() => _isSaving = false);
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finalStatus == 'published'
                  ? 'Page successfully published live!'
                  : 'Page saved as draft.',
            ),
            backgroundColor: finalStatus == 'published' ? const Color(0xFF059669) : const Color(0xFF4F46E5),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving page to database. Ensure slug is unique.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pageToEdit != null;
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
          isEditing ? 'Edit Page: ${widget.pageToEdit!.title}' : 'Create New Page',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          // Preview toggle
          TextButton.icon(
            onPressed: () => setState(() => _showLivePreview = !_showLivePreview),
            icon: Icon(
              _showLivePreview ? Icons.edit_note_rounded : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF4F46E5),
            ),
            label: Text(_showLivePreview ? 'Editor' : 'Preview', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),

          // Save Draft
          OutlinedButton(
            onPressed: _isSaving ? null : () => _savePage(publishNow: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Draft'),
          ),
          const SizedBox(width: 8),

          // Publish Button
          ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _savePage(publishNow: true),
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
        // Main Editor (Left 65%)
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

        // Sidebar Settings (Right 35%)
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
                  _buildPublishSettingsCard(),
                  const SizedBox(height: 20),
                  _buildSeoCard(),
                  const SizedBox(height: 20),
                  _buildFeaturedImageCard(),
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
          _buildPublishSettingsCard(),
          const SizedBox(height: 16),
          _buildSeoCard(),
          const SizedBox(height: 16),
          _buildFeaturedImageCard(),
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
          const Text('Page Title & Slug', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Page Title *',
              hintText: 'e.g. About Us, Privacy Policy, FAQ',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),

          // Slug
          TextFormField(
            controller: _slugController,
            decoration: InputDecoration(
              labelText: 'URL Slug *',
              hintText: 'e.g. about-us, privacy-policy',
              prefixText: '/pages/',
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
          // Formatting toolbar
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
                _toolbarBtn(label: 'H1', tooltip: 'Heading 1', onTap: () => _insertMarkdown('# ')),
                _toolbarBtn(label: 'H2', tooltip: 'Heading 2', onTap: () => _insertMarkdown('## ')),
                _toolbarBtn(label: 'H3', tooltip: 'Heading 3', onTap: () => _insertMarkdown('### ')),
                const SizedBox(width: 8),
                _toolbarIcon(icon: Icons.format_bold_rounded, tooltip: 'Bold', onTap: () => _insertMarkdown('**', '**')),
                _toolbarIcon(icon: Icons.format_italic_rounded, tooltip: 'Italic', onTap: () => _insertMarkdown('*', '*')),
                _toolbarIcon(icon: Icons.format_list_bulleted_rounded, tooltip: 'Bullet List', onTap: () => _insertMarkdown('- ')),
                _toolbarIcon(icon: Icons.format_list_numbered_rounded, tooltip: 'Numbered List', onTap: () => _insertMarkdown('1. ')),
                _toolbarIcon(icon: Icons.format_quote_rounded, tooltip: 'Blockquote', onTap: () => _insertMarkdown('> ')),
                _toolbarIcon(icon: Icons.code_rounded, tooltip: 'Code Block', onTap: () => _insertMarkdown('```\n', '\n```')),
                _toolbarIcon(icon: Icons.functions_rounded, tooltip: 'LaTeX Math Formula', onTap: () => _insertMarkdown(r'$$', r'$$')),
                _toolbarIcon(icon: Icons.link_rounded, tooltip: 'Insert Link', onTap: () => _insertMarkdown('[Link Title](', ')')),
                _toolbarIcon(
                  icon: Icons.image_rounded,
                  tooltip: 'Upload & Insert Image',
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                ),
              ],
            ),
          ),

          // Content Text Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _contentController,
              maxLines: 22,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13.5, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Write page content in Markdown or formatted text...\n\n# Section Title\nDetailed content paragraph...',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishSettingsCard() {
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
          const Text('Publish Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Status:', style: TextStyle(fontSize: 13.5, color: Color(0xFF475569))),
              const Spacer(),
              DropdownButton<String>(
                value: _status,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft (Hidden)')),
                  DropdownMenuItem(value: 'published', child: Text('Published (Live)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
            ],
          ),
          const Divider(height: 20),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('System Protected Page', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Marks standard legal/core platform pages', style: TextStyle(fontSize: 11)),
            value: _isSystem,
            onChanged: (val) => setState(() => _isSystem = val ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildSeoCard() {
    final displayTitle = _seoTitleController.text.trim().isNotEmpty
        ? _seoTitleController.text.trim()
        : (_titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Page Title | Cosmyra NEET JEE');
    final displaySlug = _slugController.text.trim().isNotEmpty ? _slugController.text.trim() : 'sample-slug';
    final displayDesc = _metaDescController.text.trim().isNotEmpty
        ? _metaDescController.text.trim()
        : 'Cosmyra NEET JEE preparation platform offers mock tests, test series, and comprehensive study notes for medical and engineering entrance exams.';

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
                          const Text('Cosmyra NEET JEE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF202124))),
                          Text('https://neet-jee.in/pages/$displaySlug', style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
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
              hintText: 'Defaults to page title if empty',
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
              hintText: 'https://neet-jee.in/pages/about-us',
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
                  title: const Text('Index Page', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Allow search engines to index', style: TextStyle(fontSize: 11)),
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
              hintText: '{\n  "@context": "https://schema.org",\n  "@type": "WebPage"\n}',
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
          const Text('Featured Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                tooltip: 'Upload New Image',
                onPressed: _pickAndUploadImage,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildFullPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('PREVIEW MODE', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(height: 12),
              Text(
                _titleController.text.isNotEmpty ? _titleController.text : 'Untitled Page',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text('/pages/${_slugController.text}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
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

  Widget _toolbarBtn({required String label, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF334155))),
        ),
      ),
    );
  }

  Widget _toolbarIcon({required IconData icon, required String tooltip, required VoidCallback? onTap}) {
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
