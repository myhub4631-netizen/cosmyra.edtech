import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../tests/test_screen.dart';

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
  final String exam; // 'NEET', 'JEE Main', 'JEE Advanced'
  final String targetYear; // '2027', '2026'
  final String subtitle;
  final String description;
  final int testCount;
  final int durationMinutes;
  final String difficulty; // 'Easy', 'Moderate', 'Advanced', 'Mixed'
  final String validity; // 'Valid until exam'
  final String attemptStatus; // 'Not Attempted', 'In Progress', 'Completed'
  final String status;
  final String nextTestName;
  final Color iconBgColor;
  final IconData icon;
  final String? bannerImageUrl;
  final bool isFree;
  final double price;
  final double originalPrice;
  final String purchaseLink;
  final String purchaseButtonText;
  final bool showPurchaseButton;
  final String syllabusUrl;

  TestSeriesCardData({
    required this.id,
    required this.title,
    this.exam = 'NEET',
    this.targetYear = '2027',
    required this.subtitle,
    this.description = '',
    required this.testCount,
    required this.durationMinutes,
    this.difficulty = 'Moderate',
    this.validity = 'Valid until exam',
    this.attemptStatus = 'Not Attempted',
    required this.status,
    required this.nextTestName,
    required this.iconBgColor,
    required this.icon,
    this.bannerImageUrl,
    this.isFree = false,
    this.price = 299.0,
    this.originalPrice = 999.0,
    this.purchaseLink = '',
    this.purchaseButtonText = 'Join',
    this.showPurchaseButton = true,
    this.syllabusUrl = '',
  });

  String get durationFormatted {
    if (durationMinutes <= 0) return '3 Hours';
    if (durationMinutes >= 60 && durationMinutes % 60 == 0) {
      final h = durationMinutes ~/ 60;
      return '$h ${h == 1 ? "Hour" : "Hours"}';
    }
    return '$durationMinutes min';
  }

  String get formattedTargetYear {
    final cleanExam = exam.contains('JEE') ? (exam.contains('Advanced') ? 'JEE Adv' : 'JEE') : 'NEET';
    final cleanYear = targetYear.isNotEmpty ? targetYear : '2027';
    if (cleanYear.toLowerCase().contains('neet') || cleanYear.toLowerCase().contains('jee')) {
      return cleanYear;
    }
    return '$cleanExam $cleanYear';
  }
}

