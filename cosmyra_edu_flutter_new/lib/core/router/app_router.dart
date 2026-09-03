import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../../models/models.dart';
import '../../models/pyq_models.dart';
import '../../shared/widgets/not_found_screen.dart';
import '../../features/landing/landing_page_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/dashboard/user_dashboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/pyq_nta/pyq_nta_screen.dart';
import '../../features/pyq_nta/pyq_practice_screen.dart';
import '../../features/pyq_nta/pyq_result_screen.dart';
import '../../features/pyq_nta/nta_practice_test_screen.dart';
import '../../features/pyq_nta/nta_chapter_topic_wise_screen.dart';
import '../../features/pyq_nta/nta_paper_wise_screen.dart';
import '../../features/mistakes_bookmarks/mistakes_bookmarks_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/student/test_series_screen.dart';
import '../../features/tests/mock_tests_screen.dart';
import '../../features/tests/test_screen.dart';
import '../../features/tests/test_result_screen.dart';
import '../../features/tests/my_tests_history_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/practice/custom_practice_wizard.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/admin_user_management_screen.dart';
import '../../features/admin/admin_chapters_topics_screen.dart';
import '../../features/admin/admin_questions_bank_dashboard.dart';
import '../../features/admin/admin_bulk_upload_step1_screen.dart';
import '../../features/admin/admin_bulk_upload_step2_screen.dart';
import '../../features/admin/admin_pricing_screen.dart';
import '../../features/admin/admin_hierarchy_screen.dart';
import '../../features/admin/admin_leaderboard_screen.dart';
import '../../features/admin/admin_predictions_screen.dart';
import '../../features/admin/admin_question_builder_screen.dart';
import '../../features/admin/admin_pdf_import_screen.dart';
import '../../features/admin/admin_banner_manager_screen.dart';
import '../../features/legal/privacy_policy_screen.dart';
import '../../features/admin/admin_privacy_policy_manager_screen.dart';
import '../../features/legal/terms_of_service_screen.dart';
import '../../features/admin/admin_terms_manager_screen.dart';
import '../../features/admin/cms/admin_page_manager_screen.dart';
import '../../features/admin/cms/admin_page_editor_screen.dart';
import '../../features/admin/cms/admin_blog_manager_screen.dart';
import '../../features/admin/cms/admin_blog_editor_screen.dart';
import '../../features/admin/cms/admin_navigation_manager_screen.dart';
import '../../features/admin/seo/admin_seo_screen.dart';
import '../../features/admin/admin_test_series_manager_screen.dart';
import '../../features/cms/dynamic_page_screen.dart';
import '../../features/blog/blog_list_screen.dart';
import '../../features/blog/blog_post_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

List<QuestionModel>? _activeTestQuestions;
int _activeTestTimerMinutes = 30;
TestAttemptModel? _lastTestAttempt;
Map<int, String>? _lastTestUserAnswers;
List<QuestionModel>? _lastTestQuestions;
String? _activePracticeSessionId;
bool _isNewPracticeSession = false;
String? _activeTestSessionId;
bool _isNewTestSession = false;

