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

  group('Delete Paper Persistence & Resurrect Prevention Tests', () {
    setUpAll(() async {
      HttpOverrides.global = MyHttpOverrides();
      SharedPreferences.setMockInitialValues({});
      await SupabaseService.initialize();
    });

    test('1. Delete Custom Paper Persistence Test', () async {
      final String customPaperId = 'paper_test_delete_${DateTime.now().millisecondsSinceEpoch}';

      final created = await SupabaseService.savePaperRecord({
        'id': customPaperId,
        'paper_name': 'Disposable Test Paper for Deletion',
        'exam': 'NEET',
        'year': '2026',
        'source_category': 'PYQ',
        'is_pyq': true,
        'status': 'Published',
      });
      expect(created['id'], equals(customPaperId));

      var fetched = await SupabaseService.fetchPaperById(customPaperId);
      expect(fetched, isNotNull);
      expect(fetched!['paper_name'], equals('Disposable Test Paper for Deletion'));

      final delOk = await SupabaseService.deletePaperRecord(customPaperId);
      expect(delOk, isTrue);

      fetched = await SupabaseService.fetchPaperById(customPaperId);
      expect(fetched, isNull, reason: 'Deleted paper must not be returned after fetchPaperById');

      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final exists = allPapers.any((p) => (p['id'] ?? p['paper_id'] ?? '') == customPaperId);
      expect(exists, isFalse, reason: 'Deleted paper must remain absent from full catalogue after reload');
    });

    test('2. Delete Official PYQ Paper (Resurrection Guard) Test', () async {
      const String officialPaperId = 'neet_2021_paper_1';

      var fetched = await SupabaseService.fetchPaperById(officialPaperId);
      expect(fetched, isNotNull, reason: 'Official NEET 2021 paper must initially exist in catalogue');

      final delOk = await SupabaseService.deletePaperRecord(officialPaperId);
      expect(delOk, isTrue);

      fetched = await SupabaseService.fetchPaperById(officialPaperId);
      expect(fetched, isNull, reason: 'Official paper must not resurrect after deletion');

      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final exists = allPapers.any((p) => (p['id'] ?? p['paper_id'] ?? '') == officialPaperId);
      expect(exists, isFalse, reason: 'Official paper must not be resurrected by Step 5 hardcoded list');

      // Cleanup: Unmark tombstone so production catalog retains official default if un-deleted
      await SupabaseService.unmarkPaperAsDeleted(officialPaperId);
    });

    test('3. Recreate Deleted Paper Un-tombstones Record Test', () async {
      final String tempPaperId = 'paper_recreate_${DateTime.now().millisecondsSinceEpoch}';

      await SupabaseService.savePaperRecord({
        'id': tempPaperId,
        'paper_name': 'Paper to be Recreated',
        'exam': 'NEET',
        'year': '2026',
        'source_category': 'PYQ',
        'is_pyq': true,
      });

      await SupabaseService.deletePaperRecord(tempPaperId);
      var fetched = await SupabaseService.fetchPaperById(tempPaperId);
      expect(fetched, isNull);

      await SupabaseService.savePaperRecord({
        'id': tempPaperId,
        'paper_name': 'Paper Recreated Success',
        'exam': 'NEET',
        'year': '2026',
        'source_category': 'PYQ',
        'is_pyq': true,
      });

      fetched = await SupabaseService.fetchPaperById(tempPaperId);
      expect(fetched, isNotNull, reason: 'Recreating paper must un-tombstone and restore record');
      expect(fetched!['paper_name'], equals('Paper Recreated Success'));

      await SupabaseService.deletePaperRecord(tempPaperId);
    });
  });
}
