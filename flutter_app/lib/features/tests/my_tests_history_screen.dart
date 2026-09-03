import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/app_sidebar.dart';

enum TestCategoryFilter { all, customTest, customPractice, neetPyq, ntaQuestions, testSeries }
enum TestStatusFilter { all, completed, attempted, saved, inProgress }
enum TestSortOption { newestFirst, oldestFirst, highestScore, lowestScore }
enum TestTimeframeOption { allTime, today, thisWeek, thisMonth }

class TestHistoryItem {
  final String id;
  final String title;
  final TestCategoryFilter category;
  final String badgeLabel; // 'My Creation' or 'Official'
  final bool isOfficial;
  final int questionsCount;
  final int maxMarks;
  final String subjectsInfo; // e.g. 'Physics, Chemistry' or 'Physics • Current Electricity'
  final DateTime createdDate;
  final DateTime? savedDate;
  final TestStatusFilter status;
  final int? score;
  final int? totalScoreMax;
  final double? accuracy;
  final String? timeTaken;
  final int attemptsCount;
  final double? percentile;
  final int? rank;
  final int? bestScore;
  final int? completedQuestions;

  TestHistoryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.badgeLabel,
    this.isOfficial = false,
    required this.questionsCount,
    required this.maxMarks,
    required this.subjectsInfo,
    required this.createdDate,
    this.savedDate,
    required this.status,
    this.score,
    this.totalScoreMax,
    this.accuracy,
    this.timeTaken,
    this.attemptsCount = 1,
    this.percentile,
    this.rank,
    this.bestScore,
    this.completedQuestions,
  });

  double get progressPercentage {
    if (questionsCount == 0) return 0.0;
    return ((completedQuestions ?? 0) / questionsCount * 100).clamp(0.0, 100.0);
  }
}

class MyTestsHistoryScreen extends StatefulWidget {
  final UserProfileModel? userProfile;
  final VoidCallback? onBack;
  final Function(int tabIndex)? onNavigateTab;
  final VoidCallback? onOpenCustomPractice;
  final VoidCallback? onOpenCustomTest;
  final VoidCallback? onOpenPyqs;

  const MyTestsHistoryScreen({
    Key? key,
    this.userProfile,
    this.onBack,
    this.onNavigateTab,
    this.onOpenCustomPractice,
    this.onOpenCustomTest,
    this.onOpenPyqs,
  }) : super(key: key);

  @override
  State<MyTestsHistoryScreen> createState() => _MyTestsHistoryScreenState();
}

