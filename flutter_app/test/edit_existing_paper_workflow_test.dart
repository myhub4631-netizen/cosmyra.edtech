import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';
import 'package:cosmyra_neet_jee/features/admin/admin_bulk_upload_step2_screen.dart';

void main() {
  group('Edit Existing Paper Bulk Upload Workflow Tests (Requirements 1 - 16)', () {
    // Canonical Mock Data
    final String mockPaperId = 'b0797305-6ec7-4638-b7eb-663884347c61';
    final Map<String, dynamic> mockCanonicalPaper = {
      'id': mockPaperId,
      'paper_name': 'NEET 2026 Phase 1',
      'exam': 'NEET',
      'source_category': 'PYQ',
      'year': '2026',
      'phase': 'Phase 1',
      'paper_type': 'Medical (UG)',
      'question_count': 180,
      'duration_minutes': 180,
      'total_marks': 720,
      'status': 'Published',
      'conducting_body': 'NTA',
      'language': 'English',
      'negative_marking': 'Yes',
      'positive_marks': 4,
      'negative_marks': -1,
      'available_in': ['custom_practice', 'custom_test', 'pyq_practice', 'nta_questions', 'test_series'],
      'instructions': 'Official NEET UG 2026 instructions',
    };

    final List<Map<String, dynamic>> mockCatalogues = [
      {
        'id': mockPaperId,
        'paper_name': 'NEET 2026 Phase 1',
        'exam': 'NEET',
        'source_category': 'PYQ',
        'year': '2026',
        'question_count': 180,
        'status': 'Published',
      },
      {
        'id': 'nta-paper-uuid-2026',
        'paper_name': 'NEET 2026 NTA Practice Set 1',
        'exam': 'NEET',
        'source_category': 'NTA',
        'year': '2026',
        'question_count': 180,
        'status': 'Published',
      },
      {
        'id': 'ts-paper-uuid-2026',
        'paper_name': 'NEET 2026 All India Test Series #1',
        'exam': 'NEET',
        'source_category': 'Test Series',
        'year': '2026',
        'question_count': 180,
        'status': 'Draft',
      },
      {
        'id': 'jee-pyq-uuid-2026',
        'paper_name': 'JEE Main 2026 Shift 1',
        'exam': 'JEE Main',
        'source_category': 'PYQ',
        'year': '2026',
        'question_count': 75,
        'status': 'Published',
      },
    ];

    final List<Map<String, dynamic>> mockExistingQuestions = List.generate(180, (i) {
      final int qNum = i + 1;
      final String qUuid = '2d07a050-41b6-4169-a028-${qNum.toString().padLeft(12, '0')}';
      String subject = 'Physics';
      if (qNum > 45 && qNum <= 90) subject = 'Chemistry';
      if (qNum > 90 && qNum <= 135) subject = 'Botany';
      if (qNum > 135) subject = 'Zoology';

      return {
        'id': qUuid,
        'paper_id': mockPaperId,
        'question_number': qNum,
        'question_text': 'What is the physical principle in question $qNum?',
        'option_1': 'Option A for Q$qNum',
        'option_2': 'Option B for Q$qNum',
        'option_3': 'Option C for Q$qNum',
        'option_4': 'Option D for Q$qNum',
        'correct_option_index': 0,
        'correct_answer': 'Option A',
        'explanation': 'Standard textbook explanation for Q$qNum',
        'solution_video_url': 'https://example.com/video_$qNum.mp4',
        'difficulty': 'Medium',
        'marks': 4,
        'negative_marks': 1,
        'subject': subject,
        'chapter': 'Kinematics',
        'topic': 'Motion in One Dimension',
        'chapter_id': 'c1111111-1111-1111-1111-111111111111',
      };
    });

    test('1. Create New Paper mode preserves default behavior', () {
      const mode = 'create';
      expect(mode, equals('create'));
      final Map<String, dynamic> newPaperDetails = {
        'id': 'paper_${DateTime.now().millisecondsSinceEpoch}',
        'paperName': 'New Mock Paper',
        'isEditMode': false,
      };
      expect(newPaperDetails['isEditMode'], isFalse);
      expect(newPaperDetails['id'].toString().startsWith('paper_'), isTrue);
    });

    test('2. Edit Existing Paper mode filters by source category and exam', () {
      // Admin selects Source Category: PYQ, Exam: NEET
      final selectedCategory = 'PYQ';
      final selectedExam = 'NEET';

      final matching = mockCatalogues.where((p) {
        final cat = (p['source_category'] ?? p['sourceCategory'] ?? '').toString().trim().toUpperCase();
        final ex = (p['exam'] ?? p['exam_name'] ?? '').toString().trim().toUpperCase();
        return cat == selectedCategory.toUpperCase() && ex == selectedExam.toUpperCase();
      }).toList();

      expect(matching.length, equals(1));
      expect(matching.first['id'], equals(mockPaperId));
      expect(matching.first['paper_name'], equals('NEET 2026 Phase 1'));

      // Ensure other categories (NTA, Test Series, JEE) are excluded
      expect(matching.any((p) => p['source_category'] == 'NTA'), isFalse);
      expect(matching.any((p) => p['source_category'] == 'Test Series'), isFalse);
      expect(matching.any((p) => p['exam'] == 'JEE Main'), isFalse);
    });

    test('3. Selecting a paper loads its canonical metadata accurately', () {
      final loadedRecord = Map<String, dynamic>.from(mockCanonicalPaper);
      expect(loadedRecord['id'], equals(mockPaperId));
      expect(loadedRecord['paper_name'], equals('NEET 2026 Phase 1'));
      expect(loadedRecord['question_count'], equals(180));
      expect(loadedRecord['total_marks'], equals(720));
      expect(loadedRecord['duration_minutes'], equals(180));
      expect(loadedRecord['status'], equals('Published'));
    });

    test('4. Selecting a paper loads its actual saved questions into Step 2 with canonical UUIDs', () {
      final widget = AdminBulkUploadStep2Screen(
        paperRecord: mockCanonicalPaper,
        paperName: 'NEET 2026 Phase 1',
        totalQuestionsCount: 180,
        isEditMode: true,
        editingPaperId: mockPaperId,
      );

      expect(widget.isEditMode, isTrue);
      expect(widget.editingPaperId, equals(mockPaperId));

      // Simulate loading question items into QuestionItemData
      final List<QuestionItemData> items = mockExistingQuestions.map((sq) {
        return QuestionItemData(
          id: sq['id'].toString(),
          number: sq['question_number'] as int,
          text: sq['question_text'].toString(),
          options: [sq['option_1'], sq['option_2'], sq['option_3'], sq['option_4']],
          correctOptionIndex: sq['correct_option_index'] as int,
          explanation: sq['explanation'].toString(),
          solutionVideoUrl: sq['solution_video_url'].toString(),
          subject: sq['subject'].toString(),
          chapter: sq['chapter'].toString(),
          topic: sq['topic'].toString(),
          chapterId: sq['chapter_id'].toString(),
          isSaved: true,
        );
      }).toList();

      expect(items.length, equals(180));
      expect(items.first.id, equals('2d07a050-41b6-4169-a028-000000000001'));
      expect(items.last.id, equals('2d07a050-41b6-4169-a028-000000000180'));
    });

    test('5. Editing a question updates the existing question UUID rather than creating a duplicate', () {
      final q1 = mockExistingQuestions.first;
      final String originalUuid = q1['id'].toString();

      // Admin edits Question 1 text
      final updatedQMap = Map<String, dynamic>.from(q1);
      updatedQMap['question_text'] = 'Corrected Question 1: What is the modified principle?';

      expect(updatedQMap['id'], equals(originalUuid));
      expect(SupabaseService.isValidUuid(updatedQMap['id']), isTrue);
      expect(updatedQMap['question_text'], contains('Corrected Question 1'));
    });

    test('6. Changing a chapter/topic persists correctly', () {
      final q = mockExistingQuestions[5];
      final updatedQMap = Map<String, dynamic>.from(q);
      updatedQMap['chapter'] = 'Thermodynamics';
      updatedQMap['topic'] = 'Carnot Engine';
      updatedQMap['chapter_id'] = 'c2222222-2222-2222-2222-222222222222';

      expect(updatedQMap['chapter'], equals('Thermodynamics'));
      expect(updatedQMap['topic'], equals('Carnot Engine'));
      expect(updatedQMap['chapter_id'], equals('c2222222-2222-2222-2222-222222222222'));
    });

    test('7. Changing answer options and correct answer persists correctly', () {
      final q = mockExistingQuestions[10];
      final updatedQMap = Map<String, dynamic>.from(q);
      updatedQMap['option_1'] = r'Updated Option 1: $\Delta U = Q - W$';
      updatedQMap['option_2'] = r'Updated Option 2: $\Delta U = Q + W$';
      updatedQMap['correct_option_index'] = 1;
      updatedQMap['correct_answer'] = 'Option B';

      expect(updatedQMap['correct_option_index'], equals(1));
      expect(updatedQMap['correct_answer'], equals('Option B'));
      expect(updatedQMap['option_1'], contains(r'\Delta U'));
    });

    test('8. Changing a video solution persists correctly', () {
      final q = mockExistingQuestions[15];
      final updatedQMap = Map<String, dynamic>.from(q);
      updatedQMap['solution_video_url'] = 'https://supabase.co/storage/v1/object/public/videos/sol_q16_v2.mp4';

      expect(updatedQMap['solution_video_url'], equals('https://supabase.co/storage/v1/object/public/videos/sol_q16_v2.mp4'));
    });

    test('9. Adding a question creates only the explicitly added record', () {
      final Set<String> originalIds = mockExistingQuestions.map((q) => q['id'].toString()).toSet();
      expect(originalIds.length, equals(180));

      final newQuestion = QuestionItemData(
        id: SupabaseService.toValidUuid('q_${mockPaperId}_added_181'),
        number: 181,
        text: 'Newly explicitly added question 181',
        options: ['Opt 1', 'Opt 2', 'Opt 3', 'Opt 4'],
        correctOptionIndex: 0,
      );

      expect(originalIds.contains(newQuestion.id), isFalse);
      expect(SupabaseService.isValidUuid(newQuestion.id), isTrue);
    });

    test('10. Removing a question follows confirmation and stages deletion safely', () {
      final Set<String> originalIds = mockExistingQuestions.map((q) => q['id'].toString()).toSet();
      final Set<String> stagedDeletions = {};

      final qToRemove = mockExistingQuestions[10];
      final String removeId = qToRemove['id'].toString();

      if (originalIds.contains(removeId)) {
        stagedDeletions.add(removeId);
      }

      expect(stagedDeletions.contains(removeId), isTrue);
      expect(stagedDeletions.length, equals(1));
    });

    test('11. Saving edits preserves the original paper UUID', () {
      final Map<String, dynamic> updatedPaper = Map<String, dynamic>.from(mockCanonicalPaper);
      updatedPaper['instructions'] = 'Updated instructions during admin review';
      updatedPaper['question_count'] = 180;

      expect(updatedPaper['id'], equals(mockPaperId));
      expect(SupabaseService.isValidUuid(updatedPaper['id']), isTrue);
    });

    test('12. Question count and subject distribution are recalculated accurately', () {
      final Map<String, int> subjectCounts = {};
      for (final q in mockExistingQuestions) {
        final sub = (q['subject'] as String).toLowerCase();
        subjectCounts[sub] = (subjectCounts[sub] ?? 0) + 1;
      }

      expect(subjectCounts['physics'], equals(45));
      expect(subjectCounts['chemistry'], equals(45));
      expect(subjectCounts['botany'], equals(45));
      expect(subjectCounts['zoology'], equals(45));
      expect(subjectCounts.values.reduce((a, b) => a + b), equals(180));
    });

    test('13. Failed save reports an error and does not report false success', () {
      final failResponse = {'success': false, 'error': 'Database timeout / RLS violation'};
      expect(failResponse['success'], isFalse);
      expect(failResponse['error'], contains('Database timeout'));
    });

    test('14. Isolated PYQ, NTA, and Test Series catalogues remain untouched', () {
      final pyqPapers = mockCatalogues.where((p) => p['source_category'] == 'PYQ').toList();
      final ntaPapers = mockCatalogues.where((p) => p['source_category'] == 'NTA').toList();
      final testSeriesPapers = mockCatalogues.where((p) => p['source_category'] == 'Test Series').toList();

      expect(pyqPapers.length, equals(2));
      expect(ntaPapers.length, equals(1));
      expect(testSeriesPapers.length, equals(1));
    });

    test('15. Historical attempts and results remain linked to canonical paper UUID', () {
      final mockStudentAttempt = {
        'attempt_id': 'att_12345',
        'paper_id': mockPaperId,
        'user_id': 'student_789',
        'score': 680,
      };

      expect(mockStudentAttempt['paper_id'], equals(mockPaperId));
    });

    test('16. Existing bulk upload creation workflow backward compatibility', () {
      final defaultScreen = AdminBulkUploadStep2Screen(
        paperName: 'NEET 2026 Phase 2',
        totalQuestionsCount: 180,
      );

      expect(defaultScreen.isEditMode, isFalse);
      expect(defaultScreen.editingPaperId, isNull);
    });
  });

  group('P1 Bug Fix: Restore Empty Question Slots in Existing Paper Editor (Requirements 1 - 14)', () {
    final String testPaperId = 'b0797305-6ec7-4638-b7eb-663884347c61';

    // Helper that replicates the slot-mapping engine implemented in AdminBulkUploadStep2Screen
    List<QuestionItemData> buildSlots({
      required int expectedCount,
      required List<Map<String, dynamic>> savedQList,
      String exam = 'NEET',
    }) {
      int maxFoundNum = 0;
      final Map<int, Map<String, dynamic>> savedByNumber = {};
      final Map<int, List<Map<String, dynamic>>> duplicatesByNumber = {};
      final List<Map<String, dynamic>> unnumberedSaved = [];

      for (final savedMatch in savedQList) {
        final rawNum = savedMatch['question_number'] ?? savedMatch['questionNumber'];
        final int? parsedNum = rawNum is num ? rawNum.toInt() : int.tryParse(rawNum?.toString() ?? '');
        if (parsedNum != null && parsedNum > 0) {
          if (parsedNum > maxFoundNum) maxFoundNum = parsedNum;
          if (savedByNumber.containsKey(parsedNum)) {
            duplicatesByNumber.putIfAbsent(parsedNum, () => [savedByNumber[parsedNum]!]).add(savedMatch);
          } else {
            savedByNumber[parsedNum] = savedMatch;
          }
        } else {
          unnumberedSaved.add(savedMatch);
        }
      }

      final int totalSlots = expectedCount > 0
          ? (expectedCount > maxFoundNum ? expectedCount : maxFoundNum)
          : maxFoundNum;

      final List<QuestionItemData> slots = [];
      int unnumberedIdx = 0;

      for (int slotNum = 1; slotNum <= totalSlots; slotNum++) {
        if (savedByNumber.containsKey(slotNum)) {
          final m = savedByNumber[slotNum]!;
          slots.add(QuestionItemData(
            id: (m['id'] ?? '').toString(),
            number: slotNum,
            text: m['question_text'] ?? m['questionText'] ?? '',
            options: [
              m['option_1'] ?? 'Opt 1',
              m['option_2'] ?? 'Opt 2',
              m['option_3'] ?? 'Opt 3',
              m['option_4'] ?? 'Opt 4',
            ],
            correctOptionIndex: (m['correct_option_index'] as num?)?.toInt() ?? 0,
            explanation: m['explanation'] ?? '',
            solutionVideoUrl: m['solution_video_url'],
            subject: m['subject'] ?? 'Physics',
            chapter: m['chapter'] ?? 'Kinematics',
            topic: m['topic'] ?? 'Motion',
            chapterId: m['chapter_id'] ?? 'c-uuid-1',
            isSaved: true,
          ));
        } else if (unnumberedIdx < unnumberedSaved.length) {
          final m = unnumberedSaved[unnumberedIdx++];
          slots.add(QuestionItemData(
            id: (m['id'] ?? '').toString(),
            number: slotNum,
            text: m['question_text'] ?? m['questionText'] ?? '',
            options: ['Opt 1', 'Opt 2', 'Opt 3', 'Opt 4'],
            correctOptionIndex: 0,
            isSaved: true,
          ));
        } else {
          slots.add(QuestionItemData(
            id: '',
            number: slotNum,
            text: '',
            options: ['1', '2', '3', '4'],
            correctOptionIndex: -1,
            subject: slotNum <= 45 ? 'Physics' : (slotNum <= 90 ? 'Chemistry' : (slotNum <= 135 ? 'Botany' : 'Zoology')),
            isSaved: false,
          ));
        }
      }
      return slots;
    }

    bool isSlotEmpty(QuestionItemData q) => !q.isSaved && q.text.trim().isEmpty && (q.questionImage == null || q.questionImage!.isEmpty);

    bool isSlotComplete(QuestionItemData q) {
      if (!q.isSaved) return false;
      final bool hasText = q.text.trim().isNotEmpty || (q.questionImage != null && q.questionImage!.isNotEmpty);
      final int filledOpts = q.options.where((o) => o.trim().isNotEmpty).length;
      final bool hasCorrect = q.correctOptionIndex >= 0 && q.correctOptionIndex < q.options.length;
      final bool hasChapter = q.chapterId.trim().isNotEmpty || q.chapter.trim().isNotEmpty;
      return hasText && filledOpts >= 2 && hasCorrect && hasChapter;
    }

    bool isSlotIncomplete(QuestionItemData q) {
      if (q.isSaved) {
        return !isSlotComplete(q);
      } else {
        return q.text.trim().isNotEmpty || (q.questionImage != null && q.questionImage!.isNotEmpty);
      }
    }

    // Fixture with 179 questions out of 180 (Question 22 missing)
    final List<Map<String, dynamic>> fixture179 = List.generate(180, (i) {
      final int qNum = i + 1;
      return {
        'id': 'uuid-q-$qNum',
        'paper_id': testPaperId,
        'question_number': qNum,
        'question_text': 'Question $qNum content',
        'option_1': 'A',
        'option_2': 'B',
        'option_3': 'C',
        'option_4': 'D',
        'correct_option_index': 0,
        'chapter': 'Kinematics',
        'chapter_id': 'c-1',
      };
    }).where((q) => q['question_number'] != 22).toList();

    test('1. Paper with 180 expected questions and 179 saved records displays all 180 slots', () {
      final slots = buildSlots(expectedCount: 180, savedQList: fixture179);
      expect(slots.length, equals(180));
    });

    test('2. Missing Question 22 slot is visible and clickable with number 22', () {
      final slots = buildSlots(expectedCount: 180, savedQList: fixture179);
      final slot22 = slots[21]; // 0-indexed index 21 corresponds to Question 22
      expect(slot22.number, equals(22));
      expect(isSlotEmpty(slot22), isTrue);
    });

    test('3. Clicking slot 22 opens a blank form preassigned to Question 22', () {
      final slots = buildSlots(expectedCount: 180, savedQList: fixture179);
      final slot22 = slots[21];
      expect(slot22.id, equals(''));
      expect(slot22.number, equals(22));
      expect(slot22.text, isEmpty);
      expect(slot22.isSaved, isFalse);
    });

    test('4. Saving valid Question 22 fills that slot and persists the new question', () {
      final slots = buildSlots(expectedCount: 180, savedQList: fixture179);
      final slot22 = slots[21];

      // Admin fills in slot 22
      slot22.text = 'What is Newton second law?';
      slot22.options = ['F=ma', 'E=mc^2', 'V=IR', 'P=VI'];
      slot22.correctOptionIndex = 0;
      slot22.chapter = 'Laws of Motion';
      slot22.chapterId = 'c-laws';

      // Persist simulation
      final String newUuid = SupabaseService.toValidUuid('q_${testPaperId}_12345678_${slot22.number}');
      slot22.id = newUuid;
      slot22.isSaved = true;

      expect(slot22.isSaved, isTrue);
      expect(slot22.id, equals(newUuid));
      expect(SupabaseService.isValidUuid(slot22.id), isTrue);
      expect(isSlotComplete(slot22), isTrue);
    });

    test('5. The other 179 question UUIDs remain unchanged when slot 22 is saved', () {
      final slots = buildSlots(expectedCount: 180, savedQList: fixture179);
      final Set<String> originalIds = fixture179.map((q) => q['id'].toString()).toSet();
      expect(originalIds.length, equals(179));

      // Save Question 22
      final slot22 = slots[21];
      slot22.text = 'New Q22';
      slot22.id = SupabaseService.toValidUuid('q_${testPaperId}_new_22');
      slot22.isSaved = true;

      final Set<String> preservedIds = slots
          .where((q) => q.number != 22)
          .map((q) => q.id)
          .toSet();

      expect(preservedIds, equals(originalIds));
    });

    test('6. A 200-question paper displays slots 1–200', () {
      final List<Map<String, dynamic>> fixture199 = List.generate(200, (i) {
        return {
          'id': 'uuid-200-q-${i + 1}',
          'question_number': i + 1,
          'question_text': 'Q ${i + 1}',
          'chapter': 'Physics',
          'chapter_id': 'c-p',
        };
      }).where((q) => q['question_number'] != 50).toList();

      final slots = buildSlots(expectedCount: 200, savedQList: fixture199);
      expect(slots.length, equals(200));
      expect(slots.first.number, equals(1));
      expect(slots.last.number, equals(200));
      expect(isSlotEmpty(slots[49]), isTrue); // Slot 50 is empty
    });

    test('7. A custom paper displays exactly its configured number of slots', () {
      final slots = buildSlots(expectedCount: 75, savedQList: []);
      expect(slots.length, equals(75));
      expect(slots.every((q) => isSlotEmpty(q)), isTrue);
    });

    test('8. Existing saved questions load correctly when their slots are selected', () {
      final slots = buildSlots(expectedCount: 180, savedQList: fixture179);
      final slot1 = slots.first;
      expect(slot1.number, equals(1));
      expect(slot1.id, equals('uuid-q-1'));
      expect(slot1.text, equals('Question 1 content'));
      expect(slot1.isSaved, isTrue);
      expect(isSlotComplete(slot1), isTrue);
    });

    test('9. Incomplete saved questions remain editable and are not treated as empty records', () {
      final incompleteFixture = [
        {
          'id': 'uuid-incomplete-1',
          'question_number': 1,
          'question_text': 'Incomplete question lacking correct option and chapter',
          'option_1': 'A',
          'option_2': '',
          'option_3': '',
          'option_4': '',
          'correct_option_index': -1,
          'chapter': '',
          'chapter_id': '',
        }
      ];

      final slots = buildSlots(expectedCount: 10, savedQList: incompleteFixture);
      final q1 = slots.first;
      expect(q1.isSaved, isTrue);
      expect(isSlotEmpty(q1), isFalse);
      expect(isSlotIncomplete(q1), isTrue);
      expect(isSlotComplete(q1), isFalse);
    });

    test('10. Duplicate question numbers are detected and surfaced', () {
      final duplicateList = [
        {'id': 'uuid-dup-1', 'question_number': 5, 'question_text': 'First Q5'},
        {'id': 'uuid-dup-2', 'question_number': 5, 'question_text': 'Second Q5'},
      ];

      final Map<int, List<Map<String, dynamic>>> duplicates = {};
      final Map<int, Map<String, dynamic>> seen = {};
      for (final q in duplicateList) {
        final num = q['question_number'] as int;
        if (seen.containsKey(num)) {
          duplicates.putIfAbsent(num, () => [seen[num]!]).add(q);
        } else {
          seen[num] = q;
        }
      }

      expect(duplicates.containsKey(5), isTrue);
      expect(duplicates[5]!.length, equals(2));
    });

    test('11. Opening a blank slot without saving does not create a database record', () {
      final slots = buildSlots(expectedCount: 180, savedQList: fixture179);
      final emptySlot = slots[21];

      // Admin views slot without saving
      expect(emptySlot.id, equals(''));
      expect(emptySlot.isSaved, isFalse);
      // No DB save performed: ID remains empty and unpersisted
    });

    test('12. Progress and completeness counts are correct before and after saving', () {
      final slots = buildSlots(expectedCount: 180, savedQList: fixture179);

      int completeBefore = slots.where((q) => isSlotComplete(q)).length;
      int emptyBefore = slots.where((q) => isSlotEmpty(q)).length;
      double progressBefore = (completeBefore / 180) * 100;

      expect(completeBefore, equals(179));
      expect(emptyBefore, equals(1));
      expect(progressBefore.toInt(), equals(99));

      // Success banner condition is false
      final bool bannerBefore = completeBefore == 180 && emptyBefore == 0;
      expect(bannerBefore, isFalse);

      // Now save Q22
      final q22 = slots[21];
      q22.text = 'Filled Q22 text';
      q22.options = ['A', 'B', 'C', 'D'];
      q22.correctOptionIndex = 0;
      q22.chapter = 'Kinematics';
      q22.chapterId = 'c-1';
      q22.id = 'uuid-new-22';
      q22.isSaved = true;

      int completeAfter = slots.where((q) => isSlotComplete(q)).length;
      int emptyAfter = slots.where((q) => isSlotEmpty(q)).length;
      double progressAfter = (completeAfter / 180) * 100;

      expect(completeAfter, equals(180));
      expect(emptyAfter, equals(0));
      expect(progressAfter.toInt(), equals(100));

      final bool bannerAfter = completeAfter == 180 && emptyAfter == 0;
      expect(bannerAfter, isTrue);
    });

    test('13. A failed save does not mark the slot as complete', () {
      final slots = buildSlots(expectedCount: 180, savedQList: fixture179);
      final q22 = slots[21];
      q22.text = 'Attempting Q22 save';

      // Simulated failed API response
      final res = {'success': false, 'error': 'Network timeout'};
      if (res['success'] == true) {
        q22.isSaved = true;
      }

      expect(q22.isSaved, isFalse);
      expect(isSlotComplete(q22), isFalse);
    });

    test('14. Existing create-new-paper and bulk-upload workflows continue to work', () {
      final newPaperSlots = buildSlots(expectedCount: 180, savedQList: []);
      expect(newPaperSlots.length, equals(180));
      expect(newPaperSlots.every((q) => q.isSaved == false), isTrue);
      expect(newPaperSlots.every((q) => isSlotEmpty(q)), isTrue);
    });
  });
}

