import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import '../dashboard/widgets/recommended_test_series_section.dart';

class LandingPageScreen extends StatefulWidget {
  final VoidCallback onStartPracticing;
  final VoidCallback onExploreTests;
  final VoidCallback onSignUp;
  final VoidCallback onLogIn;
  final bool isLoginRoute;

  const LandingPageScreen({
    Key? key,
    required this.onStartPracticing,
    required this.onExploreTests,
    required this.onSignUp,
    required this.onLogIn,
    this.isLoginRoute = false,
  }) : super(key: key);

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  bool _showEmailLoginForm = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loginLoading = false;
  String? _loginError;

  Map<String, dynamic> _homeContent = {};
  List<DashboardBannerModel> _banners = [];
  bool _isLoadingContent = true;

  @override
  void initState() {
    super.initState();
    SupabaseService.authNotifier.addListener(_onLandingAuthChanged);
    _loadDynamicHomeContent();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = await SupabaseService.getCurrentUser();
        if (user != null && mounted) {
          context.go('/dashboard');
        }
      } catch (e) {
        debugPrint('Session check error: $e');
      }
    });
  }

  Future<void> _loadDynamicHomeContent() async {
    try {
      final content = await SupabaseService.fetchHomePageContent();
      final bannerList = await SupabaseService.fetchBanners(onlyActive: true);
      if (mounted) {
        setState(() {
          _homeContent = content;
          _banners = bannerList;
          _isLoadingContent = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingContent = false);
    }
  }

  @override
  void dispose() {
    SupabaseService.authNotifier.removeListener(_onLandingAuthChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLandingAuthChanged() {
    final user = SupabaseService.authNotifier.value;
    if (user != null && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    if (!isDesktop || widget.isLoginRoute) {
      if (widget.isLoginRoute && isDesktop) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 32, offset: Offset(0, 12)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                            label: Text('Back to Home', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          TextButton(
                            onPressed: widget.onSignUp,
                            child: Text('Create Account', style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: _buildMobileOnboardingContent(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return _buildMobileOnboardingView(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP HEADER NAVIGATION BAR
            _buildHeaderNav(context, isDesktop),

            // 2. HERO SECTION CANVAS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF), Color(0xFFFAF5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: MaxWidthContainer(
                child: Column(
                  children: [
                    // Clean 2-column layout on Desktop to prevent overlapping
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Headline & Call-To-Action Column (Flex 7)
                        Expanded(
                          flex: 7,
                          child: _buildHeroLeftContent(isDesktop, isTablet)
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
                        ),
                        const SizedBox(width: 48),

                        // Right Showcase Column: Student Portrait & Floating Interactive Cards (Flex 5)
                        Expanded(
                          flex: 5,
                          child: _buildHeroRightShowcase(isDesktop)
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 150.ms)
                              .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                        ),
                      ],
                    ),

                    const SizedBox(height: 52),

                    // 3. KEY STATS METRICS BAR
                    _buildStatsMetricsBar(isDesktop, isTablet)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 250.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 48),

                    // 4. PROMOTIONAL BANNERS CAROUSEL (If available from Admin)
                    if (_banners.isNotEmpty) ...[
                      _buildBannersSection(_banners)
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 300.ms),
                      const SizedBox(height: 48),
                    ],

                    // 5. RECOMMENDED TEST SERIES SHOWCASE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 20, offset: Offset(0, 4)),
                        ],
                      ),
                      child: RecommendedTestSeriesSection(
                        onViewAll: widget.onExploreTests,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                    const SizedBox(height: 48),

                    // 6. POWERFUL FEATURES FOR EVERY ASPIRANT
                    _buildFeaturesSection(context, isDesktop, isTablet)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 400.ms),
                    const SizedBox(height: 48),

                    // 7. BOTTOM NEW HERE CTA BANNER
                    _buildNewHereBanner(isDesktop)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 450.ms),
                    const SizedBox(height: 56),

                    // 8. OFFICIAL FOOTER WITH BRAND LOGO
                    _buildLandingFooter(context, isDesktop),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DEDICATED MOBILE & WEB ONBOARDING VIEW =================
  Widget _buildMobileOnboardingView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      drawer: widget.isLoginRoute ? null : _buildMobileDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderNav(context, false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: _buildMobileOnboardingContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileOnboardingContent(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 6),
              Text(
                "India's #1 NEET & JEE Prep Platform",
                style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), height: 1.2),
            children: const [
              TextSpan(text: 'Practice '),
              TextSpan(text: 'Smarter.\n', style: TextStyle(color: Color(0xFF4F46E5))),
              TextSpan(text: 'Perform '),
              TextSpan(text: 'Better.', style: TextStyle(color: Color(0xFF7C3AED))),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Master NEET, JEE & competitive exams with 500+ mock tests, 15-year PYQs and real-time AI error analytics.',
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B), height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        ElevatedButton(
          onPressed: widget.onSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            shadowColor: const Color(0x3D4F46E5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Get Started - Free Signup', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 12),

        OutlinedButton(
          onPressed: widget.onExploreTests,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Explore Test Series', style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 24),

        if (widget.isLoginRoute || _showEmailLoginForm) ...[
          _buildEmailLoginForm(),
        ] else ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => _showEmailLoginForm = true),
            icon: const Icon(Icons.email_outlined, color: Color(0xFF4F46E5), size: 18),
            label: Text('Log in with Email & Password', style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13.5)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmailLoginForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log In to Cosmyra', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 16),
          if (_loginError != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
              child: Text(_loginError!, style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 12)),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _loginLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _loginLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Log In', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _loginError = 'Please enter both email and password.');
      return;
    }
    setState(() {
      _loginLoading = true;
      _loginError = null;
    });

    try {
      final profile = await SupabaseService.signIn(email: email, password: password);
      if (profile != null && mounted) {
        context.go('/dashboard');
      } else {
        setState(() => _loginError = 'Invalid credentials. Please check your email and password.');
      }
    } catch (e) {
      setState(() => _loginError = 'Sign in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Image.asset('assets/images/cosmyra_logo.png', height: 32, errorBuilder: (_, __, ___) => Text('Cosmyra', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(),
            ListTile(leading: const Icon(Icons.home_outlined), title: const Text('Home'), onTap: () => context.go('/')),
            ListTile(leading: const Icon(Icons.edit_note_rounded), title: const Text('Practice'), onTap: () => context.go('/practice')),
            ListTile(leading: const Icon(Icons.assignment_outlined), title: const Text('Mock Tests'), onTap: () => context.go('/mock-tests')),
            ListTile(leading: const Icon(Icons.school_outlined), title: const Text('Test Series'), onTap: () => context.go('/test-series')),
            ListTile(leading: const Icon(Icons.article_outlined), title: const Text('Blog'), onTap: () => context.go('/blog')),
            ListTile(leading: const Icon(Icons.info_outline_rounded), title: const Text('About Us'), onTap: () => context.go('/about-us')),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: widget.onSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 1. HEADER NAV =================
  Widget _buildHeaderNav(BuildContext context, bool isDesktop) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: MaxWidthContainer(
        child: Row(
          children: [
            if (!isDesktop)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            // Logo
            InkWell(
              onTap: () => context.go('/'),
              child: Image.asset(
                'assets/images/cosmyra_logo.png',
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cosmyra NEET | JEE', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text('AI Mock Tests • Practice | Analyze | Succeed', style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 36),

            // Navigation Links (Desktop only)
            if (isDesktop)
              Expanded(
                child: Row(
                  children: [
                    _buildNavLink('Home', isActive: true, onTap: () => context.go('/')),
                    _buildNavLink('Practice', onTap: () => context.go('/practice')),
                    _buildNavLink('Tests', onTap: () => context.go('/mock-tests')),
                    _buildNavLink('PYQ', onTap: () => context.go('/pyq')),
                    _buildNavLink('Test Series', onTap: () => context.go('/test-series')),
                    _buildNavLink('Blog', onTap: () => context.go('/blog')),
                    _buildNavLink('About Us', onTap: () => context.go('/about-us')),
                  ],
                ),
              )
            else
              const Spacer(),

            // Right Action Buttons
            Row(
              children: [
                if (isDesktop) ...[
                  OutlinedButton(
                    onPressed: () {
                      if (widget.onLogIn != null) {
                        widget.onLogIn();
                      } else {
                        context.go('/login');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Log In', style: GoogleFonts.inter(color: const Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.onSignUp != null) {
                        widget.onSignUp();
                      } else {
                        context.go('/signup');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      shadowColor: const Color(0x3D4F46E5),
                    ),
                    child: Text('Get Started Free', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(String title, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF475569),
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(height: 2.5, width: 20, decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(2))),
            ],
          ],
        ),
      ),
    );
  }

  // ================= 2. HERO LEFT CONTENT =================
  Widget _buildHeroLeftContent(bool isDesktop, bool isTablet) {
    final heroTitle = _homeContent['hero_title']?.toString() ?? 'Master NEET & JEE with All-India Test Series';
    final heroSub = _homeContent['hero_subtitle']?.toString() ?? 'Target NEET 2026 & JEE 2026 with 500+ Chapter Tests, NTA Level Mock Papers & Real-time AI Percentile Radar.';
    final ctaText = _homeContent['cta_text']?.toString() ?? 'Explore Test Series';

    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Top Star Trust Badge Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFDE68A)),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 8),
              Text(
                "🔥 India's Most Trusted Exam Preparation Platform",
                style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Main Dynamic Headline
        Text(
          heroTitle,
          style: GoogleFonts.outfit(
            fontSize: isDesktop ? 48 : (isTablet ? 38 : 30),
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            height: 1.15,
            letterSpacing: -0.5,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Subtitle Description
        Text(
          heroSub,
          style: GoogleFonts.inter(fontSize: isDesktop ? 16 : 14, color: const Color(0xFF64748B), height: 1.6),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 28),

        // CTA Buttons Row
        Row(
          mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: widget.onStartPracticing,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                shadowColor: const Color(0x404F46E5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Start Practicing Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: widget.onExploreTests,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(ctaText, style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Social Proof Footnote
        Row(
          mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 28,
              child: Stack(
                children: const [
                  Positioned(left: 0, child: CircleAvatar(radius: 13, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=11'))),
                  Positioned(left: 18, child: CircleAvatar(radius: 13, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=12'))),
                  Positioned(left: 36, child: CircleAvatar(radius: 13, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=13'))),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  children: const [
                    TextSpan(text: 'Join '),
                    TextSpan(text: '50,000+ ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    TextSpan(text: 'aspirants preparing smarter every day!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= 3. HERO RIGHT SHOWCASE (PROTRAIT + PROGRESS + STREAK CARDS) =================
  Widget _buildHeroRightShowcase(bool isDesktop) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      _homeContent['hero_image_url']?.toString() ?? 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&auto=format&fit=crop&q=80',
                      height: 380,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 380,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFC7D2FE), Color(0xFF818CF8)]),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(child: Icon(Icons.school_rounded, size: 90, color: Colors.white)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -12,
                    top: 24,
                    child: _buildFloatingBadge(Icons.assignment_outlined, '500+ Mock Tests', 'NTA Standard Pattern', const Color(0xFF10B981)),
                  ),
                  Positioned(
                    right: -12,
                    bottom: 24,
                    child: _buildFloatingBadge(Icons.auto_awesome_rounded, 'AI Percentile Radar', 'Instant Error Detection', const Color(0xFF8B5CF6)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildYourProgressCard(),
                  const SizedBox(height: 16),
                  _buildStreakCard(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingBadge(IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text(sub, style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYourProgressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Progress', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text('This Week', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Target NEET Mock #14', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('640 / 720', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text('88.8%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.888,
              minHeight: 6,
              backgroundColor: Color(0xFFEEF2FF),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _ProgressStat('Accuracy', '84.2%'),
              _ProgressStat('Questions', '320'),
              _ProgressStat('Tests', '18'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔥 14 Day Active Streak', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('Keep up your daily target!', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _StreakDay('M', true),
              _StreakDay('T', true),
              _StreakDay('W', true),
              _StreakDay('T', true),
              _StreakDay('F', true),
              _StreakDay('S', true),
              _StreakDay('S', true),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 4. BANNERS SECTION =================
  Widget _buildBannersSection(List<DashboardBannerModel> banners) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promotional Banners & Announcements',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: banners.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (ctx, idx) {
              final b = banners[idx];
              return Container(
                width: 480,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      b.imageUrl.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xCC0F172A), Color(0x330F172A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(b.title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (b.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(b.subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)), maxLines: 2),
                          ],
                          if (b.ctaText.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: () {
                                if (b.ctaDestination.isNotEmpty) {
                                  context.go(b.ctaDestination);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFACC15),
                                foregroundColor: const Color(0xFF0F172A),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(b.ctaText, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= 5. STATS METRICS BAR =================
  Widget _buildStatsMetricsBar(bool isDesktop, bool isTablet) {
    final statsList = (_homeContent['stats'] is List)
        ? (_homeContent['stats'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [
            {'value': '50,000+', 'label': 'Active Students'},
            {'value': '500+', 'label': 'Full Length Tests'},
            {'value': '15+ Yrs', 'label': 'NTA PYQ Banks'},
            {'value': '98%', 'label': 'Satisfaction Rate'}
          ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: statsList.map((st) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stars_rounded, color: Color(0xFF4F46E5), size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(st['value']?.toString() ?? '', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Text(st['label']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ================= 6. FEATURES SECTION GRID =================
  Widget _buildFeaturesSection(BuildContext context, bool isDesktop, bool isTablet) {
    final int crossCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return Column(
      children: [
        Text(
          'EVERYTHING YOU NEED TO SUCCEED',
          style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          'Powerful Features for Every Aspirant',
          style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'All the tools you need to plan, practice, analyze and improve your performance.',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        GridView.count(
          crossAxisCount: crossCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: isDesktop ? 1.8 : 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard('Custom Chapter Practice', 'Practice questions from specific subjects, chapters & topics of your choice.', Icons.track_changes_outlined, const Color(0xFF8B5CF6)),
            _buildFeatureCard('NTA Level Test Engine', 'Create tests with custom time limit, negative marking & full video solutions.', Icons.assignment_outlined, const Color(0xFF10B981)),
            _buildFeatureCard('15-Year PYQ Archives', 'Practice previous year questions and official NTA questions chapter-wise.', Icons.auto_stories_outlined, const Color(0xFFF59E0B)),
            _buildFeatureCard('AI Performance Radar', 'Detailed weakness analysis, accuracy trends and topic mastery score.', Icons.bar_chart_rounded, const Color(0xFF3B82F6)),
            _buildFeatureCard('Smart Revision Bookmarks', 'Bookmark tricky questions and revise them anytime with instant solutions.', Icons.bookmark_outline_rounded, const Color(0xFFEC4899)),
            _buildFeatureCard('All-India Leaderboards', 'Compete with 50,000+ aspirants and track your real AIR percentile rank.', Icons.emoji_events_outlined, const Color(0xFF6366F1)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Expanded(
            child: Text(description, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ================= 7. NEW HERE BOTTOM BANNER =================
  Widget _buildNewHereBanner(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x3D312E81), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New to Cosmyra NEET | JEE?', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Create your free account today and get access to free mock tests, PYQ banks & AI analytics.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFC7D2FE))),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: widget.onSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E1B4B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Row(
              children: [
                Text('Create Free Account', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 8. FOOTER WITH LOGO =================
  Widget _buildLandingFooter(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/cosmyra_logo.png', height: 36, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 12,
            children: [
              InkWell(onTap: () => context.go('/'), child: Text('Home', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
              InkWell(onTap: () => context.go('/about-us'), child: Text('About Us', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
              InkWell(onTap: () => context.go('/blog'), child: Text('Blog & Insights', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
              InkWell(onTap: () => context.go('/privacy-policy'), child: Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
              InkWell(onTap: () => context.go('/terms-of-service'), child: Text('Terms of Service', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
              InkWell(onTap: () => context.go('/refund-policy'), child: Text('Refund Policy', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
              InkWell(onTap: () => context.go('/faq'), child: Text('FAQ', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
              InkWell(onTap: () => context.go('/contact-us'), child: Text('Contact Us', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 18),
          Text('© 2026 Cosmyra Technologies Pvt. Ltd. All rights reserved.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class MaxWidthContainer extends StatelessWidget {
  final Widget child;

  const MaxWidthContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: child,
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String val;

  const _ProgressStat(this.label, this.val);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(val, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
      ],
    );
  }
}

class _StreakDay extends StatelessWidget {
  final String day;
  final bool isDone;

  const _StreakDay(this.day, this.isDone);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(day, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
        const SizedBox(height: 4),
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
        ),
      ],
    );
  }
}
