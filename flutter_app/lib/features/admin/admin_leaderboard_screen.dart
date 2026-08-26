import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import 'admin_user_management_screen.dart';

class AdminLeaderboardScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminLeaderboardScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminLeaderboardScreen> createState() => _AdminLeaderboardScreenState();
}

class _AdminLeaderboardScreenState extends State<AdminLeaderboardScreen> {
  String _activeTab = 'Overall Leaderboard';
  String _selectedExam = 'NEET UG 2026';
  String _selectedTestType = 'All Test Types';
  String _selectedTimePeriod = 'This Month';
  String _selectedSubject = 'All Subjects';
  String _selectedClass = 'All Years';
  String _searchQuery = '';

  bool _showMyRank = true;
  bool _verifiedOnly = true;
  bool _instituteFilter = false;

  final List<Map<String, dynamic>> _leaderboardData = [
    {
      'rank': 1,
      'name': 'Mahboob Hasan',
      'id': '230145',
      'avatar': 'https://i.pravatar.cc/100?img=33',
      'score': 720,
      'accuracy': '98.6%',
      'tests': 68,
      'best': '720 Full Score',
      'improvement': '↗ 32.4% vs last month',
      'badges': ['👑', '🎯', '🛡️'],
      'isVerified': true,
      'isUser': false,
    },
    {
      'rank': 2,
      'name': 'Riya Patel',
      'id': '230987',
      'avatar': 'https://i.pravatar.cc/100?img=47',
      'score': 698,
      'accuracy': '96.1%',
      'tests': 54,
      'best': '712',
      'improvement': '↗ 28.7% vs last month',
      'badges': ['🎯', '🔥'],
      'isVerified': true,
      'isUser': false,
    },
    {
      'rank': 3,
      'name': 'Karan Singh',
      'id': '231102',
      'avatar': 'https://i.pravatar.cc/100?img=12',
      'score': 685,
      'accuracy': '94.3%',
      'tests': 62,
      'best': '700',
      'improvement': '↗ 24.1%',
      'badges': ['🛡️', '🎯'],
      'isVerified': true,
      'isUser': false,
    },
    {
      'rank': 4,
      'name': 'Meera Joshi',
      'id': '230512',
      'avatar': 'https://i.pravatar.cc/100?img=24',
      'score': 672,
      'accuracy': '93.2%',
      'tests': 49,
      'best': '688',
      'improvement': '↗ 21.6%',
      'badges': ['🎯'],
      'isVerified': true,
      'isUser': false,
    },
    {
      'rank': 5,
      'name': 'Dev Arora',
      'id': '230751',
      'avatar': 'https://i.pravatar.cc/100?img=60',
      'score': 659,
      'accuracy': '92.5%',
      'tests': 58,
      'best': '672',
      'improvement': '↗ 19.3%',
      'badges': ['🎯'],
      'isVerified': true,
      'isUser': false,
    },
    {
      'rank': 6,
      'name': 'Sneha Pandey',
      'id': '229543',
      'avatar': 'https://i.pravatar.cc/100?img=49',
      'score': 645,
      'accuracy': '91.8%',
      'tests': 44,
      'best': '660',
      'improvement': '↗ 17.8%',
      'badges': ['🛡️', '🔥'],
      'isVerified': true,
      'isUser': false,
    },
    {
      'rank': 7,
      'name': 'Aditya Verma',
      'id': '229876',
      'avatar': 'https://i.pravatar.cc/100?img=53',
      'score': 632,
      'accuracy': '90.2%',
      'tests': 52,
      'best': '645',
      'improvement': '↗ 16.5%',
      'badges': ['🎯'],
      'isVerified': true,
      'isUser': false,
    },
    {
      'rank': 28,
      'name': 'You (Mahboob Hasan)',
      'id': '230145',
      'avatar': 'https://i.pravatar.cc/100?img=33',
      'score': 560,
      'accuracy': '84.6%',
      'tests': 34,
      'best': '598',
      'improvement': '↗ 8.2%',
      'badges': ['🛡️'],
      'isVerified': true,
      'isUser': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. LEFT DARK SIDEBAR NAVIGATION (#0B0F19)
          if (isDesktop) _buildAdminSidebar(),

          // 2. MAIN LEADERBOARD CANVAS AREA
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildAdminHeader(),

                // Main Scrollable Canvas
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Title & Subtitle + Top Action Buttons
                        _buildTitleRow(),
                        const SizedBox(height: 20),

                        // Sub-navigation Tabs
                        _buildSubNavTabs(),
                        const SizedBox(height: 24),

                        // Top 5 Metrics Cards Row
                        _buildTopMetricsRow(),
                        const SizedBox(height: 24),

                        // Main Content Layout (Left: Filters + Leaderboard Table, Right: Sidebar Panels)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Filter Card + Leaderboard Table
                            Expanded(
                              flex: 8,
                              child: Column(
                                children: [
                                  _buildFilterControlCard(),
                                  const SizedBox(height: 20),
                                  _buildLeaderboardTableCard(),
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Right Column: My Performance + Top Performers + Settings + About
                            SizedBox(
                              width: 300,
                              child: Column(
                                children: [
                                  _buildMyPerformanceCard(),
                                  const SizedBox(height: 20),
                                  _buildTopPerformersCard(),
                                  const SizedBox(height: 20),
                                  _buildLeaderboardSettingsCard(),
                                  const SizedBox(height: 20),
                                  _buildAboutLeaderboardCard(),
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

  // ================= 1. LEFT SIDEBAR NAVIGATION =================
  Widget _buildAdminSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF0B0F19),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cosmyra Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Control Center', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarSectionLabel('MAIN NAVIGATION'),
                _buildSidebarTile('Dashboard', Icons.dashboard_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin')),
                _buildSidebarTile('Paper Predictions', Icons.note_alt_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin/predictions')),
                _buildSidebarTile('Exam Hierarchy', Icons.account_tree_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin/hierarchy')),
                _buildSidebarTile('Pricing & Plans', Icons.sell_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin/pricing')),
                _buildSidebarTile('Question Bank', Icons.quiz_outlined, false),
                _buildSidebarTile('CSV Bulk Import', Icons.upload_file_outlined, false),
                _buildSidebarTile('Reported Questions', Icons.flag_outlined, false),
                _buildSidebarTile('PYQs & Papers', Icons.auto_stories_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin/predictions')),
                _buildSidebarTile('Leaderboard', Icons.emoji_events_outlined, true, onTap: () => Navigator.pushNamed(context, '/admin/leaderboard')),
                _buildSidebarTile('User Management', Icons.people_outline_rounded, false, onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => AdminUserManagementScreen(userProfile: widget.userProfile)));
                }),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('REPORTS & ANALYTICS'),
                _buildSidebarTile('Analytics Dashboard', Icons.bar_chart_rounded, false),
                _buildSidebarTile('Question Reports', Icons.assessment_outlined, false),
                _buildSidebarTile('Student Performance', Icons.insights_rounded, false),
                _buildSidebarTile('Topper Analytics', Icons.stars_outlined, false),
                _buildSidebarTile('Activity Logs', Icons.history_rounded, false),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('SYSTEM & SETTINGS'),
                _buildSidebarTile('System Settings', Icons.settings_outlined, false),
                _buildSidebarTile('Notification Center', Icons.notifications_none_rounded, false),
                _buildSidebarTile('Backup & Restore', Icons.cloud_download_outlined, false),
                _buildSidebarTile('Integrations', Icons.extension_outlined, false),
                const SizedBox(height: 20),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Need Help?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Check documentation or contact support.', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: const Text('View Docs →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF6366F1),
                  child: Text('AU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin User', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Super Administrator', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    ],
                  ),
                ),
                Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildSidebarTile(String title, IconData icon, bool isActive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 2. TOP HEADER BAR =================
  Widget _buildAdminHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu, color: Color(0xFF64748B)),
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 8),
              const Text('Cosmyra Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(width: 32),

          Expanded(
            child: Container(
              height: 38,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users, exams, topics or performance...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Text('⌘ K', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF4F46E5)),
                label: const Text('Quick Actions', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(icon: const Icon(Icons.dark_mode_outlined, size: 20, color: Color(0xFF64748B)), onPressed: () {}),
              Stack(
                children: [
                  IconButton(icon: const Icon(Icons.notifications_none_rounded, size: 22, color: Color(0xFF64748B)), onPressed: () {}),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Text('8', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF8B5CF6),
                child: Text('AU', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Super Administrator', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. PAGE TITLE ROW =================
  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leaderboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 2),
            Text('Real-time rankings and performance leaderboard across exams, tests and categories.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF4F46E5)),
              label: const Text('Share Leaderboard', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF4F46E5)),
              label: const Text('Refresh', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export ∨', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= 4. SUB-NAVIGATION TABS =================
  Widget _buildSubNavTabs() {
    final tabs = ['Overall Leaderboard', 'Exam Wise', 'Daily Challenge', 'Weekly Challenge', 'Monthly Challenge', 'Custom Leaderboard'];
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _activeTab == t;
          return InkWell(
            onTap: () => setState(() => _activeTab = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= 5. TOP 5 METRICS CARDS ROW =================
  Widget _buildTopMetricsRow() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Participants', '24,850', '↗ 1,250 this week', Icons.people_outline, const Color(0xFF8B5CF6))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Tests Attempted', '1,42,580', '↗ 8,340 this week', Icons.assignment_outlined, const Color(0xFF10B981))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Average Score', '64.8%', '↗ 5.2% this week', Icons.bar_chart_rounded, const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Top Score', '720 / 720', 'by Mahboob Hasan', Icons.emoji_events_outlined, const Color(0xFFF59E0B))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('My Rank', '#28', '↗ 12 positions', Icons.person_outline, const Color(0xFFEC4899))),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(subtext, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subtext.startsWith('↗') ? const Color(0xFF10B981) : Colors.grey)),
        ],
      ),
    );
  }

  // ================= 6. FILTER CONTROL PANEL CARD =================
  Widget _buildFilterControlCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdowns Row
          Row(
            children: [
              Expanded(child: _buildFilterDropdown('Exam', _selectedExam, ['NEET UG 2026', 'JEE Main 2026', 'JEE Advanced 2026'], (v) => setState(() => _selectedExam = v!))),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterDropdown('Test Type', _selectedTestType, ['All Test Types', 'Full Mock Test', 'Chapter Test'], (v) => setState(() => _selectedTestType = v!))),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterDropdown('Time Period', _selectedTimePeriod, ['This Month', 'This Week', 'All Time'], (v) => setState(() => _selectedTimePeriod = v!))),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterDropdown('Subject', _selectedSubject, ['All Subjects', 'Physics', 'Chemistry', 'Biology'], (v) => setState(() => _selectedSubject = v!))),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterDropdown('Class / Year', _selectedClass, ['All Years', 'Class 11', 'Class 12', 'Dropper'], (v) => setState(() => _selectedClass = v!))),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF4F46E5)),
                label: const Text('More Filters ∨', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search + Checkboxes Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: const InputDecoration(
                            hintText: 'Search by name or user ID...',
                            hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              _buildCheckbox('Show My Rank', _showMyRank, (v) => setState(() => _showMyRank = v!)),
              const SizedBox(width: 12),
              _buildCheckbox('Verified Users Only', _verifiedOnly, (v) => setState(() => _verifiedOnly = v!)),
              const SizedBox(width: 12),
              _buildCheckbox('Institute Filter', _instituteFilter, (v) => setState(() => _instituteFilter = v!)),
              const SizedBox(width: 16),

              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.red),
                label: const Text('Reset Filters', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            activeColor: const Color(0xFF4F46E5),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      ],
    );
  }

  // ================= 7. LEADERBOARD TABLE CARD =================
  Widget _buildLeaderboardTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 40, child: Text('RANK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 3, child: Text('USER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Center(child: Text('SCORE\n(OUT OF 720)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)), textAlign: TextAlign.center))),
                Expanded(flex: 2, child: Center(child: Text('ACCURACY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                Expanded(flex: 2, child: Center(child: Text('TESTS\nATTEMPTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)), textAlign: TextAlign.center))),
                Expanded(flex: 2, child: Center(child: Text('BEST SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                Expanded(flex: 3, child: Center(child: Text('IMPROVEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                Expanded(flex: 2, child: Center(child: Text('BADGES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
                SizedBox(width: 60, child: Center(child: Text('ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
              ],
            ),
          ),
          const Divider(height: 1),

          // Rows
          ..._leaderboardData
              .where((row) => row['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
              .map((row) => _buildLeaderboardRow(row))
              .toList(),

          const Divider(height: 1),

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Showing 1 to 10 of 24,850 participants', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Row(
                  children: [
                    const Text('Show ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(6)),
                      child: const Text('10 per page ∨', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        _buildPageBtn('<', false),
                        _buildPageBtn('1', true),
                        _buildPageBtn('2', false),
                        _buildPageBtn('3', false),
                        const Text(' ... ', style: TextStyle(color: Colors.grey)),
                        _buildPageBtn('2485', false),
                        _buildPageBtn('>', false),
                      ],
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

  Widget _buildLeaderboardRow(Map<String, dynamic> row) {
    final isUser = row['isUser'] == true;
    final rank = row['rank'] as int;

    return Container(
      color: isUser ? const Color(0xFFEEF2FF) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Rank Icon/Badge
          SizedBox(
            width: 40,
            child: rank == 1
                ? const Text('🥇', style: TextStyle(fontSize: 18))
                : (rank == 2
                    ? const Text('🥈', style: TextStyle(fontSize: 18))
                    : (rank == 3
                        ? const Text('🥉', style: TextStyle(fontSize: 18))
                        : Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))))),
          ),

          // User Profile
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(radius: 14, backgroundImage: NetworkImage(row['avatar'])),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              row['name'],
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUser ? const Color(0xFF4F46E5) : const Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (row['isVerified'] == true) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF3B82F6)),
                          ],
                        ],
                      ),
                      Text('ID: ${row['id']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Score
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '${row['score']}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),
          ),

          // Accuracy
          Expanded(
            flex: 2,
            child: Center(
              child: Text(row['accuracy'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ),
          ),

          // Tests
          Expanded(
            flex: 2,
            child: Center(
              child: Text('${row['tests']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            ),
          ),

          // Best Score
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(row['best'].toString().split(' ')[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  if (row['best'].toString().contains('Full'))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Full Score', style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),

          // Improvement
          Expanded(
            flex: 3,
            child: Center(
              child: Text(row['improvement'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            ),
          ),

          // Badges
          Expanded(
            flex: 2,
            child: Center(
              child: Text((row['badges'] as List).join(' '), style: const TextStyle(fontSize: 14)),
            ),
          ),

          // Actions
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.download_outlined, size: 14, color: Color(0xFF64748B)), onPressed: () {}),
                IconButton(icon: const Icon(Icons.more_vert_rounded, size: 14, color: Color(0xFF64748B)), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBtn(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4F46E5) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
      ),
      child: Text(
        label,
        style: TextStyle(color: isActive ? Colors.white : const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ================= 8. RIGHT SIDEBAR WIDGETS =================
  Widget _buildMyPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Performance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              TextButton(onPressed: () {}, child: const Text('View Profile →', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Percentile Donut
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 26,
                        sections: [
                          PieChartSectionData(color: const Color(0xFF4F46E5), value: 78, radius: 10, showTitle: false),
                          PieChartSectionData(color: const Color(0xFFEEF2FF), value: 22, radius: 10, showTitle: false),
                        ],
                      ),
                    ),
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('78%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text('Percentile', style: TextStyle(fontSize: 7, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Rank', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('#28', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  SizedBox(height: 6),
                  Text('Score', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('560 / 720', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  SizedBox(height: 6),
                  Text('Accuracy', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('84.6%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Rank Trend Line Chart
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rank Trend (This Month)', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('↗ 12', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 30), FlSpot(1, 26), FlSpot(2, 28), FlSpot(3, 24), FlSpot(4, 20), FlSpot(5, 28)],
                    isCurved: true,
                    color: const Color(0xFF4F46E5),
                    barWidth: 2,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Performers (This Month)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 10, color: Colors.grey))),
            ],
          ),
          const SizedBox(height: 10),
          _buildPerformerRow('🥇', 'Mahboob Hasan', 'https://i.pravatar.cc/100?img=33', '720'),
          _buildPerformerRow('🥈', 'Riya Patel', 'https://i.pravatar.cc/100?img=47', '698'),
          _buildPerformerRow('🥉', 'Karan Singh', 'https://i.pravatar.cc/100?img=12', '685'),
        ],
      ),
    );
  }

  Widget _buildPerformerRow(String medal, String name, String avatar, String score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          CircleAvatar(radius: 12, backgroundImage: NetworkImage(avatar)),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
          Text(score, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leaderboard Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _buildSettingRow(Icons.track_changes_outlined, 'Scoring Criteria', 'Based on Accuracy & Score'),
          _buildSettingRow(Icons.access_time_rounded, 'Update Frequency', 'Real-time'),
          _buildSettingRow(Icons.person_outline, 'Include Inactive Users', 'No'),
        ],
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(val, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutLeaderboardCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About Leaderboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text(
            'Rankings are calculated based on performance in tests during the selected time period. Only verified users are included.',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: const Text('Learn More →', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
