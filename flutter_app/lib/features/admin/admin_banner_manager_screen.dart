import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/dashboard_cms_service.dart';
import '../../core/services/supabase_service.dart';
import '../auth/login_screen.dart';

class AdminBannerManagerScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminBannerManagerScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminBannerManagerScreen> createState() => _AdminBannerManagerScreenState();
}

class _AdminBannerManagerScreenState extends State<AdminBannerManagerScreen> {
  String _activeTab = 'Website Banners'; // 'Website Banners', 'Mobile App Banners', 'All Banners'
  bool _isLoading = true;
  List<DashboardBannerModel> _allBanners = [];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    try {
      final list = await DashboardCmsService.fetchBanners();
      if (mounted) {
        setState(() {
          _allBanners = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminBannerManagerScreen] Error loading banners: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DashboardBannerModel> get _filteredBanners {
    if (_activeTab == 'Website Banners') {
      return _allBanners.where((b) => b.targetPlatform == 'website' || b.targetPlatform == 'all').toList();
    } else if (_activeTab == 'Mobile App Banners') {
      return _allBanners.where((b) => b.targetPlatform == 'app' || b.targetPlatform == 'all').toList();
    }
    return _allBanners;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _openBannerModal({DashboardBannerModel? banner, String defaultPlatform = 'all'}) {
    final titleCtrl = TextEditingController(text: banner?.title ?? '');
    final subCtrl = TextEditingController(text: banner?.subtitle ?? '');
    final imgCtrl = TextEditingController(text: banner?.imageUrl ?? '');
    final ctaCtrl = TextEditingController(text: banner?.ctaText ?? 'Subscribe Now');
    final destCtrl = TextEditingController(text: banner?.ctaDestination ?? '/practice');
    final bgCtrl = TextEditingController(text: banner?.bgColor ?? '#5B21B6');
    final btnCtrl = TextEditingController(text: banner?.btnColor ?? '#FACC15');
    String audience = banner?.targetAudience ?? 'All Students';
    String platform = banner?.targetPlatform ?? defaultPlatform;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(banner == null ? 'Add New Banner' : 'Edit Banner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Banner Title *')),
                TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Subtitle')),
                TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Image URL (Direct image link / Supabase Storage)')),
                TextField(controller: ctaCtrl, decoration: const InputDecoration(labelText: 'CTA Button Text')),
                TextField(controller: destCtrl, decoration: const InputDecoration(labelText: 'CTA Destination Route')),
                TextField(controller: bgCtrl, decoration: const InputDecoration(labelText: 'Background Color (e.g. #5B21B6)')),
                TextField(controller: btnCtrl, decoration: const InputDecoration(labelText: 'Button Color (e.g. #FACC15)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: platform,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('🌐 & 📱 Both Website & Mobile App')),
                    DropdownMenuItem(value: 'website', child: Text('🌐 User Website Only')),
                    DropdownMenuItem(value: 'app', child: Text('📱 User Mobile App Only')),
                  ],
                  onChanged: (val) => platform = val ?? 'all',
                  decoration: const InputDecoration(labelText: 'Target Platform *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: audience,
                  items: ['All Students', 'NEET', 'JEE Main', 'JEE Advanced', 'New Users', 'Premium Users']
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (val) => audience = val ?? 'All Students',
                  decoration: const InputDecoration(labelText: 'Target Audience'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (titleCtrl.text.trim().isEmpty) {
                  _showMessage('Please enter a banner title.');
                  return;
                }
                setModalState(() => isSaving = true);
                try {
                  final newB = DashboardBannerModel(
                    id: banner?.id ?? '',
                    title: titleCtrl.text.trim(),
                    subtitle: subCtrl.text.trim(),
                    ctaText: ctaCtrl.text.trim(),
                    ctaDestination: destCtrl.text.trim(),
                    imageUrl: imgCtrl.text.trim().isNotEmpty ? imgCtrl.text.trim() : null,
                    bgColor: bgCtrl.text.trim().isNotEmpty ? bgCtrl.text.trim() : '#5B21B6',
                    btnColor: btnCtrl.text.trim().isNotEmpty ? btnCtrl.text.trim() : '#FACC15',
                    isActive: true,
                    sortOrder: banner?.sortOrder ?? (_allBanners.length + 1),
                    targetAudience: audience,
                    targetPlatform: platform,
                  );
                  await DashboardCmsService.saveBanner(newB);
                  if (mounted) {
                    Navigator.pop(ctx);
                    _showMessage('Banner saved successfully!');
                    await _loadBanners();
                  }
                } catch (e) {
                  debugPrint('[ADMIN CMS] Error saving banner: $e');
                  setModalState(() => isSaving = false);
                  _showMessage('Error saving banner: $e');
                }
              },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Banner'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBanner(DashboardBannerModel b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner'),
        content: Text('Are you sure you want to delete "${b.title}"? This will permanently remove it from Supabase.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              await DashboardCmsService.deleteBanner(b.id);
              _showMessage('Banner deleted successfully.');
              _loadBanners();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Banner Management System', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openBannerModal(
                defaultPlatform: _activeTab == 'Website Banners' ? 'website' : (_activeTab == 'Mobile App Banners' ? 'app' : 'all'),
              ),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Add Banner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Tab Selector
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      _buildTabButton('Website Banners', '🌐 User Website Banners'),
                      const SizedBox(width: 12),
                      _buildTabButton('Mobile App Banners', '📱 User Mobile App Banners'),
                      const SizedBox(width: 12),
                      _buildTabButton('All Banners', '⚡ All Banners'),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_filteredBanners.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(48),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.view_carousel_outlined, size: 56, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 16),
                                Text('No Banners Found for $_activeTab', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                const SizedBox(height: 6),
                                const Text('Create active banners targeted for website or mobile app to display on user homepages.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => _openBannerModal(
                                    defaultPlatform: _activeTab == 'Website Banners' ? 'website' : (_activeTab == 'Mobile App Banners' ? 'app' : 'all'),
                                  ),
                                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                                  label: const Text('Add Banner Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          // Data Table Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Column(
                              children: [
                                // Table Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                                  ),
                                  child: const Row(
                                    children: [
                                      SizedBox(width: 40, child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Expanded(flex: 3, child: Text('Banner Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Expanded(flex: 2, child: Text('Platform Target', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Expanded(flex: 2, child: Text('Target Audience', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Expanded(flex: 2, child: Text('CTA Button', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      SizedBox(width: 90, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                ..._filteredBanners.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final b = entry.value;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 40, child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(b.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                              if (b.subtitle.isNotEmpty)
                                                Text(b.subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: b.targetPlatform == 'website'
                                                  ? const Color(0xFFEFF6FF)
                                                  : (b.targetPlatform == 'app' ? const Color(0xFFF0FDF4) : const Color(0xFFF5F3FF)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              b.targetPlatform == 'website' ? '🌐 Website Only' : (b.targetPlatform == 'app' ? '📱 Mobile App Only' : '🌐 & 📱 Both'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: b.targetPlatform == 'website'
                                                    ? const Color(0xFF2563EB)
                                                    : (b.targetPlatform == 'app' ? const Color(0xFF16A34A) : const Color(0xFF7C3AED)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(b.targetAudience, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('${b.ctaText} → ${b.ctaDestination}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                        ),
                                        SizedBox(
                                          width: 90,
                                          child: Switch(
                                            value: b.isActive,
                                            activeColor: const Color(0xFF10B981),
                                            onChanged: (val) async {
                                              final updated = b.copyWith(isActive: val);
                                              await DashboardCmsService.saveBanner(updated);
                                              _showMessage('Banner status updated!');
                                              await _loadBanners();
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18, color: Color(0xFF3B82F6)),
                                                tooltip: 'Edit Banner',
                                                onPressed: () => _openBannerModal(banner: b),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                                                tooltip: 'Delete Banner',
                                                onPressed: () => _confirmDeleteBanner(b),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabButton(String tabKey, String label) {
    final isSelected = _activeTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
