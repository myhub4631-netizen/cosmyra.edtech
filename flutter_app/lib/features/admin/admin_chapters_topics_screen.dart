import 'package:flutter/material.dart';

class AdminChaptersTopicsScreen extends StatefulWidget {
  const AdminChaptersTopicsScreen({Key? key}) : super(key: key);

  @override
  State<AdminChaptersTopicsScreen> createState() => _AdminChaptersTopicsScreenState();
}

class _AdminChaptersTopicsScreenState extends State<AdminChaptersTopicsScreen> {
  String _selectedExam = 'NEET';
  String _selectedSubject = 'Physics';
  String _searchChapterQuery = '';
  String _selectedChapterForTopics = '1. Mechanics';

  final List<Map<String, dynamic>> _chaptersList = [
    {'name': '1. Mechanics', 'topics': 8, 'questions': 1248, 'status': 'Active'},
    {'name': '2. Thermodynamics', 'topics': 6, 'questions': 896, 'status': 'Active'},
    {'name': '3. Oscillations', 'topics': 5, 'questions': 642, 'status': 'Active'},
    {'name': '4. Waves', 'topics': 7, 'questions': 734, 'status': 'Active'},
    {'name': '5. Electromagnetism', 'topics': 12, 'questions': 1856, 'status': 'Active'},
    {'name': '6. Optics', 'topics': 9, 'questions': 1124, 'status': 'Inactive'},
    {'name': '7. Modern Physics', 'topics': 10, 'questions': 1346, 'status': 'Active'},
    {'name': '8. Dual Nature of Radiation and Matter', 'topics': 4, 'questions': 512, 'status': 'Active'},
  ];

