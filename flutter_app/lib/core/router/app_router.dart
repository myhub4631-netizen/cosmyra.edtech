import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../../models/models.dart';
import '../../shared/widgets/not_found_screen.dart';
import '../../features/landing/landing_page_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/dashboard/user_dashboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/pyq_nta/pyq_nta_screen.dart';
import '../../features/mistakes_bookmarks/mistakes_bookmarks_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/student/test_series_screen.dart';
import '../../features/tests/mock_tests_screen.dart';
import '../../features/tests/test_screen.dart';
import '../../features/tests/test_result_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/practice/custom_practice_wizard.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/admin_user_management_screen.dart';
import '../../features/admin/admin_dashboard_sections_screen.dart';
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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

UserProfileModel _getEffectiveProfile() {
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

    // =========================================================================
    // STUDENT / USER ROUTES
    // =========================================================================
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => UserDashboardScreen(
        userProfile: _getEffectiveProfile(),
        activeExam: 'NEET',
        onOpenPractice: () => context.go('/practice'),
        onOpenCustomTest: () => context.go('/mock-tests'),
        onOpenMockTests: () => context.go('/mock-tests'),
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
        onOpenCustomTest: () => context.go('/mock-tests'),
        onOpenMockTests: () => context.go('/mock-tests'),
        onOpenPyqs: () => context.go('/pyq'),
        onOpenMistakes: () => context.go('/mistakes'),
        onLogout: () => context.go('/login'),
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
      builder: (context, state) => TestSeriesScreen(
        onBackToDashboard: () => context.go('/dashboard'),
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
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Examination Score Report')),
        body: TestResultScreen(
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
    ),
    GoRoute(
      path: '/practice',
      builder: (context, state) => CustomPracticeWizardModal(
        initialExam: state.uri.queryParameters['exam'] ?? 'NEET',
        onClose: () => context.go('/dashboard'),
        onStartPractice: (questions, timerMins) {},
      ),
    ),
    GoRoute(
      path: '/practice/:subject',
      builder: (context, state) {
        return PracticeScreen(
          questions: SupabaseService.getSampleQuestions(20),
          timerMinutes: 30,
          onFinish: () => context.go('/dashboard'),
        );
      },
    ),
    GoRoute(
      path: '/pyq',
      builder: (context, state) => PyqNtaScreen(
        activeExam: state.uri.queryParameters['exam'] ?? 'NEET',
      ),
    ),
    GoRoute(
      path: '/pyq/:paperId',
      builder: (context, state) => PyqNtaScreen(
        activeExam: 'NEET',
      ),
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
      path: '/admin/users',
      builder: (context, state) => AdminUserManagementScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/courses',
      builder: (context, state) => AdminDashboardSectionsScreen(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
      ),
    ),
    GoRoute(
      path: '/admin/sections',
      builder: (context, state) => AdminDashboardSectionsScreen(
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
      builder: (context, state) => AdminQuestionsBankDashboard(
        userProfile: SupabaseService.getMockProfile(role: 'admin'),
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
