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

  // Simulated faulty previous catalogue router (from commit 361958f / before fix)
  String legacyFaultyGetPaperCatalogue(Map<String, dynamic> p) {
    final cat = (p['source_category'] ?? p['sourceCategory'] ?? p['category'] ?? p['paper_type'] ?? '').toString().toUpperCase();
    final title = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? '').toString().toLowerCase();
    final id = (p['id'] ?? p['paper_id'] ?? '').toString().toLowerCase();
    final isPyq = p['is_pyq'] == true;
    final isNta = p['is_nta'] == true;
    final isTestSeries = p['is_test_series'] == true;

    if (isTestSeries || cat == 'TEST_SERIES' || cat == 'TEST SERIES' || title.contains('test series') || title.contains('mock test') || title.contains('fst')) {
      return 'Test Series';
    }
    if (isNta || cat == 'NTA' || (title.contains('nta') && !title.contains('pyq') && !isPyq)) {
      return 'NTA';
    }
    if (isPyq || cat == 'PYQ' || id.startsWith('neet_') || id.startsWith('jee_') || title.contains('official pyq') || title.contains('phase 1') || title.contains('re-neet') || title.contains('paper 1') || title.contains('pyq')) {
      return 'PYQ';
    }
    if (title.contains('test') || title.contains('series')) return 'Test Series';
    // FAULTY DEFAULT: Dumped everything ambiguous to PYQ!
    return 'PYQ';
  }

  // Current corrected catalogue router
  String correctedGetPaperCatalogue(Map<String, dynamic> p) {
    if (SupabaseService.isTestSeriesContainer(p)) {
      return 'InvalidContainer';
    }

    final cat = (p['source_category'] ?? p['sourceCategory'] ?? p['category'] ?? p['paper_type'] ?? '').toString().toUpperCase();
    final title = ((p['paper_name']?.toString().trim().isNotEmpty == true)
            ? p['paper_name'].toString().trim()
            : ((p['paperName']?.toString().trim().isNotEmpty == true)
                ? p['paperName'].toString().trim()
                : ((p['title']?.toString().trim().isNotEmpty == true)
                    ? p['title'].toString().trim()
                    : ((p['name']?.toString().trim().isNotEmpty == true) ? p['name'].toString().trim() : ''))))
        .toLowerCase();

    final id = (p['id'] ?? p['paper_id'] ?? '').toString().toLowerCase().trim();
    final isPyq = p['is_pyq'] == true;
    final isNta = p['is_nta'] == true;
    final isTestSeries = p['is_test_series'] == true;
    final hasSeriesParent = (p['test_series_id'] != null && p['test_series_id'].toString().trim().isNotEmpty);

    if (isTestSeries ||
        hasSeriesParent ||
        cat == 'TEST_SERIES' ||
        cat == 'TEST SERIES' ||
        cat == 'TEST_SERIES_PAPERS' ||
        title.contains('test series') ||
        title.contains('mock test') ||
        title.contains('fst') ||
        title.contains('leader test series') ||
        title.contains('beginner test series') ||
        title.contains('full syllabus test series') ||
        p.containsKey('series_name')) {
      return 'Test Series';
    }

    if (isNta || cat == 'NTA' || (title.contains('nta') && !title.contains('pyq') && !isPyq)) {
      return 'NTA';
    }

    if (isPyq ||
        cat == 'PYQ' ||
        id.startsWith('neet_') ||
        id.startsWith('jee_') ||
        title.contains('official pyq') ||
        title.contains('phase 1') ||
        title.contains('phase 2') ||
        title.contains('re-neet') ||
        title.contains('paper 1') ||
        title.contains('pyq')) {
      return 'PYQ';
    }

    if (title.contains('test') || title.contains('series') || title.contains('mock')) {
      return 'Test Series';
    }

    return 'Ambiguous';
  }

  // Realistic production fixtures matching the exact shape in Supabase system_config
  final Map<String, dynamic> beginnerSeriesFixture = {
    'id': '9cca7648-4f81-4638-a013-9cca4f81c638',
    'exam': 'NEET',
    'name': 'NEET 2027 Beginner Test Series',
    'title': 'NEET 2027 Beginner Test Series',
    'paper_name': '', // Blank title as observed in production
    'slug': 'neet-2027-beginner-test-series',
    'year': '2027',
    'price': 249,
    'status': 'Published',
    'is_free': false,
    'category': 'Chapter + Part + Unit + Full Syllabus',
    'currency': 'INR',
    'features': ['100% NTA Exam Pattern', 'All India Rank Prediction'],
    'paper_id': '',
    'validity': 'Valid until exam',
    'test_type': 'Chapter + Part + Unit + Full',
    'test_count': 32,
    'checkout_url': 'https://neet-jee.in/checkout?productId=9cca7648-4f81-4638-a013-9cca4f81c638',
    'product_url': 'https://neet-jee.in/product/9cca7648-4f81-4638-a013-9cca4f81c638',
    'tests': [
      {
        'id': 'test_1790831626913',
        'type': 'Chapter + Part + Unit + Full Syllabus',
        'marks': 720,
        'title': 'Mock Test 1',
        'status': 'Not Attempted',
        'duration': 180,
        'paper_id': 'test_1790831626913',
        'questions': 200,
      },
      {
        'id': 'test_1790831626914',
        'type': 'Chapter + Part + Unit + Full Syllabus',
        'marks': 720,
        'title': 'Mock Test 2',
        'status': 'Not Attempted',
        'duration': 180,
        'paper_id': 'test_1790831626914',
        'questions': 200,
      },
    ],
  };

  final Map<String, dynamic> leaderSeriesFixture = {
    'id': 'cec367ad-de65-4619-a029-cec3de657619',
    'exam': 'NEET',
    'name': 'NEET 2027 Leader Test Series',
    'title': 'NEET 2027 Leader Test Series',
    'paper_name': '', // Blank title as observed in production
    'slug': 'neet-2027-leader-test-series',
    'year': '2027',
    'price': 249,
    'status': 'Published',
    'is_free': false,
    'category': 'Full Syllabus',
    'currency': 'INR',
    'features': ['100% NTA Exam Pattern', 'Step-by-Step Solutions'],
    'paper_id': '',
    'validity': 'Valid until exam',
    'test_type': 'Full',
    'test_count': 33,
    'checkout_url': 'https://neet-jee.in/checkout?productId=cec367ad-de65-4619-a029-cec3de657619',
    'product_url': 'https://neet-jee.in/product/cec367ad-de65-4619-a029-cec3de657619',
    'tests': [
      {
        'id': '6237b088-76ac-4eaf-a03e-623776ac5eaf',
        'type': 'Full Syllabus',
        'marks': 720,
        'title': 'NEET 2027 Leader Test Series - Paper 1',
        'status': 'Not Attempted',
        'duration': 180,
        'paper_id': '6237b088-76ac-4eaf-a03e-623776ac5eaf',
        'questions': 180,
      },
    ],
  };

  group('P0 Regression Tests: Test Series Containers vs Individual Papers', () {
    test('1. Confirm previous faulty parser incorrectly routed containers to PYQ', () {
      // In the previous faulty parser, when the container object was added to the paper list:
      // paper_name was empty string '', so title was '', and it fell through to default 'PYQ'
      final faultyCat1 = legacyFaultyGetPaperCatalogue(beginnerSeriesFixture);
      final faultyCat2 = legacyFaultyGetPaperCatalogue(leaderSeriesFixture);

      expect(faultyCat1, equals('PYQ'), reason: 'Previous faulty parser leaked 9cca7648 container into PYQ due to default fallback');
      expect(faultyCat2, equals('PYQ'), reason: 'Previous faulty parser leaked cec367ad container into PYQ due to default fallback');
    });

    test('2. Corrected parser and schema detector identify containers and reject them from PYQ', () {
      expect(SupabaseService.isTestSeriesContainer(beginnerSeriesFixture), isTrue);
      expect(SupabaseService.isTestSeriesContainer(leaderSeriesFixture), isTrue);

      expect(SupabaseService.isValidIndividualPaper(beginnerSeriesFixture), isFalse);
      expect(SupabaseService.isValidIndividualPaper(leaderSeriesFixture), isFalse);

      final cat1 = correctedGetPaperCatalogue(beginnerSeriesFixture);
      final cat2 = correctedGetPaperCatalogue(leaderSeriesFixture);

      expect(cat1, equals('InvalidContainer'));
      expect(cat2, equals('InvalidContainer'));
      expect(cat1, isNot(equals('PYQ')));
      expect(cat2, isNot(equals('PYQ')));
    });

    test('3. Verify fetchAllPapersAndTestSeries excludes container IDs from production data', () async {
      final papers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);

      final ghostIds = [
        '9cca7648-4f81-4638-a013-9cca4f81c638',
        'cec367ad-de65-4619-a029-cec3de657619',
        'dc86cc30-956a-4ade-a030-dc86956acade',
      ];

      for (var gid in ghostIds) {
        final found = papers.any((p) => (p['id'] ?? p['paper_id'] ?? '').toString() == gid);
        expect(found, isFalse, reason: 'Container ID $gid must never appear as an individual paper');
      }

      // Check PYQ catalogue specifically
      final pyqs = papers.where((p) => correctedGetPaperCatalogue(p) == 'PYQ').toList();
      for (var gid in ghostIds) {
        final foundInPyq = pyqs.any((p) => (p['id'] ?? p['paper_id'] ?? '').toString() == gid);
        expect(foundInPyq, isFalse, reason: 'Container ID $gid must never leak into PYQ catalogue');
      }
    });

    test('4. Test Series containers and their nested tests remain accessible in Test Series Manager', () async {
      final testSeriesList = await SupabaseService.fetchAllTestSeries();
      expect(testSeriesList, isNotEmpty);

      final beginnerSeries = testSeriesList.firstWhere(
        (s) => s['id'] == '9cca7648-4f81-4638-a013-9cca4f81c638',
        orElse: () => {},
      );
      expect(beginnerSeries, isNotEmpty);
      expect((beginnerSeries['tests'] as List).length, greaterThanOrEqualTo(1));

      final leaderSeries = testSeriesList.firstWhere(
        (s) => s['id'] == 'cec367ad-de65-4619-a029-cec3de657619',
        orElse: () => {},
      );
      expect(leaderSeries, isNotEmpty);
      expect((leaderSeries['tests'] as List).length, greaterThanOrEqualTo(1));
    });

    test('5. Nested test papers retain canonical IDs and relationships without leaking to PYQ', () async {
      final papers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);

      // Embedded test from beginner test series
      final test1 = papers.firstWhere(
        (p) => (p['id'] ?? p['paper_id'] ?? '') == 'test_1790831626913',
        orElse: () => {},
      );
      expect(test1, isNotEmpty);
      expect(test1['test_series_id'], equals('9cca7648-4f81-4638-a013-9cca4f81c638'));
      expect(test1['is_test_series'], isTrue);
      expect(correctedGetPaperCatalogue(test1), equals('Test Series'));
      expect(correctedGetPaperCatalogue(test1), isNot(equals('PYQ')));

      // Embedded test from leader test series
      final leaderTest1 = papers.firstWhere(
        (p) => (p['id'] ?? p['paper_id'] ?? '') == '6237b088-76ac-4eaf-a03e-623776ac5eaf',
        orElse: () => {},
      );
      expect(leaderTest1, isNotEmpty);
      expect(leaderTest1['test_series_id'], equals('cec367ad-de65-4619-a029-cec3de657619'));
      expect(leaderTest1['is_test_series'], isTrue);
      expect(correctedGetPaperCatalogue(leaderTest1), equals('Test Series'));
      expect(correctedGetPaperCatalogue(leaderTest1), isNot(equals('PYQ')));
    });

    test('6. Genuine PYQ papers remain intact and visible in PYQ catalogue', () async {
      final papers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final pyqs = papers.where((p) => correctedGetPaperCatalogue(p) == 'PYQ').toList();

      final expectedPyqIds = [
        'neet_2026_reneet',
        'neet_2026_phase_1',
        'neet_2025_paper_1',
        'neet_2024_paper_1',
        'neet_2023_paper_1',
        'neet_2022_paper_1',
        'neet_2021_paper_1',
      ];

      for (var id in expectedPyqIds) {
        final found = pyqs.any((p) => (p['id'] ?? p['paper_id'] ?? '') == id);
        expect(found, isTrue, reason: 'Genuine PYQ paper $id must be present in PYQ catalogue');
      }
    });

    test('7. Multiple consecutive refreshes cannot reintroduce container rows', () async {
      for (int i = 0; i < 3; i++) {
        final refreshed = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
        final hasGhost1 = refreshed.any((p) => (p['id'] ?? p['paper_id'] ?? '') == '9cca7648-4f81-4638-a013-9cca4f81c638');
        final hasGhost2 = refreshed.any((p) => (p['id'] ?? p['paper_id'] ?? '') == 'cec367ad-de65-4619-a029-cec3de657619');
        expect(hasGhost1, isFalse);
        expect(hasGhost2, isFalse);
      }
    });
  });
}
