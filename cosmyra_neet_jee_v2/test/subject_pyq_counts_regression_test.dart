import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';
import 'package:cosmyra_neet_jee/shared/utils/neet_subject_helper.dart';

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

  group('Subject PYQ Counts Live Database & Regression Tests', () {
    test('1. Subject counts match actual distinct eligible question IDs in database', () async {
      final neetCounts = await SupabaseService.fetchSubjectPYQCounts('NEET 2026');
      
      // Verified database counts for 180-question NEET paper
      expect(neetCounts['Physics'], equals(45), reason: 'NEET Physics has 45 questions');
      expect(neetCounts['Chemistry'], equals(45), reason: 'NEET Chemistry has 45 questions');
      expect(neetCounts['Biology'], equals(90), reason: 'NEET Biology has 90 questions');
      expect(neetCounts.values.reduce((a, b) => a + b), equals(180));
    });

    test('2. JEE Main and JEE Advanced use independent subject sets and accurate counts', () async {
      final jeeMainCounts = await SupabaseService.fetchSubjectPYQCounts('JEE Main 2026');
      expect(jeeMainCounts.containsKey('Mathematics'), isTrue);
      expect(jeeMainCounts.containsKey('Biology'), isFalse);
      expect(jeeMainCounts['Physics'], equals(0));
      expect(jeeMainCounts['Chemistry'], equals(0));
      expect(jeeMainCounts['Mathematics'], equals(0));

      final jeeAdvCounts = await SupabaseService.fetchSubjectPYQCounts('JEE Advanced 2026');
      expect(jeeAdvCounts.containsKey('Mathematics'), isTrue);
      expect(jeeAdvCounts['Physics'], equals(0));
      expect(jeeAdvCounts['Chemistry'], equals(0));
      expect(jeeAdvCounts['Mathematics'], equals(0));
    });

    test('3. NTA and Test Series questions are excluded from subject totals', () async {
      // Query raw questions with source != pyq or status != published
      final nonPyqRes = await SupabaseService.client
          .from('questions')
          .select('id, source, exam_id')
          .neq('source', 'pyq');
      final nonPyqCount = (nonPyqRes as List).length;
      expect(nonPyqCount, greaterThan(0), reason: 'Non-PYQ questions exist in database');

      // fetchSubjectPYQCounts must strictly filter source = 'pyq'
      final neetCounts = await SupabaseService.fetchSubjectPYQCounts('NEET 2026');
      final totalPyqSubjects = neetCounts.values.reduce((a, b) => a + b);
      expect(totalPyqSubjects, equals(180), reason: 'Must only count published PYQ questions');
    });

    test('4. Unknown subject IDs are never silently misclassified', () {
      final unknown1 = NeetSubjectHelper.getSubjectNameFromId('random_unknown_uuid');
      expect(unknown1, equals('random_unknown_uuid'));
      expect(unknown1, isNot(equals('Physics')));
      expect(unknown1, isNot(equals('Chemistry')));
      expect(unknown1, isNot(equals('Biology')));
      expect(unknown1, isNot(equals('Mathematics')));

      final unknown2 = NeetSubjectHelper.getSubjectNameFromId('unknown_jee_subject', exam: 'JEE Main');
      expect(unknown2, equals('unknown_jee_subject'));
      expect(unknown2, isNot(equals('Physics')));
      expect(unknown2, isNot(equals('Chemistry')));
      expect(unknown2, isNot(equals('Mathematics')));
    });

    test('5. Legitimate zero count displays 0 without falling back to demo values', () async {
      final jeeCounts = await SupabaseService.fetchSubjectPYQCounts('JEE Main 2026');
      expect(jeeCounts['Physics'], equals(0));
      expect(jeeCounts['Physics'], isNot(equals(300)));
      expect(jeeCounts['Physics'], isNot(equals(520)));
      expect(jeeCounts['Chemistry'], equals(0));
      expect(jeeCounts['Mathematics'], equals(0));
    });

    test('6. Duplicate question rows do not inflate subject counts', () {
      final sampleRows = [
        {'id': 'q-1', 'subject_id': 'a1111111-1111-1111-1111-111111111111'},
        {'id': 'q-1', 'subject_id': 'a1111111-1111-1111-1111-111111111111'}, // duplicate
        {'id': 'q-2', 'subject_id': 'a1111111-1111-1111-1111-111111111111'},
        {'id': 'q-3', 'subject_id': 'a3333333-3333-3333-3333-333333333333'},
      ];

      final Map<String, int> counts = {'Physics': 0, 'Chemistry': 0, 'Biology': 0};
      final Set<String> seenIds = {};

      for (var r in sampleRows) {
        final qId = r['id']!;
        if (seenIds.contains(qId)) continue;
        seenIds.add(qId);

        final sId = r['subject_id']!;
        final sName = NeetSubjectHelper.getSubjectNameFromId(sId, exam: 'NEET');
        if (counts.containsKey(sName)) {
          counts[sName] = counts[sName]! + 1;
        }
      }

      expect(counts['Physics'], equals(2)); // not 3
      expect(counts['Biology'], equals(1));
    });
  });
}
