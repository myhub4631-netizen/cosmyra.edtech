import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';

class AdminHierarchyScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminHierarchyScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminHierarchyScreen> createState() => _AdminHierarchyScreenState();
}

class _AdminHierarchyScreenState extends State<AdminHierarchyScreen> {
  String _selectedExamId = 'NEET_UG';
  String _activeTab = 'Subjects (4)';
  String _searchExamQuery = '';

  final List<Map<String, dynamic>> _examsList = [
    {
      'id': 'NEET_UG',
      'name': 'NEET UG',
      'code': 'NEET',
      'status': 'Active',
      'created': 'Jan 10, 2024',
      'updated': 'Aug 20, 2026',
      'subjectsCount': 4,
      'chaptersCount': 13,
      'topicsCount': 68,
      'subtopicsCount': 234,
      'icon': Icons.school_rounded,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'JEE_MAIN',
      'name': 'JEE Main',
      'code': 'JEE_MAIN',
      'status': 'Active',
      'created': 'Feb 05, 2024',
      'updated': 'Aug 18, 2026',
      'subjectsCount': 3,
      'chaptersCount': 12,
      'topicsCount': 45,
      'subtopicsCount': 180,
      'icon': Icons.explore_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'JEE_ADV',
      'name': 'JEE Advanced',
      'code': 'JEE_ADVANCED',
      'status': 'Active',
      'created': 'Mar 12, 2024',
      'updated': 'Aug 15, 2026',
      'subjectsCount': 3,
      'chaptersCount': 15,
      'topicsCount': 50,
      'subtopicsCount': 210,
      'icon': Icons.science_rounded,
      'color': const Color(0xFF3B82F6),
    },
  ];

  final List<Map<String, dynamic>> _subjects = [
    {
      'name': 'Physics',
      'code': 'PHYSICS',
      'chapters': '4 Chapters',
      'topics': '26 Topics',
      'subtopics': '89 Subtopics',
      'status': 'Active',
      'icon': Icons.science_outlined,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Chemistry',
      'code': 'CHEMISTRY',
      'chapters': '3 Chapters',
      'topics': '20 Topics',
      'subtopics': '72 Subtopics',
      'status': 'Active',
      'icon': Icons.biotech_outlined,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Botany',
      'code': 'BOTANY',
      'chapters': '3 Chapters',
      'topics': '12 Topics',
      'subtopics': '38 Subtopics',
      'status': 'Active',
      'icon': Icons.eco_outlined,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Zoology',
      'code': 'ZOOLOGY',
      'chapters': '3 Chapters',
      'topics': '10 Topics',
      'subtopics': '35 Subtopics',
      'status': 'Active',
      'icon': Icons.pets_outlined,
      'color': const Color(0xFFF59E0B),
    },
  ];

