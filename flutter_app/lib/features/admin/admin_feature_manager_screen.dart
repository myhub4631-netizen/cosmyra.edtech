import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/feature_config_service.dart';

class AdminFeatureManagerScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminFeatureManagerScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<AdminFeatureManagerScreen> createState() => _AdminFeatureManagerScreenState();
}

class _AdminFeatureManagerScreenState extends State<AdminFeatureManagerScreen>
    with SingleTickerProviderStateMixin {
  late List<FeatureModel> _features;
  late List<Map<String, dynamic>> _auditLogs;
  bool _isLoading = true;
  bool _isSaving = false;
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeatureData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatureData() async {
    setState(() => _isLoading = true);
    await FeatureConfigService.init(forceRefresh: true);
    if (mounted) {
      setState(() {
        _features = FeatureConfigService.getAllFeatures();
        _auditLogs = FeatureConfigService.getAuditLogs();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAllChanges() async {
    setState(() => _isSaving = true);
    final success = await FeatureConfigService.saveFeatures(
      _features,
      adminEmail: 'Admin',
    );
    if (mounted) {
      setState(() {
        _isSaving = false;
        _auditLogs = FeatureConfigService.getAuditLogs();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Feature Manager settings saved successfully across all platforms!'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updateFeature(int index, FeatureModel updated) {
    setState(() {
      _features[index] = updated;
    });
  }

  void _bulkSetStatus(String status) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Bulk Action', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to set status to ${status.toUpperCase()} for all features?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _features = _features.map((f) => f.copyWith(status: status, visibility: 'visible')).toList();
              });
            },
            child: const Text('Apply To All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _bulkSetVisibility(String visibility) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Bulk Action', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to set visibility to ${visibility.toUpperCase()} for all features?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _features = _features.map((f) => f.copyWith(visibility: visibility)).toList();
              });
            },
            child: const Text('Apply To All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddNewFeatureModal() {
    final keyCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final routeCtrl = TextEditingController(text: '/');
    String vis = 'visible';
    String st = 'coming_soon';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.add_box_rounded, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text('Add New Feature', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Feature Key (unique identifier)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: keyCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. ai_tutor',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Feature Display Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. AI Tutor',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Short Description', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Brief description of feature capability...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Target Route', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: routeCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. /ai-tutor',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Visibility', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                            DropdownButtonFormField<String>(
                              value: vis,
                              items: const [
                                DropdownMenuItem(value: 'visible', child: Text('Visible')),
                                DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
                              ],
                              onChanged: (v) => setModalState(() => vis = v ?? 'visible'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Initial Status', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                            DropdownButtonFormField<String>(
                              value: st,
                              items: const [
                                DropdownMenuItem(value: 'active', child: Text('Active')),
                                DropdownMenuItem(value: 'coming_soon', child: Text('Coming Soon')),
                                DropdownMenuItem(value: 'premium', child: Text('Premium')),
                              ],
                              onChanged: (s) => setModalState(() => st = s ?? 'coming_soon'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () {
                final k = keyCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
                final n = nameCtrl.text.trim();
                if (k.isEmpty || n.isEmpty) return;

                final newFeature = FeatureModel(
                  key: k,
                  name: n,
                  description: descCtrl.text.trim(),
                  visibility: vis,
                  status: st,
                  iconName: 'star',
                  sortOrder: _features.length + 1,
                  ctaText: n,
                  comingSoonMessage: '$n is currently under development. Stay tuned!',
                  targetRoute: routeCtrl.text.trim(),
                );

                setState(() {
                  _features.add(newFeature);
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add Feature', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMetadataModal(int index) {
    final feature = _features[index];
    final nameCtrl = TextEditingController(text: feature.name);
    final descCtrl = TextEditingController(text: feature.description);
    final msgCtrl = TextEditingController(text: feature.comingSoonMessage);
    final ctaCtrl = TextEditingController(text: feature.ctaText);
    final routeCtrl = TextEditingController(text: feature.targetRoute);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Feature Metadata', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 12),
                Text('Description', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 12),
                Text('Coming Soon Message', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: msgCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 12),
                Text('CTA Button Text', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: ctaCtrl,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 12),
                Text('Target Route', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: routeCtrl,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              _updateFeature(
                index,
                feature.copyWith(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  comingSoonMessage: msgCtrl.text.trim(),
                  ctaText: ctaCtrl.text.trim(),
                  targetRoute: routeCtrl.text.trim(),
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save Metadata', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _previewFeature(FeatureModel feature) {
    if (feature.isHidden) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.visibility_off, color: Colors.grey),
              SizedBox(width: 8),
              Text('Feature Hidden Preview'),
            ],
          ),
          content: Text(
            'The feature "${feature.name}" is currently set to HIDDEN.\nIt will not appear anywhere on User Website, Web App, or Mobile App.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } else if (feature.isComingSoon) {
      FeatureConfigService.showComingSoonDialog(
        context,
        title: feature.name,
        message: feature.comingSoonMessage,
        ctaText: feature.ctaText,
      );
    } else if (feature.isPremium) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.workspace_premium, color: Color(0xFF9333EA)),
              SizedBox(width: 8),
              Text('Premium Flow Preview'),
            ],
          ),
          content: Text(
            'Feature "${feature.name}" is marked as PREMIUM.\nUser tap triggers the subscription / purchase checkout flow.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text('Active Feature Preview'),
            ],
          ),
          content: Text(
            'Feature "${feature.name}" is ACTIVE.\nUser tap opens full functionality at route: ${feature.targetRoute}',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredFeatures = _features.where((f) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return f.name.toLowerCase().contains(q) || f.key.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: widget.onBack,
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Manager',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Control which user-facing features are active, coming soon, premium or hidden',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAllChanges,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save All Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(text: 'Feature Controls'),
            Tab(text: 'Audit Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeatureControlTab(filteredFeatures),
          _buildAuditLogsTab(),
        ],
      ),
    );
  }

  Widget _buildFeatureControlTab(List<FeatureModel> features) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bulk Controls & Search Bar Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search features...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _bulkSetStatus('active'),
                      icon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
                      label: const Text('Set All Active'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _bulkSetStatus('coming_soon'),
                      icon: const Icon(Icons.schedule, size: 16, color: Color(0xFFD97706)),
                      label: const Text('Set Dev Features Coming Soon'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _bulkSetVisibility('hidden'),
                      icon: const Icon(Icons.visibility_off_outlined, size: 16, color: Color(0xFFDC2626)),
                      label: const Text('Hide All'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddNewFeatureModal,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Feature'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Feature Grid / List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final feature = features[index];
              final realIndex = _features.indexWhere((f) => f.key == feature.key);

              return _buildFeatureCard(feature, realIndex);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(FeatureModel feature, int index) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (feature.isHidden) {
      badgeBg = const Color(0xFFF1F5F9);
      badgeText = const Color(0xFF64748B);
      badgeLabel = 'HIDDEN';
    } else if (feature.isComingSoon) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFB45309);
      badgeLabel = 'COMING SOON';
    } else if (feature.isPremium) {
      badgeBg = const Color(0xFFF3E8FF);
      badgeText = const Color(0xFF6B21A8);
      badgeLabel = 'PREMIUM';
    } else {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
      badgeLabel = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: feature.isHidden ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
          width: feature.isHidden ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(feature.iconName),
                  color: badgeText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          feature.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            feature.key,
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: badgeText,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      feature.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, thickness: 1, color: Color(0xFFF1F5F9)),

          // Controls Row: Visibility & Status
          Wrap(
            spacing: 24,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Visibility Toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VISIBILITY',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: const Text('Visible'),
                        selected: feature.visibility == 'visible',
                        onSelected: (sel) {
                          if (sel) {
                            _updateFeature(index, feature.copyWith(visibility: 'visible'));
                          }
                        },
                        selectedColor: const Color(0xFFDBEAFE),
                        labelStyle: TextStyle(
                          color: feature.visibility == 'visible' ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Hidden'),
                        selected: feature.visibility == 'hidden',
                        onSelected: (sel) {
                          if (sel) {
                            _updateFeature(index, feature.copyWith(visibility: 'hidden'));
                          }
                        },
                        selectedColor: const Color(0xFFFEE2E2),
                        labelStyle: TextStyle(
                          color: feature.visibility == 'hidden' ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Status Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABILITY STATUS',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: const Text('Active'),
                        selected: feature.status == 'active',
                        onSelected: (sel) {
                          if (sel) {
                            _updateFeature(index, feature.copyWith(status: 'active'));
                          }
                        },
                        selectedColor: const Color(0xFFDCFCE7),
                        labelStyle: TextStyle(
                          color: feature.status == 'active' ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Coming Soon'),
                        selected: feature.status == 'coming_soon',
                        onSelected: (sel) {
                          if (sel) {
                            _updateFeature(index, feature.copyWith(status: 'coming_soon'));
                          }
                        },
                        selectedColor: const Color(0xFFFEF3C7),
                        labelStyle: TextStyle(
                          color: feature.status == 'coming_soon' ? const Color(0xFFB45309) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Premium'),
                        selected: feature.status == 'premium',
                        onSelected: (sel) {
                          if (sel) {
                            _updateFeature(index, feature.copyWith(status: 'premium'));
                          }
                        },
                        selectedColor: const Color(0xFFF3E8FF),
                        labelStyle: TextStyle(
                          color: feature.status == 'premium' ? const Color(0xFF6B21A8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Edit & Preview Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showEditMetadataModal(index),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Edit Metadata'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _previewFeature(feature),
                    icon: const Icon(Icons.play_circle_fill, size: 16),
                    label: const Text('Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    if (_auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No Feature Manager audit logs yet',
              style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _auditLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.change_circle_outlined, color: Color(0xFF2563EB), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log['feature']} (${log['feature_key']})',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${log['old_status']} → ${log['new_status']} | Visibility: ${log['old_visibility']} → ${log['new_visibility']}',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    log['changed_by'] ?? 'Admin',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log['changed_at'] ?? '',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'quiz':
        return Icons.quiz_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'analytics':
        return Icons.analytics_rounded;
      case 'tune':
        return Icons.tune_rounded;
      case 'timer':
        return Icons.timer_rounded;
      case 'history_edu':
        return Icons.history_edu_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
