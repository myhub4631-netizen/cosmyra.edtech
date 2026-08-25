import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../auth/auth_screen.dart';
import '../landing/landing_page_screen.dart';
import '../home/home_screen.dart';
import '../practice/practice_screen.dart';
import '../practice/custom_practice_wizard.dart';
import '../tests/test_screen.dart';
import '../tests/test_result_screen.dart';
import '../pyq_nta/pyq_nta_screen.dart';
import '../mistakes_bookmarks/mistakes_bookmarks_screen.dart';
import '../analytics/analytics_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_pricing_screen.dart';
import '../admin/admin_hierarchy_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int? initialIndex;

  const MainNavigationScreen({Key? key, this.initialIndex}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late UserProfileModel _currentUser;
  bool _showAuthModal = false;
  late int _selectedIndex;
  String _activeExam = 'NEET';

  // Active Practice Engine State
  List<QuestionModel>? _activePracticeQuestions;
  int _activePracticeTimerMinutes = 0;

  // Active Test Engine State
  List<QuestionModel>? _activeTestQuestions;
  TestAttemptModel? _lastTestAttemptResult;
  Map<int, String>? _lastTestUserAnswers;

  @override
  void initState() {
    super.initState();

    // Check URL path or fragment
    final uriPath = Uri.base.path;
    final uriFragment = Uri.base.fragment;
    final isHierarchyRoute = uriPath.contains('hierarchy') || uriFragment.contains('hierarchy');
    final isPricingRoute = uriPath.contains('pricing') || uriFragment.contains('pricing');
    final isAdminRoute = uriPath.contains('admin') || uriFragment.contains('admin');
    final isLandingRoute = uriPath.contains('landing') || uriPath == '/' || uriPath.isEmpty;

    if (widget.initialIndex != null) {
      _selectedIndex = widget.initialIndex!;
    } else if (isHierarchyRoute) {
      _selectedIndex = 10;
    } else if (isPricingRoute) {
      _selectedIndex = 9;
    } else if (isAdminRoute) {
      _selectedIndex = 8;
    } else {
      _selectedIndex = 0; // Front Landing Page
    }

    _currentUser = SupabaseService.getMockProfile(role: 'student');
    _loadUser();
  }

  Future<void> _loadUser() async {
    final profile = await SupabaseService.getCurrentUser();
    if (profile != null) {
      setState(() {
        _currentUser = profile;
      });
    }
  }

  void _openCustomPracticeWizard() {
    showDialog(
      context: context,
      builder: (ctx) => CustomPracticeWizardModal(
        initialExam: _activeExam,
        onStartPractice: (questions, timerMins) {
          setState(() {
            _activePracticeQuestions = questions;
            _activePracticeTimerMinutes = timerMins;
          });
        },
      ),
    );
  }

  void _startCustomTest() async {
    final questions = await SupabaseService.fetchQuestions(examId: _activeExam, limit: 10);
    setState(() {
      _activeTestQuestions = questions;
      _lastTestAttemptResult = null;
    });
  }

  void _openAuthModal() {
    setState(() => _showAuthModal = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showAuthModal) {
      return AuthScreen(
        onAuthSuccess: (profile) {
          setState(() {
            _currentUser = profile;
            _showAuthModal = false;
          });
        },
      );
    }

    // 1. If currently inside an active practice session
    if (_activePracticeQuestions != null) {
      return PracticeScreen(
        questions: _activePracticeQuestions!,
        timerMinutes: _activePracticeTimerMinutes,
        onFinish: () {
          setState(() {
            _activePracticeQuestions = null;
          });
        },
      );
    }

    // 2. If currently inside an active custom test session
    if (_activeTestQuestions != null) {
      return CustomTestScreen(
        questions: _activeTestQuestions!,
        durationMinutes: 30,
        onTestSubmitted: (attempt, answers) {
          setState(() {
            _activeTestQuestions = null;
            _lastTestAttemptResult = attempt;
            _lastTestUserAnswers = answers;
          });
        },
      );
    }

    // 3. If showing Test Results Screen
    if (_lastTestAttemptResult != null && _lastTestUserAnswers != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Examination Score Report')),
        body: TestResultScreen(
          attempt: _lastTestAttemptResult!,
          questions: SupabaseService.getSampleQuestions(),
          userAnswers: _lastTestUserAnswers!,
          onBackToDashboard: () {
            setState(() {
              _lastTestAttemptResult = null;
              _lastTestUserAnswers = null;
            });
          },
        ),
      );
    }

    // 4. Standalone Admin Screens
    if (_selectedIndex == 8) {
      return AdminDashboardScreen(userProfile: _currentUser);
    }
    if (_selectedIndex == 9) {
      return AdminPricingScreen(userProfile: _currentUser);
    }
    if (_selectedIndex == 10) {
      return AdminHierarchyScreen(userProfile: _currentUser);
    }

    // 5. Front Website Landing Page (Index 0)
    if (_selectedIndex == 0) {
      return LandingPageScreen(
        onStartPracticing: _openCustomPracticeWizard,
        onExploreTests: _startCustomTest,
        onSignUp: _openAuthModal,
        onLogIn: _openAuthModal,
      );
    }

    // 6. Student Dashboard Navigation Shell
    return ResponsiveLayoutShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
      activeExam: _activeExam,
      onExamChanged: (newExam) => setState(() => _activeExam = newExam),
      userProfile: _currentUser,
      body: _buildCurrentTab(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return LandingPageScreen(
          onStartPracticing: _openCustomPracticeWizard,
          onExploreTests: _startCustomTest,
          onSignUp: _openAuthModal,
          onLogIn: _openAuthModal,
        );
      case 1:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('Question Practice Engine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Start a practice session with immediate step-by-step solutions.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openCustomPracticeWizard,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Open Custom Practice Wizard'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
              ),
            ],
          ),
        );
      case 2:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_rounded, size: 64, color: Colors.purple),
              const SizedBox(height: 16),
              const Text('Custom Mock Examination Engine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Timed exam simulator. Feedback & solutions are hidden until final submit.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startCustomTest,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Full Mock Test Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        );
      case 3:
        return PyqNtaScreen(
          activeExam: _activeExam,
          onStartPractice: (questions) {
            setState(() {
              _activePracticeQuestions = questions;
              _activePracticeTimerMinutes = 0;
            });
          },
        );
      case 4:
        return MistakesBookmarksScreen(
          onStartPractice: (questions) {
            setState(() {
              _activePracticeQuestions = questions;
              _activePracticeTimerMinutes = 0;
            });
          },
        );
      case 5:
        return const AnalyticsScreen();
      case 6:
        return LeaderboardScreen(userProfile: _currentUser);
      case 7:
        return ProfileScreen(
          userProfile: _currentUser,
          activeExam: _activeExam,
          onExamChanged: (newExam) => setState(() => _activeExam = newExam),
          onSignOut: () => _openAuthModal(),
        );
      case 8:
        return AdminDashboardScreen(userProfile: _currentUser);
      case 9:
        return AdminPricingScreen(userProfile: _currentUser);
      case 10:
        return AdminHierarchyScreen(userProfile: _currentUser);
      default:
        return const SizedBox.shrink();
    }
  }
}
