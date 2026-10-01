import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/cart_service.dart';
import 'widgets/ecommerce_checkout_dialog.dart';
import 'widgets/ecommerce_cart_modal.dart';
import '../tests/test_screen.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_sidebar.dart';
import '../../shared/widgets/app_header.dart';
import '../../core/theme/app_design_system.dart';

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
  final String testType; // 'Full', 'Part', 'Chapter', 'Part + Unit + Full', 'Chapter + Part + Unit + Full'
  final String category;
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
  final String longDescription;
  final List<dynamic> features;
  final List<Map<String, dynamic>> tests;
  final List<Map<String, dynamic>> reviews;
  final Map<String, dynamic> topScores;

  // New Dynamic Badge & Feature Overlays matching Reference UI
  final String tagLabel;
  final Color tagBgColor;
  final String feature1Label;
  final String feature2Label;
  final String feature3Label;
  final bool isFavorite;

  final String bannerImageFit;

  TestSeriesCardData({
    required this.id,
    required this.title,
    this.exam = 'NEET',
    this.targetYear = '2027',
    required this.subtitle,
    this.description = '',
    this.longDescription = '',
    this.features = const [],
    this.tests = const [],
    this.reviews = const [],
    this.topScores = const {},
    required this.testCount,
    required this.durationMinutes,
    this.difficulty = 'Moderate',
    this.testType = 'Full',
    this.category = 'Full Syllabus',
    this.validity = 'Valid until exam',
    this.attemptStatus = 'Not Attempted',
    required this.status,
    required this.nextTestName,
    required this.iconBgColor,
    required this.icon,
    this.bannerImageUrl,
    this.bannerImageFit = 'contain',
    this.isFree = false,
    this.price = 299.0,
    this.originalPrice = 999.0,
    this.purchaseLink = '',
    this.purchaseButtonText = 'Join',
    this.showPurchaseButton = true,
    this.syllabusUrl = '',
    this.tagLabel = '',
    this.tagBgColor = const Color(0xFFDC2626),
    this.feature1Label = '',
    this.feature2Label = '',
    this.feature3Label = '',
    this.isFavorite = false,
  });

  BoxFit get imageBoxFit {
    switch (bannerImageFit.toLowerCase()) {
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'fitwidth':
      case 'fit_width':
        return BoxFit.fitWidth;
      case 'fitheight':
      case 'fit_height':
        return BoxFit.fitHeight;
      case 'contain':
      default:
        return BoxFit.contain;
    }
  }

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

  String get dynamicTag {
    if (tagLabel.isNotEmpty) return tagLabel;
    if (isFree) return 'FREE';
    if (title.toLowerCase().contains('leader') || title.toLowerCase().contains('best')) return '🔥 Best Seller';
    if (title.toLowerCase().contains('main') || title.toLowerCase().contains('popular')) return '⭐ Most Popular';
    if (exam.toLowerCase().contains('jee')) return 'JEE ${targetYear.isNotEmpty ? targetYear : "2026"}';
    return 'NEET ${targetYear.isNotEmpty ? targetYear : "2027"}';
  }

  Color get dynamicTagColor {
    if (tagLabel.isNotEmpty) return tagBgColor;
    if (dynamicTag.contains('Best')) return const Color(0xFFDC2626); // Red
    if (dynamicTag.contains('Popular')) return const Color(0xFFD97706); // Orange
    if (dynamicTag.contains('JEE')) return const Color(0xFF0284C7); // Blue
    return const Color(0xFF7E22CE); // Purple
  }

  String get dynamicFeature1 => feature1Label.isNotEmpty ? feature1Label : '📄 $testCount Tests';
  String get dynamicFeature2 {
    if (feature2Label.isNotEmpty) return feature2Label;
    if (title.toLowerCase().contains('pyq')) return '📑 PYQ Based';
    if (title.toLowerCase().contains('foundation')) return '📑 Concept Videos';
    if (title.toLowerCase().contains('board')) return '📑 Board + NEET';
    if (title.toLowerCase().contains('crash')) return '📑 Quick Revision';
    return '📑 Detailed Solutions';
  }

  String get dynamicFeature3 {
    if (feature3Label.isNotEmpty) return feature3Label;
    if (title.toLowerCase().contains('main')) return '📊 Performance Analysis';
    if (title.toLowerCase().contains('foundation')) return '📊 Difficulty-wise Practice';
    if (title.toLowerCase().contains('board')) return '📊 Performance Report';
    return '📊 Progress Analytics';
  }
}

