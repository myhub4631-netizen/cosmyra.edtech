import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/services/supabase_service.dart';

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

  group('Admin PYQ Paper Manager CRUD Integration Tests', () {
    final String testPaperId = 'test_pyq_crud_${DateTime.now().millisecondsSinceEpoch}';

    test('1. Create Paper Record Test', () async {
      final createData = {
        'id': testPaperId,
        'paper_name': 'NEET 2026 Test Practice Paper',
        'paper_code': 'N26TP',
        'exam': 'NEET',
        'year': '2026',
        'phase_session': 'Phase 1',
        'source_category': 'PYQ',
        'is_pyq': true,
        'status': 'Published',
        'expected_question_count': 180,
      };

      final saved = await SupabaseService.savePaperRecord(createData);
      expect(saved['id'], equals(testPaperId));
      expect(saved['paper_name'], equals('NEET 2026 Test Practice Paper'));
      expect(saved['source_category'], equals('PYQ'));

      final all = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final found = all.any((p) => p['id'] == testPaperId);
      expect(found, isTrue, reason: 'Created paper must appear in fetched papers catalogue');
      print('✓ 1. Create Paper Record Test passed.');
    });

    test('2. Read & View Details Test', () async {
      final paper = await SupabaseService.fetchPaperById(testPaperId);
      expect(paper, isNotNull);
      expect(paper!['id'], equals(testPaperId));
      expect(paper['exam'], equals('NEET'));
      expect(paper['year'], equals('2026'));
      print('✓ 2. Read & View Details Test passed.');
    });

    test('3. Update / Edit Metadata Test', () async {
      final paper = await SupabaseService.fetchPaperById(testPaperId);
      expect(paper, isNotNull);

      final updateData = {
        ...paper!,
        'paper_name': 'NEET 2026 Test Practice Paper (Updated)',
        'status': 'Draft',
      };

      final updated = await SupabaseService.savePaperRecord(updateData);
      expect(updated['paper_name'], equals('NEET 2026 Test Practice Paper (Updated)'));
      expect(updated['status'], equals('Draft'));
      expect(updated['source_category'], equals('PYQ'));

      final fetched = await SupabaseService.fetchPaperById(testPaperId);
      expect(fetched!['paper_name'], equals('NEET 2026 Test Practice Paper (Updated)'));
      expect(fetched['status'], equals('Draft'));
      print('✓ 3. Update / Edit Metadata Test passed.');
    });

    test('4. Archive & Restore Test', () async {
      final archOk = await SupabaseService.archivePaperRecord(testPaperId, isArchived: true);
      expect(archOk, isTrue);

      var fetched = await SupabaseService.fetchPaperById(testPaperId);
      expect(fetched!['status'], equals('Archived'));

      final restOk = await SupabaseService.archivePaperRecord(testPaperId, isArchived: false);
      expect(restOk, isTrue);

      fetched = await SupabaseService.fetchPaperById(testPaperId);
      expect(fetched!['status'], equals('Published'));
      print('✓ 4. Archive & Restore Test passed.');
    });

    test('5. Safe Delete Paper Record Test', () async {
      final delOk = await SupabaseService.deletePaperRecord(testPaperId);
      expect(delOk, isTrue);

      final fetched = await SupabaseService.fetchPaperById(testPaperId);
      expect(fetched, isNull, reason: 'Deleted paper must no longer exist in catalogue');
      print('✓ 5. Safe Delete Paper Record Test passed.');
    });

    test('6. Canonical NEET 2026 Paper 1 Integrity Test', () async {
      final neet2026 = await SupabaseService.fetchPaperById('neet_2026_phase_1');
      expect(neet2026, isNotNull);
      expect(neet2026!['paper_name'], contains('NEET 2026'));

      final questions = await SupabaseService.fetchQuestionsForPaper(neet2026['id']);
      expect(questions.length, greaterThanOrEqualTo(175), reason: 'Canonical NEET 2026 paper questions must be preserved');
      print('✓ 6. Canonical NEET 2026 Paper 1 Integrity Test passed (${questions.length} Qs preserved).');
    });
  });
}
