import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/feature_config_service.dart';
import '../../../models/landing_page_config_model.dart';

class AdminLandingPageManagerScreen extends StatefulWidget {
  const AdminLandingPageManagerScreen({Key? key}) : super(key: key);

  @override
  State<AdminLandingPageManagerScreen> createState() => _AdminLandingPageManagerScreenState();
}

class _AdminLandingPageManagerScreenState extends State<AdminLandingPageManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LandingPageConfigModel _config = LandingPageConfigModel.defaultConfig();
  bool _isLoading = true;
  bool _isSaving = false;
  String _previewDevice = 'DESKTOP'; // 'DESKTOP', 'TABLET', 'MOBILE'

  // Text Controllers
  // Header
  final _brandNameController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _announcementTextController = TextEditingController();
  final _loginBtnController = TextEditingController();
  final _signupBtnController = TextEditingController();

  // Hero
  final _heroTrustBadgeController = TextEditingController();
  final _heroHeadlineController = TextEditingController();
  final _heroDescController = TextEditingController();
  final _heroPrimaryBtnLabelController = TextEditingController();
  final _heroPrimaryBtnLinkController = TextEditingController();
  final _heroSecondaryBtnLabelController = TextEditingController();
  final _heroSecondaryBtnLinkController = TextEditingController();
  final _heroImageUrlController = TextEditingController();
  final _heroMobileImageUrlController = TextEditingController();
  final _heroStudentCountController = TextEditingController();

  // Banners & Test Series
  final _bannersTitleController = TextEditingController();
  final _bannersSubtitleController = TextEditingController();
  final _testSeriesTitleController = TextEditingController();
  final _testSeriesSubtitleController = TextEditingController();

  // Features & CTA
  final _featuresBadgeController = TextEditingController();
  final _featuresTitleController = TextEditingController();
  final _featuresSubtitleController = TextEditingController();

  final _ctaTitleController = TextEditingController();
  final _ctaDescController = TextEditingController();
  final _ctaBtnLabelController = TextEditingController();
  final _ctaBtnLinkController = TextEditingController();

  // Footer
  final _footerBrandDescController = TextEditingController();
  final _footerCopyrightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _brandNameController.dispose();
    _logoUrlController.dispose();
    _announcementTextController.dispose();
    _loginBtnController.dispose();
    _signupBtnController.dispose();

    _heroTrustBadgeController.dispose();
    _heroHeadlineController.dispose();
    _heroDescController.dispose();
    _heroPrimaryBtnLabelController.dispose();
    _heroPrimaryBtnLinkController.dispose();
    _heroSecondaryBtnLabelController.dispose();
    _heroSecondaryBtnLinkController.dispose();
    _heroImageUrlController.dispose();
    _heroMobileImageUrlController.dispose();
    _heroStudentCountController.dispose();

    _bannersTitleController.dispose();
    _bannersSubtitleController.dispose();
    _testSeriesTitleController.dispose();
    _testSeriesSubtitleController.dispose();

    _featuresBadgeController.dispose();
    _featuresTitleController.dispose();
    _featuresSubtitleController.dispose();

    _ctaTitleController.dispose();
    _ctaDescController.dispose();
    _ctaBtnLabelController.dispose();
    _ctaBtnLinkController.dispose();

    _footerBrandDescController.dispose();
    _footerCopyrightController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final loaded = await SupabaseService.fetchLandingPageConfig();
    if (mounted) {
      setState(() {
        _config = loaded;
        _populateControllers(loaded);
        _isLoading = false;
      });
    }
  }

  void _populateControllers(LandingPageConfigModel cfg) {
    _brandNameController.text = cfg.header.brandName;
    _logoUrlController.text = cfg.header.logoUrl;
    _announcementTextController.text = cfg.header.announcementBarText;
    _loginBtnController.text = cfg.header.loginButtonLabel;
    _signupBtnController.text = cfg.header.signupButtonLabel;

    _heroTrustBadgeController.text = cfg.hero.trustBadgeText;
    _heroHeadlineController.text = cfg.hero.headlineText;
    _heroDescController.text = cfg.hero.descriptionText;
    _heroPrimaryBtnLabelController.text = cfg.hero.primaryButtonLabel;
    _heroPrimaryBtnLinkController.text = cfg.hero.primaryButtonDestination;
    _heroSecondaryBtnLabelController.text = cfg.hero.secondaryButtonLabel;
    _heroSecondaryBtnLinkController.text = cfg.hero.secondaryButtonDestination;
    _heroImageUrlController.text = cfg.hero.heroImageUrl;
    _heroMobileImageUrlController.text = cfg.hero.heroMobileImageUrl;
    _heroStudentCountController.text = cfg.hero.studentCountText;

    _bannersTitleController.text = cfg.banners.sectionTitle;
    _bannersSubtitleController.text = cfg.banners.sectionSubtitle;
    _testSeriesTitleController.text = cfg.testSeries.sectionTitle;
    _testSeriesSubtitleController.text = cfg.testSeries.sectionSubtitle;

    _featuresBadgeController.text = cfg.features.badgeText;
    _featuresTitleController.text = cfg.features.sectionTitle;
    _featuresSubtitleController.text = cfg.features.sectionSubtitle;

    _ctaTitleController.text = cfg.ctaBanner.title;
    _ctaDescController.text = cfg.ctaBanner.description;
    _ctaBtnLabelController.text = cfg.ctaBanner.buttonLabel;
    _ctaBtnLinkController.text = cfg.ctaBanner.buttonDestination;

    _footerBrandDescController.text = cfg.footer.brandDescription;
    _footerCopyrightController.text = cfg.footer.copyrightText;
  }

  void _updateConfigState() {
    setState(() {
      _config = _config.copyWith(
        header: HeaderConfig(
          logoUrl: _logoUrlController.text.trim(),
          brandName: _brandNameController.text.trim(),
          stickyHeader: _config.header.stickyHeader,
          announcementBarText: _announcementTextController.text.trim(),
          showAnnouncementBar: _config.header.showAnnouncementBar,
          loginButtonLabel: _loginBtnController.text.trim(),
          signupButtonLabel: _signupBtnController.text.trim(),
          navItems: _config.header.navItems,
        ),
        hero: HeroSectionConfig(
          isVisible: _config.hero.isVisible,
          trustBadgeText: _heroTrustBadgeController.text.trim(),
          showTrustBadge: _config.hero.showTrustBadge,
          headlineText: _heroHeadlineController.text.trim(),
          descriptionText: _heroDescController.text.trim(),
          primaryButtonLabel: _heroPrimaryBtnLabelController.text.trim(),
          primaryButtonDestination: _heroPrimaryBtnLinkController.text.trim(),
          secondaryButtonLabel: _heroSecondaryBtnLabelController.text.trim(),
          secondaryButtonDestination: _heroSecondaryBtnLinkController.text.trim(),
          heroImageUrl: _heroImageUrlController.text.trim(),
          heroMobileImageUrl: _heroMobileImageUrlController.text.trim(),
          layoutTemplate: _config.hero.layoutTemplate,
          studentCountText: _heroStudentCountController.text.trim(),
          showFloatingCards: _config.hero.showFloatingCards,
        ),
        banners: BannersSectionConfig(
          isVisible: _config.banners.isVisible,
          sectionTitle: _bannersTitleController.text.trim(),
          sectionSubtitle: _bannersSubtitleController.text.trim(),
          carouselAutoPlay: _config.banners.carouselAutoPlay,
          carouselIntervalSeconds: _config.banners.carouselIntervalSeconds,
        ),
        testSeries: TestSeriesSectionConfig(
          isVisible: _config.testSeries.isVisible,
          sectionTitle: _testSeriesTitleController.text.trim(),
          sectionSubtitle: _testSeriesSubtitleController.text.trim(),
          maxItemsToShow: _config.testSeries.maxItemsToShow,
          layoutTemplate: _config.testSeries.layoutTemplate,
        ),
        features: FeaturesSectionConfig(
          isVisible: _config.features.isVisible,
          badgeText: _featuresBadgeController.text.trim(),
          sectionTitle: _featuresTitleController.text.trim(),
          sectionSubtitle: _featuresSubtitleController.text.trim(),
          features: _config.features.features,
        ),
        ctaBanner: CtaBannerConfig(
          isVisible: _config.ctaBanner.isVisible,
          title: _ctaTitleController.text.trim(),
          description: _ctaDescController.text.trim(),
          buttonLabel: _ctaBtnLabelController.text.trim(),
          buttonDestination: _ctaBtnLinkController.text.trim(),
          backgroundGradient: _config.ctaBanner.backgroundGradient,
        ),
        footer: FooterConfig(
          isVisible: _config.footer.isVisible,
          brandDescription: _footerBrandDescController.text.trim(),
          copyrightText: _footerCopyrightController.text.trim(),
          footerLinks: _config.footer.footerLinks,
        ),
        updatedAtTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  Future<void> _saveAndPublish() async {
    _updateConfigState();
    setState(() => _isSaving = true);
    final success = await SupabaseService.saveLandingPageConfig(_config);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Landing Page CMS published live across Web, Flutter Web & Mobile!'
                : '❌ Failed to publish CMS. Check connection.',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/admin'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.web_rounded, color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Landing Page Manager (CMS)',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Manage neet-jee.in landing page content, section order & layout live across all platforms',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset to Default',
            icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              setState(() {
                _config = LandingPageConfigModel.defaultConfig();
                _populateControllers(_config);
              });
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAndPublish,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.publish_rounded, size: 18),
            label: Text(_isSaving ? 'Publishing...' : 'Publish Live Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: '1. Header & Nav'),
            Tab(text: '2. Hero Section'),
            Tab(text: '3. Statistics Bar'),
            Tab(text: '4. Banners'),
            Tab(text: '5. Test Series'),
            Tab(text: '6. Features Grid'),
            Tab(text: '7. Signup CTA'),
            Tab(text: '8. Footer & Order'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : Row(
              children: [
                // Left Column: Tabbed Form Editor (Flex 6)
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.white,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHeaderEditor(),
                        _buildHeroEditor(),
                        _buildStatsEditor(),
                        _buildBannersEditor(),
                        _buildTestSeriesEditor(),
                        _buildFeaturesEditor(),
                        _buildCtaEditor(),
                        _buildFooterAndOrderEditor(),
                      ],
                    ),
                  ),
                ),

                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                // Right Column: Interactive Multi-Device Live Preview (Flex 6)
                Expanded(
                  flex: 6,
                  child: _buildLivePreviewPanel(),
                ),
              ],
            ),
    );
  }

  // ================= 1. HEADER EDITOR =================
  Widget _buildHeaderEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Header Navigation & Announcement Bar', 'Configure brand logo, nav buttons, and notification banner'),
        const SizedBox(height: 16),
        _buildTextField(_brandNameController, 'Brand Name / Platform Title', 'e.g. Cosmyra NEET | JEE'),
        const SizedBox(height: 14),
        _buildTextField(_logoUrlController, 'Logo Asset / Image URL', 'Leave empty for default logo vector'),
        const SizedBox(height: 14),
        SwitchListTile(
          value: _config.header.stickyHeader,
          onChanged: (val) => setState(() => _config = _config.copyWith(header: HeaderConfig(
            logoUrl: _config.header.logoUrl,
            brandName: _config.header.brandName,
            stickyHeader: val,
            announcementBarText: _config.header.announcementBarText,
            showAnnouncementBar: _config.header.showAnnouncementBar,
            loginButtonLabel: _config.header.loginButtonLabel,
            signupButtonLabel: _config.header.signupButtonLabel,
            navItems: _config.header.navItems,
          ))),
          title: Text('Sticky Top Header', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('Keep navigation bar pinned to top during scroll', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
          activeColor: const Color(0xFF4F46E5),
        ),
        const Divider(height: 32),
        SwitchListTile(
          value: _config.header.showAnnouncementBar,
          onChanged: (val) => setState(() => _config = _config.copyWith(header: HeaderConfig(
            logoUrl: _config.header.logoUrl,
            brandName: _config.header.brandName,
            stickyHeader: _config.header.stickyHeader,
            announcementBarText: _config.header.announcementBarText,
            showAnnouncementBar: val,
            loginButtonLabel: _config.header.loginButtonLabel,
            signupButtonLabel: _config.header.signupButtonLabel,
            navItems: _config.header.navItems,
          ))),
          title: Text('Show Top Announcement Bar', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          activeColor: const Color(0xFF4F46E5),
        ),
        const SizedBox(height: 8),
        _buildTextField(_announcementTextController, 'Announcement Bar Text', 'Promotional headline text'),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(child: _buildTextField(_loginBtnController, 'Log In Button Text', 'e.g. Log In')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(_signupBtnController, 'Sign Up Button Text', 'e.g. Get Started Free')),
          ],
        ),
      ],
    );
  }

  // ================= 2. HERO EDITOR =================
  Widget _buildHeroEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Hero Banner Section', 'Main headline, trust badge, primary CTAs, and hero illustration'),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _config.hero.isVisible,
          onChanged: (val) => setState(() => _config = _config.copyWith(hero: HeroSectionConfig(
            isVisible: val,
            trustBadgeText: _config.hero.trustBadgeText,
            showTrustBadge: _config.hero.showTrustBadge,
            headlineText: _config.hero.headlineText,
            descriptionText: _config.hero.descriptionText,
            primaryButtonLabel: _config.hero.primaryButtonLabel,
            primaryButtonDestination: _config.hero.primaryButtonDestination,
            secondaryButtonLabel: _config.hero.secondaryButtonLabel,
            secondaryButtonDestination: _config.hero.secondaryButtonDestination,
            heroImageUrl: _config.hero.heroImageUrl,
            heroMobileImageUrl: _config.hero.heroMobileImageUrl,
            layoutTemplate: _config.hero.layoutTemplate,
            studentCountText: _config.hero.studentCountText,
            showFloatingCards: _config.hero.showFloatingCards,
          ))),
          title: Text('Enable Hero Section', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          activeColor: const Color(0xFF4F46E5),
        ),
        const SizedBox(height: 14),
        _buildTextField(_heroHeadlineController, 'Main Headline', 'Master NEET & JEE with All-India Test Series'),
        const SizedBox(height: 14),
        _buildTextField(_heroDescController, 'Supporting Subtitle', 'Detailed platform description', maxLines: 3),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(_heroTrustBadgeController, 'Trust Badge Text', '⭐ India\'s #1 Test Series Platform')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(_heroStudentCountController, 'Community/Student Counter', 'Join 50,000+ aspirants')),
          ],
        ),
        const Divider(height: 32),
        Text('Layout Preset Template', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF334155))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            _buildChoiceChip('Split Left (Text Left, Image Right)', _config.hero.layoutTemplate == 'HERO_SPLIT_LEFT', () {
              setState(() => _config = _config.copyWith(hero: HeroSectionConfig(
                isVisible: _config.hero.isVisible,
                trustBadgeText: _config.hero.trustBadgeText,
                showTrustBadge: _config.hero.showTrustBadge,
                headlineText: _config.hero.headlineText,
                descriptionText: _config.hero.descriptionText,
                primaryButtonLabel: _config.hero.primaryButtonLabel,
                primaryButtonDestination: _config.hero.primaryButtonDestination,
                secondaryButtonLabel: _config.hero.secondaryButtonLabel,
                secondaryButtonDestination: _config.hero.secondaryButtonDestination,
                heroImageUrl: _config.hero.heroImageUrl,
                heroMobileImageUrl: _config.hero.heroMobileImageUrl,
                layoutTemplate: 'HERO_SPLIT_LEFT',
                studentCountText: _config.hero.studentCountText,
                showFloatingCards: _config.hero.showFloatingCards,
              )));
            }),
            _buildChoiceChip('Centered Hero Layout', _config.hero.layoutTemplate == 'HERO_CENTERED', () {
              setState(() => _config = _config.copyWith(hero: HeroSectionConfig(
                isVisible: _config.hero.isVisible,
                trustBadgeText: _config.hero.trustBadgeText,
                showTrustBadge: _config.hero.showTrustBadge,
                headlineText: _config.hero.headlineText,
                descriptionText: _config.hero.descriptionText,
                primaryButtonLabel: _config.hero.primaryButtonLabel,
                primaryButtonDestination: _config.hero.primaryButtonDestination,
                secondaryButtonLabel: _config.hero.secondaryButtonLabel,
                secondaryButtonDestination: _config.hero.secondaryButtonDestination,
                heroImageUrl: _config.hero.heroImageUrl,
                heroMobileImageUrl: _config.hero.heroMobileImageUrl,
                layoutTemplate: 'HERO_CENTERED',
                studentCountText: _config.hero.studentCountText,
                showFloatingCards: _config.hero.showFloatingCards,
              )));
            }),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(child: _buildTextField(_heroPrimaryBtnLabelController, 'Primary Button Label', 'Start Practicing Now')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(_heroPrimaryBtnLinkController, 'Primary Button Link', '/signup')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(_heroSecondaryBtnLabelController, 'Secondary Button Label', 'Explore Test Series')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(_heroSecondaryBtnLinkController, 'Secondary Button Link', '/test-series')),
          ],
        ),
      ],
    );
  }

  // ================= 3. STATS EDITOR =================
  Widget _buildStatsEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Statistics Bar Section', 'Key platform counters (Students, Mock Tests, PYQs, Satisfaction Rate)'),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _config.stats.isVisible,
          onChanged: (val) => setState(() => _config = _config.copyWith(stats: StatsSectionConfig(
            isVisible: val,
            statsList: _config.stats.statsList,
          ))),
          title: Text('Enable Statistics Section', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          activeColor: const Color(0xFF4F46E5),
        ),
        const SizedBox(height: 16),
        ..._config.stats.statsList.map((st) {
          final idx = _config.stats.statsList.indexOf(st);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.analytics_outlined, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Card #${idx + 1}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                        Text('${st.value} — ${st.label}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF4F46E5)),
                    onPressed: () => _editStatDialog(st, idx),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _editStatDialog(StatCardConfig stat, int index) {
    final valCtrl = TextEditingController(text: stat.value);
    final lblCtrl = TextEditingController(text: stat.label);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Stat Card #${index + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(valCtrl, 'Metric Value', 'e.g. 50,000+'),
            const SizedBox(height: 12),
            _buildTextField(lblCtrl, 'Metric Label', 'e.g. Active Students'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newList = List<StatCardConfig>.from(_config.stats.statsList);
              newList[index] = StatCardConfig(
                id: stat.id,
                value: valCtrl.text.trim(),
                label: lblCtrl.text.trim(),
                icon: stat.icon,
                isVisible: stat.isVisible,
              );
              setState(() => _config = _config.copyWith(stats: StatsSectionConfig(
                isVisible: _config.stats.isVisible,
                statsList: newList,
              )));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ================= 4. BANNERS EDITOR =================
  Widget _buildBannersEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Promotional Banners & Announcements', 'Dynamic banners pulled directly from database Banner Management'),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _config.banners.isVisible,
          onChanged: (val) => setState(() => _config = _config.copyWith(banners: BannersSectionConfig(
            isVisible: val,
            sectionTitle: _config.banners.sectionTitle,
            sectionSubtitle: _config.banners.sectionSubtitle,
            carouselAutoPlay: _config.banners.carouselAutoPlay,
            carouselIntervalSeconds: _config.banners.carouselIntervalSeconds,
          ))),
          title: Text('Enable Banners Section', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          activeColor: const Color(0xFF4F46E5),
        ),
        const SizedBox(height: 14),
        _buildTextField(_bannersTitleController, 'Section Title', 'Promotional Banners & Announcements'),
        const SizedBox(height: 14),
        _buildTextField(_bannersSubtitleController, 'Section Subtitle', 'Special offers, live test events & updates'),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.go('/admin/banners'),
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF4F46E5)),
          label: Text('Open Full Banner Manager CMS (Upload & Schedule Banners)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ================= 5. TEST SERIES EDITOR =================
  Widget _buildTestSeriesEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Recommended Test Series Showcase', 'Fetches real active Test Series products from database'),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _config.testSeries.isVisible,
          onChanged: (val) => setState(() => _config = _config.copyWith(testSeries: TestSeriesSectionConfig(
            isVisible: val,
            sectionTitle: _config.testSeries.sectionTitle,
            sectionSubtitle: _config.testSeries.sectionSubtitle,
            maxItemsToShow: _config.testSeries.maxItemsToShow,
            layoutTemplate: _config.testSeries.layoutTemplate,
          ))),
          title: Text('Enable Recommended Test Series Section', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          activeColor: const Color(0xFF4F46E5),
        ),
        const SizedBox(height: 14),
        _buildTextField(_testSeriesTitleController, 'Section Title', 'Recommended Test Series'),
        const SizedBox(height: 14),
        _buildTextField(_testSeriesSubtitleController, 'Section Subtitle', 'Curated by Top NEET & JEE Educators'),
      ],
    );
  }

  // ================= 6. FEATURES EDITOR =================
  Widget _buildFeaturesEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Powerful Features Grid', 'Integrated with Feature Manager (hidden features auto-hide)'),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _config.features.isVisible,
          onChanged: (val) => setState(() => _config = _config.copyWith(features: FeaturesSectionConfig(
            isVisible: val,
            badgeText: _config.features.badgeText,
            sectionTitle: _config.features.sectionTitle,
            sectionSubtitle: _config.features.sectionSubtitle,
            features: _config.features.features,
          ))),
          title: Text('Enable Features Section', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          activeColor: const Color(0xFF4F46E5),
        ),
        const SizedBox(height: 14),
        _buildTextField(_featuresBadgeController, 'Top Badge Text', 'EVERYTHING YOU NEED TO SUCCEED'),
        const SizedBox(height: 14),
        _buildTextField(_featuresTitleController, 'Section Title', 'Powerful Features for Every Aspirant'),
        const SizedBox(height: 14),
        _buildTextField(_featuresSubtitleController, 'Section Subtitle', 'All the tools you need to plan, practice, analyze...'),
        const Divider(height: 32),
        OutlinedButton.icon(
          onPressed: () => context.go('/admin/feature-manager'),
          icon: const Icon(Icons.toggle_on_rounded, color: Color(0xFF4F46E5)),
          label: Text('Open Feature Manager (Global App Feature Toggles)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFFC7D2FE)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // ================= 7. CTA EDITOR =================
  Widget _buildCtaEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Signup Call-To-Action Banner', 'Bottom callout banner encouraging free account signup'),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _config.ctaBanner.isVisible,
          onChanged: (val) => setState(() => _config = _config.copyWith(ctaBanner: CtaBannerConfig(
            isVisible: val,
            title: _config.ctaBanner.title,
            description: _config.ctaBanner.description,
            buttonLabel: _config.ctaBanner.buttonLabel,
            buttonDestination: _config.ctaBanner.buttonDestination,
            backgroundGradient: _config.ctaBanner.backgroundGradient,
          ))),
          title: Text('Enable CTA Banner Section', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          activeColor: const Color(0xFF4F46E5),
        ),
        const SizedBox(height: 14),
        _buildTextField(_ctaTitleController, 'Banner Heading', 'New to Cosmyra NEET | JEE?'),
        const SizedBox(height: 14),
        _buildTextField(_ctaDescController, 'Supporting Text', 'Create your free account today and get access...'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(_ctaBtnLabelController, 'Button Label', 'Create Free Account')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(_ctaBtnLinkController, 'Button Link', '/signup')),
          ],
        ),
      ],
    );
  }

  // ================= 8. FOOTER & ORDER EDITOR =================
  Widget _buildFooterAndOrderEditor() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Footer & Section Ordering', 'Manage copyright, legal links, and reorder landing page sections'),
        const SizedBox(height: 16),
        _buildTextField(_footerBrandDescController, 'Brand Description Text', 'Cosmyra Technologies — India\'s premier platform...'),
        const SizedBox(height: 14),
        _buildTextField(_footerCopyrightController, 'Copyright Line', '© 2026 Cosmyra Technologies Pvt. Ltd.'),
        const Divider(height: 32),
        Text('Section Display Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
        Text('Reorder landing page blocks live', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 12),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _config.sectionOrder.map((sec) {
            return Card(
              key: ValueKey(sec),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
              child: ListTile(
                leading: const Icon(Icons.drag_indicator_rounded, color: Color(0xFF94A3B8)),
                title: Text(_getSectionName(sec), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5)),
                trailing: const Icon(Icons.unfold_more_rounded, size: 20, color: Color(0xFF64748B)),
              ),
            );
          }).toList(),
          onReorder: (oldIdx, newIdx) {
            setState(() {
              if (newIdx > oldIdx) newIdx -= 1;
              final list = List<String>.from(_config.sectionOrder);
              final item = list.removeAt(oldIdx);
              list.insert(newIdx, item);
              _config = _config.copyWith(sectionOrder: list);
            });
          },
        ),
      ],
    );
  }

  String _getSectionName(String key) {
    switch (key) {
      case 'hero': return 'Hero Section';
      case 'stats': return 'Statistics Bar';
      case 'banners': return 'Promotional Banners';
      case 'test_series': return 'Recommended Test Series';
      case 'features': return 'Powerful Features Grid';
      case 'cta_banner': return 'Signup CTA Banner';
      case 'footer': return 'Official Footer';
      default: return key;
    }
  }

  // ================= LIVE PREVIEW PANEL =================
  Widget _buildLivePreviewPanel() {
    double width = 800;
    if (_previewDevice == 'MOBILE') width = 390;
    if (_previewDevice == 'TABLET') width = 768;

    return Column(
      children: [
        // Preview Header Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFFF1F5F9),
          child: Row(
            children: [
              Text('LIVE DEVICE PREVIEW', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF475569), letterSpacing: 0.5)),
              const Spacer(),
              _buildDeviceBtn('DESKTOP', Icons.desktop_windows_rounded),
              const SizedBox(width: 6),
              _buildDeviceBtn('TABLET', Icons.tablet_mac_rounded),
              const SizedBox(width: 6),
              _buildDeviceBtn('MOBILE', Icons.smartphone_rounded),
            ],
          ),
        ),

        // Live Simulated Viewport
        Expanded(
          child: Center(
            child: Container(
              width: width,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))],
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.school_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(_brandNameController.text.isEmpty ? 'Cosmyra NEET | JEE' : _brandNameController.text, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton(onPressed: () {}, child: Text(_loginBtnController.text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)))),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                child: Text(_signupBtnController.text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Announcement Bar
                    if (_config.header.showAnnouncementBar)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        color: const Color(0xFFEEF2FF),
                        child: Text(
                          _announcementTextController.text,
                          style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Hero Live Preview
                    if (_config.hero.isVisible)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF)]),
                        ),
                        child: Column(
                          children: [
                            if (_config.hero.showTrustBadge)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7D2FE))),
                                child: Text(_heroTrustBadgeController.text, style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(height: 12),
                            Text(_heroHeadlineController.text, style: GoogleFonts.outfit(fontSize: _previewDevice == 'MOBILE' ? 20 : 26, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(_heroDescController.text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                                  child: Text(_heroPrimaryBtnLabelController.text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                OutlinedButton(
                                  onPressed: () {},
                                  child: Text(_heroSecondaryBtnLabelController.text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Stats Live Preview
                    if (_config.stats.isVisible)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _config.stats.statsList.map((st) => Column(
                            children: [
                              Text(st.value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5))),
                              Text(st.label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                            ],
                          )).toList(),
                        ),
                      ),

                    // Features Preview
                    if (_config.features.isVisible)
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: const Color(0xFFF8FAFC),
                        child: Column(
                          children: [
                            Text(_featuresTitleController.text, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _config.features.features.map((f) {
                                return SizedBox(
                                  width: _previewDevice == 'MOBILE' ? double.infinity : 160.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(f.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(f.description, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                    // CTA Preview
                    if (_config.ctaBanner.isVisible)
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: const Color(0xFF4F46E5),
                        child: Column(
                          children: [
                            Text(_ctaTitleController.text, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(_ctaDescController.text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5)),
                              child: Text(_ctaBtnLabelController.text, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceBtn(String mode, IconData icon) {
    final isSelected = _previewDevice == mode;
    return InkWell(
      onTap: () => setState(() => _previewDevice = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(mode, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) => _updateConfigState(),
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onSelect) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF334155))),
      selected: isSelected,
      onSelected: (_) => onSelect(),
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: const Color(0xFFF1F5F9),
    );
  }
}
