import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/models/models.dart';
import 'package:cosmyra_neet_jee/core/services/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyticsService Core & Anti-Fraud Unit Tests', () {
    test('AnalyticsService singleton instance is accessible', () {
      final instance1 = AnalyticsService.instance;
      final instance2 = AnalyticsService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('Sensitive parameters and PII are properly sanitized', () {
      final service = AnalyticsService.instance;
      final rawParams = {
        'exam': 'NEET',
        'score': 540,
        'password': 'secret_password_123',
        'access_token': 'jwt_bearer_token_abc',
        'user_phone': '+919876543210',
        'authorization': 'Bearer xyz789',
        'secret': 'super_private_key',
        'safe_property': 'valid_value',
      };

      final sanitized = service.sanitizeParameters(rawParams);

      // Sensitive keys must be removed
      expect(sanitized.containsKey('password'), isFalse);
      expect(sanitized.containsKey('access_token'), isFalse);
      expect(sanitized.containsKey('user_phone'), isFalse);
      expect(sanitized.containsKey('authorization'), isFalse);
      expect(sanitized.containsKey('secret'), isFalse);

      // Safe keys must be preserved
      expect(sanitized['exam'], equals('NEET'));
      expect(sanitized['score'], equals(540));
      expect(sanitized['safe_property'], equals('valid_value'));
    });

    test('In-memory LRU deduplication prevents duplicate event IDs', () {
      final service = AnalyticsService.instance;
      const testEventId = 'test_event_dedup_001';

      // First check should allow processing
      expect(service.isDuplicateEvent(testEventId), isFalse);

      // Register the event
      service.recordEventId(testEventId);

      // Second check must detect duplicate
      expect(service.isDuplicateEvent(testEventId), isTrue);
    });
  });

  group('Authoritative Financial & KPI Metric Computation Tests', () {
    test('Only completed orders are counted towards verified revenue', () {
      final now = DateTime.now();

      final mockOrders = [
        {
          'id': 'ord_1',
          'user_id': 'user_a',
          'total_amount': 999.0,
          'status': 'completed',
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'ord_2',
          'user_id': 'user_b',
          'total_amount': 1499.0,
          'status': 'completed',
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'ord_3',
          'user_id': 'user_c',
          'total_amount': 2999.0,
          'status': 'pending', // MUST BE EXCLUDED
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'ord_4',
          'user_id': 'user_d',
          'total_amount': 499.0,
          'status': 'failed', // MUST BE EXCLUDED
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'ord_5',
          'user_id': 'user_e',
          'total_amount': 799.0,
          'status': 'created', // MUST BE EXCLUDED
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'ord_6',
          'user_id': 'user_f',
          'total_amount': 500.0,
          'status': 'refunded', // Must be tracked as refund
          'created_at': now.toIso8601String(),
        },
      ];

      final metrics = AnalyticsService.calculateKpiMetrics(
        profiles: [],
        orders: mockOrders,
        testAttempts: [],
        entitlements: [],
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 1)),
      );

      // Completed orders total: 999 + 1499 = 2498
      expect(metrics.grossRevenue, equals(2498.0));
      expect(metrics.completedOrdersCount, equals(2));
      expect(metrics.refundsCount, equals(1));
      expect(metrics.refundedAmount, equals(500.0));
      expect(metrics.netRevenue, equals(1998.0));
    });

    test('DAU, WAU, and MAU are calculated authoritatively from genuine student qualifying activity', () {
      final now = DateTime.now();

      final mockProfiles = [
        UserProfileModel.fromJson({
          'id': 'u1',
          'email': 'student1@example.com',
          'role': 'student',
          'created_at': now.subtract(const Duration(days: 20)).toIso8601String(),
          'updated_at': now.toIso8601String(),
        }),
        UserProfileModel.fromJson({
          'id': 'u2',
          'email': 'student2@example.com',
          'role': 'student',
          'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
          'updated_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        }),
        UserProfileModel.fromJson({
          'id': 'u3',
          'email': 'student3@example.com',
          'role': 'student',
          'created_at': now.subtract(const Duration(days: 25)).toIso8601String(),
          'updated_at': now.subtract(const Duration(days: 15)).toIso8601String(),
        }),
        // Profile u4 has updated_at today (e.g. profile edit or background job) but NO qualifying events
        UserProfileModel.fromJson({
          'id': 'u4_profile_edit_only',
          'email': 'student4@example.com',
          'role': 'student',
          'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
          'updated_at': now.toIso8601String(),
        }),
        // Admin user with events today (MUST BE EXCLUDED from student DAU)
        UserProfileModel.fromJson({
          'id': 'u_admin',
          'email': 'admin@example.com',
          'role': 'superadmin',
          'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
          'updated_at': now.toIso8601String(),
        }),
      ];

      final mockTelemetry = [
        // u1 has duplicate session_start events today (deduplication check)
        {
          'event_name': 'session_start',
          'user_id': 'u1',
          'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'event_name': 'session_start',
          'user_id': 'u1',
          'created_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
        },
        // Admin active today
        {
          'event_name': 'session_start',
          'user_id': 'u_admin',
          'created_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
        },
      ];

      // u2 has a test attempt 3 days ago (WAU & MAU qualifying activity)
      final mockAttempts = [
        {
          'id': 'att_u2',
          'student_id': 'u2',
          'status': 'submitted',
          'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        },
      ];

      // u3 has a completed order 15 days ago (MAU qualifying activity)
      final mockOrders = [
        {
          'id': 'ord_u3',
          'user_id': 'u3',
          'status': 'completed',
          'total_amount': 999.0,
          'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
        },
      ];

      final metrics = AnalyticsService.calculateKpiMetrics(
        profiles: mockProfiles,
        orders: mockOrders,
        testAttempts: mockAttempts,
        entitlements: [],
        telemetryEvents: mockTelemetry,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 1)),
      );

      // DAU: exactly 1 student ('u1'). Admin 'u_admin' is excluded. 'u4' (profile edit only) is excluded!
      expect(metrics.dau, equals(1));
      // WAU: 2 students ('u1' + 'u2')
      expect(metrics.wau, equals(2));
      // MAU: 3 students ('u1' + 'u2' + 'u3')
      expect(metrics.mau, equals(3));
    });

    test('Test completion rate and average scores are computed correctly', () {
      final now = DateTime.now();

      final mockAttempts = [
        {
          'id': 'att_1',
          'user_id': 'u1',
          'status': 'submitted',
          'total_score': 620.0,
          'max_score': 720.0,
          'accuracy': 88.5,
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'att_2',
          'user_id': 'u2',
          'status': 'submitted',
          'total_score': 540.0,
          'max_score': 720.0,
          'accuracy': 75.0,
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'att_3',
          'user_id': 'u3',
          'status': 'in_progress', // Started but not completed
          'total_score': 0.0,
          'max_score': 720.0,
          'accuracy': 0.0,
          'created_at': now.toIso8601String(),
        },
      ];

      final metrics = AnalyticsService.calculateKpiMetrics(
        profiles: [],
        orders: [],
        testAttempts: mockAttempts,
        entitlements: [],
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 1)),
      );

      expect(metrics.testStartsCount, equals(3));
      expect(metrics.testSubmissionsCount, equals(2));
      // Completion rate: 2 / 3 * 100 = 66.67%
      expect(metrics.testCompletionRate, closeTo(66.67, 0.1));
      // Average score percentage: (620 + 540) / (720 + 720) * 100 = 1160 / 1440 * 100 = 80.56%
      expect(metrics.avgScorePercentage, closeTo(80.56, 0.1));
    });

    test('Entitlements classify Free vs Paid enrollments accurately', () {
      final now = DateTime.now();

      final mockEntitlements = [
        {
          'id': 'ent_1',
          'user_id': 'u1',
          'product_type': 'test_series',
          'access_type': 'free',
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'ent_2',
          'user_id': 'u2',
          'product_type': 'test_series',
          'access_type': 'paid',
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'ent_3',
          'user_id': 'u3',
          'product_type': 'test_series',
          'access_type': 'subscription',
          'created_at': now.toIso8601String(),
        },
      ];

      final metrics = AnalyticsService.calculateKpiMetrics(
        profiles: [],
        orders: [],
        testAttempts: [],
        entitlements: mockEntitlements,
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 1)),
      );

      expect(metrics.freeEnrollments, equals(1));
      expect(metrics.paidEnrollments, equals(2)); // paid + subscription
      expect(metrics.totalEnrollments, equals(3));
    });

    test('Retention cohorts and crash-free metrics handle dynamic data and unavailable states cleanly', () {
      final now = DateTime.now();

      // Test with empty dataset (no fake baseline)
      final metricsEmpty = AnalyticsService.calculateKpiMetrics(
        profiles: [],
        orders: [],
        testAttempts: [],
        entitlements: [],
        startDate: now.subtract(const Duration(days: 35)),
        endDate: now.add(const Duration(days: 1)),
      );

      // Crash-free percentage should be null (N/A) without mobile crashlytics telemetry
      expect(metricsEmpty.crashFreePercentage, isNull);
      // Installed devices count should be 0 without fake multiplier
      expect(metricsEmpty.installedDevicesCount, equals(0));

      final cohortsEmpty = metricsEmpty.retentionCohorts;
      expect(cohortsEmpty.length, equals(4));
      for (final cohort in cohortsEmpty) {
        expect(cohort.signupsCount, equals(0));
        expect(cohort.week0Pct, equals(0));
        expect(cohort.week1Pct, isNull);
      }

      // Test with genuine cohort signups and subsequent qualifying activity
      final mockProfiles = [
        UserProfileModel.fromJson({
          'id': 'c_u1',
          'email': 'cohort_student1@example.com',
          'role': 'student',
          'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
          'updated_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        }),
      ];

      // c_u1 had qualifying session_start in week 1 after signup
      final mockCohortTelemetry = [
        {
          'event_name': 'session_start',
          'user_id': 'c_u1',
          'device_id': 'dev_test_device_1',
          'session_id': 'sess_1',
          'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        },
        // Duplicate event on same device
        {
          'event_name': 'test_start',
          'user_id': 'c_u1',
          'device_id': 'dev_test_device_1',
          'session_id': 'sess_1',
          'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        },
      ];

      final metricsPopulated = AnalyticsService.calculateKpiMetrics(
        profiles: mockProfiles,
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: mockCohortTelemetry,
        startDate: now.subtract(const Duration(days: 35)),
        endDate: now.add(const Duration(days: 1)),
      );

      final populatedCohort = metricsPopulated.retentionCohorts.firstWhere((c) => c.signupsCount > 0);
      expect(populatedCohort.week0Pct, equals(100));
      // Deduplicated device count
      expect(metricsPopulated.installedDevicesCount, equals(1));
      expect(metricsPopulated.uniqueVisitorsCount, equals(1));

      // Test zero denominator safety in funnel
      final zeroMetrics = AnalyticsService.calculateKpiMetrics(
        profiles: [],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [],
      );
      expect(zeroMetrics.funnelVisits, equals(0));
      expect(zeroMetrics.funnelSignups, equals(0));
      expect(zeroMetrics.installedDevicesCount, equals(0));
    });
  });
}
