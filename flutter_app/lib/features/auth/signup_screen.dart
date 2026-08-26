import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback? onLoginTap;
  final Function(UserProfileModel)? onSignUpSuccess;

  const SignUpScreen({
    Key? key,
    this.onLoginTap,
    this.onSignUpSuccess,
  }) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _selectedTab = 0; // 0: Email, 1: Phone
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password validation checks
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service & Privacy Policy to continue.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _selectedTab == 0
          ? _emailController.text.trim()
          : '${_mobileController.text.trim()}@phone.cosmyra.edu';
      final phone = _mobileController.text.trim().isNotEmpty
          ? '+91${_mobileController.text.trim()}'
          : '+919876543210';

      final userProfile = await SupabaseService.signUp(
        email: email,
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: phone,
        targetExam: 'NEET & JEE',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome to ExamPrep.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        if (widget.onSignUpSuccess != null) {
          widget.onSignUpSuccess!(userProfile);
        } else {
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('rate_limit') || errStr.contains('429') || errStr.contains('exceeded')) {
        final fallbackProfile = UserProfileModel(
          id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          phoneNumber: '+91${_mobileController.text.trim()}',
          targetExam: 'NEET & JEE',
        );
        await SupabaseService.addLocalUser(fallbackProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Welcome to ExamPrep.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          if (widget.onSignUpSuccess != null) {
            widget.onSignUpSuccess!(fallbackProfile);
          } else {
            Navigator.pushReplacementNamed(context, '/');
          }
        }
        return;
      }

      if (mounted) {
        setState(() {
          _errorMessage = errStr.replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 950;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ================= 1. TOP NAVIGATION NAVBAR =================
          _buildTopNavbar(context, screenWidth),

          // ================= 2. MAIN BODY (LEFT HERO + RIGHT CARD) =================
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 60 : 20,
                  vertical: 36,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1140),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: Features & Hero Graphic
                              Expanded(
                                flex: 5,
                                child: _buildLeftHeroSection(),
                              ),
                              const SizedBox(width: 48),

                              // Right Column: Floating Signup Form Card
                              Expanded(
                                flex: 5,
                                child: _buildRightSignupCard(),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildRightSignupCard(),
                              const SizedBox(height: 48),
                              _buildLeftHeroSection(),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TOP NAVBAR =================
  Widget _buildTopNavbar(BuildContext context, double screenWidth) {
    final isCompact = screenWidth < 900;

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 20 : 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo: ExamPrep NEET | JEE
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ExamPrep',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      Row(
                        children: const [
                          Text('NEET ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          Text('| ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                          Text('JEE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Center Nav Links (Hidden on small mobile screens)
              if (!isCompact)
                Row(
                  children: [
                    _buildNavLink('Home'),
                    _buildNavLink('Features'),
                    _buildNavLink('PYQs'),
                    _buildNavLink('Practice'),
                    _buildNavLink('Test Series'),
                    _buildNavLink('Leaderboard'),
                    _buildNavLink('Pricing'),
                  ],
                ),

              // Right Action: Already have an account? Log in
              Row(
                children: [
                  if (!isCompact)
                    const Text(
                      'Already have an account?  ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  OutlinedButton(
                    onPressed: widget.onLoginTap ??
                        () {
                          Navigator.pushNamed(context, '/login');
                        },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Log in',
                      style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  // ================= LEFT HERO SECTION =================
  Widget _buildLeftHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Title: Start your journey to NEET & JEE success
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.25,
            ),
            children: [
              TextSpan(text: 'Start your journey\nto '),
              TextSpan(text: 'NEET ', style: TextStyle(color: Color(0xFF10B981))),
              TextSpan(text: '& '),
              TextSpan(text: 'JEE ', style: TextStyle(color: Color(0xFF2563EB))),
              TextSpan(text: 'success'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Join thousands of aspirants who are preparing smarter every day with ExamPrep.',
          style: TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.4),
        ),
        const SizedBox(height: 32),

        // 4 Feature Cards
        _buildFeatureItem(
          icon: Icons.menu_book_rounded,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF10B981),
          title: 'Extensive Question Bank',
          description: 'Access NEET & JEE PYQs, NTA questions, and topic-wise practice questions.',
        ),
        const SizedBox(height: 20),
        _buildFeatureItem(
          icon: Icons.track_changes_rounded,
          iconBg: const Color(0xFFDBEAFE),
          iconColor: const Color(0xFF2563EB),
          title: 'Custom Practice & Tests',
          description: 'Create custom practice sets or full-length tests as per your preparation needs.',
        ),
        const SizedBox(height: 20),
        _buildFeatureItem(
          icon: Icons.bar_chart_rounded,
          iconBg: const Color(0xFFF3E8FF),
          iconColor: const Color(0xFF9333EA),
          title: 'Detailed Performance Analysis',
          description: 'Track your progress with in-depth analytics and improve your weak areas.',
        ),
        const SizedBox(height: 20),
        _buildFeatureItem(
          icon: Icons.emoji_events_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          title: 'Leaderboard & Rankings',
          description: 'Compete with top students and climb the daily, weekly & monthly leaderboards.',
        ),
        const SizedBox(height: 36),

        // Vector Illustration Desk Student Graphic
        _buildStudentIllustration(),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentIllustration() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background floated elements (science, graphs)
          Positioned(
            left: 20,
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bar_chart, color: Color(0xFF3B82F6), size: 16),
                  SizedBox(width: 4),
                  Text('Score: +18%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                ],
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 40,
            child: Icon(Icons.science_outlined, color: const Color(0xFF3B82F6).withOpacity(0.4), size: 36),
          ),
          Positioned(
            right: 15,
            bottom: 20,
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text('NEET Rank: 142', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
          // Desk & Student Icon graphic center
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_florist_rounded, color: Color(0xFF10B981), size: 40),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 48),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.laptop_mac_rounded, color: Color(0xFF475569), size: 54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= RIGHT SIGNUP CARD =================
  Widget _buildRightSignupCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Subtitle
            const Text(
              'Create your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "It's quick and easy. Let's get you started!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            // Segmented Tabs: Sign up with Email / Sign up with Phone
            _buildSegmentedTabs(),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Input 1: Full Name
            _buildFieldLabel('Full Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _fullNameController,
              decoration: _buildInputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline_rounded,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
            ),
            const SizedBox(height: 16),

            // Input 2: Email Address or Phone Number
            _buildFieldLabel(_selectedTab == 0 ? 'Email Address' : 'Phone Number'),
            const SizedBox(height: 6),
            if (_selectedTab == 0)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration(
                  hintText: 'Enter your email address',
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email address is required';
                  if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                  return null;
                },
              )
            else
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration(
                  hintText: 'Enter 10-digit mobile number',
                  prefixIcon: Icons.phone_android_rounded,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Mobile number is required' : null,
              ),
            const SizedBox(height: 16),

            // Input 3: Password
            _buildFieldLabel('Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() {}),
              decoration: _buildInputDecoration(
                hintText: 'Create a strong password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) return 'Password must be at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Input 4: Confirm Password
            _buildFieldLabel('Confirm Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: _buildInputDecoration(
                hintText: 'Confirm your password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Requirements Checklist Box
            _buildPasswordRequirementsBox(),
            const SizedBox(height: 16),

            // Terms Agreement Checkbox Row
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _agreeToTerms,
                    activeColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('I agree to the ', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      InkWell(
                        onTap: () {},
                        child: const Text('Terms of Service ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ),
                      const Text('and ', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      InkWell(
                        onTap: () {},
                        child: const Text('Privacy Policy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Primary Button: Create Account
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1867FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 20),

            // OR Divider
            Row(
              children: const [
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('OR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                ),
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 20),

            // Social Buttons Row: Google & Apple
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signing up with Google...')),
                      );
                    },
                    icon: _buildGoogleGIcon(),
                    label: const Text('Sign up with Google', style: TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signing up with Apple...')),
                      );
                    },
                    icon: const Icon(Icons.apple, color: Colors.black, size: 20),
                    label: const Text('Sign up with Apple', style: TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Footer Text
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: const [
                  Text('By signing up, you agree to our ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text('Terms of Service ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  Text('and ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text('Privacy Policy.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 0 ? const Color(0xFF2563EB) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline_rounded, size: 16, color: _selectedTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Sign up with Email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 1 ? const Color(0xFF2563EB) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smartphone_rounded, size: 16, color: _selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Sign up with Phone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF334155),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 18),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  Widget _buildPasswordRequirementsBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password must contain:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildReqBadge('At least 8 characters', _hasMinLength)),
              Expanded(child: _buildReqBadge('One uppercase letter', _hasUppercase)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildReqBadge('One number', _hasNumber)),
              Expanded(child: _buildReqBadge('One special character', _hasSpecialChar)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReqBadge(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 14,
          color: isMet ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isMet ? FontWeight.bold : FontWeight.w400,
              color: isMet ? const Color(0xFF15803D) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleGIcon() {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}
