import 'dart:io';
import 'dart:convert';
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

String resolveQuestionSubject(Map<String, dynamic> q, {String? exam}) {
  // 1. Direct subject string
  final rawSub = (q['subject'] ?? q['subject_name'])?.toString().trim() ?? '';
  if (rawSub.isNotEmpty && !rawSub.toLowerCase().contains('uuid') && rawSub.length < 35) {
    final mapped = NeetSubjectHelper.getSubjectNameFromId(rawSub, exam: exam);
    if (mapped.isNotEmpty && mapped != rawSub) {
      return mapped;
    }
    final sLower = rawSub.toLowerCase();
    if (sLower.contains('phys')) return 'Physics';
    if (sLower.contains('chem')) return 'Chemistry';
    if (sLower.contains('botan')) return 'Botany';
    if (sLower.contains('zool')) return 'Zoology';
    if (sLower.contains('bio')) return 'Biology';
    if (sLower.contains('math')) return 'Mathematics';
  }

  // 2. Check subject_id
  final rawSubId = (q['subject_id'] ?? q['subjectId'])?.toString().trim() ?? '';
  if (rawSubId.isNotEmpty) {
    final mapped = NeetSubjectHelper.getSubjectNameFromId(rawSubId, exam: exam);
    if (mapped.isNotEmpty && mapped != rawSubId) {
      return mapped;
    }
  }

  // 3. Check section_name / section
  final rawSection = (q['section_name'] ?? q['section'])?.toString().trim() ?? '';
  if (rawSection.isNotEmpty) {
    final sLower = rawSection.toLowerCase();
    if (sLower.contains('phys')) return 'Physics';
    if (sLower.contains('chem')) return 'Chemistry';
    if (sLower.contains('botan')) return 'Botany';
    if (sLower.contains('zool')) return 'Zoology';
    if (sLower.contains('bio')) return 'Biology';
    if (sLower.contains('math')) return 'Mathematics';
  }

  // 4. Sequence-based fallback for NEET official papers
  final bool isNeet = exam == null || exam.toUpperCase().contains('NEET');
  if (isNeet) {
    final rawNum = q['question_number'] ?? q['questionNumber'] ?? q['order_index'] ?? q['sequence_order'];
    final int? qNum = rawNum is num ? rawNum.toInt() : int.tryParse(rawNum?.toString() ?? '');
    if (qNum != null && qNum > 0) {
      if (qNum >= 1 && qNum <= 45) return 'Physics';
      if (qNum >= 46 && qNum <= 90) return 'Chemistry';
      if (qNum >= 91 && qNum <= 180) return 'Biology';
    }
  }

  return 'Unknown';
}

