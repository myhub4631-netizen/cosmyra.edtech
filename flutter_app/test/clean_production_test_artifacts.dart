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

  test('Clean Production Test Artifacts from system_config', () async {
    // 1. Clean admin_custom_papers
    final sysRes = await SupabaseService.client
        .from('system_config')
        .select('value')
        .eq('key', 'admin_custom_papers')
        .maybeSingle();

    if (sysRes != null && sysRes['value'] is List) {
      final List<Map<String, dynamic>> list = (sysRes['value'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final before = list.length;
      list.removeWhere((p) {
        final name = (p['paper_name'] ?? p['title'] ?? '').toString();
        final id = (p['id'] ?? p['paper_id'] ?? '').toString();
        return name.contains('Paper Recreated') ||
            name.contains('Disposable Test') ||
            id.startsWith('paper_recreate_') ||
            id.startsWith('paper_test_delete_');
      });

      print('admin_custom_papers before: $before, after: ${list.length}');

      await SupabaseService.client.from('system_config').upsert({
        'key': 'admin_custom_papers',
        'value': list,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');
      print('✓ Cleaned admin_custom_papers in system_config.');
    }

    // 2. Clean admin_custom_test_series
    final tsRes = await SupabaseService.client
        .from('system_config')
        .select('value')
        .eq('key', 'admin_custom_test_series')
        .maybeSingle();

    if (tsRes != null && tsRes['value'] is List) {
      final List<Map<String, dynamic>> list = (tsRes['value'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final before = list.length;
      list.removeWhere((s) {
        final name = (s['title'] ?? s['name'] ?? '').toString();
        final id = (s['id'] ?? '').toString();
        return name.contains('NEET 2026 Test Practice Paper') ||
            id.startsWith('paper_recreate_') ||
            id.startsWith('paper_test_delete_');
      });

      print('admin_custom_test_series before: $before, after: ${list.length}');

      await SupabaseService.client.from('system_config').upsert({
        'key': 'admin_custom_test_series',
        'value': list,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');
      print('✓ Cleaned admin_custom_test_series in system_config.');
    }

    // 3. Mark in admin_deleted_paper_ids
    await SupabaseService.markPaperAsDeleted('paper_recreate_1791659852799');
    print('✓ Marked paper_recreate_1791659852799 in admin_deleted_paper_ids.');
  });
}
