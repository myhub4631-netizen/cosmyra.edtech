import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/models.dart';
import '../../auth/auth_screen.dart';

class AdminAuthManagerScreen extends StatefulWidget {
  const AdminAuthManagerScreen({Key? key}) : super(key: key);

  @override
  State<AdminAuthManagerScreen> createState() => _AdminAuthManagerScreenState();
}

class _AdminAuthManagerScreenState extends State<AdminAuthManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  AuthPageConfigModel _config = AuthPageConfigModel.defaultConfig();
  String _previewDevice = 'Desktop'; // 'Desktop', 'Tablet', 'Mobile'
  bool _previewIsLogin = true;

  // Login Controllers
  final _loginTitleCtrl = TextEditingController();
  final _loginSubtitleCtrl = TextEditingController();
  final _loginBadgeCtrl = TextEditingController();
  final _loginHeroTitleCtrl = TextEditingController();
  final _loginHeroSubtitleCtrl = TextEditingController();
  final _loginHeroImageCtrl = TextEditingController();

  // Signup Controllers
  final _signupTitleCtrl = TextEditingController();
  final _signupSubtitleCtrl = TextEditingController();
  final _signupBadgeCtrl = TextEditingController();
  final _signupHeroTitleCtrl = TextEditingController();
  final _signupHeroSubtitleCtrl = TextEditingController();
  final _signupHeroImageCtrl = TextEditingController();

  // Shared Controllers
  final _googleButtonCtrl = TextEditingController();
  final _signinButtonCtrl = TextEditingController();
  final _signupButtonCtrl = TextEditingController();
  final _forgotPasswordCtrl = TextEditingController();
  final _termsTextCtrl = TextEditingController();
  final _footerTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginTitleCtrl.dispose();
    _loginSubtitleCtrl.dispose();
    _loginBadgeCtrl.dispose();
    _loginHeroTitleCtrl.dispose();
    _loginHeroSubtitleCtrl.dispose();
    _loginHeroImageCtrl.dispose();
    _signupTitleCtrl.dispose();
    _signupSubtitleCtrl.dispose();
    _signupBadgeCtrl.dispose();
    _signupHeroTitleCtrl.dispose();
    _signupHeroSubtitleCtrl.dispose();
    _signupHeroImageCtrl.dispose();
    _googleButtonCtrl.dispose();
    _signinButtonCtrl.dispose();
    _signupButtonCtrl.dispose();
    _forgotPasswordCtrl.dispose();
    _termsTextCtrl.dispose();
    _footerTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final loaded = await SupabaseService.fetchAuthPageConfig();
    if (mounted) {
      setState(() {
        _config = loaded;
        _populateControllers(loaded);
        _isLoading = false;
      });
    }
  }

  void _populateControllers(AuthPageConfigModel cfg) {
    _loginTitleCtrl.text = cfg.loginTitle;
    _loginSubtitleCtrl.text = cfg.loginSubtitle;
    _loginBadgeCtrl.text = cfg.loginBadge;
    _loginHeroTitleCtrl.text = cfg.loginHeroTitle;
    _loginHeroSubtitleCtrl.text = cfg.loginHeroSubtitle;
    _loginHeroImageCtrl.text = cfg.loginHeroImage;

    _signupTitleCtrl.text = cfg.signupTitle;
    _signupSubtitleCtrl.text = cfg.signupSubtitle;
    _signupBadgeCtrl.text = cfg.signupBadge;
    _signupHeroTitleCtrl.text = cfg.signupHeroTitle;
    _signupHeroSubtitleCtrl.text = cfg.signupHeroSubtitle;
    _signupHeroImageCtrl.text = cfg.signupHeroImage;

    _googleButtonCtrl.text = cfg.googleButtonText;
    _signinButtonCtrl.text = cfg.signinButtonText;
    _signupButtonCtrl.text = cfg.signupButtonText;
    _forgotPasswordCtrl.text = cfg.forgotPasswordText;
    _termsTextCtrl.text = cfg.termsText;
    _footerTextCtrl.text = cfg.footerText;
  }

  AuthPageConfigModel _buildUpdatedConfigFromInputs() {
    return AuthPageConfigModel(
      layout: _config.layout,
      loginTitle: _loginTitleCtrl.text.trim(),
      loginSubtitle: _loginSubtitleCtrl.text.trim(),
      loginBadge: _loginBadgeCtrl.text.trim(),
      loginHeroTitle: _loginHeroTitleCtrl.text.trim(),
      loginHeroSubtitle: _loginHeroSubtitleCtrl.text.trim(),
      loginHeroImage: _loginHeroImageCtrl.text.trim(),

      signupTitle: _signupTitleCtrl.text.trim(),
      signupSubtitle: _signupSubtitleCtrl.text.trim(),
      signupBadge: _signupBadgeCtrl.text.trim(),
      signupHeroTitle: _signupHeroTitleCtrl.text.trim(),
      signupHeroSubtitle: _signupHeroSubtitleCtrl.text.trim(),
      signupHeroImage: _signupHeroImageCtrl.text.trim(),

      googleButtonText: _googleButtonCtrl.text.trim(),
      signinButtonText: _signinButtonCtrl.text.trim(),
      signupButtonText: _signupButtonCtrl.text.trim(),
      forgotPasswordText: _forgotPasswordCtrl.text.trim(),
      termsText: _termsTextCtrl.text.trim(),
      footerText: _footerTextCtrl.text.trim(),

      showGoogleLogin: _config.showGoogleLogin,
      showEmailLogin: _config.showEmailLogin,
      showSignup: _config.showSignup,
      showForgotPassword: _config.showForgotPassword,
      showHeroPanel: _config.showHeroPanel,
      showBadge: _config.showBadge,
      showTerms: _config.showTerms,
      showFooter: _config.showFooter,

      updatedAt: DateTime.now().toIso8601String(),
      updatedBy: 'Super Admin',
    );
  }

  Future<void> _saveConfig() async {
    // Safety enforcement: At least one auth method must remain enabled
    if (!_config.showGoogleLogin && !_config.showEmailLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safety Check: At least one login method (Google or Email) must remain enabled.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final updatedConfig = _buildUpdatedConfigFromInputs();
    final success = await SupabaseService.saveAuthPageConfig(updatedConfig);

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) _config = updatedConfig;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Auth Experience CMS published! Changes live across Web, Web App & Mobile.'
              : 'Failed to publish Auth CMS settings.'),
          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF4F46E5), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Login & Signup CMS Manager',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Manage content, layout, branding & visibility across all platforms',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveConfig,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.publish_rounded, size: 18),
              label: Text(_isSaving ? 'Publishing...' : 'Publish Changes', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Login Content'),
            Tab(text: 'Signup Content'),
            Tab(text: 'Layout & Visibility'),
            Tab(text: 'Live Multi-Device Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginContentTab(),
          _buildSignupContentTab(),
          _buildLayoutVisibilityTab(),
          _buildLivePreviewTab(),
        ],
      ),
    );
  }

  // TAB 1: LOGIN CONTENT
  Widget _buildLoginContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Login Page Text & Headlines', 'Customize page titles, hero text, and subtitle messages.'),
            const SizedBox(height: 16),
            _buildTextField('Login Page Title', _loginTitleCtrl, 'e.g. Welcome to Cosmyra'),
            _buildTextField('Login Page Subtitle', _loginSubtitleCtrl, 'e.g. Your smarter way to prepare for NEET & JEE'),
            _buildTextField('Badge Text', _loginBadgeCtrl, 'e.g. NEET | JEE PREP'),
            const SizedBox(height: 24),
            _buildSectionHeader('Desktop Left Hero Panel (Marketing Panel)', 'Text displayed on the left side of desktop split-screen view.'),
            const SizedBox(height: 16),
            _buildTextField('Hero Title', _loginHeroTitleCtrl, 'e.g. Practice Smarter. Perform Better.', maxLines: 2),
            _buildTextField('Hero Subtitle', _loginHeroSubtitleCtrl, 'e.g. Master NEET & JEE with 500+ mock tests...', maxLines: 3),
            _buildTextField('Hero Image Asset / URL', _loginHeroImageCtrl, 'assets/images/student_study_illustration.png'),
          ],
        ),
      ),
    );
  }

  // TAB 2: SIGNUP CONTENT
  Widget _buildSignupContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Signup Page Text & Headlines', 'Customize registration title, badges, and terms text.'),
            const SizedBox(height: 16),
            _buildTextField('Signup Page Title', _signupTitleCtrl, 'e.g. Create Your Account'),
            _buildTextField('Signup Page Subtitle', _signupSubtitleCtrl, 'e.g. Join 50,000+ aspirants scoring top ranks with AI'),
            _buildTextField('Badge Text', _signupBadgeCtrl, 'e.g. FREE ACCESS'),
            const SizedBox(height: 24),
            _buildSectionHeader('Desktop Left Hero Panel (Signup Variant)', 'Text displayed on desktop split screen for signup.'),
            const SizedBox(height: 16),
            _buildTextField('Signup Hero Title', _signupHeroTitleCtrl, 'e.g. Transform Your Exam Preparation', maxLines: 2),
            _buildTextField('Signup Hero Subtitle', _signupHeroSubtitleCtrl, 'e.g. Get instant access to chapter practice, NTA mock test engine...', maxLines: 3),
            _buildTextField('Signup Hero Image Asset / URL', _signupHeroImageCtrl, 'assets/images/student_study_illustration.png'),
          ],
        ),
      ),
    );
  }

  // TAB 3: LAYOUT & VISIBILITY TOGGLES
  Widget _buildLayoutVisibilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Layout Template Preset', 'Choose how authentication page renders on Desktop & Mobile.'),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildLayoutChoiceCard('AUTH_LAYOUT_SPLIT', 'Split Screen (Recommended)', 'Left hero branding panel + Right auth card', Icons.vertical_split_rounded),
                const SizedBox(width: 12),
                _buildLayoutChoiceCard('AUTH_LAYOUT_CENTERED', 'Centered Card', 'Clean centered authentication box', Icons.crop_square_rounded),
                const SizedBox(width: 12),
                _buildLayoutChoiceCard('AUTH_LAYOUT_MINIMAL', 'Minimal Compact', 'Simplified minimal card layout', Icons.splitscreen_rounded),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Button Labels & Footer Text', 'Configure button copy and legal statements.'),
            const SizedBox(height: 16),
            _buildTextField('Google Button Text', _googleButtonCtrl, 'Continue with Google'),
            _buildTextField('Sign In Button Text', _signinButtonCtrl, 'Sign In'),
            _buildTextField('Signup Button Text', _signupButtonCtrl, 'Create Free Account'),
            _buildTextField('Forgot Password Link Text', _forgotPasswordCtrl, 'Forgot Password?'),
            _buildTextField('Terms & Privacy Text', _termsTextCtrl, 'I agree to Cosmyra\'s Terms of Service & Privacy Policy'),
            _buildTextField('Footer Legal Statement', _footerTextCtrl, '© 2026 Cosmyra NEET | JEE. All rights reserved.'),

            const SizedBox(height: 32),
            _buildSectionHeader('Section Visibility Toggles', 'Enable or disable optional Auth elements with safety guards.'),
            const SizedBox(height: 16),

            _buildSwitchTile('Google Login CTA', 'Show "Continue with Google" button', _config.showGoogleLogin, (val) {
              setState(() => _config = _config.copyWith(showGoogleLogin: val));
            }),
            _buildSwitchTile('Email Login Form', 'Show email & password input fields', _config.showEmailLogin, (val) {
              setState(() => _config = _config.copyWith(showEmailLogin: val));
            }),
            _buildSwitchTile('Sign Up Switcher', 'Allow users to toggle between Login & Signup', _config.showSignup, (val) {
              setState(() => _config = _config.copyWith(showSignup: val));
            }),
            _buildSwitchTile('Forgot Password Link', 'Show password recovery trigger', _config.showForgotPassword, (val) {
              setState(() => _config = _config.copyWith(showForgotPassword: val));
            }),
            _buildSwitchTile('Hero Panel', 'Show left marketing panel on desktop', _config.showHeroPanel, (val) {
              setState(() => _config = _config.copyWith(showHeroPanel: val));
            }),
            _buildSwitchTile('Top Pill Badge', 'Show "NEET | JEE PREP" star pill badge', _config.showBadge, (val) {
              setState(() => _config = _config.copyWith(showBadge: val));
            }),
            _buildSwitchTile('Terms Checkbox', 'Show terms agreement checkbox on Signup', _config.showTerms, (val) {
              setState(() => _config = _config.copyWith(showTerms: val));
            }),
            _buildSwitchTile('Footer Copyright Bar', 'Show footer copyright text', _config.showFooter, (val) {
              setState(() => _config = _config.copyWith(showFooter: val));
            }),
          ],
        ),
      ),
    );
  }

  // TAB 4: LIVE PREVIEW
  Widget _buildLivePreviewTab() {
    final previewConfig = _buildUpdatedConfigFromInputs();

    double width;
    if (_previewDevice == 'Mobile') {
      width = 380;
    } else if (_previewDevice == 'Tablet') {
      width = 680;
    } else {
      width = 1100;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Preview Device: ', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Desktop', label: Text('Desktop (1100px)'), icon: Icon(Icons.desktop_windows_rounded, size: 16)),
                      ButtonSegment(value: 'Tablet', label: Text('Tablet (680px)'), icon: Icon(Icons.tablet_mac_rounded, size: 16)),
                      ButtonSegment(value: 'Mobile', label: Text('Mobile (380px)'), icon: Icon(Icons.phone_iphone_rounded, size: 16)),
                    ],
                    selected: {_previewDevice},
                    onSelectionChanged: (set) => setState(() => _previewDevice = set.first),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Mode: ', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sign In'),
                    selected: _previewIsLogin,
                    onSelected: (val) => setState(() => _previewIsLogin = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Create Account'),
                    selected: !_previewIsLogin,
                    onSelected: (val) => setState(() => _previewIsLogin = false),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: width,
                height: 700,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8))],
                ),
                clipBehavior: Clip.antiAlias,
                child: AuthScreen(
                  initialIsLogin: _previewIsLogin,
                  configOverride: previewConfig,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutChoiceCard(String key, String title, String subtitle, IconData icon) {
    final isSelected = _config.layout == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _config = _config.copyWith(layout: key)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B), size: 24),
              const SizedBox(height: 10),
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF4F46E5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

