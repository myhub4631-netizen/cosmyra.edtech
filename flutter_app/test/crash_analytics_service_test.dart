import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_edu_flutter/core/services/crash_analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashAnalyticsService Unit Tests', () {
    test('initializes gracefully in fallback mode when Firebase config is absent', () async {
      await CrashAnalyticsService.initialize();
      // Should not throw any exception and should fall back safely to console logging
      expect(CrashAnalyticsService.isAvailable, isFalse);
    });

    test('recordError executes safely without throwing', () async {
      await CrashAnalyticsService.recordError(
        Exception('Test non-fatal exception'),
        StackTrace.current,
        reason: 'Unit Test Exception Test',
      );
    });

    test('setUserIdentifier executes safely without throwing', () async {
      await CrashAnalyticsService.setUserIdentifier('test_user_12345');
    });

    test('setCustomKey executes safely without throwing', () async {
      await CrashAnalyticsService.setCustomKey('test_environment', 'unit_test');
    });

    test('log executes safely without throwing', () async {
      await CrashAnalyticsService.log('Unit test breadcrumb log entry');
    });
  });
}
