import 'package:flutter/material.dart';
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
  bool _hasPurchased = false;
  bool _checkingAccess = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

    Map<String, dynamic>? match;
    for (var m in allSeriesMaps) {
      if ((m['id']?.toString() ?? '') == widget.productId ||
          (m['paper_id']?.toString() ?? '') == widget.productId) {
        match = m;
        break;
      }
    }

    if (match == null) {
      for (var def in SupabaseService.defaultCuratedTestSeries) {
        if ((def['id']?.toString() ?? '') == widget.productId) {
          match = def;
          break;
        }
      }
    }

    // If still null, check default fallback
    match ??= SupabaseService.defaultCuratedTestSeries.first;

    final String title = (match['title'] ?? match['name'] ?? 'Test Series').toString().trim();
    final exam = (match['exam'] ?? 'NEET').toString();
    final year = (match['year'] ?? '2026').toString();
    final qCount = (match['question_count'] is num) ? (match['question_count'] as num).toInt() : 200;
    final duration = (match['duration_minutes'] is num) ? (match['duration_minutes'] as num).toInt() : 180;
    final testCount = (match['test_count'] is num) ? (match['test_count'] as num).toInt() : 10;
    final difficulty = (match['difficulty'] ?? 'Moderate').toString();
    final testType = (match['test_type'] ?? match['testType'] ?? 'Full').toString();
    final validity = (match['validity'] ?? 'Valid until exam').toString();
    final attemptStatus = (match['attempt_status'] ?? match['attemptStatus'] ?? 'Not Attempted').toString();
    final syllabusUrl = (match['syllabus_url'] ?? match['syllabusUrl'] ?? '').toString();
    final isFree = match['is_free'] == true || match['isFree'] == true;
    final price = (match['price'] is num) ? (match['price'] as num).toDouble() : 499.0;
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
          : 'Comprehensive mock tests covering full syllabus with step-by-step solutions.',
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
        _checkingAccess = false;
        _isLoading = false;
      });
    }
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
          content: Text('Downloading syllabus for ${item.title}...'),
          backgroundColor: const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startTest(String testId, String testTitle, int durationMins) {
    // Navigate into the test directly
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
    if (_isLoading || _product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
          ),
          title: Text('Loading Course...', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 16)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    final item = _product!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Shopping Cart',
            onPressed: () => context.push('/cart'),
            icon: AnimatedBuilder(
              animation: CartService.instance,
              builder: (ctx, _) => Badge(
                isLabelVisible: CartService.instance.isNotEmpty,
                label: Text('${CartService.instance.itemCount}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                backgroundColor: const Color(0xFFEF4444),
                child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF334155)),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Header Banner Card
                      _buildHeroHeader(item),

                      // Sticky Tab Bar
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF4F46E5),
                          unselectedLabelColor: const Color(0xFF64748B),
                          indicatorColor: const Color(0xFF4F46E5),
                          indicatorWeight: 3,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                          tabs: const [
                            Tab(text: 'Overview', icon: Icon(Icons.info_outline_rounded, size: 18)),
                            Tab(text: 'All Tests', icon: Icon(Icons.format_list_bulleted_rounded, size: 18)),
                            Tab(text: 'Reviews', icon: Icon(Icons.star_outline_rounded, size: 18)),
                            Tab(text: 'Top Scores', icon: Icon(Icons.emoji_events_outlined, size: 18)),
                          ],
                        ),
                      ),

                      // Tab View Canvas
                      SizedBox(
                        height: 580,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(item),
                            _buildAllTestsTab(item),
                            _buildReviewsTab(item),
                            _buildTopScoresTab(item),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sticky Bottom Action Bar
          _buildStickyBottomBar(item),
        ],
      ),
    );
  }

  // ==========================================
  // 1. HERO HEADER BANNER
  // ==========================================
  Widget _buildHeroHeader(TestSeriesCardData item) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
                child: Text(item.exam, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
                child: Text('Target: ${item.formattedTargetYear}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              if (item.isFree)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                  child: const Text('100% FREE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              if (_hasPurchased)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                  child: const Text('ENROLLED ✓', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            item.title,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25),
          ),
          const SizedBox(height: 12),

          // Rating Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(6)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('4.9 (1,480+ Aspirants Enrolled)', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Meta Specs Grid / Wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPill(Icons.description_outlined, '${item.testCount} Estimated Tests'),
              _buildPill(Icons.category_outlined, 'Type: ${item.testType}'),
              _buildPill(Icons.timer_outlined, item.durationFormatted),
              _buildPill(Icons.bar_chart_rounded, item.difficulty),
              _buildPill(Icons.verified_outlined, item.validity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW
  // ==========================================
  Widget _buildOverviewTab(TestSeriesCardData item) {
    final features = item.features.isNotEmpty
        ? item.features.map((e) => e.toString()).toList()
        : [
            'Simulated computer-based test platform matching real exam interface',
            'Full syllabus mock tests based on latest official syllabus & pattern',
            'Detailed step-by-step solutions with diagrams and formulas',
            'All India Rank (AIR) & percentile performance analytics',
            'Chapter-wise & topic-wise weak area diagnostics',
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About This Test Series', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(
            item.longDescription.isNotEmpty ? item.longDescription : item.description,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569), height: 1.6),
          ),
          const SizedBox(height: 24),

          Text('Key Highlights & Inclusions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 12),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF334155), height: 1.4))),
                  ],
                ),
              )),
          const SizedBox(height: 20),

          // Download Syllabus CTA card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB), size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Official Exam Syllabus', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                      const SizedBox(height: 2),
                      Text('Detailed chapter weightage and topic breakdown', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3B82F6))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: _downloadSyllabus,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: ALL TESTS
  // ==========================================
  Widget _buildAllTestsTab(TestSeriesCardData item) {
    final tests = item.tests.isNotEmpty
        ? item.tests
        : List.generate(
            item.testCount > 0 ? item.testCount : 5,
            (index) => {
              'id': 'test_${index + 1}',
              'title': 'Mock Test ${index + 1 < 10 ? '0${index + 1}' : '${index + 1}'} (${item.exam} Pattern)',
              'duration': item.durationMinutes,
              'questions': item.durationMinutes == 180 ? 200 : (item.durationMinutes == 60 ? 50 : 30),
              'marks': item.durationMinutes == 180 ? 720 : (item.durationMinutes == 60 ? 200 : 120),
              'status': index == 0 ? 'Ready' : (index % 3 == 0 ? 'Completed' : 'Available'),
            },
          );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final t = tests[index];
        final testTitle = (t['title'] ?? 'Mock Test ${index + 1}').toString();
        final testId = (t['id'] ?? 'test_${index + 1}').toString();
        final durationMins = (t['duration'] is num) ? (t['duration'] as num).toInt() : item.durationMinutes;
        final qCount = (t['questions'] is num) ? (t['questions'] as num).toInt() : 200;
        final marks = (t['marks'] is num) ? (t['marks'] as num).toInt() : 720;
        final status = (t['status'] ?? 'Available').toString();

        final bool isUnlocked = item.isFree || _hasPurchased;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnlocked ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                  color: isUnlocked ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(testTitle, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('$durationMins Mins • $qCount Qs • $marks Marks', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnlocked ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (isUnlocked) {
                    _startTest(testId, testTitle, durationMins);
                  } else {
                    // Navigate to checkout
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
                child: Text(
                  isUnlocked ? (status == 'Completed' ? 'Retake' : 'Start') : 'Unlock',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: REVIEWS
  // ==========================================
  Widget _buildReviewsTab(TestSeriesCardData item) {
    final reviews = item.reviews.isNotEmpty
        ? item.reviews
        : [
            {
              'name': 'Aarav Sharma',
              'rating': 5.0,
              'date': '2 days ago',
              'comment': 'The question standard matches the real NEET paper exceptionally well. Physics calculations and Biology assertion-reason questions are top notch.',
              'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=80',
              'verified': true,
            },
            {
              'name': 'Priya Patel',
              'rating': 5.0,
              'date': '1 week ago',
              'comment': 'Helped me boost my score from 560 to 670 in 6 weeks! Highly recommended for all serious aspirants.',
              'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&auto=format&fit=crop&q=80',
              'verified': true,
            },
            {
              'name': 'Rohan M.',
              'rating': 4.8,
              'date': '2 weeks ago',
              'comment': 'The time analysis and question-level difficulty breakdown is identical to the actual NTA test interface.',
              'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120&auto=format&fit=crop&q=80',
              'verified': true,
            }
          ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final r = reviews[index];
        final name = (r['name'] ?? 'Aspirant').toString();
        final comment = (r['comment'] ?? '').toString();
        final rating = (r['rating'] is num) ? (r['rating'] as num).toDouble() : 5.0;
        final date = (r['date'] ?? 'Recently').toString();
        final avatar = (r['avatar'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    backgroundColor: const Color(0xFF4F46E5),
                    child: avatar.isEmpty ? Text(name[0], style: const TextStyle(color: Colors.white)) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        Text(date, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (starIdx) => Icon(
                        starIdx < rating.floor() ? Icons.star_rounded : Icons.star_half_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(comment, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.4)),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: TOP SCORES & LEADERBOARD
  // ==========================================
  Widget _buildTopScoresTab(TestSeriesCardData item) {
    final topScores = item.topScores;
    final highest = topScores['highest_score'] ?? (item.exam.contains('JEE') ? 295 : 715);
    final avg = topScores['average_score'] ?? (item.exam.contains('JEE') ? 168 : 548);
    final total = topScores['total_participants'] ?? 14280;

    final rankers = (topScores['top_rankers'] is List)
        ? (topScores['top_rankers'] as List).whereType<Map>().toList()
        : [
            {'rank': 1, 'name': 'Aditya R.', 'score': highest, 'max_score': item.exam.contains('JEE') ? 300 : 720, 'accuracy': '98.2%', 'percentile': '99.99%', 'badge': 'AIR 1'},
            {'rank': 2, 'name': 'Sneha K.', 'score': (highest is num) ? (highest - 7) : 708, 'max_score': item.exam.contains('JEE') ? 300 : 720, 'accuracy': '97.5%', 'percentile': '99.95%', 'badge': 'AIR 2'},
            {'rank': 3, 'name': 'Rohan M.', 'score': (highest is num) ? (highest - 14) : 701, 'max_score': item.exam.contains('JEE') ? 300 : 720, 'accuracy': '96.8%', 'percentile': '99.89%', 'badge': 'AIR 3'},
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Highlights Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreStat('Highest Score', '$highest', const Color(0xFF16A34A)),
                _buildScoreStat('Avg Score', '$avg', const Color(0xFF2563EB)),
                _buildScoreStat('Participants', '$total+', const Color(0xFF7C3AED)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Top Rankers & Percentile Leaderboard', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 12),

          ...rankers.map((rk) {
            final rank = rk['rank'] ?? 1;
            final rkName = (rk['name'] ?? 'Candidate').toString();
            final score = rk['score'] ?? 0;
            final maxScore = rk['max_score'] ?? (item.exam.contains('JEE') ? 300 : 720);
            final accuracy = (rk['accuracy'] ?? '95%').toString();
            final percentile = (rk['percentile'] ?? '99%').toString();
            final badge = (rk['badge'] ?? 'AIR $rank').toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: rank <= 3 ? const Color(0xFFD97706) : const Color(0xFF64748B))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(rkName, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(4)),
                              child: Text(badge, style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Accuracy: $accuracy • Percentile: $percentile', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Text('$score / $maxScore', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
      ],
    );
  }

  // ==========================================
  // STICKY BOTTOM ACTION BAR
  // ==========================================
  Widget _buildStickyBottomBar(TestSeriesCardData item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.isFree)
                  const Text('FREE ACCESS', style: TextStyle(color: Color(0xFF16A34A), fontSize: 16, fontWeight: FontWeight.w900))
                else
                  Row(
                    children: [
                      Text(
                        '₹${item.price.toInt()}',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${item.originalPrice.toInt()}',
                        style: GoogleFonts.inter(fontSize: 12, decoration: TextDecoration.lineThrough, color: const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          '${(((item.originalPrice - item.price) / item.originalPrice) * 100).toInt()}% OFF',
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                Text(
                  _hasPurchased ? 'Unlocked • ${item.validity}' : 'Instant Access • ${item.validity}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
            const Spacer(),

            // DYNAMIC CTAs
            if (SupabaseService.activeUserSession == null) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login_rounded, size: 16),
                label: const Text('Sign In to Enroll', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ] else if (_hasPurchased || item.isFree) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  _tabController.animateTo(1); // Switch to All Tests tab
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start Learning', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              // Add to Cart
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFF4F46E5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
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
                  final added = await CartService.instance.addToCart(cartItem);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(added ? '✓ Added "${item.title}" to Cart!' : 'Product already in cart.'),
                        backgroundColor: added ? const Color(0xFF4F46E5) : const Color(0xFFF59E0B),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: const Text('Add to Cart', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),

              // Buy Now -> Direct Page Navigation to /checkout
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
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
                },
                icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                label: Text(
                  'Buy Now - ₹${item.price.toInt()}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
