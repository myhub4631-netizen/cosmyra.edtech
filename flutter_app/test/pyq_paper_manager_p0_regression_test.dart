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

  group('P0 Regression Tests: PYQ Paper Manager Catalogue & Question Counts', () {
    test('1. NEET 2026 Paper 1 appears in the PYQ catalogue exactly once', () async {
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final pyqs = allPapers.where((p) => SupabaseService.getPaperCatalogue(p) == 'PYQ').toList();

      final neet2026List = pyqs.where((p) {
        final id = (p['id'] ?? p['paper_id'] ?? '').toString();
        final title = (p['paper_name'] ?? p['title'] ?? '').toString();
        return id == 'neet_2026_phase_1' || title.contains('NEET 2026');
      }).toList();

      expect(neet2026List.length, equals(1), reason: 'NEET 2026 Paper 1 must appear exactly once in PYQ catalogue');
      final neet2026 = neet2026List.first;
      expect(neet2026['id'], equals('neet_2026_phase_1'));
      expect(neet2026['paper_name'], equals('NEET 2026 Paper 1'));
      expect(neet2026['exam'], equals('NEET'));
      expect(neet2026['year'], equals('2026'));
      expect(neet2026['source_category'], equals('PYQ'));
      expect(neet2026['is_pyq'], isTrue);
      expect(neet2026['is_test_series'], isNot(equals(true)));
    });

    test('2. Canonical record resolves to the correct paper identity and title', () async {
      final title = await SupabaseService.resolvePaperTitle('neet_2026_phase_1');
      expect(title, equals('NEET 2026 Paper 1'));
    });

    test('3. All 180 distinct linked questions are counted and duplicate aliases do not inflate count', () async {
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final neet2026 = allPapers.firstWhere((p) => p['id'] == 'neet_2026_phase_1');

      expect(neet2026['actual_questions_count'], equals(180));
      expect(neet2026['expected_question_count'], equals(180));
      expect(neet2026['saved_questions_count'], equals(180));

      // Verify fetchQuestionsForPaper returns 180 distinct questions
      final questions = await SupabaseService.fetchQuestionsForPaper('neet_2026_phase_1', forceRefresh: true);
      expect(questions.length, equals(180));
      final distinctIds = questions.map((q) => q['id']).toSet();
      expect(distinctIds.length, equals(180));
    });

    test('4. Subject distribution is 45 Physics, 45 Chemistry, 90 Biology', () async {
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final neet2026 = allPapers.firstWhere((p) => p['id'] == 'neet_2026_phase_1');
      final subjs = neet2026['subject_counts'] as Map<String, dynamic>?;

      expect(subjs, isNotNull);
      expect(subjs!['physics'], equals(45));
      expect(subjs['chemistry'], equals(45));
      expect(subjs['biology'], equals(90));
    });

    test('5. NEET 2022-2025 records remain visible with their correct configurations', () async {
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final pyqs = allPapers.where((p) => SupabaseService.getPaperCatalogue(p) == 'PYQ').toList();

      for (final y in ['2022', '2023', '2024', '2025']) {
        final paper = pyqs.firstWhere(
          (p) => (p['year'] ?? '').toString() == y && (p['id'] ?? '').toString().startsWith('neet_'),
          orElse: () => {},
        );
        expect(paper, isNotEmpty, reason: 'NEET $y record must remain visible in PYQ catalogue');
        expect(paper['expected_question_count'], equals(200));
        expect(paper['source_category'], equals('PYQ'));
      }
    });

    test('6. NTA and Test Series papers remain in their own tabs and do not leak into PYQ', () async {
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final pyqs = allPapers.where((p) => SupabaseService.getPaperCatalogue(p) == 'PYQ').toList();
      final ntas = allPapers.where((p) => SupabaseService.getPaperCatalogue(p) == 'NTA').toList();
      final testSeries = allPapers.where((p) => SupabaseService.getPaperCatalogue(p) == 'Test Series').toList();

      expect(pyqs.length, equals(5), reason: 'PYQ tab must have NEET 2022, 2023, 2024, 2025, 2026 Paper 1');
      expect(testSeries, isNotEmpty, reason: 'Test Series papers must be in their own tab');

      for (var p in pyqs) {
        final title = (p['paper_name'] ?? p['title'] ?? '').toString().toLowerCase();
        expect(title.contains('leader test series'), isFalse);
        expect(title.contains('full syllabus test series'), isFalse);
        expect(p['is_test_series'], isNot(equals(true)));
        expect(SupabaseService.isTestSeriesContainer(p), isFalse);
      }

      for (var ts in testSeries) {
        expect(ts['id'], isNot(equals('neet_2026_phase_1')));
      }
    });

    test('7. Deleted and tombstoned papers are excluded and not resurrected', () async {
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final deletedIds = await SupabaseService.getDeletedPaperIds();

      for (var p in allPapers) {
        final id = (p['id'] ?? p['paper_id'] ?? '').toString();
        expect(deletedIds.contains(id), isFalse, reason: 'Tombstoned id $id must not be present');
      }
    });

    test('8. Refresh preserves list and metrics idempotently', () async {
      final run1 = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final run2 = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);

      final pyqs1 = run1.where((p) => SupabaseService.getPaperCatalogue(p) == 'PYQ').toList();
      final pyqs2 = run2.where((p) => SupabaseService.getPaperCatalogue(p) == 'PYQ').toList();

      expect(pyqs1.length, equals(pyqs2.length));
      expect(pyqs1.map((p) => p['id']).toList(), equals(pyqs2.map((p) => p['id']).toList()));
    });
  });
}