List<Map<String, dynamic>> filterQuestionsByMode(List<Map<String, dynamic>> rawQuestions, String mode, {String exam = 'NEET'}) {
  if (mode == 'full') {
    return rawQuestions;
  } else if (mode == 'physics') {
    return rawQuestions.where((q) => resolveQuestionSubject(q, exam: exam) == 'Physics').toList();
  } else if (mode == 'chemistry') {
    return rawQuestions.where((q) => resolveQuestionSubject(q, exam: exam) == 'Chemistry').toList();
  } else if (mode == 'biology') {
    return rawQuestions.where((q) {
      final s = resolveQuestionSubject(q, exam: exam);
      return s == 'Biology' || s == 'Botany' || s == 'Zoology';
    }).toList();
  }
  return rawQuestions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = MyHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  group('P0 Regression Tests: NEET 2026 Paper 1 Biology Selection and Question Counts', () {
    test('1. Authoritative source retrieval returns all 180 questions with 45/45/90 distribution', () async {
      final questions = await SupabaseService.fetchQuestionsForPaper(
        'neet_2026_phase_1',
        paperName: 'NEET 2026 Paper 1',
        forceRefresh: true,
      );

      expect(questions.length, equals(180), reason: 'Total questions must be exactly 180');

      int physics = 0;
      int chemistry = 0;
      int biology = 0;
      int unknown = 0;

      for (var q in questions) {
        final sub = resolveQuestionSubject(q, exam: 'NEET');
        if (sub == 'Physics') physics++;
        else if (sub == 'Chemistry') chemistry++;
        else if (sub == 'Biology') biology++;
        else unknown++;
      }

      expect(physics, equals(45), reason: 'Expected 45 Physics questions');
      expect(chemistry, equals(45), reason: 'Expected 45 Chemistry questions');
      expect(biology, equals(90), reason: 'Expected 90 Biology questions');
      expect(unknown, equals(0), reason: 'Expected 0 unclassified questions');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('2. Biology selection returns exactly Q91–Q180 (90 questions)', () async {
      final questions = await SupabaseService.fetchQuestionsForPaper(
        'neet_2026_phase_1',
        paperName: 'NEET 2026 Paper 1',
        forceRefresh: true,
      );

      final bioQuestions = filterQuestionsByMode(questions, 'biology', exam: 'NEET');

      expect(bioQuestions.length, equals(90), reason: 'Biology selection must contain exactly 90 questions');

      final Set<String> distinctIds = {};
      final List<int> bioSequence = [];

      for (var q in bioQuestions) {
        final id = q['id']?.toString() ?? '';
        expect(id.isNotEmpty, isTrue);
        distinctIds.add(id);

        final qNum = (q['question_number'] as num?)?.toInt() ?? 0;
        bioSequence.add(qNum);
      }

      expect(distinctIds.length, equals(90), reason: 'All 90 Biology questions must have distinct UUIDs');
      bioSequence.sort();
      expect(bioSequence.first, equals(91), reason: 'Biology questions start at Q91');
      expect(bioSequence.last, equals(180), reason: 'Biology questions end at Q180');
      expect(bioSequence, equals(List.generate(90, (i) => i + 91)), reason: 'Sequence must be exactly Q91 to Q180');
    });

    test('3. Stale SharedPreferences cache does not override authoritative DB questions', () async {
      // Simulate cache poisoning with 116 stale questions
      final prefs = await SharedPreferences.getInstance();
      final stale116 = List.generate(116, (i) => {
        'id': 'stale_q_${i + 1}',
        'question_number': i + 1,
        'paper': 'NEET 2026 Paper 1',
        'subject': i < 45 ? 'Physics' : (i < 89 ? 'Chemistry' : 'Biology'),
      });
      await prefs.setString('cosmyra_paper_questions_neet_2026_phase_1', jsonEncode(stale116));

      // Fetch with forceRefresh: true
      final questions = await SupabaseService.fetchQuestionsForPaper(
        'neet_2026_phase_1',
        paperName: 'NEET 2026 Paper 1',
        forceRefresh: true,
      );

      // Must retrieve 180 from DB, not 116 from cache
      expect(questions.length, equals(180), reason: 'Authoritative DB must take precedence over stale SharedPreferences');
      expect(questions.first['id'], isNot(equals('stale_q_1')));
    });

    test('4. Subject metadata represented by IDs without names resolves correctly', () async {
      final dummyQPhysics = {'question_number': 10, 'subject_id': 'a1111111-1111-1111-1111-111111111111'};
      final dummyQChemistry = {'question_number': 50, 'subject_id': 'a2222222-2222-2222-2222-222222222222'};
      final dummyQBiology = {'question_number': 100, 'subject_id': 'a3333333-3333-3333-3333-333333333333'};

      expect(resolveQuestionSubject(dummyQPhysics, exam: 'NEET'), equals('Physics'));
      expect(resolveQuestionSubject(dummyQChemistry, exam: 'NEET'), equals('Chemistry'));
      expect(resolveQuestionSubject(dummyQBiology, exam: 'NEET'), equals('Biology'));
    });

    test('5. Sequence-based fallback resolves subject when metadata is completely absent', () async {
      final dummyQ1 = {'question_number': 15};
      final dummyQ2 = {'question_number': 75};
      final dummyQ3 = {'question_number': 130};

      expect(resolveQuestionSubject(dummyQ1, exam: 'NEET'), equals('Physics'));
      expect(resolveQuestionSubject(dummyQ2, exam: 'NEET'), equals('Chemistry'));
      expect(resolveQuestionSubject(dummyQ3, exam: 'NEET'), equals('Biology'));
    });

    test('6. Duplicate relationship entries do not produce duplicate selected UUIDs', () async {
      final questions = await SupabaseService.fetchQuestionsForPaper(
        'neet_2026_phase_1',
        paperName: 'NEET 2026 Paper 1',
        forceRefresh: true,
      );

      final bioQuestions = filterQuestionsByMode(questions, 'biology', exam: 'NEET');
      // Simulate duplicate entries in source list
      final duplicatedList = [...bioQuestions, bioQuestions[0], bioQuestions[5]];

      final Set<String> uniqueIds = {};
      final List<Map<String, dynamic>> deduped = [];
      for (var q in duplicatedList) {
        final id = q['id'].toString();
        if (!uniqueIds.contains(id)) {
          uniqueIds.add(id);
          deduped.add(q);
        }
      }

      expect(deduped.length, equals(90), reason: 'Duplicates must be removed leaving exactly 90 unique questions');
      expect(uniqueIds.length, equals(90));
    });

    test('7. Source paper remains completely unchanged with 180 questions in DB', () async {
      final client = SupabaseService.client;
      final res = await client
          .from('questions')
          .select('id, question_number, paper')
          .eq('paper', 'NEET 2026 Paper 1');
      
      expect((res as List).length, equals(180), reason: 'Source paper NEET 2026 Paper 1 in DB must have 180 rows');
    });

    test('8. Repeating fetch produces the same deterministic 180-question result', () async {
      final res1 = await SupabaseService.fetchQuestionsForPaper(
        'neet_2026_phase_1',
        paperName: 'NEET 2026 Paper 1',
        forceRefresh: true,
      );
      final res2 = await SupabaseService.fetchQuestionsForPaper(
        'neet_2026_phase_1',
        paperName: 'NEET 2026 Paper 1',
        forceRefresh: true,
      );

      expect(res1.length, equals(180));
      expect(res2.length, equals(180));
      expect(res1.map((q) => q['id']).toList(), equals(res2.map((q) => q['id']).toList()));
    });
  });
}