  final List<Map<String, dynamic>> _topicsList = [
    {'name': '1.1 Units and Dimensions', 'questions': 156, 'status': 'Active'},
    {'name': '1.2 Kinematics', 'questions': 312, 'status': 'Active'},
    {'name': '1.3 Laws of Motion', 'questions': 298, 'status': 'Active'},
    {'name': '1.4 Friction', 'questions': 184, 'status': 'Active'},
    {'name': '1.5 Circular Motion', 'questions': 210, 'status': 'Active'},
    {'name': '1.6 Work, Power and Energy', 'questions': 246, 'status': 'Active'},
    {'name': '1.7 Centre of Mass', 'questions': 128, 'status': 'Active'},
    {'name': '1.8 Rigid Body Dynamics', 'questions': 114, 'status': 'Inactive'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredChapters = _searchChapterQuery.isEmpty
        ? _chaptersList
        : _chaptersList.where((c) => (c['name'] as String).toLowerCase().contains(_searchChapterQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. Dark Navy Admin Sidebar
          Container(
            width: 250,
            color: const Color(0xFF0B132B),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo & Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.school_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Cosmyra Edu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Admin Panel', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildSidebarItem(Icons.dashboard_outlined, 'Dashboard', false),
                      _buildSidebarItem(Icons.people_outline, 'Users Management', false),
                      _buildSidebarItem(Icons.menu_book_outlined, 'Courses', false),
                      _buildSidebarItem(Icons.assignment_outlined, 'Exams', false),
                      _buildSidebarItem(Icons.science_outlined, 'Subjects', false),
                      _buildSidebarItem(Icons.auto_stories_rounded, 'Chapters & Topics', true),
                      _buildSidebarItem(Icons.help_outline_rounded, 'Questions', false),
                      _buildSidebarItem(Icons.insert_drive_file_outlined, 'PYQ Papers', false),
                      _buildSidebarItem(Icons.timer_outlined, 'Test Series', false),
                      _buildSidebarItem(Icons.video_call_outlined, 'Live Classes', false),
                      _buildSidebarItem(Icons.analytics_outlined, 'Reports & Analytics', false),
                      _buildSidebarItem(Icons.notifications_none_rounded, 'Notifications', false),
                      _buildSidebarItem(Icons.confirmation_number_outlined, 'Support Tickets', false),
                      _buildSidebarItem(Icons.settings_outlined, 'System Settings', false),
                    ],
                  ),
                ),

                // User Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF7C3AED),
                        child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Admin User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Super Admin', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Admin Dashboard Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Chapters & Topics Management',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage chapters and topics across all exams and subjects',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Search Ctrl+K
                          Container(
                            width: 240,
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Search chapters or topics...', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.all(Radius.circular(4))),
                                  child: const Text('Ctrl + K', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Notification Icon Badge
                          Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 20),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Text('12', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Add Chapter Button
                          ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            label: const Text('Add Chapter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stat Cards (Top Row - 4 Cards)
                  Row(
                    children: [
                      _buildMetricCard(
                        icon: Icons.menu_book_rounded,
                        iconBg: const Color(0xFFEEF2FF),
                        iconColor: const Color(0xFF6366F1),
                        title: 'Total Chapters',
                        value: '324',
                        subtitle: 'Across all exams',
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        icon: Icons.style_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Total Topics',
                        value: '1,256',
                        subtitle: 'Across all chapters',
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        icon: Icons.check_circle_outline_rounded,
                        iconBg: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF10B981),
                        title: 'Active Chapters',
                        value: '298',
                        subtitle: '92.0% Active',
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        icon: Icons.grid_view_outlined,
                        iconBg: const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFF97316),
                        title: 'Active Topics',
                        value: '1,142',
                        subtitle: '90.9% Active',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Middle Section: 2 Side-by-Side Tables (Chapters & Topics)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Table: Chapters
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chapters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 14),

                              // Filters Bar
                              Row(
                                children: [
                                  // Exam Dropdown
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedExam,
                                        isDense: true,
                                        items: ['NEET', 'JEE Main', 'JEE Advanced'].map((e) {
                                          return DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedExam = val);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Subject Dropdown
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedSubject,
                                        isDense: true,
                                        items: ['Physics', 'Chemistry', 'Biology', 'Mathematics'].map((s) {
                                          return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedSubject = val);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Search Field
                                  Expanded(
                                    child: Container(
                                      height: 34,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: TextField(
                                              onChanged: (v) => setState(() => _searchChapterQuery = v),
                                              decoration: const InputDecoration(
                                                hintText: 'Search chapters...',
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
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Table Header
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2.5),
                                  1: FlexColumnWidth(1.0),
                                  2: FlexColumnWidth(1.2),
                                  3: FlexColumnWidth(1.0),
                                  4: FlexColumnWidth(1.0),
                                },
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                                    children: const [
                                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text('Chapter Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text('Topics', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text('Questions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                    ],
                                  ),
                                  ...filteredChapters.map((c) {
                                    final isActive = c['status'] == 'Active';
                                    final isSelected = c['name'] == _selectedChapterForTopics;
                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
                                        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                      ),
                                      children: [
                                        InkWell(
                                          onTap: () => setState(() => _selectedChapterForTopics = c['name']),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                            child: Text(c['name'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF0F172A))),
                                          ),
                                        ),
                                        Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text('${c['topics']}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                        Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text('${c['questions']}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              c['status'],
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF16A34A) : const Color(0xFFE11D48)),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                          child: Row(
                                            children: const [
                                              Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                                              SizedBox(width: 6),
                                              Icon(Icons.more_vert, size: 16, color: Color(0xFF64748B)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Right Table: Topics in Selected Chapter
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                                  Text(
                                    'Topics in: Mechanics',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                    label: const Text('Add Topic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Table Header
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2.5),
                                  1: FlexColumnWidth(1.2),
                                  2: FlexColumnWidth(1.0),
                                  3: FlexColumnWidth(1.0),
                                },
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                                    children: const [
                                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text('Topic Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text('Questions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                    ],
                                  ),
                                  ..._topicsList.map((t) {
                                    final isActive = t['status'] == 'Active';
                                    return TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                      ),
                                      children: [
                                        Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text(t['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                                        Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text('${t['questions']}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              t['status'],
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF16A34A) : const Color(0xFFE11D48)),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                          child: Row(
                                            children: const [
                                              Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                                              SizedBox(width: 6),
                                              Icon(Icons.more_vert, size: 16, color: Color(0xFF64748B)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bottom Section: Hierarchy View Node Diagram & Quick Actions Card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Node Diagram Panel
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                                  Row(
                                    children: const [
                                      Icon(Icons.account_tree_outlined, color: Color(0xFF6366F1), size: 20),
                                      SizedBox(width: 8),
                                      Text('Hierarchy View', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                                  Row(
                                    children: const [
                                      Text('NEET → Physics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildNodeItem('1. Mechanics', '8 Topics', true),
                                    _buildNodeArrow(),
                                    _buildNodeItem('2. Thermodynamics', '6 Topics', false),
                                    _buildNodeArrow(),
                                    _buildNodeItem('3. Oscillations', '5 Topics', false),
                                    _buildNodeArrow(),
                                    _buildNodeItem('4. Waves', '7 Topics', false),
                                    _buildNodeArrow(),
                                    _buildNodeItem('5. Electromagnetism', '12 Topics', false),
                                    _buildNodeArrow(),
                                    _buildNodeItem('6. Optics', '9 Topics', false),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Quick Actions Card
                      Container(
                        width: 240,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 14),
                            _buildQuickActionButton(Icons.add, 'Add New Chapter'),
                            const SizedBox(height: 8),
                            _buildQuickActionButton(Icons.add, 'Add New Topic'),
                            const SizedBox(height: 8),
                            _buildQuickActionButton(Icons.file_upload_outlined, 'Import Chapters/Topics'),
                            const SizedBox(height: 8),
                            _buildQuickActionButton(Icons.file_download_outlined, 'Export Chapters/Topics'),
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
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isActive ? Colors.white : const Color(0xFF94A3B8), size: 18),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeItem(String title, String subtitle, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildNodeArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFFCBD5E1)),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16, color: const Color(0xFF6366F1)),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
