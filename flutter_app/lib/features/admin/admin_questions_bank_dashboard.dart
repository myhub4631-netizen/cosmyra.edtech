import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/latex_view.dart';
import 'admin_question_builder_screen.dart';
import 'admin_pdf_import_screen.dart';

class AdminQuestionsBankDashboard extends StatefulWidget {
  final UserProfileModel userProfile;
  final VoidCallback? onBack;

  const AdminQuestionsBankDashboard({
    Key? key,
    required this.userProfile,
    this.onBack,
  }) : super(key: key);

  @override
  State<AdminQuestionsBankDashboard> createState() => _AdminQuestionsBankDashboardState();
}

class _AdminQuestionsBankDashboardState extends State<AdminQuestionsBankDashboard> {
  int _activeCategoryTab = 0; // 0 = All Questions, 1 = Custom Practice, 2 = Custom Test, 3 = PYQ Practice, 4 = NTA Questions, 5 = Mock Tests
  String _searchQuery = '';
  String _selectedExam = 'NEET 2026';
  String _selectedSubject = 'All Subjects';
  String _selectedChapter = 'All Chapters';
  String _selectedType = 'All Types';
  String _selectedStatus = 'All Status';

  bool _isSidebarCollapsed = false;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final Set<String> _selectedQuestionIds = {};

