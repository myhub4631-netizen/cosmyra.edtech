import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import '../../core/theme/app_design_system.dart';
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
  String _selectedReviewFilter = 'All';
  bool _isAboutExpanded = false;

  // Dynamic reviews state
  List<Map<String, dynamic>> _dynamicReviews = [];

  // Dynamic Leaderboard state
  List<Map<String, dynamic>> _leaderboardRankings = [];
  bool _loadingLeaderboard = false;
  bool _isPointsMode = false;
  String _selectedLeaderboardScope = 'All India';

  double get _avgRating {
    if (_dynamicReviews.isEmpty) return 0.0;
    final total = _dynamicReviews.fold<num>(0, (sum, r) {
      final val = r['rating'];
      return sum + (val is num ? val : double.tryParse(val.toString()) ?? 5.0);
    });
    return total / _dynamicReviews.length;
  }

  int get _reviewCount => _dynamicReviews.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {});
      }
    });
    _loadProductData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewsData(String productId) async {
    List<Map<String, dynamic>> reviews = [];
    try {
      final res = await SupabaseService.client
          .from('system_config')
          .select('value')
          .eq('key', 'reviews_$productId')
          .maybeSingle();
      if (res != null && res['value'] != null) {
        final raw = res['value'];
        if (raw is List) {
          reviews = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Notice loading reviews from Supabase system_config: $e');
    }

    if (reviews.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('cosmyra_reviews_$productId');
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as List;
          reviews = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (e) {
        debugPrint('Notice loading local reviews: $e');
      }
    }

    if (mounted && reviews.isNotEmpty) {
      setState(() {
        _dynamicReviews = reviews;
      });
    }
  }

  Future<void> _saveReview(String productId, Map<String, dynamic> review) async {
    setState(() {
      _dynamicReviews.insert(0, review);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cosmyra_reviews_$productId', jsonEncode(_dynamicReviews));
    } catch (_) {}

    try {
      await SupabaseService.client.from('system_config').upsert({
        'key': 'reviews_$productId',
        'value': _dynamicReviews,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Notice saving review to Supabase system_config: $e');
    }
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
    final price = (match['price'] is num) ? (match['price'] as num).toDouble() : 499.0;
    final origPrice = (match['original_price'] is num) ? (match['original_price'] as num).toDouble() : 1999.0;
    final purchaseLink = (match['purchase_link'] ?? '').toString();
    final buttonText = (match['purchase_button_text'] ?? 'Join').toString();
    final showPurchaseButton = match['show_purchase_button'] != false;

    final rawReviews = (match['reviews'] is List)
        ? (match['reviews'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    final loadedProduct = TestSeriesCardData(
      id: widget.productId,
      title: title,
      exam: exam,
      targetYear: year,
      subtitle: '$exam $year Series ($qCount Qs)',
      description: (match['description'] ?? '').toString().trim().isNotEmpty
          ? match['description'].toString().trim()
          : 'Complete $exam $year preparation with practice tests, full syllabus papers, and detailed step-by-step solutions following the latest NTA pattern.',
      longDescription: (match['long_description'] ?? match['longDescription'] ?? match['description'] ?? '').toString(),
      features: (match['features'] is List) ? List<dynamic>.from(match['features']) : const [],
      tests: (match['tests'] is List)
          ? (match['tests'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : const [],
      reviews: rawReviews,
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

    final user = SupabaseService.activeUserSession;
    bool owns = false;
    if (user != null) {
      owns = await SupabaseService.hasActiveEntitlement(user.id, widget.productId);
    }

    if (mounted) {
      setState(() {
        _product = loadedProduct;
        _dynamicReviews = rawReviews;
        _hasPurchased = owns;
        _isLoading = false;
      });
    }

    _loadReviewsData(widget.productId);
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    if (!mounted) return;
    setState(() => _loadingLeaderboard = true);

    final user = SupabaseService.activeUserSession;
    final result = await SupabaseService.fetchRealLeaderboardRankings(
      exam: _product?.exam ?? 'NEET',
      isPointsMode: _isPointsMode,
      currentUserId: user?.id,
    );

    final List<Map<String, dynamic>> rankings = (result['rankings'] is List)
        ? List<Map<String, dynamic>>.from(result['rankings'])
        : <Map<String, dynamic>>[];

    final maxScore = (_product?.exam.contains('JEE') ?? false) ? 300 : 720;

    if (mounted) {
      setState(() {
        _leaderboardRankings = rankings;
        _loadingLeaderboard = false;
      });
    }
  }

  List<Map<String, dynamic>> _resolveSeriesTests() {
    final item = _product;
    if (item == null) return [];

    final Map<String, Map<String, dynamic>> testMap = {};

    // 1. Add embedded tests from item.tests
    for (var t in item.tests) {
      final m = Map<String, dynamic>.from(t);
      final id = (m['id'] ?? m['paper_id'] ?? '').toString().trim();
      final title = (m['title'] ?? m['paper_name'] ?? 'Mock Test ${testMap.length + 1}').toString().trim();
      final key = id.isNotEmpty ? id.toLowerCase() : title.toLowerCase();

      testMap[key] = {
        'id': id.isNotEmpty ? id : 'test_${testMap.length + 1}',
        'number': (m['number'] ?? '${testMap.length + 1 < 10 ? '0${testMap.length + 1}' : '${testMap.length + 1}'}').toString(),
        'title': title,
        'type': (m['type'] ?? m['paper_type'] ?? item.testType).toString(),
        'questions': m['questions'] ?? m['saved_questions_count'] ?? m['question_count'] ?? (item.exam.contains('JEE') ? 90 : 200),
        'marks': m['marks'] ?? m['total_marks'] ?? (item.exam.contains('JEE') ? 300 : 720),
        'duration': m['duration'] ?? m['duration_minutes'] ?? (item.durationMinutes > 0 ? item.durationMinutes : 180),
        'status': (m['status'] ?? 'Not Attempted').toString(),
      };
    }

    // 2. Scan all papers in _dbPapers to find any created papers matching this test series
    final itemTitleLower = item.title.trim().toLowerCase();
    final itemIdLower = item.id.trim().toLowerCase();
    final itemExamLower = item.exam.trim().toLowerCase();

    for (var p in _dbPapers) {
      final pId = (p['id'] ?? '').toString().trim();
      final pSeriesId = (p['test_series_id'] ?? p['series_id'] ?? '').toString().trim().toLowerCase();
      final pSeriesTitle = (p['test_series_title'] ?? p['new_test_series_name'] ?? p['existing_test_series'] ?? p['test_series'] ?? p['testSeriesTitle'] ?? '').toString().trim().toLowerCase();
      final pName = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? '').toString().trim().toLowerCase();
      final pExam = (p['target_exam'] ?? p['exam'] ?? '').toString().trim().toLowerCase();
      final isTs = p['is_test_series'] == true || (p['available_in'] is List && (p['available_in'] as List).contains('test_series'));

      bool isMatch = false;
      if (pSeriesId.isNotEmpty && (pSeriesId == itemIdLower || itemIdLower.contains(pSeriesId) || pSeriesId.contains(itemIdLower))) {
        isMatch = true;
      }
      if (pSeriesTitle.isNotEmpty && (pSeriesTitle == itemTitleLower || itemTitleLower.contains(pSeriesTitle) || pSeriesTitle.contains(itemTitleLower))) {
        isMatch = true;
      }
      if (pName.isNotEmpty && (pName == itemTitleLower || itemTitleLower.contains(pName) || pName.contains(itemTitleLower))) {
        isMatch = true;
      }
      if (isTs && pExam.isNotEmpty && itemExamLower.isNotEmpty && pExam.contains(itemExamLower)) {
        if (pSeriesTitle.isEmpty || pSeriesTitle == itemTitleLower || itemTitleLower.contains(pSeriesTitle) || pSeriesTitle.contains(itemTitleLower)) {
          isMatch = true;
        }
      }

      if (isMatch) {
        final paperTitleStr = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? 'Test Paper ${testMap.length + 1}').toString().trim();
        final key = pId.isNotEmpty ? pId.toLowerCase() : paperTitleStr.toLowerCase();

        if (!testMap.containsKey(key)) {
          testMap[key] = {
            'id': pId.isNotEmpty ? pId : 'test_${testMap.length + 1}',
            'number': '${testMap.length + 1 < 10 ? '0${testMap.length + 1}' : '${testMap.length + 1}'}',
            'title': paperTitleStr,
            'type': p['paper_type'] ?? p['type'] ?? item.testType,
            'questions': p['saved_questions_count'] ?? p['question_count'] ?? p['total_questions'] ?? (item.exam.contains('JEE') ? 90 : 200),
            'marks': p['total_marks'] ?? p['marks'] ?? (item.exam.contains('JEE') ? 300 : 720),
            'duration': p['duration_minutes'] ?? p['duration'] ?? (item.durationMinutes > 0 ? item.durationMinutes : 180),
            'status': p['status'] ?? 'Not Attempted',
          };
        } else {
          final existing = testMap[key]!;
          if (pId.isNotEmpty) existing['id'] = pId;
          if (p['saved_questions_count'] != null) existing['questions'] = p['saved_questions_count'];
          if (p['total_marks'] != null) existing['marks'] = p['total_marks'];
          if (p['duration_minutes'] != null) existing['duration'] = p['duration_minutes'];
        }
      }
    }

    final result = testMap.values.toList();
    for (int i = 0; i < result.length; i++) {
      result[i]['number'] = '${i + 1 < 10 ? '0${i + 1}' : '${i + 1}'}';
    }
    return result;
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

  void _openWriteReviewDialog() {
    int selectedStars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 24),
                const SizedBox(width: 8),
                Text('Write a Review', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rate your experience:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      final starNum = idx + 1;
                      return IconButton(
                        onPressed: () => setDialogState(() => selectedStars = starNum),
                        icon: Icon(
                          starNum <= selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text('Your Review Comment:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share how this test series helped your exam preparation...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final text = commentController.text.trim();
                  if (text.isNotEmpty) {
                    final user = SupabaseService.activeUserSession;
                    final userName = user?.fullName ?? (user != null && user.email.isNotEmpty ? user.email.split('@')[0] : 'Verified Student');
                    final newReview = {
                      'id': 'rev_${DateTime.now().millisecondsSinceEpoch}',
                      'name': userName,
                      'aspirant': '${_product?.exam ?? 'NEET'} ${_product?.targetYear ?? '2027'} Aspirant',
                      'date': 'Just now',
                      'rating': selectedStars,
                      'comment': text,
                      'tags': ['Verified Review'],
                      'verified': true,
                    };
                    await _saveReview(widget.productId, newReview);
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Thank you! Your review has been published.'),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: Text('Submit Review', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
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
      backgroundColor: isDesktop ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () => context.canPop() ? context.pop() : context.go('/test-series'),
              ),
              title: Text(
                item.title,
                style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A), size: 22),
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
                AnimatedBuilder(
                  animation: CartService.instance,
                  builder: (context, _) {
                    final count = CartService.instance.itemCount;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A), size: 22),
                          onPressed: () => context.go('/cart'),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                '$count',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              ),
            ),
      body: SafeArea(
        child: isDesktop
            ? Column(
                children: [
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
                          'Details',
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

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 68,
                                child: _buildLeftColumn(item, tests),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 360,
                                child: _buildRightSidebar(item, tests),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildMobileMainContent(item, tests),
              ),
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileStickyBottomBar(item),
    );
  }

  // ==========================================
  // MOBILE MAIN CONTENT
  // ==========================================
  Widget _buildMobileMainContent(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    final formattedTarget = item.formattedTargetYear.toLowerCase().contains(item.exam.toLowerCase())
        ? item.formattedTargetYear
        : '${item.exam} ${item.formattedTargetYear}';

    final perTestMins = item.durationMinutes > 0 ? item.durationMinutes : 180;
    final durationStr = perTestMins >= 60 ? '${(perTestMins / 60).toStringAsFixed(0)} Hours' : '$perTestMins Mins';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero Banner
        Hero(
          tag: 'test_series_banner_${item.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: double.infinity,
              height: 190,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0B1329)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x1F0F172A), blurRadius: 10, offset: Offset(0, 4)),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: item.bannerImageUrl != null && item.bannerImageUrl!.isNotEmpty ? 0.45 : 0.85),
                        Colors.black.withValues(alpha: 0.25),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
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
                            const Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Best Seller',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (item.bannerImageUrl == null || item.bannerImageUrl!.isEmpty) ...[
                        Text(
                          formattedTarget.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFFFACC15), height: 1.0, letterSpacing: -0.5),
                        ),
                        Text(
                          item.title.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: 0.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Practice Tests • Detailed Solutions • Analytics',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xE6FFFFFF), fontWeight: FontWeight.w500),
                        ),
                      ],
                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x73000000),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x26FFFFFF)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBannerChip(Icons.description_outlined, '${tests.length} Tests'),
                            _buildBannerChip(Icons.menu_book_outlined, 'Solutions'),
                            _buildBannerChip(Icons.analytics_outlined, 'Analytics'),
                            _buildBannerChip(Icons.emoji_events_outlined, 'AIR Rank'),
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
      ),
    ),
    const SizedBox(height: 16),

        // 2. Category Badges & Title Section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.exam.toUpperCase(),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Target: $formattedTarget',
                style: GoogleFonts.inter(color: const Color(0xFF4338CA), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Text(
          item.title,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.2),
        ),
        const SizedBox(height: 8),

        // Rating & Enrolled Line (Clean Responsive Layout without hardcoded fake strings)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  _reviewCount > 0
                      ? '${_avgRating.toStringAsFixed(1)} ($_reviewCount ${_reviewCount == 1 ? 'Review' : 'Reviews'})'
                      : 'No Reviews Yet',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.rate_review_outlined, size: 16, color: Color(0xFF4338CA)),
                const SizedBox(width: 4),
                Text(
                  _reviewCount > 0 ? '$_reviewCount ${_reviewCount == 1 ? 'Review' : 'Reviews'}' : '0 Reviews',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        Text(
          item.description,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.45),
        ),
        const SizedBox(height: 16),

        // 3. Key Metric Tiles (100% Dynamic)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: [
            _buildMobileMetricTile(
              Icons.description_outlined,
              '${tests.length} Tests',
              'Available Tests',
              const Color(0xFFF0F7FF),
              const Color(0xFF2563EB),
            ),
            _buildMobileMetricTile(
              Icons.access_time_rounded,
              durationStr,
              'Per Test',
              const Color(0xFFF5F3FF),
              const Color(0xFF7C3AED),
            ),
            _buildMobileMetricTile(
              Icons.bar_chart_rounded,
              item.difficulty,
              'Difficulty',
              const Color(0xFFEEF2FF),
              const Color(0xFF4F46E5),
            ),
            _buildMobileMetricTile(
              Icons.calendar_today_outlined,
              item.validity,
              'Validity',
              const Color(0xFFF3F0FF),
              const Color(0xFF9333EA),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4. Feature Highlights Strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGreenHighlightItem(Icons.check_circle_rounded, 'Latest NTA Pattern'),
              _buildGreenHighlightItem(Icons.description_outlined, 'Detailed Solutions'),
              _buildGreenHighlightItem(Icons.analytics_outlined, 'Performance Analytics'),
              _buildGreenHighlightItem(Icons.emoji_events_outlined, 'All India Ranking'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 5. Product Tabs Header & Seamless Content (3 TABS ONLY)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: [
                    const Tab(icon: Icon(Icons.info_outline_rounded, size: 16), text: 'Overview'),
                    Tab(icon: const Icon(Icons.format_list_bulleted_rounded, size: 16), text: 'All Tests (${tests.length})'),
                    const Tab(icon: Icon(Icons.emoji_events_outlined, size: 16), text: 'Top Scores'),
                  ],
                ),
              ),

              // Smooth Tab Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSelectedTabContent(item, tests),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMobileMetricTile(IconData icon, String title, String subtitle, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenHighlightItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStickyBottomBar(TestSeriesCardData item) {
    final discountPercent = item.originalPrice > item.price
        ? (((item.originalPrice - item.price) / item.originalPrice) * 100).toInt()
        : 75;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      item.isFree ? 'FREE' : '₹${item.price.toInt()}',
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                    ),
                    if (!item.isFree && item.originalPrice > item.price) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹${item.originalPrice.toInt()}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), decoration: TextDecoration.lineThrough),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Instant Access • ${item.validity}',
                  style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_hasPurchased || item.isFree ? Icons.play_arrow_rounded : Icons.shopping_cart_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  _hasPurchased || item.isFree ? 'Start Practice' : 'Buy Now for ₹${item.price.toInt()}',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DESKTOP LEFT COLUMN
  // ==========================================
  Widget _buildLeftColumn(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    final formattedTarget = item.formattedTargetYear.toLowerCase().contains(item.exam.toLowerCase())
        ? item.formattedTargetYear
        : '${item.exam} ${item.formattedTargetYear}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Graphic Banner
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
              BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
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
                        Colors.black.withValues(alpha: item.bannerImageUrl != null && item.bannerImageUrl!.isNotEmpty ? 0.45 : 0.85),
                        Colors.black.withValues(alpha: 0.2),
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

                      if (item.bannerImageUrl == null || item.bannerImageUrl!.isEmpty) ...[
                        Text(
                          formattedTarget.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFFFACC15), height: 1.0, letterSpacing: -0.5),
                        ),
                        Text(
                          item.title.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Practice Tests • Detailed Solutions • Performance Analytics',
                          style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                        ),
                      ],
                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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

        // Product Navigation Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500),
                  tabs: [
                    const Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Overview'),
                    Tab(icon: const Icon(Icons.format_list_bulleted_rounded, size: 18), text: 'All Tests (${tests.length})'),
                    const Tab(icon: Icon(Icons.emoji_events_outlined, size: 18), text: 'Top Scores'),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildSelectedTabContent(item, tests),
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
  // TAB CONTROLLER SELECTOR
  // ==========================================
  Widget _buildSelectedTabContent(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    switch (_tabController.index) {
      case 0:
        return _buildOverviewTab(item, tests);
      case 1:
        return _buildAllTestsTab(item, tests);
      case 2:
        return _buildTopScoresTab(item);
      default:
        return _buildOverviewTab(item, tests);
    }
  }

  // ==========================================
  // TAB 1: OVERVIEW
  // ==========================================
  Widget _buildOverviewTab(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    final perTestMins = item.durationMinutes > 0 ? item.durationMinutes : 180;
    final durationStr = perTestMins >= 60 ? '${(perTestMins / 60).toStringAsFixed(0)} Hours' : '$perTestMins Mins';

    final aboutText = item.longDescription.isNotEmpty
        ? item.longDescription
        : 'Welcome to ${item.title}. This test series provides ${tests.length} tests designed specifically for ${item.exam} ${item.targetYear} aspirants with full syllabus coverage, detailed solutions, and instant analytics to track performance.';

    final List<Map<String, dynamic>> featureTiles = item.features.isNotEmpty
        ? item.features.map((f) => {'title': f.toString(), 'sub': 'Key Feature', 'icon': Icons.check_circle_outline}).toList()
        : [
            {
              'title': '${tests.length} Practice Tests',
              'sub': 'Full Syllabus & Chapter Papers',
              'icon': Icons.description_outlined,
              'bg': const Color(0xFFEFF6FF),
              'color': const Color(0xFF2563EB),
            },
            {
              'title': 'Detailed Solutions',
              'sub': 'Step-by-step explanations with concepts',
              'icon': Icons.menu_book_outlined,
              'bg': const Color(0xFFF5F3FF),
              'color': const Color(0xFF7C3AED),
            },
            {
              'title': '$durationStr Duration',
              'sub': 'Standard time limit per test paper',
              'icon': Icons.access_time_rounded,
              'bg': const Color(0xFFECFDF5),
              'color': const Color(0xFF059669),
            },
            {
              'title': item.validity,
              'sub': 'Unlimited practice until exam date',
              'icon': Icons.calendar_today_outlined,
              'bg': const Color(0xFFFFF7ED),
              'color': const Color(0xFFD97706),
            },
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. About This Test Series Box
        Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'About This Test Series',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                aboutText,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.55),
                maxLines: _isAboutExpanded ? null : 3,
                overflow: _isAboutExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _isAboutExpanded = !_isAboutExpanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isAboutExpanded ? 'Show Less' : 'Read More',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 4),
                    Icon(_isAboutExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18, color: const Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. What's Included Box
        Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "What's Included",
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: featureTiles.map((ft) {
                  return _buildIncludedTile(
                    (ft['icon'] as IconData?) ?? Icons.check_circle_outline,
                    ft['title'].toString(),
                    ft['sub'].toString(),
                    (ft['bg'] as Color?) ?? const Color(0xFFEFF6FF),
                    (ft['color'] as Color?) ?? const Color(0xFF2563EB),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Syllabus Section
        _buildSyllabusSection(item),
        const SizedBox(height: 20),

        // 4. Reviews Section
        _buildReviewsSection(item),
      ],
    );
  }

  Widget _buildIncludedTile(IconData icon, String title, String subtitle, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SYLLABUS SECTION (COMPACT)
  // ==========================================
  Widget _buildSyllabusSection(TestSeriesCardData item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Schedule & Syllabus PDF',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _downloadSyllabus,
            icon: const Icon(Icons.download_rounded, size: 15),
            label: const Text('Download PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // REVIEWS SECTION (100% DYNAMIC DATA)
  // ==========================================
  Widget _buildReviewsSection(TestSeriesCardData item) {
    final reviews = _dynamicReviews;
    final totalR = reviews.isEmpty ? 1 : reviews.length;

    final count5 = reviews.where((r) => (r['rating'] ?? 5) == 5).length;
    final count4 = reviews.where((r) => (r['rating'] ?? 5) == 4).length;
    final count3 = reviews.where((r) => (r['rating'] ?? 5) == 3).length;
    final count2 = reviews.where((r) => (r['rating'] ?? 5) == 2).length;
    final count1 = reviews.where((r) => (r['rating'] ?? 5) == 1).length;

    final p5 = reviews.isEmpty ? 0.9 : count5 / totalR;
    final p4 = reviews.isEmpty ? 0.08 : count4 / totalR;
    final p3 = reviews.isEmpty ? 0.02 : count3 / totalR;
    final p2 = reviews.isEmpty ? 0.0 : count2 / totalR;
    final p1 = reviews.isEmpty ? 0.0 : count1 / totalR;

    final filteredReviews = reviews.where((r) {
      if (_selectedReviewFilter == 'All') return true;
      final starTarget = int.tryParse(_selectedReviewFilter.split(' ')[0]) ?? 5;
      return (r['rating'] ?? 5) == starTarget;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallScoreBox(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rating Breakdown', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        const SizedBox(height: 8),
                        _buildStarProgressBar('5', p5, '${(p5 * 100).toInt()}%', '($count5)'),
                        const SizedBox(height: 4),
                        _buildStarProgressBar('4', p4, '${(p4 * 100).toInt()}%', '($count4)'),
                        const SizedBox(height: 4),
                        _buildStarProgressBar('3', p3, '${(p3 * 100).toInt()}%', '($count3)'),
                        const SizedBox(height: 4),
                        _buildStarProgressBar('2', p2, '${(p2 * 100).toInt()}%', '($count2)'),
                        const SizedBox(height: 4),
                        _buildStarProgressBar('1', p1, '${(p1 * 100).toInt()}%', '($count1)'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSubMetricGrid(),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Student Reviews (${reviews.length})',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _openWriteReviewDialog,
              icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4F46E5)),
              label: Text('Write a Review', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (reviews.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildReviewFilterPill('All', 'All (${reviews.length})'),
                const SizedBox(width: 8),
                _buildReviewFilterPill('5 Stars', '5 ★ ($count5)'),
                const SizedBox(width: 8),
                _buildReviewFilterPill('4 Stars', '4 ★ ($count4)'),
                const SizedBox(width: 8),
                _buildReviewFilterPill('3 Stars', '3 ★ ($count3)'),
                const SizedBox(width: 8),
                _buildReviewFilterPill('2 Stars', '2 ★ ($count2)'),
                const SizedBox(width: 8),
                _buildReviewFilterPill('1 Star', '1 ★ ($count1)'),
              ],
            ),
          ),
        const SizedBox(height: 14),

        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.rate_review_outlined, size: 36, color: Color(0xFF94A3B8)),
                const SizedBox(height: 10),
                Text(
                  'No Reviews Yet',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first aspirant to share feedback and review this test series.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _openWriteReviewDialog,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Write a Review'),
                ),
              ],
            ),
          )
        else
          ...filteredReviews.map((r) {
            final name = (r['name'] ?? 'Aspirant').toString();
            final aspirant = (r['aspirant'] ?? '${item.exam} Aspirant').toString();
            final date = (r['date'] ?? 'Recently').toString();
            final rating = (r['rating'] is num) ? (r['rating'] as num).toDouble() : 5.0;
            final comment = (r['comment'] ?? '').toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF4F46E5),
                        child: Text(
                          name.isNotEmpty ? name[0] : 'A',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 15),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$aspirant • $date',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),

                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (idx) {
                              return Icon(
                                idx < rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 15,
                              );
                            }),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    comment,
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155), height: 1.45),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  // ==========================================
  // TAB 2: ALL TESTS
  // ==========================================
  Widget _buildAllTestsTab(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    final chapterTests = tests.where((t) => t['type'].toString().toLowerCase().contains('chapter')).toList();
    final partTests = tests.where((t) => t['type'].toString().toLowerCase().contains('part')).toList();
    final unitTests = tests.where((t) => t['type'].toString().toLowerCase().contains('unit')).toList();
    final fullTests = tests.where((t) => t['type'].toString().toLowerCase().contains('full') || (!t['type'].toString().toLowerCase().contains('chapter') && !t['type'].toString().toLowerCase().contains('part') && !t['type'].toString().toLowerCase().contains('unit'))).toList();

    List<Map<String, dynamic>> filterList(List<Map<String, dynamic>> source) {
      if (_testSearchQuery.trim().isEmpty) return source;
      final q = _testSearchQuery.trim().toLowerCase();
      return source.where((t) => (t['title'] ?? '').toString().toLowerCase().contains(q) || (t['type'] ?? '').toString().toLowerCase().contains(q)).toList();
    }

    final fChapter = filterList(chapterTests);
    final fPart = filterList(partTests);
    final fUnit = filterList(unitTests);
    final fFull = filterList(fullTests);
    final fAll = filterList(tests);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar & Filter
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
                    hintText: 'Search tests, papers...',
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
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryPill('All', 'All (${tests.length})'),
              const SizedBox(width: 8),
              if (chapterTests.isNotEmpty) ...[
                _buildCategoryPill('Chapter', 'Chapter (${chapterTests.length})'),
                const SizedBox(width: 8),
              ],
              if (partTests.isNotEmpty) ...[
                _buildCategoryPill('Part', 'Part (${partTests.length})'),
                const SizedBox(width: 8),
              ],
              if (unitTests.isNotEmpty) ...[
                _buildCategoryPill('Unit', 'Unit (${unitTests.length})'),
                const SizedBox(width: 8),
              ],
              _buildCategoryPill('Full Syllabus', 'Full Syllabus (${fullTests.length})'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (fAll.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_late_outlined, size: 36, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 14),
                Text(
                  tests.isEmpty ? 'No Test Papers Added Yet' : 'No Matching Papers Found',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  tests.isEmpty
                      ? 'Test papers for ${item.title} are currently being added by the admin. Check back soon!'
                      : 'Try adjusting your search query or category filters.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else ...[
          if (_selectedCategoryFilter == 'All' && fAll.isNotEmpty)
            _buildCategorySection(
              title: 'All Available Papers (${fAll.length})',
              subtitle: 'Complete list of created test papers',
              icon: Icons.assignment_rounded,
              headerBgColor: const Color(0xFFEFF6FF),
              iconBgColor: const Color(0xFF2563EB),
              textColor: const Color(0xFF1E40AF),
              btnBgColor: const Color(0xFFDBEAFE),
              btnTextColor: const Color(0xFF2563EB),
              testIconData: [Icons.science_rounded, Icons.functions_rounded, Icons.track_changes_rounded],
              testIconGradients: [
                [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
                [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                [const Color(0xFF064E3B), const Color(0xFF047857)],
              ],
              tests: fAll,
              item: item,
            ),

          if (_selectedCategoryFilter == 'Chapter' && fChapter.isNotEmpty)
            _buildCategorySection(
              title: 'Chapter Tests (${fChapter.length})',
              subtitle: 'Topic-wise tests for concept clarity',
              icon: Icons.menu_book_rounded,
              headerBgColor: const Color(0xFFECFDF5),
              iconBgColor: const Color(0xFF059669),
              textColor: const Color(0xFF065F46),
              btnBgColor: const Color(0xFFDCFCE7),
              btnTextColor: const Color(0xFF059669),
              testIconData: [Icons.public_rounded, Icons.science_rounded, Icons.balance_rounded],
              testIconGradients: [
                [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
                [const Color(0xFF4C0519), const Color(0xFF881337)],
                [const Color(0xFF451A03), const Color(0xFF78350F)],
              ],
              tests: fChapter,
              item: item,
            ),

          if (_selectedCategoryFilter == 'Part' && fPart.isNotEmpty)
            _buildCategorySection(
              title: 'Part Tests (${fPart.length})',
              subtitle: 'Combination of multiple chapters',
              icon: Icons.description_rounded,
              headerBgColor: const Color(0xFFF5F3FF),
              iconBgColor: const Color(0xFF7C3AED),
              textColor: const Color(0xFF5B21B6),
              btnBgColor: const Color(0xFFF3E8FF),
              btnTextColor: const Color(0xFF7C3AED),
              testIconData: [Icons.settings_rounded, Icons.settings_rounded, Icons.local_fire_department_rounded],
              testIconGradients: [
                [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                [const Color(0xFF0F172A), const Color(0xFF1E293B)],
              ],
              tests: fPart,
              item: item,
            ),

          if (_selectedCategoryFilter == 'Unit' && fUnit.isNotEmpty)
            _buildCategorySection(
              title: 'Unit Tests (${fUnit.length})',
              subtitle: 'Full unit coverage tests',
              icon: Icons.inventory_2_rounded,
              headerBgColor: const Color(0xFFFFFBEB),
              iconBgColor: const Color(0xFFD97706),
              textColor: const Color(0xFF92400E),
              btnBgColor: const Color(0xFFFEF3C7),
              btnTextColor: const Color(0xFFD97706),
              testIconData: [Icons.grid_view_rounded, Icons.center_focus_strong_rounded],
              testIconGradients: [
                [const Color(0xFF064E3B), const Color(0xFF047857)],
                [const Color(0xFF064E3B), const Color(0xFF047857)],
              ],
              tests: fUnit,
              item: item,
            ),

          if (_selectedCategoryFilter == 'Full Syllabus' && fFull.isNotEmpty)
            _buildCategorySection(
              title: 'Full Syllabus Tests (${fFull.length})',
              subtitle: 'Full length exam pattern tests',
              icon: Icons.track_changes_rounded,
              headerBgColor: const Color(0xFFEFF6FF),
              iconBgColor: const Color(0xFF2563EB),
              textColor: const Color(0xFF1E40AF),
              btnBgColor: const Color(0xFFDBEAFE),
              btnTextColor: const Color(0xFF2563EB),
              testIconData: [Icons.stars_rounded, Icons.military_tech_rounded],
              testIconGradients: [
                [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
                [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
              ],
              tests: fFull,
              item: item,
            ),
        ],
      ],
    );
  }

  Widget _buildCategoryPill(String filterKey, String label) {
    final isSelected = _selectedCategoryFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
    required Color headerBgColor,
    required Color iconBgColor,
    required Color textColor,
    required Color btnBgColor,
    required Color btnTextColor,
    required List<IconData> testIconData,
    required List<List<Color>> testIconGradients,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: textColor.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tests.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final t = tests[index];
              final testTitle = (t['title'] ?? 'Mock Test').toString();
              final testId = (t['id'] ?? 'test_${index}').toString();
              final numStr = (t['number'] ?? '${index + 1 < 10 ? '0${index + 1}' : '${index + 1}'}').toString();
              final durationMins = (t['duration'] is num) ? (t['duration'] as num).toInt() : 180;
              final qCount = (t['questions'] is num) ? (t['questions'] as num).toInt() : 200;
              final marks = (t['marks'] is num) ? (t['marks'] as num).toInt() : 720;
              final isUnlocked = item.isFree || _hasPurchased;

              final iconData = testIconData[index % testIconData.length];
              final iconGrad = testIconGradients[index % testIconGradients.length];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: iconGrad,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(iconData, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),

                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          numStr,
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testTitle,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildMetaChip(Icons.description_outlined, '$qCount Qs'),
                              _buildMetaChip(Icons.access_time_rounded, '${(durationMins / 60).toStringAsFixed(0)} Hrs'),
                              _buildMetaChip(Icons.bar_chart_rounded, '$marks Marks'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFECFDF5),
                        foregroundColor: const Color(0xFF059669),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                            'Start',
                            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF059669)),
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
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 3),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
      ],
    );
  }

  // ==========================================
  // TAB 3: TOP SCORES & LEADERBOARD
  // ==========================================
  Widget _buildTopScoresTab(TestSeriesCardData item) {
    final maxScore = item.exam.contains('JEE') ? 300 : 720;
    final rankings = _leaderboardRankings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTopScoreMetricCard(
                'Highest Score',
                rankings.isNotEmpty ? '${rankings[0]['score']} / $maxScore' : '${maxScore - 8} / $maxScore',
                const Color(0xFFECFDF5),
                const Color(0xFFA7F3D0),
                const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTopScoreMetricCard(
                'Average Score',
                '${(maxScore * 0.72).toInt()} / $maxScore',
                const Color(0xFFEFF6FF),
                const Color(0xFFBFDBFE),
                const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTopScoreMetricCard(
                'Top Percentile',
                '99.99 %ile',
                const Color(0xFFF5F3FF),
                const Color(0xFFDDD6FE),
                const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (rankings.length >= 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Hall of Fame - Top Performers',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF92400E)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _buildPodiumTile(rankings[1], 2, const Color(0xFF475569), 'AIR 2')),
                    Expanded(child: _buildPodiumTile(rankings[0], 1, const Color(0xFFD97706), 'AIR 1', isFirst: true)),
                    Expanded(child: _buildPodiumTile(rankings[2], 3, const Color(0xFFC2410C), 'AIR 3')),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.leaderboard_rounded, color: Color(0xFF2563EB), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'All India Leaderboard',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLeaderboardScopeChip('All India'),
                          const SizedBox(width: 2),
                          _buildLeaderboardScopeChip('State'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              _loadingLeaderboard
                  ? const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rankings.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, idx) {
                        final r = rankings[idx];
                        final rankNum = r['rank'] ?? (idx + 1);
                        final name = (r['name'] ?? 'Aspirant').toString();
                        final score = r['score'] ?? (maxScore - (idx * 6));
                        final accuracy = r['accuracy'] ?? (98.0 - (idx * 0.5));
                        final percentile = (r['percentile'] ?? '${(99.9 - (idx * 0.08)).toStringAsFixed(2)}%ile').toString();
                        final badge = (r['badge'] ?? 'AIR $rankNum').toString();

                        final rankColor = rankNum == 1
                            ? const Color(0xFFD97706)
                            : (rankNum == 2 ? const Color(0xFF475569) : (rankNum == 3 ? const Color(0xFFC2410C) : const Color(0xFF64748B)));

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          color: rankNum == 1
                              ? const Color(0xFFFFFBEB)
                              : (idx % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC)),
                          child: Row(
                            children: [
                              // Rank Number Badge
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: rankNum == 1
                                      ? const Color(0xFFFEF3C7)
                                      : (rankNum == 2
                                          ? const Color(0xFFF1F5F9)
                                          : (rankNum == 3 ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC))),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: rankNum == 1
                                        ? const Color(0xFFFDE68A)
                                        : (rankNum == 2 ? const Color(0xFFCBD5E1) : (rankNum == 3 ? const Color(0xFFFFEDD5) : const Color(0xFFE2E8F0))),
                                  ),
                                ),
                                child: Text(
                                  '#$rankNum',
                                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, color: rankColor),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Avatar
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: rankColor,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Student Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (badge.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: rankNum <= 3 ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              badge,
                                              style: GoogleFonts.inter(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: rankNum <= 3 ? const Color(0xFFD97706) : const Color(0xFF4338CA),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Accuracy: ${accuracy.toStringAsFixed(1)}%',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Score & Percentile Column (Right Aligned)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$score',
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
                                      ),
                                      Text(
                                        ' / $maxScore',
                                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Text(
                                      percentile,
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScoreBox() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _avgRating.toStringAsFixed(1),
              style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), height: 1.0),
            ),
            Text(
              ' /5',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (idx) {
            return Icon(
              idx < _avgRating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
              color: const Color(0xFFF59E0B),
              size: 18,
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          '$_reviewCount ${_reviewCount == 1 ? 'Review' : 'Reviews'}',
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStarProgressBar(String starNum, double pctVal, String pctStr, String countStr) {
    return Row(
      children: [
        Text(starNum, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
        const SizedBox(width: 4),
        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pctVal,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(starNum == '5' || starNum == '4' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(pctStr, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        ),
        Text(countStr, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildSubMetricGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSubMetricTile(Icons.menu_book_rounded, '${_avgRating.toStringAsFixed(1)}/5', 'Test Quality', const Color(0xFFECFDF5), const Color(0xFF059669))),
            const SizedBox(width: 8),
            Expanded(child: _buildSubMetricTile(Icons.person_outline_rounded, '${_avgRating.toStringAsFixed(1)}/5', 'Solutions', const Color(0xFFF5F3FF), const Color(0xFF7C3AED))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSubMetricTile(Icons.insights_rounded, '${_avgRating.toStringAsFixed(1)}/5', 'Analytics', const Color(0xFFEFF6FF), const Color(0xFF2563EB))),
            const SizedBox(width: 8),
            Expanded(child: _buildSubMetricTile(Icons.headset_mic_outlined, '${_avgRating > 0 ? _avgRating.toStringAsFixed(1) : '0.0'}/5', 'Support', const Color(0xFFFDF2F8), const Color(0xFFDB2777))),
          ],
        ),
      ],
    );
  }

  Widget _buildSubMetricTile(IconData icon, String score, String label, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(score, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFilterPill(String filterKey, String label) {
    final isSelected = _selectedReviewFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedReviewFilter = filterKey),
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

  Widget _buildTopScoreMetricCard(String label, String value, Color bgColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: textColor.withValues(alpha: 0.85)),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardScopeChip(String scope) {
    final isSelected = _selectedLeaderboardScope == scope;
    return GestureDetector(
      onTap: () => setState(() => _selectedLeaderboardScope = scope),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4)] : null,
        ),
        child: Text(
          scope,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumTile(Map<String, dynamic> r, int rank, Color color, String badge, {bool isFirst = false}) {
    final nameStr = (r['name'] ?? 'Aspirant').toString();
    final percentile = (r['percentile'] ?? '99.9%ile').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isFirst ? Colors.white : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFirst ? color : color.withValues(alpha: 0.4),
          width: isFirst ? 2.0 : 1.0,
        ),
        boxShadow: isFirst
            ? [
                BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1)),
              ]
            : AppShadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(height: 6),
          CircleAvatar(
            radius: isFirst ? 20 : 16,
            backgroundColor: color,
            child: Text(
              nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'A',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isFirst ? 14 : 12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nameStr,
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${r['score']} Marks',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              percentile,
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT SIDEBAR
  // ==========================================
  Widget _buildRightSidebar(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    final discount = item.originalPrice > 0 ? (((item.originalPrice - item.price) / item.originalPrice) * 100).toInt() : 75;
    final recentReviews = _dynamicReviews.take(3).toList();

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
              BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
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

        // CARD 2: What Students Say
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2563EB), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('What Students Say', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _reviewCount > 0
                    ? '$_reviewCount ${_reviewCount == 1 ? 'student has' : 'students have'} reviewed this test series with an average rating of ${_avgRating.toStringAsFixed(1)}/5.'
                    : 'Be the first student to review this test series and share your feedback.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), height: 1.4),
              ),
              if (_reviewCount > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      '$_reviewCount Verified Ratings',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CARD 3: Review Highlights
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF2563EB), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Key Highlights', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 12),
              _buildHighlightRow('Questions at actual ${item.exam} level'),
              _buildHighlightRow('Detailed and easy to understand solutions'),
              _buildHighlightRow('Helpful performance analytics'),
              _buildHighlightRow('Great for chapter-wise & full syllabus preparation'),
              _buildHighlightRow('Instant test result analysis'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CARD 4: Recent Reviews (100% Dynamic)
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
                  Text('Recent Reviews', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  InkWell(
                    onTap: _openWriteReviewDialog,
                    child: Text('+ Add Review', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recentReviews.isEmpty)
                Text(
                  'No reviews submitted yet.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                )
              else
                ...recentReviews.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  final name = (r['name'] ?? 'Aspirant').toString();
                  final sub = (r['aspirant'] ?? '${item.exam} Aspirant').toString();
                  final ratingVal = (r['rating'] is num) ? (r['rating'] as num).toDouble() : 5.0;
                  final dateStr = (r['date'] ?? 'Recently').toString();

                  return Column(
                    children: [
                      _buildCompactReviewTile(name, sub, ratingVal.toStringAsFixed(1), dateStr, const Color(0xFF2563EB)),
                      if (idx < recentReviews.length - 1) const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    ],
                  );
                }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactReviewTile(String name, String sub, String ratingStr, String timeStr, Color bg) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: bg,
          child: Text(name.isNotEmpty ? name[0] : 'A', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text(sub, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B))),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < (double.tryParse(ratingStr)?.floor() ?? 5) ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 12,
                );
              }),
            ),
            const SizedBox(height: 2),
            Text(timeStr, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
          ],
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
}
