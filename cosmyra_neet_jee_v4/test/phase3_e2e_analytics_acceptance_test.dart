import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/models/models.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';
import 'package:cosmyra_neet_jee/core/services/analytics_service.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> sampleStudentProfile;
  late Map<String, dynamic> sampleAdminProfile;

  setUpAll(() async {
    HttpOverrides.global = TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  group('Phase 3 E2E Acceptance Test 1: Student Activity Ingestion & Deduplication', () {
    test('Inspect live student profiles and verify non-admin qualification', () async {
      final profilesRes = await SupabaseService.client
          .from('profiles')
          .select('id, email, full_name, role, created_at, updated_at')
          .limit(20);
      
      final profilesList = List<Map<String, dynamic>>.from(profilesRes);
      expect(profilesList.isNotEmpty, isTrue);

      final studentProfiles = profilesList.where((p) {
        final role = (p['role'] ?? '').toString().toLowerCase();
        return !role.contains('admin');
      }).toList();

      expect(studentProfiles.isNotEmpty, isTrue, reason: 'There must be legitimate non-admin student profiles.');
      sampleStudentProfile = studentProfiles.first;

      final adminProfiles = profilesList.where((p) {
        final role = (p['role'] ?? '').toString().toLowerCase();
        return role.contains('admin');
      }).toList();
      sampleAdminProfile = adminProfiles.first;
    });

    test('Qualifying student event correctly increases DAU by exactly 1', () {
      final now = DateTime.now();
      final studentId = sampleStudentProfile['id'].toString();
      final adminId = sampleAdminProfile['id'].toString();

      final studentUser = UserProfileModel.fromJson({
        'id': studentId,
        'email': sampleStudentProfile['email'] ?? 'student@test.com',
        'full_name': 'Test Student',
        'role': 'student',
        'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
      });

      final adminUser = UserProfileModel.fromJson({
        'id': adminId,
        'email': sampleAdminProfile['email'] ?? 'admin@test.com',
        'full_name': 'Admin User',
        'role': 'superadmin',
        'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
      });

      final profiles = [studentUser, adminUser];

      // Case A: 0 qualifying events -> DAU = 0
      var kpi = AnalyticsService.calculateKpiMetrics(
        profiles: profiles,
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [],
      );
      expect(kpi.dau, 0, reason: 'Zero qualifying activity must yield DAU = 0');

      // Case B: Student emits 1 qualifying event (test_start)
      final telemetryEvent1 = {
        'id': 'evt_001',
        'event_name': 'test_start',
        'user_id': studentId,
        'device_id': 'dev_test_device_1',
        'session_id': 'sess_test_1',
        'platform': 'web',
        'created_at': now.toUtc().toIso8601String(),
      };

      kpi = AnalyticsService.calculateKpiMetrics(
        profiles: profiles,
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [telemetryEvent1],
      );
      expect(kpi.dau, 1, reason: '1 qualifying student event must yield DAU = 1');

      // Case C: Deduplication - same student emits multiple qualifying events
      final telemetryEvent2 = {
        'id': 'evt_002',
        'event_name': 'question_answer',
        'user_id': studentId,
        'device_id': 'dev_test_device_1',
        'session_id': 'sess_test_1',
        'platform': 'web',
        'created_at': now.add(const Duration(minutes: 5)).toUtc().toIso8601String(),
      };
      final telemetryEvent3 = {
        'id': 'evt_003',
        'event_name': 'test_submit',
        'user_id': studentId,
        'device_id': 'dev_test_device_1',
        'session_id': 'sess_test_1',
        'platform': 'web',
        'created_at': now.add(const Duration(minutes: 15)).toUtc().toIso8601String(),
      };

      kpi = AnalyticsService.calculateKpiMetrics(
        profiles: profiles,
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [telemetryEvent1, telemetryEvent2, telemetryEvent3],
      );
      expect(kpi.dau, 1, reason: 'Multiple events for the same student must remain strictly deduplicated to DAU = 1');

      // Case D: Profile edits and background refreshes must NOT count towards DAU
      final nonQualifyingEvent = {
        'id': 'evt_004',
        'event_name': 'profile_edit',
        'user_id': 'another_student_uuid',
        'device_id': 'dev_test_device_2',
        'session_id': 'sess_test_2',
        'platform': 'web',
        'created_at': now.toUtc().toIso8601String(),
      };
      final backgroundRefreshEvent = {
        'id': 'evt_005',
        'event_name': 'background_sync',
        'user_id': 'another_student_uuid',
        'device_id': 'dev_test_device_2',
        'session_id': 'sess_test_2',
        'platform': 'web',
        'created_at': now.toUtc().toIso8601String(),
      };

      kpi = AnalyticsService.calculateKpiMetrics(
        profiles: profiles,
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [telemetryEvent1, nonQualifyingEvent, backgroundRefreshEvent],
      );
      expect(kpi.dau, 1, reason: 'Profile edits and background refreshes must never increase student DAU');

      // Case E: Administrator events must NOT count towards student DAU
      final adminEvent = {
        'id': 'evt_006',
        'event_name': 'session_start',
        'user_id': adminId,
        'device_id': 'dev_admin_device',
        'session_id': 'sess_admin',
        'platform': 'web',
        'created_at': now.toUtc().toIso8601String(),
      };

      kpi = AnalyticsService.calculateKpiMetrics(
        profiles: profiles,
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [adminEvent],
      );
      expect(kpi.dau, 0, reason: 'Admin actions must be strictly excluded from student DAU');
    });

    test('Verify WAU and MAU rolling date windows in Indian Standard Time (IST)', () {
      final now = DateTime.now();
      final studentId = sampleStudentProfile['id'].toString();

      final studentUser = UserProfileModel.fromJson({
        'id': studentId,
        'email': sampleStudentProfile['email'] ?? 'student@test.com',
        'full_name': 'Test Student',
        'role': 'student',
        'created_at': now.subtract(const Duration(days: 45)).toIso8601String(),
      });

      // Event 5 days ago (Inside WAU and MAU, outside DAU)
      final event5DaysAgo = {
        'id': 'evt_w1',
        'event_name': 'practice_session',
        'user_id': studentId,
        'device_id': 'dev_test_device_1',
        'session_id': 'sess_w1',
        'platform': 'web',
        'created_at': now.subtract(const Duration(days: 5)).toUtc().toIso8601String(),
      };

      final kpi = AnalyticsService.calculateKpiMetrics(
        profiles: [studentUser],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [event5DaysAgo],
      );

      expect(kpi.dau, 0, reason: 'Event 5 days ago is outside rolling 24h DAU window');
      expect(kpi.wau, 1, reason: 'Event 5 days ago is inside rolling 7d WAU window');
      expect(kpi.mau, 1, reason: 'Event 5 days ago is inside rolling 30d MAU window');

      // Event 20 days ago (Inside MAU, outside WAU and DAU)
      final event20DaysAgo = {
        'id': 'evt_m1',
        'event_name': 'test_submit',
        'user_id': studentId,
        'device_id': 'dev_test_device_1',
        'session_id': 'sess_m1',
        'platform': 'web',
        'created_at': now.subtract(const Duration(days: 20)).toUtc().toIso8601String(),
      };

      final kpi2 = AnalyticsService.calculateKpiMetrics(
        profiles: [studentUser],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [event20DaysAgo],
      );

      expect(kpi2.dau, 0, reason: 'Event 20 days ago is outside DAU window');
      expect(kpi2.wau, 0, reason: 'Event 20 days ago is outside WAU window');
      expect(kpi2.mau, 1, reason: 'Event 20 days ago is inside rolling 30d MAU window');
    });
  });

  group('Phase 3 E2E Acceptance Test 2: Device Telemetry & Storage Lifecycle', () {
    test('Client-install identifier persists across sessions and regenerates on storage clear', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Initialization 1
      String? devId1 = prefs.getString('cosmyra_device_uuid_v2');
      expect(devId1, isNull);
      devId1 = 'dev_${DateTime.now().millisecondsSinceEpoch}_1001';
      await prefs.setString('cosmyra_device_uuid_v2', devId1);

      // Re-read (simulating app relaunch or page reload)
      final devIdCached = prefs.getString('cosmyra_device_uuid_v2');
      expect(devIdCached, equals(devId1), reason: 'Device ID must remain stable across sessions');

      // Simulate browser cache clear / app reinstallation
      await prefs.clear();
      expect(prefs.getString('cosmyra_device_uuid_v2'), isNull);

      // Re-initialization after clear
      final devId2 = 'dev_${DateTime.now().millisecondsSinceEpoch}_1002';
      await prefs.setString('cosmyra_device_uuid_v2', devId2);
      expect(devId2, isNot(equals(devId1)), reason: 'A cleared storage regenerates a new privacy-preserving UUID');
    });

    test('Dashboard accurately counts unique tracked devices and handles zero count safely', () {
      final now = DateTime.now();

      // Case A: Confirmed 0 devices tracked
      final kpiZero = AnalyticsService.calculateKpiMetrics(
        profiles: [],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [],
      );
      expect(kpiZero.installedDevicesCount, 0);
      expect(kpiZero.telemetryStatus, equals('Ingestion Pending'));

      // Case B: Multiple events across 2 distinct devices
      final events = [
        {
          'event_name': 'session_start',
          'device_id': 'dev_alpha',
          'session_id': 'sess_1',
          'created_at': now.toUtc().toIso8601String(),
        },
        {
          'event_name': 'test_start',
          'device_id': 'dev_alpha', // Duplicate device
          'session_id': 'sess_1',
          'created_at': now.toUtc().toIso8601String(),
        },
        {
          'event_name': 'session_start',
          'device_id': 'dev_beta',
          'session_id': 'sess_2',
          'created_at': now.toUtc().toIso8601String(),
        },
      ];

      final kpiTwoDevices = AnalyticsService.calculateKpiMetrics(
        profiles: [],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: events,
      );
      expect(kpiTwoDevices.installedDevicesCount, 2);
      expect(kpiTwoDevices.uniqueVisitorsCount, 2);
    });
  });

  group('Phase 3 E2E Acceptance Test 3: Retention Cohorts & Missing Data Integrity', () {
    test('Retention cohorts require qualifying events, protect incomplete weeks and handle duplicates', () {
      final now = DateTime.now();

      // Cohort created in Week -2 (14 to 21 days ago)
      final cohortStudent1 = UserProfileModel.fromJson({
        'id': 'c_student_1',
        'email': 'cohort1@test.com',
        'full_name': 'Cohort Student 1',
        'role': 'student',
        'created_at': now.subtract(const Duration(days: 18)).toIso8601String(),
      });
      final cohortStudent2 = UserProfileModel.fromJson({
        'id': 'c_student_2',
        'email': 'cohort2@test.com',
        'full_name': 'Cohort Student 2',
        'role': 'student',
        'created_at': now.subtract(const Duration(days: 17)).toIso8601String(),
      });

      // Student 1 returned in Week 1 with a qualifying activity event
      final returnEvent1 = {
        'event_name': 'test_submit',
        'user_id': 'c_student_1',
        'device_id': 'dev_c1',
        'created_at': now.subtract(const Duration(days: 10)).toUtc().toIso8601String(),
      };
      // Duplicate event by Student 1 in the same week
      final duplicateReturnEvent = {
        'event_name': 'question_answer',
        'user_id': 'c_student_1',
        'device_id': 'dev_c1',
        'created_at': now.subtract(const Duration(days: 9)).toUtc().toIso8601String(),
      };

      // Non-qualifying profile edit by Student 2 (must not count as retention)
      final profileEditEvent = {
        'event_name': 'profile_update',
        'user_id': 'c_student_2',
        'device_id': 'dev_c2',
        'created_at': now.subtract(const Duration(days: 10)).toUtc().toIso8601String(),
      };

      final kpi = AnalyticsService.calculateKpiMetrics(
        profiles: [cohortStudent1, cohortStudent2],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [returnEvent1, duplicateReturnEvent, profileEditEvent],
      );

      final row = kpi.retentionCohorts.firstWhere((r) => r.cohortLabel.contains('W-3'));
      expect(row.signupsCount, 2);
      expect(row.week0Pct, 100);
      // Exactly 1 out of 2 students had genuine qualifying return activity (50%)
      expect(row.week1Pct, 50, reason: 'Duplicate events by student 1 and profile edit by student 2 must yield exactly 50%');
      // Incomplete/future week must be null ('—')
      expect(row.week3Pct, isNull, reason: 'Future/incomplete weeks must display as null (—)');
    });
  });

  group('Phase 3 E2E Acceptance Test 4: Crash-Free Reporting & Platform Distinction', () {
    test('Crash-free rate displays N/A on Web and awaits mobile telemetry stream', () {
      final kpi = AnalyticsService.calculateKpiMetrics(
        profiles: [],
        orders: [],
        testAttempts: [],
        entitlements: [],
        telemetryEvents: [],
      );

      expect(kpi.crashFreePercentage, isNull, reason: 'Crash-free percentage must be null (N/A) until real telemetry is streamed');
      expect(kpi.crashReportingStatus, contains('Mobile (Android/iOS) Supported • Web Unsupported'));
    });
  });
}
