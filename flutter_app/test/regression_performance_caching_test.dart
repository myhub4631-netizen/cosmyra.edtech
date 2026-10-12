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

  setUp(() async {
    SupabaseService.invalidateCaches();
    SupabaseService.invalidateEnrollmentCache();
  });

  group('Performance Optimization & Safe Caching Regression Tests', () {
    test('1. Test Series memory cache and in-flight deduplication', () async {
      // Invalidate caches before test
      SupabaseService.invalidateCaches();
      expect(SupabaseService.hasCachedTestSeries, isFalse);

      // Concurrent fetch calls should share in-flight Future
      final futures = await Future.wait([
        SupabaseService.fetchAllTestSeries(),
        SupabaseService.fetchAllTestSeries(),
        SupabaseService.fetchAllTestSeries(exam: 'NEET'),
      ]);

      // All returns should be lists without exception
      expect(futures[0], isA<List>());
      expect(futures[1], isA<List>());
      expect(futures[2], isA<List>());

      // Cache should now be warm
      expect(SupabaseService.hasCachedTestSeries, isTrue);

      // Repeat call should hit warm cache instantly
      final warmStart = DateTime.now();
      final cachedResult = await SupabaseService.fetchAllTestSeries();
      final warmDuration = DateTime.now().difference(warmStart);

      expect(cachedResult, isA<List>());
      expect(warmDuration.inMilliseconds, lessThan(50));
    });

    test('2. Student enrollment status map user-scoped caching and invalidation', () async {
      const testUserId = '00000000-0000-0000-0000-000000000001';
      const testUserEmail = 'perf_student@cosmyra.test';

      SupabaseService.invalidateEnrollmentCache();

      // First fetch
      final firstFetch = await SupabaseService.fetchStudentEnrollmentStatusMap(
        userId: testUserId,
        userEmail: testUserEmail,
      );
      expect(firstFetch, isA<Map<String, Map<String, dynamic>>>());

      // Concurrent calls should deduplicate and return cached value
      final concurrentResults = await Future.wait([
        SupabaseService.fetchStudentEnrollmentStatusMap(
          userId: testUserId,
          userEmail: testUserEmail,
        ),
        SupabaseService.fetchStudentEnrollmentStatusMap(
          userId: testUserId,
          userEmail: testUserEmail,
        ),
      ]);

      expect(concurrentResults[0], isA<Map<String, Map<String, dynamic>>>());
      expect(concurrentResults[1], isA<Map<String, Map<String, dynamic>>>());

      // Invalidation clears the user-scoped cache
      SupabaseService.invalidateEnrollmentCache('${testUserId}_$testUserEmail');

      final freshFetch = await SupabaseService.fetchStudentEnrollmentStatusMap(
        userId: testUserId,
        userEmail: testUserEmail,
        forceRefresh: true,
      );
      expect(freshFetch, isA<Map<String, Map<String, dynamic>>>());
    });

    test('3. Paper questions in-flight deduplication and cache', () async {
      const testPaperId = 'paper_cache_test_001';

      SupabaseService.invalidateCaches();

      // Concurrent fetches for the same paper should not collide
      final results = await Future.wait([
        SupabaseService.fetchQuestionsForPaper(testPaperId),
        SupabaseService.fetchQuestionsForPaper(testPaperId),
      ]);

      expect(results[0], isA<List>());
      expect(results[1], isA<List>());
    });

    test('4. Global invalidateCaches clears all warm caches', () async {
      SupabaseService.invalidateCaches();
      expect(SupabaseService.hasCachedTestSeries, isFalse);
      expect(SupabaseService.cachedTestSeries, isEmpty);
      expect(SupabaseService.cachedDbPapers, isEmpty);
    });
  });
}
