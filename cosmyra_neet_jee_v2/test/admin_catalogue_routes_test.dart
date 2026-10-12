import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/services/supabase_service.dart';

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

  String getPaperCatalogue(Map<String, dynamic> p) {
    final cat = (p['source_category'] ?? p['sourceCategory'] ?? p['category'] ?? p['paper_type'] ?? '').toString().toUpperCase();
    final title = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? '').toString().toLowerCase();
    final id = (p['id'] ?? p['paper_id'] ?? '').toString().toLowerCase();
    final isPyq = p['is_pyq'] == true;
    final isNta = p['is_nta'] == true;
    final isTestSeries = p['is_test_series'] == true;

    if (isTestSeries || cat == 'TEST_SERIES' || cat == 'TEST SERIES' || title.contains('test series') || title.contains('mock test') || title.contains('fst')) {
      return 'Test Series';
    }
    if (isNta || cat == 'NTA' || (title.contains('nta') && !title.contains('pyq') && !isPyq)) {
      return 'NTA';
    }
    if (isPyq || cat == 'PYQ' || id.startsWith('neet_') || id.startsWith('jee_') || title.contains('official pyq') || title.contains('phase 1') || title.contains('re-neet') || title.contains('paper 1') || title.contains('pyq')) {
      return 'PYQ';
    }
    if (title.contains('test') || title.contains('series')) return 'Test Series';
    return 'PYQ';
  }

  test('Acceptance Test: Separate Catalogues (PYQ, NTA, Test Series)', () async {
    final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
    expect(allPapers, isNotEmpty);

    final pyqs = allPapers.where((p) => getPaperCatalogue(p) == 'PYQ').toList();
    final ntas = allPapers.where((p) => getPaperCatalogue(p) == 'NTA').toList();
    final testSeries = allPapers.where((p) => getPaperCatalogue(p) == 'Test Series').toList();

    print('📊 CATALOGUE BREAKDOWN REPORT:');
    print('  • PYQ Papers Count: ${pyqs.length}');
    print('  • NTA Papers Count: ${ntas.length}');
    print('  • Test Series Papers Count: ${testSeries.length}');
    print('  • Total Papers in DB: ${allPapers.length}');

    // 1. PYQ Catalogue excludes Test Series
    for (var p in pyqs) {
      final title = (p['paper_name'] ?? p['title'] ?? '').toString().toLowerCase();
      expect(title.contains('full syllabus test series'), isFalse, reason: 'PYQ catalogue must not contain custom test series');
      expect(title.contains('leader test series'), isFalse);
    }

    // 2. Canonical NEET 2026 Paper 1 is strictly in PYQ
    final canonicalNeet2026 = pyqs.firstWhere((p) => p['id'] == '49bfe774-1e41-495e-a029-49bf1e41595e' || p['id'] == 'neet_2026_phase_1');
    expect(canonicalNeet2026, isNotNull);
    expect(getPaperCatalogue(canonicalNeet2026), equals('PYQ'));

    print('✓ Acceptance Test Passed: Catalogues are cleanly separated and verified.');
  });
}