extension AuthPageConfigModelCopyWith on AuthPageConfigModel {
  AuthPageConfigModel copyWith({
    String? layout,
    String? loginTitle,
    String? loginSubtitle,
    String? loginBadge,
    String? loginHeroTitle,
    String? loginHeroSubtitle,
    String? loginHeroImage,
    String? signupTitle,
    String? signupSubtitle,
    String? signupBadge,
    String? signupHeroTitle,
    String? signupHeroSubtitle,
    String? signupHeroImage,
    String? googleButtonText,
    String? signinButtonText,
    String? signupButtonText,
    String? forgotPasswordText,
    String? termsText,
    String? footerText,
    bool? showGoogleLogin,
    bool? showEmailLogin,
    bool? showSignup,
    bool? showForgotPassword,
    bool? showHeroPanel,
    bool? showBadge,
    bool? showTerms,
    bool? showFooter,
    String? updatedAt,
    String? updatedBy,
  }) {
    return AuthPageConfigModel(
      layout: layout ?? this.layout,
      loginTitle: loginTitle ?? this.loginTitle,
      loginSubtitle: loginSubtitle ?? this.loginSubtitle,
      loginBadge: loginBadge ?? this.loginBadge,
      loginHeroTitle: loginHeroTitle ?? this.loginHeroTitle,
      loginHeroSubtitle: loginHeroSubtitle ?? this.loginHeroSubtitle,
      loginHeroImage: loginHeroImage ?? this.loginHeroImage,
      signupTitle: signupTitle ?? this.signupTitle,
      signupSubtitle: signupSubtitle ?? this.signupSubtitle,
      signupBadge: signupBadge ?? this.signupBadge,
      signupHeroTitle: signupHeroTitle ?? this.signupHeroTitle,
      signupHeroSubtitle: signupHeroSubtitle ?? this.signupHeroSubtitle,
      signupHeroImage: signupHeroImage ?? this.signupHeroImage,
      googleButtonText: googleButtonText ?? this.googleButtonText,
      signinButtonText: signinButtonText ?? this.signinButtonText,
      signupButtonText: signupButtonText ?? this.signupButtonText,
      forgotPasswordText: forgotPasswordText ?? this.forgotPasswordText,
      termsText: termsText ?? this.termsText,
      footerText: footerText ?? this.footerText,
      showGoogleLogin: showGoogleLogin ?? this.showGoogleLogin,
      showEmailLogin: showEmailLogin ?? this.showEmailLogin,
      showSignup: showSignup ?? this.showSignup,
      showForgotPassword: showForgotPassword ?? this.showForgotPassword,
      showHeroPanel: showHeroPanel ?? this.showHeroPanel,
      showBadge: showBadge ?? this.showBadge,
      showTerms: showTerms ?? this.showTerms,
      showFooter: showFooter ?? this.showFooter,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
