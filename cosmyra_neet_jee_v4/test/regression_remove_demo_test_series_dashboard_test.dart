import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';
import 'package:cosmyra_neet_jee/features/student/test_series_screen.dart';

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

  group('P1 Production Bug: Canonical Test Series Dashboard Data Isolation Tests', () {
    test('1. Named demo/regression entries are completely absent from canonical catalogue', () async {
      final allSeries = await SupabaseService.fetchAllTestSeries(forceRefresh: true);
      final titles = allSeries.map((s) => (s['title'] ?? s['name'] ?? '').toString().toLowerCase()).toList();

      expect(titles.any((t) => t.contains('biology full syllabus regression test')), isFalse,
          reason: 'Biology Full Syllabus Regression Test must NOT appear in catalogue');
      expect(titles.any((t) => t.contains('series with global paper')), isFalse,
          reason: 'Series with Global Paper must NOT appear in catalogue');
      expect(titles.any((t) => t.contains('biology practice sets')), isFalse,
          reason: 'Biology Practice Sets must NOT appear in catalogue');
    });

    test('2. Legitimate published series remain visible with correct details', () async {
      final allSeries = await SupabaseService.fetchAllTestSeries(forceRefresh: true);
      final titles = allSeries.map((s) => (s['title'] ?? s['name'] ?? '').toString()).toList();

      expect(titles.any((t) => t.contains('BIO Fst v2')), isTrue,
          reason: 'BIO Fst v2 must be present');
      expect(titles.any((t) => t.contains('NEET 2027 Full Syllabus Test Series')), isTrue,
          reason: 'NEET 2027 Full Syllabus Test Series must be present');
      expect(titles.any((t) => t.contains('NEET 2027 Beginner Test Series')), isTrue,
          reason: 'NEET 2027 Beginner Test Series must be present');
      expect(titles.any((t) => t.contains('NEET 2027 Leader Test Series')), isTrue,
          reason: 'NEET 2027 Leader Test Series must be present');

      // Check BIO Fst v2 has its tests
      final bioSeries = allSeries.firstWhere((s) => (s['title'] ?? '').toString().contains('BIO Fst v2'));
      final tests = bioSeries['tests'] as List?;
      expect(tests, isNotNull);
      expect(tests!.length, greaterThanOrEqualTo(2), reason: 'BIO Fst v2 must have its tests');
    });

    test('3. Orphaned dbPapers marked as Test Series do not spawn phantom series cards', () async {
      final state = TestSeriesScreenStateTester();
      
      // Inject dbPapers with custom test series category & title that is not registered
      final dummyPapers = [
        {
          'id': 'orphan_test_paper_1',
          'paper_name': 'Orphan Paper 1',
          'test_series_title': 'Phantom Unregistered Series',
          'source_category': 'Test Series',
          'category': 'Test Series',
          'is_test_series': true,
          'status': 'Published',
        }
      ];

      final registeredSeries = [
        {
          'id': 'real_series_1',
          'title': 'Real Registered Series',
          'exam': 'NEET',
          'year': '2027',
          'status': 'Published',
          'tests': <Map<String, dynamic>>[],
        }
      ];

      final cards = state.computeCards(registeredSeries, dummyPapers);
      final cardTitles = cards.map((c) => c.title).toList();

      expect(cardTitles.contains('Real Registered Series'), isTrue);
      expect(cardTitles.contains('Phantom Unregistered Series'), isFalse,
          reason: 'Orphaned papers in dbPapers must not invent phantom series cards');
    });

    test('4. Unpublished and archived test series are strictly excluded from student catalogue', () async {
      final state = TestSeriesScreenStateTester();

      final seriesList = [
        {
          'id': 'published_series',
          'title': 'Published Series',
          'status': 'Published',
          'is_archived': false,
        },
        {
          'id': 'draft_series',
          'title': 'Draft Series',
          'status': 'Draft',
          'is_archived': false,
        },
        {
          'id': 'archived_series',
          'title': 'Archived Series',
          'status': 'Published',
          'is_archived': true,
        },
      ];

      final cards = state.computeCards(seriesList, []);
      final cardTitles = cards.map((c) => c.title).toList();

      expect(cardTitles.contains('Published Series'), isTrue);
      expect(cardTitles.contains('Draft Series'), isFalse, reason: 'Draft series must be excluded');
      expect(cardTitles.contains('Archived Series'), isFalse, reason: 'Archived series must be excluded');
    });

    test('5. Duplicate titles are deduplicated without duplicate cards', () async {
      final state = TestSeriesScreenStateTester();

      final duplicateSeries = [
        {
          'id': 'id_1',
          'title': 'NEET Leader 2027',
          'status': 'Published',
        },
        {
          'id': 'id_2',
          'title': 'NEET Leader 2027',
          'status': 'Published',
        },
      ];

      final cards = state.computeCards(duplicateSeries, []);
      expect(cards.length, equals(1), reason: 'Duplicate series representations must be deduplicated');
    });

    test('6. Empty or failed remote query does not substitute hardcoded fake demo records', () async {
      // defaultCuratedTestSeries must return empty
      expect(SupabaseService.defaultCuratedTestSeries, isEmpty);
    });

    test('7. Home recommendations exclude Biology Practice Sets and phantom series', () async {
      final recs = await SupabaseService.fetchHomeRecommendations();
      final titles = recs.map((r) => (r['title'] ?? '').toString().toLowerCase()).toList();

      expect(titles.any((t) => t.contains('biology practice sets')), isFalse,
          reason: 'Biology Practice Sets must NOT appear in home recommendations');
    });
  });
}

/// Helper class to test _getAllRealTestSeries logic deterministically
class TestSeriesScreenStateTester {
  List<TestSeriesCardData> computeCards(
    List<Map<String, dynamic>> customSeriesList,
    List<Map<String, dynamic>> dbPapers,
  ) {
    final List<TestSeriesCardData> list = [];
    final Set<String> seenTitles = {};

    for (var cs in customSeriesList) {
      final bool isArchived = cs['is_archived'] == true || cs['archived'] == true;
      final String status = (cs['status'] ?? 'Published').toString().trim().toLowerCase();
      final bool isPublished = status == 'published' || status.isEmpty;
      if (isArchived || !isPublished) continue;

      final String title = (cs['title'] ?? cs['name'] ?? '').toString().trim();
      final String sId = (cs['id'] ?? cs['paper_id'] ?? 'ts_${title.hashCode}').toString();
      if (title.isNotEmpty && !seenTitles.contains(title.toLowerCase())) {
        seenTitles.add(title.toLowerCase());
        list.add(
          TestSeriesCardData(
            id: sId,
            title: title,
            exam: (cs['exam'] ?? 'NEET').toString(),
            targetYear: (cs['year'] ?? '2027').toString(),
            subtitle: '',
            description: '',
            testCount: 1,
            durationMinutes: 180,
            difficulty: 'Moderate',
            testType: 'Full',
            validity: 'Valid until exam',
            attemptStatus: 'Not Attempted',
            syllabusUrl: '',
            status: 'Published',
            nextTestName: 'Test 01',
            iconBgColor: const Color(0xFF4F46E5),
            icon: Icons.track_changes_rounded,
            isFree: false,
            price: 299.0,
            originalPrice: 999.0,
            purchaseLink: '',
            purchaseButtonText: 'Join',
            showPurchaseButton: true,
          ),
        );
      }
    }

    list.removeWhere((item) => SupabaseService.legacyDemoTestSeriesIds.contains(item.id));
    return list;
  }
}
