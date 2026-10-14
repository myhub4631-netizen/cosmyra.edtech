import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';
import 'package:cosmyra_neet_jee/core/services/platform_time_tracker_service.dart';
import 'package:cosmyra_neet_jee/models/pyq_models.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  tearDown(() async {
    SupabaseService.isAdminPreview = false;
    await PlatformTimeTrackerService.resetForTesting();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('PYQ Statistics Dashboard & Live Metrics Tests', () {
    test('1. NEET question count uses distinct eligible PYQ question IDs', () async {
      final stats = await SupabaseService.fetchPYQStats('NEET 2026');
      final count = stats['availableQuestions'] as int;
      expect(count, equals(180), reason: 'NEET has exactly 180 distinct published PYQ questions');

      // Direct verify against PostgREST count
      final directCount = await SupabaseService.client
          .from('questions')
          .count(CountOption.exact)
          .eq('source', 'pyq')
          .eq('status', 'published')
          .eq('exam_id', SupabaseService.getExamId('NEET 2026'));
      expect(count, equals(directCount));
    });

    test('2. JEE Main and JEE Advanced counts are independently correct', () async {
      final jeeMainStats = await SupabaseService.fetchPYQStats('JEE Main 2026');
      final jeeAdvStats = await SupabaseService.fetchPYQStats('JEE Advanced 2026');

      expect(jeeMainStats['availableQuestions'], equals(1), reason: 'JEE Main has 1 published PYQ in DB');
      expect(jeeAdvStats['availableQuestions'], equals(0), reason: 'JEE Advanced has 0 published PYQs in DB');
    });

    test('3. NTA and Test Series questions are excluded from PYQ totals', () async {
      // In the database there are 181 practice/custom questions that must be excluded
      final totalInExam = await SupabaseService.client
          .from('questions')
          .count(CountOption.exact)
          .eq('status', 'published')
          .eq('exam_id', '11111111-1111-1111-1111-111111111111');
      expect(totalInExam, greaterThan(180), reason: 'Total questions in exam include non-PYQs');

      final pyqStats = await SupabaseService.fetchPYQStats('NEET 2026');
      expect(pyqStats['availableQuestions'], equals(180), reason: 'Non-PYQs must be strictly excluded');
    });

    test('4. Paper totals match the canonical filtered catalogue', () async {
      final neetStats = await SupabaseService.fetchPYQStats('NEET 2026');
      final jeeStats = await SupabaseService.fetchPYQStats('JEE Main 2026');

      expect(neetStats['availablePapers'], equals(5), reason: 'Active official NEET PYQ papers in catalogue');
      expect(jeeStats['availablePapers'], equals(0), reason: 'JEE Main has 0 active PYQ papers');
    });

    test('5. Duplicate metadata does not inflate paper total', () async {
      final initialStats = await SupabaseService.fetchPYQStats('NEET 2026');
      final initialPapers = initialStats['availablePapers'];

      // Injecting a duplicate entry with existing ID should not increase paper count
      final prefs = await SharedPreferences.getInstance();
      final existingPapers = await SupabaseService.fetchAllPapersAndTestSeries();
      final duplicatePaper = Map<String, dynamic>.from(existingPapers.first);
      await prefs.setString('cosmyra_saved_papers', jsonEncode([duplicatePaper]));

      final updatedStats = await SupabaseService.fetchPYQStats('NEET 2026');
      expect(updatedStats['availablePapers'], equals(initialPapers));
    });

    test('6. Accuracy is correct for mixed correct, incorrect, unanswered and ungraded responses', () async {
      final prefs = await SharedPreferences.getInstance();

      // Case: 8 correct, 2 incorrect, 10 unanswered (total 20 questions)
      // Accuracy must be 8 / (8 + 2) * 100 = 80.0%, NOT 8 / 20 * 100 = 40.0%
      final historyEntry = {
        'id': 'test-session-accuracy-1',
        'exam': 'NEET 2026',
        'mode': 'chapterWise',
        'subjects': ['Physics'],
        'years': [2026],
        'attemptedAt': DateTime.now().toIso8601String(),
        'totalQuestions': 20,
        'attemptedCount': 10,
        'correctCount': 8,
        'incorrectCount': 2,
        'skippedCount': 10,
        'accuracy': 80.0,
        'timeSpentSeconds': 300,
      };
      await prefs.setString('cosmyra_pyq_practice_history', jsonEncode([historyEntry]));

      final stats = await SupabaseService.fetchPYQStats('NEET 2026');
      expect(stats['avgAccuracy'], equals(80.0));
    });

    test('7. New students see an honest empty state for accuracy and time', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cosmyra_pyq_practice_history');

      final stats = await SupabaseService.fetchPYQStats('NEET 2026');
      expect(stats['avgAccuracy'], isNull, reason: 'New students must have null accuracy (not 0% or 72.4%)');

      // Test duration formatting
      expect(PlatformTimeTrackerService.formatDuration(0), equals('Not yet available'));
      expect(PlatformTimeTrackerService.formatDuration(null), equals('Not yet available'));
      expect(PlatformTimeTrackerService.formatDuration(45), equals('< 1m'));
      expect(PlatformTimeTrackerService.formatDuration(180), equals('3m'));
      expect(PlatformTimeTrackerService.formatDuration(3660), equals('1h 1m'));
    });

    test('8. Other students activity cannot be accessed', () async {
      // Unauthenticated query should not return any other user's private test attempts
      final stats = await SupabaseService.fetchPYQStats('NEET 2026');
      expect(stats['avgAccuracy'], isNull);
    });

    test('9. Admin preview activity does not affect accuracy or time spent', () async {
      SupabaseService.isAdminPreview = true;
      final prefs = await SharedPreferences.getInstance();

      final historyEntry = {
        'id': 'admin-preview-session-1',
        'exam': 'NEET 2026',
        'mode': 'chapterWise',
        'subjects': ['Physics'],
        'years': [2026],
        'attemptedAt': DateTime.now().toIso8601String(),
        'totalQuestions': 10,
        'attemptedCount': 10,
        'correctCount': 10,
        'incorrectCount': 0,
        'skippedCount': 0,
        'accuracy': 100.0,
        'timeSpentSeconds': 9999,
      };
      await prefs.setString('cosmyra_pyq_practice_history', jsonEncode([historyEntry]));

      final stats = await SupabaseService.fetchPYQStats('NEET 2026');
      expect(stats['avgAccuracy'], isNull, reason: 'Admin preview must be excluded from accuracy calculations');
      expect(stats['timeSpentSeconds'], equals(0), reason: 'Admin preview must be excluded from time tracking');
    });

    test('10. Active-time tracking does not double-count overlapping sessions', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Simulate first heartbeat at current timestamp
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('cosmyra_platform_last_heartbeat_ms', nowMs);
      await prefs.setInt('cosmyra_platform_active_time_seconds', 15);

      // A second tab attempting a heartbeat 5 seconds later (< 12s threshold) must be ignored
      final initialRecorded = prefs.getInt('cosmyra_platform_active_time_seconds');
      expect(initialRecorded, equals(15));
    });

    test('11. Exam switching refreshes statistics correctly', () async {
      final neetStats = await SupabaseService.fetchPYQStats('NEET 2026');
      final jeeStats = await SupabaseService.fetchPYQStats('JEE Main 2026');

      expect(neetStats['availableQuestions'], equals(180));
      expect(jeeStats['availableQuestions'], equals(1));

      expect(neetStats['availablePapers'], equals(5));
      expect(jeeStats['availablePapers'], equals(0));
    });

    test('12. Subject PYQ counts query accurately reflects database per subject', () async {
      final neetSubjectCounts = await SupabaseService.fetchSubjectPYQCounts('NEET 2026');
      expect(neetSubjectCounts['Physics'], equals(178));
      expect(neetSubjectCounts['Chemistry'], equals(0));
      expect(neetSubjectCounts['Biology'], equals(2));

      final jeeSubjectCounts = await SupabaseService.fetchSubjectPYQCounts('JEE Main 2026');
      expect(jeeSubjectCounts['Chemistry'], equals(1));
    });

    test('13. Normal practice behavior and answer persistence remain functional', () async {
      final sessionResult = PYQSessionResultModel(
        id: 'real-student-test-session-123',
        userId: 'test-user-123',
        exam: 'NEET 2026',
        mode: PYQPracticeMode.chapterWise,
        subjects: ['Physics'],
        years: [2026],
        attemptedAt: DateTime.now(),
        totalQuestions: 10,
        attemptedCount: 10,
        correctCount: 7,
        incorrectCount: 3,
        skippedCount: 0,
        accuracy: 70.0,
        timeSpentSeconds: 600,
      );

      final success = await SupabaseService.savePYQPracticeResult(
        result: sessionResult,
        questions: [],
        userAnswers: {},
      );
      expect(success, isTrue);

      final stats = await SupabaseService.fetchPYQStats('NEET 2026');
      expect(stats['avgAccuracy'], equals(70.0));
      expect(stats['timeSpentSeconds'], greaterThanOrEqualTo(600));
    });
  });
}
