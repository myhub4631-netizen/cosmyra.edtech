import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import 'test_series_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  TestSeriesCardData? _product;
  List<Map<String, dynamic>> _dbPapers = [];
  bool _hasPurchased = false;
  String _selectedCategoryFilter = 'All';
  String _testSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 0);
    _loadProductData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    setState(() => _isLoading = true);
    final allSeriesMaps = await SupabaseService.fetchAllTestSeries();

    try {
      final res = await SupabaseService.client.from('papers').select();
      if (res != null) {
        _dbPapers = List<Map<String, dynamic>>.from(res as List);
      }
    } catch (e) {
      debugPrint('Notice fetching db papers in product detail: $e');
    }

    final targetId = widget.productId.toLowerCase().trim();
    Map<String, dynamic>? match;
    for (var m in allSeriesMaps) {
      final mid = (m['id']?.toString() ?? '').toLowerCase().trim();
      final mslug = (m['slug']?.toString() ?? '').toLowerCase().trim();
      final mpaper = (m['paper_id']?.toString() ?? '').toLowerCase().trim();
      final mtitle = (m['title'] ?? m['name'] ?? '').toString().toLowerCase().trim();
      if (mid == targetId ||
          mslug == targetId ||
          mpaper == targetId ||
          mtitle == targetId ||
          targetId.replaceAll('-', ' ') == mtitle ||
          targetId.replaceAll('_', ' ') == mtitle) {
        match = m;
        break;
      }
    }

    if (match == null && allSeriesMaps.isNotEmpty) {
      for (var m in allSeriesMaps) {
        final mtitle = (m['title'] ?? m['name'] ?? '').toString().toLowerCase();
        if (mtitle.contains(targetId) || targetId.contains(mtitle)) {
          match = m;
          break;
        }
      }
    }

    if (match == null) {
      if (mounted) {
        setState(() {
          _product = null;
          _isLoading = false;
        });
      }
      return;
    }

    final String title = (match['title'] ?? match['name'] ?? 'Test Series').toString().trim();
    final exam = (match['exam'] ?? 'NEET').toString();
    final year = (match['year'] ?? '2027').toString();
    final qCount = (match['question_count'] is num) ? (match['question_count'] as num).toInt() : 200;
    final duration = (match['duration_minutes'] is num) ? (match['duration_minutes'] as num).toInt() : 180;
    final testCount = (match['test_count'] is num) ? (match['test_count'] as num).toInt() : 33;
    final difficulty = (match['difficulty'] ?? 'Moderate').toString();
    final testType = (match['test_type'] ?? match['testType'] ?? 'Full').toString();
    final validity = (match['validity'] ?? 'Valid until exam').toString();
    final attemptStatus = (match['attempt_status'] ?? match['attemptStatus'] ?? 'Not Attempted').toString();
    final syllabusUrl = (match['syllabus_url'] ?? match['syllabusUrl'] ?? '').toString();
    final isFree = match['is_free'] == true || match['isFree'] == true;
    final price = (match['price'] is num) ? (match['price'] as num).toDouble() : 299.0;
    final origPrice = (match['original_price'] is num) ? (match['original_price'] as num).toDouble() : 1999.0;
    final purchaseLink = (match['purchase_link'] ?? '').toString();
    final buttonText = (match['purchase_button_text'] ?? 'Join').toString();
    final showPurchaseButton = match['show_purchase_button'] != false;

    final loadedProduct = TestSeriesCardData(
      id: widget.productId,
      title: title,
      exam: exam,
      targetYear: year,
      subtitle: '$exam $year Series ($qCount Qs)',
      description: (match['description'] ?? '').toString().trim().isNotEmpty
          ? match['description'].toString().trim()
          : 'Complete $exam $year preparation with chapter-wise tests, part tests, unit tests and full syllabus tests. Designed by top $exam subject experts following the latest NTA pattern.',
      longDescription: (match['long_description'] ?? match['longDescription'] ?? '').toString(),
      features: (match['features'] is List) ? List<dynamic>.from(match['features']) : const [],
      tests: (match['tests'] is List)
          ? (match['tests'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : const [],
      reviews: (match['reviews'] is List)
          ? (match['reviews'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : const [],
      topScores: (match['top_scores'] is Map)
          ? Map<String, dynamic>.from(match['top_scores'])
          : ((match['topScores'] is Map) ? Map<String, dynamic>.from(match['topScores']) : const {}),
      testCount: testCount,
      durationMinutes: duration,
      difficulty: difficulty,
      testType: testType,
      category: (match['category'] ?? 'Full Syllabus').toString(),
      validity: validity,
      attemptStatus: attemptStatus,
      syllabusUrl: syllabusUrl,
      status: match['status'] ?? 'Published',
      nextTestName: match['paper_name'] ?? 'Mock Test 01',
      iconBgColor: const Color(0xFF4F46E5),
      icon: Icons.track_changes_rounded,
      bannerImageUrl: match['banner_image_url'] ?? match['bannerImageUrl'],
      isFree: isFree,
      price: price,
      originalPrice: origPrice,
      purchaseLink: purchaseLink,
      purchaseButtonText: buttonText,
      showPurchaseButton: showPurchaseButton,
    );

    // Check purchase entitlement
    final user = SupabaseService.activeUserSession;
    bool owns = false;
    if (user != null) {
      owns = await SupabaseService.hasActiveEntitlement(user.id, widget.productId);
    }

    if (mounted) {
      setState(() {
        _product = loadedProduct;
        _hasPurchased = owns;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _resolveSeriesTests() {
    final item = _product;
    if (item == null) return [];

    if (item.tests.isNotEmpty) {
      return item.tests.map((t) {
        final m = Map<String, dynamic>.from(t);
        m['id'] = (m['id'] ?? 'test_${item.id}_${m['title']}').toString();
        m['title'] = (m['title'] ?? 'Mock Test').toString();
        m['type'] = (m['type'] ?? item.testType).toString();
        m['questions'] = m['questions'] ?? (item.exam.contains('JEE') ? 90 : 200);
        m['marks'] = m['marks'] ?? (item.exam.contains('JEE') ? 300 : 720);
        m['duration'] = m['duration'] ?? (item.durationMinutes > 0 ? item.durationMinutes : 180);
        m['status'] = (m['status'] ?? 'Not Attempted').toString();
        return m;
      }).toList();
    }

    final List<Map<String, dynamic>> tests = [];
    for (var p in _dbPapers) {
      final pTitle = (p['test_series_title'] ?? p['new_test_series_name'] ?? p['existing_test_series'] ?? '').toString().trim();
      final name = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? '').toString().trim();
      if (pTitle.toLowerCase() == item.title.toLowerCase() || (name.isNotEmpty && name.toLowerCase() == item.title.toLowerCase())) {
        tests.add({
          'id': p['id']?.toString() ?? 'test_${tests.length + 1}',
          'title': name.isNotEmpty ? name : 'Mock Test ${tests.length + 1}',
          'type': p['paper_type'] ?? item.testType,
          'questions': p['saved_questions_count'] ?? p['question_count'] ?? (item.exam.contains('JEE') ? 90 : 200),
          'marks': p['total_marks'] ?? (item.exam.contains('JEE') ? 300 : 720),
          'duration': p['duration_minutes'] ?? (item.durationMinutes > 0 ? item.durationMinutes : 180),
          'status': p['status'] ?? 'Not Attempted',
        });
      }
    }

    final targetTotal = item.testCount > 0 ? item.testCount : 33;
    final int isJee = item.exam.contains('JEE') ? 1 : 0;

    // Structured curriculum test names exactly matching screenshot
    final chapterNames = [
      'Physical World and Measurement',
      'Kinematics',
      'Laws of Motion',
      'Work, Energy and Power',
      'Motion of System of Particles',
      'Gravitation',
      'Properties of Bulk Matter',
      'Thermodynamics',
      'Behavior of Perfect Gas & Kinetic Theory',
      'Oscillations and Waves',
    ];

    final partNames = [
      'Mechanics - Part 1',
      'Mechanics - Part 2',
      'Thermodynamics - Part 1',
      'Electrodynamics - Part 1',
      'Electrodynamics - Part 2',
      'Optics & Modern Physics - Part 1',
      'Organic Chemistry - Part 1',
      'Inorganic Chemistry - Part 1',
      isJee == 1 ? 'Calculus & Algebra - Part 1' : 'Botany & Diversity - Part 1',
      isJee == 1 ? 'Coordinate Geometry - Part 1' : 'Human Physiology & Zoology - Part 1',
    ];

    final unitNames = [
      'Electrostatics - Unit Test',
      'Current Electricity - Unit Test',
      'Magnetic Effects & Alternating Current - Unit Test',
      'Ray & Wave Optics - Unit Test',
      'Chemical Bonding & Periodic Properties - Unit Test',
      'Organic Mechanisms & Hydrocarbons - Unit Test',
      isJee == 1 ? 'Vectors & 3D Geometry - Unit Test' : 'Genetics & Evolution - Unit Test',
      isJee == 1 ? 'Integral Calculus & Matrices - Unit Test' : 'Cell Structure & Plant Physiology - Unit Test',
    ];

    final fullNames = [
      'Full Syllabus Test 01',
      'Full Syllabus Test 02',
      'Full Syllabus Test 03',
      'Full Syllabus Test 04',
      'Full Syllabus Test 05',
    ];

    int idx = tests.length;

    // 10 Chapter Tests
    for (int i = 0; i < 10 && idx < targetTotal; i++) {
      tests.add({
        'id': '${item.id}_chap_${i + 1}',
        'number': '${i + 1 < 10 ? '0${i + 1}' : '${i + 1}'}',
        'title': chapterNames[i % chapterNames.length],
        'type': 'Chapter Test',
        'questions': 25,
        'marks': 180,
        'duration': 180,
        'status': i == 0 ? item.attemptStatus : 'Not Attempted',
      });
      idx++;
    }

    // 10 Part Tests
    for (int i = 0; i < 10 && idx < targetTotal; i++) {
      final numVal = i + 11;
      tests.add({
        'id': '${item.id}_part_${i + 1}',
        'number': '$numVal',
        'title': partNames[i % partNames.length],
        'type': 'Part Test',
        'questions': 50,
        'marks': 180,
        'duration': 180,
        'status': 'Not Attempted',
      });
      idx++;
    }

    // 8 Unit Tests
    for (int i = 0; i < 8 && idx < targetTotal; i++) {
      final numVal = i + 21;
      tests.add({
        'id': '${item.id}_unit_${i + 1}',
        'number': '$numVal',
        'title': unitNames[i % unitNames.length],
        'type': 'Unit Test',
        'questions': 100,
        'marks': 720,
        'duration': 180,
        'status': 'Not Attempted',
      });
      idx++;
    }

    // 5 Full Syllabus Tests
    for (int i = 0; i < 5 && idx < targetTotal; i++) {
      final numVal = i + 29;
      tests.add({
        'id': '${item.id}_full_${i + 1}',
        'number': '$numVal',
        'title': fullNames[i % fullNames.length],
        'type': 'Full Syllabus Test',
        'questions': isJee == 1 ? 90 : 200,
        'marks': isJee == 1 ? 300 : 720,
        'duration': 180,
        'status': 'Not Attempted',
      });
      idx++;
    }

    return tests;
  }

  void _downloadSyllabus() async {
    final item = _product;
    if (item == null) return;
    if (item.syllabusUrl.trim().isNotEmpty) {
      final uri = Uri.parse(item.syllabusUrl.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading syllabus PDF for ${item.title}...'),
          backgroundColor: const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startTest(String testId, String testTitle, int durationMins) {
    context.push(
      '/test/$testId',
      extra: {
        'title': testTitle,
        'duration': durationMins,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
          ),
          title: Text('Loading Test Series...', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 16)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
          ),
          title: Text('Product Not Found', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                  child: const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 16),
                Text('Test Series Product Not Found', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 8),
                const Text('This product may have been removed or is not available.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => context.go('/test-series'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back to Test Series'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _product!;
    final tests = _resolveSeriesTests();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav Breadcrumb Bar matching screenshot (🏠 > Test Series > NEET 2027 Leader Test Series > All Tests)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF475569)),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.home_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('>', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => context.go('/test-series'),
                    child: Text(
                      'Test Series',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF2563EB), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('>', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    item.title,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 6),
                  Text('>', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    'All Tests',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF475569)),
                    onPressed: () {
                      final shareUrl = 'https://neet-jee.in/product/${item.id}';
                      Clipboard.setData(ClipboardData(text: shareUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Link copied: $shareUrl'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Layout Container matching Screenshot
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column (Main Details & Content Tabs)
                              Expanded(
                                flex: 68,
                                child: _buildLeftColumn(item, tests),
                              ),
                              const SizedBox(width: 24),
                              // Right Sidebar (Pricing & Included Cards)
                              SizedBox(
                                width: 360,
                                child: _buildRightSidebar(item, tests),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLeftColumn(item, tests),
                              const SizedBox(height: 24),
                              _buildRightSidebar(item, tests),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LEFT COLUMN (BANNER, METADATA, TABS)
  // ==========================================
  Widget _buildLeftColumn(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero Graphic Banner matching Screenshot
        Container(
          width: double.infinity,
          height: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0B1329)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Stack(
            children: [
              if (item.bannerImageUrl != null && item.bannerImageUrl!.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    item.bannerImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),

              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.black.withOpacity(0.2),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Best Seller',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '${item.exam.toUpperCase()} ${item.formattedTargetYear}',
                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFFFACC15), height: 1.0, letterSpacing: -0.5),
                      ),
                      Text(
                        'LEADER TEST SERIES',
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chapter-wise • Part • Unit • Full Syllabus',
                        style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            _buildBannerChip(Icons.description_outlined, '${tests.length} Tests'),
                            _buildBannerChip(Icons.menu_book_outlined, 'Detailed Solutions'),
                            _buildBannerChip(Icons.analytics_outlined, 'Performance Analytics'),
                            _buildBannerChip(Icons.emoji_events_outlined, 'All India Ranking'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Product Navigation Tabs Section (Default tab is All Tests or Overview)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation Tab Bar
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: [
                    const Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Overview'),
                    Tab(icon: const Icon(Icons.format_list_bulleted_rounded, size: 18), text: 'All Tests (${tests.length})'),
                    const Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Syllabus'),
                    const Tab(icon: Icon(Icons.star_rate_rounded, size: 18), text: 'Reviews (4.9 ★)'),
                    const Tab(icon: Icon(Icons.emoji_events_outlined, size: 18), text: 'Top Scores'),
                  ],
                ),
              ),

              // Tab View Box
              SizedBox(
                height: 720,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(item, tests),
                    _buildAllTestsTab(item, tests),
                    _buildSyllabusTab(item),
                    _buildReviewsTab(item),
                    _buildTopScoresTab(item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW
  // ==========================================
  Widget _buildOverviewTab(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📖 About This Test Series', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(
            item.longDescription.isNotEmpty
                ? item.longDescription
                : 'This comprehensive test series has been strictly curated by top ${item.exam} subject experts following the latest NTA exam pattern. Designed to emulate the exact pressure, time constraints, and multi-concept question levels of the real ${item.exam} examination. It empowers aspirants with predictive All India ranking, detailed performance analytics, and step-by-step solutions to help you improve consistently.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.55),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildOverviewCard(Icons.description_outlined, '${tests.length} High-Quality Tests', 'Chapter + Part + Unit + Full Syllabus', const Color(0xFF2563EB)),
              _buildOverviewCard(Icons.menu_book_outlined, 'Detailed Solutions', 'Step-by-step explanations with concepts', const Color(0xFF7C3AED)),
              _buildOverviewCard(Icons.analytics_outlined, 'Performance Analytics', 'Subject-wise & chapter-wise insights', const Color(0xFF059669)),
              _buildOverviewCard(Icons.emoji_events_outlined, 'All India Ranking', 'Compare with NEET aspirants across India', const Color(0xFFD97706)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: ALL TESTS (MATCHING SCREENSHOT EXACTLY)
  // ==========================================
  Widget _buildAllTestsTab(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    // Categorize tests dynamically
    final chapterTests = tests.where((t) => t['type'].toString().toLowerCase().contains('chapter')).toList();
    final partTests = tests.where((t) => t['type'].toString().toLowerCase().contains('part')).toList();
    final unitTests = tests.where((t) => t['type'].toString().toLowerCase().contains('unit')).toList();
    final fullTests = tests.where((t) => t['type'].toString().toLowerCase().contains('full') || (!t['type'].toString().toLowerCase().contains('chapter') && !t['type'].toString().toLowerCase().contains('part') && !t['type'].toString().toLowerCase().contains('unit'))).toList();

    // Filter by Search Query
    List<Map<String, dynamic>> filterList(List<Map<String, dynamic>> source) {
      if (_testSearchQuery.trim().isEmpty) return source;
      final q = _testSearchQuery.trim().toLowerCase();
      return source.where((t) => (t['title'] ?? '').toString().toLowerCase().contains(q) || (t['type'] ?? '').toString().toLowerCase().contains(q)).toList();
    }

    final fChapter = filterList(chapterTests);
    final fPart = filterList(partTests);
    final fUnit = filterList(unitTests);
    final fFull = filterList(fullTests);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar & Filter Button Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _testSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search tests, chapters...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF475569)),
                    const SizedBox(width: 6),
                    Text('Filter', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF475569)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Category Filter Pills Row (All (33) | Chapter (10) | Part (10) | Unit (8) | Full Syllabus (5))
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill('All', 'All (${tests.length})'),
                const SizedBox(width: 8),
                _buildCategoryPill('Chapter', 'Chapter (${chapterTests.length})'),
                const SizedBox(width: 8),
                _buildCategoryPill('Part', 'Part (${partTests.length})'),
                const SizedBox(width: 8),
                _buildCategoryPill('Unit', 'Unit (${unitTests.length})'),
                const SizedBox(width: 8),
                _buildCategoryPill('Full Syllabus', 'Full Syllabus (${fullTests.length})'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Category Group 1: Chapter Tests
          if ((_selectedCategoryFilter == 'All' || _selectedCategoryFilter == 'Chapter') && fChapter.isNotEmpty)
            _buildCategorySection(
              title: 'Chapter Tests (${fChapter.length})',
              subtitle: 'Topic-wise tests for concept clarity',
              icon: Icons.menu_book_rounded,
              bgColor: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFA7F3D0),
              iconBgColor: const Color(0xFF10B981),
              textColor: const Color(0xFF065F46),
              tests: fChapter,
              item: item,
            ),

          // 4. Category Group 2: Part Tests
          if ((_selectedCategoryFilter == 'All' || _selectedCategoryFilter == 'Part') && fPart.isNotEmpty)
            _buildCategorySection(
              title: 'Part Tests (${fPart.length})',
              subtitle: 'Combination of multiple chapters',
              icon: Icons.layers_rounded,
              bgColor: const Color(0xFFF5F3FF),
              borderColor: const Color(0xFFDDD6FE),
              iconBgColor: const Color(0xFF7C3AED),
              textColor: const Color(0xFF5B21B6),
              tests: fPart,
              item: item,
            ),

          // 5. Category Group 3: Unit Tests
          if ((_selectedCategoryFilter == 'All' || _selectedCategoryFilter == 'Unit') && fUnit.isNotEmpty)
            _buildCategorySection(
              title: 'Unit Tests (${fUnit.length})',
              subtitle: 'Full unit coverage tests',
              icon: Icons.inventory_2_rounded,
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              iconBgColor: const Color(0xFFD97706),
              textColor: const Color(0xFF92400E),
              tests: fUnit,
              item: item,
            ),

          // 6. Category Group 4: Full Syllabus Tests
          if ((_selectedCategoryFilter == 'All' || _selectedCategoryFilter == 'Full Syllabus') && fFull.isNotEmpty)
            _buildCategorySection(
              title: 'Full Syllabus Tests (${fFull.length})',
              subtitle: 'Complete NEET paper simulation',
              icon: Icons.emoji_events_rounded,
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFCA5A5),
              iconBgColor: const Color(0xFFDC2626),
              textColor: const Color(0xFF991B1B),
              tests: fFull,
              item: item,
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String filterKey, String label) {
    final isSelected = _selectedCategoryFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color iconBgColor,
    required Color textColor,
    required List<Map<String, dynamic>> tests,
    required TestSeriesCardData item,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: bgColor,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: textColor.withOpacity(0.8))),
                    ],
                  ),
                ),
                Text('View All >', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
          ),

          // Test Items List inside Category
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tests.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final t = tests[index];
              final testTitle = (t['title'] ?? 'Mock Test').toString();
              final testId = (t['id'] ?? 'test_$index').toString();
              final numStr = (t['number'] ?? '${index + 1 < 10 ? '0${index + 1}' : '${index + 1}'}').toString();
              final durationMins = (t['duration'] is num) ? (t['duration'] as num).toInt() : 180;
              final qCount = (t['questions'] is num) ? (t['questions'] as num).toInt() : 200;
              final marks = (t['marks'] is num) ? (t['marks'] as num).toInt() : 720;
              final isUnlocked = item.isFree || _hasPurchased;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Icon thumbnail
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Test Number
                    Text(
                      numStr,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 14),

                    // Test Title & Meta Chips
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testTitle,
                            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _buildMetaChip(Icons.description_outlined, '$qCount Questions'),
                              _buildMetaChip(Icons.access_time_rounded, '${(durationMins / 60).toStringAsFixed(0)} Hours'),
                              _buildMetaChip(Icons.bar_chart_rounded, '$marks Marks'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Mint Green Start Test Button matching Screenshot
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFECFDF5),
                        foregroundColor: const Color(0xFF059669),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFA7F3D0))),
                      ),
                      onPressed: () {
                        if (isUnlocked) {
                          _startTest(testId, testTitle, durationMins);
                        } else {
                          final cartItem = CartItem(
                            id: item.id,
                            title: item.title,
                            description: item.description,
                            price: item.price,
                            originalPrice: item.originalPrice,
                            bannerImageUrl: item.bannerImageUrl ?? '',
                            exam: item.exam,
                            validity: item.validity,
                            testCount: item.testCount,
                          );
                          context.push('/checkout', extra: cartItem);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isUnlocked ? 'Start Test' : 'Buy Now',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
      ],
    );
  }

  // ==========================================
  // TAB 3: SYLLABUS
  // ==========================================
  Widget _buildSyllabusTab(TestSeriesCardData item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE))),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF2563EB), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Official Test Schedule & Syllabus Blueprint', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                      const SizedBox(height: 2),
                      Text('Download the detailed PDF mapping for all chapter and unit tests.', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF3B82F6))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  onPressed: _downloadSyllabus,
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: const Text('Download PDF', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Curriculum Topics Covered:', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          _buildSyllabusTopicRow('Physics', 'Kinematics, Thermodynamics, Optics, Modern Physics, Magnetism & Current Electricity'),
          _buildSyllabusTopicRow('Chemistry', 'Physical Chemistry, Organic Mechanisms, Coordination Compounds, Electrochemistry'),
          _buildSyllabusTopicRow('Botany / Zoology', 'Cell Biology, Genetics, Human Physiology, Ecology, Molecular Basis of Inheritance'),
        ],
      ),
    );
  }

  Widget _buildSyllabusTopicRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
            child: Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(desc, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)))),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: REVIEWS
  // ==========================================
  Widget _buildReviewsTab(TestSeriesCardData item) {
    final reviews = item.reviews.isNotEmpty
        ? item.reviews
        : [
            {'name': 'Aarav Sharma', 'comment': 'Matches the exact NTA pattern! Helped me manage time efficiently.', 'rating': 5},
            {'name': 'Sneha Patel', 'comment': 'Best detailed solutions and All India Rank insights.', 'rating': 5},
            {'name': 'Rohan Verma', 'comment': 'Extremely realistic CBT experience.', 'rating': 5},
          ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final r = reviews[index];
        final name = (r['name'] ?? 'Aspirant').toString();
        final comment = (r['comment'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 14, backgroundColor: const Color(0xFF2563EB), child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 11))),
                  const SizedBox(width: 8),
                  Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  const Spacer(),
                  Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14))),
                ],
              ),
              const SizedBox(height: 6),
              Text(comment, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 5: TOP SCORES
  // ==========================================
  Widget _buildTopScoresTab(TestSeriesCardData item) {
    final maxScore = item.exam.contains('JEE') ? 300 : 720;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildTopScoreMetric('Highest Score', '${maxScore - 8} / $maxScore', const Color(0xFF10B981))),
              const SizedBox(width: 10),
              Expanded(child: _buildTopScoreMetric('Average Score', '${(maxScore * 0.78).toInt()} / $maxScore', const Color(0xFF2563EB))),
              const SizedBox(width: 10),
              Expanded(child: _buildTopScoreMetric('Active Aspirants', '1,480+', const Color(0xFF7C3AED))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopScoreMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT SIDEBAR (PRICING & INCLUDED CARDS)
  // ==========================================
  Widget _buildRightSidebar(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    final discount = item.originalPrice > 0 ? (((item.originalPrice - item.price) / item.originalPrice) * 100).toInt() : 85;

    final chapterCount = tests.where((t) => t['type'].toString().toLowerCase().contains('chapter')).length;
    final partCount = tests.where((t) => t['type'].toString().toLowerCase().contains('part')).length;
    final unitCount = tests.where((t) => t['type'].toString().toLowerCase().contains('unit')).length;
    final fullCount = tests.where((t) => t['type'].toString().toLowerCase().contains('full') || (!t['type'].toString().toLowerCase().contains('chapter') && !t['type'].toString().toLowerCase().contains('part') && !t['type'].toString().toLowerCase().contains('unit'))).length;

    final displayChapter = chapterCount > 0 ? chapterCount : 10;
    final displayPart = partCount > 0 ? partCount : 10;
    final displayUnit = unitCount > 0 ? unitCount : 8;
    final displayFull = fullCount > 0 ? fullCount : 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CARD 1: Price Box & Green Buy Button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹${item.price.toInt()}',
                    style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${item.originalPrice.toInt()}',
                    style: GoogleFonts.inter(fontSize: 14, decoration: TextDecoration.lineThrough, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                    child: Text('$discount% OFF', style: const TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Instant Access • ${item.validity}',
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_hasPurchased || item.isFree) {
                      _tabController.animateTo(1);
                    } else {
                      final cartItem = CartItem(
                        id: item.id,
                        title: item.title,
                        description: item.description,
                        price: item.price,
                        originalPrice: item.originalPrice,
                        bannerImageUrl: item.bannerImageUrl ?? '',
                        exam: item.exam,
                        validity: item.validity,
                        testCount: item.testCount,
                      );
                      context.push('/checkout', extra: cartItem);
                    }
                  },
                  icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                  label: Text(
                    _hasPurchased || item.isFree ? 'Start Learning' : 'Buy Now for ₹${item.price.toInt()}',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGuaranteeItem(Icons.access_time_rounded, 'Instant Access\nafter payment'),
                  _buildGuaranteeItem(Icons.lock_outline_rounded, 'Secure\nPayment'),
                  _buildGuaranteeItem(Icons.refresh_rounded, '7 Days\nRefund Policy'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CARD 2: What's Included Card
        Container(
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
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 8),
                  Text("What's Included", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 14),
              _buildIncludedItem(Icons.description_outlined, '${tests.length} Tests', 'Chapter + Part + Unit + Full Syllabus'),
              _buildIncludedItem(Icons.menu_book_outlined, 'Detailed Solutions', 'Step-by-step explanations with concepts'),
              _buildIncludedItem(Icons.insights_rounded, 'Performance Analytics', 'Subject-wise & chapter-wise insights'),
              _buildIncludedItem(Icons.emoji_events_outlined, 'All India Ranking', 'Compare with NEET aspirants across India'),
              _buildIncludedItem(Icons.check_circle_outline_rounded, 'Latest NTA Pattern', 'Based on latest NEET pattern & syllabus'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CARD 3: Test Schedule Card
        Container(
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
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 8),
                      Text('Test Schedule', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Text('View Full Schedule ->', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildScheduleRow(const Color(0xFF2563EB), 'Chapter Tests', '$displayChapter Tests'),
              _buildScheduleRow(const Color(0xFF059669), 'Part Tests', '$displayPart Tests'),
              _buildScheduleRow(const Color(0xFFD97706), 'Unit Tests', '$displayUnit Tests'),
              _buildScheduleRow(const Color(0xFFDC2626), 'Full Syllabus Tests', '$displayFull Tests'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CARD 4: Join Aspirants Banner Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFF7C3AED), size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Join 1,480+ Serious Aspirants', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF5B21B6))),
                    const SizedBox(height: 2),
                    Text("Get ahead with India's most trusted ${item.exam} test series", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6D28D9))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuaranteeItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B), height: 1.2),
        ),
      ],
    );
  }

  Widget _buildIncludedItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(Color dotColor, String label, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)))),
          Text(count, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
