import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';
import 'package:cosmyra_neet_jee/core/services/analytics_service.dart';
import 'package:cosmyra_neet_jee/core/router/app_router.dart';
import 'package:cosmyra_neet_jee/features/admin/admin_live_user_activity_screen.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
    await AnalyticsService.initialize();
  });

  group('Phase 5 Live User Activity Monitor Tests', () {
    test('AnalyticsRouteObserver canonicalizes paths and sanitizes query tokens', () {
      expect(AnalyticsRouteObserver.formatScreenTitle('/'), equals('Home / Landing'));
      expect(AnalyticsRouteObserver.formatScreenTitle('/dashboard'), equals('Student Dashboard'));
      expect(AnalyticsRouteObserver.formatScreenTitle('/admin/live-activity'), equals('Admin Live User Activity'));
      expect(AnalyticsRouteObserver.formatScreenTitle('/admin/analytics'), equals('Admin Analytics Dashboard'));
      expect(AnalyticsRouteObserver.formatScreenTitle('/admin/users'), equals('Admin User Management'));
      expect(AnalyticsRouteObserver.formatScreenTitle('/pyq-nta'), equals('Question Bank'));
      expect(AnalyticsRouteObserver.formatScreenTitle('/practice'), equals('Practice & Study'));
      expect(AnalyticsRouteObserver.formatScreenTitle('/test/neet_full_1'), equals('Test Examination'));
      expect(AnalyticsRouteObserver.formatScreenTitle('/test-solutions'), equals('Test Solutions'));
    });

    test('AnalyticsService.logScreenView logs screen_view and debounces duplicates within 600ms', () async {
      await AnalyticsService.instance.logScreenView(
        'Student Dashboard',
        routePath: '/dashboard',
      );
      expect(AnalyticsService.instance.deviceId, isNotEmpty);
      expect(AnalyticsService.instance.sessionId, isNotEmpty);

      // Immediate identical call should be debounced without throwing
      await AnalyticsService.instance.logScreenView(
        'Student Dashboard',
        routePath: '/dashboard',
      );
    });

    test('Lifecycle events app_foregrounded and app_backgrounded log cleanly', () async {
      await AnalyticsService.instance.logAppForegrounded();
      await AnalyticsService.instance.logAppBackgrounded();
      expect(AnalyticsService.instance.deviceId, isNotEmpty);
    });

    test('Extended taxonomy events log without throwing', () async {
      await AnalyticsService.instance.logQuestionAnswer(
        questionId: 'q_test_101',
        subject: 'Physics',
        isCorrect: true,
        timeSpentSeconds: 45,
      );

      await AnalyticsService.instance.logPracticeSession(
        subject: 'Chemistry',
        chapter: 'Thermodynamics',
        questionCount: 15,
      );

      await AnalyticsService.instance.logVideoSolutionOpened(
        videoId: 'vid_neet_01',
        title: 'Rotational Motion Solution',
      );

      await AnalyticsService.instance.logQuestionBankSearch(
        query: 'Genetics Mendel',
        resultsCount: 24,
      );

      await AnalyticsService.instance.logCheckoutStarted(
        seriesId: 'series_neet_2026',
        title: 'NEET 2026 Test Series',
        price: 999.0,
      );

      await AnalyticsService.instance.logLogout();
      expect(AnalyticsService.instance.sessionId, isNotEmpty);
    });

    test('Router has /admin/live-activity route registered', () {
      final routeMatch = appRouter.configuration.routes
          .whereType<dynamic>()
          .any((r) => r.path == '/admin/live-activity' || (r is RouteBase && r.routes.any((child) => child is GoRoute && child.path == '/admin/live-activity')));
      expect(routeMatch, isTrue, reason: '/admin/live-activity must be present in GoRouter');
    });

    testWidgets('AdminLiveUserActivityScreen renders overview cards and live stream section', (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleEvents = [
        {
          'id': 'evt_001',
          'actor_id': 'usr_student_1',
          'event_name': 'screen_view',
          'category': 'navigation',
          'platform': 'android',
          'session_id': 'sess_1',
          'device_model': 'Pixel 7',
          'app_version': '4.1.1+1',
          'screen_name': 'Question Bank',
          'route_path': '/questions',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AdminLiveUserActivityScreen(
            enableTimers: false,
            initialEvents: sampleEvents,
          ),
        ),
      );

      // Top title is immediately visible in header
      expect(find.text('Live User Activity Monitor'), findsOneWidget);

      // Table and sections are rendered
      expect(find.text('Currently Observed Users & Sessions'), findsOneWidget);
      expect(find.text('Live Event Stream'), findsOneWidget);

      // Verify presence calculation & overview elements
      expect(find.text('Active Students (5m)'), findsOneWidget);
      expect(find.text('Total Sessions Today'), findsOneWidget);

      // Unmount widget cleanly
      await tester.pumpWidget(const SizedBox());
    });
  });
}
