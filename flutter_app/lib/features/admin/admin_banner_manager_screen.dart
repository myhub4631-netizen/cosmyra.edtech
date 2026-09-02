import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';

ImageProvider? _getBannerImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('data:image')) {
    try {
      final comma = url.indexOf(',');
      if (comma != -1) {
        final b64 = url.substring(comma + 1);
        return MemoryImage(base64Decode(b64));
      }
    } catch (_) {}
  } else if (url.startsWith('http')) {
    return NetworkImage(url);
  }
  return null;
}

class AdminBannerManagerScreen extends StatefulWidget {
  final UserProfileModel? userProfile;

  const AdminBannerManagerScreen({super.key, this.userProfile});

  @override
  State<AdminBannerManagerScreen> createState() => _AdminBannerManagerScreenState();
}

class _AdminBannerManagerScreenState extends State<AdminBannerManagerScreen> {
  List<DashboardBannerModel> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _loading = true);
    try {
      final list = await SupabaseService.fetchBanners();
      setState(() {
        _banners = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showMessage('Failed to load banners: $e', isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleActive(DashboardBannerModel banner) async {
    final updated = banner.copyWith(isActive: !banner.isActive);
    final saved = await SupabaseService.saveBanner(updated);
    if (saved != null) {
      setState(() {
        final idx = _banners.indexWhere((b) => b.id == banner.id);
        if (idx >= 0) _banners[idx] = saved;
      });
      _showMessage(saved.isActive ? 'Banner activated' : 'Banner deactivated');
    } else {
      _showMessage('Failed to update banner status', isError: true);
    }
  }

  Future<void> _deleteBanner(DashboardBannerModel banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Banner?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete "${banner.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await SupabaseService.deleteBanner(banner.id);
      if (ok) {
        setState(() {
          _banners.removeWhere((b) => b.id == banner.id);
        });
        _showMessage('Banner deleted successfully');
      } else {
        _showMessage('Failed to delete banner', isError: true);
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _banners.removeAt(oldIndex);
      _banners.insert(newIndex, item);
    });
    await SupabaseService.reorderBanners(_banners);
    _showMessage('Banner order updated');
  }

  bool _isOpeningDialog = false;

  Future<void> _openBannerDialog({DashboardBannerModel? banner}) async {
    if (_isOpeningDialog) return;
    _isOpeningDialog = true;
    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => _BannerEditorDialog(
          banner: banner,
          onSaved: (saved) {
            setState(() {
              final idx = _banners.indexWhere((b) => b.id == saved.id);
              if (idx >= 0) {
                _banners[idx] = saved;
              } else {
                _banners.insert(0, saved);
              }
            });
            _showMessage(banner == null ? 'Banner created successfully!' : 'Banner updated successfully!');
          },
        ),
      );
    } finally {
      _isOpeningDialog = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Promotional Banners Manager',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openBannerDialog(),
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: Text('Create Banner', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBanners,
              child: _banners.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.view_carousel_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No Banners Configured',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                          const SizedBox(height: 8),
                          Text('Create a promotional banner to display on user app & website dashboard.',
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _openBannerDialog(),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Create First Banner', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF4F46E5), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Active banners automatically appear at the top of the Student Dashboard. Drag items using the handle to reorder the slides.',
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF3730A3)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _banners.length,
                          onReorder: _onReorder,
                          itemBuilder: (context, index) {
                            final banner = _banners[index];
                            return _buildBannerCard(banner, index);
                          },
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildBannerCard(DashboardBannerModel banner, int index) {
    final hasImage = banner.imageUrl != null && banner.imageUrl!.isNotEmpty;
    final isScheduled = banner.isScheduledActive;

    return Container(
      key: ValueKey(banner.id),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              color: _parseColor(banner.bgColor, const Color(0xFF5B21B6)),
              image: _getBannerImageProvider(banner.imageUrl) != null
                  ? DecorationImage(
                      image: _getBannerImageProvider(banner.imageUrl)!,
                      fit: BoxFit.cover,
                      colorFilter: banner.overlayOpacity > 0
                          ? ColorFilter.mode(Colors.black.withValues(alpha: banner.overlayOpacity), BlendMode.darken)
                          : null,
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Stack(
              children: [
                if (banner.showTextOverlay && (banner.title.isNotEmpty || banner.subtitle.isNotEmpty))
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (banner.targetAudience.isNotEmpty && banner.targetAudience != 'None')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  banner.targetAudience,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              banner.title,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                shadows: [const Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4)],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (banner.subtitle.isNotEmpty)
                              Text(
                                banner.subtitle,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 11,
                                  shadows: [const Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4)],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (banner.showButton && banner.ctaText.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _parseColor(banner.btnColor, const Color(0xFFFACC15)),
                        disabledBackgroundColor: _parseColor(banner.btnColor, const Color(0xFFFACC15)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        banner.ctaText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _parseColor(banner.btnTextColor, const Color(0xFF1E1B4B)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.drag_indicator, color: Color(0xFF94A3B8)),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleActive(banner),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: banner.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: banner.isActive ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          banner.isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                          size: 14,
                          color: banner.isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          banner.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: banner.isActive ? const Color(0xFF15803D) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (banner.startAt != null || banner.endAt != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: isScheduled ? Colors.green : Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          isScheduled ? 'Live Now' : 'Scheduled',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Text(
                    'Link: ${banner.ctaDestination}',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Tooltip(
                  message: 'Edit Banner',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _openBannerDialog(banner: banner),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: Color(0xFF4F46E5)),
                            SizedBox(width: 4),
                            Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Delete Banner',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _deleteBanner(banner),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) {
        buffer.write('ff');
        buffer.write(hex.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      }
    } catch (_) {}
    return fallback;
  }
}

class _BannerEditorDialog extends StatefulWidget {
  final DashboardBannerModel? banner;
  final ValueChanged<DashboardBannerModel> onSaved;

  const _BannerEditorDialog({this.banner, required this.onSaved});

  @override
  State<_BannerEditorDialog> createState() => _BannerEditorDialogState();
}

class _BannerEditorDialogState extends State<_BannerEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _ctaTextCtrl;
  late TextEditingController _ctaDestCtrl;
  late TextEditingController _targetAudienceCtrl;

  String _bgColor = '#5B21B6';
  String _btnColor = '#FACC15';
  String _btnTextColor = '#1E1B4B';
  bool _isActive = true;
  String? _imageUrl;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _saving = false;

  bool _showTextOverlay = true;
  bool _showButton = true;
  double _overlayOpacity = 0.0;

  final List<String> _commonDestinations = [
    '/practice',
    '/custom-practice',
    '/mock-tests',
    '/test-series',
    '/leaderboard',
    '/profile',
    '/mistakes',
    '/bookmarks',
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _subtitleCtrl = TextEditingController(text: b?.subtitle ?? '');
    _ctaTextCtrl = TextEditingController(text: b?.ctaText ?? 'Explore Now');
    _ctaDestCtrl = TextEditingController(text: b?.ctaDestination ?? '/practice');
    _targetAudienceCtrl = TextEditingController(text: b?.targetAudience ?? 'All Students');
    if (b != null) {
      _bgColor = b.bgColor;
      _btnColor = b.btnColor;
      _btnTextColor = b.btnTextColor;
      _isActive = b.isActive;
      _imageUrl = b.imageUrl;
      _startAt = b.startAt;
      _endAt = b.endAt;
      _showTextOverlay = b.showTextOverlay;
      _showButton = b.showButton;
      _overlayOpacity = b.overlayOpacity;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _ctaTextCtrl.dispose();
    _ctaDestCtrl.dispose();
    _targetAudienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (res != null && res.files.isNotEmpty && res.files.first.bytes != null) {
        final file = res.files.first;
        setState(() => _saving = true);
        final url = await SupabaseService.uploadBannerImage(file.bytes!, file.name);
        setState(() {
          _imageUrl = url;
          // When uploading graphic banner, default overlay opacity to 0 so graphic remains crisp
          _overlayOpacity = 0.0;
          _saving = false;
        });
      }
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final banner = DashboardBannerModel(
      id: widget.banner?.id ?? '',
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim(),
      ctaText: _ctaTextCtrl.text.trim(),
      ctaDestination: _ctaDestCtrl.text.trim(),
      imageUrl: _imageUrl,
      bgColor: _bgColor,
      btnColor: _btnColor,
      btnTextColor: _btnTextColor,
      isActive: _isActive,
      sortOrder: widget.banner?.sortOrder ?? 0,
      startAt: _startAt,
      endAt: _endAt,
      targetAudience: _targetAudienceCtrl.text.trim(),
      showTextOverlay: _showTextOverlay,
      showButton: _showButton,
      overlayOpacity: _overlayOpacity,
    );

    final saved = await SupabaseService.saveBanner(banner);
    setState(() => _saving = false);

    if (saved != null) {
      widget.onSaved(saved);
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save banner. Please check connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.banner == null ? 'Create Promotional Banner' : 'Edit Banner',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Banner Title (Optional if Image Provided)',
                          hintText: 'e.g., NEET 2026 Full Length Test Series',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _subtitleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Subtitle / Description (Optional)',
                          hintText: 'e.g., Simulate real exam conditions with 720-marks tests',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),

                      // OVERLAY & BUTTON DISPLAY TOGGLES
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visual Customization & Overlays',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Show Text Overlay on Banner', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Turn OFF if your banner image already contains text graphics', style: TextStyle(fontSize: 11)),
                              value: _showTextOverlay,
                              activeColor: const Color(0xFF4F46E5),
                              onChanged: (v) => setState(() => _showTextOverlay = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Show Action Button on Banner', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Turn OFF to make the entire banner clickable without displaying a button', style: TextStyle(fontSize: 11)),
                              value: _showButton,
                              activeColor: const Color(0xFF4F46E5),
                              onChanged: (v) => setState(() => _showButton = v),
                            ),
                            if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Image Darkening Layer: ${(_overlayOpacity * 100).toInt()}%',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (_overlayOpacity > 0)
                                    TextButton(
                                      onPressed: () => setState(() => _overlayOpacity = 0.0),
                                      child: const Text('Set to 0% (Crisp)', style: TextStyle(fontSize: 11)),
                                    ),
                                ],
                              ),
                              Slider(
                                value: _overlayOpacity,
                                min: 0.0,
                                max: 0.8,
                                divisions: 16,
                                label: '${(_overlayOpacity * 100).toInt()}%',
                                activeColor: const Color(0xFF4F46E5),
                                onChanged: (v) => setState(() => _overlayOpacity = v),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ctaTextCtrl,
                              decoration: InputDecoration(
                                labelText: 'CTA Button Text',
                                hintText: 'e.g., Explore Now',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _ctaDestCtrl,
                              decoration: InputDecoration(
                                labelText: 'Clickable Link / Destination *',
                                hintText: 'e.g., /mock-tests',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Destination is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: _commonDestinations.map((dest) {
                          return ActionChip(
                            label: Text(dest, style: const TextStyle(fontSize: 11)),
                            onPressed: () => setState(() => _ctaDestCtrl.text = dest),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Text('Banner Image (Optional)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            if (_getBannerImageProvider(_imageUrl) != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image(
                                  image: _getBannerImageProvider(_imageUrl)!,
                                  width: 80,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 50,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            ElevatedButton.icon(
                              onPressed: _saving ? null : _pickImage,
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: Text(_imageUrl == null ? 'Upload Banner Image' : 'Change Image'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            if (_imageUrl != null) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => setState(() => _imageUrl = null),
                                child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _targetAudienceCtrl,
                              decoration: InputDecoration(
                                labelText: 'Target Audience Badge',
                                hintText: 'e.g., NEET 2026, JEE MAIN, All Students',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Text('Active Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                              Switch(
                                value: _isActive,
                                activeColor: const Color(0xFF10B981),
                                onChanged: (v) => setState(() => _isActive = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Schedule Visibility (Optional)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _startAt ?? DateTime.now(),
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) setState(() => _startAt = d);
                              },
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(_startAt == null ? 'Start Date' : DateFormat('dd MMM yyyy').format(_startAt!)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _endAt ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) setState(() => _endAt = d);
                              },
                              icon: const Icon(Icons.event_busy, size: 16),
                              label: Text(_endAt == null ? 'End Date' : DateFormat('dd MMM yyyy').format(_endAt!)),
                            ),
                          ),
                          if (_startAt != null || _endAt != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() {
                                _startAt = null;
                                _endAt = null;
                              }),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(widget.banner == null ? 'Create Banner' : 'Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
