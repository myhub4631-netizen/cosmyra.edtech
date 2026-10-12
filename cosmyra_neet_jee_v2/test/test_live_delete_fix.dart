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

  test('Verify Delete Fix for Top-Level Test Series and Custom Papers in Production', () async {
    // 1. Create a disposable test paper in system_config
    final String disposableId = 'disposable_live_test_${DateTime.now().millisecondsSinceEpoch}';

    final saved = await SupabaseService.savePaperRecord({
      'id': disposableId,
      'paper_name': 'Disposable Delete Verification Paper',
      'exam': 'NEET',
      'year': '2026',
      'source_category': 'PYQ',
      'is_pyq': true,
      'status': 'Published',
    });
    expect(saved['id'], equals(disposableId));

    // Confirm it is returned in fetchAllPapersAndTestSeries
    var all = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
    var found = all.any((p) => (p['id'] ?? p['paper_id'] ?? '') == disposableId);
    expect(found, isTrue, reason: 'Disposable paper must be visible before delete');

    // 2. Call deletePaperRecord
    final delOk = await SupabaseService.deletePaperRecord(disposableId);
    expect(delOk, isTrue, reason: 'deletePaperRecord must return true on success');

    // 3. Verify it is gone from fetchAllPapersAndTestSeries
    all = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
    found = all.any((p) => (p['id'] ?? p['paper_id'] ?? '') == disposableId);
    expect(found, isFalse, reason: 'Deleted paper must not be present in fetchAllPapersAndTestSeries');

    // 4. Verify system_config in production does not contain the paper ID
    final sysRes = await SupabaseService.client
        .from('system_config')
        .select('key, value')
        .inFilter('key', ['admin_custom_papers', 'created_test_papers', 'admin_custom_test_series']);

    for (var row in (sysRes as List)) {
      final key = row['key'].toString();
      final val = row['value'];
      if (val is List) {
        final hasItem = val.any((item) {
          if (item is Map) {
            final id = (item['id'] ?? item['paper_id'] ?? '').toString();
            return id == disposableId;
          }
          return false;
        });
        expect(hasItem, isFalse, reason: 'Key "$key" in system_config must not contain deleted paper ID');
      }
    }
    print('✓ Verified deletePaperRecord removes top-level and embedded items from all persistence stores.');
  });
}
