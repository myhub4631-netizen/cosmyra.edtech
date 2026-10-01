import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/cloudflare_r2_service.dart';
import '../../core/theme/app_design_system.dart';

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
      final rawFn = (item['file_name'] ?? '').toString();
      final fileName = (rawFn.length > 50 ? rawFn.substring(0, 50) : rawFn).toLowerCase();
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

  Widget _buildSafeImageThumbnail(String url, {double? height = 140, BoxFit fit = BoxFit.cover}) {
    if (url.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported_rounded, size: 36, color: Color(0xFF94A3B8)),
      );
    }
    if (url.startsWith('data:image') || (url.startsWith('data:') && url.contains('base64,'))) {
      try {
        final commaIndex = url.indexOf(',');
        if (commaIndex != -1) {
          final b64 = url.substring(commaIndex + 1);
          final bytes = base64Decode(b64);
          return Image.memory(
            bytes,
            width: double.infinity,
            height: height,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded, size: 36, color: Color(0xFF94A3B8)),
            ),
          );
        }
      } catch (e) {
        return const Center(
          child: Icon(Icons.broken_image_rounded, size: 36, color: Color(0xFF94A3B8)),
        );
      }
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: double.infinity,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_not_supported_rounded, size: 36, color: Color(0xFF94A3B8)),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.image_rounded, size: 36, color: Color(0xFF94A3B8)),
    );
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

  String _getShortWebUrl(Map<String, dynamic> asset) {
    final url = (asset['public_url'] ?? '').toString();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final rawName = (asset['file_name'] ?? 'asset.png').toString();
    final cleanName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return 'https://neet-jee.in/assets/uploads/$cleanName';
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
    final urlCtrl = TextEditingController();
    PlatformFile? pickedFile;
    String fileType = 'image';
    bool isUploading = false;
    String uploadStatusMessage = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
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
                        onPressed: isUploading ? null : () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // File Picker Container
                  InkWell(
                    onTap: isUploading
                        ? null
                        : () async {
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
                        color: isUploading ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUploading
                              ? const Color(0xFF6366F1)
                              : (pickedFile == null ? const Color(0xFFCBD5E1) : const Color(0xFF10B981)),
                          width: isUploading ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isUploading
                                ? Icons.cloud_upload
                                : (pickedFile == null ? Icons.cloud_upload_outlined : Icons.check_circle_outline_rounded),
                            size: 38,
                            color: isUploading
                                ? const Color(0xFF6366F1)
                                : (pickedFile == null ? const Color(0xFF6366F1) : const Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pickedFile == null
                                ? 'Click to browse image, PDF, or SVG'
                                : (isUploading ? 'Uploading: ${pickedFile!.name}' : pickedFile!.name),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: pickedFile == null ? const Color(0xFF334155) : const Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
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
                  const SizedBox(height: 14),

                  // Direct Public Web URL Option
                  Text('Or Enter Direct Web / CDN URL (Optional)', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlCtrl,
                    enabled: !isUploading,
                    decoration: InputDecoration(
                      hintText: 'https://neet-jee.in/assets/uploads/diagram.png',
                      prefixIcon: const Icon(Icons.link_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title Input
                  Text('Asset Title / Label', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    enabled: !isUploading,
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
                    onChanged: isUploading
                        ? null
                        : (val) {
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
                    enabled: !isUploading,
                    decoration: InputDecoration(
                      hintText: 'neet, biology, diagram, 2026',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Live Uploading Progress Banner Card
                  if (isUploading) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  uploadStatusMessage,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3730A3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              backgroundColor: Color(0xFFE0E7FF),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isUploading ? null : () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUploading ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isUploading
                            ? null
                            : () async {
                                if (titleCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter asset title'), backgroundColor: Color(0xFFEF4444)),
                                  );
                                  return;
                                }

                                String publicUrl = urlCtrl.text.trim();
                                int sizeKb = 120;

                                setDialogState(() {
                                  isUploading = true;
                                  uploadStatusMessage = pickedFile != null
                                      ? '⏳ Uploading "${pickedFile!.name}" (${(pickedFile!.size / 1024).toStringAsFixed(1)} KB)... Please wait'
                                      : '⏳ Saving asset metadata... Please wait';
                                });

                                try {
                                  if (publicUrl.isEmpty && pickedFile != null) {
                                    sizeKb = (pickedFile!.size / 1024).ceil();
                                    final cleanName = pickedFile!.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
                                    final uploadedUrl = await SupabaseService.uploadMediaFile(
                                      fileBytes: pickedFile!.bytes,
                                      fileName: cleanName,
                                      mimeType: fileType == 'pdf' ? 'application/pdf' : (fileType == 'svg' ? 'image/svg+xml' : 'image/png'),
                                    );
                                    publicUrl = uploadedUrl ?? 'https://neet-jee.in/assets/uploads/$cleanName';
                                  } else if (publicUrl.isEmpty) {
                                    final cleanName = 'asset_${DateTime.now().millisecondsSinceEpoch}.${fileType == 'pdf' ? 'pdf' : (fileType == 'svg' ? 'svg' : 'png')}';
                                    publicUrl = 'https://neet-jee.in/assets/uploads/$cleanName';
                                  }

                                  setDialogState(() {
                                    uploadStatusMessage = '⚡ Registering asset in catalog database...';
                                  });

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
                                      const SnackBar(
                                        content: Text('✓ Asset uploaded and saved to Media Manager!'),
                                        backgroundColor: Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    _loadMediaAssets();
                                  }
                                } catch (e) {
                                  debugPrint('Upload error: $e');
                                  if (mounted) {
                                    setDialogState(() {
                                      isUploading = false;
                                      uploadStatusMessage = '';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Upload failed: $e'), backgroundColor: const Color(0xFFEF4444)),
                                    );
                                  }
                                }
                              },
                        icon: isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(
                          isUploading ? 'Uploading...' : 'Save Asset',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                              child: _buildSafeImageThumbnail(url, fit: BoxFit.contain),
                            ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Web URL: ${_getShortWebUrl(asset)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (url.startsWith('data:'))
                          Text(
                            '[Embedded Base64 Data • ${(url.length / 1024).toStringAsFixed(1)} KB]',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                    onPressed: () => _copyToClipboard(_getShortWebUrl(asset), 'Short Web URL'),
                    icon: const Icon(Icons.link_rounded, size: 14),
                    label: const Text('Copy Short URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  if (url.startsWith('data:')) ...[
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(url, 'Full Base64 Data'),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy Base64', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  if (url.startsWith('http')) ...[
                    const SizedBox(width: 6),
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

  Future<void> _openR2SettingsDialog() async {
    await CloudflareR2Service.loadConfig();
    final accountIdCtrl = TextEditingController(text: CloudflareR2Service.accountId);
    final accessKeyCtrl = TextEditingController(text: CloudflareR2Service.accessKeyId);
    final secretKeyCtrl = TextEditingController(text: CloudflareR2Service.secretAccessKey);
    final bucketCtrl = TextEditingController(text: CloudflareR2Service.bucketName);
    final domainCtrl = TextEditingController(text: CloudflareR2Service.publicDomain);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cloud_sync_rounded, color: Color(0xFFF97316)),
            const SizedBox(width: 8),
            Text('Cloudflare R2 Storage Settings', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure your Cloudflare R2 S3-compatible credentials to upload images and PDFs with short public URLs and \$0 bandwidth cost.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                Text('Cloudflare Account ID', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: accountIdCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. c1a2b3c4d5e6f7...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Text('R2 Access Key ID', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: accessKeyCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. 9f8e7d6c5b4a3...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Text('R2 Secret Access Key', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: secretKeyCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. 1a2b3c4d5e6f7g8...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Text('R2 Bucket Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: bucketCtrl,
                  decoration: InputDecoration(
                    hintText: 'question-bank-assets',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Public Custom Domain / R2 URL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: domainCtrl,
                  decoration: InputDecoration(
                    hintText: 'https://media.neet-jee.in or https://pub-xxx.r2.dev',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
            onPressed: () async {
              await CloudflareR2Service.saveConfig(
                accountIdVal: accountIdCtrl.text,
                accessKeyIdVal: accessKeyCtrl.text,
                secretAccessKeyVal: secretKeyCtrl.text,
                bucketNameVal: bucketCtrl.text,
                publicDomainVal: domainCtrl.text,
              );
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Cloudflare R2 credentials updated successfully!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            icon: const Icon(Icons.save_rounded, size: 16),
            label: const Text('Save R2 Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF97316),
              side: const BorderSide(color: Color(0xFFF97316)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _openR2SettingsDialog,
            icon: const Icon(Icons.cloud_sync_rounded, size: 18),
            label: const Text('R2 Config', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 10),
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
                              child: _buildSafeImageThumbnail(url, height: 140),
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
                  fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName,
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
                      onPressed: () => _copyToClipboard(_getShortWebUrl(asset), 'Short Web URL'),
                      tooltip: 'Copy Short Web URL',
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppShadows.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            headingRowHeight: 46,
            dataRowMaxHeight: 64,
            columns: [
              DataColumn(label: Text('TYPE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF475569), letterSpacing: 0.5))),
              DataColumn(label: Text('TITLE / NAME', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF475569), letterSpacing: 0.5))),
              DataColumn(label: Text('CATEGORY', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF475569), letterSpacing: 0.5))),
              DataColumn(label: Text('SIZE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF475569), letterSpacing: 0.5))),
              DataColumn(label: Text('UPLOADER', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF475569), letterSpacing: 0.5))),
              DataColumn(label: Text('DATE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF475569), letterSpacing: 0.5))),
              DataColumn(label: Text('ACTIONS', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF475569), letterSpacing: 0.5))),
            ],
            rows: assets.map((a) {
              final type = (a['file_type'] ?? 'image').toString();
              final sizeKb = (a['file_size_kb'] as num?)?.toInt() ?? 0;
              final dateStr = a['created_at'] != null ? DateFormat('dd MMM, yyyy').format(DateTime.parse(a['created_at'])) : '-';

              final typeColor = type == 'pdf'
                  ? const Color(0xFFEF4444)
                  : (type == 'svg' ? const Color(0xFF8B5CF6) : const Color(0xFF10B981));

              return DataRow(cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type == 'pdf'
                              ? Icons.picture_as_pdf_rounded
                              : (type == 'svg' ? Icons.polyline_rounded : Icons.image_rounded),
                          color: typeColor,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          type.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(a['title'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      Text(
                        (a['file_name'] ?? '').toString().length > 30
                            ? '${(a['file_name'] ?? '').toString().substring(0, 27)}...'
                            : (a['file_name'] ?? '').toString(),
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      a['category'] ?? '-',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                  ),
                ),
                DataCell(
                  Text('$sizeKb KB', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
                ),
                DataCell(
                  Text(a['uploader_name'] ?? 'Admin', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ),
                DataCell(
                  Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF4F46E5)),
                        onPressed: () => _previewAsset(a),
                        tooltip: 'Preview',
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF10B981)),
                        onPressed: () => _copyToClipboard(_getShortWebUrl(a), 'Short Web URL'),
                        tooltip: 'Copy Short Web URL',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                        onPressed: () => _openEditAssetDialog(a),
                        tooltip: 'Edit Metadata',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        onPressed: () => _confirmDeleteAsset(a),
                        tooltip: 'Delete Asset',
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
