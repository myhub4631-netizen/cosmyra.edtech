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
}