class _TestSeriesScreenState extends State<TestSeriesScreen> {
  String _selectedCategory = 'All Series';
  String _selectedExamFilter = 'All Exams';
  bool _isLoading = false;
  List<Map<String, dynamic>> _dbPapers = [];
  List<Map<String, dynamic>> _customSeriesList = [];
  UserProfileModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadPapers();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await SupabaseService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user ?? SupabaseService.activeUserSession;
      });
    }
  }

  String _getUserDisplayName() {
    final profile = _currentUser ?? SupabaseService.activeUserSession;
    if (profile != null && profile.fullName.trim().isNotEmpty) {
      return profile.fullName;
    }
    final authUser = SupabaseService.client.auth.currentUser;
    if (authUser != null) {
      final metaName = authUser.userMetadata?['full_name'] ?? authUser.userMetadata?['name'];
      if (metaName != null && metaName.toString().trim().isNotEmpty) {
        return metaName.toString().trim();
      }
      if (authUser.email != null && authUser.email!.isNotEmpty) {
        return authUser.email!.split('@').first;
      }
    }
    return 'My Profile';
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
    // 1. Check if test belongs to a paid series
    final allSeries = _getAllRealTestSeries();
    TestSeriesCardData? matchingSeries;
    for (var s in allSeries) {
      if (s.id == paperId || s.tests.any((t) => (t['id']?.toString() ?? '') == paperId)) {
        matchingSeries = s;
        break;
      }
    }

    if (matchingSeries != null && !matchingSeries.isFree) {
      final user = SupabaseService.activeUserSession;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please sign in or create an account to access "$title".'),
              action: SnackBarAction(label: 'Sign In', textColor: Colors.white, onPressed: () => context.go('/login')),
              backgroundColor: const Color(0xFF4F46E5),
            ),
          );
        }
        return;
      }

      final hasAccess = await SupabaseService.hasActiveEntitlement(user.id, matchingSeries.id);
      if (!hasAccess) {
        if (mounted) {
          _handlePurchaseOrEnroll(matchingSeries);
        }
        return;
      }
    }

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

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Popular';
  Map<String, bool> _favoritesMap = {};
  String _activeSidebarTab = 'Test Series';

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

        final rawTestsList = (cs['tests'] is List)
            ? (cs['tests'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];

        // Count matching papers in _dbPapers
        final String sIdLower = sId.toLowerCase();
        final String titleLower = title.toLowerCase();
        int matchingDbCount = 0;
        for (var p in _dbPapers) {
          final pSeriesId = (p['test_series_id'] ?? p['series_id'] ?? p['testSeriesId'] ?? '').toString().trim().toLowerCase();
          final pSeriesTitle = (p['test_series_title'] ?? p['new_test_series_name'] ?? p['existing_test_series'] ?? p['test_series'] ?? p['testSeriesTitle'] ?? p['test_series_name'] ?? '').toString().trim().toLowerCase();
          final pName = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? p['name'] ?? '').toString().trim().toLowerCase();

          if ((pSeriesId.isNotEmpty && (pSeriesId == sIdLower || sIdLower.contains(pSeriesId))) ||
              (pSeriesTitle.isNotEmpty && (pSeriesTitle == titleLower || titleLower.contains(pSeriesTitle) || pSeriesTitle.contains(titleLower))) ||
              (pName.isNotEmpty && (pName == titleLower || titleLower.contains(pName)))) {
            matchingDbCount++;
          }
        }

        final int resolvedTestCount = rawTestsList.isNotEmpty
            ? rawTestsList.length
            : (matchingDbCount > 0
                ? matchingDbCount
                : ((cs['test_count'] is num) ? (cs['test_count'] as num).toInt() : 5));

        String cleanDesc = (cs['description'] ?? '').toString().trim();
        if (cleanDesc.isEmpty) {
          cleanDesc = '$resolvedTestCount full-syllabus $exam mock tests covering complete syllabus with step-by-step solutions.';
        } else {
          cleanDesc = cleanDesc.replaceAll(RegExp(r'\b\d+\s+full-syllabus', caseSensitive: false), '$resolvedTestCount full-syllabus');
          cleanDesc = cleanDesc.replaceAll(RegExp(r'\b\d+\s+progressive', caseSensitive: false), '$resolvedTestCount progressive');
          cleanDesc = cleanDesc.replaceAll(RegExp(r'\b\d+\s+tests', caseSensitive: false), '$resolvedTestCount tests');
          cleanDesc = cleanDesc.replaceAll(RegExp(r'\b\d+\s+mock tests', caseSensitive: false), '$resolvedTestCount mock tests');
        }

        final difficulty = (cs['difficulty'] ?? 'Moderate').toString();
        final testType = (cs['test_type'] ?? cs['testType'] ?? 'Full').toString();
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
            description: cleanDesc,
            longDescription: (cs['long_description'] ?? cs['longDescription'] ?? '').toString(),
            features: (cs['features'] is List) ? List<dynamic>.from(cs['features']) : const [],
            tests: rawTestsList,
            reviews: (cs['reviews'] is List)
                ? (cs['reviews'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
                : const [],
            topScores: (cs['top_scores'] is Map)
                ? Map<String, dynamic>.from(cs['top_scores'])
                : ((cs['topScores'] is Map) ? Map<String, dynamic>.from(cs['topScores']) : const {}),
            testCount: resolvedTestCount,
            durationMinutes: duration,
            difficulty: difficulty,
            testType: testType,
            category: (cs['category'] ?? 'Full Syllabus').toString(),
            validity: validity,
            attemptStatus: attemptStatus,
            syllabusUrl: syllabusUrl,
            status: cs['status'] ?? 'Published',
            nextTestName: cs['paper_name'] ?? 'Test 01',
            iconBgColor: const Color(0xFF4F46E5),
            icon: Icons.track_changes_rounded,
            bannerImageUrl: cs['banner_image_url'] ?? cs['bannerImageUrl'],
            bannerImageFit: (cs['banner_image_fit'] ?? cs['bannerImageFit'] ?? 'contain').toString(),
            isFree: isFree,
            price: price,
            originalPrice: origPrice,
            purchaseLink: purchaseLink,
            purchaseButtonText: buttonText,
            showPurchaseButton: showPurchaseButton,
            tagLabel: (cs['tag_label'] ?? '').toString(),
            feature1Label: (cs['feature1'] ?? '').toString(),
            feature2Label: (cs['feature2'] ?? '').toString(),
            feature3Label: (cs['feature3'] ?? '').toString(),
          ),
        );
      }
    }

    // 2. Load from dbPapers marked as test series (Only standalone Test Series packages, excluding individual test papers)
    for (var p in _dbPapers) {
      final String pId = p['id']?.toString() ?? '';
      final String tsTitle = (p['test_series_title'] ?? p['new_test_series_name'] ?? p['existing_test_series'] ?? '').toString().trim();
      final String pName = (p['paper_name'] ?? p['paperName'] ?? '').toString().trim();
      final String effectiveTitle = tsTitle.isNotEmpty ? tsTitle : pName;

      final bool isIndividualPaper = (p['is_paper'] == true || p['isPaper'] == true) ||
          pName.toLowerCase().contains('paper') ||
          pName.toLowerCase().contains('mock paper') ||
          effectiveTitle.toLowerCase().contains('paper 1') ||
          effectiveTitle.toLowerCase().contains('paper 2') ||
          effectiveTitle.toLowerCase().contains('paper 3') ||
          effectiveTitle.toLowerCase().contains('paper-') ||
          effectiveTitle.toLowerCase().contains('paper_') ||
          (p['test_series_id'] != null && p['test_series_id'].toString().isNotEmpty) ||
          (p['test_series_title'] != null && p['test_series_title'].toString().isNotEmpty);

      final bool isTestSeries = !isIndividualPaper &&
          ((p['source_category'] == 'Test Series') ||
           (p['category'] == 'Test Series') ||
           (p['is_test_series'] == true) ||
           ((p['available_in'] is List) && (p['available_in'] as List).contains('test_series')));

      if (isTestSeries && effectiveTitle.isNotEmpty && !seenTitles.contains(effectiveTitle.toLowerCase())) {
        seenTitles.add(effectiveTitle.toLowerCase());
        final exam = (p['exam'] ?? 'NEET').toString();
        final year = (p['year'] ?? '2027').toString();
        final qCount = (p['saved_questions_count'] is num) ? (p['saved_questions_count'] as num).toInt() : (p['question_count'] ?? 200);
        final duration = (p['duration_minutes'] is num) ? (p['duration_minutes'] as num).toInt() : (p['duration'] ?? 180);
        final difficulty = (p['difficulty'] ?? 'Moderate').toString();
        final testType = (p['test_type'] ?? (p['category'] != null && p['category'].toString().contains('Part') ? 'Part' : (p['category'] != null && p['category'].toString().contains('Chapter') ? 'Chapter' : 'Full'))).toString();
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
            testType: testType,
            validity: validity,
            attemptStatus: attemptStatus,
            syllabusUrl: syllabusUrl,
            status: p['status'] == 'Completed' ? 'Completed' : 'Ready',
            nextTestName: pName,
            iconBgColor: const Color(0xFF7C3AED),
            icon: Icons.assignment_turned_in_rounded,
            bannerImageUrl: p['banner_image_url'] ?? p['bannerImageUrl'],
            bannerImageFit: (p['banner_image_fit'] ?? p['bannerImageFit'] ?? 'contain').toString(),
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

    // Filter out any legacy demo test series IDs
    list.removeWhere((item) => SupabaseService.legacyDemoTestSeriesIds.contains(item.id));

    return list;
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

  void _handlePurchaseOrEnroll(TestSeriesCardData item) async {
    if (item.isFree) {
      _startTestSeries(item.id, item.title, item.durationMinutes);
      return;
    }

    if (item.purchaseLink.trim().isNotEmpty &&
        (item.purchaseLink.startsWith('http://') || item.purchaseLink.startsWith('https://')) &&
        !item.purchaseLink.contains('neet-jee.in')) {
      final uri = Uri.tryParse(item.purchaseLink.trim());
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

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

  void _showProductDetailsModal(TestSeriesCardData item) {
    context.push('/product/${item.id}');
  }

  @override
  Widget build(BuildContext context) {
    final allRealSeries = _getAllRealTestSeries();

    // Filter Series dynamically
    final filteredSeries = allRealSeries.where((item) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isNotEmpty) {
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesDesc = item.description.toLowerCase().contains(query);
        final matchesExam = item.exam.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc && !matchesExam) return false;
      }

      if (_selectedCategory == 'NEET') {
        if (!item.exam.toLowerCase().contains('neet') && !item.title.toLowerCase().contains('neet')) return false;
      } else if (_selectedCategory == 'JEE') {
        if (!item.exam.toLowerCase().contains('jee') && !item.title.toLowerCase().contains('jee')) return false;
      } else if (_selectedCategory == 'Class 11') {
        if (!item.category.contains('11') && !item.title.contains('11') && !item.subtitle.contains('11')) return false;
      } else if (_selectedCategory == 'Class 12') {
        if (!item.category.contains('12') && !item.title.contains('12') && !item.subtitle.contains('12')) return false;
      }

      return true;
    }).toList();

    // Sort series dynamically
    if (_selectedSort == 'Price: Low to High') {
      filteredSeries.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == 'Price: High to Low') {
      filteredSeries.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == 'Test Count') {
      filteredSeries.sort((a, b) => b.testCount.compareTo(a.testCount));
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideDesktop = screenWidth >= 992;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const Drawer(
        child: AppSidebar(
          selectedIndex: 9,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Standard App Header with Search, Cart, Profile & Logout
            AppHeader(
              onOpenDrawer: () => scaffoldKey.currentState?.openDrawer(),
              onSearch: (query) => setState(() => _searchQuery = query),
            ),

            // Body Layout (Sidebar + Main Content Grid)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Navigation Sidebar (Desktop > 992px)
                  if (isWideDesktop)
                    const AppSidebar(
                      selectedIndex: 9,
                    ),

                  // Main Content Scrollable View
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Breadcrumb & Page Title Header
                          _buildPageHeader(screenWidth),

                          const SizedBox(height: 20),

                          // Filter Pills Bar & Controls
                          _buildFilterTabsRow(allRealSeries),

                          const SizedBox(height: 24),

                          // Responsive Grid of Test Series Cards
                          _buildCardsGrid(filteredSeries, screenWidth),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP NAVIGATION HEADER BAR (Matching Reference UI)
  // ===========================================================================
  Widget _buildTopHeaderBar(double screenWidth) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Logo (if mobile or small screen)
          if (screenWidth < 992) ...[
            Image.asset(
              'assets/images/cosmyra_logo.png',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.network(
                'https://neet-jee.in/assets/images/cosmyra_logo.png',
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Search Bar Input (Center)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              height: 40,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search test series, exams, subjects...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Right Header Controls
          Row(
            children: [
              // All Exams Dropdown Button
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: const [
                      Icon(Icons.menu_rounded, size: 18, color: Color(0xFF475569)),
                      SizedBox(width: 6),
                      Text('All Exams', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Shopping Cart Icon with Badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 22, color: Color(0xFF475569)),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),

              // Notification Bell Icon with Badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, size: 22, color: Color(0xFF475569)),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // User Real Profile Avatar & Name (from Google account / Supabase auth)
              AppAvatar.fromProfile(
                _currentUser ?? SupabaseService.activeUserSession,
                size: 34,
              ),
              const SizedBox(width: 8),
              if (screenWidth > 600)
                Text(
                  _getUserDisplayName(),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LEFT SIDEBAR NAVIGATION (Matching Reference UI)
  // ===========================================================================
  Widget _buildLeftSidebar() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Image.asset(
              'assets/images/cosmyra_logo.png',
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.network(
                'https://neet-jee.in/assets/images/cosmyra_logo.png',
                height: 38,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebarNavItem(Icons.home_outlined, 'Home', false, () => context.go('/dashboard')),
                  _buildSidebarNavItem(Icons.track_changes_rounded, 'Practice', false, () => context.go('/practice')),
                  _buildSidebarNavItem(Icons.calendar_today_rounded, 'Test Series', true, () {}),
                  _buildSidebarNavItem(Icons.quiz_outlined, 'Previous Year Questions', false, () {}),
                  _buildSidebarNavItem(Icons.auto_stories_outlined, 'Study Material', false, () {}),
                  _buildSidebarNavItem(Icons.bar_chart_rounded, 'Analytics', false, () => context.go('/analytics')),
                  _buildSidebarNavItem(Icons.emoji_events_outlined, 'Leaderboard', false, () => context.go('/leaderboard')),
                  _buildSidebarNavItem(Icons.shopping_bag_outlined, 'Store', false, () {}),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text('EXAMS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 0.5)),
                  ),
                  _buildSidebarExamAccordion('NEET'),
                  _buildSidebarExamAccordion('JEE'),
                  _buildSidebarExamAccordion('Class 11'),
                  _buildSidebarExamAccordion('Class 12'),
                ],
              ),
            ),
          ),

          // Bottom Unlock Premium Widget
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('👑', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text('Unlock All Test Series', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4C1D95))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPremiumCheckItem('Access all test series'),
                  _buildPremiumCheckItem('Detailed analytics'),
                  _buildPremiumCheckItem('Rank comparison'),
                  _buildPremiumCheckItem('Personalized recommendations'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {},
                      child: const Text('Get Premium', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarExamAccordion(String label) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCheckItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 12, color: Color(0xFF4F46E5)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF5B21B6)))),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAGE HEADER & BREADCRUMB
  // ===========================================================================
  Widget _buildPageHeader(double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Home > Test Series', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              Text(
                'Test Series',
                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                'High-quality test series to boost your preparation',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),

        // Right side search bar in header (matching screenshot)
        if (screenWidth > 600)
          Container(
            width: 220,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search test series...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // FILTER TABS & SORT CONTROLS ROW (Matching Reference UI)
  // ===========================================================================
  Widget _buildFilterTabsRow(List<TestSeriesCardData> allSeries) {
    int allCount = allSeries.length;
    int neetCount = allSeries.where((s) => s.exam.toLowerCase().contains('neet') || s.title.toLowerCase().contains('neet')).length;
    int jeeCount = allSeries.where((s) => s.exam.toLowerCase().contains('jee') || s.title.toLowerCase().contains('jee')).length;
    int class11Count = allSeries.where((s) => s.category.contains('11') || s.title.contains('11') || s.subtitle.contains('11')).length;
    int class12Count = allSeries.where((s) => s.category.contains('12') || s.title.contains('12') || s.subtitle.contains('12')).length;

    final categories = [
      {'label': 'All Series', 'count': allCount},
      {'label': 'NEET', 'count': neetCount},
      {'label': 'JEE', 'count': jeeCount},
      {'label': 'Class 11', 'count': class11Count},
      {'label': 'Class 12', 'count': class12Count},
    ];

    return Row(
      children: [
        // Filter Pills
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final label = cat['label'] as String;
                final count = cat['count'] as int;
                final bool isSelected = _selectedCategory == label;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = label),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '$label ($count)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Filter Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: const [
              Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF475569)),
              SizedBox(width: 6),
              Text('Filter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Sort Dropdown Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: PopupMenuButton<String>(
            onSelected: (val) => setState(() => _selectedSort = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'Popular', child: Text('Popular')),
              const PopupMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
              const PopupMenuItem(value: 'Test Count', child: Text('Test Count')),
            ],
            child: Row(
              children: [
                const Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF475569)),
                const SizedBox(width: 6),
                Text('Sort by: $_selectedSort', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  Widget _buildCardsGrid(List<TestSeriesCardData> seriesList, double screenWidth) {
    if (seriesList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text('No test series found', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Text('Try adjusting your search query or filter selection.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          ],
        ),
      );
    }

    if (screenWidth < 680) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: seriesList.length,
        itemBuilder: (context, index) {
          final item = seriesList[index];
          return _buildMobileTestSeriesCard(item);
        },
      );
    }

    int crossAxisCount = screenWidth >= 1050 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        mainAxisExtent: 330,
      ),
      itemCount: seriesList.length,
      itemBuilder: (context, index) {
        final item = seriesList[index];
        return _buildDesktopTestSeriesCard(item);
      },
    );
  }

  // ===========================================================================
  // MOBILE TEST SERIES CARD (Horizontal Split Layout matching Mobile Screenshot)
  // ===========================================================================
  Widget _buildMobileTestSeriesCard(TestSeriesCardData item) {
    final bool isFav = _favoritesMap[item.id] ?? false;
    final int discountPct = (((item.originalPrice - item.price) / item.originalPrice) * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Banner (Full Width, ~150px Height)
            InkWell(
              onTap: () => context.push('/product/${item.id}'),
              child: Stack(
                children: [
                  Hero(
                    tag: 'test_series_banner_${item.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: _getCardBannerGradient(item),
                        ),
                        child: item.bannerImageUrl != null && item.bannerImageUrl!.isNotEmpty
                            ? Image.network(
                                item.bannerImageUrl!,
                                fit: item.imageBoxFit,
                                errorBuilder: (ctx, err, st) => _buildBannerGraphic(item),
                              )
                            : _buildBannerGraphic(item),
                      ),
                    ),
                  ),

                  // Top-Left Glassmorphic Tag Badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item.dynamicTagColor.withValues(alpha: 0.95),
                            item.dynamicTagColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: item.dynamicTagColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        item.dynamicTag,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  // Top-Right Favorite Heart Icon with Glass Backdrop
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () => setState(() => _favoritesMap[item.id] = !isFav),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFEF4444) : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Content Area
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Icon Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.iconBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, color: Colors.white, size: 17),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Description
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Meta Pills Row
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.exam.contains('JEE') ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: item.exam.contains('JEE') ? const Color(0xFFBFDBFE) : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Text(
                          item.exam.contains('JEE') ? 'JEE' : 'NEET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.exam.contains('JEE') ? const Color(0xFF1E40AF) : const Color(0xFF166534),
                          ),
                        ),
                      ),
                      _buildMetaMiniPill('📄 ${item.testCount} Tests'),
                      _buildMetaMiniPill('⏱️ ${item.durationFormatted}'),
                      _buildMetaMiniPill('📊 ${item.difficulty}'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Footer Row: Price + Green "Buy Now" CTA Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price Stack
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${item.price.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
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
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$discountPct% OFF',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Green "Buy Now" CTA Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _handlePurchaseOrEnroll(item),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.white),
                        label: Text(
                          item.isFree ? 'Enroll Free' : 'Buy Now',
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => context.push('/product/${item.id}'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Click card for full overview, all tests, reviews & top scores',
                              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                              overflow: TextOverflow.ellipsis,
                            ),
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
      ),
    );
  }

  // ===========================================================================
  // DESKTOP TEST SERIES CARD (Matching Desktop Screenshot)
  // ===========================================================================
  Widget _buildDesktopTestSeriesCard(TestSeriesCardData item) {
    final bool isFav = _favoritesMap[item.id] ?? false;
    final int discountPct = (((item.originalPrice - item.price) / item.originalPrice) * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showProductDetailsModal(item),
              child: Stack(
                children: [
                  Hero(
                    tag: 'test_series_banner_${item.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        height: 135,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: _getCardBannerGradient(item),
                        ),
                        child: item.bannerImageUrl != null && item.bannerImageUrl!.isNotEmpty
                            ? Image.network(
                                item.bannerImageUrl!,
                                fit: item.imageBoxFit,
                                errorBuilder: (ctx, err, st) => _buildBannerGraphic(item),
                              )
                            : _buildBannerGraphic(item),
                      ),
                    ),
                  ),

                  // Top-Left Glass Tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item.dynamicTagColor.withValues(alpha: 0.95),
                            item.dynamicTagColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: item.dynamicTagColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        item.dynamicTag,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () => setState(() => _favoritesMap[item.id] = !isFav),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFEF4444) : Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: item.iconBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, color: Colors.white, size: 19),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 18),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: item.exam.contains('JEE') ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: item.exam.contains('JEE') ? const Color(0xFFBFDBFE) : const Color(0xFFBBF7D0),
                            ),
                          ),
                          child: Text(
                            item.exam.contains('JEE') ? 'JEE' : 'NEET',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.exam.contains('JEE') ? const Color(0xFF1E40AF) : const Color(0xFF166534),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),
                        _buildMetaMiniPill('📄 ${item.testCount} Tests'),
                        const SizedBox(width: 4),
                        _buildMetaMiniPill('⏱️ ${item.durationFormatted}'),
                        const SizedBox(width: 4),
                        _buildMetaMiniPill('📊 ${item.difficulty}'),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${item.price.toInt()}',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
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
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$discountPct% OFF',
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _handlePurchaseOrEnroll(item),
                          icon: const Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.white),
                          label: Text(
                            item.isFree ? 'Enroll Free' : 'Buy Now',
                            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildOverlayFeaturePill(String text) {
    return Flexible(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetaMiniPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
      ),
    );
  }

  LinearGradient _getCardBannerGradient(TestSeriesCardData item) {
    if (item.title.contains('JEE Main 2026')) {
      return const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF047857)]);
    } else if (item.title.contains('Foundation')) {
      return const LinearGradient(colors: [Color(0xFF831843), Color(0xFFBE185D)]);
    } else if (item.title.contains('Advanced')) {
      return const LinearGradient(colors: [Color(0xFF78350F), Color(0xFFB45309)]);
    } else if (item.title.contains('Combo') || item.title.contains('Board')) {
      return const LinearGradient(colors: [Color(0xFF311B92), Color(0xFF4A148C)]);
    } else if (item.title.contains('Crash')) {
      return const LinearGradient(colors: [Color(0xFF0C4A6E), Color(0xFF0284C7)]);
    }
    return const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]);
  }

  Widget _buildBannerGraphic(TestSeriesCardData item) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: _getCardBannerGradient(item),
            ),
          ),
        ),
        Positioned(
          right: -10,
          bottom: -10,
          child: Icon(item.icon, size: 110, color: Colors.white.withOpacity(0.08)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 32, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.title.toUpperCase(),
                maxLines: 2,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 60,
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

// ===========================================================================
// 8. FULL PRODUCT DETAILS DIALOG (Description, Reviews, Top Scores, Top Users, All Tests)
// ===========================================================================
class _TestSeriesProductDetailDialog extends StatefulWidget {
  final TestSeriesCardData item;
  final List<Map<String, dynamic>> dbPapers;
  final Function(String testId, String title, int durationMins) onStartTest;
  final Function(TestSeriesCardData) onDownloadSyllabus;
  final Function(TestSeriesCardData) onPurchase;

  const _TestSeriesProductDetailDialog({
    Key? key,
    required this.item,
    required this.dbPapers,
    required this.onStartTest,
    required this.onDownloadSyllabus,
    required this.onPurchase,
  }) : super(key: key);

  @override
  State<_TestSeriesProductDetailDialog> createState() => _TestSeriesProductDetailDialogState();
}

class _TestSeriesProductDetailDialogState extends State<_TestSeriesProductDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasPurchased = false;
  bool _isLoadingAccess = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkEntitlementStatus();
  }

  Future<void> _checkEntitlementStatus() async {
    final user = SupabaseService.activeUserSession;
    if (user != null) {
      final owns = await SupabaseService.hasActiveEntitlement(user.id, widget.item.id);
      if (mounted) {
        setState(() {
          _hasPurchased = owns;
          _isLoadingAccess = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasPurchased = false;
          _isLoadingAccess = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _resolveSeriesTests() {
    final item = widget.item;

    // 0. If real tests are explicitly defined by admin, return them
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

    // 1. Check for real tests in dbPapers matching this series
    for (var p in widget.dbPapers) {
      final pTitle = (p['test_series_title'] ?? p['new_test_series_name'] ?? p['existing_test_series'] ?? '').toString().trim();
      final name = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? '').toString().trim();
      if (pTitle.toLowerCase() == item.title.toLowerCase() || (name.isNotEmpty && name.toLowerCase() == item.title.toLowerCase())) {
        tests.add({
          'id': p['id']?.toString() ?? 'test_${tests.length + 1}',
          'title': name.isNotEmpty ? name : 'Mock Test ${tests.length + 1}',
          'type': item.testType,
          'questions': p['saved_questions_count'] ?? p['question_count'] ?? (item.exam.contains('JEE') ? 90 : 200),
          'marks': p['total_marks'] ?? (item.exam.contains('JEE') ? 300 : 720),
          'duration': p['duration_minutes'] ?? (item.durationMinutes > 0 ? item.durationMinutes : 180),
          'status': p['status'] ?? 'Not Attempted',
        });
      }
    }

    // 2. Supplement up to item.testCount with structured mock tests
    final targetTotal = item.testCount > 0 ? item.testCount : 10;
    final int defaultQCount = item.exam.contains('JEE') ? 90 : 200;
    final int defaultMarks = item.exam.contains('JEE') ? 300 : 720;

    final mockNames = [
      'All India Open Grand Mock 01',
      'High Yield NTA Standard Mock 02',
      'Physics & Chemistry Core Mastery Mock 03',
      item.exam.contains('JEE') ? 'Mathematics Advance Problem-Solving Mock 04' : 'Biology / Botany & Zoology Complete Mock 04',
      'National All India Ranker Grand Mock 05',
      'Speed & Negative Marking Control Mock 06',
      'Previous 10-Year High-Weightage Mock 07',
      'Target Score Maximizer Mock 08',
      'Pre-Exam Final Readiness Mock 09',
      'All India Rank Prediction Mock 10',
      'Ultimate Final Sprint Mock 11',
      'Championship Benchmark Mock 12',
    ];

    while (tests.length < targetTotal) {
      final idx = tests.length;
      final title = idx < mockNames.length
          ? mockNames[idx]
          : '${item.testType} Syllabus Mock Test ${idx + 1}';
      tests.add({
        'id': '${item.id}_test_${idx + 1}',
        'title': title,
        'type': item.testType,
        'questions': defaultQCount,
        'marks': defaultMarks,
        'duration': item.durationMinutes > 0 ? item.durationMinutes : 180,
        'status': idx == 0 ? item.attemptStatus : 'Not Attempted',
      });
    }

    return tests;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tests = _resolveSeriesTests();

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 860,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // 1. Header Banner & Hero Section
            _buildHeroHeader(item),

            // 2. Product Navigation Tabs (Overview, All Tests, Reviews, Top Rankers)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                tabs: [
                  const Tab(
                    icon: Icon(Icons.info_outline_rounded, size: 18),
                    text: 'Overview & Details',
                  ),
                  Tab(
                    icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                    text: 'All Tests (${tests.length})',
                  ),
                  const Tab(
                    icon: Icon(Icons.star_rate_rounded, size: 18),
                    text: 'Reviews (4.9 ★)',
                  ),
                  const Tab(
                    icon: Icon(Icons.emoji_events_outlined, size: 18),
                    text: 'Top Scores & Users',
                  ),
                ],
              ),
            ),

            // 3. Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(item),
                  _buildAllTestsTab(item, tests),
                  _buildReviewsTab(item),
                  _buildTopScoresAndUsersTab(item),
                ],
              ),
            ),

            // 4. Sticky Bottom Action Bar
            _buildStickyBottomBar(item),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(TestSeriesCardData item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item.iconBgColor,
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Badges and Close Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.exam,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: Text(
                  'Target: ${item.formattedTargetYear}',
                  style: GoogleFonts.inter(color: const Color(0xFFA7F3D0), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              // Close Button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          // Hero Highlights Meta Pills Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '4.9 (1,480+ Aspirants)',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              _buildHeroPill(Icons.description_outlined, '${item.testCount} Estimated Tests'),
              _buildHeroPill(Icons.layers_outlined, 'Type: ${item.testType}'),
              _buildHeroPill(Icons.access_time_rounded, item.durationFormatted),
              _buildHeroPill(Icons.bar_chart_rounded, item.difficulty),
              _buildHeroPill(Icons.event_available_rounded, item.validity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW & DETAILS
  // ==========================================
  Widget _buildOverviewTab(TestSeriesCardData item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Detailed Description
          Text(
            'About This Test Series',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            item.longDescription.isNotEmpty
                ? item.longDescription
                : (item.description.isNotEmpty
                    ? '${item.description}\n\nThis comprehensive test series has been strictly curated by top NEET/JEE subject experts following the latest NTA exam pattern. Designed to emulate the exact pressure, time constraints, and multi-concept question levels of the real computer-based examination. It empowers aspirants with predictive All India Rankings, deep topic-level analytics, and error diagnosis to optimize their scores.'
                    : 'Experience the ultimate examination readiness with curated full-syllabus and high-yield tests designed to replicate the real NTA test environment with precision.'),
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF334155), height: 1.55),
          ),
          const SizedBox(height: 24),

          // Section 2: Key Features Grid
          Text(
            'Key Features & Inclusions',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: item.features.isNotEmpty
                ? item.features.map((f) {
                    if (f is Map) {
                      return _buildFeatureCard(
                        Icons.verified_outlined,
                        (f['title'] ?? 'Feature').toString(),
                        (f['description'] ?? 'Comprehensive coverage for high exam scores.').toString(),
                        const Color(0xFF2563EB),
                      );
                    }
                    return _buildFeatureCard(
                      Icons.verified_outlined,
                      f.toString(),
                      'Key examination preparation inclusion.',
                      const Color(0xFF2563EB),
                    );
                  }).toList()
                : [
                    _buildFeatureCard(
                      Icons.verified_outlined,
                      '100% NTA Exam Pattern',
                      'Matches exact weightage, question difficulty, and sectional division (Section A & Section B).',
                      const Color(0xFF2563EB),
                    ),
                    _buildFeatureCard(
                      Icons.leaderboard_outlined,
                      'All India Rank Prediction',
                      'Real-time percentile benchmarking and national rank estimation against 14,000+ active aspirants.',
                      const Color(0xFF059669),
                    ),
                    _buildFeatureCard(
                      Icons.menu_book_outlined,
                      'Step-by-Step Solutions',
                      'Detailed conceptual explanations and shortcut techniques for every single problem.',
                      const Color(0xFFD97706),
                    ),
                    _buildFeatureCard(
                      Icons.analytics_outlined,
                      'Deep Performance Analytics',
                      'Identify weak chapters, wasted time on unattempted questions, and negative mark traps.',
                      const Color(0xFF7C3AED),
                    ),
                  ],
          ),
          const SizedBox(height: 24),

          // Section 3: Test Series Blueprint Table
          Text(
            'Test Structure & Specifications',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildSpecRow('Exam Focus', item.exam, true),
                _buildSpecRow('Target Session', item.formattedTargetYear, false),
                _buildSpecRow('Total Estimated Tests', '${item.testCount} Tests', true),
                _buildSpecRow('Test Type', '${item.testType} Syllabus Mock Tests', false),
                _buildSpecRow('Total Marks per Test', item.exam.contains('JEE') ? '300 Marks' : '720 Marks', true),
                _buildSpecRow('Questions per Test', item.exam.contains('JEE') ? '90 Questions' : '200 Questions', false),
                _buildSpecRow('Marking Scheme', '+4 Marks for Correct, -1 Mark for Incorrect', true),
                _buildSpecRow('Exam Mode', 'Computer Based Test (CBT) Interface', false),
                _buildSpecRow('Validity Period', item.validity, true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: Syllabus Download Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detailed Syllabus & Schedule Blueprint',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Download the official curriculum mapping and test release timeline PDF.',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => widget.onDownloadSyllabus(item),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc, Color color) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isEven) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: ALL TESTS IN THIS SERIES
  // ==========================================
  Widget _buildAllTestsTab(TestSeriesCardData item, List<Map<String, dynamic>> tests) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: tests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final test = tests[index];
        final testTitle = test['title'] ?? 'Mock Test ${index + 1}';
        final qCount = test['questions'] ?? 200;
        final marks = test['marks'] ?? 720;
        final duration = test['duration'] ?? test['duration_minutes'] ?? 180;
        final status = test['status'] ?? 'Not Attempted';

        // Parse test date & time
        final rawDateTime = test['test_date_time'] ?? test['scheduled_at'] ?? test['test_date'] ?? test['start_time'] ?? test['date_time'];
        DateTime? dt;
        if (rawDateTime != null) {
          if (rawDateTime is DateTime) {
            dt = rawDateTime;
          } else {
            dt = DateTime.tryParse(rawDateTime.toString().trim());
          }
        }
        final bool isUpcoming = dt != null && dt.isAfter(DateTime.now());
        final String formattedDateTime = dt != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(dt)
            : '';

        Color statusBg = const Color(0xFFF1F5F9);
        Color statusColor = const Color(0xFF475569);
        if (isUpcoming) {
          statusBg = const Color(0xFFFFFBEB);
          statusColor = const Color(0xFFD97706);
        } else if (status == 'Completed') {
          statusBg = const Color(0xFFDCFCE7);
          statusColor = const Color(0xFF15803D);
        } else if (status == 'In Progress') {
          statusBg = const Color(0xFFFEF3C7);
          statusColor = const Color(0xFFB45309);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              // Test Number Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '#${index + 1}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Meta Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            testTitle,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            isUpcoming ? 'Upcoming' : status,
                            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text('$qCount Questions', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                        Text('$marks Marks', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                        Text('$duration Mins', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                        Text('Type: ${item.testType}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                        if (formattedDateTime.isNotEmpty) ...[
                          const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                          Text('📅 $formattedDateTime', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF059669))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Action Button
              if (isUpcoming) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    'Upcoming',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'Completed' ? const Color(0xFF0F172A) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onStartTest(test['id'], testTitle, duration);
                  },
                  child: Text(
                    status == 'In Progress' ? 'Resume' : (status == 'Completed' ? 'Retake' : 'Start Test'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: REVIEWS & RATINGS
  // ==========================================
  Widget _buildReviewsTab(TestSeriesCardData item) {
    final List<Map<String, dynamic>> reviewsList = item.reviews.isNotEmpty
        ? List<Map<String, dynamic>>.from(item.reviews)
        : [
            {
              'name': 'Aarav Sharma',
              'credential': 'AIR 142 • NEET Qualified',
              'rating': 5,
              'date': 'August 2026',
              'comment': 'The question framing in this test series matches the actual NTA paper level with extreme accuracy. The multi-statement Biology questions and Organic Chemistry mechanism problems helped me eliminate silly mistakes and improve my time management.',
              'is_verified': true,
            },
            {
              'name': 'Sneha Patel',
              'credential': 'Score: 685/720 • Target NEET 2027',
              'rating': 5,
              'date': 'July 2026',
              'comment': 'Part tests and Full syllabus mocks gave me immense confidence. The time management insights and chapter-wise breakdown helped me pinpoint my weak areas in Physics numericals.',
              'is_verified': true,
            },
            {
              'name': 'Rohan Verma',
              'credential': 'JEE Main 99.4%ile Aspirant',
              'rating': 5,
              'date': 'June 2026',
              'comment': 'The numerical value questions and difficulty curve are on par with the real JEE CBT exam. Solutions are super crisp and provide direct shortcut formulas.',
              'is_verified': true,
            },
            {
              'name': 'Priya Das',
              'credential': 'Target NEET 2027 Aspirant',
              'rating': 5,
              'date': 'May 2026',
              'comment': 'Best test series on the platform. The CBT interface is completely identical to NTA NEET, and the validity until exam makes it incredible value for money.',
              'is_verified': true,
            },
          ];

    double avgRating = 0;
    if (reviewsList.isNotEmpty) {
      final totalScore = reviewsList.fold<num>(0, (sum, r) => sum + (r['rating'] is num ? r['rating'] as num : int.tryParse(r['rating']?.toString() ?? '5') ?? 5));
      avgRating = totalScore / reviewsList.length;
    }
    final displayRating = (avgRating > 0 ? avgRating : 4.9).toStringAsFixed(1);
    final countRatings = reviewsList.length > 4 ? '${reviewsList.length} Verified Reviews' : '1,480+ Ratings';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      displayRating,
                      style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      countRatings,
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar('5 Star', 0.91, '91%'),
                      const SizedBox(height: 4),
                      _buildRatingBar('4 Star', 0.07, '7%'),
                      const SizedBox(height: 4),
                      _buildRatingBar('3 Star', 0.02, '2%'),
                      const SizedBox(height: 4),
                      _buildRatingBar('2 Star', 0.00, '0%'),
                      const SizedBox(height: 4),
                      _buildRatingBar('1 Star', 0.00, '0%'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verified Aspirant Testimonials (${reviewsList.length})',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...reviewsList.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            final colors = [
              const Color(0xFF2563EB),
              const Color(0xFF059669),
              const Color(0xFFD97706),
              const Color(0xFF7C3AED),
              const Color(0xFFEC4899),
            ];
            final color = colors[idx % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReviewCard(
                name: (r['name'] ?? 'Aspirant').toString(),
                credential: (r['credential'] ?? 'Verified Aspirant').toString(),
                rating: (r['rating'] is num) ? (r['rating'] as num).toInt() : (int.tryParse(r['rating']?.toString() ?? '5') ?? 5),
                date: (r['date'] ?? 'Recent').toString(),
                comment: (r['comment'] ?? '').toString(),
                avatarBg: color,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, double value, String pct) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(pct, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String name,
    required String credential,
    required int rating,
    required String date,
    required String comment,
    required Color avatarBg,
  }) {
    return Container(
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
                backgroundColor: avatarBg,
                child: Text(
                  name[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 11, color: Color(0xFF16A34A)),
                              SizedBox(width: 3),
                              Text('Verified', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(credential, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(
                      rating,
                      (_) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(date, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8))),
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
  }

  // ==========================================
  // TAB 4: TOP SCORES & TOP USERS
  // ==========================================
  Widget _buildTopScoresAndUsersTab(TestSeriesCardData item) {
    final maxScore = item.exam.contains('JEE') ? 300 : 720;
    final topScoresMap = item.topScores;
    final topScore = (topScoresMap['highest_score'] is num)
        ? (topScoresMap['highest_score'] as num).toInt()
        : (int.tryParse(topScoresMap['highest_score']?.toString() ?? '') ?? (item.exam.contains('JEE') ? 296 : 712));
    final avgScore = (topScoresMap['average_score'] is num)
        ? (topScoresMap['average_score'] as num).toInt()
        : (int.tryParse(topScoresMap['average_score']?.toString() ?? '') ?? (item.exam.contains('JEE') ? 210 : 584));
    final activeStudents = (topScoresMap['active_aspirants'] ?? '14,850+').toString();

    final List<Map<String, dynamic>> rankersList = (topScoresMap['rankers'] is List && (topScoresMap['rankers'] as List).isNotEmpty)
        ? (topScoresMap['rankers'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [
            {'rank': 1, 'name': 'Aayush Kulkarni', 'score': topScore, 'maxScore': maxScore, 'accuracy': '98.2%', 'percentile': '99.99%ile', 'badge': 'AIR 1', 'badgeColor': const Color(0xFFF59E0B)},
            {'rank': 2, 'name': 'Meera Sen', 'score': topScore - 7, 'maxScore': maxScore, 'accuracy': '97.4%', 'percentile': '99.95%ile', 'badge': 'AIR 4', 'badgeColor': const Color(0xFF94A3B8)},
            {'rank': 3, 'name': 'Devansh Mehta', 'score': topScore - 14, 'maxScore': maxScore, 'accuracy': '96.8%', 'percentile': '99.88%ile', 'badge': 'AIR 9', 'badgeColor': const Color(0xFFB45309)},
            {'rank': 4, 'name': 'Tanvi Agarwal', 'score': topScore - 20, 'maxScore': maxScore, 'accuracy': '96.1%', 'percentile': '99.79%ile', 'badge': 'AIR 18', 'badgeColor': const Color(0xFF2563EB)},
            {'rank': 5, 'name': 'Kabir Singhania', 'score': topScore - 24, 'maxScore': maxScore, 'accuracy': '95.5%', 'percentile': '99.71%ile', 'badge': 'AIR 27', 'badgeColor': const Color(0xFF059669)},
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3 Metric Cards Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Highest Score', '$topScore / $maxScore', 'Top Ranker Score', const Color(0xFF10B981), Icons.emoji_events_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('Average Score', '$avgScore / $maxScore', 'Platform Average', const Color(0xFF2563EB), Icons.bar_chart_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('Aspirants Active', activeStudents, 'Enrolled Students', const Color(0xFF7C3AED), Icons.people_alt_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Leaderboard Hall of Fame
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Rankers Leaderboard (${rankersList.length})',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              Text(
                'Updated live from recent CBT sessions',
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rankers Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: rankersList.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final rankNum = (r['rank'] is num) ? (r['rank'] as num).toInt() : (idx + 1);
                Color badgeColor = const Color(0xFF2563EB);
                if (rankNum == 1) badgeColor = const Color(0xFFF59E0B);
                else if (rankNum == 2) badgeColor = const Color(0xFF94A3B8);
                else if (rankNum == 3) badgeColor = const Color(0xFFB45309);

                final scoreVal = (r['score'] is num) ? (r['score'] as num).toInt() : (int.tryParse(r['score']?.toString() ?? '') ?? (topScore - (idx * 5)));

                return _buildRankerRow(
                  rank: rankNum,
                  name: (r['name'] ?? 'Ranker ${idx + 1}').toString(),
                  score: scoreVal,
                  maxScore: maxScore,
                  accuracy: (r['accuracy'] ?? '96.5%').toString(),
                  percentile: (r['percentile'] ?? '99.5%ile').toString(),
                  badge: (r['badge'] ?? 'AIR $rankNum').toString(),
                  badgeColor: badgeColor,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildRankerRow({
    required int rank,
    required String name,
    required int score,
    required int maxScore,
    required String accuracy,
    required String percentile,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? badgeColor.withOpacity(0.15) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? badgeColor : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Accuracy: $accuracy • $percentile', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Text(
            '$score / $maxScore',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STICKY BOTTOM ACTION BAR
  // ==========================================
  Widget _buildStickyBottomBar(TestSeriesCardData item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          // Price Display
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
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E8), borderRadius: BorderRadius.circular(4)),
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

          // Download Syllabus Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => widget.onDownloadSyllabus(item),
            icon: const Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF2563EB)),
            label: const Text('Download Syllabus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),

          // DYNAMIC CTAs BASED ON EXACT SPECIFICATIONS:
          // 1. NOT LOGGED IN -> Sign In / Create Account
          if (SupabaseService.activeUserSession == null) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('Sign In / Create Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]
          // 2. LOGGED IN + ALREADY PURCHASED (OR FREE) -> Open Product / Start Learning
          else if (_hasPurchased || item.isFree) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onStartTest(item.id, item.title, item.durationMinutes);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Open Product / Start Learning', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            ),
          ]
          // 3. LOGGED IN + NOT PURCHASED -> Add to Cart + Buy Now
          else ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFF4F46E5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      content: Text(added ? '✓ Added "${item.title}" to Cart!' : 'Product already in your cart or library.'),
                      backgroundColor: added ? const Color(0xFF4F46E5) : const Color(0xFFF59E0B),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
              label: const Text('Add to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
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
                EcommerceCheckoutDialog.show(
                  context,
                  singleItem: cartItem,
                  onStartTest: (testId, title, duration) => widget.onStartTest(testId, title, duration),
                );
              },
              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
              label: Text(
                'Buy Now - ₹${item.price.toInt()}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
