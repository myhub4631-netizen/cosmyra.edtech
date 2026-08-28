import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../auth/auth_screen.dart';
import '../landing/landing_page_screen.dart';
import '../home/home_screen.dart';
import '../practice/practice_screen.dart';
import '../practice/custom_practice_wizard.dart';
import '../tests/mock_tests_screen.dart';
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
import '../admin/admin_leaderboard_screen.dart';
import '../admin/admin_predictions_screen.dart';
import '../admin/admin_user_management_screen.dart';
import '../admin/admin_chapters_topics_screen.dart';

import '../dashboard/user_dashboard_screen.dart';

import '../admin/admin_dashboard_sections_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int? initialIndex;
  final bool forceDashboard;

  const MainNavigationScreen({
    Key? key,
    this.initialIndex,
    this.forceDashboard = false,
  }) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late UserProfileModel _currentUser;
  bool _showAuthModal = false;
  late int _selectedIndex;
  bool _isLoggedIn = false;
  String _activeExam = 'NEET';

  // Active Practice Engine State
  List<QuestionModel>? _activePracticeQuestions;
  int _activePracticeTimerMinutes = 0;

  // Active Test Engine State
  List<QuestionModel>? _activeTestQuestions;
  int _activeTestDurationMinutes = 30;
  List<QuestionModel>? _lastTestQuestions;
  TestAttemptModel? _lastTestAttemptResult;
  Map<int, String>? _lastTestUserAnswers;

  @override
  void initState() {
    super.initState();

    final uriPath = Uri.base.path;
    final uriFragment = Uri.base.fragment;
    final isSuperAdminRoute = uriPath.contains('superadmin') || uriFragment.contains('superadmin');
    final isSectionsRoute = uriPath.contains('sections') || uriFragment.contains('sections');
    final isUsersRoute = uriPath.contains('users') || uriFragment.contains('users');
    final isPredictionsRoute = uriPath.contains('predictions') || uriFragment.contains('predictions');
    final isLeaderboardRoute = uriPath.contains('leaderboard') || uriFragment.contains('leaderboard');
    final isHierarchyRoute = uriPath.contains('hierarchy') || uriFragment.contains('hierarchy');
    final isPricingRoute = uriPath.contains('pricing') || uriFragment.contains('pricing');
    final isAdminRoute = uriPath.contains('admin') || uriFragment.contains('admin');
    final isDashboardRoute = uriPath.contains('dashboard') || uriFragment.contains('dashboard');

    if (widget.initialIndex != null) {
      _selectedIndex = widget.initialIndex!;
    } else if (isSuperAdminRoute) {
      _selectedIndex = 15;
    } else if (isSectionsRoute) {
      _selectedIndex = 14;
    } else if (isUsersRoute) {
      _selectedIndex = 13;
    } else if (isPredictionsRoute) {
      _selectedIndex = 12;
    } else if (isLeaderboardRoute) {
      _selectedIndex = 11;
    } else if (isHierarchyRoute) {
      _selectedIndex = 10;
    } else if (isPricingRoute) {
      _selectedIndex = 9;
    } else if (isAdminRoute) {
      _selectedIndex = 8;
    } else if (isDashboardRoute) {
      _selectedIndex = 0;
    } else {
      _selectedIndex = -1;
    }

    _currentUser = SupabaseService.getMockProfile(role: 'student');
    _loadUser();
  }

  Future<void> _loadUser() async {
    final profile = await SupabaseService.getCurrentUser();
    if (profile != null) {
      setState(() {
        _currentUser = profile;
        _isLoggedIn = true;
        if (profile.isSuperAdmin && (_selectedIndex == -1 || _selectedIndex == 0)) {
          _selectedIndex = 15;
        } else if (profile.isAdmin && (_selectedIndex == -1 || _selectedIndex == 0)) {
          _selectedIndex = 8;
        } else if (_selectedIndex == -1) {
          _selectedIndex = 0;
        }
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _selectedIndex = -1;
      });
    }
  }

  void _openCustomPracticeWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CustomPracticeWizardModal(
          initialExam: _activeExam,
          onClose: () {
            if (Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop();
            } else {
              setState(() => _selectedIndex = 0);
            }
          },
          onStartPractice: (questions, timerMins) {
            if (Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop();
            }
            setState(() {
              _activePracticeQuestions = questions;
              _activePracticeTimerMinutes = timerMins;
            });
          },
        ),
      ),
    );
  }

  void _startPYQSession(List<QuestionModel> questions, int timerMins, bool isTestMode) {
    if (isTestMode) {
      setState(() {
        _activeTestQuestions = questions;
        _activeTestDurationMinutes = timerMins;
      });
    } else {
      setState(() {
        _activePracticeQuestions = questions;
        _activePracticeTimerMinutes = 0;
      });
    }
  }

  void _startCustomTest() {
    _openCustomTestWizard();
  }

  void _openCustomTestWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CustomPracticeWizardModal(
          initialExam: _activeExam,
          mode: PracticeTestMode.test,
          onClose: () {
            if (Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop();
            } else {
              setState(() => _selectedIndex = 0);
            }
          },
          onStartPractice: (questions, timerMins) {
            if (Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop();
            }
            setState(() {
              _activeTestQuestions = questions;
              _activeTestDurationMinutes = timerMins;
            });
          },
        ),
      ),
    );
  }

  void _openAuthModal() {
    setState(() {
      _showAuthModal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showAuthModal) {
      return AuthScreen(
        onAuthSuccess: (profile) {
          setState(() {
            _currentUser = profile;
            _isLoggedIn = true;
            _showAuthModal = false;
            if (profile.isAdmin || profile.isSuperAdmin) {
              _selectedIndex = 8;
            } else {
              _selectedIndex = 0;
            }
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
        durationMinutes: _activeTestDurationMinutes > 0 ? _activeTestDurationMinutes : 30,
        onTestSubmitted: (attempt, answers) {
          setState(() {
            _lastTestQuestions = List<QuestionModel>.from(_activeTestQuestions!);
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
          questions: _lastTestQuestions ?? SupabaseService.getSampleQuestions(),
          userAnswers: _lastTestUserAnswers!,
          onBackToDashboard: () {
            setState(() {
              _lastTestAttemptResult = null;
              _lastTestUserAnswers = null;
              _lastTestQuestions = null;
              _selectedIndex = 0;
            });
          },
        ),
      );
    }

    // 0. AUTHENTICATION GUARD: If user is NOT logged in, ANY route or URL MUST render LandingPageScreen
    if (!_isLoggedIn) {
      return LandingPageScreen(
        onStartPracticing: _openCustomPracticeWizard,
        onExploreTests: _startCustomTest,
        onSignUp: _openAuthModal,
        onLogIn: _openAuthModal,
      );
    }

    // 4. Standalone Admin Screens (Only accessible when _isLoggedIn is true)
    if (_selectedIndex == 8 || _selectedIndex == 15) {
      return AdminDashboardScreen(userProfile: _currentUser);
    }
    if (_selectedIndex == 9) {
      return AdminPricingScreen(userProfile: _currentUser);
    }
    if (_selectedIndex == 10) {
      return AdminHierarchyScreen(userProfile: _currentUser);
    }
    if (_selectedIndex == 11) {
      return AdminLeaderboardScreen(userProfile: _currentUser);
    }
    if (_selectedIndex == 12) {
      return AdminPredictionsScreen(userProfile: _currentUser);
    }
    if (_selectedIndex == 13) {
      return AdminUserManagementScreen(userProfile: _currentUser);
    }
    if (_selectedIndex == 14) {
      return AdminDashboardSectionsScreen(userProfile: _currentUser);
    }
    if (_selectedIndex == 16) {
      return const AdminChaptersTopicsScreen();
    }

    // 5. Root / Dashboard handling for authenticated users
    if (_currentUser.isSuperAdmin || _currentUser.isAdmin) {
      return AdminDashboardScreen(userProfile: _currentUser);
    }

    return _buildCurrentTab();
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return UserDashboardScreen(
          userProfile: _currentUser,
          activeExam: _activeExam,
          onOpenPractice: _openCustomPracticeWizard,
          onOpenCustomTest: _openCustomTestWizard,
          onOpenMockTests: () => setState(() => _selectedIndex = 2),
          onOpenPyqs: () => setState(() => _selectedIndex = 3),
          onOpenMistakes: () => setState(() => _selectedIndex = 4),
          onLogout: () {
            setState(() {
              _isLoggedIn = false;
              _selectedIndex = -1;
            });
          },
        );
      case 1:
        return CustomPracticeWizardModal(
          initialExam: _activeExam,
          onClose: () {
            setState(() => _selectedIndex = 0);
          },
          onStartPractice: (questions, timerMins) {
            setState(() {
              _activePracticeQuestions = questions;
              _activePracticeTimerMinutes = timerMins;
            });
          },
        );
      case 2:
        return MockTestsScreen(
          onStartTest: _startCustomTest,
        );
      case 3:
        return PyqNtaScreen(
          activeExam: _activeExam,
          onStartSession: _startPYQSession,
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
      case 11:
        return AdminLeaderboardScreen(userProfile: _currentUser);
      case 12:
        return AdminPredictionsScreen(userProfile: _currentUser);
      case 13:
        return AdminUserManagementScreen(userProfile: _currentUser);
      case 14:
        return AdminDashboardSectionsScreen(userProfile: _currentUser);
      default:
        return UserDashboardScreen(
          userProfile: _currentUser,
          activeExam: _activeExam,
          onOpenPractice: _openCustomPracticeWizard,
          onOpenCustomTest: _openCustomTestWizard,
          onOpenMockTests: () => setState(() => _selectedIndex = 2),
          onOpenPyqs: () => setState(() => _selectedIndex = 3),
          onOpenMistakes: () => setState(() => _selectedIndex = 4),
          onLogout: () {
            setState(() {
              _isLoggedIn = false;
              _selectedIndex = -1;
            });
          },
        );
    }
  }
}
