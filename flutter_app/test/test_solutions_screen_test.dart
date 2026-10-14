import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/models/models.dart';
import 'package:cosmyra_neet_jee/features/tests/test_solutions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Test Solutions Screen Tests', () {
    late TestAttemptModel attempt;
    late List<QuestionModel> questions;
    late Map<int, String> userAnswers;

    setUp(() {
      attempt = TestAttemptModel(
        id: 'att_solutions_1',
        userId: 'student_123',
        testTemplateId: 'template_neet_1',
        testTitle: 'NEET Full Syllabus Mock 1',
        startedAt: DateTime.now().subtract(const Duration(hours: 3)),
        expiresAt: DateTime.now(),
        submittedAt: DateTime.now(),
        status: 'submitted',
        totalScore: 8.0,
        maxMarks: 16.0,
        totalQuestions: 4,
        attemptedCount: 3,
        correctCount: 2,
        incorrectCount: 1,
        unattemptedCount: 1,
        accuracy: 66.7,
        timeSpentSeconds: 120,
      );

      questions = [
        // Q1: Correct MCQ with video solution
        QuestionModel(
          id: 'q1',
          examId: 'NEET',
          subjectId: 'Physics',
          chapterId: 'Kinematics',
          questionText: 'A projectile follows trajectory y = x - x^2/20. Range is:',
          qType: 'single_correct',
          marks: 4.0,
          negativeMarks: 1.0,
          explanation: 'On comparing with trajectory equation, R = 20 m.',
          solutionVideoUrl: 'https://example.com/solution1.mp4',
          options: [
            QuestionOptionModel(id: 'opt1_1', questionId: 'q1', optionIndex: 0, optionText: '20 m', isCorrect: true),
            QuestionOptionModel(id: 'opt1_2', questionId: 'q1', optionIndex: 1, optionText: '10 m', isCorrect: false),
            QuestionOptionModel(id: 'opt1_3', questionId: 'q1', optionIndex: 2, optionText: '40 m', isCorrect: false),
            QuestionOptionModel(id: 'opt1_4', questionId: 'q1', optionIndex: 3, optionText: '80 m', isCorrect: false),
          ],
        ),
        // Q2: Incorrect MCQ without video solution
        QuestionModel(
          id: 'q2',
          examId: 'NEET',
          subjectId: 'Physics',
          chapterId: 'Electrostatics',
          questionText: 'Electric field inside a uniformly charged conducting sphere is:',
          qType: 'single_correct',
          marks: 4.0,
          negativeMarks: 1.0,
          explanation: 'Inside a conductor in electrostatic equilibrium, E = 0.',
          options: [
            QuestionOptionModel(id: 'opt2_1', questionId: 'q2', optionIndex: 0, optionText: 'Zero', isCorrect: true),
            QuestionOptionModel(id: 'opt2_2', questionId: 'q2', optionIndex: 1, optionText: 'Constant and non-zero', isCorrect: false),
            QuestionOptionModel(id: 'opt2_3', questionId: 'q2', optionIndex: 2, optionText: 'Inversely proportional to r', isCorrect: false),
            QuestionOptionModel(id: 'opt2_4', questionId: 'q2', optionIndex: 3, optionText: 'Directly proportional to r', isCorrect: false),
          ],
        ),
        // Q3: Correct Numerical question
        QuestionModel(
          id: 'q3',
          examId: 'NEET',
          subjectId: 'Chemistry',
          chapterId: 'Solutions',
          questionText: 'Calculate the molality of 18g glucose in 1000g water:',
          qType: 'numerical',
          numericalAnswer: '0.1',
          marks: 4.0,
          negativeMarks: 0.0,
          explanation: 'Molality = moles / mass of solvent in kg = 0.1 m.',
          options: [],
        ),
        // Q4: Skipped MCQ
        QuestionModel(
          id: 'q4',
          examId: 'NEET',
          subjectId: 'Biology',
          chapterId: 'Genetics',
          questionText: 'Mendel performed monohybrid cross on:',
          qType: 'single_correct',
          marks: 4.0,
          negativeMarks: 1.0,
          options: [
            QuestionOptionModel(id: 'opt4_1', questionId: 'q4', optionIndex: 0, optionText: 'Pisum sativum', isCorrect: true),
            QuestionOptionModel(id: 'opt4_2', questionId: 'q4', optionIndex: 1, optionText: 'Drosophila', isCorrect: false),
          ],
        ),
      ];

      // Student answered:
      // Q1: 'opt1_1' (Correct)
      // Q2: 'opt2_2' (Incorrect, correct is opt2_1)
      // Q3: '0.1' (Correct)
      // Q4: not answered (Skipped)
      userAnswers = {
        0: 'opt1_1',
        1: 'opt2_2',
        2: '0.1',
      };
    });

    testWidgets('Renders top bar with Solutions title, attempt badge, and section', (tester) async {
      final attempt2 = TestAttemptModel(
        id: 'att_solutions_2',
        userId: 'student_123',
        testTemplateId: 'template_neet_1',
        testTitle: 'NEET Full Syllabus Mock 1',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now(),
        submittedAt: DateTime.now(),
        status: 'submitted',
        totalScore: 12.0,
        maxMarks: 16.0,
        totalQuestions: 4,
        attemptedCount: 3,
        correctCount: 3,
        incorrectCount: 0,
        unattemptedCount: 1,
        accuracy: 100.0,
        timeSpentSeconds: 150,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TestSolutionsScreen(
            attempt: attempt,
            questions: questions,
            userAnswers: userAnswers,
            onBack: () {},
            allAttempts: [attempt, attempt2],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Solutions'), findsOneWidget);
      expect(find.text('All Sections'), findsOneWidget);
      expect(find.text('Attempt 1'), findsOneWidget);
    });

    testWidgets('Reconciles filter counts: All=4, Correct=2, Incorrect=1, Skipped=1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestSolutionsScreen(
            attempt: attempt,
            questions: questions,
            userAnswers: userAnswers,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check filter titles
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Correct'), findsNWidgets(2)); // Filter tab title + comparison row
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      // Check badge counts
      expect(find.text('4'), findsWidgets); // All count = 4
      expect(find.text('2'), findsWidgets); // Correct count = 2
      expect(find.text('1'), findsWidgets); // Incorrect count = 1, Skipped count = 1
    });

    testWidgets('Displays question 1 details, options, and View Video Sol. button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestSolutionsScreen(
            attempt: attempt,
            questions: questions,
            userAnswers: userAnswers,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Q1 metadata
      expect(find.text('Marks : +4'), findsOneWidget);
      expect(find.text('Type : Single'), findsOneWidget);

      // Trajectory text
      expect(find.textContaining('trajectory y = x - x^2/20'), findsOneWidget);

      // Options
      expect(find.text('20 m'), findsOneWidget);
      expect(find.text('10 m'), findsOneWidget);

      // Status and timing card (Reference screenshot 3)
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);

      // Correct answer banner
      expect(find.text('Correct Answer : 1'), findsOneWidget);

      // Solution header
      expect(find.text('Solution'), findsOneWidget);
      expect(find.text('View Video Sol.'), findsOneWidget);
    });

    testWidgets('Navigating to Q2 hides View Video Sol. when no video url exists', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestSolutionsScreen(
            attempt: attempt,
            questions: questions,
            userAnswers: userAnswers,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Next button to go to Q2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on Q2 (Electrostatics)
      expect(find.textContaining('Electric field inside'), findsOneWidget);

      // Q2 has no video URL, so View Video Sol. must NOT be shown
      expect(find.text('View Video Sol.'), findsNothing);

      // Prev button should now be visible
      expect(find.text('Prev'), findsOneWidget);
    });

    testWidgets('Filtering by Incorrect displays only Q2 in question palette and card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestSolutionsScreen(
            attempt: attempt,
            questions: questions,
            userAnswers: userAnswers,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Incorrect' filter tab
      await tester.tap(find.text('Incorrect'));
      await tester.pumpAndSettle();

      // Displayed question should automatically be Q2 (only incorrect question)
      expect(find.textContaining('Electric field inside'), findsOneWidget);
    });

    testWidgets('Toggling bookmark dynamically updates review count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestSolutionsScreen(
            attempt: attempt,
            questions: questions,
            userAnswers: userAnswers,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial review count is 0
      expect(find.text('0'), findsWidgets);

      // Tap bookmark icon button on Q1
      final bookmarkButton = find.byTooltip('Mark for Review');
      expect(bookmarkButton, findsOneWidget);
      await tester.tap(bookmarkButton);
      await tester.pumpAndSettle();

      // Review count should now be 1
      expect(find.byTooltip('Marked for Review'), findsOneWidget);
    });
  });
}
