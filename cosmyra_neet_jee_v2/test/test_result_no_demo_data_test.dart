import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/models/models.dart';
import 'package:cosmyra_neet_jee/features/tests/test_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Test Result Real Calculation & No Demo Data Tests', () {
    test('TestCohortStats computes genuine rank and percentile without fake fallbacks', () {
      final stats = TestCohortStats(
        totalAttempts: 5,
        topperScore: 650.0,
        topperCorrect: 165,
        topperIncorrect: 10,
        topperSkipped: 5,
        topperAccuracy: 94.3,
        avgScore: 420.0,
        avgCorrect: 110,
        avgIncorrect: 30,
        avgSkipped: 40,
        avgAccuracy: 78.5,
        allScores: [650.0, 520.0, 420.0, 310.0, 200.0],
      );

      // Student scored 520.0 (second highest out of 5)
      expect(stats.calculateRank(520.0), equals(2));
      // Student scored 650.0 (top score)
      expect(stats.calculateRank(650.0), equals(1));
      // Student scored 150.0 (lowest)
      expect(stats.calculateRank(150.0), equals(6));

      // Percentile for 520: 3 students below out of 5 = 60.0%
      expect(stats.calculatePercentile(520.0), equals(60.0));
    });

    testWidgets('TestResultScreen renders actual student score and does not show fake 680/720 or 206.64',
        (WidgetTester tester) async {
      // Real student attempt with 320/720 marks
      final realAttempt = TestAttemptModel(
        id: 'real_att_123',
        userId: 'student_real',
        testTemplateId: 'test_real_template',
        testTitle: 'NEET Full Length Mock 2026',
        startedAt: DateTime.now().subtract(const Duration(hours: 3)),
        expiresAt: DateTime.now(),
        submittedAt: DateTime.now(),
        status: 'submitted',
        totalScore: 320,
        maxMarks: 720,
        totalQuestions: 180,
        attemptedCount: 90,
        correctCount: 82,
        incorrectCount: 8,
        unattemptedCount: 90,
        accuracy: 91.1,
        timeSpentSeconds: 7200,
      );

      // Sample questions across Physics, Chemistry, Botany, Zoology
      final List<QuestionModel> questions = List.generate(180, (i) {
        String sub;
        if (i < 45) {
          sub = 'Physics';
        } else if (i < 90) {
          sub = 'Chemistry';
        } else if (i < 135) {
          sub = 'Botany';
        } else {
          sub = 'Zoology';
        }
        return QuestionModel(
          id: 'q_$i',
          examId: 'neet',
          subjectId: sub,
          chapterId: 'ch1',
          questionText: 'Question $i in $sub',
          qType: 'mcq',
          marks: 4,
          negativeMarks: 1,
          options: [
            QuestionOptionModel(id: 'opt_A_$i', questionId: 'q_$i', optionIndex: 0, optionText: 'Option A', isCorrect: true),
            QuestionOptionModel(id: 'opt_B_$i', questionId: 'q_$i', optionIndex: 1, optionText: 'Option B', isCorrect: false),
          ],
        );
      });

      // Student answers: Q0-Q9 in Physics correct
      final Map<int, String> answers = {};
      for (int i = 0; i < 10; i++) {
        answers[i] = 'opt_A_$i';
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestResultScreen(
              attempt: realAttempt,
              questions: questions,
              userAnswers: answers,
              onBackToDashboard: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify the real student score is displayed
      expect(find.textContaining('320/720'), findsWidgets);

      // Verify hardcoded fake numbers are NOT present
      expect(find.text('680'), findsNothing);
      expect(find.text('206.64'), findsNothing);
      expect(find.text('57448'), findsNothing);
      expect(find.text('97.13'), findsNothing);

      // Verify "Not enough comparison data yet" is displayed because cohort data hasn't arrived
      expect(find.text('Not enough comparison data yet'), findsOneWidget);
    });

    testWidgets('TestResultScreen displays explicit unavailable message when questions list is empty instead of fake 0 metrics',
        (WidgetTester tester) async {
      final attemptWithoutQuestions = TestAttemptModel(
        id: 'att_no_q',
        userId: 'student_1',
        testTemplateId: 'tmpl_1',
        testTitle: 'NEET 2026 Test',
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now(),
        submittedAt: DateTime.now(),
        status: 'submitted',
        totalScore: 450,
        maxMarks: 720,
        totalQuestions: 180,
        attemptedCount: 120,
        correctCount: 115,
        incorrectCount: 5,
        unattemptedCount: 60,
        accuracy: 95.8,
        timeSpentSeconds: 5400,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestResultScreen(
              attempt: attemptWithoutQuestions,
              questions: const [],
              userAnswers: const {},
              onBackToDashboard: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Sectional card should show clean unavailable message, NOT fake zeros
      expect(find.text('Subject breakdown is unavailable'), findsOneWidget);
      expect(find.text('Detailed question records for this attempt could not be loaded.'), findsOneWidget);
    });

    testWidgets('TestResultScreen reconciles subject-wise metrics with overall attempt',
        (WidgetTester tester) async {
      final attempt = TestAttemptModel(
        id: 'att_reconcile',
        userId: 'student_1',
        testTemplateId: 'tmpl_neet',
        testTitle: 'NEET Full Mock Exam',
        startedAt: DateTime.now().subtract(const Duration(hours: 3)),
        expiresAt: DateTime.now(),
        submittedAt: DateTime.now(),
        status: 'submitted',
        totalScore: 150,
        maxMarks: 720,
        totalQuestions: 180,
        attemptedCount: 40,
        correctCount: 38,
        incorrectCount: 2,
        unattemptedCount: 140,
        accuracy: 95.0,
        timeSpentSeconds: 7200,
      );

      final List<QuestionModel> questions = List.generate(180, (i) {
        String sub;
        if (i < 45) {
          sub = 'Physics';
        } else if (i < 90) {
          sub = 'Chemistry';
        } else if (i < 135) {
          sub = 'Botany';
        } else {
          sub = 'Zoology';
        }
        return QuestionModel(
          id: 'q_$i',
          examId: 'neet',
          subjectId: sub,
          chapterId: 'ch1',
          questionText: 'Question $i in $sub',
          qType: 'mcq',
          marks: 4,
          negativeMarks: 1,
          options: [
            QuestionOptionModel(id: 'opt_A_$i', questionId: 'q_$i', optionIndex: 0, optionText: 'Option A', isCorrect: true),
            QuestionOptionModel(id: 'opt_B_$i', questionId: 'q_$i', optionIndex: 1, optionText: 'Option B', isCorrect: false),
          ],
        );
      });

      // Student answers:
      // Physics (0-44): Q0-Q9 correct (10 correct -> 40 marks)
      // Chemistry (45-89): Q45-Q52 correct (8 correct), Q53-Q54 incorrect (2 incorrect -> 30 marks)
      // Botany (90-134): Q90-Q99 correct (10 correct -> 40 marks)
      // Zoology (135-179): Q135-Q144 correct (10 correct -> 40 marks)
      final Map<int, String> answers = {};
      for (int i = 0; i < 10; i++) {
        answers[i] = 'opt_A_$i'; // Physics
      }
      for (int i = 45; i < 53; i++) {
        answers[i] = 'opt_A_$i'; // Chemistry correct
      }
      answers[53] = 'opt_B_53'; // Chemistry incorrect
      answers[54] = 'opt_B_54'; // Chemistry incorrect
      for (int i = 90; i < 100; i++) {
        answers[i] = 'opt_A_$i'; // Botany
      }
      for (int i = 135; i < 145; i++) {
        answers[i] = 'opt_A_$i'; // Zoology
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestResultScreen(
              attempt: attempt,
              questions: questions,
              userAnswers: answers,
              onBackToDashboard: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Overall: 150/720 marks, 38 correct, 2 incorrect, 140 skipped
      expect(find.textContaining('150/720'), findsWidgets);
      expect(find.text('38/180'), findsOneWidget);
      expect(find.text('2/180'), findsOneWidget);
      expect(find.text('140/180'), findsOneWidget);

      // Sectional starts with Physics selected: Score 40, Correct 10, Incorrect 0, Skipped 35
      expect(find.text('40'), findsWidgets);
      expect(find.text('10'), findsWidgets);
      expect(find.text('35'), findsWidgets);
    });
  });
}