  final List<Map<String, dynamic>> _allQuestionsData = [
    {
      'id': 'Q125678',
      'questionText': 'The velocity-time graph of a particle moving in a straight line is shown below...',
      'category': 'Custom Practice',
      'categoryColor': const Color(0xFFEEF2FF),
      'categoryTextColor': const Color(0xFF4F46E5),
      'subject': 'Physics',
      'chapter': '1. Mechanics',
      'topic': 'Kinematics',
      'type': 'MCQ',
      'marks': 4,
      'status': 'Active',
      'usedIn': 12,
    },
    {
      'id': 'Q125677',
      'questionText': 'Two bodies A and B of masses 2m and m are connected by a light string...',
      'category': 'Custom Test',
      'categoryColor': const Color(0xFFDBEAFE),
      'categoryTextColor': const Color(0xFF2563EB),
      'subject': 'Physics',
      'chapter': '2. Thermodynamics',
      'topic': 'Thermal Properties',
      'type': 'MCQ',
      'marks': 4,
      'status': 'Active',
      'usedIn': 8,
    },
    {
      'id': 'Q125676',
      'questionText': r'If y = \sin^{-1}\left(\frac{2x}{1+x^2}\right), \text{ then } \frac{dy}{dx} \text{ is equal to?}',
      'category': 'PYQ Practice',
      'categoryColor': const Color(0xFFDCFCE7),
      'categoryTextColor': const Color(0xFF16A34A),
      'subject': 'Mathematics',
      'chapter': '3. Trigonometry',
      'topic': 'Inverse Trigonometric Functions',
      'type': 'MCQ',
      'marks': 4,
      'status': 'Active',
      'usedIn': 15,
    },
    {
      'id': 'Q125675',
      'questionText': 'Match List-I with List-II regarding chemical stoichiometry.',
      'category': 'NTA Question',
      'categoryColor': const Color(0xFFFFEDD5),
      'categoryTextColor': const Color(0xFFEA580C),
      'subject': 'Chemistry',
      'chapter': '1. Some Basic Concepts',
      'topic': 'Mole Concept',
      'type': 'Match',
      'marks': 4,
      'status': 'Active',
      'usedIn': 24,
    },
    {
      'id': 'Q125674',
      'questionText': 'Which of the following is not a primary organelle in eukaryotic cells?',
      'category': 'NTA Question',
      'categoryColor': const Color(0xFFFFEDD5),
      'categoryTextColor': const Color(0xFFEA580C),
      'subject': 'Biology',
      'chapter': '2. Cell: The Unit of Life',
      'topic': 'Cell Organelles',
      'type': 'MCQ',
      'marks': 4,
      'status': 'Active',
      'usedIn': 18,
    },
    {
      'id': 'Q125673',
      'questionText': 'Consider the following statements regarding Kirchhoff\'s current law.',
      'category': 'Mock Test',
      'categoryColor': const Color(0xFFFCE7F3),
      'categoryTextColor': const Color(0xFFDB2777),
      'subject': 'Physics',
      'chapter': '4. Electromagnetism',
      'topic': 'Current Electricity',
      'type': 'Assertion',
      'marks': 4,
      'status': 'Active',
      'usedIn': 30,
    },
    {
      'id': 'Q125672',
      'questionText': 'A hydrogen-like atom in the ground state absorbs a photon of energy...',
      'category': 'Mock Test',
      'categoryColor': const Color(0xFFFCE7F3),
      'categoryTextColor': const Color(0xFFDB2777),
      'subject': 'Physics',
      'chapter': '5. Modern Physics',
      'topic': 'Atomic Structure',
      'type': 'MCQ',
      'marks': 4,
      'status': 'Active',
      'usedIn': 22,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSupabaseQuestions();
  }

  Future<void> _loadSupabaseQuestions() async {
    try {
      final dbQuestions = await SupabaseService.fetchAllQuestionsFromSupabase();
      if (dbQuestions.isNotEmpty && mounted) {
        setState(() {
          for (var q in dbQuestions) {
            final idx = _allQuestionsData.indexWhere((item) => item['id'] == q['id']);
            if (idx != -1) {
              _allQuestionsData[idx] = q;
            } else {
              _allQuestionsData.insert(0, {
                'id': q['id'] ?? 'Q_${_allQuestionsData.length + 1}',
                'questionText': q['questionText'] ?? q['question_text'] ?? '',
                'category': q['category'] ?? 'Custom Practice',
                'categoryColor': const Color(0xFFEEF2FF),
                'categoryTextColor': const Color(0xFF4F46E5),
                'subject': q['subject'] ?? 'Physics',
                'chapter': q['chapter'] ?? '1. Mechanics',
                'topic': q['topic'] ?? 'General',
                'type': q['type'] ?? 'MCQ',
                'marks': q['marks'] ?? 4,
                'status': 'Active',
                'usedIn': q['usedIn'] ?? 10,
              });
            }
          }
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredQuestions {
    final catTabs = ['All', 'Custom Practice', 'Custom Test', 'PYQ Practice', 'NTA Question', 'Mock Test'];
    final activeTabName = catTabs[_activeCategoryTab];

    return _allQuestionsData.where((q) {
      // Category Tab Filter
      if (activeTabName != 'All') {
        final cat = (q['category'] ?? '').toString();
        if (!cat.toLowerCase().contains(activeTabName.toLowerCase())) return false;
      }

      // Subject Filter
      if (_selectedSubject != 'All Subjects' && q['subject'] != _selectedSubject) {
        return false;
      }

      // Type Filter
      if (_selectedType != 'All Types' && q['type'] != _selectedType) {
        return false;
      }

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final qText = (q['questionText'] ?? '').toString().toLowerCase();
        final qId = (q['id'] ?? '').toString().toLowerCase();
        final qChapter = (q['chapter'] ?? '').toString().toLowerCase();
        final sLower = _searchQuery.toLowerCase();
        if (!qText.contains(sLower) && !qId.contains(sLower) && !qChapter.contains(sLower)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _openAddQuestionDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AdminQuestionBuilderScreen(
          userProfile: widget.userProfile,
          onBack: () {
            Navigator.pop(ctx);
            _loadSupabaseQuestions();
          },
        ),
      ),
    );
  }

  void _openImportPdfDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AdminPdfImportScreen(
          userProfile: widget.userProfile,
          onBack: () {
            Navigator.pop(ctx);
            _loadSupabaseQuestions();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LEFT SIDEBAR NAVIGATION
          _buildSidebar(),

          // 2. MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                _buildTopAppBar(),

                // Scrollable Content Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header Title & Buttons
                        _buildPageHeader(),

                        const SizedBox(height: 20),

                        // 5 Stat Metric Cards Row
                        _buildStatCardsRow(),

                        const SizedBox(height: 24),

                        // Category Sub-Navigation Tabs Bar
                        _buildCategoryTabsBar(),

                        const SizedBox(height: 18),

                        // Filter Toolbar
                        _buildFilterToolbar(),

                        const SizedBox(height: 16),

                        // Questions Data Table
                        _buildQuestionsDataTable(),

                        const SizedBox(height: 16),

                        // Table Pagination Footer
                        _buildPaginationFooter(),

                        const SizedBox(height: 30),
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

  // ==========================================
  // 1. LEFT SIDEBAR NAVIGATION
  // ==========================================
  Widget _buildSidebar() {
    return Container(
      width: _isSidebarCollapsed ? 70 : 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        children: [
          // Logo Bar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'Cosmyra Edu Admin',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _buildSidebarItem(Icons.dashboard_outlined, 'Dashboard', false, onTap: () {
                  Navigator.pushReplacementNamed(context, '/admin');
                }),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('CONTENT MANAGEMENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.assignment_outlined, 'Exams', false),
                _buildSidebarItem(Icons.science_outlined, 'Subjects', false),
                _buildSidebarItem(Icons.menu_book_outlined, 'Chapters', false, onTap: () {
                  Navigator.pushReplacementNamed(context, '/admin/chapters');
                }),
                _buildSidebarItem(Icons.grid_view_rounded, 'Topics', false, onTap: () {
                  Navigator.pushReplacementNamed(context, '/admin/chapters');
                }),
                _buildSidebarItem(Icons.help_outline_rounded, 'Questions', true),
                _buildSidebarItem(Icons.description_outlined, 'NTA Mock Papers', false),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('PRACTICE & TEST', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.edit_note_rounded, 'Custom Practice', false),
                _buildSidebarItem(Icons.assignment_turned_in_outlined, 'Custom Tests', false),
                _buildSidebarItem(Icons.history_edu_rounded, 'PYQ Practice', false),
                _buildSidebarItem(Icons.quiz_outlined, 'Mock Tests', false),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('TEST MANAGEMENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.fact_check_outlined, 'Test Attempts', false),
                _buildSidebarItem(Icons.analytics_outlined, 'Analytics', false),
                _buildSidebarItem(Icons.insert_chart_outlined_rounded, 'Reports', false),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('USER MANAGEMENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.people_outline, 'Users', false, onTap: () {
                  Navigator.pushReplacementNamed(context, '/admin/users');
                }),
                _buildSidebarItem(Icons.admin_panel_settings_outlined, 'Roles & Permissions', false),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('OTHER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.settings_outlined, 'Settings', false),
                _buildSidebarItem(Icons.receipt_long_outlined, 'Logs', false),
                _buildSidebarItem(Icons.help_outline, 'Help & Support', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isSelected, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          icon,
          size: 19,
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
        ),
        title: _isSidebarCollapsed
            ? null
            : Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                ),
              ),
        onTap: onTap ?? () {},
      ),
    );
  }

  // ==========================================
  // TOP APP BAR
  // ==========================================
  Widget _buildTopAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              _isSidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: const Color(0xFF64748B),
              size: 22,
            ),
            onPressed: () {
              setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
            },
          ),
          Row(
            children: [
              // Notification Bell
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 22),
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
                      child: const Text(
                        '12',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Admin User Profile Avatar
              Row(
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.person_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Admin User',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Super Admin',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
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

  // ==========================================
  // PAGE HEADER (TITLE & BUTTONS)
  // ==========================================
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Dashboard  >  Questions',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        Row(
          children: [
            // + Add Question Button
            ElevatedButton.icon(
              onPressed: _openAddQuestionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: Row(
                children: const [
                  Text('Add Question', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Import Questions Button
            OutlinedButton.icon(
              onPressed: _openImportPdfDialog,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.upload_outlined, color: Color(0xFF334155), size: 18),
              label: const Text(
                'Import Questions',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 5 STAT CARDS ROW
  // ==========================================
  Widget _buildStatCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricStatCard(
            title: 'Total Questions',
            value: '24,856',
            footer: 'All Categories',
            footerColor: const Color(0xFF64748B),
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFF3E8FF),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricStatCard(
            title: 'Active Questions',
            value: '23,742',
            footer: '95.52% of Total',
            footerColor: const Color(0xFF16A34A),
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFDCFCE7),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricStatCard(
            title: 'Used in Tests',
            value: '18,562',
            footer: '74.72% of Total',
            footerColor: const Color(0xFFEA580C),
            icon: Icons.visibility_outlined,
            iconColor: const Color(0xFFEA580C),
            iconBg: const Color(0xFFFFEDD5),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricStatCard(
            title: 'Inactive Questions',
            value: '1,114',
            footer: '4.48% of Total',
            footerColor: const Color(0xFFEF4444),
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEE2E2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricStatCard(
            title: 'Total Marks',
            value: '248,560',
            footer: 'Across All Questions',
            footerColor: const Color(0xFF64748B),
            icon: Icons.local_offer_outlined,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricStatCard({
    required String title,
    required String value,
    required String footer,
    required Color footerColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  footer,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: footerColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CATEGORY SUB-NAVIGATION TABS BAR
  // ==========================================
  Widget _buildCategoryTabsBar() {
    final tabs = [
      'All Questions',
      'Custom Practice',
      'Custom Test',
      'PYQ Practice',
      'NTA Questions',
      'Mock Tests',
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final label = entry.value;
          final isSel = _activeCategoryTab == idx;

          return InkWell(
            onTap: () => setState(() => _activeCategoryTab = idx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSel ? const Color(0xFF4F46E5) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
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

  // ==========================================
  // FILTER TOOLBAR
  // ==========================================
  Widget _buildFilterToolbar() {
    return Row(
      children: [
        // Search Input Box
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by question, topic or ID...',
                      hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Exam Dropdown
        _buildDropdownFilter('Exam', _selectedExam, ['NEET 2026', 'NEET 2025', 'JEE Main 2026'], (v) {
          setState(() => _selectedExam = v!);
        }),
        const SizedBox(width: 10),

        // Subject Dropdown
        _buildDropdownFilter('Subject', _selectedSubject, ['All Subjects', 'Physics', 'Chemistry', 'Biology', 'Mathematics'], (v) {
          setState(() => _selectedSubject = v!);
        }),
        const SizedBox(width: 10),

        // Chapter Dropdown
        _buildDropdownFilter('Chapter', _selectedChapter, ['All Chapters', '1. Mechanics', '2. Thermodynamics', '3. Trigonometry'], (v) {
          setState(() => _selectedChapter = v!);
        }),
        const SizedBox(width: 10),

        // Question Type Dropdown
        _buildDropdownFilter('Question Type', _selectedType, ['All Types', 'MCQ', 'Match', 'Assertion'], (v) {
          setState(() => _selectedType = v!);
        }),
        const SizedBox(width: 10),

        // Status Dropdown
        _buildDropdownFilter('Status', _selectedStatus, ['All Status', 'Active', 'Inactive'], (v) {
          setState(() => _selectedStatus = v!);
        }),
        const SizedBox(width: 10),

        // Reset Button
        OutlinedButton(
          onPressed: () {
            setState(() {
              _searchQuery = '';
              _selectedExam = 'NEET 2026';
              _selectedSubject = 'All Subjects';
              _selectedChapter = 'All Chapters';
              _selectedType = 'All Types';
              _selectedStatus = 'All Status';
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Reset', style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),

        // Filters Button
        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEEF2FF),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF4F46E5), size: 16),
          label: const Text('Filters', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          onChanged: onChanged,
          items: items.map((i) {
            return DropdownMenuItem<String>(
              value: i,
              child: Text(i),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // QUESTIONS DATA TABLE
  // ==========================================
  Widget _buildQuestionsDataTable() {
    final questions = _filteredQuestions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowHeight: 64,
          headingRowHeight: 46,
          horizontalMargin: 16,
          columnSpacing: 18,
          columns: const [
            DataColumn(label: SizedBox(width: 24, child: Checkbox(value: false, onChanged: null))),
            DataColumn(label: Text('ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            DataColumn(label: Text('Question', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            DataColumn(label: Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            DataColumn(label: Text('Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            DataColumn(label: Text('Chapter / Topic', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            DataColumn(label: Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            DataColumn(label: Text('Marks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            DataColumn(label: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            DataColumn(label: Text('Used In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            DataColumn(label: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
          ],
          rows: questions.map((q) {
            final qId = q['id'].toString();
            final isChecked = _selectedQuestionIds.contains(qId);

            return DataRow(
              cells: [
                DataCell(
                  Checkbox(
                    value: isChecked,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedQuestionIds.add(qId);
                        } else {
                          _selectedQuestionIds.remove(qId);
                        }
                      });
                    },
                  ),
                ),
                DataCell(
                  Text(
                    qId,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 240,
                    child: LaTeXView(
                      text: q['questionText'] ?? '',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: q['categoryColor'] ?? const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      q['category'] ?? 'Custom Practice',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: q['categoryTextColor'] ?? const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    q['subject'] ?? 'Physics',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q['chapter'] ?? '',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        q['topic'] ?? '',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    q['type'] ?? 'MCQ',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
                DataCell(
                  Text(
                    '${q['marks'] ?? 4}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${q['usedIn'] ?? 10}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF2563EB)),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF7C3AED)),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.content_copy_outlined, size: 16, color: Color(0xFF475569)),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // TABLE PAGINATION FOOTER
  // ==========================================
  Widget _buildPaginationFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Showing 1 to 10 of 24,856 questions',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        Row(
          children: [
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _itemsPerPage,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  onChanged: (v) {
                    if (v != null) setState(() => _itemsPerPage = v);
                  },
                  items: [10, 25, 50, 100].map((count) {
                    return DropdownMenuItem<int>(
                      value: count,
                      child: Text('$count / page'),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Pagination Buttons
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF94A3B8)),
              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            _buildPageNumBtn(1, true),
            _buildPageNumBtn(2, false),
            _buildPageNumBtn(3, false),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('...', style: TextStyle(color: Color(0xFF64748B))),
            ),
            _buildPageNumBtn(2486, false),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF0F172A)),
              onPressed: () => setState(() => _currentPage++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageNumBtn(int pageNum, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          '$pageNum',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
