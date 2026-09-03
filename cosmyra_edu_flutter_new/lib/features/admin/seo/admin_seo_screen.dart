import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/seo_tracking_service.dart';

class AdminSeoScreen extends StatefulWidget {
  final UserProfileModel? userProfile;

  const AdminSeoScreen({super.key, this.userProfile});

  @override
  State<AdminSeoScreen> createState() => _AdminSeoScreenState();
}

class _AdminSeoScreenState extends State<AdminSeoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _statusMessage;
  bool _statusIsError = false;

  // Global Settings Data
  late SeoGlobalSettingsModel _settings;

  // Custom Scripts Data
  List<SeoCustomScriptModel> _customScripts = [];

  // Schemas Data
  List<SeoSchemaModel> _schemas = [];

  // SEO Health Data
  SeoHealthAuditModel? _healthAudit;
  bool _isAuditing = false;

  // Form Controllers - Global SEO
  final _siteNameCtrl = TextEditingController();
  final _websiteTitleCtrl = TextEditingController();
  final _metaTitleCtrl = TextEditingController();
  final _metaDescCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  final _canonicalUrlCtrl = TextEditingController();
  final _ogTitleCtrl = TextEditingController();
  final _ogDescCtrl = TextEditingController();
  final _ogImageCtrl = TextEditingController();
  final _twitterHandleCtrl = TextEditingController();
  final _orgNameCtrl = TextEditingController();
  final _orgLogoCtrl = TextEditingController();
  final _orgEmailCtrl = TextEditingController();
  final _orgPhoneCtrl = TextEditingController();
  String _twitterCardType = 'summary_large_image';

  // Google Search Console
  String _gscMethod = 'meta_tag';
  final _gscCodeCtrl = TextEditingController();
  bool _gscActive = true;

  // Google Analytics
  final _ga4IdCtrl = TextEditingController();
  bool _ga4Enabled = false;
  String _ga4Env = 'production';

  // Google Ads
  final _gAdsIdCtrl = TextEditingController();
  final _gAdsLabelCtrl = TextEditingController();
  bool _gAdsEnabled = false;

  // AdSense
  final _adsensePubIdCtrl = TextEditingController();
  bool _adsenseEnabled = false;
  bool _adsenseAutoAds = false;
  final _adsenseCustomCodeCtrl = TextEditingController();

  // Code Injection Zones
  final _headCodeCtrl = TextEditingController();
  bool _headCodeEnabled = false;
  final _bodyStartCodeCtrl = TextEditingController();
  bool _bodyStartCodeEnabled = false;
  final _bodyEndCodeCtrl = TextEditingController();
  bool _bodyEndCodeEnabled = false;
  final _footerCodeCtrl = TextEditingController();
  bool _footerCodeEnabled = false;

  // Sitemap & Robots
  final _robotsTxtCtrl = TextEditingController();
  bool _sitemapEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _loadAllSeoData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _siteNameCtrl.dispose();
    _websiteTitleCtrl.dispose();
    _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose();
    _keywordsCtrl.dispose();
    _canonicalUrlCtrl.dispose();
    _ogTitleCtrl.dispose();
    _ogDescCtrl.dispose();
    _ogImageCtrl.dispose();
    _twitterHandleCtrl.dispose();
    _orgNameCtrl.dispose();
    _orgLogoCtrl.dispose();
    _orgEmailCtrl.dispose();
    _orgPhoneCtrl.dispose();
    _gscCodeCtrl.dispose();
    _ga4IdCtrl.dispose();
    _gAdsIdCtrl.dispose();
    _gAdsLabelCtrl.dispose();
    _adsensePubIdCtrl.dispose();
    _adsenseCustomCodeCtrl.dispose();
    _headCodeCtrl.dispose();
    _bodyStartCodeCtrl.dispose();
    _bodyEndCodeCtrl.dispose();
    _footerCodeCtrl.dispose();
    _robotsTxtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllSeoData() async {
    setState(() => _isLoading = true);
    final settings = await SupabaseService.fetchSeoGlobalSettings();
    final scripts = await SupabaseService.fetchSeoCustomScripts();
    final schemas = await SupabaseService.fetchSeoSchemas();

    if (mounted) {
      setState(() {
        _settings = settings;
        _customScripts = scripts;
        _schemas = schemas;

        // Populate controllers
        _siteNameCtrl.text = settings.siteName;
        _websiteTitleCtrl.text = settings.websiteTitle;
        _metaTitleCtrl.text = settings.defaultMetaTitle;
        _metaDescCtrl.text = settings.defaultMetaDescription;
        _keywordsCtrl.text = settings.defaultKeywords;
        _canonicalUrlCtrl.text = settings.canonicalBaseUrl;
        _ogTitleCtrl.text = settings.defaultOgTitle;
        _ogDescCtrl.text = settings.defaultOgDescription;
        _ogImageCtrl.text = settings.defaultOgImage;
        _twitterCardType = settings.twitterCardType;
        _twitterHandleCtrl.text = settings.twitterSiteHandle;
        _orgNameCtrl.text = settings.organizationName;
        _orgLogoCtrl.text = settings.organizationLogoUrl;
        _orgEmailCtrl.text = settings.organizationContactEmail;
        _orgPhoneCtrl.text = settings.organizationPhone;

        _gscMethod = settings.gscVerificationMethod;
        _gscCodeCtrl.text = settings.gscVerificationCode;
        _gscActive = settings.gscIsActive;

        _ga4IdCtrl.text = settings.ga4MeasurementId;
        _ga4Enabled = settings.ga4IsEnabled;
        _ga4Env = settings.ga4Environment;

        _gAdsIdCtrl.text = settings.googleAdsConversionId;
        _gAdsLabelCtrl.text = settings.googleAdsConversionLabel;
        _gAdsEnabled = settings.googleAdsIsEnabled;

        _adsensePubIdCtrl.text = settings.adsensePublisherId;
        _adsenseEnabled = settings.adsenseIsEnabled;
        _adsenseAutoAds = settings.adsenseAutoAdsEnabled;
        _adsenseCustomCodeCtrl.text = settings.adsenseCustomCode;

        _headCodeCtrl.text = settings.headCode;
        _headCodeEnabled = settings.headCodeEnabled;
        _bodyStartCodeCtrl.text = settings.bodyStartCode;
        _bodyStartCodeEnabled = settings.bodyStartCodeEnabled;
        _bodyEndCodeCtrl.text = settings.bodyEndCode;
        _bodyEndCodeEnabled = settings.bodyEndCodeEnabled;
        _footerCodeCtrl.text = settings.footerCode;
        _footerCodeEnabled = settings.footerCodeEnabled;

        _robotsTxtCtrl.text = settings.robotsTxtContent;
        _sitemapEnabled = settings.sitemapXmlEnabled;

        _isLoading = false;
      });
      _runAudit();
    }
  }

  Future<void> _runAudit() async {
    setState(() => _isAuditing = true);
    final audit = await SupabaseService.runSeoHealthAudit();
    if (mounted) {
      setState(() {
        _healthAudit = audit;
        _isAuditing = false;
      });
    }
  }

  Future<void> _saveAllSettings() async {
    setState(() {
      _isSaving = true;
      _statusMessage = 'Saving SEO settings to database...';
      _statusIsError = false;
    });

    final updated = _settings.copyWith(
      siteName: _siteNameCtrl.text.trim(),
      websiteTitle: _websiteTitleCtrl.text.trim(),
      defaultMetaTitle: _metaTitleCtrl.text.trim(),
      defaultMetaDescription: _metaDescCtrl.text.trim(),
      defaultKeywords: _keywordsCtrl.text.trim(),
      canonicalBaseUrl: _canonicalUrlCtrl.text.trim(),
      defaultOgTitle: _ogTitleCtrl.text.trim(),
      defaultOgDescription: _ogDescCtrl.text.trim(),
      defaultOgImage: _ogImageCtrl.text.trim(),
      twitterCardType: _twitterCardType,
      twitterSiteHandle: _twitterHandleCtrl.text.trim(),
      organizationName: _orgNameCtrl.text.trim(),
      organizationLogoUrl: _orgLogoCtrl.text.trim(),
      organizationContactEmail: _orgEmailCtrl.text.trim(),
      organizationPhone: _orgPhoneCtrl.text.trim(),
      gscVerificationMethod: _gscMethod,
      gscVerificationCode: _gscCodeCtrl.text.trim(),
      gscIsActive: _gscActive,
      ga4MeasurementId: _ga4IdCtrl.text.trim(),
      ga4IsEnabled: _ga4Enabled,
      ga4Environment: _ga4Env,
      googleAdsConversionId: _gAdsIdCtrl.text.trim(),
      googleAdsConversionLabel: _gAdsLabelCtrl.text.trim(),
      googleAdsIsEnabled: _gAdsEnabled,
      adsensePublisherId: _adsensePubIdCtrl.text.trim(),
      adsenseIsEnabled: _adsenseEnabled,
      adsenseAutoAdsEnabled: _adsenseAutoAds,
      adsenseCustomCode: _adsenseCustomCodeCtrl.text.trim(),
      headCode: _headCodeCtrl.text,
      headCodeEnabled: _headCodeEnabled,
      bodyStartCode: _bodyStartCodeCtrl.text,
      bodyStartCodeEnabled: _bodyStartCodeEnabled,
      bodyEndCode: _bodyEndCodeCtrl.text,
      bodyEndCodeEnabled: _bodyEndCodeEnabled,
      footerCode: _footerCodeCtrl.text,
      footerCodeEnabled: _footerCodeEnabled,
      robotsTxtContent: _robotsTxtCtrl.text,
      sitemapXmlEnabled: _sitemapEnabled,
      updatedAt: DateTime.now(),
    );

    final success = await SupabaseService.saveSeoGlobalSettings(updated);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _settings = updated;
        _statusMessage = success ? 'Saved successfully! Changes are live.' : 'Save failed. Check database connection.';
        _statusIsError = !success;
      });

      if (success) {
        SeoTrackingService.refreshTracking();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All SEO & Tracking settings saved successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings to Supabase. Check RLS or network.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/admin');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.travel_explore_rounded, color: Color(0xFF059669), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'SEO & Tracking Manager',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (_statusMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _statusIsError ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  ),
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAllSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Save All Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF059669),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'SEO Settings'),
            Tab(text: 'Google Search Console'),
            Tab(text: 'Google Analytics'),
            Tab(text: 'Google Ads'),
            Tab(text: 'AdSense'),
            Tab(text: 'Code Injection'),
            Tab(text: 'Scripts'),
            Tab(text: 'Schema'),
            Tab(text: 'Sitemap & Robots'),
            Tab(text: 'SEO Health'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGlobalSeoTab(),
                _buildGscTab(),
                _buildGa4Tab(),
                _buildGoogleAdsTab(),
                _buildAdSenseTab(),
                _buildCodeInjectionTab(),
                _buildScriptsTab(),
                _buildSchemaTab(),
                _buildSitemapRobotsTab(),
                _buildSeoHealthTab(),
              ],
            ),
    );
  }

  // =========================================================================
  // TAB 1: GLOBAL SEO SETTINGS
  // =========================================================================
  Widget _buildGlobalSeoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Global Search Engine Optimization', 'Control meta titles, descriptions, canonical URLs, and social share cards across the entire website.'),
              const SizedBox(height: 20),

              // Card 1: Core Titles & Metadata
              _card(
                title: 'Core Website Identity & Meta Tags',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _textField(controller: _siteNameCtrl, label: 'Website / Brand Name *', hint: 'Cosmyra NEET JEE'),
                    const SizedBox(height: 14),
                    _textField(controller: _websiteTitleCtrl, label: 'Main Website Title *', hint: 'Cosmyra NEET JEE | India\'s Best Exam Preparation Platform'),
                    const SizedBox(height: 14),
                    _textField(controller: _metaTitleCtrl, label: 'Default Meta Title (Fallback for all pages)', hint: 'Cosmyra NEET JEE - Practice Today, Achieve Tomorrow'),
                    const SizedBox(height: 14),
                    _textField(
                      controller: _metaDescCtrl,
                      label: 'Default Meta Description (150-160 characters)',
                      hint: 'High-yield question banks, mock tests, and analytics for NEET & JEE...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _textField(controller: _keywordsCtrl, label: 'Default Meta Keywords (Comma separated)', hint: 'NEET 2026, JEE Main, Mock Tests, Cosmyra'),
                    const SizedBox(height: 14),
                    _textField(controller: _canonicalUrlCtrl, label: 'Canonical Base URL *', hint: 'https://neet-jee.in'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card 2: Open Graph & Twitter Cards
              _card(
                title: 'Social Share Cards (Open Graph & Twitter/X)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _textField(controller: _ogTitleCtrl, label: 'Default Open Graph Title', hint: 'Cosmyra NEET JEE | Ace Your Medical & Engineering Entrance'),
                    const SizedBox(height: 14),
                    _textField(controller: _ogDescCtrl, label: 'Default Open Graph Description', hint: 'Join thousands of students cracking NEET & JEE...', maxLines: 2),
                    const SizedBox(height: 14),
                    _textField(controller: _ogImageCtrl, label: 'Default Social Share Image URL (1200x630px recommended)', hint: 'https://neet-jee.in/icons/Icon-512.png'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _twitterCardType,
                            decoration: const InputDecoration(labelText: 'Twitter Card Format', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'summary_large_image', child: Text('Summary with Large Image (Recommended)')),
                              DropdownMenuItem(value: 'summary', child: Text('Standard Summary Card')),
                            ],
                            onChanged: (v) => setState(() => _twitterCardType = v ?? 'summary_large_image'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _textField(controller: _twitterHandleCtrl, label: 'Twitter Handle', hint: '@cosmyra_edu'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card 3: Organization Schema Information
              _card(
                title: 'Organization Information',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _textField(controller: _orgNameCtrl, label: 'Organization Legal Name', hint: 'Cosmyra Technologies Pvt. Ltd.')),
                        const SizedBox(width: 14),
                        Expanded(child: _textField(controller: _orgEmailCtrl, label: 'Support / Contact Email', hint: 'support@neet-jee.in')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _textField(controller: _orgPhoneCtrl, label: 'Support Phone Number', hint: '+91 98765 43210')),
                        const SizedBox(width: 14),
                        Expanded(child: _textField(controller: _orgLogoCtrl, label: 'Organization Logo URL', hint: 'https://neet-jee.in/assets/images/cosmyra_logo.png')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2: GOOGLE SEARCH CONSOLE
  // =========================================================================
  Widget _buildGscTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Google Search Console Integration', 'Verify domain ownership and monitor indexing status on Google Search.'),
              const SizedBox(height: 20),
              _card(
                title: 'Domain Ownership Verification',
                headerAction: _statusBadge(_gscActive && _gscCodeCtrl.text.isNotEmpty ? 'Active' : 'Disabled'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Search Console Verification', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Injects verification meta tags into all public page <head> tags'),
                      value: _gscActive,
                      activeColor: const Color(0xFF059669),
                      onChanged: (v) => setState(() => _gscActive = v),
                    ),
                    const Divider(height: 24),
                    DropdownButtonFormField<String>(
                      value: _gscMethod,
                      decoration: const InputDecoration(labelText: 'Verification Method', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'meta_tag', child: Text('HTML Tag (<meta name="google-site-verification">)')),
                        DropdownMenuItem(value: 'html_file', child: Text('HTML File Upload')),
                        DropdownMenuItem(value: 'dns', child: Text('DNS TXT Record')),
                      ],
                      onChanged: (v) => setState(() => _gscMethod = v ?? 'meta_tag'),
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _gscCodeCtrl,
                      label: 'Verification Code / Token *',
                      hint: 'U3bHrqMV9245aSAvvNJxbuheY1mOPNFDfXZkGbEvHys',
                      helperText: 'Copied directly from Google Search Console > Settings > Ownership Verification.',
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF4F46E5), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Generated HTML Tag:\n<meta name="google-site-verification" content="${_gscCodeCtrl.text}" />',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF1E293B)),
                            ),
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
      ),
    );
  }

  // =========================================================================
  // TAB 3: GOOGLE ANALYTICS (GA4)
  // =========================================================================
  Widget _buildGa4Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Google Analytics 4 (GA4)', 'Track student engagement, mock test starts, question attempts, and organic traffic automatically.'),
              const SizedBox(height: 20),
              _card(
                title: 'GA4 Stream Settings',
                headerAction: _statusBadge(_ga4Enabled && _ga4IdCtrl.text.isNotEmpty ? 'Active' : 'Disabled'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Google Analytics 4', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Automatically injects gtag.js into the public website with deduplication protection'),
                      value: _ga4Enabled,
                      activeColor: const Color(0xFF059669),
                      onChanged: (v) => setState(() => _ga4Enabled = v),
                    ),
                    const Divider(height: 24),
                    _textField(
                      controller: _ga4IdCtrl,
                      label: 'GA4 Measurement ID *',
                      hint: 'G-XXXXXXXXXX',
                      helperText: 'Found under Google Analytics Admin > Data Streams > Web > Measurement ID.',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _ga4Env,
                      decoration: const InputDecoration(labelText: 'Tracking Environment', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'production', child: Text('Production Only (Excludes local testing)')),
                        DropdownMenuItem(value: 'all', child: Text('All Environments (Including staging)')),
                      ],
                      onChanged: (v) => setState(() => _ga4Env = v ?? 'production'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 4: GOOGLE ADS
  // =========================================================================
  Widget _buildGoogleAdsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Google Ads Conversion Tracking', 'Track ad campaign return on investment (ROI), registrations, and premium course purchases.'),
              const SizedBox(height: 20),
              _card(
                title: 'Conversion Tracking Credentials',
                headerAction: _statusBadge(_gAdsEnabled && _gAdsIdCtrl.text.isNotEmpty ? 'Active' : 'Disabled'),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Google Ads Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Tracks signup and test purchase conversions across Google campaigns'),
                      value: _gAdsEnabled,
                      activeColor: const Color(0xFF059669),
                      onChanged: (v) => setState(() => _gAdsEnabled = v),
                    ),
                    const Divider(height: 24),
                    _textField(controller: _gAdsIdCtrl, label: 'Google Ads Conversion ID', hint: 'AW-XXXXXXXXX'),
                    const SizedBox(height: 16),
                    _textField(controller: _gAdsLabelCtrl, label: 'Default Conversion Label', hint: 'AbCdEfGhIjKlMnOpQrS'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 5: GOOGLE ADSENSE
  // =========================================================================
  Widget _buildAdSenseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Google AdSense Monetization', 'Manage display advertising and auto-ads on informational pages and blog articles.'),
              const SizedBox(height: 20),
              _card(
                title: 'Publisher Account Settings',
                headerAction: _statusBadge(_adsenseEnabled && _adsensePubIdCtrl.text.isNotEmpty ? 'Active' : 'Disabled'),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable AdSense Integration', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Injects adsbygoogle.js script automatically'),
                      value: _adsenseEnabled,
                      activeColor: const Color(0xFF059669),
                      onChanged: (v) => setState(() => _adsenseEnabled = v),
                    ),
                    const Divider(height: 24),
                    _textField(
                      controller: _adsensePubIdCtrl,
                      label: 'AdSense Publisher ID',
                      hint: 'ca-pub-XXXXXXXXXXXXXXXX',
                      helperText: 'Your 16-digit publisher ID from Google AdSense account.',
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Auto Ads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Allows Google to automatically place non-intrusive ads on eligible blog posts'),
                      value: _adsenseAutoAds,
                      activeColor: const Color(0xFF059669),
                      onChanged: (v) => setState(() => _adsenseAutoAds = v),
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _adsenseCustomCodeCtrl,
                      label: 'Custom Ad Unit Snippet (Optional)',
                      hint: '<ins class="adsbygoogle" ...></ins>',
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 6: CUSTOM CODE INJECTION
  // =========================================================================
  Widget _buildCodeInjectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Custom Code Injection', 'Inject verified tracking scripts, meta tags, and third-party widgets into 4 distinct document zones.'),
              const SizedBox(height: 20),

              _codeZoneCard(
                title: 'HEAD CODE',
                subtitle: 'Scripts, custom meta tags, CSS link tags, and pre-connect hints injected inside <head>.',
                controller: _headCodeCtrl,
                enabled: _headCodeEnabled,
                onToggle: (v) => setState(() => _headCodeEnabled = v),
              ),
              const SizedBox(height: 20),

              _codeZoneCard(
                title: 'BODY START CODE',
                subtitle: 'Injected immediately after the opening <body> tag (e.g. Google Tag Manager noscript fallback).',
                controller: _bodyStartCodeCtrl,
                enabled: _bodyStartCodeEnabled,
                onToggle: (v) => setState(() => _bodyStartCodeEnabled = v),
              ),
              const SizedBox(height: 20),

              _codeZoneCard(
                title: 'BODY END CODE',
                subtitle: 'Injected just before closing </body> tag (e.g. heavy analytics, session recording pixels).',
                controller: _bodyEndCodeCtrl,
                enabled: _bodyEndCodeEnabled,
                onToggle: (v) => setState(() => _bodyEndCodeEnabled = v),
              ),
              const SizedBox(height: 20),

              _codeZoneCard(
                title: 'FOOTER CODE',
                subtitle: 'Custom JavaScript widgets, chat plugins, and footer badges.',
                controller: _footerCodeCtrl,
                enabled: _footerCodeEnabled,
                onToggle: (v) => setState(() => _footerCodeEnabled = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codeZoneCard({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return _card(
      title: title,
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusBadge(enabled ? 'Active' : 'Disabled'),
          const SizedBox(width: 8),
          Switch(
            value: enabled,
            activeColor: const Color(0xFF059669),
            onChanged: onToggle,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF38BDF8), fontSize: 13, height: 1.4),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '<!-- Paste HTML/JS code here -->',
                hintStyle: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 7: MODULAR SCRIPT MANAGEMENT
  // =========================================================================
  Widget _buildScriptsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Modular Script Management', 'Create, manage, and order standalone tracking scripts independently.'),
                  ElevatedButton.icon(
                    onPressed: () => _showAddOrEditScriptDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Script', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_customScripts.isEmpty)
                _card(
                  title: 'No Custom Scripts Configured',
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Click "Add Script" to register Meta Pixels, Hotjar, Clarity, or custom integrations.'),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _customScripts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final s = _customScripts[idx];
                    return _buildScriptRow(s);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScriptRow(SeoCustomScriptModel s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(s.placement.toUpperCase(), style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                if (s.description != null && s.description!.isNotEmpty)
                  Text(s.description!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
              ],
            ),
          ),
          Switch(
            value: s.isActive,
            activeColor: const Color(0xFF059669),
            onChanged: (val) async {
              await SupabaseService.toggleSeoCustomScript(s.id, val);
              _loadAllSeoData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5), size: 20),
            onPressed: () => _showAddOrEditScriptDialog(scriptToEdit: s),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
            onPressed: () async {
              await SupabaseService.deleteSeoCustomScript(s.id);
              _loadAllSeoData();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddOrEditScriptDialog({SeoCustomScriptModel? scriptToEdit}) async {
    final isEdit = scriptToEdit != null;
    final nameCtrl = TextEditingController(text: scriptToEdit?.name ?? '');
    final descCtrl = TextEditingController(text: scriptToEdit?.description ?? '');
    final codeCtrl = TextEditingController(text: scriptToEdit?.code ?? '');
    String placement = scriptToEdit?.placement ?? 'head';
    bool isActive = scriptToEdit?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Script' : 'Add New Script', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Script Name *', hintText: 'e.g. Meta Pixel')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', hintText: 'Purpose of this script')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: placement,
                    decoration: const InputDecoration(labelText: 'Document Placement'),
                    items: const [
                      DropdownMenuItem(value: 'head', child: Text('HEAD (<head>)')),
                      DropdownMenuItem(value: 'body_start', child: Text('BODY START (Top of <body>)')),
                      DropdownMenuItem(value: 'body_end', child: Text('BODY END (Before </body>)')),
                      DropdownMenuItem(value: 'footer', child: Text('FOOTER')),
                    ],
                    onChanged: (v) => setDialogState(() => placement = v ?? 'head'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    maxLines: 6,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: const InputDecoration(labelText: 'Raw Script Code *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
                final script = SeoCustomScriptModel(
                  id: scriptToEdit?.id ?? '',
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  code: codeCtrl.text.trim(),
                  placement: placement,
                  isActive: isActive,
                  createdAt: scriptToEdit?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await SupabaseService.saveSeoCustomScript(script);
                Navigator.pop(ctx);
                _loadAllSeoData();
              },
              child: const Text('Save Script'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 8: STRUCTURED DATA SCHEMAS (JSON-LD)
  // =========================================================================
  Widget _buildSchemaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Structured Data Schemas (JSON-LD)', 'Help Google rich snippets understand your educational courses, organization, and FAQs.'),
              const SizedBox(height: 20),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schemas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, idx) {
                  final schema = _schemas[idx];
                  return _card(
                    title: '${schema.name} (${schema.schemaType.toUpperCase()})',
                    headerAction: Switch(
                      value: schema.isActive,
                      activeColor: const Color(0xFF059669),
                      onChanged: (v) async {
                        await SupabaseService.toggleSeoSchema(schema.id, v);
                        _loadAllSeoData();
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        schema.jsonLdContent,
                        style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF38BDF8), fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 9: SITEMAP & ROBOTS.TXT
  // =========================================================================
  Widget _buildSitemapRobotsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Sitemap & Robots.txt Configuration', 'Guide search engine bots and maintain crawler directives.'),
              const SizedBox(height: 20),

              // Sitemap card
              _card(
                title: 'XML Sitemap',
                headerAction: _statusBadge(_sitemapEnabled ? 'Active' : 'Disabled'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Auto-Generated Sitemap.xml', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Provides full URL list for Google, Bing, and search crawlers'),
                      value: _sitemapEnabled,
                      activeColor: const Color(0xFF059669),
                      onChanged: (v) => setState(() => _sitemapEnabled = v),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.link_rounded, color: Color(0xFF4F46E5), size: 20),
                          SizedBox(width: 8),
                          Text('Live Sitemap Endpoint: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('https://neet-jee.in/sitemap.xml', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF4F46E5), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Robots.txt editor
              _card(
                title: 'Robots.txt Editor',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit crawler directives below. Avoid disallowing essential assets or public content.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _robotsTxtCtrl,
                        maxLines: 8,
                        style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF4ADE80), fontSize: 13),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 10: SEO HEALTH AUDITOR
  // =========================================================================
  Widget _buildSeoHealthTab() {
    final audit = _healthAudit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('SEO Health Auditor', 'Instant automated scan of meta tags, descriptions, canonical URLs, and indexability across the site.'),
                  ElevatedButton.icon(
                    onPressed: _isAuditing ? null : _runAudit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isAuditing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(_isAuditing ? 'Scanning...' : 'Run Audit Now'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (audit == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Score Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: audit.healthScore >= 80
                          ? [const Color(0xFF065F46), const Color(0xFF059669)]
                          : (audit.healthScore >= 50
                              ? [const Color(0xFF92400E), const Color(0xFFD97706)]
                              : [const Color(0xFF991B1B), const Color(0xFFDC2626)]),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            '${audit.healthScore}%',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audit.healthScore >= 80 ? 'Excellent SEO Health!' : 'Action Needed for Higher Rankings',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Audited ${audit.totalPagesChecked} pages and ${audit.totalBlogsChecked} blog articles on ${audit.auditedAt.day}/${audit.auditedAt.month}/${audit.auditedAt.year}.',
                              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Metrics Row
                Row(
                  children: [
                    _metricCard('Missing Titles', audit.missingTitlesCount.toString(), Icons.title_rounded, const Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    _metricCard('Missing Meta Desc', audit.missingDescriptionsCount.toString(), Icons.description_outlined, const Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    _metricCard('Missing Social Covers', audit.missingOgImagesCount.toString(), Icons.image_not_supported_outlined, const Color(0xFF8B5CF6)),
                    const SizedBox(width: 12),
                    _metricCard('Noindex Pages', audit.noindexPagesCount.toString(), Icons.visibility_off_outlined, const Color(0xFF6B7280)),
                  ],
                ),
                const SizedBox(height: 20),

                // Issues List
                _card(
                  title: 'Detected Warnings & Improvement Opportunities (${audit.issues.length})',
                  child: audit.issues.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('All pages have optimal meta titles and descriptions! 🎉')))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: audit.issues.length,
                          separatorBuilder: (_, __) => const Divider(height: 20),
                          itemBuilder: (ctx, idx) {
                            final issue = audit.issues[idx];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _severityIcon(issue.type),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(issue.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(issue.description, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                                      const SizedBox(height: 4),
                                      Text('Target: ${issue.pageUrl} • Tip: ${issue.suggestion}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF059669))),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _severityIcon(String type) {
    if (type == 'error') return const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20);
    if (type == 'warning') return const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20);
    return const Icon(Icons.info_outline_rounded, color: Color(0xFF4F46E5), size: 20);
  }

  // =========================================================================
  // SHARED UI HELPERS
  // =========================================================================
  Widget _buildSectionHeader(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _card({required String title, required Widget child, Widget? headerAction}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
              if (headerAction != null) headerAction,
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF15803D) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
