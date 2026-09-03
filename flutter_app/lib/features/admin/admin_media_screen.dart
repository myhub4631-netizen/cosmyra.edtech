import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';

class AdminMediaScreen extends StatefulWidget {
  const AdminMediaScreen({Key? key}) : super(key: key);

  @override
  State<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends State<AdminMediaScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assets = [];
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  String _selectedTypeFilter = 'all'; // all, image, pdf, svg
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadMediaAssets();
  }

  Future<void> _loadMediaAssets() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.fetchAdminMediaAssets();
    if (mounted) {
      setState(() {
        _assets = data;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAssets {
    return _assets.where((item) {
      final q = _searchQuery.trim().toLowerCase();
      final title = (item['title'] ?? '').toString().toLowerCase();
      final fileName = (item['file_name'] ?? '').toString().toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      final tags = (item['tags'] as List?)?.join(' ').toLowerCase() ?? '';

      final matchesQuery = q.isEmpty ||
          title.contains(q) ||
          fileName.contains(q) ||
          category.contains(q) ||
          tags.contains(q);

      final matchesType = _selectedTypeFilter == 'all' ||
          (item['file_type']?.toString().toLowerCase() == _selectedTypeFilter);

      final matchesCategory = _selectedCategoryFilter == 'All' ||
          (item['category']?.toString() == _selectedCategoryFilter);

      return matchesQuery && matchesType && matchesCategory;
    }).toList();
  }

  int get _imageCount => _assets.where((a) => a['file_type'] == 'image').length;
  int get _pdfCount => _assets.where((a) => a['file_type'] == 'pdf').length;
  int get _svgCount => _assets.where((a) => a['file_type'] == 'svg').length;
  double get _totalSizeMb {
    double totalKb = 0;
    for (var a in _assets) {
      totalKb += (a['file_size_kb'] as num?)?.toDouble() ?? 0;
    }
    return totalKb / 1024.0;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Copied $label to clipboard!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openUploadAssetDialog() async {
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Question Diagrams');
    final tagsCtrl = TextEditingController();
    PlatformFile? pickedFile;
    String fileType = 'image';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upload New Asset',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // File Picker Container
                  InkWell(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'svg', 'doc', 'docx'],
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final f = result.files.first;
                        setDialogState(() {
                          pickedFile = f;
                          final ext = (f.extension ?? '').toLowerCase();
                          if (ext == 'pdf') {
                            fileType = 'pdf';
                          } else if (ext == 'svg') {
                            fileType = 'svg';
                          } else {
                            fileType = 'image';
                          }

                          if (titleCtrl.text.isEmpty) {
                            titleCtrl.text = f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').replaceAll('_', ' ');
                          }
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            pickedFile == null ? Icons.cloud_upload_outlined : Icons.check_circle_outline_rounded,
                            size: 38,
                            color: pickedFile == null ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pickedFile == null ? 'Click to browse image, PDF, or SVG' : pickedFile!.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: pickedFile == null ? const Color(0xFF334155) : const Color(0xFF0F172A),
                            ),
                          ),
                          if (pickedFile != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${(pickedFile!.size / 1024).toStringAsFixed(1)} KB • ${fileType.toUpperCase()}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title Input
                  Text('Asset Title / Label', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. NEET 2026 Biology Plant Cell Diagram',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  Text('Category', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: categoryCtrl.text,
                    items: const [
                      DropdownMenuItem(value: 'Question Diagrams', child: Text('Question Diagrams')),
                      DropdownMenuItem(value: 'Syllabus & Curriculum', child: Text('Syllabus & Curriculum')),
                      DropdownMenuItem(value: 'Study Notes', child: Text('Study Notes (PDF)')),
                      DropdownMenuItem(value: 'Branding & Logos', child: Text('Branding & Logos')),
                      DropdownMenuItem(value: 'User Avatars', child: Text('User Avatars')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => categoryCtrl.text = val);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tags Input
                  Text('Tags (comma separated)', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: tagsCtrl,
                    decoration: InputDecoration(
                      hintText: 'neet, biology, diagram, 2026',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter asset title'), backgroundColor: Color(0xFFEF4444)),
                            );
                            return;
                          }

                          String publicUrl = 'https://neet-jee.in/assets/uploads/custom_asset.png';
                          int sizeKb = 120;

                          if (pickedFile != null) {
                            sizeKb = (pickedFile!.size / 1024).ceil();
                            if (pickedFile!.bytes != null) {
                              final b64 = base64Encode(pickedFile!.bytes!);
                              publicUrl = 'data:${fileType == 'pdf' ? 'application/pdf' : 'image/png'};base64,$b64';
                            }
                          }

                          final newAsset = {
                            'id': 'med_${DateTime.now().millisecondsSinceEpoch}',
                            'title': titleCtrl.text.trim(),
                            'file_name': pickedFile?.name ?? 'uploaded_asset.${fileType == 'pdf' ? 'pdf' : (fileType == 'svg' ? 'svg' : 'png')}',
                            'file_type': fileType,
                            'mime_type': fileType == 'pdf' ? 'application/pdf' : (fileType == 'svg' ? 'image/svg+xml' : 'image/png'),
                            'file_size_kb': sizeKb,
                            'public_url': publicUrl,
                            'category': categoryCtrl.text.trim(),
                            'uploader_role': 'admin',
                            'uploader_name': 'Admin Portal',
                            'created_at': DateTime.now().toIso8601String(),
                            'tags': tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
                          };

                          await SupabaseService.saveAdminMediaAsset(newAsset);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ Asset uploaded and saved to Media Manager!'), backgroundColor: Color(0xFF10B981)),
                            );
                            _loadMediaAssets();
                          }
                        },
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text('Save Asset', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditAssetDialog(Map<String, dynamic> asset) async {
    final titleCtrl = TextEditingController(text: asset['title'] ?? '');
    final categoryCtrl = TextEditingController(text: asset['category'] ?? 'Question Diagrams');
    final tagsCtrl = TextEditingController(
      text: (asset['tags'] as List?)?.join(', ') ?? '',
    );

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Asset Metadata',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const Divider(height: 24),
                Text('Asset Title', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Category', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: categoryCtrl.text,
                  items: const [
                    DropdownMenuItem(value: 'Question Diagrams', child: Text('Question Diagrams')),
                    DropdownMenuItem(value: 'Syllabus & Curriculum', child: Text('Syllabus & Curriculum')),
                    DropdownMenuItem(value: 'Study Notes', child: Text('Study Notes (PDF)')),
                    DropdownMenuItem(value: 'Branding & Logos', child: Text('Branding & Logos')),
                    DropdownMenuItem(value: 'User Avatars', child: Text('User Avatars')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => categoryCtrl.text = val);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Tags (comma separated)', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: tagsCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final updated = Map<String, dynamic>.from(asset);
                        updated['title'] = titleCtrl.text.trim();
                        updated['category'] = categoryCtrl.text.trim();
                        updated['tags'] = tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

                        await SupabaseService.saveAdminMediaAsset(updated);
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadMediaAssets();
                        }
                      },
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAsset(Map<String, dynamic> asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Asset?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete "${asset['title']}"? Any tests or pages referencing this asset will no longer be able to access it.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.deleteAdminMediaAsset(asset['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset deleted successfully.'), backgroundColor: Color(0xFF10B981)),
        );
        _loadMediaAssets();
      }
    }
  }

  void _previewAsset(Map<String, dynamic> asset) {
    final url = (asset['public_url'] ?? '').toString();
    final type = (asset['file_type'] ?? 'image').toString();
    final title = (asset['title'] ?? 'Asset Preview').toString();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                ],
              ),
              const Divider(height: 20),
              Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: type == 'pdf'
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, size: 64, color: Color(0xFFEF4444)),
                            const SizedBox(height: 12),
                            Text(asset['file_name'] ?? 'Document.pdf', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${asset['file_size_kb']} KB • PDF Document', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        )
                      : type == 'svg'
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.polyline_rounded, size: 64, color: Color(0xFF8B5CF6)),
                                const SizedBox(height: 12),
                                Text(asset['file_name'] ?? 'Graphic.svg', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Vector XML / SVG Illustration', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                url,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, size: 48, color: Color(0xFF94A3B8)),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(url, 'Public URL'),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy URL', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  if (url.startsWith('http')) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                      onPressed: () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('Open External', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAssets;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        title: Text(
          'Media & Asset Manager',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _openUploadAssetDialog,
            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
            label: const Text('Upload Asset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Metric Stats Row
                  Row(
                    children: [
                      _buildMetricCard('Total Assets', '${_assets.length}', Icons.folder_copy_outlined, const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
                      const SizedBox(width: 14),
                      _buildMetricCard('Images', '$_imageCount', Icons.image_outlined, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                      const SizedBox(width: 14),
                      _buildMetricCard('PDF Documents', '$_pdfCount', Icons.picture_as_pdf_outlined, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                      const SizedBox(width: 14),
                      _buildMetricCard('Vector SVGs', '$_svgCount', Icons.polyline_outlined, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
                      const SizedBox(width: 14),
                      _buildMetricCard('Storage Used', '${_totalSizeMb.toStringAsFixed(1)} MB', Icons.storage_rounded, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Search & Controls Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Search Box
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: 'Search assets by title, filename, category, or tag...',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Type Filter Pills
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'all', label: Text('All')),
                                ButtonSegment(value: 'image', label: Text('Images')),
                                ButtonSegment(value: 'pdf', label: Text('PDFs')),
                                ButtonSegment(value: 'svg', label: Text('SVGs')),
                              ],
                              selected: {_selectedTypeFilter},
                              onSelectionChanged: (set) => setState(() => _selectedTypeFilter = set.first),
                            ),
                            const SizedBox(width: 14),

                            // Grid vs Table Toggle
                            IconButton(
                              icon: Icon(_isGridView ? Icons.grid_view_rounded : Icons.table_rows_rounded, color: const Color(0xFF4F46E5)),
                              onPressed: () => setState(() => _isGridView = !_isGridView),
                              tooltip: _isGridView ? 'Switch to Table View' : 'Switch to Grid View',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Asset Display Grid / Table
                  if (filtered.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.perm_media_outlined, size: 54, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text('No media assets found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                          const SizedBox(height: 4),
                          const Text('Try adjusting your search query or upload a new asset.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ],
                      ),
                    )
                  else if (_isGridView)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        mainAxisExtent: 310,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) => _buildAssetGridCard(filtered[idx]),
                    )
                  else
                    _buildAssetTableView(filtered),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(count, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetGridCard(Map<String, dynamic> asset) {
    final type = (asset['file_type'] ?? 'image').toString();
    final url = (asset['public_url'] ?? '').toString();
    final title = (asset['title'] ?? 'Asset').toString();
    final fileName = (asset['file_name'] ?? '').toString();
    final sizeKb = (asset['file_size_kb'] as num?)?.toInt() ?? 0;
    final uploader = (asset['uploader_name'] ?? 'Admin').toString();
    final role = (asset['uploader_role'] ?? 'admin').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Thumbnail
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Stack(
              children: [
                Center(
                  child: type == 'pdf'
                      ? const Icon(Icons.picture_as_pdf_rounded, size: 48, color: Color(0xFFEF4444))
                      : type == 'svg'
                          ? const Icon(Icons.polyline_rounded, size: 48, color: Color(0xFF8B5CF6))
                          : ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                              child: Image.network(
                                url,
                                width: double.infinity,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, size: 36, color: Color(0xFF94A3B8)),
                              ),
                            ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: role == 'user' ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$sizeKb KB', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    Text(uploader, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                  ],
                ),
                const Divider(height: 16),

                // Actions: Preview, Copy Link, Edit, Delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF4F46E5)),
                      onPressed: () => _previewAsset(asset),
                      tooltip: 'Preview',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF10B981)),
                      onPressed: () => _copyToClipboard(url, 'URL'),
                      tooltip: 'Copy Public URL',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                      onPressed: () => _openEditAssetDialog(asset),
                      tooltip: 'Edit Metadata',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      onPressed: () => _confirmDeleteAsset(asset),
                      tooltip: 'Delete Asset',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetTableView(List<Map<String, dynamic>> assets) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Title / Name')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Size')),
          DataColumn(label: Text('Uploader')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Actions')),
        ],
        rows: assets.map((a) {
          final type = (a['file_type'] ?? 'image').toString();
          final sizeKb = (a['file_size_kb'] as num?)?.toInt() ?? 0;
          final dateStr = a['created_at'] != null ? DateFormat('dd MMM, yyyy').format(DateTime.parse(a['created_at'])) : '-';

          return DataRow(cells: [
            DataCell(
              Icon(
                type == 'pdf'
                    ? Icons.picture_as_pdf_rounded
                    : type == 'svg'
                        ? Icons.polyline_rounded
                        : Icons.image_rounded,
                color: type == 'pdf'
                    ? const Color(0xFFEF4444)
                    : type == 'svg'
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF10B981),
                size: 20,
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(a['file_name'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            DataCell(Text(a['category'] ?? '-')),
            DataCell(Text('$sizeKb KB')),
            DataCell(Text(a['uploader_name'] ?? 'Admin')),
            DataCell(Text(dateStr)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF4F46E5)),
                    onPressed: () => _previewAsset(a),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF10B981)),
                    onPressed: () => _copyToClipboard(a['public_url'] ?? '', 'URL'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    onPressed: () => _openEditAssetDialog(a),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    onPressed: () => _confirmDeleteAsset(a),
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}
