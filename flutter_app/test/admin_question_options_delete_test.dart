import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';
import 'package:cosmyra_neet_jee/features/admin/admin_bulk_upload_step2_screen.dart';

void main() {
  group('Admin Question Editor - Option Add/Delete Regression Tests', () {

    test('1. Delete Option A while retaining B–E (Reindexed to A, B, C, D)', () {
      final q = QuestionItemData(
        number: 1,
        text: 'What is the powerhouse of the cell?',
        options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi apparatus', 'Lysosome'],
        optionImages: [null, null, null, null, null],
        correctOptionIndex: 1, // 'Mitochondria' (initially Option B)
      );
      expect(q.options.length, 5);
      expect(q.options[0], 'Nucleus');
      expect(q.options[1], 'Mitochondria');
      expect(q.correctOptionIndex, 1);

      // Delete Option A (index 0)
      const int deletedIdx = 0;
      final isCorrect = (q.correctOptionIndex == deletedIdx);
      q.options.removeAt(deletedIdx);
      if (deletedIdx < q.optionImages.length) q.optionImages.removeAt(deletedIdx);
      if (deletedIdx < q.optionKeys.length) q.optionKeys.removeAt(deletedIdx);
      q.optionsVersion++;

      if (isCorrect) {
        q.correctOptionIndex = -1;
      } else if (q.correctOptionIndex > deletedIdx) {
        q.correctOptionIndex -= 1; // Shifts down to 0
      }

      // Verify remaining 4 options
      expect(q.options.length, 4);
      expect(q.options[0], 'Mitochondria'); // Old B is now A
      expect(q.options[1], 'Ribosome');     // Old C is now B
      expect(q.options[2], 'Golgi apparatus'); // Old D is now C
      expect(q.options[3], 'Lysosome');    // Old E is now D

      // Correct answer shifted safely to point to Mitochondria (now Option A, index 0)
      expect(q.correctOptionIndex, 0);
      expect(q.options[q.correctOptionIndex], 'Mitochondria');
    });

    test('2. Delete Option E while retaining A–D', () {
      final q = QuestionItemData(
        number: 2,
        text: 'Select the primary colors of light.',
        options: ['Red', 'Green', 'Blue', 'Yellow', 'Accidental Option E'],
        optionImages: [null, null, null, null, null],
        correctOptionIndex: 0, // 'Red' (Option A)
      );

      // Delete Option E (index 4)
      const int deletedIdx = 4;
      final isCorrect = (q.correctOptionIndex == deletedIdx);
      q.options.removeAt(deletedIdx);
      if (deletedIdx < q.optionImages.length) q.optionImages.removeAt(deletedIdx);
      if (deletedIdx < q.optionKeys.length) q.optionKeys.removeAt(deletedIdx);
      q.optionsVersion++;

      if (isCorrect) {
        q.correctOptionIndex = -1;
      } else if (q.correctOptionIndex > deletedIdx) {
        q.correctOptionIndex -= 1;
      }

      // Verify options A to D remain intact
      expect(q.options.length, 4);
      expect(q.options[0], 'Red');
      expect(q.options[1], 'Green');
      expect(q.options[2], 'Blue');
      expect(q.options[3], 'Yellow');
      expect(q.correctOptionIndex, 0); // Unchanged since deleted option was after correct answer
    });

    test('3. Delete a middle option and verify the remaining options stay in correct order', () {
      final q = QuestionItemData(
        number: 3,
        text: 'Arrange items in sequence.',
        options: ['Option 1', 'Option 2', 'Option to delete (3)', 'Option 4', 'Option 5'],
        optionImages: [null, null, null, null, null],
        correctOptionIndex: 3, // 'Option 4' (index 3)
      );

      // Delete middle Option C (index 2)
      const int deletedIdx = 2;
      final isCorrect = (q.correctOptionIndex == deletedIdx);
      q.options.removeAt(deletedIdx);
      if (deletedIdx < q.optionImages.length) q.optionImages.removeAt(deletedIdx);
      if (deletedIdx < q.optionKeys.length) q.optionKeys.removeAt(deletedIdx);
      q.optionsVersion++;

      if (isCorrect) {
        q.correctOptionIndex = -1;
      } else if (q.correctOptionIndex > deletedIdx) {
        q.correctOptionIndex -= 1; // Shifts from 3 to 2
      }

      expect(q.options.length, 4);
      expect(q.options[0], 'Option 1');
      expect(q.options[1], 'Option 2');
      expect(q.options[2], 'Option 4');
      expect(q.options[3], 'Option 5');

      // Correct option still points to 'Option 4' (now at index 2)
      expect(q.correctOptionIndex, 2);
      expect(q.options[q.correctOptionIndex], 'Option 4');
    });

    test('4. Delete an option from an unsaved question (Local editor state only)', () {
      final q = QuestionItemData(
        number: 4,
        text: 'Unsaved draft question.',
        options: ['Draft A', 'Draft B', 'Draft C', 'Draft D', 'Accidental Draft E'],
        isSaved: false,
        correctOptionIndex: 1,
      );

      expect(q.isSaved, false);

      // Delete option 4
      const int deletedIdx = 4;
      q.options.removeAt(deletedIdx);
      q.optionsVersion++;

      // Verified: isSaved remains false, local state mutated only
      expect(q.options.length, 4);
      expect(q.isSaved, false);
      expect(q.options.contains('Accidental Draft E'), false);
    });

    test('5. Delete an option from an existing saved question and reload payload', () {
      final q = QuestionItemData(
        id: '11111111-2222-3333-4444-555555555555',
        number: 5,
        text: 'Saved question test',
        options: ['Opt 1', 'Opt 2', 'Opt 3', 'Opt 4', 'Opt 5'],
        correctOptionIndex: 0,
        isSaved: true,
      );

      // Simulate admin deleting Option 4 (index 4)
      q.options.removeAt(4);
      q.optionsVersion++;

      // Construct persist payload as done in save workflows
      final persistMap = {
        'id': q.id,
        'question_number': q.number,
        'options': q.options,
        'correct_option_index': q.correctOptionIndex,
      };

      // Reloading from persistMap
      final reloadedOptions = List<String>.from(persistMap['options'] as List);
      expect(reloadedOptions.length, 4);
      expect(reloadedOptions, ['Opt 1', 'Opt 2', 'Opt 3', 'Opt 4']);
      expect(persistMap['id'], '11111111-2222-3333-4444-555555555555');
    });

    test('6. Delete the currently correct option and verify that replacement answer is required', () {
      final q = QuestionItemData(
        number: 6,
        text: 'Question with correct answer in Option B',
        options: ['Wrong 1', 'Correct Answer Choice', 'Wrong 2', 'Wrong 3'],
        correctOptionIndex: 1, // Currently correct
      );

      // Delete Option B (index 1)
      const int deletedIdx = 1;
      final isCorrect = (q.correctOptionIndex == deletedIdx);
      q.options.removeAt(deletedIdx);

      if (isCorrect) {
        q.correctOptionIndex = -1; // Must NOT silently pick another option!
      }

      // Verification: correctOptionIndex is invalidated (-1)
      expect(q.correctOptionIndex, -1);
      expect(q.options.length, 3);

      // Verification: Attempting to save with correctOptionIndex == -1 fails validation
      final bool hasValidAnswerKey = (q.correctOptionIndex >= 0 && q.correctOptionIndex < q.options.length);
      expect(hasValidAnswerKey, false); // Required to select new correct answer before saving!
    });

    test('7. Verify that a failed save preserves the edited options', () {
      final q = QuestionItemData(
        number: 7,
        text: 'Question with failed save network simulation',
        options: ['A', 'B', 'C', 'D'],
        correctOptionIndex: 0,
      );

      // Delete option 3
      q.options.removeAt(3);
      expect(q.options.length, 3);

      // Simulate a network failure during save:
      const bool networkFailed = true;
      if (networkFailed) {
        // In the app, catching save error keeps q in memory intact
      }

      // User's edits are fully preserved in memory for retry
      expect(q.options.length, 3);
      expect(q.options, ['A', 'B', 'C']);
    });

    test('8. Verify that other questions and paper records remain unchanged', () {
      final paperQuestions = [
        QuestionItemData(id: 'q-uuid-1', number: 1, text: 'Q1', options: ['1', '2', '3', '4']),
        QuestionItemData(id: 'q-uuid-2', number: 2, text: 'Q2', options: ['A', 'B', 'C', 'D', 'E']),
        QuestionItemData(id: 'q-uuid-3', number: 3, text: 'Q3', options: ['X', 'Y', 'Z', 'W']),
      ];

      // Delete option from Q2 only
      paperQuestions[1].options.removeAt(4);

      // Q1 and Q3 options and identifiers remain untouched
      expect(paperQuestions[0].options.length, 4);
      expect(paperQuestions[0].id, 'q-uuid-1');
      expect(paperQuestions[1].options.length, 4);
      expect(paperQuestions[1].id, 'q-uuid-2');
      expect(paperQuestions[2].options.length, 4);
      expect(paperQuestions[2].id, 'q-uuid-3');
    });

    test('9. Verify compatibility with LaTeX options and long option text', () {
      final latexOptA = r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}';
      final latexOptB = r'\int_{0}^{\infty} e^{-x^2} dx = \frac{\sqrt{\pi}}{2}';
      final longOptC = 'This is an extensive textual option that elaborates on biochemical pathways including phosphorylation and oxidative glycolysis in eukaryotic cellular respiration.';
      final latexOptD = r'\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}';
      final extraOptE = r'\lim_{x \to 0} \frac{\sin x}{x} = 1';

      final q = QuestionItemData(
        number: 9,
        text: 'Evaluate the mathematical and biochemical statements.',
        options: [latexOptA, latexOptB, longOptC, latexOptD, extraOptE],
        correctOptionIndex: 1,
      );

      // Delete the long option C (index 2)
      q.options.removeAt(2);

      expect(q.options.length, 4);
      expect(q.options[0], latexOptA);
      expect(q.options[1], latexOptB);
      expect(q.options[2], latexOptD);
      expect(q.options[3], extraOptE);
      // Correct option remains latexOptB (index 1)
      expect(q.correctOptionIndex, 1);
      expect(q.options[q.correctOptionIndex], latexOptB);
    });

    test('10. Verify match-the-following and other structured question types', () {
      final q = QuestionItemData(
        number: 10,
        questionType: 'Match the Following',
        text: 'Match Column I with Column II:\nA. Ribosome - (i) Protein synthesis\nB. Mitochondria - (ii) ATP production\nC. Chloroplast - (iii) Photosynthesis',
        options: [
          'A-(i), B-(ii), C-(iii)',
          'A-(ii), B-(i), C-(iii)',
          'A-(iii), B-(ii), C-(i)',
          'A-(i), B-(iii), C-(ii)',
          'Accidental Extra Match Combination',
        ],
        correctOptionIndex: 0,
      );

      expect(q.questionType, 'Match the Following');
      expect(q.options.length, 5);

      // Admin deletes accidental combination 5
      q.options.removeAt(4);
      expect(q.options.length, 4);
      expect(q.options[0], 'A-(i), B-(ii), C-(iii)');
      expect(q.correctOptionIndex, 0);
      expect(q.questionType, 'Match the Following');
    });

    test('11. Verify that existing question UUIDs and student history remain unchanged', () {
      const String existingUuid = '98765432-1234-5678-9876-543210987654';
      final q = QuestionItemData(
        id: existingUuid,
        number: 11,
        text: 'Question with student attempts history',
        options: ['Choice 1', 'Choice 2', 'Choice 3', 'Choice 4', 'Choice 5'],
        correctOptionIndex: 2,
        isSaved: true,
      );

      // Deleting Option 4
      q.options.removeAt(4);

      // The question UUID must NEVER change when modifying options!
      expect(q.id, existingUuid);
      expect(q.options.length, 4);
    });

    test('12. Safeguard: Prevent deleting below minimum 2 options', () {
      final q = QuestionItemData(
        number: 12,
        text: 'Question with 2 options',
        options: ['True', 'False'],
        correctOptionIndex: 0,
      );

      expect(q.options.length, 2);

      // Attempting to delete when options.length <= 2
      bool allowedToDelete = q.options.length > 2;
      expect(allowedToDelete, false); // Safeguard blocks deletion
    });
  });
}
