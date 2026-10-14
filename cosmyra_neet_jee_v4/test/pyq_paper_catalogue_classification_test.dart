import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = MyHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  group('PYQ Paper Catalogue Classification & Filtering Tests', () {
    // 1. Realistic fixtures
    final Map<String, dynamic> genuineNeet2022Pyq = {
      'id': 'neet_2022_paper_1',
      'paper_name': 'NEET 2022 (Official PYQ)',
      'title': 'NEET 2022 (Official PYQ)',
      'exam': 'NEET',
      'year': '2022',
      'source_category': 'PYQ',
      'status': 'Published',
    };

    final Map<String, dynamic> neetNtaPaper = {
      'id': 'nta_neet_abhyas_paper_01',
      'paper_name': 'NTA Abhyas Test 01',
      'title': 'NTA Abhyas Test 01',
      'exam': 'NEET',
      'year': '2023',
      'is_nta': true,
      'source_category': 'NTA',
      'status': 'Published',
    };

    final Map<String, dynamic> neetCustomTestSeriesPaper = {
      'id': 'custom_mock_test_01',
      'paper_name': 'NEET Full Syllabus Mock Test 01',
      'title': 'NEET Full Syllabus Mock Test 01',
      'exam': 'NEET',
      'is_test_series': true,
      'test_series_id': 'series_9cca',
      'source_category': 'TEST_SERIES',
      'status': 'Published',
    };

    final Map<String, dynamic> testSeriesContainer = {
      'id': '9cca7648-4f81-4638-a013-9cca4f81c638',
      'name': 'NEET 2027 Beginner Test Series',
      'title': 'NEET 2027 Beginner Test Series',
      'exam': 'NEET',
      'test_count': 32,
      'tests': [
        {'id': 'test_1', 'title': 'Mock Test 1'}
      ],
      'status': 'Published',
    };

    final Map<String, dynamic> jeeMainPyq = {
      'id': 'jee_main_2025_session_1',
      'paper_name': 'JEE Main 2025 Session 1',
      'title': 'JEE Main 2025 Session 1',
      'exam': 'JEE Main',
      'year': '2025',
      'source_category': 'PYQ',
      'status': 'Published',
    };

    final Map<String, dynamic> jeeAdvPyq = {
      'id': 'jee_adv_2024_paper_1',
      'paper_name': 'JEE Advanced 2024 Paper 1',
      'title': 'JEE Advanced 2024 Paper 1',
      'exam': 'JEE Advanced',
      'year': '2024',
      'source_category': 'PYQ',
      'status': 'Published',
    };

    final Map<String, dynamic> archivedNeetPyq = {
      'id': 'neet_archived_legacy',
      'paper_name': 'NEET 2018 Archived PYQ',
      'title': 'NEET 2018 Archived PYQ',
      'exam': 'NEET',
      'year': '2018',
      'source_category': 'PYQ',
      'status': 'Archived',
    };

    final Map<String, dynamic> ambiguousRecord = {
      'id': 'unknown_practice_paper_99',
      'paper_name': 'Weekend Classroom Assessment',
      'title': 'Weekend Classroom Assessment',
      'exam': 'NEET',
      'status': 'Published',
    };

    test('1. SupabaseService.getPaperCatalogue accurately classifies all fixture types', () {
      expect(SupabaseService.getPaperCatalogue(genuineNeet2022Pyq), equals('PYQ'));
      expect(SupabaseService.getPaperCatalogue(neetNtaPaper), equals('NTA'));
      expect(SupabaseService.getPaperCatalogue(neetCustomTestSeriesPaper), equals('Test Series'));
      expect(SupabaseService.getPaperCatalogue(testSeriesContainer), equals('InvalidContainer'));
      expect(SupabaseService.getPaperCatalogue(jeeMainPyq), equals('PYQ'));
      expect(SupabaseService.getPaperCatalogue(jeeAdvPyq), equals('PYQ'));
      expect(SupabaseService.getPaperCatalogue(ambiguousRecord), equals('Other'));
    });

    test('2. fetchAvailablePYQPapers for NEET returns only genuine NEET PYQ papers', () async {
      final neetPapers = await SupabaseService.fetchAvailablePYQPapers('NEET 2026', forceRefresh: true);
      
      expect(neetPapers, isNotEmpty);
      for (var p in neetPapers) {
        expect(SupabaseService.getPaperCatalogue(p), equals('PYQ'));
        expect(SupabaseService.isTestSeriesContainer(p), isFalse);
        expect(p['is_test_series'], isNot(equals(true)));
        expect(p['is_nta'], isNot(equals(true)));
        
        final exam = (p['exam'] ?? p['target_exam'] ?? '').toString().toUpperCase();
        expect(exam.contains('JEE'), isFalse, reason: 'NEET PYQ papers must not include JEE');
      }
    });

    test('3. Historical PYQ years remain available within the correct exam family and are sorted reverse-chronologically', () async {
      final neetPapers = await SupabaseService.fetchAvailablePYQPapers('NEET 2026', forceRefresh: true);
      
      // NEET 2026, 2025, 2024, 2023, 2022
      final titles = neetPapers.map((p) => p['title'] ?? p['paper_name']).toList();
      print('Available NEET PYQ Papers in order: $titles');

      final found2022 = neetPapers.any((p) => (p['id'] ?? '') == 'neet_2022_paper_1');
      expect(found2022, isTrue, reason: 'Historical NEET 2022 PYQ paper is available for NEET 2026 practice');

      // Check reverse chronological order
      int lastYear = 9999;
      for (var p in neetPapers) {
        final yStr = p['year']?.toString() ?? '';
        final y = int.tryParse(yStr) ?? 0;
        if (y > 0) {
          expect(y, lessThanOrEqualTo(lastYear), reason: 'Papers must be sorted descending by year');
          lastYear = y;
        }
      }
    });

    test('4. NTA and Test Series papers never appear in fetchAvailablePYQPapers', () async {
      final neetPapers = await SupabaseService.fetchAvailablePYQPapers('NEET 2026');
      final hasNta = neetPapers.any((p) => SupabaseService.getPaperCatalogue(p) == 'NTA');
      final hasTestSeries = neetPapers.any((p) => SupabaseService.getPaperCatalogue(p) == 'Test Series');
      final hasContainer = neetPapers.any((p) => SupabaseService.isTestSeriesContainer(p));

      expect(hasNta, isFalse);
      expect(hasTestSeries, isFalse);
      expect(hasContainer, isFalse);
    });

    test('5. Deleted and archived papers are excluded from PYQ papers', () async {
      final neetPapers = await SupabaseService.fetchAvailablePYQPapers('NEET 2026');
      final deletedIds = await SupabaseService.getDeletedPaperIds();

      for (var p in neetPapers) {
        final id = (p['id'] ?? p['paper_id'] ?? '').toString();
        expect(deletedIds.contains(id), isFalse, reason: 'Deleted paper $id must not appear');
        expect(p['status']?.toString().toLowerCase(), isNot(equals('archived')));
        expect(p['status']?.toString().toLowerCase(), isNot(equals('deleted')));
      }
    });

    test('6. fetchAvailablePYQPapers for JEE Main excludes NEET and JEE Advanced', () async {
      final jeePapers = await SupabaseService.fetchAvailablePYQPapers('JEE Main 2026', forceRefresh: true);
      for (var p in jeePapers) {
        final exam = (p['exam'] ?? '').toString().toUpperCase();
        final title = (p['title'] ?? '').toString().toUpperCase();
        expect(exam.contains('NEET'), isFalse);
        expect(title.contains('NEET'), isFalse);
        expect(exam.contains('ADV'), isFalse);
        expect(title.contains('ADVANCED'), isFalse);
      }
    });
  });
}
