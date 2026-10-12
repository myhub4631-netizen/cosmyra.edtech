import 'dart:io';
import 'dart:convert';
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

  group('Phase 4 Regression Tests: NEET FST 4 End-to-End', () {
    const neetFst4Id = 'bcca7a1c-8e68-414d-a01d-bcca8e68c14d';
    const bioFstV2SeriesId = 'd8f94798-6370-4d5c-a017-d8f963704d5c';
    const sourcePaperId = 'neet_2026_phase_1';
    const sourcePaperName = 'NEET 2026 Paper 1';

    test('1. Verify Destination Paper & Series Relationship in system_config', () async {
      final client = SupabaseService.client;
      final scRes = await client.from('system_config').select('value').eq('key', 'admin_custom_papers').single();
      final List papers = scRes['value'] is String ? jsonDecode(scRes['value']) : scRes['value'];
      final paper = papers.firstWhere((p) => p['id'] == neetFst4Id);

      expect(paper['id'], equals(neetFst4Id));
      expect(paper['paper_name'], equals('NEET FST 4'));
      expect(paper['source_paper_id'], equals(sourcePaperId));
      expect(paper['selection_mode'], equals('biology'));

      final tsRes = await client.from('system_config').select('value').eq('key', 'admin_custom_test_series').single();
      final List seriesList = tsRes['value'] is String ? jsonDecode(tsRes['value']) : tsRes['value'];
      final series = seriesList.firstWhere((s) => s['id'] == bioFstV2SeriesId);

      expect(series['title'], equals('BIO Fst v2'));
      final tests = series['tests'] as List;
      final neetFst4Test = tests.firstWhere((t) => t['id'] == neetFst4Id);

      expect(neetFst4Test['title'], equals('NEET FST 4'));
      expect(neetFst4Test['source_paper_id'], equals(sourcePaperId));
      expect(neetFst4Test['selection_mode'], equals('biology'));
      expect((neetFst4Test['question_ids'] as List).length, equals(90));
    });

    test('2. Source Paper NEET 2026 Paper 1 remains intact with all 180 questions', () async {
      final srcQuestions = await SupabaseService.fetchQuestionsForPaper(sourcePaperId, paperName: sourcePaperName);
      expect(srcQuestions.length, equals(180));
    });

    test('3. Student retrieval via fetchQuestionsForPaper returns exactly 90 distinct Biology questions', () async {
      final questions = await SupabaseService.fetchQuestionsForPaper(neetFst4Id, forceRefresh: true);
      expect(questions.length, equals(90));

      // Assert all 90 IDs are distinct
      final ids = questions.map((q) => q['id'].toString()).toSet();
      expect(ids.length, equals(90));

      // Assert sequential question numbers 1 to 90
      for (int i = 0; i < questions.length; i++) {
        expect(questions[i]['question_number'], equals(i + 1));
      }

      // Assert no Physics or Chemistry questions leaked
      for (final q in questions) {
        final sub = (q['subject'] ?? q['subject_name'] ?? '').toString().toLowerCase();
        final subId = (q['subject_id'] ?? '').toString();
        expect(
          sub.contains('bio') || sub.contains('botan') || sub.contains('zool') || subId == 'a3333333-3333-3333-3333-333333333333',
          isTrue,
          reason: 'Non-biology question found: $sub',
        );
        expect(sub.contains('phys'), isFalse);
        expect(sub.contains('chem'), isFalse);
      }
    });

    test('4. Student attempt loader fetchTestSeriesQuestions returns exactly 90 QuestionModels', () async {
      final models = await SupabaseService.fetchTestSeriesQuestions(paperId: neetFst4Id, forceRefresh: true);
      expect(models.length, equals(90));

      // Verify question options, answers, and data formatting
      for (int i = 0; i < models.length; i++) {
        final m = models[i];
        expect(m.questionNumber, equals(i + 1));
        expect(m.options.isNotEmpty, isTrue, reason: 'Question ${i + 1} has empty options');
        expect(m.questionText.isNotEmpty, isTrue, reason: 'Question ${i + 1} has empty text');
      }
    });

    test('5. Reopening/refreshing returns identical question set', () async {
      final firstLoad = await SupabaseService.fetchQuestionsForPaper(neetFst4Id, forceRefresh: true);
      final secondLoad = await SupabaseService.fetchQuestionsForPaper(neetFst4Id, forceRefresh: false);

      expect(firstLoad.length, equals(secondLoad.length));
      for (int i = 0; i < firstLoad.length; i++) {
        expect(firstLoad[i]['id'], equals(secondLoad[i]['id']));
        expect(firstLoad[i]['question_number'], equals(secondLoad[i]['question_number']));
      }
    });

    test('6. Genuinely empty test returns 0 questions without crashing', () async {
      final nonExistentQuestions = await SupabaseService.fetchQuestionsForPaper('non_existent_paper_uuid_12345', forceRefresh: true);
      expect(nonExistentQuestions.isEmpty, isTrue);
    });
  });

  group('Phase 4 Regression Tests: Bio FST v2 Paper Creation', () {
    const bioFstV2SeriesId = 'd8f94798-6370-4d5c-a017-d8f963704d5c';

    test('7. Create new test paper in Bio FST v2, persist question_ids, and verify retrieval', () async {
      // Fetch source questions
      final srcQuestions = await SupabaseService.fetchQuestionsForPaper('neet_2026_phase_1', paperName: 'NEET 2026 Paper 1');
      final bioQuestions = srcQuestions.where((q) {
        final rawNum = q['question_number'] ?? q['questionNumber'] ?? 0;
        final int qNum = rawNum is num ? rawNum.toInt() : int.tryParse(rawNum.toString()) ?? 0;
        return qNum >= 91 && qNum <= 180;
      }).toList();

      expect(bioQuestions.length, equals(90));

      final testPaperUniqueId = SupabaseService.toValidUuid('test_regression_${DateTime.now().millisecondsSinceEpoch}');
      final testPaperTitle = 'Bio FST v2 Practice Paper ${DateTime.now().millisecondsSinceEpoch % 1000}';

      final res = await SupabaseService.createTestSeriesPaperFromExistingQuestions(
        paperDetails: {
          'id': testPaperUniqueId,
          'paper_name': testPaperTitle,
          'destination_test_name': testPaperTitle,
          'source_paper_id': 'neet_2026_phase_1',
          'source_paper_name': 'NEET 2026 Paper 1',
          'selection_mode': 'biology',
          'exam': 'NEET',
          'year': 2026,
          'total_marks': 360,
          'duration_minutes': 90,
        },
        selectedQuestionItems: bioQuestions,
        testSeriesDetails: {
          'id': bioFstV2SeriesId,
          'title': 'BIO Fst v2',
        },
      );

      expect(res['success'], isTrue);
      expect(res['paperId'], equals(testPaperUniqueId));
      expect(res['paperName'], equals(testPaperTitle));

      // Verify retrieval
      final retrievedQuestions = await SupabaseService.fetchQuestionsForPaper(testPaperUniqueId, forceRefresh: true);
      expect(retrievedQuestions.length, equals(90));
      expect(retrievedQuestions.first['id'], equals(bioQuestions.first['id']));
      expect(retrievedQuestions.last['id'], equals(bioQuestions.last['id']));

      // Clean up the created regression paper from system_config so production stays clean
      final client = SupabaseService.client;
      final pRes = await client.from('system_config').select('value').eq('key', 'admin_custom_papers').single();
      final List papers = pRes['value'] is String ? jsonDecode(pRes['value']) : pRes['value'];
      final cleanedPapers = papers.where((p) => p['id'] != testPaperUniqueId).toList();
      await client.from('system_config').upsert({'key': 'admin_custom_papers', 'value': cleanedPapers});

      final tsRes = await client.from('system_config').select('value').eq('key', 'admin_custom_test_series').single();
      final List seriesList = tsRes['value'] is String ? jsonDecode(tsRes['value']) : tsRes['value'];
      for (var s in seriesList) {
        if (s['id'] == bioFstV2SeriesId && s['tests'] is List) {
          s['tests'] = (s['tests'] as List).where((t) => t['id'] != testPaperUniqueId).toList();
          s['test_count'] = (s['tests'] as List).length;
        }
      }
      await client.from('system_config').upsert({'key': 'admin_custom_test_series', 'value': seriesList});
    });
  });
}