class _MyTestsHistoryScreenState extends State<MyTestsHistoryScreen> {
  TestCategoryFilter _selectedCategory = TestCategoryFilter.all;
  TestStatusFilter _selectedStatus = TestStatusFilter.all;
  TestSortOption _selectedSort = TestSortOption.newestFirst;
  TestTimeframeOption _selectedTimeframe = TestTimeframeOption.allTime;

  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<TestHistoryItem> _allHistoryItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRealHistoryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRealHistoryData() async {
    setState(() => _isLoading = true);

    final List<TestHistoryItem> items = [];

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load submitted test attempts from local storage 'cosmyra_test_attempts_history'
      final localAttemptsStr = prefs.getString('cosmyra_test_attempts_history');
      if (localAttemptsStr != null && localAttemptsStr.isNotEmpty) {
        final List<dynamic> localList = jsonDecode(localAttemptsStr);
        for (var item in localList) {
          final String id = item['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            final String title = item['testTitle'] ?? 'Custom Practice Session';
            final double score = (item['totalScore'] as num?)?.toDouble() ?? 0.0;
            final double maxMarks = (item['maxMarks'] as num?)?.toDouble() ?? 200.0;
            final double accuracy = (item['accuracy'] as num?)?.toDouble() ?? 0.0;
            final int timeSpent = (item['timeSpentSeconds'] as num?)?.toInt() ?? 0;

            TestCategoryFilter cat = TestCategoryFilter.customPractice;
            if (title.toUpperCase().contains('PYQ')) {
              cat = TestCategoryFilter.neetPyq;
            } else if (title.toUpperCase().contains('NTA')) {
              cat = TestCategoryFilter.ntaQuestions;
            } else if (title.toUpperCase().contains('SERIES') || title.toUpperCase().contains('MOCK')) {
              cat = TestCategoryFilter.testSeries;
            } else if (title.toUpperCase().contains('TEST')) {
              cat = TestCategoryFilter.customTest;
            }

            final hours = timeSpent ~/ 3600;
            final mins = (timeSpent % 3600) ~/ 60;
            final secs = timeSpent % 60;
            final timeStr = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

            items.add(TestHistoryItem(
              id: id,
              title: title,
              category: cat,
              badgeLabel: (cat == TestCategoryFilter.neetPyq || cat == TestCategoryFilter.ntaQuestions || cat == TestCategoryFilter.testSeries) ? 'Official' : 'My Creation',
              isOfficial: (cat == TestCategoryFilter.neetPyq || cat == TestCategoryFilter.ntaQuestions || cat == TestCategoryFilter.testSeries),
              questionsCount: (maxMarks / 4.0).round(),
              maxMarks: maxMarks.toInt(),
              subjectsInfo: 'Submitted Attempt',
              createdDate: DateTime.tryParse(item['submittedAt'] ?? '') ?? DateTime.now(),
              status: TestStatusFilter.completed,
              score: score.toInt(),
              totalScoreMax: maxMarks.toInt(),
              accuracy: accuracy,
              timeTaken: timeStr,
              attemptsCount: 1,
            ));
          }
        }
      }

      // 2. Load attempts from Supabase DB 'test_attempts' table
      try {
        final List<dynamic> dbRows = await SupabaseService.client
            .from('test_attempts')
            .select('*')
            .order('submitted_at', ascending: false)
            .limit(50);

        for (var row in dbRows) {
          final String id = row['id']?.toString() ?? '';
          if (id.isNotEmpty && !items.any((i) => i.id == id)) {
            final String title = row['test_title'] ?? row['title'] ?? 'Custom Test Attempt';
            final double score = (row['total_score'] as num?)?.toDouble() ?? 0.0;
            final double maxMarks = (row['max_score'] as num?)?.toDouble() ?? 720.0;
            final double accuracy = (row['accuracy_percentage'] as num?)?.toDouble() ?? 0.0;
            final int timeSpent = (row['time_spent_seconds'] as num?)?.toInt() ?? 0;
            final String statusStr = (row['status'] ?? 'completed').toString().toLowerCase();

            TestCategoryFilter cat = TestCategoryFilter.customTest;
            if (title.toUpperCase().contains('PYQ')) {
              cat = TestCategoryFilter.neetPyq;
            } else if (title.toUpperCase().contains('NTA')) {
              cat = TestCategoryFilter.ntaQuestions;
            } else if (title.toUpperCase().contains('SERIES') || title.toUpperCase().contains('MOCK')) {
              cat = TestCategoryFilter.testSeries;
            } else if (title.toUpperCase().contains('PRACTICE')) {
              cat = TestCategoryFilter.customPractice;
            }

            final hours = timeSpent ~/ 3600;
            final mins = (timeSpent % 3600) ~/ 60;
            final secs = timeSpent % 60;
            final timeStr = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

            items.add(TestHistoryItem(
              id: id,
              title: title,
              category: cat,
              badgeLabel: (cat == TestCategoryFilter.neetPyq || cat == TestCategoryFilter.ntaQuestions || cat == TestCategoryFilter.testSeries) ? 'Official' : 'My Creation',
              isOfficial: (cat == TestCategoryFilter.neetPyq || cat == TestCategoryFilter.ntaQuestions || cat == TestCategoryFilter.testSeries),
              questionsCount: (maxMarks / 4.0).round(),
              maxMarks: maxMarks.toInt(),
              subjectsInfo: 'All Subjects',
              createdDate: DateTime.tryParse(row['submitted_at'] ?? row['started_at'] ?? '') ?? DateTime.now(),
              status: statusStr == 'submitted' || statusStr == 'completed' ? TestStatusFilter.completed : TestStatusFilter.attempted,
              score: score.toInt(),
              totalScoreMax: maxMarks.toInt(),
              accuracy: accuracy,
              timeTaken: timeStr,
              attemptsCount: 1,
            ));
          }
        }
      } catch (e) {
        debugPrint('Notice loading Supabase test_attempts: $e');
      }

      // 3. Load saved custom papers from SharedPreferences key 'cosmyra_saved_papers'
      final savedPapersStr = prefs.getString('cosmyra_saved_papers');
      if (savedPapersStr != null && savedPapersStr.isNotEmpty) {
        final List<dynamic> savedList = jsonDecode(savedPapersStr);
        for (var item in savedList) {
          final String id = item['id']?.toString() ?? '';
          if (id.isNotEmpty && !items.any((i) => i.id == id)) {
            final String title = item['title'] ?? item['name'] ?? 'Custom Saved Paper';
            final int qCount = (item['question_count'] ?? item['questionsCount'] ?? 30) as int;
            final int maxM = qCount * 4;

            items.add(TestHistoryItem(
              id: id,
              title: title,
              category: TestCategoryFilter.customTest,
              badgeLabel: 'My Creation',
              isOfficial: false,
              questionsCount: qCount,
              maxMarks: maxM,
              subjectsInfo: item['subject'] ?? 'Custom Test',
              createdDate: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
              savedDate: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
              status: TestStatusFilter.saved,
              attemptsCount: 0,
            ));
          }
        }
      }

      // 4. Load PYQ practice history from SharedPreferences key 'cosmyra_pyq_practice_history'
      final pyqHistoryStr = prefs.getString('cosmyra_pyq_practice_history');
      if (pyqHistoryStr != null && pyqHistoryStr.isNotEmpty) {
        final List<dynamic> pyqList = jsonDecode(pyqHistoryStr);
        for (var item in pyqList) {
          final String id = item['id']?.toString() ?? 'pyq_${DateTime.now().millisecondsSinceEpoch}';
          if (!items.any((i) => i.id == id)) {
            final String title = item['title'] ?? 'PYQ Practice';
            final int qCount = (item['questionCount'] ?? 20) as int;
            final double accuracy = (item['accuracy'] as num?)?.toDouble() ?? 0.0;
            final int timeSpent = (item['timeSpentSeconds'] as num?)?.toInt() ?? 0;

            final hours = timeSpent ~/ 3600;
            final mins = (timeSpent % 3600) ~/ 60;
            final secs = timeSpent % 60;
            final timeStr = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

            items.add(TestHistoryItem(
              id: id,
              title: title,
              category: TestCategoryFilter.neetPyq,
              badgeLabel: 'Official',
              isOfficial: true,
              questionsCount: qCount,
              maxMarks: qCount * 4,
              subjectsInfo: item['exam'] ?? 'NEET PYQ',
              createdDate: DateTime.tryParse(item['date'] ?? '') ?? DateTime.now(),
              status: TestStatusFilter.completed,
              accuracy: accuracy,
              timeTaken: timeStr,
              attemptsCount: 1,
            ));
          }
        }
      }

      // Sort newest createdDate first
      items.sort((a, b) => b.createdDate.compareTo(a.createdDate));

    } catch (e) {
      debugPrint('Error loading real history data: $e');
    }

