class AuthPageConfigModel {
  final String layout; // 'AUTH_LAYOUT_SPLIT', 'AUTH_LAYOUT_CENTERED', 'AUTH_LAYOUT_MINIMAL'
  final String loginTitle;
  final String loginSubtitle;
  final String loginBadge;
  final String loginHeroTitle;
  final String loginHeroSubtitle;
  final String loginHeroImage;

  final String signupTitle;
  final String signupSubtitle;
  final String signupBadge;
  final String signupHeroTitle;
  final String signupHeroSubtitle;
  final String signupHeroImage;

  final String googleButtonText;
  final String googleLoginButtonText;
  final String googleSignupButtonText;
  final String signinButtonText;
  final String signupButtonText;
  final String forgotPasswordText;
  final String termsText;
  final String footerText;

  // Visibility toggles
  final bool showGoogleLogin;
  final bool showEmailLogin;
  final bool showSignup;
  final bool showForgotPassword;
  final bool showHeroPanel;
  final bool showBadge;
  final bool showTerms;
  final bool showFooter;

  final String updatedAt;
  final String updatedBy;

  const AuthPageConfigModel({
    this.layout = 'AUTH_LAYOUT_SPLIT',
    this.loginTitle = 'Welcome Back',
    this.loginSubtitle = 'Sign in to your Cosmyra NEET | JEE account',
    this.loginBadge = 'NEET | JEE PREP',
    this.loginHeroTitle = 'Practice Smarter.\nPerform Better.',
    this.loginHeroSubtitle = 'Master NEET, JEE & competitive exams with 500+ mock tests, 15-year PYQs and real-time AI error analytics.',
    this.loginHeroImage = 'assets/images/student_study_illustration.png',

    this.signupTitle = 'Create your Cosmyra Account',
    this.signupSubtitle = 'Join 50,000+ aspirants preparing for NEET & JEE',
    this.signupBadge = 'FREE ACCESS',
    this.signupHeroTitle = 'Transform Your Exam Preparation',
    this.signupHeroSubtitle = 'Get instant access to chapter practice, NTA mock test engine, and AI error radar.',
    this.signupHeroImage = 'assets/images/student_study_illustration.png',

    this.googleButtonText = 'Login with Google',
    this.googleLoginButtonText = 'Login with Google',
    this.googleSignupButtonText = 'Signup with Google',
    this.signinButtonText = 'Log In',
    this.signupButtonText = 'Sign Up',
    this.forgotPasswordText = 'Forgot Password?',
    this.termsText = 'I agree to Cosmyra\'s Terms of Service & Privacy Policy',
    this.footerText = '© 2026 Cosmyra NEET | JEE. All rights reserved.',

    this.showGoogleLogin = true,
    this.showEmailLogin = true,
    this.showSignup = true,
    this.showForgotPassword = true,
    this.showHeroPanel = true,
    this.showBadge = true,
    this.showTerms = true,
    this.showFooter = true,

    this.updatedAt = '',
    this.updatedBy = 'Admin',
  });

  factory AuthPageConfigModel.defaultConfig() => const AuthPageConfigModel();

  Map<String, dynamic> toJson() => {
    'layout': layout,
    'login_title': loginTitle,
    'login_subtitle': loginSubtitle,
    'login_badge': loginBadge,
    'login_hero_title': loginHeroTitle,
    'login_hero_subtitle': loginHeroSubtitle,
    'login_hero_image': loginHeroImage,
    'signup_title': signupTitle,
    'signup_subtitle': signupSubtitle,
    'signup_badge': signupBadge,
    'signup_hero_title': signupHeroTitle,
    'signup_hero_subtitle': signupHeroSubtitle,
    'signup_hero_image': signupHeroImage,
    'google_button_text': googleButtonText,
    'google_login_button_text': googleLoginButtonText,
    'google_signup_button_text': googleSignupButtonText,
    'signin_button_text': signinButtonText,
    'signup_button_text': signupButtonText,
    'forgot_password_text': forgotPasswordText,
    'terms_text': termsText,
    'footer_text': footerText,
    'show_google_login': showGoogleLogin,
    'show_email_login': showEmailLogin,
    'show_signup': showSignup,
    'show_forgot_password': showForgotPassword,
    'show_hero_panel': showHeroPanel,
    'show_badge': showBadge,
    'show_terms': showTerms,
    'show_footer': showFooter,
    'updated_at': updatedAt,
    'updated_by': updatedBy,
  };

  factory AuthPageConfigModel.fromJson(Map<String, dynamic> json) {
    final defaultGoogle = json['google_button_text']?.toString();
    return AuthPageConfigModel(
      layout: json['layout']?.toString() ?? 'AUTH_LAYOUT_SPLIT',
      loginTitle: json['login_title']?.toString() ?? 'Welcome Back',
      loginSubtitle: json['login_subtitle']?.toString() ?? 'Sign in to your Cosmyra NEET | JEE account',
      loginBadge: json['login_badge']?.toString() ?? 'NEET | JEE PREP',
      loginHeroTitle: json['login_hero_title']?.toString() ?? 'Practice Smarter.\nPerform Better.',
      loginHeroSubtitle: json['login_hero_subtitle']?.toString() ?? 'Master NEET, JEE & competitive exams with 500+ mock tests, 15-year PYQs and real-time AI error analytics.',
      loginHeroImage: json['login_hero_image']?.toString() ?? 'assets/images/student_study_illustration.png',
      signupTitle: json['signup_title']?.toString() ?? 'Create your Cosmyra Account',
      signupSubtitle: json['signup_subtitle']?.toString() ?? 'Join 50,000+ aspirants preparing for NEET & JEE',
      signupBadge: json['signup_badge']?.toString() ?? 'FREE ACCESS',
      signupHeroTitle: json['signup_hero_title']?.toString() ?? 'Transform Your Exam Preparation',
      signupHeroSubtitle: json['signup_hero_subtitle']?.toString() ?? 'Get instant access to chapter practice, NTA mock test engine, and AI error radar.',
      signupHeroImage: json['signup_hero_image']?.toString() ?? 'assets/images/student_study_illustration.png',
      googleButtonText: defaultGoogle ?? 'Login with Google',
      googleLoginButtonText: json['google_login_button_text']?.toString() ?? defaultGoogle ?? 'Login with Google',
      googleSignupButtonText: json['google_signup_button_text']?.toString() ?? 'Signup with Google',
      signinButtonText: json['signin_button_text']?.toString() ?? 'Log In',
      signupButtonText: json['signup_button_text']?.toString() ?? 'Sign Up',
      forgotPasswordText: json['forgot_password_text']?.toString() ?? 'Forgot Password?',
      termsText: json['terms_text']?.toString() ?? 'I agree to Cosmyra\'s Terms of Service & Privacy Policy',
      footerText: json['footer_text']?.toString() ?? '© 2026 Cosmyra NEET | JEE. All rights reserved.',
      showGoogleLogin: json['show_google_login'] as bool? ?? true,
      showEmailLogin: json['show_email_login'] as bool? ?? true,
      showSignup: json['show_signup'] as bool? ?? true,
      showForgotPassword: json['show_forgot_password'] as bool? ?? true,
      showHeroPanel: json['show_hero_panel'] as bool? ?? true,
      showBadge: json['show_badge'] as bool? ?? true,
      showTerms: json['show_terms'] as bool? ?? true,
      showFooter: json['show_footer'] as bool? ?? true,
      updatedAt: json['updated_at']?.toString() ?? '',
      updatedBy: json['updated_by']?.toString() ?? 'Admin',
    );
  }
}
