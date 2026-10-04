import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserProfileModel)? onAuthSuccess;
  final bool initialIsLogin;
  final VoidCallback? onBackTap;
  final AuthPageConfigModel? configOverride;

  const AuthScreen({
    Key? key,
    this.onAuthSuccess,
    this.initialIsLogin = true,
    this.onBackTap,
    this.configOverride,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late bool _isLogin;
  final _formKey = GlobalKey<FormState>();

  // Config State
  AuthPageConfigModel _config = AuthPageConfigModel.defaultConfig();
  bool _isLoadingConfig = true;

  // Login Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Signup Controllers
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Options & States
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _agreeToTerms = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  String _selectedExam = 'NEET';

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
    _isLogin = widget.initialIsLogin;
    if (widget.configOverride != null) {
      _config = widget.configOverride!;
      _isLoadingConfig = false;
    } else {
      _loadCMSConfig();
    }
    SupabaseService.authNotifier.addListener(_onAuthNotifierChanged);
  }

  @override
  void didUpdateWidget(AuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.configOverride != null) {
      setState(() {
        _config = widget.configOverride!;
        _isLoadingConfig = false;
      });
    }
  }

  Future<void> _loadCMSConfig() async {
    try {
      final loaded = await SupabaseService.fetchAuthPageConfig();
      if (mounted) {
        setState(() {
          _config = loaded;
          _isLoadingConfig = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  @override
  void dispose() {
    SupabaseService.authNotifier.removeListener(_onAuthNotifierChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onAuthNotifierChanged() {
    final profile = SupabaseService.authNotifier.value;
    if (profile != null && mounted) {
      widget.onAuthSuccess?.call(profile);
      _redirectAfterSuccess(profile);
    }
  }

  void _redirectAfterSuccess(UserProfileModel profile) {
    if (!mounted) return;
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    if (redirect != null &&
        redirect.trim().isNotEmpty &&
        redirect != '/login' &&
        redirect != '/signup' &&
        redirect != '/') {
      context.go(redirect);
    } else if (profile.isAdmin || profile.isSuperAdmin) {
      context.go('/admin');
    } else {
      context.go('/dashboard');
    }
  }

  // Password validation getters
  bool get _hasMinLength => _signupPasswordController.text.length >= 8;
  bool get _hasUppercase => _signupPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _signupPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => _signupPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProfile = await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${userProfile.fullName}!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!(userProfile);
        }
        _redirectAfterSuccess(userProfile);
      }
    } catch (e) {
      if (mounted) {
        final raw = e.toString().replaceAll('Exception:', '').trim();
        setState(() {
          _errorMessage = raw.toLowerCase().contains('invalid') || raw.toLowerCase().contains('grant')
              ? 'Email or password is incorrect. Please try again.'
              : raw.isEmpty
                  ? 'Unable to sign in. Please check your credentials.'
                  : raw;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_config.showTerms && !_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms of Service & Privacy Policy.'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _signupEmailController.text.trim();
      final phone = _mobileController.text.trim().isNotEmpty
          ? '+91${_mobileController.text.trim()}'
          : '+919876543210';

      final userProfile = await SupabaseService.signUp(
        email: email,
        password: _signupPasswordController.text,
        fullName: _fullNameController.text.trim(),
        phone: phone,
        targetExam: _selectedExam,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully! Welcome to Cosmyra NEET | JEE.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!(userProfile);
        }
        _redirectAfterSuccess(userProfile);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('rate_limit') || errStr.contains('429') || errStr.contains('exceeded')) {
        final fallbackProfile = UserProfileModel(
          id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
          email: _signupEmailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          phoneNumber: '+91${_mobileController.text.trim()}',
          targetExam: _selectedExam,
        );
        await SupabaseService.addLocalUser(fallbackProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created! Welcome to Cosmyra.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          if (widget.onAuthSuccess != null) {
            widget.onAuthSuccess!(fallbackProfile);
          }
          _redirectAfterSuccess(fallbackProfile);
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = errStr.replaceAll('Exception:', '').trim();
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      final success = await SupabaseService.signInWithGoogle();
      if (success && mounted) {
        final profile = SupabaseService.activeUserSession;
        if (profile != null) {
          widget.onAuthSuccess?.call(profile);
          _redirectAfterSuccess(profile);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Google sign-in was cancelled or could not be completed.';
        });
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showForgotPasswordModal() {
    final resetEmailController = TextEditingController(
      text: _isLogin ? _emailController.text.trim() : _signupEmailController.text.trim(),
    );
    bool isSending = false;
    String? resetError;
    bool resetSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF4F46E5), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset Password',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "We'll send a reset link to your email",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (resetSuccess) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Password reset instructions sent! Please check your email inbox.',
                              style: GoogleFonts.inter(color: const Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ] else ...[
                    if (resetError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          resetError!,
                          style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      'Email Address',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'name@example.com',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () async {
                                final email = resetEmailController.text.trim();
                                if (email.isEmpty || !email.contains('@')) {
                                  setModalState(() => resetError = 'Please enter a valid email address.');
                                  return;
                                }
                                setModalState(() {
                                  isSending = true;
                                  resetError = null;
                                });
                                try {
                                  await SupabaseService.resetPasswordForEmail(email);
                                  setModalState(() {
                                    resetSuccess = true;
                                    isSending = false;
                                  });
                                } catch (e) {
                                  setModalState(() {
                                    resetError = 'Failed to send reset link. Please check your email.';
                                    isSending = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Send Password Reset Link',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900 && _config.layout == 'AUTH_LAYOUT_SPLIT' && _config.showHeroPanel;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background ambient gradient decor
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4F46E5).withOpacity(0.12),
                    const Color(0xFF7C3AED).withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.08),
                    const Color(0xFF3B82F6).withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: isDesktop ? _buildDesktopSplitLayout(context) : _buildCenteredLayout(context),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // DESKTOP SPLIT LAYOUT
  // ----------------------------------------------------
  Widget _buildDesktopSplitLayout(BuildContext context) {
    final heroTitle = _isLogin ? _config.loginHeroTitle : _config.signupHeroTitle;
    final heroSubtitle = _isLogin ? _config.loginHeroSubtitle : _config.signupHeroSubtitle;

    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Hero Branding Panel (Flex 5)
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Color(0x3D4F46E5), blurRadius: 32, offset: Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFCD34D), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _isLogin ? _config.loginBadge : _config.signupBadge,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Text(
                    heroTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    heroSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Features Checkmarks
                  _buildDesktopFeatureItem('500+ NTA-Standard Full Length & Chapter Mock Tests'),
                  _buildDesktopFeatureItem('15-Year Solved PYQ Archives with Video Solutions'),
                  _buildDesktopFeatureItem('Real-Time AI Error Radar & AIR Percentile Analytics'),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05, end: 0),
          ),

          const SizedBox(width: 40),

          // Right Auth Form Card (Flex 5)
          Expanded(
            flex: 5,
            child: _buildFormCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // CENTERED / MOBILE LAYOUT
  // ----------------------------------------------------
  Widget _buildCenteredLayout(BuildContext context) {
    final title = _isLogin ? _config.loginTitle : _config.signupTitle;
    final subtitle = _isLogin ? _config.loginSubtitle : _config.signupSubtitle;
    final badge = _isLogin ? _config.loginBadge : _config.signupBadge;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          children: [
            // Top bar: Back Button & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: widget.onBackTap ?? () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/');
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Home',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_config.showBadge && badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          badge,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4F46E5),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            // Logo & Title Header
            Column(
              children: [
                Image.asset(
                  'assets/images/cosmyra_logo.png',
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => Text(
                    'COSMYRA',
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4F46E5),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 450.ms, delay: 100.ms).slideY(begin: -0.05, end: 0),

            const SizedBox(height: 24),

            // Form Card
            _buildFormCard(context),

            const SizedBox(height: 20),

            // Bottom Switcher
            if (_config.showSignup)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Don't have an account? " : "Already have an account? ",
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                    }),
                    child: Text(
                      _isLogin ? _config.signupButtonText : _config.signinButtonText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),

            if (_config.showFooter && _config.footerText.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                _config.footerText,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // SHARED FORM CARD WIDGET
  // ----------------------------------------------------
  Widget _buildFormCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented Control Switcher
            if (_config.showSignup) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _isLogin = true;
                          _errorMessage = null;
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isLogin
                                ? const [BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2))]
                                : [],
                          ),
                          child: Text(
                            _config.signinButtonText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: _isLogin ? FontWeight.bold : FontWeight.w500,
                              color: _isLogin ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _isLogin = false;
                          _errorMessage = null;
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isLogin
                                ? const [BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2))]
                                : [],
                          ),
                          child: Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: !_isLogin ? FontWeight.bold : FontWeight.w500,
                              color: !_isLogin ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // GOOGLE LOGIN BUTTON
            if (_config.showGoogleLogin) ...[
              InkWell(
                onTap: _isGoogleLoading || _isLoading ? null : _handleGoogleSignIn,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isGoogleLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4F46E5)),
                        )
                      else ...[
                        SvgPicture.string(_googleSvg, width: 22, height: 22),
                        const SizedBox(width: 12),
                        Text(
                          _isLogin ? _config.googleLoginButtonText : _config.googleSignupButtonText,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Divider
            if (_config.showGoogleLogin && _config.showEmailLogin) ...[
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR WITH EMAIL',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),
              const SizedBox(height: 18),
            ],

            // Error Banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Form Fields (Sign In ↔ Sign Up)
            if (_config.showEmailLogin)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _isLogin
                    ? _buildLoginFormFields()
                    : _buildSignUpFormFields(),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05, end: 0);
  }

  // ----------------------------------------------------
  // LOGIN FORM FIELDS
  // ----------------------------------------------------
  Widget _buildLoginFormFields() {
    return Column(
      key: const ValueKey('login_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('Email Address'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter your email';
            if (!val.contains('@')) return 'Enter a valid email address';
            return null;
          },
          decoration: _buildInputDecoration(
            hintText: 'name@example.com',
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),

        _buildFieldLabel('Password'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Please enter your password';
            return null;
          },
          decoration: _buildInputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Remember Me & Forgot Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _rememberMe = val ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Remember me',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                ),
              ],
            ),
            if (_config.showForgotPassword)
              GestureDetector(
                onTap: _showForgotPasswordModal,
                child: Text(
                  _config.forgotPasswordText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),

        // Submit Sign In Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              elevation: 2,
              shadowColor: const Color(0x3D4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _config.signinButtonText,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // SIGN UP FORM FIELDS
  // ----------------------------------------------------
  Widget _buildSignUpFormFields() {
    return Column(
      key: const ValueKey('signup_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('Full Name'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter your full name';
            return null;
          },
          decoration: _buildInputDecoration(
            hintText: 'e.g. Ananya Sharma',
            prefixIcon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Email Address'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter your email';
            if (!val.contains('@')) return 'Enter a valid email address';
            return null;
          },
          decoration: _buildInputDecoration(
            hintText: 'name@example.com',
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Mobile Number (Optional)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: _buildInputDecoration(
            hintText: '9876543210',
            prefixIcon: Icons.phone_outlined,
            prefixWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Text(
                '+91',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF334155), fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Target Exam'),
        const SizedBox(height: 8),
        Row(
          children: ['NEET', 'JEE', 'NEET & JEE'].map((exam) {
            final isSelected = _selectedExam == exam;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _selectedExam = exam),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      exam,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Password'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _signupPasswordController,
          obscureText: _obscurePassword,
          onChanged: (_) => setState(() {}),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Please enter a password';
            if (val.length < 8) return 'Password must be at least 8 characters';
            return null;
          },
          decoration: _buildInputDecoration(
            hintText: 'At least 8 characters',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Password Rules Badges
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildRuleBadge('8+ Chars', _hasMinLength),
            _buildRuleBadge('1 Uppercase', _hasUppercase),
            _buildRuleBadge('1 Number', _hasNumber),
            _buildRuleBadge('1 Special', _hasSpecialChar),
          ],
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Confirm Password'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Please confirm your password';
            if (val != _signupPasswordController.text) return 'Passwords do not match';
            return null;
          },
          decoration: _buildInputDecoration(
            hintText: 'Re-enter your password',
            prefixIcon: Icons.lock_clock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Terms Checkbox
        if (_config.showTerms)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreeToTerms,
                  activeColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _agreeToTerms = val ?? true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _config.termsText,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        const SizedBox(height: 22),

        // Submit Sign Up Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              elevation: 2,
              shadowColor: const Color(0x3D4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _config.signupButtonText,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
    );
  }

  Widget _buildRuleBadge(String text, bool isMet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMet ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isMet ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 12,
            color: isMet ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isMet ? const Color(0xFF065F46) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? prefixWidget,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w400),
      prefixIcon: prefixWidget ?? (prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20) : null),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.8),
      ),
    );
  }
}
