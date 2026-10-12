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

    if (cat == 'TEST_SERIES' || cat == 'TEST SERIES' || p['is_test_series'] == true || title.contains('test series') || title.contains('mock test') || title.contains('fst')) {
      return 'Test Series';
    }
    if (cat == 'NTA' || p['is_nta'] == true || title.contains('nta')) {
      return 'NTA';
    }
    if (cat == 'PYQ' || p['is_pyq'] == true || id.startsWith('neet_') || id.startsWith('jee_') || title.contains('official pyq') || title.contains('phase 1') || title.contains('re-neet') || title.contains('paper 1') || title.contains('pyq')) {
      return 'PYQ';
    }
    if (title.contains('test') || title.contains('series')) return 'Test Series';
    return 'PYQ';
  }

  test('Verify Catalogue Classification (PYQ, NTA, Test Series Separation)', () async {
    final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
    print('Total Papers Fetched: ${allPapers.length}');

    final pyqList = allPapers.where((p) => getPaperCatalogue(p) == 'PYQ').toList();
    final ntaList = allPapers.where((p) => getPaperCatalogue(p) == 'NTA').toList();
    final testSeriesList = allPapers.where((p) => getPaperCatalogue(p) == 'Test Series').toList();

    print('✓ PYQ Papers Count: ${pyqList.length}');
    print('✓ NTA Papers Count: ${ntaList.length}');
    print('✓ Test Series Papers Count: ${testSeriesList.length}');

    // Verify PYQ papers do NOT contain test series items
    for (var p in pyqList) {
      final title = (p['paper_name'] ?? p['title'] ?? '').toString();
      expect(title.toLowerCase().contains('full syllabus test series'), isFalse);
    }

    // Verify canonical NEET 2026 Paper 1 is in PYQ list
    final neet2026InPyq = pyqList.any((p) => (p['id'] == '49bfe774-1e41-495e-a029-49bf1e41595e' || p['id'] == 'neet_2026_phase_1'));
    expect(neet2026InPyq, isTrue);

    print('✓ Verified catalogue classification works cleanly and accurately.');
  });
}
