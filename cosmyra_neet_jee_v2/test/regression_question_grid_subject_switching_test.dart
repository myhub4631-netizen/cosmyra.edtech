import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/models/models.dart';
import 'package:cosmyra_neet_jee/features/tests/test_screen.dart';
import 'package:cosmyra_neet_jee/shared/utils/neet_subject_helper.dart';

void main() {
  List<QuestionOptionModel> makeMockOptions(String qId) {
    return [
      QuestionOptionModel(id: 'opt_${qId}_1', questionId: qId, optionIndex: 0, optionText: 'Option A', isCorrect: true),
      QuestionOptionModel(id: 'opt_${qId}_2', questionId: qId, optionIndex: 1, optionText: 'Option B', isCorrect: false),
      QuestionOptionModel(id: 'opt_${qId}_3', questionId: qId, optionIndex: 2, optionText: 'Option C', isCorrect: false),
      QuestionOptionModel(id: 'opt_${qId}_4', questionId: qId, optionIndex: 3, optionText: 'Option D', isCorrect: false),
    ];
  }

  group('NEET Subject Mapping & Combining Botany/Zoology Regression Tests', () {
    test('1. Standard 180 questions NEET test maps Botany and Zoology into Biology without duplicates', () {
      final List<QuestionModel> questions = [];
      // 45 Physics
      for (int i = 1; i <= 45; i++) {
        questions.add(QuestionModel(
          id: 'p_$i',
          examId: 'neet',
          subjectId: 'Physics',
          chapterId: 'chap_p',
          questionNumber: i,
          questionText: 'Physics Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('p_$i'),
        ));
      }
      // 45 Chemistry
      for (int i = 46; i <= 90; i++) {
        questions.add(QuestionModel(
          id: 'c_$i',
          examId: 'neet',
          subjectId: 'Chemistry',
          chapterId: 'chap_c',
          questionNumber: i,
          questionText: 'Chemistry Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('c_$i'),
        ));
      }
      // 45 Botany
      for (int i = 91; i <= 135; i++) {
        questions.add(QuestionModel(
          id: 'bot_$i',
          examId: 'neet',
          subjectId: 'Botany',
          chapterId: 'chap_bot',
          questionNumber: i,
          questionText: 'Botany Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('bot_$i'),
        ));
      }
      // 45 Zoology
      for (int i = 136; i <= 180; i++) {
        questions.add(QuestionModel(
          id: 'zoo_$i',
          examId: 'neet',
          subjectId: 'Zoology',
          chapterId: 'chap_zoo',
          questionNumber: i,
          questionText: 'Zoology Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('zoo_$i'),
        ));
      }

      expect(questions.length, equals(180));

      // Test getQuestionIndicesForSubject
      final physicsIndices = NeetSubjectHelper.getQuestionIndicesForSubject(
        subject: 'Physics',
        totalQuestions: questions.length,
        questions: questions,
      );
      final chemistryIndices = NeetSubjectHelper.getQuestionIndicesForSubject(
        subject: 'Chemistry',
        totalQuestions: questions.length,
        questions: questions,
      );
      final biologyIndices = NeetSubjectHelper.getQuestionIndicesForSubject(
        subject: 'Biology',
        totalQuestions: questions.length,
        questions: questions,
      );

      // Verify counts
      expect(physicsIndices.length, equals(45));
      expect(chemistryIndices.length, equals(45));
      expect(biologyIndices.length, equals(90)); // Combines 45 Botany + 45 Zoology

      // Verify Biology order preserves original sequence: 90 through 179
      for (int i = 0; i < 90; i++) {
        expect(biologyIndices[i], equals(90 + i));
      }

      // Verify no duplicates across subjects
      final allIndices = <int>{...physicsIndices, ...chemistryIndices, ...biologyIndices};
      expect(allIndices.length, equals(180));
      expect(physicsIndices.toSet().intersection(chemistryIndices.toSet()), isEmpty);
      expect(physicsIndices.toSet().intersection(biologyIndices.toSet()), isEmpty);
      expect(chemistryIndices.toSet().intersection(biologyIndices.toSet()), isEmpty);
    });

    test('2. 90-question Biology-only test displays all 90 questions without duplicates', () {
      final List<QuestionModel> questions = [];
      // 45 Botany + 45 Zoology in a 90 question test
      for (int i = 1; i <= 45; i++) {
        questions.add(QuestionModel(
          id: 'bot_$i',
          examId: 'neet',
          subjectId: 'Botany',
          chapterId: 'chap_bot',
          questionNumber: i,
          questionText: 'Botany Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('bot_$i'),
        ));
      }
      for (int i = 46; i <= 90; i++) {
        questions.add(QuestionModel(
          id: 'zoo_$i',
          examId: 'neet',
          subjectId: 'Zoology',
          chapterId: 'chap_zoo',
          questionNumber: i,
          questionText: 'Zoology Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('zoo_$i'),
        ));
      }

      final bioIndices = NeetSubjectHelper.getQuestionIndicesForSubject(
        subject: 'Biology',
        totalQuestions: questions.length,
        questions: questions,
      );

      expect(bioIndices.length, equals(90));
      expect(bioIndices, equals(List.generate(90, (i) => i)));
    });

    test('3. Canonical metadata is prioritized over index ranges without guessing', () {
      // Single question test with explicit subject 'Biology' at index 0
      final questions = [
        QuestionModel(
          id: 'bio_q0',
          examId: 'neet',
          subjectId: 'Biology',
          chapterId: 'chap_bio',
          questionNumber: 1,
          questionText: 'Standalone Biology Question',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('bio_q0'),
        ),
      ];

      final physIndices = NeetSubjectHelper.getQuestionIndicesForSubject(
        subject: 'Physics',
        totalQuestions: 1,
        questions: questions,
      );
      final bioIndices = NeetSubjectHelper.getQuestionIndicesForSubject(
        subject: 'Biology',
        totalQuestions: 1,
        questions: questions,
      );

      expect(physIndices, isEmpty);
      expect(bioIndices, equals([0]));
    });
  });

  group('Question Grid View Widget & Subject Stability Tests', () {
    List<QuestionModel> createTestQuestions() {
      final List<QuestionModel> questions = [];
      // 5 Physics (0..4)
      for (int i = 1; i <= 5; i++) {
        questions.add(QuestionModel(
          id: 'p_$i',
          examId: 'neet',
          subjectId: 'Physics',
          chapterId: 'chap_p',
          questionNumber: i,
          questionText: 'Physics Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('p_$i'),
        ));
      }
      // 5 Chemistry (5..9)
      for (int i = 6; i <= 10; i++) {
        questions.add(QuestionModel(
          id: 'c_$i',
          examId: 'neet',
          subjectId: 'Chemistry',
          chapterId: 'chap_c',
          questionNumber: i,
          questionText: 'Chemistry Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('c_$i'),
        ));
      }
      // 5 Botany (10..14)
      for (int i = 11; i <= 15; i++) {
        questions.add(QuestionModel(
          id: 'bot_$i',
          examId: 'neet',
          subjectId: 'Botany',
          chapterId: 'chap_bot',
          questionNumber: i,
          questionText: 'Botany Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('bot_$i'),
        ));
      }
      // 5 Zoology (15..19)
      for (int i = 16; i <= 20; i++) {
        questions.add(QuestionModel(
          id: 'zoo_$i',
          examId: 'neet',
          subjectId: 'Zoology',
          chapterId: 'chap_zoo',
          questionNumber: i,
          questionText: 'Zoology Question $i',
          marks: 4,
          negativeMarks: 1,
          options: makeMockOptions('zoo_$i'),
        ));
      }
      return questions;
    }

    testWidgets('Opening grid shows exactly 3 tabs: Physics, Chemistry, Biology; selecting Chemistry/Biology stays stable across rebuilds', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final questions = createTestQuestions();

      await tester.pumpWidget(
        MaterialApp(
          home: CustomTestScreen(
            questions: questions,
            durationMinutes: 60,
            isPreview: true,
            onTestSubmitted: (attempt, answers) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify grid icon is present
      final gridBtnFinder = find.byTooltip('Grid View / Question Palette');
      expect(gridBtnFinder, findsOneWidget);

      // Open Grid View Modal
      await tester.tap(gridBtnFinder);
      await tester.pumpAndSettle();

      // Verify title '< Grid View'
      expect(find.text('Grid View'), findsOneWidget);

      // Verify Subject Switcher Tabs: Exactly 3 tabs: Physics, Chemistry, Biology
      expect(find.text('Physics'), findsWidgets);
      expect(find.text('Chemistry'), findsOneWidget);
      expect(find.text('Biology'), findsOneWidget);
      expect(find.text('Botany'), findsNothing);
      expect(find.text('Zoology'), findsNothing);

      // Verify initially Physics questions (1 to 5) are shown in GridView
      expect(find.descendant(of: find.byType(GridView), matching: find.text('1')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('5')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('6')), findsNothing); // Question 6 is Chemistry

      // Tap Chemistry Tab
      await tester.tap(find.text('Chemistry'));
      await tester.pumpAndSettle();

      // Chemistry grid should now display questions 6 to 10
      expect(find.descendant(of: find.byType(GridView), matching: find.text('6')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('10')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('1')), findsNothing);

      // Trigger multiple timer ticks / rebuilds to simulate 1-second ticks
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Verify Chemistry remains selected and is NOT reset to Physics!
      expect(find.descendant(of: find.byType(GridView), matching: find.text('6')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('10')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('1')), findsNothing);

      // Tap Biology Tab
      await tester.tap(find.text('Biology'));
      await tester.pumpAndSettle();

      // Biology grid should display Botany and Zoology combined (questions 11 to 20)
      expect(find.descendant(of: find.byType(GridView), matching: find.text('11')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('20')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('6')), findsNothing);

      // Simulate multiple rebuilds and timer ticks
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Verify Biology is STILL selected!
      expect(find.descendant(of: find.byType(GridView), matching: find.text('11')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('20')), findsOneWidget);
      expect(find.descendant(of: find.byType(GridView), matching: find.text('6')), findsNothing);

      // Tap on question 15 (Botany/Zoology inside Biology grid)
      await tester.tap(find.descendant(of: find.byType(GridView), matching: find.text('15')));
      await tester.pumpAndSettle();

      // The modal should close
      expect(find.text('Grid View'), findsNothing);

      // Verify question 15 is now the active question on the test screen
      expect(find.text('15'), findsWidgets);
      expect(find.text('Biology'), findsOneWidget); // Top bar subject is Biology
    });
  });
}
