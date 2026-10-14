import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/models/models.dart';
import 'package:cosmyra_neet_jee/core/services/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: Real-Time Analytics & Platform Intelligence Tests', () {
    final now = DateTime.now();

    final testAdmin = UserProfileModel(
      id: 'admin_usr_001',
      email: 'admin@cosmyra.edtech',
      fullName: 'Super Admin',
      role: 'superadmin',
    );

    final testStudent = UserProfileModel(
      id: 'student_usr_001',
      email: 'student@cosmyra.edtech',
      fullName: 'Aarav Sharma',
      role: 'student',
    );

    test('PlatformDistributionData dynamically aggregates Web, Android, and iOS telemetry', () {
      final events = [
        {'id': 'e1', 'platform': 'web', 'event_name': 'session_start', 'user_id': testStudent.id},
        {'id': 'e2', 'platform': 'web', 'event_name': 'test_start', 'user_id': testStudent.id},
        {'id': 'e3', 'platform': 'android', 'event_name': 'session_start', 'user_id': testStudent.id},
        {'id': 'e4', 'platform': 'ios', 'event_name': 'session_start', 'user_id': testStudent.id},
      ];

      final kpis = AnalyticsService.calculateKpiMetrics(
        profiles: [testAdmin, testStudent],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: events,
      );

      final dist = kpis.platformDistribution;
      expect(dist, isNotNull);
      expect(dist!.totalEvents, equals(4));
      expect(dist.webEvents, equals(2));
      expect(dist.androidEvents, equals(1));
      expect(dist.iosEvents, equals(1));
      expect(dist.webPercentage, equals(50.0));
      expect(dist.androidPercentage, equals(25.0));
      expect(dist.iosPercentage, equals(25.0));
    });

    test('PlatformDistributionData handles Web-only telemetry with 100% and 0% mobile', () {
      final webOnlyEvents = [
        {'id': 'e1', 'platform': 'web', 'event_name': 'session_start', 'user_id': testStudent.id},
        {'id': 'e2', 'platform': 'web', 'event_name': 'test_start', 'user_id': testStudent.id},
      ];

      final kpis = AnalyticsService.calculateKpiMetrics(
        profiles: [testAdmin, testStudent],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: webOnlyEvents,
      );

      final dist = kpis.platformDistribution;
      expect(dist, isNotNull);
      expect(dist!.webEvents, equals(2));
      expect(dist.androidEvents, equals(0));
      expect(dist.iosEvents, equals(0));
      expect(dist.webPercentage, equals(100.0));
      expect(dist.androidPercentage, equals(0.0));
      expect(dist.iosPercentage, equals(0.0));
    });

    test('Telemetry status reflects admin-only vs student activity honestly', () {
      // 1. Admin-only telemetry
      final adminEvents = [
        {
          'id': 'a1',
          'platform': 'web',
          'event_name': 'session_start',
          'user_id': testAdmin.id,
          'created_at': now.toIso8601String(),
        },
      ];

      final adminKpis = AnalyticsService.calculateKpiMetrics(
        profiles: [testAdmin, testStudent],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: adminEvents,
      );

      expect(adminKpis.dau, equals(0)); // Admin excluded from DAU
      expect(adminKpis.hasStudentActivity, isFalse);
      expect(adminKpis.telemetryStatus, contains('Admin Telemetry • No Student Activity Yet'));

      // 2. Student telemetry
      final studentEvents = [
        {
          'id': 's1',
          'platform': 'web',
          'event_name': 'test_start',
          'user_id': testStudent.id,
          'created_at': now.toIso8601String(),
        },
      ];

      final studentKpis = AnalyticsService.calculateKpiMetrics(
        profiles: [testAdmin, testStudent],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: studentEvents,
      );

      expect(studentKpis.dau, equals(1)); // Genuine student counts!
      expect(studentKpis.hasStudentActivity, isTrue);
      expect(studentKpis.telemetryStatus, equals('Connected (Student Activity Active)'));

      // 3. Delayed telemetry (>15 mins ago)
      final staleEvents = [
        {
          'id': 'stale1',
          'platform': 'web',
          'event_name': 'test_start',
          'user_id': testStudent.id,
          'created_at': now.subtract(const Duration(minutes: 30)).toIso8601String(),
        },
      ];

      final staleKpis = AnalyticsService.calculateKpiMetrics(
        profiles: [testAdmin, testStudent],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: staleEvents,
      );

      expect(staleKpis.telemetryStatus, contains('Delayed'));
    });
  });
}
