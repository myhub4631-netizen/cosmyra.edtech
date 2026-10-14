import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = MyHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  test('Query and audit live Supabase tables for Analytics & KPI Dashboard', () async {
    print('\n================ PRODUCTION DATA INTEGRITY AUDIT ================\n');

    // 1. Audit Profiles
    final profilesRes = await SupabaseService.client
        .from('profiles')
        .select('id, email, full_name, role, created_at, updated_at');
    final profiles = List<Map<String, dynamic>>.from(profilesRes);
    print('1. PROFILES (Registered Users):');
    print('   Total Count: ${profiles.length}');

    final now = DateTime.now();
    int active1d = 0;
    int active7d = 0;
    int active30d = 0;

    print('   Profile Creation & Activity Breakdown:');
    final creationMap = <String, int>{};
    final activityMap = <String, int>{};
    for (var p in profiles) {
      final c = DateTime.tryParse(p['created_at']?.toString() ?? '');
      if (c != null) {
        final key = '${c.year}-${c.month.toString().padLeft(2, '0')}-${c.day.toString().padLeft(2, '0')}';
        creationMap[key] = (creationMap[key] ?? 0) + 1;
      }
      final u = DateTime.tryParse(p['updated_at']?.toString() ?? '') ?? c;
      if (u != null) {
        final key = '${u.year}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
        activityMap[key] = (activityMap[key] ?? 0) + 1;
      }
    }
    print('   Signups by Date: $creationMap');
    print('   Active by Date:  $activityMap');

    // 2. Audit Orders
    print('\n2. ORDERS (Financial / Purchases):');
    try {
      final ordersRes = await SupabaseService.client
          .from('orders')
          .select('id, user_id, user_email, total_amount, status, payment_method, created_at');
      final orders = List<Map<String, dynamic>>.from(ordersRes);
      print('   Total Orders Count: ${orders.length}');
      final statusMap = <String, int>{};
      double completedRevenue = 0.0;
      double refundedRevenue = 0.0;
      for (var o in orders) {
        final s = (o['status'] ?? 'unknown').toString();
        statusMap[s] = (statusMap[s] ?? 0) + 1;
        final amt = double.tryParse((o['total_amount'] ?? '0').toString()) ?? 0.0;
        if (s == 'completed') completedRevenue += amt;
        if (s == 'refunded') refundedRevenue += amt;
      }
      print('   Status breakdown: $statusMap');
      print('   Completed Revenue: ₹$completedRevenue');
      print('   Refunded Revenue:  ₹$refundedRevenue');
    } catch (e) {
      print('   Orders query error: $e');
    }

    // 3. Audit Test Attempts
    print('\n3. TEST ATTEMPTS:');
    try {
      final attemptsRes = await SupabaseService.client
          .from('test_attempts')
          .select('id, student_id, test_id, status, total_score, max_score, accuracy_percentage, started_at, submitted_at, created_at')
          .limit(500);
      final attempts = List<Map<String, dynamic>>.from(attemptsRes);
      print('   Total Test Attempts Count: ${attempts.length}');
      final attemptStatusMap = <String, int>{};
      for (var a in attempts) {
        final s = (a['status'] ?? 'unknown').toString();
        attemptStatusMap[s] = (attemptStatusMap[s] ?? 0) + 1;
      }
      print('   Attempt Status breakdown: $attemptStatusMap');
      if (attempts.isNotEmpty) {
        print('   Sample attempt: ${attempts.first}');
      }
    } catch (e) {
      print('   Test attempts query error: $e');
    }

    // 4. Audit Entitlements
    print('\n4. ENTITLEMENTS (Test Series Enrollments):');
    try {
      final entRes = await SupabaseService.client
          .from('entitlements')
          .select('id, user_id, product_title, product_type, access_type, is_active, created_at');
      final ents = List<Map<String, dynamic>>.from(entRes);
      print('   Total Entitlements Count: ${ents.length}');
      final accessMap = <String, int>{};
      for (var e in ents) {
        final a = (e['access_type'] ?? 'unknown').toString();
        accessMap[a] = (accessMap[a] ?? 0) + 1;
      }
      print('   Access Type breakdown: $accessMap');
    } catch (e) {
      print('   Entitlements query error: $e');
    }

    // 5. Audit Analytics Events
    print('\n5. ANALYTICS EVENTS (Telemetry):');
    try {
      final eventsRes = await SupabaseService.client
          .from('analytics_events')
          .select('id, event_name, event_id, user_id, device_id, platform, created_at');
      final events = List<Map<String, dynamic>>.from(eventsRes);
      print('   Total analytics_events rows: ${events.length}');
      final deviceIds = <String>{};
      final userIds = <String>{};
      final eventNameMap = <String, int>{};
      for (var ev in events) {
        final d = ev['device_id']?.toString();
        if (d != null && d.isNotEmpty) deviceIds.add(d);
        final u = ev['user_id']?.toString();
        if (u != null && u.isNotEmpty) userIds.add(u);
        final name = (ev['event_name'] ?? 'unknown').toString();
        eventNameMap[name] = (eventNameMap[name] ?? 0) + 1;
      }
      print('   Unique Tracked Devices: ${deviceIds.length}');
      print('   Unique Tracked Users:   ${userIds.length}');
      print('   Event breakdown: $eventNameMap');
    } catch (e) {
      print('   analytics_events query note: $e');
    }

    // 6. Audit Logs (fallback)
    print('\n6. AUDIT LOGS:');
    try {
      final logsRes = await SupabaseService.client
          .from('audit_logs')
          .select('id, action, user_id, created_at')
          .limit(100);
      final logs = List<Map<String, dynamic>>.from(logsRes);
      print('   Sample audit_logs count: ${logs.length}');
    } catch (e) {
      print('   audit_logs query note: $e');
    }

    print('\n================ AUDIT QUERY COMPLETE ================\n');
  });
}
