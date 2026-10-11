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

  group('P0 Test Series Data Isolation and CRUD Integrity Regression Tests', () {
    test('1. Production Biology Practice Sets must have 0 tests and no foreign papers', () async {
      final allSeries = await SupabaseService.fetchAllTestSeries(forceRefresh: true);
      final bioSeries = allSeries.firstWhere(
        (s) => (s['title'] ?? s['name'] ?? s['test_series_title'] ?? '').toString().toLowerCase().contains('biology'),
        orElse: () => {},
      );

      if (bioSeries.isNotEmpty) {
        final tests = bioSeries['tests'] as List?;
        expect(tests == null || tests.isEmpty, isTrue, reason: 'Biology Practice Sets must have 0 tests');
        expect(bioSeries['test_count'], equals(0), reason: 'test_count must be 0');
      }

      // Ensure no paper in DB is misattributed to Biology Practice Sets
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final contaminated = allPapers.where((p) {
        final ts = (p['existing_test_series'] ?? p['test_series_title'] ?? p['new_test_series_name'] ?? '').toString().toLowerCase();
        return ts.contains('biology practice sets');
      }).toList();
      expect(contaminated, isEmpty, reason: 'No global papers should be claimed by Biology Practice Sets');
    });

    test('2. Independent Test Series Creation must start with 0 tests', () async {
      final String seriesId = 'test_series_isolation_${DateTime.now().millisecondsSinceEpoch}';
      final newSeries = {
        'id': seriesId,
        'title': 'Isolated Chemistry Practice Sets',
        'exam': 'NEET',
        'year': '2026',
        'category': 'Full Syllabus',
        'tests': <Map<String, dynamic>>[],
        'test_count': 0,
        'question_count': 0,
      };

      final saved = await SupabaseService.saveTestSeries(newSeries);
      expect(saved['id'], equals(seriesId));
      expect(saved['tests'], isEmpty, reason: 'New series must have empty tests array');
      expect(saved['test_count'], equals(0));

      // Verify in fetchAllTestSeries
      final all = await SupabaseService.fetchAllTestSeries(forceRefresh: true);
      final found = all.firstWhere((s) => s['id'] == seriesId, orElse: () => {});
      expect(found, isNotEmpty);
      expect((found['tests'] as List).length, equals(0));
      expect(found['test_count'], equals(0));

      // Cleanup
      await SupabaseService.deleteTestSeries(seriesId);
    });

    test('3. Test Removal from series must persist without restoration', () async {
      final String seriesId = 'test_removal_persist_${DateTime.now().millisecondsSinceEpoch}';
      final initialSeries = {
        'id': seriesId,
        'title': 'Test Series Removal Persistence Check',
        'exam': 'NEET',
        'year': '2026',
        'tests': [
          {'id': 't1', 'paper_id': 't1', 'title': 'Test 1', 'questions': 45},
          {'id': 't2', 'paper_id': 't2', 'title': 'Test 2', 'questions': 45},
          {'id': 't3', 'paper_id': 't3', 'title': 'Test 3', 'questions': 45},
        ],
        'test_count': 3,
        'question_count': 135,
      };

      await SupabaseService.saveTestSeries(initialSeries);

      // Verify initial state has 3 tests
      var all = await SupabaseService.fetchAllTestSeries(forceRefresh: true);
      var current = all.firstWhere((s) => s['id'] == seriesId);
      expect((current['tests'] as List).length, equals(3));

      // Now remove Test 2 and Test 3 (leaving only Test 1)
      final updatedSeries = {
        ...current,
        'tests': [
          {'id': 't1', 'paper_id': 't1', 'title': 'Test 1', 'questions': 45},
        ],
        'test_count': 1,
        'question_count': 45,
      };

      await SupabaseService.saveTestSeries(updatedSeries);

      // Verify that removal persisted and tests was NOT restored to 3!
      all = await SupabaseService.fetchAllTestSeries(forceRefresh: true);
      current = all.firstWhere((s) => s['id'] == seriesId);
      expect((current['tests'] as List).length, equals(1), reason: 'Removed tests must stay removed');
      expect((current['tests'] as List).first['id'], equals('t1'));
      expect(current['test_count'], equals(1));

      // Cleanup
      await SupabaseService.deleteTestSeries(seriesId);
    });

    test('4. Removing paper from a series must NOT delete the global paper or questions', () async {
      final String paperId = 'global_paper_preserve_${DateTime.now().millisecondsSinceEpoch}';
      final String seriesId = 'test_series_preserve_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Create a global paper
      await SupabaseService.savePaperRecord({
        'id': paperId,
        'paper_name': 'Preserved Global Paper',
        'exam': 'NEET',
        'year': '2026',
        'source_category': 'Test Series',
        'is_test_series': true,
        'status': 'Published',
      });

      // 2. Add it to a series
      await SupabaseService.saveTestSeries({
        'id': seriesId,
        'title': 'Series with Global Paper',
        'exam': 'NEET',
        'year': '2026',
        'tests': [
          {'id': paperId, 'paper_id': paperId, 'title': 'Preserved Global Paper', 'questions': 90},
        ],
        'test_count': 1,
      });

      // 3. Remove paper from the series
      await SupabaseService.saveTestSeries({
        'id': seriesId,
        'title': 'Series with Global Paper',
        'exam': 'NEET',
        'year': '2026',
        'tests': <Map<String, dynamic>>[],
        'test_count': 0,
      });

      // 4. Verify global paper still exists in catalogue!
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final paperStillExists = allPapers.any((p) => (p['id'] ?? p['paper_id'] ?? '') == paperId);
      expect(paperStillExists, isTrue, reason: 'Removing from a series must not delete the underlying global paper');

      // Cleanup
      await SupabaseService.deletePaperRecord(paperId);
      await SupabaseService.deleteTestSeries(seriesId);
    });

    test('5. Two independent test series must maintain strict isolation', () async {
      final String seriesAId = 'series_a_${DateTime.now().millisecondsSinceEpoch}';
      final String seriesBId = 'series_b_${DateTime.now().millisecondsSinceEpoch}';

      await SupabaseService.saveTestSeries({
        'id': seriesAId,
        'title': 'Series Alpha',
        'exam': 'NEET',
        'year': '2026',
        'tests': [
          {'id': 'a1', 'title': 'Alpha Test 1', 'questions': 50},
        ],
        'test_count': 1,
      });

      await SupabaseService.saveTestSeries({
        'id': seriesBId,
        'title': 'Series Beta',
        'exam': 'NEET',
        'year': '2026',
        'tests': [
          {'id': 'b1', 'title': 'Beta Test 1', 'questions': 50},
          {'id': 'b2', 'title': 'Beta Test 2', 'questions': 50},
        ],
        'test_count': 2,
      });

      var all = await SupabaseService.fetchAllTestSeries(forceRefresh: true);
      var seriesA = all.firstWhere((s) => s['id'] == seriesAId);
      var seriesB = all.firstWhere((s) => s['id'] == seriesBId);

      expect((seriesA['tests'] as List).length, equals(1));
      expect((seriesB['tests'] as List).length, equals(2));

      // Update series A only
      await SupabaseService.saveTestSeries({
        ...seriesA,
        'tests': [
          {'id': 'a1', 'title': 'Alpha Test 1', 'questions': 50},
          {'id': 'a2', 'title': 'Alpha Test 2', 'questions': 50},
        ],
        'test_count': 2,
      });

      all = await SupabaseService.fetchAllTestSeries(forceRefresh: true);
      seriesA = all.firstWhere((s) => s['id'] == seriesAId);
      seriesB = all.firstWhere((s) => s['id'] == seriesBId);

      expect((seriesA['tests'] as List).length, equals(2));
      expect((seriesB['tests'] as List).length, equals(2), reason: 'Series B must remain untouched');

      // Cleanup
      await SupabaseService.deleteTestSeries(seriesAId);
      await SupabaseService.deleteTestSeries(seriesBId);
    });
  });
}