  void _openAddExamDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New Exam Hierarchy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exam Name (e.g. BITSAT 2026)')),
              const SizedBox(height: 12),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Exam Code (e.g. BITSAT)')),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        setState(() {
                          _examsList.add({
                            'id': nameCtrl.text.toUpperCase().replaceAll(' ', '_'),
                            'name': nameCtrl.text,
                            'code': codeCtrl.text.toUpperCase(),
                            'status': 'Active',
                            'created': 'Today',
                            'updated': 'Today',
                            'subjectsCount': 0,
                            'chaptersCount': 0,
                            'topicsCount': 0,
                            'subtopicsCount': 0,
                            'icon': Icons.school_rounded,
                            'color': const Color(0xFF8B5CF6),
                          });
                        });
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameCtrl.text} hierarchy created!')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                    child: const Text('Add Exam'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddSubjectDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Subject to NEET UG', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Subject Name (e.g. Organic Chemistry)')),
              const SizedBox(height: 12),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Subject Code (e.g. ORG_CHEM)')),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        setState(() {
                          _subjects.add({
                            'name': nameCtrl.text,
                            'code': codeCtrl.text.toUpperCase(),
                            'chapters': '0 Chapters',
                            'topics': '0 Topics',
                            'subtopics': '0 Subtopics',
                            'status': 'Active',
                            'icon': Icons.menu_book_outlined,
                            'color': const Color(0xFF3B82F6),
                          });
                        });
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subject ${nameCtrl.text} added!')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                    child: const Text('Add Subject'),
                  ),
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final selectedExam = _examsList.firstWhere((e) => e['id'] == _selectedExamId, orElse: () => _examsList[0]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. LEFT DARK SIDEBAR NAVIGATION (#0B0F19)
          if (isDesktop) _buildAdminSidebar(),

          // 2. MAIN EXAM HIERARCHY CANVAS AREA
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
                        const SizedBox(height: 24),

                        // Top 5 Metrics Cards Row
                        _buildTopMetricsRow(),
                        const SizedBox(height: 24),

                        // Main 2-Column Content Layout (Left: Exam List + Overview, Right: Selected Exam Details & Table)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Section: Exam List + Hierarchy Donut Overview
                            SizedBox(
                              width: 320,
                              child: Column(
                                children: [
                                  _buildExamListCard(),
                                  const SizedBox(height: 20),
                                  _buildHierarchyOverviewCard(selectedExam),
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Right Section: Selected Exam Details + Sub-Tabs + Subjects Table
                            Expanded(
                              child: Column(
                                children: [
                                  _buildExamDetailHeaderCard(selectedExam),
                                  const SizedBox(height: 24),
                                  _buildBottomUtilityCardsRow(),
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
          // Logo & Title
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
                  child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
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

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarSectionLabel('MAIN NAVIGATION'),
                _buildSidebarTile('Overview & KPIs', Icons.dashboard_outlined, false),
                _buildSidebarTile('Question Bank', Icons.quiz_outlined, false),
                _buildSidebarTile('CSV Bulk Import', Icons.upload_file_outlined, false),
                _buildSidebarTile('Exam Hierarchy', Icons.account_tree_outlined, true),
                _buildSidebarTile('Tags & Topics', Icons.label_outline_rounded, false),
                _buildSidebarTile('PYQs & Papers', Icons.auto_stories_outlined, false),
                _buildSidebarTile('Mistake Book', Icons.menu_book_outlined, false),
                _buildSidebarTile('Bookmarks', Icons.bookmark_outline_rounded, false),
                _buildSidebarTile('Reported Questions', Icons.flag_outlined, false),
                _buildSidebarTile('User Management', Icons.people_outline_rounded, false),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('USERS & ROLES'),
                _buildSidebarTile('Users', Icons.person_outline, false),
                _buildSidebarTile('Roles & Permissions', Icons.security_outlined, false),
                _buildSidebarTile('Activity Logs', Icons.history_rounded, false),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('REPORTS & ANALYTICS'),
                _buildSidebarTile('Analytics Dashboard', Icons.bar_chart_rounded, false),
                _buildSidebarTile('Question Reports', Icons.assessment_outlined, false),
                _buildSidebarTile('Student Performance', Icons.insights_rounded, false),
                _buildSidebarTile('Leaderboard', Icons.emoji_events_outlined, false),

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

          // Bottom Floating Help Card
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
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View Docs →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),

          // User Footer Profile Tile
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

  Widget _buildSidebarTile(String title, IconData icon, bool isActive) {
    return InkWell(
      onTap: () {},
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
                child: const Icon(Icons.hub_rounded, color: Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 8),
              const Text('Cosmyra Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(width: 32),

          // Search Input Bar
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
                        hintText: 'Search exams, subjects, chapters, topics...',
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

          // Header Right Utilities
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
            Text('Dynamic Exam Hierarchy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 2),
            Text('Configure Exam → Subject → Chapter → Topic → Subtopic hierarchy dynamically.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF4F46E5)),
              label: const Text('Hierarchy Settings', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF4F46E5)),
              label: const Text('View as Tree', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _openAddExamDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Exam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

  // ================= 4. TOP 5 METRICS CARDS ROW =================
  Widget _buildTopMetricsRow() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Exams', '3', '+1 this month', Icons.school_outlined, const Color(0xFF8B5CF6))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Total Subjects', '9', '+2 this month', Icons.menu_book_outlined, const Color(0xFF10B981))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Total Chapters', '26', '+6 this month', Icons.description_outlined, const Color(0xFFF59E0B))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Total Topics', '128', '+18 this month', Icons.hub_outlined, const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Total Subtopics', '452', '+52 this month', Icons.format_list_bulleted_rounded, const Color(0xFF8B5CF6))),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String trend, IconData icon, Color color) {
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
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(trend, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ================= 5. EXAM LIST CARD =================
  Widget _buildExamListCard() {
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
          const Text('Exam List', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),

          // Search + Filter Input
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchExamQuery = v),
                          decoration: const InputDecoration(
                            hintText: 'Search exams...',
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
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(10),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: _openAddExamDialog,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(10),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Icon(Icons.add, size: 16, color: Color(0xFF4F46E5)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List Items
          ..._examsList.where((e) => e['name'].toString().toLowerCase().contains(_searchExamQuery.toLowerCase())).map((exam) {
            final isSelected = exam['id'] == _selectedExamId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                onTap: () => setState(() => _selectedExamId = exam['id']),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: (exam['color'] as Color).withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(exam['icon'] as IconData, color: exam['color'] as Color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exam['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text(exam['code'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Active', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.more_vert_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 8),

          // Bottom Dashed Add Exam Button
          InkWell(
            onTap: _openAddExamDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Color(0xFF4F46E5)),
                    SizedBox(width: 6),
                    Text('Add New Exam', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 6. HIERARCHY OVERVIEW CARD (DONUT CHART) =================
  Widget _buildHierarchyOverviewCard(Map<String, dynamic> selectedExam) {
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
          const Text('Hierarchy Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: [
                          PieChartSectionData(color: const Color(0xFF10B981), value: 4, radius: 12, showTitle: false),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 13, radius: 12, showTitle: false),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: 68, radius: 12, showTitle: false),
                          PieChartSectionData(color: const Color(0xFFFF6B6B), value: 234, radius: 12, showTitle: false),
                        ],
                      ),
                    ),
                    Center(
                      child: Text(
                        selectedExam['name'],
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewLegendItem('4 Subjects', const Color(0xFF10B981)),
                    const SizedBox(height: 6),
                    _buildOverviewLegendItem('${selectedExam['chaptersCount']} Chapters', const Color(0xFF3B82F6)),
                    const SizedBox(height: 6),
                    _buildOverviewLegendItem('${selectedExam['topicsCount']} Topics', const Color(0xFFF59E0B)),
                    const SizedBox(height: 6),
                    _buildOverviewLegendItem('${selectedExam['subtopicsCount']} Subtopics', const Color(0xFFFF6B6B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 14, color: Color(0xFF4F46E5)),
                  SizedBox(width: 6),
                  Text('View Full Hierarchy Stats', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      ],
    );
  }

  // ================= 7. SELECTED EXAM DETAIL HEADER CARD & SUBJECTS TABLE =================
  Widget _buildExamDetailHeaderCard(Map<String, dynamic> selectedExam) {
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
          // Header Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(selectedExam['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: Text(selectedExam['code'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Active', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4F46E5)),
                    label: const Text('Edit Exam', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.pause_circle_outline, size: 14, color: Colors.red),
                    label: const Text('Deactivate', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.all(10),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(Icons.more_vert_rounded, size: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Code: ${selectedExam['code']}  ·  Created on: ${selectedExam['created']}  ·  Last Updated: ${selectedExam['updated']}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Sub-Tabs Navigation
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              children: [
                _buildExamTab('Subjects (${_subjects.length})'),
                _buildExamTab('Chapters (${selectedExam['chaptersCount']})'),
                _buildExamTab('Topics (${selectedExam['topicsCount']})'),
                _buildExamTab('Subtopics (${selectedExam['subtopicsCount']})'),
                _buildExamTab('Settings'),
                _buildExamTab('Mapping'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subjects Table Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subjects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('Manage subjects under this exam', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.swap_vert_rounded, size: 14, color: Color(0xFF4F46E5)),
                    label: const Text('Reorder', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _openAddSubjectDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subjects Table Content
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFFF8FAFC),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('SUBJECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      Expanded(flex: 2, child: Text('CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      Expanded(flex: 2, child: Text('CHAPTERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      Expanded(flex: 2, child: Text('TOPICS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      Expanded(flex: 2, child: Text('SUBTOPICS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      Expanded(flex: 1, child: Text('ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Table Rows
                ..._subjects.map((subj) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: (subj['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                                    child: Icon(subj['icon'] as IconData, size: 14, color: subj['color'] as Color),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(subj['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                            Expanded(flex: 2, child: Text(subj['code'], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                            Expanded(flex: 2, child: Text(subj['chapters'], style: const TextStyle(fontSize: 11, color: Color(0xFF334155)))),
                            Expanded(flex: 2, child: Text(subj['topics'], style: const TextStyle(fontSize: 11, color: Color(0xFF334155)))),
                            Expanded(flex: 2, child: Text(subj['subtopics'], style: const TextStyle(fontSize: 11, color: Color(0xFF334155)))),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Active', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)), onPressed: () {}),
                                  IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red), onPressed: () {}),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Info Reorder Alert
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text(
                  'Drag and drop subjects to reorder them. Changes will be reflected across all levels.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF4338CA), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamTab(String label) {
    final isSelected = _activeTab == label;
    return InkWell(
      onTap: () => setState(() => _activeTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ================= 8. BOTTOM 3 UTILITY ACTION CARDS =================
  Widget _buildBottomUtilityCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildBottomUtilityCard(
            'Bulk Operations',
            'Import or export hierarchy data in bulk using CSV/Excel.',
            '📥 Bulk Import / Export',
            Icons.upload_file_outlined,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBottomUtilityCard(
            'Mapping Tools',
            'Map chapters, topics, or questions across exams.',
            '🔀 Open Mapping Tools',
            Icons.sync_rounded,
            const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBottomUtilityCard(
            'Validation & Health',
            'Check hierarchy integrity and find unused items.',
            '⚙ Run Validation',
            Icons.shield_outlined,
            const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomUtilityCard(String title, String subtitle, String btnLabel, IconData icon, Color color) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(btnLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
