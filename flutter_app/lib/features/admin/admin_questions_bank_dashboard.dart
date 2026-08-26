import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/latex_view.dart';
import '../../shared/utils/smooth_page_route.dart';
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
  @override
  void initState() {
    super.initState();
    _loadSavedCustomQuestions();
  }

  Future<void> _loadSavedCustomQuestions() async {
    try {
      // 1. Seed & Sync all 20 real questions to Supabase
      SupabaseService.seedRealQuestionsToSupabase();

      // 2. Fetch from Supabase questions table
      final supabaseQs = await SupabaseService.fetchAllQuestionsFromSupabase();
      for (var q in supabaseQs) {
        final existingIdx = _sharedQuestionsBankList.indexWhere((item) => item['id'] == q['id']);
        if (existingIdx != -1) {
          _sharedQuestionsBankList[existingIdx] = q;
        } else {
          _sharedQuestionsBankList.insert(0, q);
        }
      }

      // 3. Fetch from SharedPreferences local storage
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cosmyra_saved_custom_questions');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final List<Map<String, dynamic>> savedQuestions =
            decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        for (var q in savedQuestions) {
          final existingIdx = _sharedQuestionsBankList.indexWhere((item) => item['id'] == q['id']);
          if (existingIdx != -1) {
            _sharedQuestionsBankList[existingIdx] = q;
          } else {
            _sharedQuestionsBankList.insert(0, q);
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading saved questions: $e');
    }
  }

  // Sidebar state
  String _activeSidebarNav = 'Questions Bank';
  String _activeSubNav = 'All Questions';
  bool _isSidebarCollapsed = false;

  // Filter & Search states
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSubjectFilter = 'All Subjects';
  String _selectedChapterFilter = 'All Chapters';
  String _selectedSourceFilter = 'All Source Types';
  String _selectedDifficultyFilter = 'All Difficulty';

  // Table selection & pagination
  final Set<String> _selectedQuestionIds = {};
  int _currentPage = 1;
  int _rowsPerPage = 10;

  // Question list state (shared across navigation)
  static final List<Map<String, dynamic>> _sharedQuestionsBankList = SupabaseService.get20RealQuestionsMap();

  List<Map<String, dynamic>> get _questionsList => _sharedQuestionsBankList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LEFT SIDEBAR NAVIGATION (Dark Navy #0D1127)
          _buildSidebar(),

          // 2. MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // TOP APP BAR
                _buildTopAppBar(),

                // MAIN DASHBOARD BODY (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Title & Header Actions
                        _buildPageHeader(),

                        const SizedBox(height: 20),

                        // 6 Stat Summary Cards Row
                        _buildStatCardsRow(),

                        const SizedBox(height: 20),

                        // Analytics Donut Chart & Used In Grid Row
                        _buildAnalyticsRow(),

                        const SizedBox(height: 20),

                        // Filter & Search Bar
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
  // 1. DARK NAVY SIDEBAR NAVIGATION (#0D1127)
  // ==========================================
  Widget _buildSidebar() {
    return Container(
      width: _isSidebarCollapsed ? 70 : 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Column(
        children: [
          // Logo Header
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(79, 70, 229, 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Cosmyra Edu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Nav Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildSidebarNavItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isGroupHeader: false,
                ),
                _buildSidebarNavItem(
                  icon: Icons.people_outline_rounded,
                  title: 'Users',
                  hasTrailingChevron: true,
                ),
                const SizedBox(height: 16),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'CONTENT MANAGEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                // Active Item: Questions Bank
                _buildSidebarActiveItem(
                  icon: Icons.quiz_outlined,
                  title: 'Questions Bank',
                  subItems: [
                    'All Questions',
                    'Add New Question',
                    'Import Questions',
                    'PDF Import',
                    'Bulk Import',
                    'Question Tags',
                    'Question Sets',
                  ],
                ),

                _buildSidebarNavItem(
                  icon: Icons.assignment_outlined,
                  title: 'Test Management',
                  hasTrailingChevron: true,
                ),
                _buildSidebarNavItem(
                  icon: Icons.fitness_center_outlined,
                  title: 'Practice',
                  hasTrailingChevron: true,
                ),
                _buildSidebarNavItem(
                  icon: Icons.history_edu_outlined,
                  title: 'PYQ',
                  hasTrailingChevron: true,
                ),
                _buildSidebarNavItem(
                  icon: Icons.description_outlined,
                  title: 'NTA Practice',
                  hasTrailingChevron: true,
                ),
                _buildSidebarNavItem(
                  icon: Icons.menu_book_outlined,
                  title: 'Study Material',
                  hasTrailingChevron: true,
                ),

                const SizedBox(height: 16),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'ANALYTICS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                _buildSidebarNavItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Analytics',
                ),
                _buildSidebarNavItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Reports',
                ),

                const SizedBox(height: 16),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'SYSTEM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                _buildSidebarNavItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                ),
                _buildSidebarNavItem(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Roles & Permissions',
                ),
                _buildSidebarNavItem(
                  icon: Icons.list_alt_rounded,
                  title: 'Logs',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String title,
    bool isGroupHeader = false,
    bool hasTrailingChevron = false,
  }) {
    final bool isActive = _activeSidebarNav == title;
    return InkWell(
      onTap: () {
        setState(() => _activeSidebarNav = title);
        if (title == 'Dashboard') {
          if (widget.onBack != null) {
            widget.onBack!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
            ),
            if (!_isSidebarCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              if (hasTrailingChevron)
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarActiveItem({
    required IconData icon,
    required String title,
    required List<String> subItems,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(79, 70, 229, 0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.white),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
              ],
            ],
          ),
        ),

        if (!_isSidebarCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subItems.map((item) {
                final bool isSubActive = _activeSubNav == item;
                return InkWell(
                  onTap: () {
                    setState(() => _activeSubNav = item);
                    if (item == 'Add Question' || item == 'Add New Question') _openAddQuestionDialog();
                    if (item == 'Import Questions' || item == 'PDF Import') {
                      Navigator.push(
                        context,
                        SmoothPageRoute(
                          child: AdminPdfImportScreen(userProfile: widget.userProfile),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSubActive ? FontWeight.w700 : FontWeight.w400,
                        color: isSubActive ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // 2. TOP APPLICATION APP BAR
  // ==========================================
  Widget _buildTopAppBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 16),

          // Search Input Box
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Notification Bell
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 24),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '8',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // User Profile Avatar
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF4F46E5),
                child: Text(
                  widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName[0].toUpperCase() : 'A',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName : 'Admin',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const Text(
                    'Super Admin',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
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
  // 3. PAGE HEADER & TOP ACTION BUTTONS
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
              'Questions Bank',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage, upload and organize questions for all practice and test modules.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),

        Row(
          children: [
            // Question Import Button
            OutlinedButton.icon(
              onPressed: _openImportQuestionsDialog,
              icon: const Icon(Icons.file_download_outlined, size: 18, color: Color(0xFF4F46E5)),
              label: const Text(
                'Question Import',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(width: 12),

            // + Add New Question Button
            ElevatedButton.icon(
              onPressed: _openAddQuestionDialog,
              icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
              label: const Text(
                'Add New Question',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                backgroundColor: const Color(0xFF4F46E5),
                elevation: 2,
                shadowColor: const Color.fromRGBO(79, 70, 229, 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 4. 6 STAT SUMMARY CARDS ROW
  // ==========================================
  Widget _buildStatCardsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - (5 * 12)) / 6;
        return Row(
          children: [
            _buildSingleStatCard(
              width: cardWidth,
              title: 'Total Questions',
              count: '1,24,560',
              trend: '+ 12.5% from last month',
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              icon: Icons.assignment_outlined,
              chartColor: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 12),
            _buildSingleStatCard(
              width: cardWidth,
              title: 'NTA Questions',
              count: '28,540',
              trend: '+ 8.3% from last month',
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              icon: Icons.event_note_outlined,
              chartColor: const Color(0xFF22C55E),
            ),
            const SizedBox(width: 12),
            _buildSingleStatCard(
              width: cardWidth,
              title: 'PYQ Questions',
              count: '46,780',
              trend: '+ 15.2% from last month',
              iconBg: const Color(0xFFFFEDD5),
              iconColor: const Color(0xFFEA580C),
              icon: Icons.school_outlined,
              chartColor: const Color(0xFFF97316),
            ),
            const SizedBox(width: 12),
            _buildSingleStatCard(
              width: cardWidth,
              title: 'NCERT Questions',
              count: '18,950',
              trend: '+ 7.1% from last month',
              iconBg: const Color(0xFFE0F2FE),
              iconColor: const Color(0xFF0284C7),
              icon: Icons.menu_book_outlined,
              chartColor: const Color(0xFF0EA5E9),
            ),
            const SizedBox(width: 12),
            _buildSingleStatCard(
              width: cardWidth,
              title: 'Practice Questions',
              count: '25,380',
              trend: '+ 10.4% from last month',
              iconBg: const Color(0xFFFCE7F3),
              iconColor: const Color(0xFFDB2777),
              icon: Icons.track_changes_rounded,
              chartColor: const Color(0xFFEC4899),
            ),
            const SizedBox(width: 12),
            _buildSingleStatCard(
              width: cardWidth,
              title: 'Other Questions',
              count: '4,910',
              trend: '+ 5.6% from last month',
              iconBg: const Color(0xFFCCFBF1),
              iconColor: const Color(0xFF0D9488),
              icon: Icons.more_horiz_rounded,
              chartColor: const Color(0xFF14B8A6),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleStatCard({
    required double width,
    required String title,
    required String count,
    required String trend,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required Color chartColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                trend.split(' ')[0] + ' ' + trend.split(' ')[1],
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'from last month',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mini Sparkline Graphic
          SizedBox(
            height: 20,
            child: CustomPaint(
              size: Size(width, 20),
              painter: SparklinePainter(color: chartColor),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. ANALYTICS & USED IN MODULES ROW
  // ==========================================
  Widget _buildAnalyticsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Questions by Source Type Donut Chart
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.02),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Questions by Source Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Donut Chart
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 46,
                              sections: [
                                PieChartSectionData(color: const Color(0xFF4F46E5), value: 22.9, radius: 18, showTitle: false),
                                PieChartSectionData(color: const Color(0xFFF97316), value: 37.6, radius: 18, showTitle: false),
                                PieChartSectionData(color: const Color(0xFF0EA5E9), value: 15.2, radius: 18, showTitle: false),
                                PieChartSectionData(color: const Color(0xFFEC4899), value: 20.4, radius: 18, showTitle: false),
                                PieChartSectionData(color: const Color(0xFF14B8A6), value: 3.9, radius: 18, showTitle: false),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                '1,24,560',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'Total',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Donut Chart Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendRow(const Color(0xFF4F46E5), 'NTA Questions', '28,540 (22.9%)'),
                          const SizedBox(height: 8),
                          _buildLegendRow(const Color(0xFFF97316), 'PYQ Questions', '46,780 (37.6%)'),
                          const SizedBox(height: 8),
                          _buildLegendRow(const Color(0xFF0EA5E9), 'NCERT Questions', '18,950 (15.2%)'),
                          const SizedBox(height: 8),
                          _buildLegendRow(const Color(0xFFEC4899), 'Practice Questions', '25,380 (20.4%)'),
                          const SizedBox(height: 8),
                          _buildLegendRow(const Color(0xFF14B8A6), 'Other Questions', '4,910 (3.9%)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Right: Used In Module Cards
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.02),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Used In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'These questions are used across the platform in:',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildUsedInCard('Custom Practice', Icons.track_changes_rounded, const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
                    _buildUsedInCard('Custom Test', Icons.assignment_turned_in_outlined, const Color(0xFFF0F9FF), const Color(0xFF0284C7)),
                    _buildUsedInCard('PYQ Practice', Icons.event_note_outlined, const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
                    _buildUsedInCard('NTA Question Practice', Icons.font_download_outlined, const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
                    _buildUsedInCard('Test Series', Icons.format_list_numbered_rounded, const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildUsedInCard(String title, IconData icon, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. FILTER & SEARCH TOOLBAR BAR
  // ==========================================
  Widget _buildFilterToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Search Box
          Expanded(
            flex: 3,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  hintText: 'Search by question, chapter, subject, tags...',
                  hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Dropdown 1: All Subjects
          _buildFilterDropdown(
            value: _selectedSubjectFilter,
            items: ['All Subjects', 'Physics', 'Chemistry', 'Biology', 'Mathematics'],
            onChanged: (val) => setState(() => _selectedSubjectFilter = val!),
          ),

          const SizedBox(width: 10),

          // Dropdown 2: All Chapters
          _buildFilterDropdown(
            value: _selectedChapterFilter,
            items: ['All Chapters', 'Laws of Motion', 'Units and Measurements', 'States of Matter', 'Photosynthesis', 'Solutions'],
            onChanged: (val) => setState(() => _selectedChapterFilter = val!),
          ),

          const SizedBox(width: 10),

          // Dropdown 3: All Source Types
          _buildFilterDropdown(
            value: _selectedSourceFilter,
            items: ['All Source Types', 'NTA', 'PYQ', 'NCERT', 'Practice', 'Other'],
            onChanged: (val) => setState(() => _selectedSourceFilter = val!),
          ),

          const SizedBox(width: 10),

          // Dropdown 4: All Difficulty
          _buildFilterDropdown(
            value: _selectedDifficultyFilter,
            items: ['All Difficulty', 'Easy', 'Medium', 'Hard'],
            onChanged: (val) => setState(() => _selectedDifficultyFilter = val!),
          ),

          const SizedBox(width: 10),

          // Action: More Filters
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF4F46E5)),
            label: const Text('More Filters', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(width: 8),

          // Action: Reset
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedSubjectFilter = 'All Subjects';
                _selectedChapterFilter = 'All Chapters';
                _selectedSourceFilter = 'All Source Types';
                _selectedDifficultyFilter = 'All Difficulty';
              });
            },
            child: const Text('Reset', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
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
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // 7. QUESTIONS DATA TABLE
  // ==========================================
  Widget _buildQuestionsDataTable() {
    final filtered = _questionsList.where((q) {
      if (_searchQuery.isNotEmpty) {
        final qry = _searchQuery.toLowerCase();
        final textMatches = (q['questionText'] as String).toLowerCase().contains(qry);
        final tagMatches = (q['tags'] as List).any((t) => (t as String).toLowerCase().contains(qry));
        if (!textMatches && !tagMatches) return false;
      }
      if (_selectedSubjectFilter != 'All Subjects' && q['subject'] != _selectedSubjectFilter) return false;
      if (_selectedChapterFilter != 'All Chapters' && q['chapter'] != _selectedChapterFilter) return false;
      if (_selectedSourceFilter != 'All Source Types' && q['sourceType'] != _selectedSourceFilter) return false;
      if (_selectedDifficultyFilter != 'All Difficulty' && q['difficulty'] != _selectedDifficultyFilter) return false;
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: const [
                SizedBox(width: 24, child: CheckboxHeader()),
                SizedBox(width: 12),
                Expanded(flex: 4, child: Text('QUESTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                Expanded(flex: 1, child: Text('SUBJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('CHAPTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                Expanded(flex: 1, child: Text('SOURCE TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                Expanded(flex: 1, child: Text('DIFFICULTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('TAGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                Expanded(flex: 1, child: Text('USED IN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('ADDED ON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                SizedBox(width: 90, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
              ],
            ),
          ),

          // Table Rows List
          ...filtered.map((q) => _buildDataTableRow(q)),
        ],
      ),
    );
  }

  Widget _buildDataTableRow(Map<String, dynamic> q) {
    final String id = q['id'];
    final bool isSelected = _selectedQuestionIds.contains(id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            child: Checkbox(
              value: isSelected,
              activeColor: const Color(0xFF4F46E5),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedQuestionIds.add(id);
                  } else {
                    _selectedQuestionIds.remove(id);
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // QUESTION Preview + ID
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q['questionText'],
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: $id',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // SUBJECT Badge
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildSubjectBadge(q['subject']),
            ),
          ),

          // CHAPTER Name
          Expanded(
            flex: 2,
            child: Text(
              q['chapter'],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // SOURCE TYPE Badge
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildSourceBadge(q['sourceType']),
            ),
          ),

          // DIFFICULTY Badge
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildDifficultyBadge(q['difficulty']),
            ),
          ),

          // TAGS
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (q['tags'] as List).map<Widget>((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag as String,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                );
              }).toList(),
            ),
          ),

          // USED IN Icons
          Expanded(
            flex: 1,
            child: Row(
              children: [
                _buildSmallModuleBadge(Icons.track_changes_rounded, const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
                const SizedBox(width: 4),
                _buildSmallModuleBadge(Icons.assignment_turned_in_outlined, const Color(0xFFF0F9FF), const Color(0xFF0284C7)),
                const SizedBox(width: 4),
                _buildSmallModuleBadge(Icons.font_download_outlined, const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
              ],
            ),
          ),

          // ADDED ON Date
          Expanded(
            flex: 2,
            child: Text(
              q['addedOn'],
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
          ),

          // ACTIONS
          SizedBox(
            width: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF64748B)),
                  onPressed: () => _openViewQuestionDialog(q),
                  tooltip: 'View Question',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                  onPressed: () => _openEditQuestionDialog(q),
                  tooltip: 'Edit Question',
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBadge(String subject) {
    Color bg = const Color(0xFFEEF2FF);
    Color text = const Color(0xFF4F46E5);

    if (subject == 'Chemistry') {
      bg = const Color(0xFFF0F9FF);
      text = const Color(0xFF0284C7);
    } else if (subject == 'Biology') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF16A34A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(subject, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text)),
    );
  }

  Widget _buildSourceBadge(String source) {
    Color bg = const Color(0xFFDCFCE7);
    Color text = const Color(0xFF16A34A);

    if (source == 'PYQ') {
      bg = const Color(0xFFFFEDD5);
      text = const Color(0xFFEA580C);
    } else if (source == 'NCERT') {
      bg = const Color(0xFFE0F2FE);
      text = const Color(0xFF0284C7);
    } else if (source == 'Practice') {
      bg = const Color(0xFFFCE7F3);
      text = const Color(0xFFDB2777);
    } else if (source == 'Other') {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(source, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text)),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color bg = const Color(0xFFDCFCE7);
    Color text = const Color(0xFF16A34A);

    if (difficulty == 'Medium') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
    } else if (difficulty == 'Hard') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(difficulty, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text)),
    );
  }

  Widget _buildSmallModuleBadge(IconData icon, Color bg, Color iconColor) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 12, color: iconColor),
    );
  }

  // ==========================================
  // 8. TABLE PAGINATION FOOTER BAR
  // ==========================================
  Widget _buildPaginationFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Showing 1 to 10 of 1,24,560 questions',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
        ),

        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF64748B)),
              onPressed: () {},
            ),
            _buildPageButton(1, isActive: true),
            _buildPageButton(2),
            _buildPageButton(3),
            _buildPageButton(4),
            _buildPageButton(5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(color: Color(0xFF64748B))),
            ),
            _buildPageButton(12456),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF64748B)),
              onPressed: () {},
            ),
          ],
        ),

        Row(
          children: [
            const Text('Rows per page: ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  onChanged: (val) => setState(() => _rowsPerPage = val!),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 25, child: Text('25')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageButton(int page, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4F46E5) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 9. MODALS: ADD, IMPORT, VIEW, EDIT QUESTION
  // ==========================================
  void _openAddQuestionDialog({Map<String, dynamic>? initialData}) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      SmoothPageRoute(
        child: AdminQuestionBuilderScreen(
          userProfile: widget.userProfile,
          initialQuestionData: initialData,
          onQuestionSaved: (savedQ) {
            setState(() {
              if (initialData != null) {
                final idx = _sharedQuestionsBankList.indexWhere((q) => q['id'] == initialData['id']);
                if (idx != -1) {
                  _sharedQuestionsBankList[idx] = savedQ;
                }
              } else {
                _sharedQuestionsBankList.insert(0, savedQ);
              }
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final existingIdx = _sharedQuestionsBankList.indexWhere((q) => q['id'] == result['id']);
        if (existingIdx != -1) {
          _sharedQuestionsBankList[existingIdx] = result;
        } else {
          _sharedQuestionsBankList.insert(0, result);
        }
      });
    }
  }

  void _openEditQuestionDialog(Map<String, dynamic> q) {
    _openAddQuestionDialog(initialData: q);
  }

  void _openImportQuestionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Question Import Engine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    SmoothPageRoute(
                      child: AdminPdfImportScreen(userProfile: widget.userProfile),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4F46E5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF4F46E5), size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Advanced PDF Import Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                            SizedBox(height: 2),
                            Text('Extract NEET/JEE papers with Text, OCR, LaTeX, Diagrams & Side-by-Side Review', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
                  if (result != null && result.files.single.bytes != null) {
                    final csvString = utf8.decode(result.files.single.bytes!);
                    final List<List<dynamic>> fields = const CsvToListConverter().convert(csvString);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Imported ${fields.length - 1} questions successfully!'), backgroundColor: const Color(0xFF16A34A)),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.table_chart_outlined, color: Color(0xFF64748B), size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Bulk CSV Import', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                            SizedBox(height: 2),
                            Text('Quick import from standard CSV spreadsheet files', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openViewQuestionDialog(Map<String, dynamic> q) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Question Preview (${q['id']})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 16),
              LaTeXView(text: q['questionText'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              const Text('Options:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              ...(q['options'] as List).map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked_rounded, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Expanded(child: LaTeXView(text: opt as String)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Correct Answer: ${q['correctAnswer']}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF15803D)))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final Color color;
  SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.2, size.height * 0.8);
    path.lineTo(size.width * 0.4, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.height * 0.6);
    path.lineTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CheckboxHeader extends StatefulWidget {
  const CheckboxHeader({Key? key}) : super(key: key);

  @override
  State<CheckboxHeader> createState() => _CheckboxHeaderState();
}

class _CheckboxHeaderState extends State<CheckboxHeader> {
  bool isChecked = false;
  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: isChecked,
      activeColor: const Color(0xFF4F46E5),
      onChanged: (v) => setState(() => isChecked = v ?? false),
    );
  }
}
