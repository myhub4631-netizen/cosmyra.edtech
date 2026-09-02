import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/dashboard_cms_service.dart';
import '../auth/login_screen.dart';
import 'admin_banner_manager_screen.dart';

class AdminDashboardSectionsScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminDashboardSectionsScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminDashboardSectionsScreen> createState() => _AdminDashboardSectionsScreenState();
}

class _AdminDashboardSectionsScreenState extends State<AdminDashboardSectionsScreen> {
  String _activeTab = 'Dashboard Sections';
  String _activeSidebar = 'Dashboard Sections';
  bool _isLoading = true;
  bool _isPreviewMobile = false;

  // Supabase CMS Data Arrays
  List<DashboardSectionModel> _sections = [];
  List<DashboardBannerModel> _banners = [];
  List<DashboardQuickStatModel> _quickStats = [];
  List<DashboardQuickActionModel> _quickActions = [];
  List<AuditLogModel> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _loadCmsData();
  }

  Future<void> _loadCmsData() async {
    setState(() => _isLoading = true);
    try {
      final secs = await DashboardCmsService.fetchSections();
      final bans = await DashboardCmsService.fetchBanners();
      final stats = await DashboardCmsService.fetchQuickStats();
      final acts = await DashboardCmsService.fetchQuickActions();
      final logs = await DashboardCmsService.fetchAuditLogs();

      if (mounted) {
        setState(() {
          _sections = secs;
          _banners = bans;
          _quickStats = stats;
          _quickActions = acts;
          _auditLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading CMS data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await SupabaseService.logoutUserSession();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully.'),
          backgroundColor: Color(0xFF64748B),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _setSectionVisibility(String sectionKey, bool isVisible) async {
    final success = await DashboardCmsService.updateSectionVisibility(sectionKey, isVisible);
    if (success) {
      setState(() {
        final idx = _sections.indexWhere((s) => s.sectionKey == sectionKey);
        if (idx != -1) {
          _sections[idx] = _sections[idx].copyWith(isVisible: isVisible);
        }
      });
      _showMessage('Section visibility updated.');
    }
  }

  Future<void> _setSectionEnabled(String sectionKey, bool isEnabled) async {
    final success = await DashboardCmsService.updateSectionEnabled(sectionKey, isEnabled);
    if (success) {
      setState(() {
        final idx = _sections.indexWhere((s) => s.sectionKey == sectionKey);
        if (idx != -1) {
          _sections[idx] = _sections[idx].copyWith(isEnabled: isEnabled);
        }
      });
      _showMessage('Section status updated.');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ========================================================
  // BUILD METHOD
  // ========================================================
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 992;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar Nav
          if (isDesktop) _buildSidebar(context),

          // Main Screen Area
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(context, isDesktop),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSubHeaderTabs(),
                              const SizedBox(height: 24),

                              if (_activeTab == 'Banners' || _activeSidebar == 'Banners')
                                SizedBox(
                                  height: 850,
                                  child: AdminBannerManagerScreen(userProfile: widget.userProfile),
                                )
                              else if (_activeTab == 'Dashboard Sections')
                                _buildDashboardSectionsTab(isDesktop)
                              else if (_activeTab == 'Layout & Visibility')
                                _buildLayoutVisibilityTab()
                              else if (_activeTab == 'Settings')
                                _buildSettingsTab()
                              else if (_activeTab == 'Preview Dashboard')
                                _buildPreviewDashboardTab()
                              else if (_activeTab == 'Audit Logs')
                                _buildAuditLogsTab(),
                            ],
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

  // ========================================================
  // TOP APP BAR
  // ========================================================
  Widget _buildTopAppBar(BuildContext context, bool isDesktop) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          // Search Bar
          Expanded(
            child: Container(
              height: 42,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search for students, questions, test...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Moon / Theme icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_round, size: 18, color: Color(0xFF64748B)),
          ),

          const SizedBox(width: 12),

          // Notification Badge
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 18, color: Color(0xFF64748B)),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Admin User Profile Avatar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF4F46E5),
                  child: Text(
                    widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName : 'Dr. Sharma (Admin)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 4),
                const Text('Admin', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Logout Button
          OutlinedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 14, color: Color(0xFFEF4444)),
            label: const Text('Logout', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFECDD3)),
              backgroundColor: const Color(0xFFFFF1F2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveChangesAll() async {
    _showMessage('Saving all layout changes to Supabase...');
    final successSec = await DashboardCmsService.updateSectionOrders(_sections);
    final successBan = await DashboardCmsService.updateBannerOrders(_banners);
    if (successSec || successBan) {
      _showMessage('All dashboard changes saved successfully!');
      await _loadCmsData();
    } else {
      _showMessage('Error saving layout changes to Supabase.');
    }
  }

  // ========================================================
  // SUB HEADER TABS
  // ========================================================
  Widget _buildSubHeaderTabs() {
    final tabs = ['Banners', 'Dashboard Sections', 'Layout & Visibility', 'Settings', 'Preview Dashboard', 'Audit Logs'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: tabs.map((tab) {
              final isSelected = _activeTab == tab;
              return InkWell(
                onTap: () => setState(() => _activeTab = tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ElevatedButton.icon(
              onPressed: _handleSaveChangesAll,
              icon: const Icon(Icons.save, size: 16, color: Colors.white),
              label: const Text('Save Changes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAB 1: DASHBOARD SECTIONS (MAIN CMS VIEW)
  // ========================================================
  Widget _buildDashboardSectionsTab(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Configurable Sections
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildBannerSliderCard(),
              const SizedBox(height: 24),
              _buildQuickStatsCard(),
              const SizedBox(height: 24),
              _buildQuickActionsCard(),
            ],
          ),
        ),

        if (isDesktop) const SizedBox(width: 24),

        // Right Column: Section Visibility & Tips
        if (isDesktop)
          SizedBox(
            width: 320,
            child: Column(
              children: [
                _buildSectionVisibilityCard(),
                const SizedBox(height: 16),
                _buildTipsCard(),
                const SizedBox(height: 16),
                _buildNeedHelpCard(),
              ],
            ),
          ),
      ],
    );
  }

  // BANNER SLIDER CARD
  Widget _buildBannerSliderCard() {
    final isEnabled = _sections.firstWhere((s) => s.sectionKey == 'banner_slider', orElse: () => DashboardSectionModel(id: '', sectionKey: 'banner_slider', title: 'Banner Slider', subtitle: '', sortOrder: 1, isEnabled: true, isVisible: true)).isEnabled;

    return _buildContainerCard(
      title: 'Banner Slider Management',
      subtitle: 'Create, edit, delete, toggle status and reorder banners live in Supabase',
      number: '1',
      isEnabled: isEnabled,
      onToggleEnable: (val) => _setSectionEnabled('banner_slider', val),
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openBannerModal(),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Add Banner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _openManageBannerOrderModal(),
          icon: const Icon(Icons.swap_vert, size: 16, color: Color(0xFF475569)),
          label: const Text('Manage Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_banners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.view_carousel_outlined, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text('No Promotional Banners Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  const Text('Create custom promotional banners to highlight courses, mock tests, or announcements.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openBannerModal(),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Create First Banner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Banner Preview Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _banners.map((b) => _buildBannerCardItem(b)).toList(),
              ),
            ),
            const SizedBox(height: 24),
            // Manage Banners Data Table
            const Text('All Active Banners', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 40, child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        Expanded(flex: 3, child: Text('Banner Title & Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        Expanded(flex: 2, child: Text('Audience', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        Expanded(flex: 2, child: Text('CTA Button', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        SizedBox(width: 90, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  // Rows
                  ..._banners.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final b = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(b.targetAudience, style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                            ),
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
                                await _loadCmsData();
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
              await _deleteBanner(b.id);
              _showMessage('Banner deleted successfully.');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCardItem(DashboardBannerModel b) {
    Color bg = const Color(0xFF5B21B6);
    try {
      if (b.bgColor.startsWith('#')) {
        bg = Color(int.parse(b.bgColor.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  b.isActive ? 'Active' : 'Disabled',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                onSelected: (val) {
                  if (val == 'edit') _openBannerModal(banner: b);
                  if (val == 'delete') _confirmDeleteBanner(b);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(b.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFACC15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              b.ctaText,
              style: const TextStyle(color: Color(0xFF1E1B4B), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // QUICK STATS CARD
  Widget _buildQuickStatsCard() {
    final isEnabled = _sections.firstWhere((s) => s.sectionKey == 'quick_stats', orElse: () => DashboardSectionModel(id: '', sectionKey: 'quick_stats', title: 'Quick Stats', subtitle: '', sortOrder: 2, isEnabled: true, isVisible: true)).isEnabled;

    return _buildContainerCard(
      title: 'Quick Stats',
      subtitle: 'Manage the statistics cards shown below the banner',
      number: '2',
      isEnabled: isEnabled,
      onToggleEnable: (val) => _setSectionEnabled('quick_stats', val),
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openQuickStatModal(),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Add Stat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(50),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(3),
          4: FlexColumnWidth(2),
          5: FixedColumnWidth(80),
          6: FixedColumnWidth(80),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            children: [
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Icon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Data Source', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Change (vs 7 days)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
            ],
          ),
          ..._quickStats.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final s = entry.value;
            return TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC)))),
              children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('$idx', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.bar_chart, size: 16, color: Color(0xFF2563EB)),
                  ),
                ),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.dataSource, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B)))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.changeText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                    child: Text(s.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 16, color: Color(0xFF64748B)), onPressed: () => _openQuickStatModal(stat: s)),
                      IconButton(icon: const Icon(Icons.delete, size: 16, color: Color(0xFFEF4444)), onPressed: () => _deleteQuickStat(s.id)),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // QUICK ACTIONS CARD
  Widget _buildQuickActionsCard() {
    final isEnabled = _sections.firstWhere((s) => s.sectionKey == 'quick_actions', orElse: () => DashboardSectionModel(id: '', sectionKey: 'quick_actions', title: 'Quick Actions', subtitle: '', sortOrder: 4, isEnabled: true, isVisible: true)).isEnabled;

    return _buildContainerCard(
      title: 'Quick Actions',
      subtitle: 'Manage quick action buttons for easy navigation',
      number: '3',
      isEnabled: isEnabled,
      onToggleEnable: (val) => _setSectionEnabled('quick_actions', val),
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openQuickActionModal(),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Add Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(50),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(3),
          4: FixedColumnWidth(80),
          5: FixedColumnWidth(80),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            children: [
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Icon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Navigation / Destination', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
            ],
          ),
          ..._quickActions.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final a = entry.value;
            return TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC)))),
              children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('$idx', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.track_changes_rounded, size: 16, color: Color(0xFF16A34A)),
                  ),
                ),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(a.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Navigate to ${a.destination}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 16, color: Color(0xFF64748B)), onPressed: () => _openQuickActionModal(action: a)),
                      IconButton(icon: const Icon(Icons.delete, size: 16, color: Color(0xFFEF4444)), onPressed: () => _deleteQuickAction(a.id)),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // RIGHT SIDE PANEL: SECTION VISIBILITY
  Widget _buildSectionVisibilityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Section Visibility', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Text('Show / hide entire sections on the dashboard', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          ..._sections.map((sec) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sec.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                  Switch(
                    value: sec.isVisible,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) => _setSectionVisibility(sec.sectionKey, val),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // TIPS CARD
  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 6),
              Text('Tips', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
            ],
          ),
          SizedBox(height: 8),
          Text('• Drag and drop to reorder items in each section.', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
          Text('• Changes reflect in real-time on user dashboard.', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
          Text('• Use Preview to see how changes look for users.', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
        ],
      ),
    );
  }

  // NEED HELP CARD
  Widget _buildNeedHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Need Help?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          const Text('Learn how to customize the dashboard with our guide.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new, size: 14, color: Color(0xFF4F46E5)),
            label: const Text('View Documentation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // CONTAINER CARD HELPER
  Widget _buildContainerCard({
    required String title,
    required String subtitle,
    required String number,
    required bool isEnabled,
    required Function(bool) onToggleEnable,
    required List<Widget> actions,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF4F46E5),
                    child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Enable Section', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                  const SizedBox(width: 8),
                  Switch(
                    value: isEnabled,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) => onToggleEnable(val),
                  ),
                  const SizedBox(width: 12),
                  ...actions,
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ========================================================
  // TAB 2: LAYOUT & VISIBILITY (REORDER SECTIONS)
  // ========================================================
  Widget _buildLayoutVisibilityTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reorder & Section Visibility Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Text('Drag items to rearrange how sections appear on the Student Dashboard.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIdx, newIdx) async {
              if (newIdx > oldIdx) newIdx -= 1;
              setState(() {
                final item = _sections.removeAt(oldIdx);
                _sections.insert(newIdx, item);
              });
              await DashboardCmsService.saveSectionOrders(_sections);
              _showMessage('Section order saved to Supabase!');
            },
            children: _sections.map((sec) {
              return Container(
                key: ValueKey(sec.sectionKey),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sec.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          Text(sec.subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(sec.isVisible ? 'Visible' : 'Hidden', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sec.isVisible ? const Color(0xFF16A34A) : const Color(0xFFEF4444))),
                        Switch(
                          value: sec.isVisible,
                          onChanged: (val) => _setSectionVisibility(sec.sectionKey, val),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAB 3: SETTINGS
  // ========================================================
  Widget _buildSettingsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CMS Sync & System Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Text('Configure Supabase Realtime synchronization and default audience parameters.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 24),

          ListTile(
            title: const Text('Supabase Realtime Sync', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Propagate CMS changes instantaneously to connected student devices'),
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          const Divider(),
          ListTile(
            title: const Text('Default Target Exam Filter', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Default exam filter for new banners and quick actions'),
            trailing: DropdownButton<String>(
              value: 'NEET',
              items: ['All', 'NEET', 'JEE Main', 'JEE Advanced'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {},
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAB 4: PREVIEW DASHBOARD (INTERACTIVE STUDENT PREVIEW)
  // ========================================================
  Widget _buildPreviewDashboardTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview Header Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.visibility, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('PREVIEW MODE - Live Student Dashboard Simulation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Desktop'),
                    selected: !_isPreviewMobile,
                    onSelected: (val) => setState(() => _isPreviewMobile = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Mobile'),
                    selected: _isPreviewMobile,
                    onSelected: (val) => setState(() => _isPreviewMobile = true),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Live Frame Container
        Center(
          child: Container(
            width: _isPreviewMobile ? 380 : double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text('Good Morning, Student! 👋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const Text('Heres your live dashboard configured by Admin.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 20),

                // Render Active Sections in Order
                ..._sections.where((s) => s.isEnabled && s.isVisible).map((sec) {
                  if (sec.sectionKey == 'banner_slider') return _buildPreviewBanners();
                  if (sec.sectionKey == 'quick_stats') return _buildPreviewStats();
                  if (sec.sectionKey == 'quick_actions') return _buildPreviewActions();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Text('📍 Section: ${sec.title}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewBanners() {
    final active = _banners.where((b) => b.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    final b = active.first;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF5B21B6), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(b.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: Text(b.ctaText)),
        ],
      ),
    );
  }

  Widget _buildPreviewStats() {
    final active = _quickStats.where((s) => s.isEnabled).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: active.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  const Text('1,248', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreviewActions() {
    final active = _quickActions.where((a) => a.isEnabled).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: active.map((a) {
          return Chip(
            avatar: const Icon(Icons.arrow_forward, size: 14),
            label: Text(a.title),
            backgroundColor: const Color(0xFFEFF6FF),
          );
        }).toList(),
      ),
    );
  }

  // ========================================================
  // TAB 5: AUDIT LOGS
  // ========================================================
  Widget _buildAuditLogsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Admin Audit Log History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Text('Chronological record of all CMS modifications and section configuration changes.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(160),
              1: FixedColumnWidth(160),
              2: FixedColumnWidth(140),
              3: FixedColumnWidth(120),
              4: FlexColumnWidth(2),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                children: [
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF94A3B8)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF94A3B8)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF94A3B8)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Entity Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF94A3B8)))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF94A3B8)))),
                ],
              ),
              ..._auditLogs.map((log) {
                return TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC)))),
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(log.createdAt.toIso8601String().substring(0, 16).replaceFirst('T', ' '), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(log.userEmail, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(log.action, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(log.entityType, style: const TextStyle(fontSize: 11, color: Color(0xFF334155)))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(jsonEncode(log.details), style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B)))),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // MODALS & CRUD DIALOGS
  // ========================================================
  void _openBannerModal({DashboardBannerModel? banner}) {
    debugPrint('[ADMIN CMS] ${banner == null ? "ADD BANNER CLICKED" : "EDIT BANNER CLICKED"}');
    final titleCtrl = TextEditingController(text: banner?.title ?? '');
    final subCtrl = TextEditingController(text: banner?.subtitle ?? '');
    final imgCtrl = TextEditingController(text: banner?.imageUrl ?? '');
    final ctaCtrl = TextEditingController(text: banner?.ctaText ?? 'Subscribe Now');
    final destCtrl = TextEditingController(text: banner?.ctaDestination ?? '/practice');
    final bgCtrl = TextEditingController(text: banner?.bgColor ?? '#5B21B6');
    final btnCtrl = TextEditingController(text: banner?.btnColor ?? '#FACC15');
    String audience = banner?.targetAudience ?? 'All Students';
    String platform = banner?.targetPlatform ?? 'all';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(banner == null ? 'Add Banner' : 'Edit Banner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Banner Title *')),
                TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Subtitle')),
                TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Image URL (e.g. https://...)')),
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
                    sortOrder: banner?.sortOrder ?? (_banners.length + 1),
                    targetAudience: audience,
                    targetPlatform: platform,
                  );
                  final saved = await DashboardCmsService.saveBanner(newB);
                  debugPrint('[ADMIN CMS] Banner Saved Successfully: ${saved.id}');
                  if (mounted) {
                    Navigator.pop(ctx);
                    _showMessage('Banner saved successfully!');
                    await _loadCmsData();
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

  Future<void> _deleteBanner(String id) async {
    debugPrint('[ADMIN CMS] DELETE BANNER CLICKED: $id');
    await DashboardCmsService.deleteBanner(id);
    _loadCmsData();
  }

  void _openManageBannerOrderModal() {
    debugPrint('[ADMIN CMS] MANAGE BANNER ORDER CLICKED');
    List<DashboardBannerModel> list = [..._banners];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Banner Order'),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (context, idx) {
                final b = list[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${idx + 1}. ${b.title.replaceAll('\n', ' ')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 16),
                        onPressed: idx == 0 ? null : () {
                          setDialogState(() {
                            final temp = list[idx];
                            list[idx] = list[idx - 1];
                            list[idx - 1] = temp;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        onPressed: idx == list.length - 1 ? null : () {
                          setDialogState(() {
                            final temp = list[idx];
                            list[idx] = list[idx + 1];
                            list[idx + 1] = temp;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                for (int i = 0; i < list.length; i++) {
                  await DashboardCmsService.saveBanner(
                    DashboardBannerModel(
                      id: list[i].id,
                      title: list[i].title,
                      subtitle: list[i].subtitle,
                      ctaText: list[i].ctaText,
                      ctaDestination: list[i].ctaDestination,
                      isActive: list[i].isActive,
                      sortOrder: i + 1,
                      targetAudience: list[i].targetAudience,
                    ),
                  );
                }
                Navigator.pop(ctx);
                _loadCmsData();
                _showMessage('Banner order updated!');
              },
              child: const Text('Save Order'),
            ),
          ],
        ),
      ),
    );
  }

  void _openQuickStatModal({DashboardQuickStatModel? stat}) {
    debugPrint('[ADMIN CMS] ${stat == null ? "ADD STAT CLICKED" : "EDIT STAT CLICKED"}');
    final titleCtrl = TextEditingController(text: stat?.title ?? '');
    final sourceCtrl = TextEditingController(text: stat?.dataSource ?? 'user_stats.questions_attempted');
    final changeCtrl = TextEditingController(text: stat?.changeText ?? '↑ 10%');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(stat == null ? 'Add Quick Stat' : 'Edit Quick Stat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Stat Title *')),
              TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: 'Data Source Field')),
              TextField(controller: changeCtrl, decoration: const InputDecoration(labelText: 'Change Label')),
            ],
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (titleCtrl.text.trim().isEmpty) {
                  _showMessage('Please enter a stat title.');
                  return;
                }
                setModalState(() => isSaving = true);
                try {
                  final newS = DashboardQuickStatModel(
                    id: stat?.id ?? '',
                    statKey: stat?.statKey ?? titleCtrl.text.toLowerCase().replaceAll(' ', '_'),
                    title: titleCtrl.text.trim(),
                    iconName: 'bar_chart',
                    dataSource: sourceCtrl.text.trim(),
                    changeText: changeCtrl.text.trim(),
                    sortOrder: stat?.sortOrder ?? (_quickStats.length + 1),
                    isEnabled: true,
                  );
                  await DashboardCmsService.saveQuickStat(newS);
                  if (mounted) {
                    Navigator.pop(ctx);
                    _showMessage('Stat saved successfully!');
                    await _loadCmsData();
                  }
                } catch (e) {
                  debugPrint('[ADMIN CMS] Error saving stat: $e');
                  setModalState(() => isSaving = false);
                  _showMessage('Error saving stat: $e');
                }
              },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Stat'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQuickStat(String id) async {
    debugPrint('[ADMIN CMS] DELETE STAT CLICKED: $id');
    try {
      await DashboardCmsService.deleteQuickStat(id);
      _showMessage('Stat deleted.');
      _loadCmsData();
    } catch (e) {
      _showMessage('Error deleting stat: $e');
    }
  }

  void _openQuickActionModal({DashboardQuickActionModel? action}) {
    debugPrint('[ADMIN CMS] ${action == null ? "ADD ACTION CLICKED" : "EDIT ACTION CLICKED"}');
    final titleCtrl = TextEditingController(text: action?.title ?? '');
    final descCtrl = TextEditingController(text: action?.description ?? '');
    final destCtrl = TextEditingController(text: action?.destination ?? '/practice');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(action == null ? 'Add Quick Action' : 'Edit Quick Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Action Title *')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: destCtrl, decoration: const InputDecoration(labelText: 'Destination Route')),
            ],
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (titleCtrl.text.trim().isEmpty) {
                  _showMessage('Please enter an action title.');
                  return;
                }
                setModalState(() => isSaving = true);
                try {
                  final newA = DashboardQuickActionModel(
                    id: action?.id ?? '',
                    actionKey: action?.actionKey ?? titleCtrl.text.toLowerCase().replaceAll(' ', '_'),
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    iconName: 'assignment',
                    destination: destCtrl.text.trim(),
                    isEnabled: true,
                    sortOrder: action?.sortOrder ?? (_quickActions.length + 1),
                  );
                  await DashboardCmsService.saveQuickAction(newA);
                  if (mounted) {
                    Navigator.pop(ctx);
                    _showMessage('Quick Action saved successfully!');
                    await _loadCmsData();
                  }
                } catch (e) {
                  debugPrint('[ADMIN CMS] Error saving action: $e');
                  setModalState(() => isSaving = false);
                  _showMessage('Error saving action: $e');
                }
              },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Action'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQuickAction(String id) async {
    debugPrint('[ADMIN CMS] DELETE ACTION CLICKED: $id');
    await DashboardCmsService.deleteQuickAction(id);
    _loadCmsData();
  }

  // ========================================================
  // SIDEBAR NAVIGATION
  // ========================================================
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.school, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('ExamPrep Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSidebarGroupHeader('MAIN'),
                _buildSidebarItem(Icons.dashboard_outlined, 'Dashboard'),
                _buildSidebarItem(Icons.people_outline, 'Users'),
                _buildSidebarItem(Icons.help_outline, 'Questions'),
                _buildSidebarItem(Icons.assignment_outlined, 'Tests'),
                _buildSidebarItem(Icons.menu_book_outlined, 'PYQ & NTA'),
                _buildSidebarItem(Icons.bar_chart_outlined, 'Analytics'),

                const SizedBox(height: 16),
                _buildSidebarGroupHeader('CONTENT MANAGEMENT'),
                _buildSidebarItem(Icons.view_carousel_outlined, 'Banners'),
                _buildSidebarItem(Icons.stacked_bar_chart, 'Quick Stats'),
                _buildSidebarItem(Icons.touch_app_outlined, 'Quick Actions'),
                _buildSidebarItem(Icons.dashboard_customize, 'Dashboard Sections', isSelected: true),

                const SizedBox(height: 16),
                _buildSidebarGroupHeader('SYSTEM'),
                _buildSidebarItem(Icons.settings_outlined, 'Settings'),
                _buildSidebarItem(Icons.history, 'Audit Logs'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool isSelected = false}) {
    return InkWell(
      onTap: () {
        if (title == 'Banners') {
          setState(() {
            _activeSidebar = 'Banners';
            _activeTab = 'Banners';
          });
        } else {
          setState(() => _activeSidebar = title);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFFCBD5E1))),
          ],
        ),
      ),
    );
  }
}