UserProfileModel _getEffectiveProfile() {
  if (SupabaseService.activeUserSession != null) {
    return SupabaseService.activeUserSession!;
  }
  return SupabaseService.getMockProfile(role: 'student');
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => NotFoundScreen(path: state.uri.toString()),
  routes: [
    // =========================================================================
    // PUBLIC & AUTHENTICATION ROUTES
    // =========================================================================
    GoRoute(
      path: '/',
      builder: (context, state) => LandingPageScreen(
        onStartPracticing: () => context.go('/practice'),
        onExploreTests: () => context.go('/mock-tests'),
        onSignUp: () => context.go('/signup'),
        onLogIn: () => context.go('/login'),
      ),
    ),
    GoRoute(
      path: '/landing',
      builder: (context, state) => LandingPageScreen(
        onStartPracticing: () => context.go('/practice'),
        onExploreTests: () => context.go('/mock-tests'),
        onSignUp: () => context.go('/signup'),
        onLogIn: () => context.go('/login'),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/terms-of-service',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/pages/:slug',
      builder: (context, state) => DynamicPageScreen(
        slug: state.pathParameters['slug'] ?? '',
      ),
    ),
    GoRoute(
      path: '/about-us',
      builder: (context, state) => const DynamicPageScreen(slug: 'about-us'),
    ),
    GoRoute(
      path: '/contact-us',
      builder: (context, state) => const DynamicPageScreen(slug: 'contact-us'),
    ),
    GoRoute(
      path: '/disclaimer',
      builder: (context, state) => const DynamicPageScreen(slug: 'disclaimer'),
    ),
    GoRoute(
      path: '/refund-policy',
      builder: (context, state) => const DynamicPageScreen(slug: 'refund-policy'),
    ),
    GoRoute(
      path: '/shipping-policy',
      builder: (context, state) => const DynamicPageScreen(slug: 'shipping-policy'),
    ),
    GoRoute(
      path: '/cookie-policy',
      builder: (context, state) => const DynamicPageScreen(slug: 'cookie-policy'),
    ),
    GoRoute(
      path: '/faq',
      builder: (context, state) => const DynamicPageScreen(slug: 'faq'),
    ),
    GoRoute(
      path: '/careers',
      builder: (context, state) => const DynamicPageScreen(slug: 'careers'),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const DynamicPageScreen(slug: 'help'),
    ),
    GoRoute(
      path: '/blog',
      builder: (context, state) => const BlogListScreen(),
    ),
    GoRoute(
      path: '/blog/:slug',
      builder: (context, state) => BlogPostScreen(
        slug: state.pathParameters['slug'] ?? '',
      ),
    ),

    // =========================================================================
    // STUDENT / USER ROUTES
    // =========================================================================
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => UserDashboardScreen(
        userProfile: _getEffectiveProfile(),
        activeExam: 'NEET',
        onOpenPractice: () => context.go('/practice'),
        onOpenCustomTest: () => context.go('/my-tests'),
        onOpenMockTests: () => context.go('/my-tests'),
        onOpenMyTests: () => context.go('/my-tests'),
        onOpenTestSeries: () => context.go('/test-series'),
        onOpenPyqs: () => context.go('/pyq'),
        onOpenMistakes: () => context.go('/mistakes'),
        onLogout: () => context.go('/login'),
      ),
    ),
    GoRoute(
      path: '/user/dashboard',
      builder: (context, state) => UserDashboardScreen(
        userProfile: _getEffectiveProfile(),
        activeExam: 'NEET',
        onOpenPractice: () => context.go('/practice'),
        onOpenCustomTest: () => context.go('/my-tests'),
        onOpenMockTests: () => context.go('/my-tests'),
        onOpenMyTests: () => context.go('/my-tests'),
        onOpenTestSeries: () => context.go('/test-series'),
        onOpenPyqs: () => context.go('/pyq'),
        onOpenMistakes: () => context.go('/mistakes'),
        onLogout: () => context.go('/login'),
      ),
    ),
    GoRoute(
      path: '/my-tests',
      builder: (context, state) => MyTestsHistoryScreen(
        userProfile: _getEffectiveProfile(),
        onBack: () => context.go('/dashboard'),
        onNavigateTab: (idx) {},
      ),
    ),
    GoRoute(
      path: '/tests',
      builder: (context, state) => MyTestsHistoryScreen(
        userProfile: _getEffectiveProfile(),
        onBack: () => context.go('/dashboard'),
        onNavigateTab: (idx) {},
      ),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => MyTestsHistoryScreen(
        userProfile: _getEffectiveProfile(),
        onBack: () => context.go('/dashboard'),
        onNavigateTab: (idx) {},
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(
        userProfile: _getEffectiveProfile(),
        activeExam: 'NEET',
        onExamChanged: (newExam) {},
        onSignOut: () => context.go('/login'),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => ProfileScreen(
        userProfile: _getEffectiveProfile(),
        activeExam: 'NEET',
        onExamChanged: (newExam) {},
        onSignOut: () => context.go('/login'),
      ),
    ),
    GoRoute(
      path: '/courses',
      builder: (context, state) => TestSeriesScreen(
        onBackToDashboard: () => context.go('/dashboard'),
        onNavigateTab: (idx) {},
      ),
    ),
    GoRoute(
      path: '/courses/:courseId',
      builder: (context, state) => TestSeriesScreen(
        onBackToDashboard: () => context.go('/dashboard'),
        onNavigateTab: (idx) {},
      ),
    ),
    GoRoute(
      path: '/exams',
      builder: (context, state) => PyqNtaScreen(
        activeExam: state.uri.queryParameters['exam'] ?? 'NEET',
      ),
    ),
    GoRoute(
      path: '/exams/:examId',
      builder: (context, state) => PyqNtaScreen(
        activeExam: state.pathParameters['examId'] ?? 'NEET',
      ),
    ),
    GoRoute(
      path: '/mock-tests',
      builder: (context, state) => MyTestsHistoryScreen(
        userProfile: _getEffectiveProfile(),
        onBack: () => context.go('/dashboard'),
        onNavigateTab: (idx) {},
      ),
    ),
    GoRoute(
      path: '/mock-tests/:testId',
      builder: (context, state) => TestSeriesScreen(
        onBackToDashboard: () => context.go('/dashboard'),
        onNavigateTab: (idx) {},
      ),
    ),
    GoRoute(
      path: '/test-series',
      builder: (context, state) => TestSeriesScreen(
        onBackToDashboard: () => context.go('/dashboard'),
        onNavigateTab: (idx) {},
      ),
    ),
    GoRoute(
      path: '/test/:testId/start',
      builder: (context, state) {
        final String testId = state.pathParameters['testId'] ?? 'test_1';
        return CustomTestScreen(
          questions: SupabaseService.getSampleQuestions(20),
          durationMinutes: 30,
          onTestSubmitted: (attempt, answers) {
            context.go('/test/$testId/result');
          },
        );
      },
    ),
    GoRoute(
      path: '/test/:testId/result',
      builder: (context, state) => TestResultScreen(
        attempt: TestAttemptModel(
          id: 'attempt_1',
          userId: 'student_1',
          testTemplateId: 'template_1',
          testTitle: 'NEET Full Length Test 1',
          startedAt: DateTime.now().subtract(const Duration(hours: 3)),
          expiresAt: DateTime.now(),
          submittedAt: DateTime.now(),
          status: 'submitted',
          totalScore: 680,
          maxMarks: 720,
          totalQuestions: 180,
          attemptedCount: 170,
          correctCount: 165,
          incorrectCount: 5,
          unattemptedCount: 10,
          accuracy: 94.4,
          timeSpentSeconds: 9600,
        ),
        questions: SupabaseService.getSampleQuestions(20),
        userAnswers: const {0: 'A', 1: 'B', 2: 'C'},
        onBackToDashboard: () => context.go('/dashboard'),
      ),
    ),
    // Custom Practice & Custom Test Routes
    GoRoute(
      path: '/custom-practice',
      builder: (context, state) => CustomPracticeWizardModal(
        initialExam: state.uri.queryParameters['exam'] ?? 'NEET',
        mode: PracticeTestMode.practice,
        onClose: () => context.go('/dashboard'),
        onStartPractice: (questions, timerMins) {
          _activeTestQuestions = questions;
          _activeTestTimerMinutes = timerMins;
          final newSessionId = 'session_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
          _activePracticeSessionId = newSessionId;
          _isNewPracticeSession = true;
          context.go('/practice/session');
        },
      ),
    ),
    GoRoute(
      path: '/custom-test',
      builder: (context, state) => CustomPracticeWizardModal(
        initialExam: state.uri.queryParameters['exam'] ?? 'NEET',
        mode: PracticeTestMode.test,
        onClose: () => context.go('/dashboard'),
        onStartPractice: (questions, timerMins) {
          _activeTestQuestions = questions;
          _activeTestTimerMinutes = timerMins;
          final String attemptId = 'attempt_${DateTime.now().microsecondsSinceEpoch}';
          _activeTestSessionId = attemptId;
          _isNewTestSession = true;
          context.go('/custom-test/attempt/$attemptId');
        },
      ),
    ),
    GoRoute(
      path: '/custom-test/attempt/:attemptId',
      builder: (context, state) {
        final attemptId = state.pathParameters['attemptId'] ?? _activeTestSessionId ?? 'attempt_${DateTime.now().microsecondsSinceEpoch}';
        final questions = _activeTestQuestions ?? SupabaseService.getSampleQuestions(20);
        final bool isNew = _isNewTestSession;
        _isNewTestSession = false;
        return CustomTestScreen(
          sessionId: attemptId,
          isNewSession: isNew,
          questions: questions,
          durationMinutes: _activeTestTimerMinutes > 0 ? _activeTestTimerMinutes : 30,
          onTestSubmitted: (attempt, answers) {
            _lastTestAttempt = attempt;
            _lastTestUserAnswers = answers;
            _lastTestQuestions = List<QuestionModel>.from(questions);
            _activeTestQuestions = null;
            context.go('/custom-test/result/$attemptId');
          },
        );
      },
    ),
    GoRoute(
      path: '/custom-test/result/:attemptId',
      builder: (context, state) {
        final attempt = _lastTestAttempt ??
            TestAttemptModel(
              id: state.pathParameters['attemptId'] ?? 'attempt_1',
              userId: 'student_1',
              testTemplateId: 'template_1',
              testTitle: 'Custom Test Score Report',
              startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
              expiresAt: DateTime.now(),
              submittedAt: DateTime.now(),
              status: 'submitted',
              totalScore: 140,
              maxMarks: 160,
              totalQuestions: 40,
              attemptedCount: 38,
              correctCount: 35,
              incorrectCount: 3,
              unattemptedCount: 2,
              accuracy: 92.1,
              timeSpentSeconds: 1800,
            );
        final questions = _lastTestQuestions ?? SupabaseService.getSampleQuestions(20);
        final userAnswers = _lastTestUserAnswers ?? const {0: 'A', 1: 'B', 2: 'C'};

        return Scaffold(
          body: TestResultScreen(
            attempt: attempt,
            questions: questions,
            userAnswers: userAnswers,
            onBackToDashboard: () => context.go('/dashboard'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/practice',
      builder: (context, state) => CustomPracticeWizardModal(
        initialExam: state.uri.queryParameters['exam'] ?? 'NEET',
        mode: PracticeTestMode.practice,
        onClose: () => context.go('/dashboard'),
        onStartPractice: (questions, timerMins) {
          _activeTestQuestions = questions;
          _activeTestTimerMinutes = timerMins;
          final newSessionId = 'session_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
          _activePracticeSessionId = newSessionId;
          _isNewPracticeSession = true;
          context.go('/practice/session');
        },
      ),
    ),
    GoRoute(
      path: '/practice/:subject',
      builder: (context, state) {
        final questions = _activeTestQuestions ?? SupabaseService.getSampleQuestions(20);
        final String currentSessionId = _activePracticeSessionId ?? 'session_${DateTime.now().microsecondsSinceEpoch}';
        final bool isNew = _isNewPracticeSession;
        _isNewPracticeSession = false;
        return PracticeScreen(
          sessionId: currentSessionId,
          isNewSession: isNew,
          questions: questions,
          timerMinutes: _activeTestTimerMinutes,
          onFinish: () => context.go('/dashboard'),
        );
      },
    ),
    // =========================================================================
    // PYQ PRACTICE ROUTES (/pyq/...)
    // =========================================================================
    GoRoute(
      path: '/pyq',
      builder: (context, state) => PYQPracticeScreen(
        activeExam: state.uri.queryParameters['exam'] ?? 'NEET',
        onStartPYQSession: (questions, timerMins, isTestMode) {
          _activeTestQuestions = questions;
          _activeTestTimerMinutes = timerMins;
          final attemptId = 'pyq_${DateTime.now().microsecondsSinceEpoch}';
          _activePracticeSessionId = attemptId;
          _isNewPracticeSession = true;
          _activeTestSessionId = attemptId;
          _isNewTestSession = true;
          if (isTestMode) {
            context.go('/pyq/test');
          } else {
            context.go('/pyq/practice');
          }
        },
        onBack: () => context.go('/dashboard'),
      ),
    ),
    GoRoute(
      path: '/pyq/practice',
      builder: (context, state) {
        final questions = _activeTestQuestions ?? SupabaseService.getSampleQuestions(20);
        final String currentSessionId = _activePracticeSessionId ?? 'pyq_${DateTime.now().microsecondsSinceEpoch}';
        final bool isNew = _isNewPracticeSession;
        _isNewPracticeSession = false;
        return PracticeScreen(
          sessionId: currentSessionId,
          isNewSession: isNew,
          questions: questions,
          timerMinutes: 0,
          onFinish: () => context.go('/pyq'),
        );
      },
    ),
    GoRoute(
      path: '/pyq/test',
      builder: (context, state) {
        final questions = _activeTestQuestions ?? SupabaseService.getSampleQuestions(20);
        final attemptId = _activeTestSessionId ?? 'pyq_${DateTime.now().microsecondsSinceEpoch}';
        final bool isNew = _isNewTestSession;
        _isNewTestSession = false;
        return CustomTestScreen(
          sessionId: attemptId,
          isNewSession: isNew,
          questions: questions,
          durationMinutes: _activeTestTimerMinutes > 0 ? _activeTestTimerMinutes : 30,
          onTestSubmitted: (attempt, answers) {
            _lastTestAttempt = attempt;
            _lastTestUserAnswers = answers;
            _lastTestQuestions = List<QuestionModel>.from(questions);
            context.go('/pyq/result/$attemptId');
          },
        );
      },
    ),
    GoRoute(
      path: '/pyq/papers',
      builder: (context, state) => PYQPracticeScreen(
        activeExam: state.uri.queryParameters['exam'] ?? 'NEET',
        onBack: () => context.go('/dashboard'),
      ),
    ),
    GoRoute(
      path: '/pyq/result/:attemptId',
      builder: (context, state) {
        final pyqResult = PYQSessionResultModel(
          id: state.pathParameters['attemptId'] ?? 'pyq_1',
          userId: 'student_1',
          exam: 'NEET',
          mode: PYQPracticeMode.chapterWise,
          subjects: const ['Physics', 'Chemistry', 'Biology'],
          years: const [2024, 2025, 2026],
          attemptedAt: DateTime.now(),
          totalQuestions: 45,
          attemptedCount: 42,
          correctCount: 40,
          incorrectCount: 2,
          skippedCount: 3,
          accuracy: 95.2,
          timeSpentSeconds: 2700,
        );
        final questions = _lastTestQuestions ?? SupabaseService.getSampleQuestions(20);
        final userAnswers = _lastTestUserAnswers ?? const {0: 'A', 1: 'B', 2: 'C'};

        return PYQResultScreen(
          result: pyqResult,
          questions: questions,
          userAnswers: userAnswers,
          onDone: () => context.go('/pyq'),
        );
      },
    ),

    // =========================================================================
    // NTA PRACTICE & TEST ROUTES (/nta-practice/...)
    // =========================================================================
    GoRoute(
      path: '/nta-practice',
      builder: (context, state) => NtaPracticeTestScreen(
        activeExam: state.uri.queryParameters['exam'] ?? 'NEET',
        onStartSession: (questions, timerMins, isTestMode) {
          _activeTestQuestions = questions;
          _activeTestTimerMinutes = timerMins;
          final attemptId = 'nta_${DateTime.now().millisecondsSinceEpoch}';
          if (isTestMode) {
            context.go('/nta-practice/test/$attemptId');
          } else {
            context.go('/nta-practice/questions');
          }
        },
      ),
    ),
    GoRoute(
      path: '/nta-practice/questions',
      builder: (context, state) => NtaChapterTopicWiseScreen(
        activeExam: state.uri.queryParameters['exam'] ?? 'NEET',
        onBack: () => context.go('/nta-practice'),
      ),
    ),
    GoRoute(
      path: '/nta-practice/papers',
      builder: (context, state) => NtaPaperWiseScreen(
        activeExam: state.uri.queryParameters['exam'] ?? 'NEET',
        onBack: () => context.go('/nta-practice'),
      ),
    ),
    GoRoute(
      path: '/nta-practice/test/:paperId',
      builder: (context, state) {
        final paperId = state.pathParameters['paperId'] ?? 'nta_paper_1';
        final questions = _activeTestQuestions ?? SupabaseService.getSampleQuestions(20);
        return CustomTestScreen(
          questions: questions,
          durationMinutes: _activeTestTimerMinutes > 0 ? _activeTestTimerMinutes : 180,
          onTestSubmitted: (attempt, answers) {
            _lastTestAttempt = attempt;
            _lastTestUserAnswers = answers;
            _lastTestQuestions = List<QuestionModel>.from(questions);
            context.go('/nta-practice/result/$paperId');
          },
        );
      },
    ),
    GoRoute(
      path: '/nta-practice/result/:attemptId',
      builder: (context, state) {
        final attempt = _lastTestAttempt ??
            TestAttemptModel(
              id: state.pathParameters['attemptId'] ?? 'nta_1',
              userId: 'student_1',
              testTemplateId: 'nta_template_1',
              testTitle: 'NTA Mock Test Score Report',
              startedAt: DateTime.now().subtract(const Duration(hours: 3)),
              expiresAt: DateTime.now(),
              submittedAt: DateTime.now(),
              status: 'submitted',
              totalScore: 680,
              maxMarks: 720,
              totalQuestions: 180,
              attemptedCount: 175,
              correctCount: 170,
              incorrectCount: 5,
              unattemptedCount: 5,
              accuracy: 97.1,
              timeSpentSeconds: 10800,
            );
        final questions = _lastTestQuestions ?? SupabaseService.getSampleQuestions(20);
        final userAnswers = _lastTestUserAnswers ?? const {0: 'A', 1: 'B', 2: 'C'};

        return Scaffold(
          body: TestResultScreen(
            attempt: attempt,
            questions: questions,
            userAnswers: userAnswers,
            onBackToDashboard: () => context.go('/nta-practice'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/predictions',
      builder: (context, state) => AdminPredictionsScreen(
        userProfile: _getEffectiveProfile(),
      ),
    ),
    GoRoute(
      path: '/predictions/:paperId',
      builder: (context, state) => AdminPredictionsScreen(
        userProfile: _getEffectiveProfile(),
      ),
    ),
    GoRoute(
      path: '/mistakes',
      builder: (context, state) => MistakesBookmarksScreen(
        onStartPractice: (questions) {},
      ),
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => MistakesBookmarksScreen(
        onStartPractice: (questions) {},
      ),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => LeaderboardScreen(
        userProfile: _getEffectiveProfile(),
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Notifications Center')),
      ),
    ),

    // =========================================================================
    // ADMIN ROUTES (/admin/...)
    // =========================================================================
    GoRoute(
      path: '/admin',
      builder: (context, state) => AdminDashboardScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => AdminDashboardScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/sections',
      redirect: (context, state) => '/admin/dashboard',
    ),
    GoRoute(
      path: '/admin/banners',
      builder: (context, state) => AdminBannerManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => AdminUserManagementScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/exams',
      builder: (context, state) => const AdminChaptersTopicsScreen(),
    ),
    GoRoute(
      path: '/admin/subjects',
      builder: (context, state) => const AdminChaptersTopicsScreen(),
    ),
    GoRoute(
      path: '/admin/chapters',
      builder: (context, state) => const AdminChaptersTopicsScreen(),
    ),
    GoRoute(
      path: '/admin/topics',
      builder: (context, state) => const AdminChaptersTopicsScreen(),
    ),
    GoRoute(
      path: '/admin/questions',
      builder: (context, state) => AdminQuestionsBankDashboard(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/question-bank',
      builder: (context, state) => AdminQuestionsBankDashboard(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/questions/upload',
      builder: (context, state) => AdminBulkUploadStep1Screen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/bulk-upload',
      builder: (context, state) => AdminBulkUploadStep1Screen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/upload-step1',
      builder: (context, state) => AdminBulkUploadStep1Screen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/upload-step2',
      builder: (context, state) => AdminBulkUploadStep2Screen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/bulk-upload-step2',
      builder: (context, state) => AdminBulkUploadStep2Screen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/questions/:questionId',
      builder: (context, state) => AdminQuestionBuilderScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/papers',
      builder: (context, state) => AdminQuestionsBankDashboard(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/papers/:paperId',
      builder: (context, state) => AdminBulkUploadStep2Screen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/mock-papers',
      builder: (context, state) => AdminQuestionsBankDashboard(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/test-series',
      builder: (context, state) => TestSeriesScreen(
        onBackToDashboard: () => context.go('/admin'),
      ),
    ),
    GoRoute(
      path: '/admin/pricing',
      builder: (context, state) => AdminPricingScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/hierarchy',
      builder: (context, state) => AdminHierarchyScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/leaderboard',
      builder: (context, state) => AdminLeaderboardScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/predictions',
      builder: (context, state) => AdminPredictionsScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/pdf-import',
      builder: (context, state) => AdminPdfImportScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/admin/notifications',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Admin Notifications')),
        body: const Center(child: Text('Admin Notification Center')),
      ),
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => AdminPricingScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/privacy-policy',
      builder: (context, state) => AdminPrivacyPolicyManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/cms/privacy',
      builder: (context, state) => AdminPrivacyPolicyManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/terms',
      builder: (context, state) => AdminTermsManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/cms/terms',
      builder: (context, state) => AdminTermsManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),

    // --- CMS & Dynamic Content Routes ---
    GoRoute(
      path: '/admin/pages',
      builder: (context, state) => AdminPageManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/pages/new',
      builder: (context, state) => const AdminPageEditorScreen(),
    ),
    GoRoute(
      path: '/admin/blog',
      builder: (context, state) => AdminBlogManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/blog/new',
      builder: (context, state) => const AdminBlogEditorScreen(),
    ),
    GoRoute(
      path: '/admin/navigation',
      builder: (context, state) => AdminNavigationManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/seo',
      builder: (context, state) => AdminSeoScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/test-series-manager',
      builder: (context, state) => AdminTestSeriesManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
        onBack: () => context.go('/admin'),
      ),
    ),
    GoRoute(
      path: '/admin/test-series',
      builder: (context, state) => AdminTestSeriesManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
        onBack: () => context.go('/admin'),
      ),
    ),

    // Super Admin CMS & SEO shortcuts
    GoRoute(
      path: '/superadmin/test-series-manager',
      builder: (context, state) => AdminTestSeriesManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
        onBack: () => context.go('/superadmin/dashboard'),
      ),
    ),
    GoRoute(
      path: '/superadmin/pages',
      builder: (context, state) => AdminPageManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/blog',
      builder: (context, state) => AdminBlogManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/navigation',
      builder: (context, state) => AdminNavigationManagerScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/seo',
      builder: (context, state) => AdminSeoScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),

    // =========================================================================
    // SUPER ADMIN ROUTES (/superadmin/...)
    // =========================================================================
    GoRoute(
      path: '/superadmin',
      builder: (context, state) => AdminDashboardScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/users',
      builder: (context, state) => AdminUserManagementScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/admins',
      builder: (context, state) => AdminUserManagementScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/roles',
      builder: (context, state) => AdminUserManagementScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/permissions',
      builder: (context, state) => AdminUserManagementScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/system-settings',
      builder: (context, state) => AdminPricingScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/audit-logs',
      builder: (context, state) => AdminUserManagementScreen(
        userProfile: SupabaseService.getMockProfile(role: 'super_admin'),
      ),
    ),
    GoRoute(
      path: '/superadmin/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
  ],
);