class _TestSeriesScreenState extends State<TestSeriesScreen> {
  String _selectedCategory = 'All Series';
  String _selectedExamFilter = 'NEET 2026';
  bool _isLoading = false;
  List<Map<String, dynamic>> _dbPapers = [];
  List<Map<String, dynamic>> _customSeriesList = [];

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  Future<void> _loadPapers() async {
    setState(() => _isLoading = true);
    final papers = await SupabaseService.fetchAllPapersAndTestSeries();
    final customSeries = await SupabaseService.fetchAllTestSeries();
    if (mounted) {
      setState(() {
        _dbPapers = papers;
        _customSeriesList = customSeries;
        _isLoading = false;
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
        questions.addAll(SupabaseService.getSampleQuestions(20));
      }

      if (widget.onStartTestSeriesSession != null) {
        widget.onStartTestSeriesSession!(questions, durationMins);
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomTestScreen(
              questions: questions,
              durationMinutes: durationMins,
              onTestSubmitted: (attempt, answers) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Test Series completed and submitted!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
            ),
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

  List<TestSeriesCardData> _getAllRealTestSeries() {
    final List<TestSeriesCardData> list = [];
    final Set<String> seenTitles = {};

    // 1. Load from custom series (from Supabase test_series / tests / shared_prefs)
    for (var cs in _customSeriesList) {
      final String title = (cs['title'] ?? cs['name'] ?? '').toString().trim();
      final String sId = (cs['id'] ?? cs['paper_id'] ?? 'ts_${title.hashCode}').toString();
      if (title.isNotEmpty && !seenTitles.contains(title.toLowerCase())) {
        seenTitles.add(title.toLowerCase());
        final exam = (cs['exam'] ?? 'NEET').toString();
        final year = (cs['year'] ?? '2027').toString();
        final qCount = (cs['question_count'] is num) ? (cs['question_count'] as num).toInt() : 200;
        final duration = (cs['duration_minutes'] is num) ? (cs['duration_minutes'] as num).toInt() : 180;
        final testCount = (cs['test_count'] is num) ? (cs['test_count'] as num).toInt() : 10;
        final difficulty = (cs['difficulty'] ?? 'Moderate').toString();
        final validity = (cs['validity'] ?? 'Valid until exam').toString();
        final attemptStatus = (cs['attempt_status'] ?? cs['attemptStatus'] ?? 'Not Attempted').toString();
        final syllabusUrl = (cs['syllabus_url'] ?? cs['syllabusUrl'] ?? '').toString();
        final isFree = cs['is_free'] == true || cs['isFree'] == true;
        final price = (cs['price'] is num) ? (cs['price'] as num).toDouble() : (double.tryParse(cs['price']?.toString() ?? '299') ?? 299.0);
        final origPrice = (cs['original_price'] is num) ? (cs['original_price'] as num).toDouble() : (double.tryParse(cs['original_price']?.toString() ?? '999') ?? 999.0);
        final purchaseLink = (cs['purchase_link'] ?? '').toString();
        final buttonText = (cs['purchase_button_text'] ?? 'Join').toString();
        final showPurchaseButton = cs['show_purchase_button'] != false;

        list.add(
          TestSeriesCardData(
            id: sId,
            title: title,
            exam: exam,
            targetYear: year,
            subtitle: '$exam $year Series ($qCount Qs)',
            description: (cs['description'] ?? '').toString().trim().isNotEmpty
                ? cs['description'].toString().trim()
                : 'Comprehensive mock tests covering full syllabus with step-by-step solutions.',
            testCount: testCount,
            durationMinutes: duration,
            difficulty: difficulty,
            validity: validity,
            attemptStatus: attemptStatus,
            syllabusUrl: syllabusUrl,
            status: cs['status'] ?? 'Published',
            nextTestName: cs['paper_name'] ?? 'Test 01',
            iconBgColor: const Color(0xFF4F46E5),
            icon: Icons.track_changes_rounded,
            bannerImageUrl: cs['banner_image_url'] ?? cs['bannerImageUrl'],
            isFree: isFree,
            price: price,
            originalPrice: origPrice,
            purchaseLink: purchaseLink,
            purchaseButtonText: buttonText,
            showPurchaseButton: showPurchaseButton,
          ),
        );
      }
    }

    // 2. Load from dbPapers marked as test series
    for (var p in _dbPapers) {
      final String pId = p['id']?.toString() ?? '';
      final String tsTitle = (p['test_series_title'] ?? p['new_test_series_name'] ?? p['existing_test_series'] ?? '').toString().trim();
      final String pName = (p['paper_name'] ?? p['paperName'] ?? '').toString().trim();
      final String effectiveTitle = tsTitle.isNotEmpty ? tsTitle : pName;

      final bool isTestSeries = (p['source_category'] == 'Test Series') ||
          (p['category'] == 'Test Series') ||
          tsTitle.isNotEmpty ||
          (p['test_series_option'] != null && p['test_series_option'].toString().isNotEmpty) ||
          ((p['available_in'] is List) && (p['available_in'] as List).contains('test_series'));

      if (isTestSeries && effectiveTitle.isNotEmpty && !seenTitles.contains(effectiveTitle.toLowerCase())) {
        seenTitles.add(effectiveTitle.toLowerCase());
        final exam = (p['exam'] ?? 'NEET').toString();
        final year = (p['year'] ?? '2027').toString();
        final qCount = (p['saved_questions_count'] is num) ? (p['saved_questions_count'] as num).toInt() : (p['question_count'] ?? 200);
        final duration = (p['duration_minutes'] is num) ? (p['duration_minutes'] as num).toInt() : (p['duration'] ?? 180);
        final difficulty = (p['difficulty'] ?? 'Moderate').toString();
        final validity = (p['validity'] ?? 'Valid until exam').toString();
        final attemptStatus = (p['attempt_status'] ?? 'Not Attempted').toString();
        final syllabusUrl = (p['syllabus_url'] ?? '').toString();
        final isFree = p['is_free'] == true || p['isFree'] == true;
        final price = (p['price'] is num) ? (p['price'] as num).toDouble() : 299.0;
        final origPrice = (p['original_price'] is num) ? (p['original_price'] as num).toDouble() : 999.0;
        final purchaseLink = (p['purchase_link'] ?? '').toString();
        final buttonText = (p['purchase_button_text'] ?? 'Join').toString();

        list.add(
          TestSeriesCardData(
            id: pId,
            title: effectiveTitle,
            exam: exam,
            targetYear: year,
            subtitle: '$exam $year Series (${qCount > 0 ? qCount : 200} Qs)',
            description: (p['description'] ?? '').toString().trim().isNotEmpty
                ? p['description'].toString().trim()
                : 'Complete mock tests covering full syllabus with step-by-step solutions.',
            testCount: 1,
            durationMinutes: duration,
            difficulty: difficulty,
            validity: validity,
            attemptStatus: attemptStatus,
            syllabusUrl: syllabusUrl,
            status: p['status'] == 'Completed' ? 'Completed' : 'Ready',
            nextTestName: pName,
            iconBgColor: const Color(0xFF7C3AED),
            icon: Icons.assignment_turned_in_rounded,
            bannerImageUrl: p['banner_image_url'] ?? p['bannerImageUrl'],
            isFree: isFree,
            price: price,
            originalPrice: origPrice,
            purchaseLink: purchaseLink,
            purchaseButtonText: buttonText,
            showPurchaseButton: p['show_purchase_button'] != false,
          ),
        );
      }
    }

    return list;
  }

  List<TestSeriesCategoryItem> _getCategories(List<TestSeriesCardData> seriesList) {
    int allCount = 0;
    int fullCount = 0;
    int chapterCount = 0;
    int topicCount = 0;

    for (var s in seriesList) {
      allCount += s.testCount;
      final t = (s.title + ' ' + s.description).toLowerCase();
      if (t.contains('chapter')) {
        chapterCount += s.testCount;
      } else if (t.contains('topic')) {
        topicCount += s.testCount;
      } else {
        fullCount += s.testCount;
      }
    }

    return [
      TestSeriesCategoryItem(
        title: 'All Series',
        count: allCount,
        icon: Icons.track_changes_outlined,
        iconColor: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
      ),
      TestSeriesCategoryItem(
        title: 'Full Syllabus',
        count: fullCount,
        icon: Icons.description_outlined,
        iconColor: const Color(0xFF16A34A),
        bgColor: const Color(0xFFF0FDF4),
      ),
      TestSeriesCategoryItem(
        title: 'Chapter Wise',
        count: chapterCount,
        icon: Icons.auto_stories_outlined,
        iconColor: const Color(0xFF9333EA),
        bgColor: const Color(0xFFFAF5FF),
      ),
      TestSeriesCategoryItem(
        title: 'Topic Wise',
        count: topicCount,
        icon: Icons.sell_outlined,
        iconColor: const Color(0xFFEA580C),
        bgColor: const Color(0xFFFFF7ED),
      ),
    ];
  }

  void _handleDownloadSyllabus(TestSeriesCardData item) async {
    if (item.syllabusUrl.isNotEmpty && (item.syllabusUrl.startsWith('http://') || item.syllabusUrl.startsWith('https://'))) {
      final uri = Uri.tryParse(item.syllabusUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    _showSyllabusModal(item);
  }

  void _showSyllabusModal(TestSeriesCardData item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Test Series Syllabus', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text('${item.exam} • Target ${item.formattedTargetYear}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(item.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              const SizedBox(height: 6),
              Text(item.description, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  children: [
                    _buildSyllabusRow(Icons.description_outlined, 'Total Tests', '${item.testCount} Tests'),
                    const Divider(height: 12),
                    _buildSyllabusRow(Icons.access_time_rounded, 'Duration per Test', item.durationFormatted),
                    const Divider(height: 12),
                    _buildSyllabusRow(Icons.bar_chart_rounded, 'Difficulty Level', item.difficulty),
                    const Divider(height: 12),
                    _buildSyllabusRow(Icons.event_available_rounded, 'Validity Period', item.validity),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.syllabusUrl.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final uri = Uri.tryParse(item.syllabusUrl);
                        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      label: const Text('Download Official PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyllabusRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRealSeries = _getAllRealTestSeries();

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
                        _buildKPISummaryRow(allRealSeries),
                        const SizedBox(height: 20),

                        // Your Progress Card
                        _buildYourProgressCard(),
                        const SizedBox(height: 24),

                        // Test Series Categories Row
                        _buildCategoriesSection(allRealSeries),
                        const SizedBox(height: 24),

                        // All Test Series Section Header & Cards List
                        _buildAllTestSeriesSection(allRealSeries),
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

        // Exam & Year Filter Dropdown Popup
        PopupMenuButton<String>(
          tooltip: 'Select Exam / Year',
          initialValue: _selectedExamFilter,
          onSelected: (val) => setState(() => _selectedExamFilter = val),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'All Exams', child: Text('All Exams & Years')),
            ...List.generate(2029 - 1988 + 1, (i) {
              final y = 2029 - i;
              return PopupMenuItem(
                value: 'NEET $y',
                child: Text('NEET $y'),
              );
            }),
            ...List.generate(2029 - 1988 + 1, (i) {
              final y = 2029 - i;
              return PopupMenuItem(
                value: 'JEE Main $y',
                child: Text('JEE Main $y'),
              );
            }),
          ],
          child: Container(
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
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. 4 KPI STAT SUMMARY CARDS ROW
  // ===========================================================================
  Widget _buildKPISummaryRow(List<TestSeriesCardData> seriesList) {
    final int totalTests = seriesList.fold(0, (sum, i) => sum + i.testCount);
    final int completedTests = seriesList.where((i) => i.attemptStatus == 'Completed').length;
    final int inProgressTests = seriesList.where((i) => i.attemptStatus == 'In Progress').length;
    final int attempted = completedTests + inProgressTests;

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
          _buildKPISingleItem(Icons.article_outlined, const Color(0xFF3B82F6), '$totalTests', 'Total Tests'),
          _buildDivider(),
          _buildKPISingleItem(Icons.check_circle_outline_rounded, const Color(0xFF10B981), '$attempted', 'Tests Attempted'),
          _buildDivider(),
          _buildKPISingleItem(Icons.emoji_events_outlined, const Color(0xFFF59E0B), totalTests > 0 ? '${seriesList.length}' : '0', 'Test Series'),
          _buildDivider(),
          _buildKPISingleItem(Icons.track_changes_outlined, const Color(0xFF8B5CF6), attempted > 0 ? '${((completedTests / (attempted > 0 ? attempted : 1)) * 100).toInt()}%' : 'N/A', 'Avg Accuracy'),
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
  Widget _buildCategoriesSection(List<TestSeriesCardData> seriesList) {
    final categories = _getCategories(seriesList);

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
                children: categories.map((cat) {
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
  Widget _buildAllTestSeriesSection(List<TestSeriesCardData> allRealSeries) {
    // Filter by Category tab if applicable
    final filteredList = allRealSeries.where((item) {
      if (_selectedCategory == 'Full Syllabus' && !item.title.toLowerCase().contains('full') && !item.subtitle.toLowerCase().contains('full')) {
        return false;
      }
      if (_selectedCategory == 'Chapter Wise' && !item.title.toLowerCase().contains('chapter') && !item.subtitle.toLowerCase().contains('chapter')) {
        return false;
      }
      if (_selectedCategory == 'Topic Wise' && !item.title.toLowerCase().contains('topic') && !item.subtitle.toLowerCase().contains('topic')) {
        return false;
      }
      // Exam Filter
      if (_selectedExamFilter != 'All Exams') {
        final f = _selectedExamFilter.toLowerCase();
        final match = item.title.toLowerCase().contains(f) ||
            item.formattedTargetYear.toLowerCase().contains(f) ||
            '${item.exam} ${item.targetYear}'.toLowerCase().contains(f);
        if (!match && (f.contains('neet') && !item.exam.toLowerCase().contains('neet'))) return false;
        if (!match && (f.contains('jee') && !item.exam.toLowerCase().contains('jee'))) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Test Series (${filteredList.length})',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
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
                    Text(
                      'Active Filter: $_selectedCategory',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // List of Cards or Clean Empty State
        if (filteredList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_outlined, size: 28, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(height: 14),
                Text(
                  'No Test Series Available',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Real test series published by the admin in Admin Test Series Manager will appear here.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filteredList.map((item) => _buildTestSeriesCard(item)),
      ],
    );
  }

  Widget _buildTestSeriesCard(TestSeriesCardData item) {
    final bool hasBanner = item.bannerImageUrl != null && item.bannerImageUrl!.isNotEmpty;

    // Attempt status badge colors
    Color attemptBadgeBg;
    Color attemptBadgeText;
    if (item.attemptStatus == 'Completed') {
      attemptBadgeBg = const Color(0xFFDCFCE7);
      attemptBadgeText = const Color(0xFF15803D);
    } else if (item.attemptStatus == 'In Progress') {
      attemptBadgeBg = const Color(0xFFFEF3C7);
      attemptBadgeText = const Color(0xFFB45309);
    } else {
      attemptBadgeBg = const Color(0xFFF1F5F9);
      attemptBadgeText = const Color(0xFF475569);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image Header if present
            if (hasBanner)
              Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      item.bannerImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        color: const Color(0xFF1E1B4B),
                        child: const Center(child: Icon(Icons.track_changes_rounded, color: Colors.white70, size: 32)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.formattedTargetYear,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isFree ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isFree ? 'FREE' : '₹${item.price.toInt()}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),

            // Card Body Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Icon, Test Series Name, Exam, Target Year, Attempt Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Test Series Name
                            Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // 2. Exam & 3. Target Year Badges
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFC7D2FE)),
                                  ),
                                  child: Text(
                                    item.exam,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Text(
                                    'Target: ${item.formattedTargetYear}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 10. Attempt Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: attemptBadgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: attemptBadgeText, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.attemptStatus,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: attemptBadgeText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 4. Short Description
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Metadata Pills: 5. Number of Tests, 6. Duration, 7. Difficulty, 8. Price, 9. Validity
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildMetaPill(Icons.description_outlined, '${item.testCount} Tests'),
                      _buildMetaPill(Icons.access_time_rounded, item.durationFormatted),
                      _buildMetaPill(Icons.bar_chart_rounded, item.difficulty),
                      _buildMetaPill(Icons.event_available_rounded, item.validity),

                      // 8. Price Pill
                      if (item.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: const Text('FREE', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w800)),
                        )
                      else ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${item.price.toInt()}',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '₹${item.originalPrice.toInt()}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFEE2E8), borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                '${(((item.originalPrice - item.price) / item.originalPrice) * 100).toInt()}% OFF',
                                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Action Buttons Row: 11. CTA (Join / Start) & 12. Download Syllabus
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 12. Download Syllabus CTA Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _handleDownloadSyllabus(item),
                        icon: const Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF2563EB)),
                        label: Text(
                          'Download Syllabus',
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        ),
                      ),

                      // 11. CTA Button: Join / Start Test / Resume Test
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.showPurchaseButton && item.purchaseLink.isNotEmpty && !item.isFree) ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                final uri = Uri.tryParse(item.purchaseLink);
                                if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                              },
                              child: Text(
                                item.purchaseButtonText.isNotEmpty ? item.purchaseButtonText : 'Join',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _startTestSeries(item.id, item.title, item.durationMinutes),
                            icon: Icon(
                              item.attemptStatus == 'In Progress' ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              item.attemptStatus == 'In Progress'
                                  ? 'Resume Test'
                                  : (item.attemptStatus == 'Completed' ? 'Retake Test' : (item.isFree ? 'Join Free' : 'Start Test')),
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
        ],
      ),
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
