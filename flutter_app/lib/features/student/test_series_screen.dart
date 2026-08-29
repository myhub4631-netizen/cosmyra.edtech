import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class TestSeriesScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  final Function(int)? onNavigateTab;
  final Function(List<QuestionModel> questions, int durationMinutes)? onStartTestSeriesSession;

  const TestSeriesScreen({
    Key? key,
    this.onBackToDashboard,
    this.onNavigateTab,
    this.onStartTestSeriesSession,
  }) : super(key: key);

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class TestSeriesCategoryItem {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  TestSeriesCategoryItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class TestSeriesCardData {
  final String id;
  final String title;
  final String subtitle;
  final int testCount;
  final int durationMinutes;
  final String difficulty;
  final String status; // 'In Progress', 'Not Started', 'Completed'
  final String nextTestName;
  final Color iconBgColor;
  final IconData icon;

  TestSeriesCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.testCount,
    required this.durationMinutes,
    required this.difficulty,
    required this.status,
    required this.nextTestName,
    required this.iconBgColor,
    required this.icon,
  });
}

class _TestSeriesScreenState extends State<TestSeriesScreen> {
  String _selectedCategory = 'All Series';
  String _selectedExamFilter = 'NEET 2026';
  bool _isLoading = false;
  List<Map<String, dynamic>> _dbPapers = [];

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  Future<void> _loadPapers() async {
    final papers = await SupabaseService.fetchAllPapersAndTestSeries();
    if (mounted) {
      setState(() {
        _dbPapers = papers;
      });
    }
  }

