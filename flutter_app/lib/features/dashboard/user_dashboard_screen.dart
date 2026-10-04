import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/feature_config_service.dart';
import '../../core/theme/app_design_system.dart';
import '../../shared/widgets/app_sidebar.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/app_avatar.dart';
import '../auth/login_screen.dart';
import 'widgets/recommended_test_series_section.dart';

class UserDashboardScreen extends StatefulWidget {
  final UserProfileModel userProfile;
  final String activeExam;
  final VoidCallback onOpenPractice;
  final VoidCallback? onOpenCustomTest;
  final VoidCallback onOpenMockTests;
  final VoidCallback onOpenPyqs;
  final VoidCallback onOpenMistakes;
  final VoidCallback? onOpenLeaderboard;
  final VoidCallback? onOpenMyTests;
  final VoidCallback? onOpenTestSeries;
  final VoidCallback? onLogout;

  const UserDashboardScreen({
    super.key,
    required this.userProfile,
    required this.activeExam,
    required this.onOpenPractice,
    this.onOpenCustomTest,
    required this.onOpenMockTests,
    required this.onOpenPyqs,
    required this.onOpenMistakes,
    this.onOpenLeaderboard,
    this.onOpenMyTests,
    this.onOpenTestSeries,
    this.onLogout,
  });

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _selectedExamFilter = 'NEET 2026';
  String _selectedDateRange = 'May 16 - May 22';
  String _performanceTab = 'Questions';
  String _leaderboardTab = 'Daily';
  int _activeSidebarIndex = 0;
  int _mobileBottomNavIndex = 0;

  bool _isLeaderboardLoading = true;
  List<Map<String, dynamic>> _homepageLeaderboardRankings = [];
  Map<String, dynamic>? _homepageCurrentUserRank;

  late UserProfileModel _currentUserProfile;
  Map<String, dynamic>? _activeAbortedSession;
  Map<String, dynamic> _userRealStats = {
    'questionsAttempted': 1248,
    'accuracy': 72.4,
    'testsCompleted': 28,
    'studyStreak': 12,
  };

  @override
  void initState() {
    super.initState();
    _currentUserProfile = widget.userProfile;
    _loadCurrentUser();
  }

  bool _isSectionVisible(String key) => true;

  Future<void> _loadCurrentUser() async {
    final currentUser = await SupabaseService.getCurrentUser();
    final stats = await SupabaseService.fetchUserRealStats();
    final activeSession = await SupabaseService.loadActiveTestSession(isExplicitResume: true);

    if (mounted) {
      setState(() {
        if (currentUser != null) _currentUserProfile = currentUser;
        _userRealStats = stats;
        _activeAbortedSession = activeSession;
      });
    }
    _loadHomepageLeaderboard();
    _checkAndShowCohortOnboarding();
  }

  Future<void> _loadHomepageLeaderboard() async {
    if (!mounted) return;
    setState(() => _isLeaderboardLoading = true);
    try {
      final periodStr = _leaderboardTab.toLowerCase();
      final examKey = _selectedExamFilter.isNotEmpty
          ? _selectedExamFilter
          : (_currentUserProfile.targetExam.isNotEmpty ? _currentUserProfile.targetExam : 'NEET');

      final result = await SupabaseService.fetchRealLeaderboardRankings(
        exam: examKey,
        isPointsMode: false,
        currentUserId: _currentUserProfile.id,
        timePeriod: periodStr,
      );

      final List rawRankings = result['rankings'] as List? ?? [];
      final Map<String, dynamic>? currentUserRank =
          (result['currentUserRank'] ?? result['currentUser']) as Map<String, dynamic>?;

      final List<Map<String, dynamic>> rankingsList =
          rawRankings.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (mounted) {
        setState(() {
          _homepageLeaderboardRankings = rankingsList;
          _homepageCurrentUserRank = currentUserRank;
          _isLeaderboardLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading homepage leaderboard: $e');
      if (mounted) {
        setState(() => _isLeaderboardLoading = false);
      }
    }
  }

  String _formatLeaderboardScore(dynamic val) {
    if (val == null) return '0';
    final num n = val is num ? val : (num.tryParse(val.toString()) ?? 0);
    final str = n.toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  String _formatLeaderboardAccuracy(dynamic val) {
    if (val == null) return '0.0%';
    final double d = val is num ? val.toDouble() : (double.tryParse(val.toString()) ?? 0.0);
    return '${d.toStringAsFixed(1)}%';
  }

  Future<void> _checkAndShowCohortOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _currentUserProfile.id;
      final bool alreadyCompleted = prefs.getBool('cohort_onboarding_completed_$userId') ?? false;

      final phoneStr = _currentUserProfile.phoneNumber ?? '';
      final bool missingPhone = phoneStr.trim().isEmpty || phoneStr.contains('0000000000');
      final bool missingCohort = _currentUserProfile.targetExam.trim().isEmpty || _currentUserProfile.targetExam == 'NEET & JEE';

      if (!alreadyCompleted && (missingPhone || missingCohort) && mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showCohortSelectionModal();
        });
      }
    } catch (e) {
      debugPrint('Notice checking cohort onboarding: $e');
    }
  }

