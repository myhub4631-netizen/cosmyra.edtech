import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';

class LandingPageScreen extends StatefulWidget {
  final VoidCallback onStartPracticing;
  final VoidCallback onExploreTests;
  final VoidCallback onSignUp;
  final VoidCallback onLogIn;

  const LandingPageScreen({
    Key? key,
    required this.onStartPracticing,
    required this.onExploreTests,
    required this.onSignUp,
    required this.onLogIn,
  }) : super(key: key);

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  bool _isMobileMenuOpen = false;

  @override
  void initState() {
    super.initState();
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

  @override
    Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    if (!isDesktop) {
      return _buildMobileOnboardingView(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP HEADER NAVIGATION BAR (Responsive)
            _buildHeaderNav(context, isDesktop),

            // 2. HERO SECTION CANVAS (Responsive Stack/Column on Mobile)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 36,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: MaxWidthContainer(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Headline & Call-To-Action Column
                        Expanded(flex: 5, child: _buildHeroLeftContent(isDesktop, isTablet)),
                        const SizedBox(width: 24),

                        // Center Hero Column: Student Portrait & Floating Badges
                        Expanded(flex: 4, child: _buildHeroStudentImage(isDesktop)),
                        const SizedBox(width: 24),

                        // Right Column: Floating Progress & Streak Dashboard Cards
                        Expanded(flex: 3, child: _buildHeroRightCards()),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // 3. KEY STATS METRICS BAR (Responsive Grid/Wrap)
                    _buildStatsMetricsBar(isDesktop, isTablet),
                    const SizedBox(height: 48),

                    // 4. POWERFUL FEATURES FOR EVERY ASPIRANT
                    _buildFeaturesSection(context, isDesktop, isTablet),
                    const SizedBox(height: 40),

                    // 5. BOTTOM NEW HERE CTA BANNER
                    _buildNewHereBanner(isDesktop),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DEDICATED MOBILE ONBOARDING VIEW =================
  Widget _buildMobileOnboardingView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      drawer: _buildMobileDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // Mobile Top Header Navbar
            _buildHeaderNav(context, false),

            // Scrollable Onboarding Content matching exact layout & proportions
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // Hero Titles
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Practice Today\n',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Achieve Tomorrow',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D7A53),
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    const Text(
                      'Everything you need to crack NEET & JEE is here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Student Illustration
                    Image.asset(
                      'assets/images/student_study_illustration.png',
                      height: 210,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.school_rounded, size: 70, color: Color(0xFF0D7A53)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 1. Sign in with Google Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            try {
                              await SupabaseService.signInWithGoogle();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Google Sign In: $e')),
                                );
                              }
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.string(
                                '''<svg viewBox="0 0 24 24" width="22" height="22">
                                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
                                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/>
                                </svg>''',
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2. Sign in with Email Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: widget.onLogIn,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mail_outline_rounded, color: Color(0xFF0D7A53), size: 22),
                              SizedBox(width: 12),
                              Text(
                                'Sign in with Email',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 3. Create Account Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0D7A53), width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D7A53).withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: widget.onSignUp,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_outlined, color: Color(0xFF0D7A53), size: 22),
                              SizedBox(width: 12),
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0D7A53),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Social Proof Footer: Trusted by 2M+ students
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/trusted_avatars.png',
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => Row(
                            children: List.generate(
                              3,
                              (index) => Container(
                                margin: const EdgeInsets.only(right: 4),
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFA7F3D0),
                                ),
                                child: const Icon(Icons.person, size: 14, color: Color(0xFF0D7A53)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            children: [
                              TextSpan(text: 'Trusted by '),
                              TextSpan(
                                text: '2M+',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0D7A53),
                                ),
                              ),
                              TextSpan(text: ' students'),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MOBILE DRAWER MENU =================
  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0D7A53)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.school_rounded, color: Color(0xFF0D7A53), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('ExamPrep', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Practice | Analyze | Succeed', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11)),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.home_outlined), title: const Text('Home'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.play_circle_outline), title: const Text('Practice'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.assignment_outlined), title: const Text('Tests'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.auto_stories_outlined), title: const Text('PYQ & NTA'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.menu_book_outlined), title: const Text('Study Material'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.emoji_events_outlined), title: const Text('Leaderboard'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.monetization_on_outlined), title: const Text('Pricing'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('About Us'), onTap: () => Navigator.pop(context)),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onLogIn();
                    },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSignUp();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 1. HEADER NAV =================
  Widget _buildHeaderNav(BuildContext context, bool isDesktop) {
    return Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF0D7A53), size: 18),
                ),
                const SizedBox(width: 8),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ExamPrep', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text('Practice | Analyze | Succeed', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 24),

            // Navigation Links (Desktop only)
            if (isDesktop)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildNavLink('Home', isActive: true),
                      _buildNavLink('Practice ∨'),
                      _buildNavLink('Tests ∨'),
                      _buildNavLink('PYQ ∨'),
                      _buildNavLink('Study Material'),
                      _buildNavLink('Leaderboard'),
                      _buildNavLink('Pricing'),
                      _buildNavLink('About Us'),
                    ],
                  ),
                ),
              )
            else
              const Spacer(),

            // Right Action Buttons
            Row(
              children: [
                IconButton(icon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20), onPressed: () {}),
                if (isDesktop) ...[
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () {
                      if (widget.onLogIn != null) {
                        widget.onLogIn!();
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Log In', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.onSignUp != null) {
                        widget.onSignUp!();
                      } else {
                        Navigator.pushNamed(context, '/signup');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ] else ...[
                  // Non-logged in mobile view: No Log In button in header
                  const SizedBox.shrink(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(String title, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF475569),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 3),
            Container(height: 2, width: 14, color: const Color(0xFF4F46E5)),
          ],
        ],
      ),
    );
  }

  // ================= 2. HERO LEFT CONTENT =================
  Widget _buildHeroLeftContent(bool isDesktop, bool isTablet) {
    final double headlineSize = isDesktop ? 44 : (isTablet ? 36 : 28);
    final double subtitleSize = isDesktop ? 15 : 13;

    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Top Star Trust Badge Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  "India's Most Trusted Exam Preparation Platform",
                  style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Main Headline
        RichText(
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: headlineSize, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), height: 1.18),
            children: const [
              TextSpan(text: 'Practice '),
              TextSpan(text: 'Smarter.\n', style: TextStyle(color: Color(0xFF4F46E5))),
              TextSpan(text: 'Perform '),
              TextSpan(text: 'Better.\n', style: TextStyle(color: Color(0xFF4F46E5))),
              TextSpan(text: 'Crack Your Dream Exam.'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Paragraph Subtitle
        Text(
          'Ace NEET, JEE and other competitive exams with thousands of practice questions, full-length tests, PYQs, detailed solutions and advanced performance analytics.',
          style: TextStyle(fontSize: subtitleSize, color: const Color(0xFF64748B), height: 1.5),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 24),

        // CTA Buttons Row / Column
        if (isDesktop)
          Row(
            children: [
              ElevatedButton(
                onPressed: widget.onStartPracticing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Start Practicing Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              OutlinedButton(
                onPressed: widget.onExploreTests,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Explore Tests', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          )
        else
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onStartPracticing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start Practicing Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onExploreTests,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Explore Tests', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),

        // Social Proof Footnote
        Row(
          mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 28,
              child: Stack(
                children: const [
                  Positioned(left: 0, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=11'))),
                  Positioned(left: 16, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=12'))),
                  Positioned(left: 32, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=13'))),
                ],
              ),
            ),
            Flexible(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  children: [
                    TextSpan(text: 'Join '),
                    TextSpan(text: '2M+ ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    TextSpan(text: 'students who are preparing smarter!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= 3. HERO STUDENT IMAGE & FLOATING BADGES =================
  Widget _buildHeroStudentImage(bool isDesktop) {
    final double containerHeight = isDesktop ? 460 : 340;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 320),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Student Portrait Image
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/hero_student_portrait.jpg',
                height: containerHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: containerHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7D2FE),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(child: Icon(Icons.person_rounded, size: 90, color: Color(0xFF4F46E5))),
                ),
              ),
            ),

            // Floating Badges Overlay (Scales gracefully)
            Positioned(
              left: isDesktop ? -16 : 8,
              top: 30,
              child: _buildHeroBadge(Icons.book_outlined, '10,000+', 'Practice Questions', const Color(0xFF8B5CF6)),
            ),
            Positioned(
              left: isDesktop ? -24 : 4,
              top: 150,
              child: _buildHeroBadge(Icons.assignment_outlined, '500+', 'Full Length Tests', const Color(0xFF10B981)),
            ),
            Positioned(
              left: isDesktop ? -10 : 12,
              bottom: 30,
              child: _buildHeroBadge(Icons.emoji_events_outlined, 'NEET · JEE', '& Many More Exams', const Color(0xFFF59E0B)),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 4. HERO RIGHT DASHBOARD CARDS =================
  Widget _buildHeroRightCards() {
    return Column(
      children: [
        _buildYourProgressCard(),
        const SizedBox(height: 16),
        _buildStreakCard(),
      ],
    );
  }

  Widget _buildHeroBadge(IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 5. YOUR PROGRESS CARD =================
  Widget _buildYourProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('This Week ∨', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Score', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('612 / 720', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('85%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.85,
              minHeight: 5,
              backgroundColor: Color(0xFFEEF2FF),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ProgressStat('Accuracy', '78.4%'),
              _ProgressStat('Questions Solved', '245'),
              _ProgressStat('Tests Completed', '16'),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 6. STREAK CARD =================
  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔥 12 Day Streak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Keep it up!', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _StreakDay('M', true),
              _StreakDay('T', true),
              _StreakDay('W', true),
              _StreakDay('T', true),
              _StreakDay('F', true),
              _StreakDay('S', true),
              _StreakDay('S', false),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 7. STATS METRICS BAR =================
  Widget _buildStatsMetricsBar(bool isDesktop, bool isTablet) {
    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(Icons.people_outline, '2M+', 'Students', const Color(0xFF8B5CF6)),
            _buildMetricItem(Icons.school_outlined, '50+', 'Exams', const Color(0xFF3B82F6)),
            _buildMetricItem(Icons.description_outlined, '1.5M+', 'Questions', const Color(0xFF10B981)),
            _buildMetricItem(Icons.assignment_outlined, '25K+', 'Tests', const Color(0xFFF59E0B)),
            _buildMetricItem(Icons.trending_up_rounded, '95%', 'Student Satisfaction', const Color(0xFFEC4899)),
          ],
        ),
      );
    }

    // MOBILE / TABLET GRID LAYOUT
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _buildMetricItem(Icons.people_outline, '2M+', 'Students', const Color(0xFF8B5CF6)),
          _buildMetricItem(Icons.school_outlined, '50+', 'Exams', const Color(0xFF3B82F6)),
          _buildMetricItem(Icons.description_outlined, '1.5M+', 'Questions', const Color(0xFF10B981)),
          _buildMetricItem(Icons.assignment_outlined, '25K+', 'Tests', const Color(0xFFF59E0B)),
          _buildMetricItem(Icons.trending_up_rounded, '95%', 'Satisfaction', const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String val, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  // ================= 8. FEATURES SECTION GRID =================
  Widget _buildFeaturesSection(BuildContext context, bool isDesktop, bool isTablet) {
    final int crossCount = isDesktop ? 6 : (isTablet ? 3 : 1);

    return Column(
      children: [
        const Text(
          'EVERYTHING YOU NEED TO SUCCEED',
          style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        const SizedBox(height: 6),
        const Text(
          'Powerful Features for Every Aspirant',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'All the tools you need to plan, practice, analyze and improve your performance.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Features Grid
        GridView.count(
          crossAxisCount: crossCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isDesktop ? 0.95 : (isTablet ? 1.1 : 2.2),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard('Custom Practice', 'Practice questions from specific subjects, chapters & topics of your choice.', Icons.track_changes_outlined, const Color(0xFF8B5CF6)),
            _buildFeatureCard('Custom Tests', 'Create your own test with time limit, marks & negative marking and evaluate yourself.', Icons.assignment_outlined, const Color(0xFF10B981)),
            _buildFeatureCard('PYQ & NTA Questions', 'Practice previous year questions and official NTA questions chapter-wise or full syllabus.', Icons.auto_stories_outlined, const Color(0xFFF59E0B)),
            _buildFeatureCard('Performance Analytics', 'Detailed analysis of your strengths, weaknesses and progress over time.', Icons.bar_chart_rounded, const Color(0xFF3B82F6)),
            _buildFeatureCard('Smart Bookmarks', 'Bookmark important questions and revise them anytime, anywhere.', Icons.bookmark_outline_rounded, const Color(0xFFEC4899)),
            _buildFeatureCard('Leaderboards', 'Compete with other aspirants and climb the daily, weekly & monthly leaderboards.', Icons.emoji_events_outlined, const Color(0xFF8B5CF6)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.35), textAlign: TextAlign.center, maxLines: 3),
        ],
      ),
    );
  }

  // ================= 9. NEW HERE BOTTOM BANNER =================
  Widget _buildNewHereBanner(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Here?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    SizedBox(height: 2),
                    Text('Create your free account and get access to free tests, quizzes and more.', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                  ],
                ),
              ),
            ],
          ),
          if (!isDesktop) const SizedBox(height: 14),
          ElevatedButton(
            onPressed: widget.onSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Create Free Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 15),
              ],
            ),
          ),
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
        Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
        Text(day, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
        const SizedBox(height: 3),
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 15,
          color: isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
        ),
      ],
    );
  }
}
