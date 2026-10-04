import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/feature_config_service.dart';
import '../../models/landing_page_config_model.dart';
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
  LandingPageConfigModel _config = SupabaseService.getCachedLandingPageConfigSync();
  List<DashboardBannerModel> _banners = [];
  bool _isLoadingBanners = true;
  int _renderStage = 1; // Stage 1: Header + Hero immediately (Frame 1)

  static const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="24px" height="24px">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  @override
  void initState() {
    super.initState();
    SupabaseService.authNotifier.addListener(_onLandingAuthChanged);
    SupabaseService.landingPageConfigNotifier.addListener(_onConfigUpdated);

    // Progressive deferred rendering pipeline:
    // Frame 1: Header + Hero (LCP candidate paint in <30ms)
    // Frame 2: Stats & Banners
    // Frame 3: Test Series, Features, CTA & Footer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _renderStage = 2);
        Future.delayed(const Duration(milliseconds: 60), () {
          if (mounted) {
            setState(() => _renderStage = 3);
          }
        });
      }
    });

    _initializeContent();

    // Check if user is already logged in asynchronously without blocking initial frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = await SupabaseService.getCurrentUser();
        if (user != null && mounted) {
          context.go('/dashboard');
        }
      } catch (e) {
        debugPrint('Session check notice: $e');
      }
    });
  }

  @override
  void dispose() {
    SupabaseService.authNotifier.removeListener(_onLandingAuthChanged);
    SupabaseService.landingPageConfigNotifier.removeListener(_onConfigUpdated);
    super.dispose();
  }

  void _onLandingAuthChanged() {
    final user = SupabaseService.authNotifier.value;
    if (user != null && mounted) {
      context.go('/dashboard');
    }
  }

  void _onConfigUpdated() {
    final updated = SupabaseService.landingPageConfigNotifier.value;
    if (updated != null && mounted) {
      setState(() => _config = updated);
    }
  }

  Future<void> _initializeContent() async {
    // Background async config revalidation (never blocks Frame 1)
    final config = await SupabaseService.fetchLandingPageConfig();
    if (mounted) {
      setState(() => _config = config);
    }

    // Async banner loading
    try {
      final bannerList = await SupabaseService.fetchBanners(onlyActive: true);
      if (mounted) {
        setState(() {
          _banners = bannerList;
          _isLoadingBanners = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBanners = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isDesktop ? null : _buildMobileDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Announcement Bar
            if (_config.header.showAnnouncementBar && _config.header.announcementBarText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                ),
                child: Text(
                  _config.header.announcementBarText,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            // Header Navigation Bar
            _buildHeaderNav(context, isDesktop),

            // Main Dynamic Landing Page Content with Progressive Below-the-Fold Mounting
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    ..._buildOrderedSections(context, isDesktop, isTablet),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrderedSections(BuildContext context, bool isDesktop, bool isTablet) {
    final List<Widget> sectionWidgets = [];

    for (final secKey in _config.sectionOrder) {
      switch (secKey) {
        case 'hero':
          if (_config.hero.isVisible) {
            sectionWidgets.add(_buildHeroSection(isDesktop, isTablet));
          }
          break;
        case 'stats':
          if (_config.stats.isVisible) {
            if (_renderStage >= 2) {
              sectionWidgets.add(_buildStatsMetricsBar(isDesktop, isTablet));
            } else {
              sectionWidgets.add(_buildSectionSkeleton(height: 90));
            }
          }
          break;
        case 'banners':
          if (_config.banners.isVisible && _banners.isNotEmpty) {
            if (_renderStage >= 2) {
              sectionWidgets.add(_buildBannersSection(isDesktop));
            } else {
              sectionWidgets.add(_buildSectionSkeleton(height: 220));
            }
          }
          break;
        case 'test_series':
          if (_config.testSeries.isVisible) {
            if (_renderStage >= 3) {
              sectionWidgets.add(_buildTestSeriesSection());
            } else {
              sectionWidgets.add(_buildSectionSkeleton(height: 380));
            }
          }
          break;
        case 'features':
          if (_config.features.isVisible) {
            if (_renderStage >= 3) {
              sectionWidgets.add(_buildFeaturesSection(context, isDesktop, isTablet));
            } else {
              sectionWidgets.add(_buildSectionSkeleton(height: 340));
            }
          }
          break;
        case 'cta_banner':
          if (_config.ctaBanner.isVisible) {
            if (_renderStage >= 3) {
              sectionWidgets.add(_buildNewHereBanner(isDesktop));
            } else {
              sectionWidgets.add(_buildSectionSkeleton(height: 140));
            }
          }
          break;
        case 'footer':
          if (_config.footer.isVisible) {
            if (_renderStage >= 3) {
              sectionWidgets.add(_buildLandingFooter(context, isDesktop));
            } else {
              sectionWidgets.add(_buildSectionSkeleton(height: 120));
            }
          }
          break;
      }
    }

    return sectionWidgets;
  }

  Widget _buildSectionSkeleton({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
    );
  }

  // ================= 1. HEADER NAV BAR =================
  Widget _buildHeaderNav(BuildContext context, bool isDesktop) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Brand Title
          InkWell(
            onTap: () => context.go('/'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                    children: [
                      TextSpan(text: _config.header.brandName.contains(' ') ? _config.header.brandName.split(' ').first : _config.header.brandName),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: _config.header.brandName.contains(' ') ? _config.header.brandName.split(' ').sublist(1).join(' ') : '',
                        style: const TextStyle(color: Color(0xFF4F46E5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Desktop Nav Items
          if (isDesktop)
            Row(
              children: [
                ..._config.header.navItems.where((nav) {
                  if (!nav.isVisible) return false;
                  if (nav.featureKey != null && nav.featureKey!.isNotEmpty) {
                    return FeatureConfigService.isFeatureEnabled(nav.featureKey!);
                  }
                  return true;
                }).map((nav) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: InkWell(
                      onTap: () => context.go(nav.destination),
                      child: Text(
                        nav.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),

          // Auth Action Buttons
          Row(
            children: [
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  _config.header.loginButtonLabel,
                  style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => context.go('/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                  shadowColor: const Color(0x3D4F46E5),
                ),
                child: Text(
                  _config.header.signupButtonLabel,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              if (!isDesktop) ...[
                const SizedBox(width: 8),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 26),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ================= 2. HERO SECTION =================
  Widget _buildHeroSection(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: isDesktop ? 56 : 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF), Color(0xFFFAF5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              if (isDesktop && _config.hero.layoutTemplate == 'HERO_SPLIT_LEFT')
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 7, child: _buildHeroLeftContent(isDesktop)),
                    const SizedBox(width: 48),
                    Expanded(flex: 5, child: _buildHeroRightShowcase(isDesktop)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildHeroLeftContent(isDesktop),
                    if (_config.hero.showFloatingCards) ...[
                      const SizedBox(height: 32),
                      _buildHeroRightShowcase(isDesktop),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroLeftContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop && _config.hero.layoutTemplate == 'HERO_SPLIT_LEFT'
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (_config.hero.showTrustBadge && _config.hero.trustBadgeText.isNotEmpty)
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
                  _config.hero.trustBadgeText,
                  style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          _config.hero.headlineText,
          style: GoogleFonts.outfit(
            fontSize: isDesktop ? 44 : 30,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            height: 1.15,
            letterSpacing: -0.5,
          ),
          textAlign: isDesktop && _config.hero.layoutTemplate == 'HERO_SPLIT_LEFT' ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _config.hero.descriptionText,
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 16 : 14,
            color: const Color(0xFF64748B),
            height: 1.6,
          ),
          textAlign: isDesktop && _config.hero.layoutTemplate == 'HERO_SPLIT_LEFT' ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (!isDesktop) ...[
          // 1. Primary Login with Google Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final success = await SupabaseService.signInWithGoogle();
                if (!success && context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                ),
                elevation: 2,
                shadowColor: const Color(0x0F000000),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.string(_googleSvg, width: 22, height: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Login with Google',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Primary Signup with Google Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final success = await SupabaseService.signInWithGoogle();
                if (!success && context.mounted) {
                  context.go('/signup');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEEF2FF),
                foregroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                ),
                elevation: 1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.string(_googleSvg, width: 22, height: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Signup with Google',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF4F46E5)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Get Started - Free Signup -> /signup
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/signup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                shadowColor: const Color(0x404F46E5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Started - Free Signup',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Explore Test Series -> /test-series
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.go('/test-series'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Explore Test Series',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF4F46E5)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 5. Log in with Email & Password -> /login
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFF4F46E5)),
              label: Text(
                'Log in with Email & Password',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF4F46E5)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ] else ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: isDesktop && _config.hero.layoutTemplate == 'HERO_SPLIT_LEFT' ? WrapAlignment.start : WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go(_config.hero.primaryButtonDestination),
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: Text(_config.hero.primaryButtonLabel, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  shadowColor: const Color(0x404F46E5),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(_config.hero.secondaryButtonDestination),
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: Text(_config.hero.secondaryButtonLabel, style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFF4F46E5)),
                label: Text('Log in with Email', style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(
          _config.hero.studentCountText,
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildHeroRightShowcase(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.insights_rounded, color: Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Weekly Progress', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                  Text('Target NEET Mock #14', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20)),
                child: Text('88.8% AIR', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: 0.88, backgroundColor: const Color(0xFFE2E8F0), color: const Color(0xFF4F46E5), minHeight: 8),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeroStatMini('Accuracy', '84.2%'),
              _buildHeroStatMini('Questions', '320'),
              _buildHeroStatMini('Tests', '18'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatMini(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF0F172A))),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
      ],
    );
  }

  // ================= 3. STATS METRICS BAR =================
  Widget _buildStatsMetricsBar(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 24,
            runSpacing: 20,
            children: _config.stats.statsList.where((s) => s.isVisible).map((st) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.star_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                      Text(st.label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ================= 4. BANNERS SECTION =================
  Widget _buildBannersSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_config.banners.sectionTitle, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text(_config.banners.sectionSubtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _banners.length,
                  itemBuilder: (ctx, i) {
                    final b = _banners[i];
                    return Container(
                      width: isDesktop ? 380 : 300,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B),
                        borderRadius: BorderRadius.circular(16),
                        image: (b.imageUrl != null && b.imageUrl!.isNotEmpty)
                            ? DecorationImage(image: NetworkImage(b.imageUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(b.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          if (b.ctaDestination.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => context.go(b.ctaDestination),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                              child: Text(b.ctaText.isNotEmpty ? b.ctaText : 'Explore Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 5. TEST SERIES SECTION =================
  Widget _buildTestSeriesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: Colors.white,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_config.testSeries.sectionTitle, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text(_config.testSeries.sectionSubtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 24),
              RecommendedTestSeriesSection(onViewAll: widget.onExploreTests),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 6. FEATURES SECTION =================
  Widget _buildFeaturesSection(BuildContext context, bool isDesktop, bool isTablet) {
    final activeFeatures = _config.features.features.where((f) {
      if (!f.isVisible) return false;
      if (f.featureKey != null && f.featureKey!.isNotEmpty) {
        return FeatureConfigService.isFeatureEnabled(f.featureKey!);
      }
      return true;
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              if (_config.features.badgeText.isNotEmpty)
                Text(_config.features.badgeText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF4F46E5), letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(_config.features.sectionTitle, style: GoogleFonts.outfit(fontSize: isDesktop ? 30 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 6),
              Text(_config.features.sectionSubtitle, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
              const SizedBox(height: 36),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: activeFeatures.map((feat) {
                  final cardWidth = isDesktop ? 360.0 : (isTablet ? 340.0 : double.infinity);
                  return SizedBox(
                    width: cardWidth,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5), size: 24),
                              ),
                              if (feat.badge.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFFAF5FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE9D5FF))),
                                  child: Text(feat.badge, style: GoogleFonts.inter(color: const Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(feat.title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 8),
                          Text(feat.description, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.5)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 7. CTA BANNER =================
  Widget _buildNewHereBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x334F46E5), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_config.ctaBanner.title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(_config.ctaBanner.description, style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => context.go(_config.ctaBanner.buttonDestination),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_config.ctaBanner.buttonLabel, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 8. FOOTER =================
  Widget _buildLandingFooter(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_config.header.brandName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 16,
                    children: _config.footer.footerLinks.map((link) => InkWell(
                      onTap: () => context.go(link.destination),
                      child: Text(link.label, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
                    )).toList(),
                  ),
                ],
              ),
              const Divider(height: 40, color: Color(0xFF1E293B)),
              Text(_config.footer.copyrightText, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF4F46E5)),
            child: Text(_config.header.brandName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ..._config.header.navItems.where((n) => n.isVisible).map((n) => ListTile(
            title: Text(n.label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              context.go(n.destination);
            },
          )),
        ],
      ),
    );
  }
}