  void _showCohortSelectionModal() {
    final rawPhone = _currentUserProfile.phoneNumber ?? '';
    final phoneCtrl = TextEditingController(
      text: rawPhone.replaceAll('+91', '').replaceAll('-', '').trim(),
    );
    String primaryExam = _currentUserProfile.targetExam.toUpperCase().contains('JEE') ? 'JEE' : 'NEET';
    String jeeSubtype = _currentUserProfile.targetExam.toUpperCase().contains('ADV') ? 'JEE Advanced' : 'JEE Main';
    int targetYear = (_currentUserProfile.targetYear >= 2025 && _currentUserProfile.targetYear <= 2028) ? _currentUserProfile.targetYear : 2026;
    String? phoneErrorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF4F46E5), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter Your Mobile Number',
                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              'Provide your verified mobile number and academic goal',
                              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Mobile Number
                  Text('Enter Your Mobile Number', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    onChanged: (val) {
                      if (phoneErrorText != null) {
                        setDialogState(() => phoneErrorText = null);
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Text('+91', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ),
                      hintText: 'e.g. 9812345678',
                      counterText: '',
                      errorText: phoneErrorText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Exam Goal: NEET vs JEE
                  Text('What examination are you preparing for?', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => primaryExam = 'NEET'),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: primaryExam == 'NEET' ? const Color(0xFFEEF2FF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryExam == 'NEET' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                width: primaryExam == 'NEET' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🩺', style: TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  'NEET',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryExam == 'NEET' ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Medical',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: primaryExam == 'NEET' ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => primaryExam = 'JEE'),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: primaryExam == 'JEE' ? const Color(0xFFEEF2FF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryExam == 'JEE' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                width: primaryExam == 'JEE' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⚡', style: TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  'JEE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryExam == 'JEE' ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Engineering',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: primaryExam == 'JEE' ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 3. Sub-selection for JEE: Main vs Advanced
                  if (primaryExam == 'JEE') ...[
                    const SizedBox(height: 14),
                    Text('Select JEE Target Track:', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => jeeSubtype = 'JEE Main'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: jeeSubtype == 'JEE Main' ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: jeeSubtype == 'JEE Main' ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'JEE Main',
                                  style: TextStyle(
                                    color: jeeSubtype == 'JEE Main' ? Colors.white : const Color(0xFF334155),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => jeeSubtype = 'JEE Advanced'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: jeeSubtype == 'JEE Advanced' ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: jeeSubtype == 'JEE Advanced' ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'JEE Advanced',
                                  style: TextStyle(
                                    color: jeeSubtype == 'JEE Advanced' ? Colors.white : const Color(0xFF334155),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // 4. Target Year
                  const SizedBox(height: 16),
                  Text('Target Exam Year:', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Row(
                    children: [2025, 2026, 2027, 2028].map((yr) {
                      final isSel = targetYear == yr;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: InkWell(
                            onTap: () => setDialogState(() => targetYear = yr),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                                  width: isSel ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSel) ...[
                                    const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                                    const SizedBox(width: 2),
                                  ],
                                  Text(
                                    '$yr',
                                    style: TextStyle(
                                      color: isSel ? Colors.white : const Color(0xFF334155),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final rawPhone = phoneCtrl.text.replaceAll(RegExp(r'\D'), '').trim();

                        // Strict Indian Mobile Validation
                        if (rawPhone.length != 10) {
                          setDialogState(() {
                            phoneErrorText = 'Mobile number must be exactly 10 digits.';
                          });
                          return;
                        }
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(rawPhone)) {
                          setDialogState(() {
                            phoneErrorText = 'Invalid mobile number. Must start with 6, 7, 8, or 9.';
                          });
                          return;
                        }

                        // Blacklist known dummy/test numbers
                        const dummyList = [
                          '9988776655', '9876543210', '0123456789', '1234567890',
                          '9898989898', '9191919191', '9090909090', '9988998899',
                          '9999999999', '8888888888', '7777777777', '6666666666',
                          '9876598765', '9123456789', '9000000000', '9800000000',
                        ];
                        if (dummyList.contains(rawPhone)) {
                          setDialogState(() {
                            phoneErrorText = 'Dummy/fake numbers like $rawPhone are not permitted. Enter a real active number.';
                          });
                          return;
                        }

                        // Reject numbers with fewer than 4 unique digits (e.g. 9988998899)
                        if (rawPhone.split('').toSet().length < 4) {
                          setDialogState(() {
                            phoneErrorText = 'Please enter a genuine 10-digit mobile number.';
                          });
                          return;
                        }

                        // Reject more than 5 consecutive repeating digits
                        if (RegExp(r'(\d)\1{5,}').hasMatch(rawPhone)) {
                          setDialogState(() {
                            phoneErrorText = 'Repetitive sequences like 000000 or 999999 are not allowed.';
                          });
                          return;
                        }

                        final chosenExam = primaryExam == 'NEET' ? 'NEET' : jeeSubtype;
                        final fullPhone = '+91$rawPhone';

                        final updated = _currentUserProfile.copyWith(
                          phoneNumber: fullPhone,
                          targetExam: chosenExam,
                          targetYear: targetYear,
                        );

                        // Save to Supabase and cache
                        await SupabaseService.updateProfile(updated);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('cohort_onboarding_completed_${updated.id}', true);

                        if (mounted) {
                          setState(() {
                            _currentUserProfile = updated;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ Profile verified! Set goal to $chosenExam $targetYear'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      child: const Text('Save & Continue to Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileToUse = _currentUserProfile;
    final displayName = profileToUse.fullName.trim().isNotEmpty
        ? profileToUse.fullName.trim()
        : (profileToUse.email.contains('@')
            ? profileToUse.email.split('@').first
            : 'Aman Kumar');

    return LayoutBuilder(
      builder: (context, constraints) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900 || constraints.maxWidth < 900;

        if (isMobile) {
          return Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            drawer: Drawer(
              child: AppSidebar(
                selectedIndex: _activeSidebarIndex,
                onItemSelected: (idx) => setState(() => _activeSidebarIndex = idx),
                onOpenPractice: widget.onOpenPractice,
                onOpenCustomTest: widget.onOpenCustomTest,
                onOpenMockTests: widget.onOpenMockTests,
                onOpenTestSeries: widget.onOpenTestSeries,
                onOpenPyqs: widget.onOpenPyqs,
                onOpenMistakes: widget.onOpenMistakes,
                onOpenMyTests: widget.onOpenMyTests,
                onOpenLeaderboard: widget.onOpenLeaderboard,
                onLogout: widget.onLogout,
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 96.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Mobile Top Header
                    _buildMobileHeader(displayName),
                    const SizedBox(height: 10),

                    // 2. Offer Banner Carousel
                    if (_isSectionVisible('banner_slider')) ...[
                      DashboardBannerCarousel(
                        onOpenMockTests: widget.onOpenMockTests,
                        onOpenTestSeries: widget.onOpenTestSeries,
                        onOpenCustomPractice: widget.onOpenPractice,
                        onOpenLeaderboard: widget.onOpenLeaderboard,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 3. Quick Stats Cards
                    if (_isSectionVisible('quick_stats')) ...[
                      _buildMobileKpiGrid(),
                      const SizedBox(height: 8),
                    ],

                    // 4. Continue Where You Left Off Card
                    if (_isSectionVisible('continue_section')) ...[
                      _buildMobileContinueCard(),
                      const SizedBox(height: 8),
                    ],

                    // 5. Quick Actions Row
                    if (_isSectionVisible('quick_actions')) ...[
                      _buildMobileQuickActions(),
                      const SizedBox(height: 14),
                    ],

                    // 6. Recommended Test Series Section & Go Premium Banner
                    if (_isSectionVisible('recommended_section')) ...[
                      RecommendedTestSeriesSection(
                        onViewAll: () => context.go('/test-series'),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 7. Performance Overview Line Chart + Leaderboard Preview (Synced with Web view)
                    if (_isSectionVisible('performance_overview') || _isSectionVisible('leaderboard_preview')) ...[
                      _buildBottomSectionRow(displayName),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _buildMobileBottomNavBar(),
          );
        }

        // DESKTOP / TABLET LAYOUT (Split Navigation + Main Scrollable Container)
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Row(
            children: [
              // Left Permanent Navigation Sidebar Component
              AppSidebar(
                selectedIndex: _activeSidebarIndex,
                onItemSelected: (idx) => setState(() => _activeSidebarIndex = idx),
                onOpenPractice: widget.onOpenPractice,
                onOpenCustomTest: widget.onOpenCustomTest,
                onOpenMockTests: widget.onOpenMockTests,
                onOpenTestSeries: widget.onOpenTestSeries,
                onOpenPyqs: widget.onOpenPyqs,
                onOpenMistakes: widget.onOpenMistakes,
                onOpenMyTests: widget.onOpenMyTests,
                onOpenLeaderboard: widget.onOpenLeaderboard,
                onLogout: widget.onLogout,
              ),

              // Right Main Content Column
              Expanded(
                child: Column(
                  children: [
                    // Top Header Navbar
                    AppHeader(
                      userProfile: profileToUse,
                      activeExam: widget.activeExam,
                    ),

                    // Main Scrollable Content Body
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Banner Header Row
                            _buildWelcomeHeader(displayName),
                            const SizedBox(height: 20),

                            // Offer Banner Carousel Section
                            if (_isSectionVisible('banner_slider')) ...[
                              DashboardBannerCarousel(
                                onOpenMockTests: widget.onOpenMockTests,
                                onOpenTestSeries: widget.onOpenTestSeries,
                                onOpenCustomPractice: widget.onOpenPractice,
                                onOpenLeaderboard: widget.onOpenLeaderboard,
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Top 4 KPI Metrics Grid Row
                            if (_isSectionVisible('quick_stats')) ...[
                              _buildKpiMetricsGrid(),
                              const SizedBox(height: 28),
                            ],

                            // Middle Section Row: Continue Where You Left Off + Today's Progress
                            if (_isSectionVisible('continue_section')) ...[
                              _buildMiddleSectionRow(),
                              const SizedBox(height: 28),
                            ],

                            // Quick Start Section Header + 5 Cards Grid Row
                            if (_isSectionVisible('quick_actions')) ...[
                              _buildQuickStartSection(),
                              const SizedBox(height: 28),
                            ],

                            // Recommended Test Series Section & Go Premium Banner
                            if (_isSectionVisible('recommended_section')) ...[
                              RecommendedTestSeriesSection(
                                onViewAll: () => context.go('/test-series'),
                              ),
                              const SizedBox(height: 28),
                            ],

                            // Bottom Section Row: Performance Overview Line Chart + Leaderboard
                            if (_isSectionVisible('performance_overview') || _isSectionVisible('leaderboard_preview')) ...[
                              _buildBottomSectionRow(displayName),
                            ],
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
      },
    );
  }

  // ================= MOBILE COMPONENTS =================

  // 1. Mobile Top Header (Hi, Aman 👋 + Subtitle & Right Streak / Notification)
  Widget _buildMobileHeader(String displayName) {
    final firstName = displayName.split(" ").first;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (context) => InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hi, $firstName',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -0.4),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      "Let's achieve your ${widget.activeExam} ${_currentUserProfile.targetYear} goal!",
                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v1.1.9',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Right Streak, Store & Notification Bell
        Row(
          children: [
            if (FeatureConfigService.isVisible('premium_plans')) ...[
              InkWell(
                onTap: () => FeatureConfigService.handleFeatureTap(
                  context,
                  'premium_plans',
                  onActive: () => context.go('/test-series'),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Store',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(delay: 200.ms, duration: 400.ms),
              const SizedBox(width: 6),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Lottie.network(
                    'https://assets3.lottiefiles.com/packages/lf20_6aYx4t.json',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFEA580C)),
                  ),
                  const SizedBox(width: 3),
                  Text('12', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFFEA580C))),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // 2. Mobile Banner Carousel Card (Unlock Your Full Potential)
  Widget _buildMobileBannerCarousel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 3.1,
          child: Image.asset(
            'assets/images/promo_banner.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1E1B4B),
                alignment: Alignment.center,
                child: const Text(
                  'Unlock Your Full Potential',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 3. Mobile Metrics Cards (4 Horizontal Rectangle Cards)
  Widget _buildMobileKpiGrid() {
    final metrics = [
      {
        'title': 'Questions Attempted',
        'value': '${_userRealStats['questionsAttempted']}',
        'sub': 'Real stats',
        'icon': Icons.auto_stories_rounded,
        'lottie': 'https://assets2.lottiefiles.com/packages/lf20_w51pcehl.json',
        'gradient': const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
        'iconBg': const Color(0xFF2563EB),
        'borderColor': const Color(0xFFBFDBFE),
      },
      {
        'title': 'Accuracy',
        'value': '${_userRealStats['accuracy']}%',
        'sub': 'Overall accuracy',
        'icon': Icons.track_changes_rounded,
        'lottie': 'https://assets10.lottiefiles.com/packages/lf20_49rdyysj.json',
        'gradient': const LinearGradient(colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]),
        'iconBg': const Color(0xFF16A34A),
        'borderColor': const Color(0xFFBBF7D0),
      },
      {
        'title': 'Tests Completed',
        'value': '${_userRealStats['testsCompleted']}',
        'sub': 'Completed',
        'icon': Icons.verified_rounded,
        'lottie': 'https://assets5.lottiefiles.com/packages/lf20_touohx80.json',
        'gradient': const LinearGradient(colors: [Color(0xFFF5F3FF), Color(0xFFDDD6FE)]),
        'iconBg': const Color(0xFF7C3AED),
        'borderColor': const Color(0xFFC4B5FD),
      },
      {
        'title': 'Study Streak',
        'value': '${_userRealStats['studyStreak']} Days',
        'sub': 'Active Streak',
        'icon': Icons.local_fire_department_rounded,
        'lottie': 'https://assets3.lottiefiles.com/packages/lf20_6aYx4t.json',
        'gradient': const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
        'iconBg': const Color(0xFFEA580C),
        'borderColor': const Color(0xFFFDBA74),
      },
    ];

    return Row(
      children: metrics.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value;
        final isLast = idx == metrics.length - 1;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              gradient: m['gradient'] as LinearGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: m['borderColor'] as Color),
              boxShadow: [
                BoxShadow(
                  color: (m['iconBg'] as Color).withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: m['iconBg'] as Color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (m['iconBg'] as Color).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Lottie.network(
                    m['lottie'] as String,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => Icon(m['icon'] as IconData, color: Colors.white, size: 12),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    m['title'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    m['value'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    m['sub'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: m['iconBg'] as Color,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: (idx * 80).ms).slideY(begin: 0.1, end: 0),
        );
      }).toList(),
    );
  }

  // 4. Mobile Continue Where You Left Off Card
  // 4. Continue Where You Left Off Card (Dynamic Aborted/Active Session)
  Widget _buildMobileContinueCard() {
    if (_activeAbortedSession == null) {
      return const SizedBox.shrink();
    }

    final session = _activeAbortedSession!;
    final String sessionId = session['sessionId']?.toString() ?? '';
    final List questions = session['questions'] is List ? session['questions'] as List : [];
    final Map userAnswers = session['userAnswers'] is Map ? session['userAnswers'] as Map : {};
    final int secsRemaining = (session['secondsRemaining'] as num? ?? 0).toInt();

    final int totalQ = questions.isNotEmpty ? questions.length : 1;
    final int answeredCount = userAnswers.length;
    final double progress = (answeredCount / totalQ).clamp(0.0, 1.0);

    final int mins = secsRemaining ~/ 60;
    final int secs = secsRemaining % 60;
    final String timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final String sessionTitle = session['testTitle']?.toString() ??
        (sessionId.contains('pyq')
            ? 'PYQ Practice Session'
            : (sessionId.contains('practice') ? 'Custom Practice Session' : 'Custom Test Session'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Continue Where You Left Off', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            InkWell(
              onTap: () async {
                await SupabaseService.clearActiveTestSession();
                setState(() => _activeAbortedSession = null);
              },
              child: const Row(
                children: [
                  Text('Discard', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                  SizedBox(width: 2),
                  Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_circle_fill_rounded, size: 22, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('In-Progress Session', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sessionTitle,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$answeredCount of $totalQ Questions Answered ${secsRemaining > 0 ? "• ⏱ $timeStr remaining" : ""}',
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (sessionId.contains('pyq')) {
                        context.go('/pyq/test');
                      } else if (sessionId.contains('practice')) {
                        context.go('/practice/session');
                      } else {
                        context.go('/custom-test/attempt/$sessionId');
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
                    label: const Text('Resume', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(progress * 100).toInt()}% Completed', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Mobile Quick Actions Horizontal Row
  Widget _buildMobileQuickActions() {
    final rawActions = [
      {
        'label': 'Custom Practice',
        'key': 'custom_practice',
        'icon': Icons.track_changes_rounded,
        'lottie': 'https://assets10.lottiefiles.com/packages/lf20_49rdyysj.json',
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFDCFCE7),
        'tap': () => FeatureConfigService.handleFeatureTap(context, 'custom_practice', onActive: () => context.go('/custom-practice')),
      },
      {
        'label': 'Custom Test',
        'key': 'custom_test',
        'icon': Icons.assignment_outlined,
        'lottie': 'https://assets5.lottiefiles.com/packages/lf20_touohx80.json',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFDBEAFE),
        'tap': () => FeatureConfigService.handleFeatureTap(context, 'custom_test', onActive: () => context.go('/custom-test')),
      },
      {
        'label': 'PYQ Practice',
        'key': 'pyq_practice',
        'icon': Icons.menu_book_rounded,
        'lottie': 'https://assets2.lottiefiles.com/packages/lf20_w51pcehl.json',
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFDDD6FE),
        'tap': () => FeatureConfigService.handleFeatureTap(context, 'pyq_practice', onActive: () => context.go('/pyq')),
      },
      {
        'label': 'NTA Questions',
        'key': 'nta_questions',
        'icon': Icons.shield_outlined,
        'lottie': 'https://assets3.lottiefiles.com/packages/lf20_6aYx4t.json',
        'color': const Color(0xFFEA580C),
        'bg': const Color(0xFFFFEDD5),
        'tap': () => FeatureConfigService.handleFeatureTap(context, 'nta_questions', onActive: () => context.go('/nta-practice')),
      },
      {
        'label': 'Test Series',
        'key': 'test_series',
        'icon': Icons.calendar_today_outlined,
        'lottie': 'https://assets5.lottiefiles.com/packages/lf20_touohx80.json',
        'color': const Color(0xFFDB2777),
        'bg': const Color(0xFFFCE7F3),
        'tap': () => FeatureConfigService.handleFeatureTap(context, 'test_series', onActive: () {
          if (widget.onOpenTestSeries != null) {
            widget.onOpenTestSeries!();
          } else {
            context.go('/test-series');
          }
        }),
      },
    ];

    final actions = rawActions.where((a) => FeatureConfigService.isVisible(a['key'] as String)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.3),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: actions.asMap().entries.map((entry) {
              final idx = entry.key;
              final act = entry.value;

              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 74,
                child: GestureDetector(
                  onTap: act['tap'] as VoidCallback,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: act['bg'] as Color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (act['color'] as Color).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Lottie.network(
                          act['lottie'] as String,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => Icon(act['icon'] as IconData, color: act['color'] as Color, size: 22),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          act['label'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF334155), height: 1.1),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms, delay: (idx * 60).ms).scale(begin: const Offset(0.9, 0.9));
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 6. Mobile Performance Overview (3 Mini Sparkline Cards)
  Widget _buildMobilePerformanceOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your Performance Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Text('Last 7 Days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Questions Attempted mini sparkline card
            Expanded(
              child: _buildMiniSparklineCard('Questions Attempted', '428', const Color(0xFF2563EB), [0.3, 0.4, 0.2, 0.5, 0.4, 0.7]),
            ),
            const SizedBox(width: 8),
            // Accuracy mini sparkline card
            Expanded(
              child: _buildMiniSparklineCard('Accuracy', '74.6%', const Color(0xFF16A34A), [0.5, 0.6, 0.4, 0.7, 0.6, 0.8]),
            ),
            const SizedBox(width: 8),
            // Time Spent mini sparkline card
            Expanded(
              child: _buildMiniSparklineCard('Time Spent', '6h 32m', const Color(0xFF7C3AED), [0.4, 0.3, 0.6, 0.5, 0.8, 0.6]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniSparklineCard(String label, String value, Color color, List<double> values) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 1),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          SizedBox(
            height: 24,
            width: double.infinity,
            child: CustomPaint(
              painter: MiniSparklinePainter(values: values, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Mobile Subject Strength Card
  Widget _buildMobileSubjectStrength() {
    final subjects = [
      {'name': 'Biology', 'pct': 0.78, 'pctStr': '78%', 'correct': '612', 'incorrect': '172', 'color': const Color(0xFF16A34A), 'icon': Icons.eco_rounded, 'bg': const Color(0xFFDCFCE7)},
      {'name': 'Chemistry', 'pct': 0.65, 'pctStr': '65%', 'correct': '328', 'incorrect': '176', 'color': const Color(0xFF2563EB), 'icon': Icons.science_rounded, 'bg': const Color(0xFFDBEAFE)},
      {'name': 'Physics', 'pct': 0.58, 'pctStr': '58%', 'correct': '286', 'incorrect': '206', 'color': const Color(0xFF7C3AED), 'icon': Icons.blur_circular_rounded, 'bg': const Color(0xFFDDD6FE)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subject Strength', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            GestureDetector(
              onTap: () {},
              child: const Row(
                children: [
                  Text('View Analysis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: subjects.map((sub) {
              final isLast = sub == subjects.last;
              return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: sub['bg'] as Color, shape: BoxShape.circle),
                      child: Icon(sub['icon'] as IconData, size: 16, color: sub['color'] as Color),
                    ),
                    const SizedBox(width: 10),

                    // Name & Progress Bar
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: sub['pct'] as double,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(sub['color'] as Color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Percentage
                    Text(sub['pctStr'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sub['color'] as Color)),
                    const SizedBox(width: 12),

                    // Correct / Incorrect numbers
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Text('Correct ', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                            Text(sub['correct'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text('Incorrect ', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                            Text(sub['incorrect'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 8. Mobile Bottom Navigation Bar (Dynamic FeatureConfigService Sync)
  Widget _buildMobileBottomNavBar() {
    return ValueListenableBuilder<int>(
      valueListenable: FeatureConfigService.notifier,
      builder: (context, _, __) {
        final rawNavs = [
          {'icon': Icons.home_rounded, 'label': 'Home', 'key': ''},
          {'icon': Icons.track_changes_rounded, 'label': 'Practice', 'key': 'custom_practice'},
          {'icon': Icons.assignment_outlined, 'label': 'Tests', 'key': 'test_series'},
          {'icon': Icons.emoji_events_outlined, 'label': 'Leaderboard', 'key': 'performance_analytics'},
          {'icon': Icons.person_outline_rounded, 'label': 'Profile', 'key': ''},
        ];

        final navs = rawNavs.where((n) {
          final key = n['key'] as String;
          if (key.isEmpty) return true;
          return FeatureConfigService.isVisible(key);
        }).toList();

        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navs.length, (idx) {
                final isSelected = _mobileBottomNavIndex == idx;
                final item = navs[idx];
                final key = item['key'] as String;

                return InkWell(
                  onTap: () {
                    setState(() => _mobileBottomNavIndex = idx);
                    if (key.isEmpty) {
                      if (item['label'] == 'Home') {
                        // Already on home
                      } else if (item['label'] == 'Profile') {
                        context.push('/profile');
                      }
                    } else {
                      FeatureConfigService.handleFeatureTap(
                        context,
                        key,
                        onActive: () {
                          if (key == 'custom_practice') {
                            widget.onOpenPractice();
                          } else if (key == 'test_series') {
                            if (widget.onOpenMyTests != null) {
                              widget.onOpenMyTests!();
                            } else {
                              widget.onOpenMockTests();
                            }
                          } else if (key == 'performance_analytics') {
                            if (widget.onOpenLeaderboard != null) {
                              widget.onOpenLeaderboard!();
                            } else {
                              context.push('/leaderboard');
                            }
                          }
                        },
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ================= DESKTOP COMPONENTS =================

  Widget _buildTopNavbar(String displayName) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/cosmyra_logo.png',
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    'https://neet-jee.in/assets/images/cosmyra_logo.png',
                    height: 34,
                    fit: BoxFit.contain,
                  );
                },
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.notes_rounded, color: Color(0xFF64748B), size: 22),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(width: 32),

          Expanded(
            child: Container(
              height: 42,
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for questions, topics, tests...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Text('Ctrl /', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          // Eye-catching Store Button in Desktop Header
          InkWell(
            onTap: () => context.go('/test-series'),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFE11D48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 7),
                  Text(
                    'Store',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF08A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🔥 SALE',
                      style: TextStyle(
                        color: Color(0xFF854D0E),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('12', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFEA580C))),
                        Text('Day Streak', style: TextStyle(fontSize: 9, color: Color(0xFFC2410C), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 24),
                    onPressed: () {},
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
                        '3',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${widget.activeExam} ${_currentUserProfile.targetYear}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await SupabaseService.logoutUserSession();
                      if (widget.onLogout != null) widget.onLogout!();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.white),
                    label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final rawNavItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'hasArrow': false, 'key': ''},
      {'icon': Icons.track_changes_rounded, 'label': 'Practice', 'hasArrow': true, 'key': 'custom_practice'},
      {'icon': Icons.edit_note_rounded, 'label': 'Custom Practice', 'hasArrow': false, 'key': 'custom_practice'},
      {'icon': Icons.assignment_outlined, 'label': 'Custom Test', 'hasArrow': false, 'key': 'custom_test'},
      {'icon': Icons.menu_book_rounded, 'label': 'PYQ', 'hasArrow': true, 'key': 'pyq_practice'},
      {'icon': Icons.verified_user_outlined, 'label': 'NTA Questions', 'hasArrow': false, 'key': 'nta_questions'},
      {'icon': Icons.bookmark_border_rounded, 'label': 'Bookmarks', 'hasArrow': false, 'key': ''},
      {'icon': Icons.cancel_outlined, 'label': 'My Mistakes', 'hasArrow': false, 'key': ''},
      {'icon': Icons.calendar_today_rounded, 'label': 'Test Series', 'hasArrow': false, 'key': 'test_series'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Analytics', 'hasArrow': true, 'key': 'performance_analytics'},
      {'icon': Icons.emoji_events_outlined, 'label': 'Leaderboard', 'hasArrow': false, 'key': ''},
      {'icon': Icons.event_note_rounded, 'label': 'Study Plan', 'hasArrow': false, 'key': ''},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile', 'hasArrow': false, 'key': ''},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'hasArrow': false, 'key': ''},
      {'icon': Icons.help_outline_rounded, 'label': 'Help & Support', 'hasArrow': false, 'key': ''},
      {'icon': Icons.logout_rounded, 'label': 'Logout', 'hasArrow': false, 'key': ''},
    ];

    final navItems = rawNavItems.where((item) {
      final key = item['key'] as String;
      if (key.isEmpty) return true;
      return FeatureConfigService.isVisible(key);
    }).toList();

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/cosmyra_logo.png',
                  height: 38,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.network(
                    'https://neet-jee.in/assets/images/cosmyra_logo.png',
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'v1.1.2',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = _activeSidebarIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: InkWell(
                    onTap: () async {
                      setState(() => _activeSidebarIndex = index);
                      if (item['label'] == 'Logout') {
                        await SupabaseService.logoutUserSession();
                        if (widget.onLogout != null) {
                          widget.onLogout!();
                        }
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                        return;
                      }
                      if (item['label'] == 'Practice' || item['label'] == 'Custom Practice') {
                        FeatureConfigService.handleFeatureTap(context, 'custom_practice', onActive: () => context.go('/custom-practice'));
                      } else if (item['label'] == 'Custom Test') {
                        FeatureConfigService.handleFeatureTap(context, 'custom_test', onActive: () => context.go('/custom-test'));
                      } else if (item['label'] == 'Test Series') {
                        FeatureConfigService.handleFeatureTap(context, 'test_series', onActive: () {
                          if (widget.onOpenTestSeries != null) {
                            widget.onOpenTestSeries!();
                          } else {
                            context.go('/test-series');
                          }
                        });
                      } else if (item['label'] == 'PYQ' || item['label'] == 'PYQ Practice') {
                        FeatureConfigService.handleFeatureTap(context, 'pyq_practice', onActive: () => context.go('/pyq'));
                      } else if (item['label'] == 'NTA Questions' || item['label'] == 'NTA Practice') {
                        FeatureConfigService.handleFeatureTap(context, 'nta_questions', onActive: () => context.go('/nta-practice'));
                      } else if (item['label'] == 'Analytics') {
                        FeatureConfigService.handleFeatureTap(context, 'performance_analytics', onActive: () => context.go('/analytics'));
                      } else if (item['label'] == 'Bookmarks' || item['label'] == 'My Mistakes') {
                        widget.onOpenMistakes();
                      } else if (item['label'] == 'Leaderboard') {
                        if (widget.onOpenLeaderboard != null) {
                          widget.onOpenLeaderboard!();
                        } else {
                          context.go('/leaderboard');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 18,
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (item['hasArrow'] == true)
                            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          ValueListenableBuilder<int>(
            valueListenable: FeatureConfigService.notifier,
            builder: (context, _, __) {
              if (!FeatureConfigService.isVisible('premium_plans')) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('👑', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'Go Premium',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Unlock 500+ mock tests, video solutions & AI error radar.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            FeatureConfigService.handleFeatureTap(
                              context,
                              'premium_plans',
                              onActive: () => context.push('/pricing'),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Upgrade Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(String displayName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Welcome back, ',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                  ).createShader(bounds),
                  child: Text(
                    '${displayName.split(" ").first}!',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('👋', style: TextStyle(fontSize: 26)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Let's continue your ${widget.activeExam} ${_currentUserProfile.targetYear} preparation journey.",
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medical_services_outlined, size: 14, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedExamFilter,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDateRange,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiMetricsGrid() {
    final metrics = [
      {
        'title': 'Questions Attempted',
        'value': '${_userRealStats['questionsAttempted']}',
        'sub': 'Real cumulative attempts',
        'icon': Icons.auto_stories_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'borderColor': const Color(0xFFA7F3D0),
        'titleColor': const Color(0xFF065F46),
        'iconBg': const Color(0xFF10B981),
        'glowColor': const Color(0xFF10B981),
      },
      {
        'title': 'Accuracy Rate',
        'value': '${_userRealStats['accuracy']}%',
        'sub': 'Overall performance',
        'icon': Icons.track_changes_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'borderColor': const Color(0xFFC7D2FE),
        'titleColor': const Color(0xFF3730A3),
        'iconBg': const Color(0xFF4F46E5),
        'glowColor': const Color(0xFF4F46E5),
      },
      {
        'title': 'Tests Completed',
        'value': '${_userRealStats['testsCompleted']}',
        'sub': 'Completed sessions',
        'icon': Icons.verified_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'borderColor': const Color(0xFFDDD6FE),
        'titleColor': const Color(0xFF6B21A8),
        'iconBg': const Color(0xFF9333EA),
        'glowColor': const Color(0xFF9333EA),
      },
      {
        'title': 'Study Streak',
        'value': '${_userRealStats['studyStreak']} Days',
        'sub': 'Active daily streak',
        'icon': Icons.local_fire_department_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'borderColor': const Color(0xFFFDBA74),
        'titleColor': const Color(0xFF9A3412),
        'iconBg': const Color(0xFFEA580C),
        'glowColor': const Color(0xFFEA580C),
      },
    ];

    return Row(
      children: metrics.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value;
        final glowColor = m['glowColor'] as Color;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: m['gradient'] as LinearGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: m['borderColor'] as Color, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: m['titleColor'] as Color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m['value'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m['sub'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (m['titleColor'] as Color).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: m['iconBg'] as Color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (m['iconBg'] as Color).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(m['icon'] as IconData, color: Colors.white, size: 22),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: (idx * 80).ms).slideY(begin: 0.08, end: 0),
        );
      }).toList(),
    );
  }

  Widget _buildMiddleSectionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Continue Where You Left Off', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.show_chart_rounded, size: 40, color: Color(0xFF16A34A)),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Text('V₀', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Custom Practice • Physics', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          const Text('Kinematics - Basic Concepts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: const LinearProgressIndicator(
                                    value: 0.6,
                                    minHeight: 6,
                                    backgroundColor: Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('60% Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    ElevatedButton.icon(
                      onPressed: widget.onOpenPractice,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                      label: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 24),

        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's Progress", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Text('View Analytics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: 0.65,
                              strokeWidth: 8,
                              backgroundColor: Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('65%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              Text('Daily Goal', style: TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Questions Attempted', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              Text('65 / 100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.65,
                              minHeight: 6,
                              backgroundColor: Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Accuracy', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  SizedBox(height: 2),
                                  Text('74%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Time Spent', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  SizedBox(height: 2),
                                  Text('2h 15m', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStartSection() {
    final rawQuickCards = [
      {
        'key': 'custom_practice',
        'title': 'Custom Practice',
        'subtitle': 'Practice questions by selecting subjects, chapters & topics',
        'icon': Icons.track_changes_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        'bg': const Color(0xFFECFDF5),
        'onTap': () => FeatureConfigService.handleFeatureTap(context, 'custom_practice', onActive: () => context.go('/custom-practice')),
      },
      {
        'key': 'custom_test',
        'title': 'Custom Test',
        'subtitle': 'Create a full-length test and evaluate your performance',
        'icon': Icons.assignment_outlined,
        'gradient': const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
        'bg': const Color(0xFFEFF6FF),
        'onTap': () => FeatureConfigService.handleFeatureTap(context, 'custom_test', onActive: () => context.go('/custom-test')),
      },
      {
        'key': 'pyq_practice',
        'title': 'PYQ Practice',
        'subtitle': 'Practice previous year questions chapter-wise and year-wise',
        'icon': Icons.menu_book_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
        'bg': const Color(0xFFF5F3FF),
        'onTap': () => FeatureConfigService.handleFeatureTap(context, 'pyq_practice', onActive: () => context.go('/pyq')),
      },
      {
        'key': 'nta_questions',
        'title': 'NTA Questions',
        'subtitle': 'Practice NTA pattern questions for better rank',
        'icon': Icons.shield_outlined,
        'gradient': const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
        'bg': const Color(0xFFFFF7ED),
        'onTap': () => FeatureConfigService.handleFeatureTap(context, 'nta_questions', onActive: () => context.go('/nta-practice')),
      },
      {
        'key': 'test_series',
        'title': 'Test Series Catalog',
        'subtitle': 'Attempt mock tests and improve your exam readiness',
        'icon': Icons.calendar_today_outlined,
        'gradient': const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFD946EF)]),
        'bg': const Color(0xFFFDF2F8),
        'onTap': () => FeatureConfigService.handleFeatureTap(context, 'test_series', onActive: () {
          if (widget.onOpenTestSeries != null) {
            widget.onOpenTestSeries!();
          } else {
            context.go('/test-series');
          }
        }),
      },
    ];

    final quickCards = rawQuickCards.where((c) => FeatureConfigService.isVisible(c['key'] as String)).toList();
    if (quickCards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start Engines',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 14),
        Row(
          children: quickCards.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value;
            final grad = c['gradient'] as LinearGradient;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: c['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: grad,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: grad.colors.first.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(c['icon'] as IconData, size: 18, color: Colors.white),
                            ),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF94A3B8)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          c['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['subtitle'] as String,
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B), height: 1.35),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: (idx * 60).ms).slideY(begin: 0.06, end: 0),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomSectionRow(String displayName) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    final leftColumnContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Performance Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Text('Last 7 Days', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ['Questions', 'Accuracy', 'Time Spent', 'Tests'].map((tab) {
                  final isSelected = _performanceTab == tab;
                  return GestureDetector(
                    onTap: () => setState(() => _performanceTab = tab),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: SmoothLineChartPainter(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final rightColumnContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Leaderboard ($_leaderboardTab)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            GestureDetector(
              onTap: () {
                if (widget.onOpenLeaderboard != null) {
                  widget.onOpenLeaderboard!();
                } else {
                  context.go('/leaderboard');
                }
              },
              child: const Row(
                children: [
                  Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: ['Daily', 'Weekly', 'Monthly'].map((t) {
                  final isSelected = _leaderboardTab == t;
                  return GestureDetector(
                    onTap: () {
                      if (_leaderboardTab != t) {
                        setState(() => _leaderboardTab = t);
                        _loadHomepageLeaderboard();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 24),
                      padding: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Row(
                children: [
                  SizedBox(width: 40, child: Text('Rank', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                  Expanded(child: Text('User', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                  SizedBox(width: 60, child: Text('Score', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                  SizedBox(width: 50, child: Text('Accuracy', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),

              if (_isLeaderboardLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2)),
                )
              else if (_homepageLeaderboardRankings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No leaderboard data available',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                )
              else ...[
                ...() {
                  final List<Widget> rowWidgets = [];
                  final currentUserId = _currentUserProfile.id;
                  final topEntries = _homepageLeaderboardRankings.take(3).toList();

                  final bool currentUserInTop = topEntries.any((e) {
                    final eId = e['id']?.toString() ?? '';
                    return e['is_current_user'] == true || (eId.isNotEmpty && eId == currentUserId);
                  });

                  final List<Map<String, dynamic>> displayEntries = List.from(topEntries);
                  if (!currentUserInTop && _homepageCurrentUserRank != null) {
                    displayEntries.add(_homepageCurrentUserRank!);
                  }

                  for (int i = 0; i < displayEntries.length; i++) {
                    final item = displayEntries[i];
                    final rankNum = (item['rank'] as num?)?.toInt() ?? (i + 1);
                    String rankStr;
                    if (rankNum == 1) {
                      rankStr = '🥇';
                    } else if (rankNum == 2) {
                      rankStr = '🥈';
                    } else if (rankNum == 3) {
                      rankStr = '🥉';
                    } else {
                      rankStr = '$rankNum';
                    }

                    final rawName = (item['name'] ?? 'Aspirant').toString();
                    final itemId = item['id']?.toString() ?? '';
                    final isMe = item['is_current_user'] == true || (itemId.isNotEmpty && itemId == currentUserId);
                    String displayNameStr = rawName;
                    if (isMe && !displayNameStr.contains('(You)')) {
                      displayNameStr = '$displayNameStr (You)';
                    }

                    final rawScore = item['score'] ?? 0;
                    final scoreStr = _formatLeaderboardScore(rawScore);
                    final rawAcc = item['accuracy'] ?? 0.0;
                    final accStr = _formatLeaderboardAccuracy(rawAcc);
                    final avatarUrl = item['avatar']?.toString();

                    if (i > 0) {
                      rowWidgets.add(const SizedBox(height: 10));
                    }
                    rowWidgets.add(
                      _buildLeaderboardRow(
                        rankStr,
                        displayNameStr,
                        scoreStr,
                        accStr,
                        isMe,
                        avatarUrl: avatarUrl,
                      ),
                    );
                  }
                  return rowWidgets;
                }(),
              ],
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumnContent,
          const SizedBox(height: 20),
          rightColumnContent,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: leftColumnContent,
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: rightColumnContent,
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(String rank, String name, String score, String accuracy, bool isHighlighted, {String? avatarUrl}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              rank,
              style: TextStyle(
                fontSize: rank.length > 2 ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
          ),
          AppAvatar(
            avatarUrl: avatarUrl,
            name: name,
            size: 24,
            backgroundColor: isHighlighted ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: isHighlighted ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(score, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ),
          SizedBox(
            width: 50,
            child: Text(accuracy, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }
}

// Mini Sparkline Painter for Mobile Sparkline Cards
class MiniSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  MiniSparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final paintDotHalo = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height * (1.0 - values[i]);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height * (1.0 - values[i - 1]);
        final controlX1 = prevX + (stepX / 2);
        final controlX2 = x - (stepX / 2);
        path.cubicTo(controlX1, prevY, controlX2, y, x, y);
        fillPath.cubicTo(controlX1, prevY, controlX2, y, x, y);
      }

      if (i == values.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }

      if (i == values.length - 1) {
        canvas.drawCircle(Offset(x, y), 5, paintDotHalo);
        canvas.drawCircle(Offset(x, y), 2.5, paintDot);
      }
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SmoothLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final paintWhiteDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final yLabels = ['120', '90', '60', '0'];
    final ySteps = yLabels.length - 1;
    for (int i = 0; i <= ySteps; i++) {
      final y = size.height * (i / ySteps);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final points = [
      Offset(size.width * 0.05, size.height * 0.70),
      Offset(size.width * 0.20, size.height * 0.60),
      Offset(size.width * 0.35, size.height * 0.50),
      Offset(size.width * 0.50, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.52),
      Offset(size.width * 0.80, size.height * 0.65),
      Offset(size.width * 0.95, size.height * 0.48),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paintLine);

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (i == 3) {
        canvas.drawCircle(pt, 6, paintLine);
        canvas.drawCircle(pt, 4, paintWhiteDot);
      } else {
        canvas.drawCircle(pt, 3.5, paintDot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashboardBannerCarousel extends StatefulWidget {
  final VoidCallback? onOpenMockTests;
  final VoidCallback? onOpenTestSeries;
  final VoidCallback? onOpenCustomPractice;
  final VoidCallback? onOpenLeaderboard;

  const DashboardBannerCarousel({
    super.key,
    this.onOpenMockTests,
    this.onOpenTestSeries,
    this.onOpenCustomPractice,
    this.onOpenLeaderboard,
  });

  @override
  State<DashboardBannerCarousel> createState() => _DashboardBannerCarouselState();
}

class _DashboardBannerCarouselState extends State<DashboardBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<DashboardBannerModel> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveBanners();
  }

  Future<void> _fetchActiveBanners() async {
    try {
      final all = await SupabaseService.fetchBanners(onlyActive: true);
      final activeAndScheduled = all.where((b) => b.isScheduledActive).toList();
      if (mounted) {
        setState(() {
          _banners = activeAndScheduled;
          _loading = false;
        });
        if (_banners.length > 1) {
          _startAutoSlide();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (_banners.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && _banners.isNotEmpty) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hexString, Color fallback) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) {
        buffer.write('ff');
        buffer.write(hexString.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> _handleDestination(String dest) async {
    final trimmed = dest.trim();
    if (trimmed.isEmpty) return;

    // Handle external links (e.g. https://cosmyra.in/)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Error launching URL: $e');
      }
    }

    // Handle internal app routes
    final route = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    if (route == '/test-series') {
      if (widget.onOpenTestSeries != null) {
        widget.onOpenTestSeries!();
      } else {
        context.go('/test-series');
      }
    } else if (route == '/mock-tests' || route == '/my-tests') {
      if (widget.onOpenMockTests != null) {
        widget.onOpenMockTests!();
      } else {
        context.go('/my-tests');
      }
    } else if (route == '/custom-practice' || route == '/practice') {
      if (widget.onOpenCustomPractice != null) {
        widget.onOpenCustomPractice!();
      } else {
        context.go('/practice');
      }
    } else if (route == '/leaderboard') {
      if (widget.onOpenLeaderboard != null) {
        widget.onOpenLeaderboard!();
      } else {
        context.go('/leaderboard');
      }
    } else {
      try {
        context.go(route);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 768;

    if (_loading || _banners.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. DESKTOP / WEBSITE VIEW: Display up to 3 banners side by side
    if (isDesktopWeb) {
      final displayCount = _banners.length >= 3 ? 3 : _banners.length;
      final webBanners = _banners.take(displayCount).toList();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < webBanners.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 2.1,
                child: _buildBannerItem(
                  banner: webBanners[i],
                  height: double.infinity,
                  isMobile: false,
                  isGridItem: true,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // 2. MOBILE / APP VIEW: Slider Carousel with Auto-slide & Dots
    return Container(
      height: 155,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                return _buildBannerItem(
                  banner: _banners[index],
                  height: 155,
                  isMobile: true,
                  isGridItem: false,
                );
              },
            ),
          ),

          // Carousel Dot Indicators
          if (_banners.length > 1)
            Positioned(
              bottom: 10,
              right: 18,
              child: Row(
                children: List.generate(
                  _banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(left: 4),
                    height: 6,
                    width: _currentPage == index ? 16 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerItem({
    required DashboardBannerModel banner,
    required double height,
    required bool isMobile,
    required bool isGridItem,
  }) {
    final bgColor = _parseHexColor(banner.bgColor, const Color(0xFF5B21B6));
    final btnBg = _parseHexColor(banner.btnColor, const Color(0xFFFACC15));
    final btnTxt = _parseHexColor(banner.btnTextColor, const Color(0xFF1E1B4B));

    final hasImage = banner.imageUrl != null && banner.imageUrl!.isNotEmpty;
    ImageProvider? imageProvider;
    if (hasImage) {
      if (banner.imageUrl!.startsWith('data:image')) {
        try {
          final comma = banner.imageUrl!.indexOf(',');
          if (comma != -1) {
            final b64 = banner.imageUrl!.substring(comma + 1);
            imageProvider = MemoryImage(base64Decode(b64));
          }
        } catch (_) {}
      } else if (banner.imageUrl!.startsWith('http')) {
        imageProvider = NetworkImage(banner.imageUrl!);
      }
    }

    return GestureDetector(
      onTap: () => _handleDestination(banner.ctaDestination),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isGridItem
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          gradient: imageProvider != null
              ? null
              : LinearGradient(
                  colors: [bgColor, bgColor.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          image: imageProvider != null
              ? DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  colorFilter: banner.overlayOpacity > 0
                      ? ColorFilter.mode(Colors.black.withValues(alpha: banner.overlayOpacity), BlendMode.darken)
                      : null,
                )
              : null,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 18,
          vertical: isMobile ? 12 : 16,
        ),
        child: Stack(
          children: [
            // Text Content (Optional)
            if (banner.showTextOverlay && (banner.title.isNotEmpty || banner.subtitle.isNotEmpty))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Target Audience Badge
                  if (banner.targetAudience.isNotEmpty && banner.targetAudience != 'None')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        banner.targetAudience,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Title
                  if (banner.title.isNotEmpty)
                    Text(
                      banner.title.replaceAll('\n', ' '),
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        shadows: [
                          const Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),

                  // Subtitle
                  if (banner.subtitle.isNotEmpty)
                    Text(
                      banner.subtitle.replaceAll('\n', ' '),
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.95),
                        height: 1.25,
                        shadows: [
                          const Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),

            // Optional CTA Button at bottom left
            if (banner.showButton && banner.ctaText.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                child: ElevatedButton(
                  onPressed: () => _handleDestination(banner.ctaDestination),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnBg,
                    foregroundColor: btnTxt,
                    elevation: 2,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 14,
                      vertical: isMobile ? 6 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner.ctaText,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