  Future<void> _startTestSeries(String paperId, String title, int durationMins) async {
    setState(() => _isLoading = true);
    try {
      final questions = await SupabaseService.fetchTestSeriesQuestions(
        paperId: paperId,
        category: 'mock_test',
        exam: _selectedExamFilter,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (!mounted) return;

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No questions assigned to "$title" yet. Upload questions via Question Bank.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (widget.onStartTestSeriesSession != null) {
        widget.onStartTestSeriesSession!(questions, durationMins);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${questions.length} questions for $title!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading test questions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final List<TestSeriesCategoryItem> _categories = [
    TestSeriesCategoryItem(
      title: 'All Series',
      count: 24,
      icon: Icons.track_changes_outlined,
      iconColor: const Color(0xFF2563EB),
      bgColor: const Color(0xFFEFF6FF),
    ),
    TestSeriesCategoryItem(
      title: 'Full Syllabus',
      count: 10,
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF16A34A),
      bgColor: const Color(0xFFF0FDF4),
    ),
    TestSeriesCategoryItem(
      title: 'Chapter Wise',
      count: 8,
      icon: Icons.auto_stories_outlined,
      iconColor: const Color(0xFF9333EA),
      bgColor: const Color(0xFFFAF5FF),
    ),
    TestSeriesCategoryItem(
      title: 'Topic Wise',
      count: 6,
      icon: Icons.sell_outlined,
      iconColor: const Color(0xFFEA580C),
      bgColor: const Color(0xFFFFF7ED),
    ),
  ];

  final List<TestSeriesCardData> _allTestSeries = [
    TestSeriesCardData(
      id: 'ts1',
      title: 'NEET 2026 Full Syllabus Test Series',
      subtitle: 'Complete syllabus mock tests',
      testCount: 12,
      durationMinutes: 180,
      difficulty: 'High',
      status: 'In Progress',
      nextTestName: 'Test 09',
      iconBgColor: const Color(0xFF10B981),
      icon: Icons.description_rounded,
    ),
    TestSeriesCardData(
      id: 'ts2',
      title: 'NEET 2026 Chapter Wise Test Series',
      subtitle: 'Practice by individual chapters',
      testCount: 8,
      durationMinutes: 60,
      difficulty: 'Medium',
      status: 'Not Started',
      nextTestName: 'Chapter 01',
      iconBgColor: const Color(0xFF3B82F6),
      icon: Icons.menu_book_rounded,
    ),
    TestSeriesCardData(
      id: 'ts3',
      title: 'NEET 2026 Topic Wise Test Series',
      subtitle: 'Practice by specific topics',
      testCount: 6,
      durationMinutes: 30,
      difficulty: 'Easy',
      status: 'In Progress',
      nextTestName: 'Topic 05',
      iconBgColor: const Color(0xFF8B5CF6),
      icon: Icons.bookmark_rounded,
    ),
    TestSeriesCardData(
      id: 'ts4',
      title: 'NEET 2026 Previous Year Papers',
      subtitle: 'PYQ based mock tests',
      testCount: 5,
      durationMinutes: 180,
      difficulty: 'High',
      status: 'Not Started',
      nextTestName: 'PYQ 2025',
      iconBgColor: const Color(0xFFEF4444),
      icon: Icons.track_changes_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Title & Exam Selector Filter
                        _buildPageHeaderRow(),
                        const SizedBox(height: 20),

                        // 4 KPI Summary Metric Cards Row
                        _buildKPISummaryRow(),
                        const SizedBox(height: 20),

                        // Your Progress Card
                        _buildYourProgressCard(),
                        const SizedBox(height: 24),

                        // Test Series Categories Row
                        _buildCategoriesSection(),
                        const SizedBox(height: 24),

                        // All Test Series Section Header & Cards List
                        _buildAllTestSeriesSection(),
                        const SizedBox(height: 20),

                        // Go Premium Banner
                        _buildGoPremiumBanner(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP APP BAR
  // ===========================================================================
  Widget _buildTopAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Menu Icon & Logo
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF334155), size: 24),
                onPressed: widget.onBackToDashboard,
              ),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ExamPrep',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  Row(
                    children: [
                      Text(
                        _selectedExamFilter,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Right: Notification Bell & Profile Avatar
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569), size: 20),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text('3', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF2563EB),
                child: Text('M', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. PAGE HEADER ROW (Title & Subtitle + Exam Filter Pill Button)
  // ===========================================================================
  Widget _buildPageHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Series',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.3),
            ),
            const SizedBox(height: 2),
            Text(
              'Attempt mock tests and improve your exam readiness.',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF64748B)),
            ),
          ],
        ),

        // Exam Filter Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(_selectedExamFilter, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. 4 KPI STAT SUMMARY CARDS ROW
  // ===========================================================================
  Widget _buildKPISummaryRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _buildKPISingleItem(Icons.article_outlined, const Color(0xFF3B82F6), '24', 'Total Tests'),
          _buildDivider(),
          _buildKPISingleItem(Icons.check_circle_outline_rounded, const Color(0xFF10B981), '8', 'Tests Attempted'),
          _buildDivider(),
          _buildKPISingleItem(Icons.emoji_events_outlined, const Color(0xFFF59E0B), '3,420', 'Total Score'),
          _buildDivider(),
          _buildKPISingleItem(Icons.track_changes_outlined, const Color(0xFF8B5CF6), '76.4%', 'Avg Accuracy'),
        ],
      ),
    );
  }

  Widget _buildKPISingleItem(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 42, color: const Color(0xFFF1F5F9));
  }

  // ===========================================================================
  // 4. YOUR PROGRESS CARD (Donut Chart & Analytics Link)
  // ===========================================================================
  Widget _buildYourProgressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Progress', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              InkWell(
                onTap: () {
                  if (widget.onNavigateTab != null) widget.onNavigateTab!(5); // Analytics tab
                },
                child: Row(
                  children: [
                    Text('View Analytics', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Row (Donut Chart + Stats Progress Bar)
          Row(
            children: [
              // Circular Donut Progress Ring (65%)
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: RingChartPainter(progress: 0.65, ringColor: const Color(0xFF10B981)),
                    ),
                    Text('65%', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Progress Stats Bar & Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tests Completed', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                        Text('8 of 24', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 8 / 24,
                        minHeight: 6,
                        backgroundColor: Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Avg Accuracy', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text('76.4%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Avg Score', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text('142 / 180', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. TEST SERIES CATEGORIES ROW
  // ===========================================================================
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Test Series Categories', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = (constraints.maxWidth - (3 * 10)) / 4;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final bool isSelected = (_selectedCategory == cat.title);

                  return Container(
                    width: itemWidth < 120 ? 130 : itemWidth,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat.title),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cat.bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(cat.icon, color: cat.iconColor, size: 17),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cat.count} Tests',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. ALL TEST SERIES SECTION HEADER & CARDS LIST
  // ===========================================================================
  Widget _buildAllTestSeriesSection() {
    // Combine hardcoded + dynamic database papers
    final List<TestSeriesCardData> combinedList = List.from(_allTestSeries);
    for (var p in _dbPapers) {
      final String pId = p['id'] ?? '';
      if (!combinedList.any((item) => item.id == pId)) {
        final pName = p['paper_name'] ?? p['paperName'] ?? 'NEET 2026 Phase 1';
        final qCount = (p['saved_questions_count'] is num) ? (p['saved_questions_count'] as num).toInt() : (p['question_count'] ?? 200);
        final duration = (p['duration_minutes'] is num) ? (p['duration_minutes'] as num).toInt() : (p['duration'] ?? 180);
        combinedList.insert(
          0,
          TestSeriesCardData(
            id: pId,
            title: pName,
            subtitle: '${p['exam'] ?? 'NEET'} ${p['year'] ?? '2026'} Assigned Paper ($qCount Questions)',
            testCount: qCount > 0 ? qCount : 1,
            durationMinutes: duration,
            difficulty: 'High',
            status: p['status'] == 'Completed' ? 'Completed' : 'Not Started',
            nextTestName: 'Paper $pId',
            iconBgColor: const Color(0xFF7C3AED),
            icon: Icons.assignment_turned_in_rounded,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('All Test Series', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text('Filter', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // List of Cards
        ...combinedList.map((item) => _buildTestSeriesCard(item)).toList(),
      ],
    );
  }

  Widget _buildTestSeriesCard(TestSeriesCardData item) {
    final bool isInProgress = item.status == 'In Progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () => _startTestSeries(item.id, item.title, item.durationMinutes),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),

              // Main Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),

                    // Meta Pills Row (Tests, Duration, Difficulty)
                    Row(
                      children: [
                        _buildMetaPill(Icons.description_outlined, '${item.testCount} Tests'),
                        const SizedBox(width: 10),
                        _buildMetaPill(Icons.access_time_rounded, '${item.durationMinutes} min'),
                        const SizedBox(width: 10),
                        _buildMetaPill(Icons.bar_chart_rounded, item.difficulty),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right Status Pill & Start Next Test Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isInProgress ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.status,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isInProgress ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isInProgress ? 'Next Test' : 'Start Test',
                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.nextTestName,
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
      ],
    );
  }

  // ===========================================================================
  // 7. GO PREMIUM BANNER
  // ===========================================================================
  Widget _buildGoPremiumBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3F0FF), Color(0xFFEEF2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Row(
        children: [
          // Crown Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF7C3AED), size: 24),
          ),
          const SizedBox(width: 14),

          // Banner Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go Premium',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Unlock all test series, detailed analysis, and exclusive features.',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Upgrade Button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Premium Upgrade Plans...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              children: [
                Text('Upgrade Now', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. BOTTOM NAVIGATION BAR
  // ===========================================================================
  Widget _buildBottomNavBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', false, 0),
          _buildNavItem(Icons.track_changes_outlined, 'Practice', false, 1),
          _buildNavItem(Icons.calendar_today_rounded, 'Test Series', true, 2),
          _buildNavItem(Icons.bar_chart_rounded, 'Analytics', false, 5),
          _buildNavItem(Icons.person_outline_rounded, 'Profile', false, 7),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, int index) {
    final color = isActive ? const Color(0xFF4F46E5) : const Color(0xFF64748B);

    return InkWell(
      onTap: () {
        if (widget.onNavigateTab != null) {
          widget.onNavigateTab!(index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Ring Chart Painter for 65% Progress Ring
class RingChartPainter extends CustomPainter {
  final double progress;
  final Color ringColor;

  RingChartPainter({required this.progress, required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 7.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ringColor != ringColor;
  }
}
