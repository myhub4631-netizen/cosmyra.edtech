import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized Crash Analytics service wrapping Firebase Crashlytics.
///
/// Handles initialization, global Flutter error hooks, custom logging,
/// non-fatal exception reporting, and user tracking.
class CrashAnalyticsService {
  static bool _initialized = false;
  static bool _firebaseAvailable = false;

  /// Returns whether Firebase Crashlytics is successfully initialized and active.
  static bool get isAvailable => _firebaseAvailable;

  /// Initializes Firebase Core and Crashlytics, and sets up global Flutter error handlers.
  static Future<void> initialize({
    FirebaseOptions? options,
    bool enableInDebug = false,
  }) async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Initialize Firebase App if options are available or platform defaults exist
      if (Firebase.apps.isEmpty) {
        if (options != null) {
          await Firebase.initializeApp(options: options);
        } else {
          await Firebase.initializeApp();
        }
      }

      // 2. Configure Crashlytics collection
      final crashlytics = FirebaseCrashlytics.instance;

      // Opt-out in debug mode unless explicitly enabled
      if (kDebugMode && !enableInDebug) {
        await crashlytics.setCrashlyticsCollectionEnabled(false);
      } else {
        await crashlytics.setCrashlyticsCollectionEnabled(true);
      }

      _firebaseAvailable = true;
      debugPrint('[CrashAnalytics] Firebase Crashlytics initialized successfully.');
    } catch (e) {
      _firebaseAvailable = false;
      debugPrint('[CrashAnalytics] Firebase initialization skipped or notice: $e');
      debugPrint('[CrashAnalytics] App will continue with local console log fallback.');
    }

    // 3. Register Global Error Handlers (always active)
    _setupGlobalErrorHandlers();
  }

  /// Sets up global Flutter framework & Dart isolate error listeners.
  static void _setupGlobalErrorHandlers() {
    // Flutter Framework UI Errors (e.g. rendering/layout exceptions)
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_firebaseAvailable) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      } else {
        FlutterError.dumpErrorToConsole(details);
      }
      originalOnError?.call(details);
    };

    // Uncaught Asynchronous Dart Errors (e.g. Futures, Isolates)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (_firebaseAvailable) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        debugPrint('[CrashAnalytics] Uncaught Platform Async Error: $error\n$stack');
      }
      return true; // Handled
    };
  }

  /// Records a non-fatal exception or caught error.
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    if (_firebaseAvailable) {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
        information: information,
      );
    } else {
      debugPrint('[CrashAnalytics] RecordError (${fatal ? "Fatal" : "Non-Fatal"}): $reason -> $exception');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  /// Attach a user identifier (e.g. Supabase User ID or Email) to subsequent crash reports.
  static Future<void> setUserIdentifier(String identifier) async {
    if (_firebaseAvailable) {
      await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    } else {
      debugPrint('[CrashAnalytics] SetUserIdentifier: $identifier');
    }
  }

  /// Sets a custom key-value pair to attach context to crash reports.
  static Future<void> setCustomKey(String key, Object value) async {
    if (_firebaseAvailable) {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } else {
      debugPrint('[CrashAnalytics] SetCustomKey: $key = $value');
    }
  }

  /// Logs a custom message (breadcrumb) sent with the next crash report.
  static Future<void> log(String message) async {
    if (_firebaseAvailable) {
      await FirebaseCrashlytics.instance.log(message);
    } else {
      debugPrint('[CrashAnalytics] Log: $message');
    }
  }

  /// Forces a test crash (Use only during manual verification / debugging).
  static void testCrash() {
    if (_firebaseAvailable) {
      debugPrint('[CrashAnalytics] Triggering test crash via FirebaseCrashlytics.instance.crash()...');
      FirebaseCrashlytics.instance.crash();
    } else {
      throw StateError('[CrashAnalytics] Test Crash triggered (Local Fallback Mode)');
    }
  }
}