    if (mounted) {
      setState(() {
        _allHistoryItems = items;
        _isLoading = false;
      });
    }
  }

  List<TestHistoryItem> get _filteredItems {
    return _allHistoryItems.where((item) {
      // Category filter
      if (_selectedCategory != TestCategoryFilter.all) {
        if (item.category != _selectedCategory) return false;
      }

      // Status filter
      if (_selectedStatus != TestStatusFilter.all) {
        if (item.status != _selectedStatus) return false;
      }

      // Search filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchSubjects = item.subjectsInfo.toLowerCase().contains(q);
        if (!matchTitle && !matchSubjects) return false;
      }

      return true;
    }).toList();
  }

  // Activity summary stats
  int get _totalCreated => _allHistoryItems.length;
  int get _totalAttempted => _allHistoryItems.where((i) => i.status == TestStatusFilter.attempted || i.status == TestStatusFilter.completed).length;
  int get _totalSaved => _allHistoryItems.where((i) => i.status == TestStatusFilter.saved).length;
  int get _totalCompleted => _allHistoryItems.where((i) => i.status == TestStatusFilter.completed).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: Drawer(
        child: AppSidebar(
          selectedIndex: 7,
          onOpenPractice: widget.onOpenCustomPractice,
          onOpenCustomPractice: widget.onOpenCustomPractice,
          onOpenCustomTest: widget.onOpenCustomTest,
          onOpenPyqs: widget.onOpenPyqs,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HEADER BAR
                  _buildHeaderBar(context),

                  const SizedBox(height: 16),

                  // 2. SEARCH BAR (Expandable)
                  if (_isSearchOpen) _buildSearchBar(),

                  const SizedBox(height: 12),

                  // 3. TOP ACTIVITY SUMMARY METRICS (4 Horizontal cards)
                  _buildActivitySummaryRow(),

                  const SizedBox(height: 20),

                  // 4. CATEGORY FILTER PILL TABS
                  _buildCategoryFilterRow(),

                  const SizedBox(height: 12),

                  // 5. STATUS FILTER PILL TABS
                  _buildStatusFilterRow(),

                  const SizedBox(height: 16),

                  // 6. SORT & TIMEFRAME DROPDOWNS ROW
                  _buildSortTimeframeRow(),

                  const SizedBox(height: 16),

                  // 7. ACTIVITY CARDS LIST
                  _buildActivityList(),

                  const SizedBox(height: 24),

                  // 8. "WHAT DO YOU WANT TO DO?" CREATION BAR
                  _buildWhatDoYouWantToDoBar(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),

      // 9. FLOATING ACTION BUTTON (+)
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onOpenCustomTest ?? widget.onOpenCustomPractice,
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // 1. HEADER BAR
  Widget _buildHeaderBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (ctx) => InkWell(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(6.0),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.menu_rounded, size: 20, color: Color(0xFF0F172A)),
                ),
              ),
            ),
            InkWell(
              onTap: widget.onBack ?? () => (context.canPop() ? context.pop() : context.go('/dashboard')),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(Icons.arrow_back, size: 22, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'My Tests & Practice',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                Text(
                  'Track everything you\'ve created and attempted',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() => _isSearchOpen = !_isSearchOpen);
              },
              icon: Icon(
                _isSearchOpen ? Icons.close : Icons.search,
                size: 22,
                color: const Color(0xFF0F172A),
              ),
              tooltip: 'Search tests',
            ),
            IconButton(
              onPressed: () {
                _showFilterModal(context);
              },
              icon: const Icon(Icons.filter_list, size: 22, color: Color(0xFF0F172A)),
              tooltip: 'Filter options',
            ),
          ],
        ),
      ],
    );
  }

  // 2. SEARCH BAR
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search by test name, subject or category...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          icon: Icon(Icons.search, size: 20, color: Color(0xFF4F46E5)),
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val);
        },
      ),
    );
  }

  // 3. TOP ACTIVITY SUMMARY METRICS (4 Horizontal Cards)
  Widget _buildActivitySummaryRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Created', '$_totalCreated', Icons.description_outlined, const Color(0xFFEEF2FF), const Color(0xFF4F46E5))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricCard('Attempted', '$_totalAttempted', Icons.check_circle_outline, const Color(0xFFDCFCE7), const Color(0xFF16A34A))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Saved', '$_totalSaved', Icons.bookmark_border, const Color(0xFFFFFBEB), const Color(0xFFD97706))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricCard('Completed', '$_totalCompleted', Icons.emoji_events_outlined, const Color(0xFFEFF6FF), const Color(0xFF2563EB))),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildMetricCard('Created', '$_totalCreated', Icons.description_outlined, const Color(0xFFEEF2FF), const Color(0xFF4F46E5))),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Attempted', '$_totalAttempted', Icons.check_circle_outline, const Color(0xFFDCFCE7), const Color(0xFF16A34A))),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Saved', '$_totalSaved', Icons.bookmark_border, const Color(0xFFFFFBEB), const Color(0xFFD97706))),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('Completed', '$_totalCompleted', Icons.emoji_events_outlined, const Color(0xFFEFF6FF), const Color(0xFF2563EB))),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  // 4. CATEGORY FILTER PILL TABS
  Widget _buildCategoryFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryPill('All', TestCategoryFilter.all),
          const SizedBox(width: 6),
          _buildCategoryPill('Custom Test', TestCategoryFilter.customTest),
          const SizedBox(width: 6),
          _buildCategoryPill('Custom Practice', TestCategoryFilter.customPractice),
          const SizedBox(width: 6),
          _buildCategoryPill('NEET PYQ', TestCategoryFilter.neetPyq),
          const SizedBox(width: 6),
          _buildCategoryPill('NTA Questions', TestCategoryFilter.ntaQuestions),
          const SizedBox(width: 6),
          _buildCategoryPill('Test Series', TestCategoryFilter.testSeries),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, TestCategoryFilter category) {
    final bool isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // 5. STATUS FILTER PILL TABS
  Widget _buildStatusFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatusPill('All', TestStatusFilter.all, const Color(0xFF4F46E5)),
          const SizedBox(width: 6),
          _buildStatusPill('Completed', TestStatusFilter.completed, const Color(0xFF16A34A)),
          const SizedBox(width: 6),
          _buildStatusPill('Attempted', TestStatusFilter.attempted, const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          _buildStatusPill('Saved', TestStatusFilter.saved, const Color(0xFFD97706)),
          const SizedBox(width: 6),
          _buildStatusPill('In Progress', TestStatusFilter.inProgress, const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, TestStatusFilter status, Color activeColor) {
    final bool isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : activeColor,
          ),
        ),
      ),
    );
  }

  // 6. SORT & TIMEFRAME DROPDOWNS ROW
  Widget _buildSortTimeframeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Sort dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TestSortOption>(
              value: _selectedSort,
              isDense: true,
              style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
              items: const [
                DropdownMenuItem(value: TestSortOption.newestFirst, child: Text('⇅ Newest First')),
                DropdownMenuItem(value: TestSortOption.oldestFirst, child: Text('⇅ Oldest First')),
                DropdownMenuItem(value: TestSortOption.highestScore, child: Text('⇅ Highest Score')),
                DropdownMenuItem(value: TestSortOption.lowestScore, child: Text('⇅ Lowest Score')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedSort = val);
              },
            ),
          ),
        ),

        // Timeframe dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TestTimeframeOption>(
              value: _selectedTimeframe,
              isDense: true,
              style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
              items: const [
                DropdownMenuItem(value: TestTimeframeOption.allTime, child: Text('📅 All Time')),
                DropdownMenuItem(value: TestTimeframeOption.today, child: Text('📅 Today')),
                DropdownMenuItem(value: TestTimeframeOption.thisWeek, child: Text('📅 This Week')),
                DropdownMenuItem(value: TestTimeframeOption.thisMonth, child: Text('📅 This Month')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedTimeframe = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  // 7. ACTIVITY CARDS LIST
  Widget _buildActivityList() {
    if (_isLoading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final items = _filteredItems;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: const [
            Icon(Icons.history_toggle_off, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text('No test history found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            SizedBox(height: 4),
            Text('Try changing your filters or create a new custom practice session.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
      itemBuilder: (ctx, idx) => _buildActivityCard(items[idx]),
    );
  }

  Widget _buildActivityCard(TestHistoryItem item) {
    // Type styling details
    Color iconBg;
    Color iconColor;
    IconData icon;
    String typeLabel;

    switch (item.category) {
      case TestCategoryFilter.customTest:
        iconBg = const Color(0xFFF3E8FF);
        iconColor = const Color(0xFF8B5CF6);
        icon = Icons.description_outlined;
        typeLabel = 'Custom Test';
        break;
      case TestCategoryFilter.customPractice:
        iconBg = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF16A34A);
        icon = Icons.track_changes;
        typeLabel = 'Custom Practice';
        break;
      case TestCategoryFilter.neetPyq:
        iconBg = const Color(0xFFFFEDD5);
        iconColor = const Color(0xFFD97706);
        icon = Icons.menu_book;
        typeLabel = 'NEET PYQ';
        break;
      case TestCategoryFilter.ntaQuestions:
        iconBg = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0284C7);
        icon = Icons.file_present;
        typeLabel = 'NTA Questions';
        break;
      case TestCategoryFilter.testSeries:
      default:
        iconBg = const Color(0xFFEEF2FF);
        iconColor = const Color(0xFF4F46E5);
        icon = Icons.emoji_events_outlined;
        typeLabel = 'Test Series';
        break;
    }

    // Status Badge Details
    Color statusBg;
    Color statusTextColor;
    String statusText;
    IconData statusIcon;

    switch (item.status) {
      case TestStatusFilter.completed:
        statusBg = const Color(0xFFDCFCE7);
        statusTextColor = const Color(0xFF15803D);
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      case TestStatusFilter.attempted:
        statusBg = const Color(0xFFDBEAFE);
        statusTextColor = const Color(0xFF1D4ED8);
        statusText = 'Attempted';
        statusIcon = Icons.settings_backup_restore;
        break;
      case TestStatusFilter.saved:
        statusBg = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFB45309);
        statusText = 'Saved';
        statusIcon = Icons.bookmark;
        break;
      case TestStatusFilter.inProgress:
      default:
        statusBg = const Color(0xFFF3E8FF);
        statusTextColor = const Color(0xFF6D28D9);
        statusText = 'In Progress';
        statusIcon = Icons.timelapse;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(height: 2),
                    Text(typeLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: iconColor), textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Title & Meta Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.isOfficial ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.badgeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: item.isOfficial ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.questionsCount} Questions • ${item.maxMarks} Marks • ${item.subjectsInfo}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created: ${_formatDate(item.createdDate)}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge & Menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusTextColor),
                        const SizedBox(width: 4),
                        Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusTextColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Content Body based on Status
          if (item.status == TestStatusFilter.inProgress) ...[
            _buildInProgressProgressRow(item),
          ] else if (item.status == TestStatusFilter.saved) ...[
            _buildSavedRow(item),
          ] else ...[
            _buildCompletedStatsRow(item),
          ],
        ],
      ),
    );
  }

  // Stats Row for Completed/Attempted Tests
  Widget _buildCompletedStatsRow(TestHistoryItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 540;

        Widget ctaButton;
        if (item.status == TestStatusFilter.completed) {
          ctaButton = OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('View Result', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF4F46E5)),
              ],
            ),
          );
        } else {
          ctaButton = OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('View Practice', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF4F46E5)),
              ],
            ),
          );
        }

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Score', '${item.score ?? 0} / ${item.totalScoreMax ?? item.maxMarks}', isBoldPrimary: true),
                  _buildStatItem('Accuracy', '${item.accuracy?.toStringAsFixed(0) ?? 0}%'),
                  if (item.timeTaken != null) _buildStatItem('Time', item.timeTaken!),
                  if (item.percentile != null) _buildStatItem('Percentile', '${item.percentile}%'),
                  if (item.bestScore != null) _buildStatItem('Best Score', '${item.bestScore} / ${item.totalScoreMax ?? item.maxMarks}'),
                  _buildStatItem('Attempts', '${item.attemptsCount}'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ctaButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildStatItem('Score', '${item.score ?? 0} / ${item.totalScoreMax ?? item.maxMarks}', isBoldPrimary: true)),
            Expanded(child: _buildStatItem('Accuracy', '${item.accuracy?.toStringAsFixed(0) ?? 0}%')),
            if (item.timeTaken != null) Expanded(child: _buildStatItem('Time', item.timeTaken!)),
            if (item.percentile != null) Expanded(child: _buildStatItem('Percentile', '${item.percentile}%')),
            if (item.bestScore != null) Expanded(child: _buildStatItem('Best Score', '${item.bestScore} / ${item.totalScoreMax ?? item.maxMarks}')),
            if (item.rank != null) Expanded(child: _buildStatItem('Rank', '${item.rank}')),
            Expanded(child: _buildStatItem('Attempts', '${item.attemptsCount}')),
            const SizedBox(width: 12),
            ctaButton,
          ],
        );
      },
    );
  }

  // In Progress Bar Row
  Widget _buildInProgressProgressRow(TestHistoryItem item) {
    final double pct = item.progressPercentage;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 540;

        final ctaButton = OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFC7D2FE)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Resume', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 12)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: Color(0xFF4F46E5)),
            ],
          ),
        );

        final progressIndicator = Expanded(
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: ${item.completedQuestions ?? 0} / ${item.questionsCount} Questions',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        Text(
                          '${pct.round()}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100.0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isMobile) {
          return Column(
            children: [
              Row(children: [progressIndicator]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ctaButton),
            ],
          );
        }

        return Row(
          children: [
            progressIndicator,
            const SizedBox(width: 16),
            ctaButton,
          ],
        );
      },
    );
  }

  // Saved Item Row
  Widget _buildSavedRow(TestHistoryItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 540;

        final ctaButton = OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFC7D2FE)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Start Practice', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 12)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: Color(0xFF4F46E5)),
            ],
          ),
        );

        final infoText = Row(
          children: [
            const Icon(Icons.bookmark_outline, size: 14, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text(
              'Saved on: ${_formatDate(item.savedDate ?? item.createdDate)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 12, color: const Color(0xFFCBD5E1)),
            const SizedBox(width: 12),
            const Text(
              'Not Attempted Yet',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              infoText,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ctaButton),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            infoText,
            ctaButton,
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String val, {bool isBoldPrimary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBoldPrimary ? FontWeight.w900 : FontWeight.w700,
            color: isBoldPrimary ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // 8. "WHAT DO YOU WANT TO DO?" CREATION BAR
  Widget _buildWhatDoYouWantToDoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What do you want to do?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionCard('Custom Practice', Icons.track_changes, const Color(0xFFDCFCE7), const Color(0xFF16A34A), widget.onOpenCustomPractice),
                const SizedBox(width: 8),
                _buildActionCard('Custom Test', Icons.description_outlined, const Color(0xFFF3E8FF), const Color(0xFF8B5CF6), widget.onOpenCustomTest),
                const SizedBox(width: 8),
                _buildActionCard('NEET PYQ', Icons.menu_book, const Color(0xFFFFEDD5), const Color(0xFFD97706), widget.onOpenPyqs),
                const SizedBox(width: 8),
                _buildActionCard('NTA Questions', Icons.file_present, const Color(0xFFE0F2FE), const Color(0xFF0284C7), widget.onOpenPyqs),
                const SizedBox(width: 8),
                _buildActionCard('Test Series', Icons.emoji_events_outlined, const Color(0xFFEEF2FF), const Color(0xFF4F46E5), () => widget.onNavigateTab?.call(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color bg, Color iconColor, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              const Text('Sort By', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TestSortOption.values.map((opt) {
                  return ChoiceChip(
                    label: Text(opt.name),
                    selected: _selectedSort == opt,
                    onSelected: (val) {
                      setState(() => _selectedSort = opt);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                  child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
