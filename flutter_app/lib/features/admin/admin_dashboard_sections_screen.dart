import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class AdminDashboardSectionsScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminDashboardSectionsScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminDashboardSectionsScreen> createState() => _AdminDashboardSectionsScreenState();
}

class _AdminDashboardSectionsScreenState extends State<AdminDashboardSectionsScreen> {
  String _activeTab = 'Dashboard Sections';
  String _activeSidebar = 'Dashboard Sections';

  // Section Visibility Toggles State
  final Map<String, bool> _sectionVisibility = {
    'Banner Slider': true,
    'Quick Stats': true,
    'Continue Section': true,
    'Quick Actions': true,
    'Performance Overview': true,
    'Subject Strength': true,
    'Leaderboard Preview': true,
    'Recent Tests': true,
  };

  // Section Enable Toggles
  bool _bannerSectionEnabled = true;
  bool _quickStatsSectionEnabled = true;
  bool _quickActionsSectionEnabled = true;

  // Banners State
  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'NEET 2026\nMega Scholarship\nTest Series',
      'sub': 'Get up to 50% OFF',
      'btn': 'Subscribe Now',
      'color': const Color(0xFF5B21B6),
      'btnColor': const Color(0xFFFACC15),
      'btnTextColor': const Color(0xFF1E1B4B),
      'icon': Icons.school_rounded,
      'status': 'Active',
    },
    {
      'title': 'Unlimited Practice\nUnlimited Tests',
      'sub': 'One Subscription.\nAll Access.',
      'btn': 'View Plans',
      'color': const Color(0xFF047857),
      'btnColor': const Color(0xFFFACC15),
      'btnTextColor': const Color(0xFF064E3B),
      'icon': Icons.assignment_rounded,
      'status': 'Active',
    },
    {
      'title': 'PYQ Practice\nBoost Your Score',
      'sub': 'Practice past years\' papers\nchapter-wise & topic-wise.',
      'btn': 'Start Practicing',
      'color': const Color(0xFF1E40AF),
      'btnColor': const Color(0xFFFFFFFF),
      'btnTextColor': const Color(0xFF1E40AF),
      'icon': Icons.menu_book_rounded,
      'status': 'Active',
    },
    {
      'title': 'Refer & Earn\nInvite Friends\nEarn Premium',
      'sub': 'Earn exciting rewards by\nreferring your friends.',
      'btn': 'Know More',
      'color': const Color(0xFFC2410C),
      'btnColor': const Color(0xFFFFFFFF),
      'btnTextColor': const Color(0xFF9A3412),
      'icon': Icons.card_giftcard_rounded,
      'status': 'Active',
    },
  ];

  // Quick Stats Data
  final List<Map<String, dynamic>> _quickStats = [
    {
      'id': '1',
      'title': 'Questions Attempted',
      'source': 'user_stats.questions_attempted',
      'change': '↑ 18%',
      'icon': Icons.edit_document,
      'iconColor': const Color(0xFF2563EB),
      'iconBg': const Color(0xFFEFF6FF),
      'status': 'Active',
    },
    {
      'id': '2',
      'title': 'Accuracy',
      'source': 'user_stats.accuracy',
      'change': '↑ 6.3%',
      'icon': Icons.track_changes_rounded,
      'iconColor': const Color(0xFF16A34A),
      'iconBg': const Color(0xFFDCFCE7),
      'status': 'Active',
    },
    {
      'id': '3',
      'title': 'Tests Completed',
      'source': 'user_stats.tests_completed',
      'change': '↑ 4',
      'icon': Icons.assignment_turned_in_rounded,
      'iconColor': const Color(0xFF7C3AED),
      'iconBg': const Color(0xFFF5F3FF),
      'status': 'Active',
    },
    {
      'id': '4',
      'title': 'Study Streak',
      'source': 'user_stats.study_streak',
      'change': 'Best: 32 Days',
      'icon': Icons.local_fire_department_rounded,
      'iconColor': const Color(0xFFEA580C),
      'iconBg': const Color(0xFFFFF7ED),
      'status': 'Active',
    },
  ];

  // Quick Actions Data
  final List<Map<String, dynamic>> _quickActions = [
    {
      'id': '1',
      'title': 'Custom Practice',
      'nav': 'Navigate to /practice/custom',
      'icon': Icons.track_changes_rounded,
      'iconColor': const Color(0xFF16A34A),
      'iconBg': const Color(0xFFDCFCE7),
      'status': 'Active',
    },
    {
      'id': '2',
      'title': 'Custom Test',
      'nav': 'Navigate to /tests/custom',
      'icon': Icons.assignment_outlined,
      'iconColor': const Color(0xFF2563EB),
      'iconBg': const Color(0xFFDBEAFE),
      'status': 'Active',
    },
    {
      'id': '3',
      'title': 'PYQ Practice',
      'nav': 'Navigate to /pyq',
      'icon': Icons.menu_book_rounded,
      'iconColor': const Color(0xFF7C3AED),
      'iconBg': const Color(0xFFDDD6FE),
      'status': 'Active',
    },
    {
      'id': '4',
      'title': 'NTA Questions',
      'nav': 'Navigate to /nta',
      'icon': Icons.shield_outlined,
      'iconColor': const Color(0xFFEA580C),
      'iconBg': const Color(0xFFFFEDD5),
      'status': 'Active',
    },
    {
      'id': '5',
      'title': 'Test Series',
      'nav': 'Navigate to /tests/series',
      'icon': Icons.calendar_today_outlined,
      'iconColor': const Color(0xFFDB2777),
      'iconBg': const Color(0xFFFCE7F3),
      'status': 'Active',
    },
  ];

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dashboard layout management changes saved successfully!'),
        backgroundColor: Color(0xFF16A34A),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. Left Sidebar Navigation
          if (isDesktop) _buildSidebar(),

          // 2. Main Area
          Expanded(
            child: Column(
              children: [
                // Top Header Navbar
                _buildTopNavbar(),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Title & Header Actions
                        _buildTitleHeader(),
                        const SizedBox(height: 20),

                        // Sub Navigation Tabs
                        _buildSubNavTabs(),
                        const SizedBox(height: 24),

                        // Main Content & Side Panel Split
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Cards (72% flex)
                            Expanded(
                              flex: 72,
                              child: Column(
                                children: [
                                  // Section 1: Banner Slider
                                  _buildBannerSliderSection(),
                                  const SizedBox(height: 24),

                                  // Section 2: Quick Stats Table
                                  _buildQuickStatsSection(),
                                  const SizedBox(height: 24),

                                  // Section 3: Quick Actions Table
                                  _buildQuickActionsSection(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Right Side Panel (28% flex)
                            Expanded(
                              flex: 28,
                              child: Column(
                                children: [
                                  // Section Visibility Panel
                                  _buildSectionVisibilityCard(),
                                  const SizedBox(height: 20),

                                  // Tips Card
                                  _buildTipsCard(),
                                  const SizedBox(height: 20),

                                  // Need Help Card
                                  _buildNeedHelpCard(),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  // ================= 1. LEFT SIDEBAR =================
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo & Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ExamPrep',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarGroupLabel('MAIN'),
                _buildSidebarTile('Dashboard', Icons.dashboard_outlined),
                _buildSidebarTile('Users', Icons.people_outline_rounded),
                _buildSidebarTile('Questions', Icons.quiz_outlined),
                _buildSidebarTile('Tests', Icons.assignment_outlined),
                _buildSidebarTile('PYQ & NTA', Icons.menu_book_rounded),
                _buildSidebarTile('Analytics', Icons.bar_chart_rounded),
                _buildSidebarTile('Reports', Icons.outlined_flag_rounded),

                const SizedBox(height: 16),
                _buildSidebarGroupLabel('CONTENT MANAGEMENT'),
                _buildSidebarTile('Banners', Icons.image_outlined, badge: 'New'),
                _buildSidebarTile('Quick Stats', Icons.analytics_outlined),
                _buildSidebarTile('Quick Actions', Icons.touch_app_outlined),
                _buildSidebarTile('Dashboard Sections', Icons.dashboard_customize_outlined, isActive: true),
                _buildSidebarTile('Announcements', Icons.campaign_outlined),

                const SizedBox(height: 16),
                _buildSidebarGroupLabel('SYSTEM'),
                _buildSidebarTile('Subscriptions', Icons.credit_card_outlined),
                _buildSidebarTile('Settings', Icons.settings_outlined),
                _buildSidebarTile('Roles & Permissions', Icons.admin_panel_settings_outlined),
                _buildSidebarTile('Logs', Icons.list_alt_rounded),
                _buildSidebarTile('Support Tickets', Icons.help_outline_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarGroupLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSidebarTile(String title, IconData icon, {bool isActive = false, String? badge}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4338CA) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, color: isActive ? Colors.white : const Color(0xFF94A3B8), size: 18),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFFCBD5E1),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              )
            : null,
        onTap: () {
          if (title == 'Dashboard') {
            Navigator.pushNamed(context, '/admin');
          } else if (title == 'Users') {
            Navigator.pushNamed(context, '/admin/users');
          } else {
            setState(() => _activeSidebar = title);
          }
        },
      ),
    );
  }

  // ================= 2. TOP NAVBAR =================
  Widget _buildTopNavbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search Input
          Container(
            width: 320,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for students, questions, tests...',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User Profile & Notification Icons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.nightlight_round, color: Color(0xFF64748B), size: 18),
                onPressed: () {},
              ),
              const SizedBox(width: 8),

              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 20),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('8', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName : 'Admin',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const Text('Super Admin', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. TITLE HEADER =================
  Widget _buildTitleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Layout Management',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.4),
            ),
            SizedBox(height: 4),
            Text(
              'Customize and manage all sections that appear on the user dashboard.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),

        ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  // ================= 4. SUB NAV TABS =================
  Widget _buildSubNavTabs() {
    final tabs = ['Dashboard Sections', 'Layout & Visibility', 'Settings', 'Preview Dashboard'];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSel = t == _activeTab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSel ? const Color(0xFF4F46E5) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= 5. SECTION 1: BANNER SLIDER =================
  Widget _buildBannerSliderSection() {
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Banner Slider', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('Manage promotional banners that appear at the top of the dashboard', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),

              Row(
                children: [
                  const Text('Enable Section', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(width: 6),
                  Switch(
                    value: _bannerSectionEnabled,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (v) => setState(() => _bannerSectionEnabled = v),
                  ),
                  const SizedBox(width: 12),

                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('Add Banner', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),

                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Manage Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Banners List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _banners.map((b) {
                return Container(
                  width: 220,
                  height: 140,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: b['color'] as Color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (b['color'] as Color).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b['title'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b['sub'] as String,
                            style: const TextStyle(color: Colors.white70, fontSize: 8.5),
                          ),
                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: b['btnColor'] as Color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              b['btn'] as String,
                              style: TextStyle(color: b['btnTextColor'] as Color, fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      Positioned(
                        right: 0,
                        top: 0,
                        child: Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.8), size: 16),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Icon(b['icon'] as IconData, color: Colors.white.withOpacity(0.2), size: 42),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Pagination Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Container(
                width: index == 0 ? 8 : 6,
                height: index == 0 ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == 0 ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= 6. SECTION 2: QUICK STATS =================
  Widget _buildQuickStatsSection() {
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Stats', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('Manage the statistics cards shown below the banner', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),

              Row(
                children: [
                  const Text('Enable Section', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(width: 6),
                  Switch(
                    value: _quickStatsSectionEnabled,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (v) => setState(() => _quickStatsSectionEnabled = v),
                  ),
                  const SizedBox(width: 12),

                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('Add Stat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          Table(
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FixedColumnWidth(60),
              2: FlexColumnWidth(2.5),
              3: FlexColumnWidth(3),
              4: FlexColumnWidth(2),
              5: FixedColumnWidth(80),
              6: FixedColumnWidth(80),
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  _buildTableCell('#', isHeader: true),
                  _buildTableCell('Icon', isHeader: true),
                  _buildTableCell('Title', isHeader: true),
                  _buildTableCell('Data Source', isHeader: true),
                  _buildTableCell('Change (vs last 7 days)', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                  _buildTableCell('Actions', isHeader: true),
                ],
              ),
              ..._quickStats.map((item) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  children: [
                    _buildTableCell(item['id'] as String),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: item['iconBg'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 14),
                      ),
                    ),
                    _buildTableCell(item['title'] as String, isBold: true),
                    _buildTableCell(item['source'] as String, color: const Color(0xFF64748B)),
                    _buildTableCell(item['change'] as String, color: const Color(0xFF16A34A), isBold: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['status'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 16),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 7. SECTION 3: QUICK ACTIONS =================
  Widget _buildQuickActionsSection() {
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('Manage quick action buttons for easy navigation', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),

              Row(
                children: [
                  const Text('Enable Section', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(width: 6),
                  Switch(
                    value: _quickActionsSectionEnabled,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (v) => setState(() => _quickActionsSectionEnabled = v),
                  ),
                  const SizedBox(width: 12),

                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('Add Action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          Table(
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FixedColumnWidth(60),
              2: FlexColumnWidth(2.5),
              3: FlexColumnWidth(3.5),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(80),
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  _buildTableCell('#', isHeader: true),
                  _buildTableCell('Icon', isHeader: true),
                  _buildTableCell('Title', isHeader: true),
                  _buildTableCell('Navigation / Type', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                  _buildTableCell('Actions', isHeader: true),
                ],
              ),
              ..._quickActions.map((item) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  children: [
                    _buildTableCell(item['id'] as String),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: item['iconBg'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 14),
                      ),
                    ),
                    _buildTableCell(item['title'] as String, isBold: true),
                    _buildTableCell(item['nav'] as String, color: const Color(0xFF64748B)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['status'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 16),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.w500,
          color: isHeader ? const Color(0xFF475569) : (color ?? const Color(0xFF0F172A)),
        ),
      ),
    );
  }

  // ================= 8. RIGHT SIDE PANEL =================
  Widget _buildSectionVisibilityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Section Visibility', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Show / hide entire sections on the dashboard', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 14),

          ..._sectionVisibility.keys.map((k) {
            final isVal = _sectionVisibility[k] ?? true;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                  Switch(
                    value: isVal,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (v) => setState(() => _sectionVisibility[k] = v),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('Tips', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
            ],
          ),
          SizedBox(height: 10),

          Text('• Drag and drop to reorder items in each section.', style: TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.4)),
          SizedBox(height: 4),
          Text('• Changes reflect in real-time on user dashboard.', style: TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.4)),
          SizedBox(height: 4),
          Text('• Use Preview to see how changes look for users.', style: TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildNeedHelpCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Need Help?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Learn how to customize the dashboard with our guide.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF4F46E5)),
            label: const Text('View Documentation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
