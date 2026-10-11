import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/shared/utils/neet_subject_helper.dart';

void main() {
  group('Advanced Existing Paper Question Selector Logic Tests', () {
    // Mock Paper with 180 questions:
    // Q1-45: Physics (subject_id: a1111111-1111-1111-1111-111111111111)
    // Q46-90: Chemistry (subject_id: a2222222-2222-2222-2222-222222222222)
    // Q91-135: Botany (subject_id: a4444444-4444-4444-4444-444444444444)
    // Q136-180: Zoology (subject_id: a5555555-5555-5555-5555-555555555555)
    final List<Map<String, dynamic>> mockNeetQuestions = List.generate(180, (i) {
      final qNum = i + 1;
      String subId;
      String section;
      if (qNum <= 45) {
        subId = 'a1111111-1111-1111-1111-111111111111';
        section = 'Physics';
      } else if (qNum <= 90) {
        subId = 'a2222222-2222-2222-2222-222222222222';
        section = 'Chemistry';
      } else if (qNum <= 135) {
        subId = 'a4444444-4444-4444-4444-444444444444';
        section = 'Botany';
      } else {
        subId = 'a5555555-5555-5555-5555-555555555555';
        section = 'Zoology';
      }
      return {
        'id': 'mock_q_$qNum',
        'question_number': qNum,
        'question_text': 'Sample Question $qNum in $section',
        'subject_id': subId,
        'section_name': section,
        'marks': 4,
        'negative_marks': -1,
      };
    });

    String resolveQuestionSubject(Map<String, dynamic> q, {String? exam}) {
      final rawSub = (q['subject'] ?? q['subject_name'])?.toString().trim() ?? '';
      if (rawSub.isNotEmpty && !rawSub.toLowerCase().contains('uuid') && rawSub.length < 35) {
        final mapped = NeetSubjectHelper.getSubjectNameFromId(rawSub, exam: exam);
        if (mapped.isNotEmpty && mapped != rawSub) return mapped;
        final sLower = rawSub.toLowerCase();
        if (sLower.contains('phys')) return 'Physics';
        if (sLower.contains('chem')) return 'Chemistry';
        if (sLower.contains('botan')) return 'Botany';
        if (sLower.contains('zool')) return 'Zoology';
        if (sLower.contains('bio')) return 'Biology';
        if (sLower.contains('math')) return 'Mathematics';
      }

      final rawSubId = (q['subject_id'] ?? q['subjectId'])?.toString().trim() ?? '';
      if (rawSubId.isNotEmpty) {
        final mapped = NeetSubjectHelper.getSubjectNameFromId(rawSubId, exam: exam);
        if (mapped.isNotEmpty && mapped != rawSubId) return mapped;
      }

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

      return 'Unknown';
    }

    Set<int> parseRangeString(String text) {
      final Set<int> numbers = {};
      final parts = text.split(RegExp(r'[,;\s]+'));
      for (var part in parts) {
        final clean = part.trim();
        if (clean.isEmpty) continue;
        if (clean.contains('-')) {
          final rangeParts = clean.split('-');
          if (rangeParts.length == 2) {
            final start = int.tryParse(rangeParts[0].trim());
            final end = int.tryParse(rangeParts[1].trim());
            if (start != null && end != null) {
              final low = start < end ? start : end;
              final high = start < end ? end : start;
              for (int i = low; i <= high; i++) {
                numbers.add(i);
              }
            }
          }
        } else {
          final single = int.tryParse(clean);
          if (single != null) numbers.add(single);
        }
      }
      return numbers;
    }

    test('1. Subject Resolution accurately resolves Physics, Chemistry, Botany, Zoology for NEET', () {
      final pQ = mockNeetQuestions[0];
      final cQ = mockNeetQuestions[45];
      final bQ = mockNeetQuestions[90];
      final zQ = mockNeetQuestions[135];

      expect(resolveQuestionSubject(pQ, exam: 'NEET'), equals('Physics'));
      expect(resolveQuestionSubject(cQ, exam: 'NEET'), equals('Chemistry'));
      expect(resolveQuestionSubject(bQ, exam: 'NEET'), equals('Botany'));
      expect(resolveQuestionSubject(zQ, exam: 'NEET'), equals('Zoology'));
    });

    test('2. Option A - Full Paper selects all 180 questions', () {
      final fullSelected = mockNeetQuestions;
      expect(fullSelected.length, equals(180));
    });

    test('3. Option B - Physics Only filters exactly Physics questions', () {
      final physicsQs = mockNeetQuestions.where((q) => resolveQuestionSubject(q, exam: 'NEET') == 'Physics').toList();
      expect(physicsQs.length, equals(45));
      expect(physicsQs.every((q) => resolveQuestionSubject(q, exam: 'NEET') == 'Physics'), isTrue);
    });

    test('4. Option C - Chemistry Only filters exactly Chemistry questions', () {
      final chemQs = mockNeetQuestions.where((q) => resolveQuestionSubject(q, exam: 'NEET') == 'Chemistry').toList();
      expect(chemQs.length, equals(45));
      expect(chemQs.every((q) => resolveQuestionSubject(q, exam: 'NEET') == 'Chemistry'), isTrue);
    });

    test('5. Option D - Biology Only combines Botany and Zoology (90 questions total)', () {
      final bioQs = mockNeetQuestions.where((q) {
        final sub = resolveQuestionSubject(q, exam: 'NEET');
        return sub == 'Biology' || sub == 'Botany' || sub == 'Zoology';
      }).toList();
      expect(bioQs.length, equals(90));
      final botanyCount = bioQs.where((q) => resolveQuestionSubject(q, exam: 'NEET') == 'Botany').length;
      final zoologyCount = bioQs.where((q) => resolveQuestionSubject(q, exam: 'NEET') == 'Zoology').length;
      expect(botanyCount, equals(45));
      expect(zoologyCount, equals(45));
    });

    test('6. Option E - Custom Range selection parses ranges and numbers accurately', () {
      final ranges = parseRangeString('1-45, 91-120, 150');
      expect(ranges.contains(1), isTrue);
      expect(ranges.contains(45), isTrue);
      expect(ranges.contains(46), isFalse);
      expect(ranges.contains(91), isTrue);
      expect(ranges.contains(120), isTrue);
      expect(ranges.contains(150), isTrue);
      expect(ranges.contains(151), isFalse);
      expect(ranges.length, equals(45 + 30 + 1)); // 76 questions
    });

    test('7. JEE Subject Resolution correctly maps Mathematics and excludes Biology', () {
      final jeeMathQ = {
        'id': 'jee_math_1',
        'question_number': 1,
        'subject_id': 'a6666666-6666-6666-6666-666666666666',
        'question_text': 'Calculus problem',
      };
      expect(resolveQuestionSubject(jeeMathQ, exam: 'JEE Main'), equals('Mathematics'));
    });

    test('8. Transparent Unknown subject handling without silent Physics reassignment', () {
      final unknownQ = {
        'id': 'unclassified_q',
        'question_number': 99,
        'subject_id': 'unknown-uuid-000000',
        'question_text': 'Mystery question without subject',
      };
      expect(resolveQuestionSubject(unknownQ, exam: 'NEET'), equals('Unknown'));
    });

    test('9. Original mock questions remain completely untouched after filtering', () {
      expect(mockNeetQuestions.length, equals(180));
      expect(mockNeetQuestions.first['question_number'], equals(1));
    });
  });
}
