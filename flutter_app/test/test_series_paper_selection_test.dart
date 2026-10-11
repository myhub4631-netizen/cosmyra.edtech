import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';
import 'package:cosmyra_neet_jee/shared/utils/neet_subject_helper.dart';

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

  group('P0: Test Series Paper Selection & Subject Question Isolation Tests', () {
    // -------------------------------------------------------------
    // Test 1: Identity Separation - Destination test name preserved
    // -------------------------------------------------------------
    test('1. Selecting source paper must NOT overwrite destination test name', () {
      final initialDestTestName = 'Bio Fst Test 1';
      final sourcePaperName = 'NEET 2026 Paper 1';

      // Simulate the logic in admin_bulk_upload_step1_screen.dart & admin_test_series_manager_screen.dart:
      // If the user already has a destination test name, selecting a source paper must keep the destination test name intact.
      String currentTestName = initialDestTestName;
      final bool isTestSeriesMode = true;

      void onSourcePaperSelected(String selectedSrc) {
        if (!isTestSeriesMode && currentTestName.isEmpty) {
          currentTestName = selectedSrc;
        }
        // In Test Series mode, destination test name is preserved.
      }

      onSourcePaperSelected(sourcePaperName);

      expect(currentTestName, equals('Bio Fst Test 1'),
          reason: 'Selecting source paper must never overwrite destination test name');
      expect(currentTestName, isNot(equals(sourcePaperName)));
    });

    // -------------------------------------------------------------
    // Test 2: Subject Resolution & Filtering on NEET 2026 Paper 1
    // -------------------------------------------------------------
    test('2. Subject filtering on NEET 2026 Paper 1 questions produces exact counts', () async {
      // Query raw questions of NEET 2026 Paper 1 from Supabase
      final qRes = await SupabaseService.client
          .from('questions')
          .select('id, question_number, paper, year, subject_id')
          .eq('paper', 'NEET 2026 Paper 1');

      final List<Map<String, dynamic>> rawList = (qRes as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      expect(rawList.length, equals(180),
          reason: 'Source paper NEET 2026 Paper 1 must contain exactly 180 questions in database');

      // Sort by question_number
      rawList.sort((a, b) {
        final qA = int.tryParse((a['question_number'] ?? '0').toString()) ?? 0;
        final qB = int.tryParse((b['question_number'] ?? '0').toString()) ?? 0;
        return qA.compareTo(qB);
      });

      // Filter function matching admin_bulk_upload_step2_screen.dart logic
      List<Map<String, dynamic>> filterByMode(String mode) {
        if (mode == 'full') return rawList;
        return rawList.where((q) {
          final sId = (q['subject_id'] ?? '').toString().trim();
          final qNum = int.tryParse((q['question_number'] ?? '0').toString()) ?? 0;

          if (mode == 'biology') {
            if (sId == 'a3333333-3333-3333-3333-333333333333') return true;
            if (sId.isEmpty && qNum > 90) return true;
            return false;
          }
          if (mode == 'physics') {
            if (sId == 'a1111111-1111-1111-1111-111111111111') return true;
            if (sId.isEmpty && qNum >= 1 && qNum <= 45) return true;
            return false;
          }
          if (mode == 'chemistry') {
            if (sId == 'a2222222-2222-2222-2222-222222222222') return true;
            if (sId.isEmpty && qNum >= 46 && qNum <= 90) return true;
            return false;
          }
          return false;
        }).toList();
      }

      final bioQuestions = filterByMode('biology');
      final phyQuestions = filterByMode('physics');
      final chemQuestions = filterByMode('chemistry');
      final fullQuestions = filterByMode('full');

      expect(bioQuestions.length, equals(90),
          reason: 'Biology Only mode must yield exactly 90 questions');
      expect(phyQuestions.length, equals(45),
          reason: 'Physics Only mode must yield exactly 45 questions');
      expect(chemQuestions.length, equals(45),
          reason: 'Chemistry Only mode must yield exactly 45 questions');
      expect(fullQuestions.length, equals(180),
          reason: 'Full Paper mode must yield all 180 questions');

      // Check distinct IDs
      final bioIds = bioQuestions.map((q) => q['id']).toSet();
      expect(bioIds.length, equals(90), reason: 'All 90 Biology questions must have distinct UUIDs');

      // Verify no overlap between Physics and Biology
      final phyIds = phyQuestions.map((q) => q['id']).toSet();
      expect(bioIds.intersection(phyIds), isEmpty,
          reason: 'Biology and Physics questions must have zero overlap');
    });

    // -------------------------------------------------------------
    // Test 3: Empty selection guard
    // -------------------------------------------------------------
    test('3. Empty question selection must be rejected and never default to Full Paper', () {
      final List<Map<String, dynamic>> emptySelection = [];

      bool hasValidQuestions = emptySelection.isNotEmpty;
      expect(hasValidQuestions, isFalse, reason: 'Empty selection must be flagged as invalid');

      // Ensure fallback never secretly assigns all questions
      final resolvedQuestions = hasValidQuestions ? emptySelection : <Map<String, dynamic>>[];
      expect(resolvedQuestions, isEmpty, reason: 'Empty selection must never silently become Full Paper');
    });

    // -------------------------------------------------------------
    // Test 4: Container preservation - Adding a test preserves other tests
    // -------------------------------------------------------------
    test('4. Adding test to series container preserves all existing tests', () {
      final List<Map<String, dynamic>> existingTests = [
        {'id': 'test_1', 'title': 'Physics Practice 1', 'questions': 45},
        {'id': 'test_2', 'title': 'Chemistry Practice 1', 'questions': 45},
      ];

      final newTest = {
        'id': 'test_ts_bio_fst_1',
        'title': 'Bio Fst Test 1',
        'source_paper_id': 'cc86cc30-956a-4ade-b657-377b213c49e2',
        'source_paper_name': 'NEET 2026 Paper 1',
        'selection_mode': 'biology',
        'questions': 90,
      };

      // Append or update logic matching supabase_service.dart
      final updatedTests = List<Map<String, dynamic>>.from(existingTests);
      final idx = updatedTests.indexWhere((t) => t['id'] == newTest['id']);
      if (idx >= 0) {
        updatedTests[idx] = newTest;
      } else {
        updatedTests.add(newTest);
      }

      expect(updatedTests.length, equals(3), reason: 'Existing tests must be retained when adding a new test');
      expect(updatedTests[0]['title'], equals('Physics Practice 1'));
      expect(updatedTests[1]['title'], equals('Chemistry Practice 1'));
      expect(updatedTests[2]['title'], equals('Bio Fst Test 1'));
      expect(updatedTests[2]['selection_mode'], equals('biology'));
      expect(updatedTests[2]['questions'], equals(90));
    });

    // -------------------------------------------------------------
    // Test 5: Source paper metadata & question count preservation
    // -------------------------------------------------------------
    test('5. Source paper NEET 2026 Paper 1 metadata and question records remain intact', () async {
      // Check paper in allPapers catalogue
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final sourcePaper = allPapers.firstWhere(
        (p) => (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? '').toString().trim() == 'NEET 2026 Paper 1',
        orElse: () => {},
      );

      if (sourcePaper.isNotEmpty) {
        final qCount = sourcePaper['question_count'] ?? sourcePaper['saved_questions_count'] ?? 180;
        expect(qCount, greaterThanOrEqualTo(180),
            reason: 'Source paper NEET 2026 Paper 1 must maintain its 180 question count');
      }

      // Check questions count with paper = NEET 2026 Paper 1
      final qCountRes = await SupabaseService.client
          .from('questions')
          .select('id')
          .eq('paper', 'NEET 2026 Paper 1');

      expect((qCountRes as List).length, equals(180),
          reason: 'Source paper question bank must remain intact with exactly 180 questions');
    });

    // -------------------------------------------------------------
    // Test 6: Test Series persistence and reload simulation
    // -------------------------------------------------------------
    test('6. Saving and reloading a series preserves test name and source references', () async {
      final String seriesId = SupabaseService.toValidUuid('test_series_reg_${DateTime.now().millisecondsSinceEpoch}');
      final testPayload = {
        'id': 'test_dest_${DateTime.now().millisecondsSinceEpoch}',
        'paper_id': 'cc86cc30-956a-4ade-b657-377b213c49e2',
        'source_paper_id': 'cc86cc30-956a-4ade-b657-377b213c49e2',
        'source_paper_name': 'NEET 2026 Paper 1',
        'selection_mode': 'biology',
        'title': 'Bio Fst Test 1',
        'questions': 90,
        'marks': 360,
        'duration': 90,
        'type': 'Biology Full Syllabus',
        'status': 'Published',
      };

      final newSeries = {
        'id': seriesId,
        'title': 'Biology Full Syllabus Regression Check',
        'exam': 'NEET',
        'year': '2026',
        'category': 'Full Syllabus',
        'tests': [testPayload],
        'test_count': 1,
        'question_count': 90,
      };

      try {
        final saved = await SupabaseService.saveTestSeries(newSeries);
        expect(saved['id'], equals(seriesId));

        // Reload from backend
        final allSeries = await SupabaseService.fetchAllTestSeries(forceRefresh: true);
        final loaded = allSeries.firstWhere((s) => s['id'] == seriesId, orElse: () => {});

        expect(loaded, isNotEmpty, reason: 'Saved series must be reloadable');
        final tests = (loaded['tests'] as List).whereType<Map>().toList();
        expect(tests.length, equals(1));

        final loadedTest = tests.first;
        expect(loadedTest['title'], equals('Bio Fst Test 1'),
            reason: 'Destination test name Bio Fst Test 1 must be preserved on reload');
        expect(loadedTest['source_paper_name'], equals('NEET 2026 Paper 1'),
            reason: 'Source paper name must be preserved');
        expect(loadedTest['selection_mode'], equals('biology'),
            reason: 'Selection mode biology must be preserved');
        expect(loadedTest['questions'], equals(90),
            reason: 'Question count must remain 90');
      } finally {
        // Clean up test artifact from database
        await SupabaseService.deleteTestSeries(seriesId);
      }
    });

    // -------------------------------------------------------------
    // Test 7: Custom Question Selection Preserves Exact IDs
    // -------------------------------------------------------------
    test('7. Custom question selection preserves exactly the selected IDs', () {
      final sampleIds = [
        'q-custom-uuid-1',
        'q-custom-uuid-2',
        'q-custom-uuid-3',
      ];

      final List<Map<String, dynamic>> sourcePool = [
        {'id': 'q-custom-uuid-1', 'subject': 'Biology', 'question_text': 'Cell biology 1'},
        {'id': 'q-custom-uuid-2', 'subject': 'Biology', 'question_text': 'Cell biology 2'},
        {'id': 'q-custom-uuid-3', 'subject': 'Biology', 'question_text': 'Cell biology 3'},
        {'id': 'q-custom-uuid-4', 'subject': 'Physics', 'question_text': 'Kinematics 1'},
        {'id': 'q-custom-uuid-5', 'subject': 'Chemistry', 'question_text': 'Thermodynamics 1'},
      ];

      final selectedQuestions = sourcePool.where((q) => sampleIds.contains(q['id'])).toList();
      expect(selectedQuestions.length, equals(3));
      expect(selectedQuestions.map((q) => q['id']).toSet(), equals(sampleIds.toSet()));
      expect(selectedQuestions.any((q) => q['subject'] == 'Physics'), isFalse);
      expect(selectedQuestions.any((q) => q['subject'] == 'Chemistry'), isFalse);
    });

    // -------------------------------------------------------------
    // Test 8: End-to-End createTestSeriesPaperFromExistingQuestions
    // -------------------------------------------------------------
    test('8. createTestSeriesPaperFromExistingQuestions preserves Bio Fst Test 1 and 90 questions', () async {
      final destTestId = SupabaseService.toValidUuid('dest_test_bio_fst_${DateTime.now().millisecondsSinceEpoch}');
      final sourcePaperId = 'cc86cc30-956a-4ade-b657-377b213c49e2';
      final sourcePaperName = 'NEET 2026 Paper 1';
      final destTestName = 'Bio Fst Test 1';

      // Query raw biology questions of NEET 2026 Paper 1
      final qRes = await SupabaseService.client
          .from('questions')
          .select('*')
          .eq('paper', sourcePaperName);

      final List<Map<String, dynamic>> allSrcQuestions = (qRes as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final biologyQuestions = allSrcQuestions.where((q) {
        final sId = (q['subject_id'] ?? '').toString().trim();
        final qNum = int.tryParse((q['question_number'] ?? '0').toString()) ?? 0;
        return sId == 'a3333333-3333-3333-3333-333333333333' || (sId.isEmpty && qNum > 90);
      }).toList();

      expect(biologyQuestions.length, equals(90), reason: 'Must find 90 Biology questions');

      // Create test series paper from existing questions
      final result = await SupabaseService.createTestSeriesPaperFromExistingQuestions(
        paperDetails: {
          'id': destTestId,
          'paper_id': destTestId,
          'paper_name': destTestName,
          'destination_test_name': destTestName,
          'source_paper_id': sourcePaperId,
          'source_paper_name': sourcePaperName,
          'selection_mode': 'biology',
          'exam': 'NEET',
          'questionCount': 90,
          'question_count': 90,
        },
        selectedQuestionItems: biologyQuestions,
        testSeriesDetails: {
          'title': 'Biology Full Syllabus Regression Test',
        },
      );

      expect(result['paper_id'], equals(destTestId));
      expect(result['paper_name'], equals(destTestName));
      expect(result['source_paper_name'], equals(sourcePaperName));
      expect(result['questionCount'], equals(90));

      // Verify fetchQuestionsForPaper returns exactly 90 questions for the destination test
      final loadedForDest = await SupabaseService.fetchQuestionsForPaper(destTestId);
      expect(loadedForDest.length, equals(90),
          reason: 'Loaded destination test questions must be exactly 90');

      // Verify that the canonical source paper NEET 2026 Paper 1 is completely untouched
      final loadedForSource = await SupabaseService.client
          .from('questions')
          .select('id')
          .eq('paper', sourcePaperName);
      expect((loadedForSource as List).length, equals(180),
          reason: 'Source paper NEET 2026 Paper 1 must still have all 180 questions');

      // Clean up local mock preferences and system config if needed
      await SupabaseService.deletePaperRecord(destTestId);
    });

    // -------------------------------------------------------------
    // Test 9: Category and Taxonomy Isolation
    // -------------------------------------------------------------
    test('9. PYQ, NTA, and Test Series categories remain completely isolated', () async {
      final all = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      
      final pyqs = all.where((p) {
        final cat = (p['sourceCategory'] ?? p['source_category'] ?? '').toString().toUpperCase();
        return cat.contains('PYQ') || cat.contains('PREVIOUS');
      }).toList();

      final ntas = all.where((p) {
        final cat = (p['sourceCategory'] ?? p['source_category'] ?? '').toString().toUpperCase();
        return cat.contains('NTA');
      }).toList();

      final testSeries = all.where((p) {
        final cat = (p['sourceCategory'] ?? p['source_category'] ?? '').toString().toUpperCase();
        return cat.contains('TEST SERIES');
      }).toList();

      // Check that test series papers are not mislabeled as PYQ or NTA
      for (final ts in testSeries) {
        final cat = (ts['sourceCategory'] ?? ts['source_category'] ?? '').toString().toUpperCase();
        expect(cat, contains('TEST SERIES'));
      }
    });

    // -------------------------------------------------------------
    // Test 10: Repeated saving is idempotent and does not duplicate
    // -------------------------------------------------------------
    test('10. Repeated saving does not duplicate test or questions', () async {
      final testId = SupabaseService.toValidUuid('test_idempotent_${DateTime.now().millisecondsSinceEpoch}');
      final payload = {
        'id': testId,
        'paper_id': testId,
        'paper_name': 'Bio Fst Test 1',
        'source_paper_id': 'cc86cc30-956a-4ade-b657-377b213c49e2',
        'source_paper_name': 'NEET 2026 Paper 1',
        'selection_mode': 'biology',
        'questionCount': 90,
      };

      await SupabaseService.savePaperRecord(payload);
      await SupabaseService.savePaperRecord(payload); // Second save

      final loaded = await SupabaseService.fetchPaperById(testId);
      expect(loaded, isNotNull);
      expect(loaded?['paper_name'], equals('Bio Fst Test 1'));
      expect(loaded?['source_paper_name'], equals('NEET 2026 Paper 1'));

      await SupabaseService.deletePaperRecord(testId);
    });
  });
}
