import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_edu_flutter/models/models.dart';

void main() {
  group('Question Visibility (Available In) Unit Tests', () {
    test('QuestionModel default availableIn includes all 5 modules', () {
      final q = QuestionModel(
        id: 'q_test_1',
        examId: 'NEET',
        subjectId: 'Physics',
        chapterId: 'Kinematics',
        questionText: 'What is acceleration?',
        options: [],
      );

      expect(q.availableIn.length, equals(5));
      expect(q.availableIn, containsAll([
        'custom_practice',
        'custom_test',
        'pyq_practice',
        'nta_questions',
        'test_series',
      ]));
    });

    test('QuestionModel.fromJson parses custom available_in array correctly', () {
      final jsonMap = {
        'id': 'q_test_2',
        'exam_id': 'JEE Main',
        'subject_id': 'Chemistry',
        'chapter_id': 'Thermodynamics',
        'question_text': 'State the first law of thermodynamics.',
        'available_in': ['custom_practice', 'custom_test'],
        'options': [],
      };

      final q = QuestionModel.fromJson(jsonMap);
      expect(q.availableIn.length, equals(2));
      expect(q.availableIn, contains('custom_practice'));
      expect(q.availableIn, contains('custom_test'));
      expect(q.availableIn, isNot(contains('pyq_practice')));
    });

    test('QuestionModel.toJson includes available_in array', () {
      final q = QuestionModel(
        id: 'q_test_3',
        examId: 'JEE Advanced',
        subjectId: 'Mathematics',
        chapterId: 'Calculus',
        questionText: 'Evaluate the integral.',
        availableIn: ['pyq_practice', 'test_series'],
        options: [],
      );

      final jsonMap = q.toJson();
      expect(jsonMap['available_in'], equals(['pyq_practice', 'test_series']));
    });
  });
}
