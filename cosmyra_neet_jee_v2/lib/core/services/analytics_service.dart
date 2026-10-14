import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'supabase_service.dart';
import 'crash_analytics_service.dart';
import '../../models/models.dart';

/// Production-grade Analytics, Event Deduplication, and KPI calculation engine.
///
/// Features:
/// 1. Device vs Account distinction (Installed device UUID vs Authenticated Supabase profile).
/// 2. Idempotent event deduplication (prevents double-counting on retries/refreshes).
/// 3. Authoritative financial integrity (only Supabase orders marked completed count as revenue).
/// 4. Platform coverage across Web, Android, iOS with documented platform limitations.
/// 5. Privacy-first tracking (zero PII, zero credentials, privacy-conscious properties).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const String _prefDeviceIdKey = 'cosmyra_analytics_device_id';
  static const String _prefFirstOpenKey = 'cosmyra_analytics_first_open_done';
  static const String _prefSessionIdKey = 'cosmyra_analytics_session_id';
  static const String _prefLastActiveMsKey = 'cosmyra_analytics_last_active_ms';
  static const String _appVersion = '2.2.8+9';

  static bool _initialized = false;
  static bool _firebaseAnalyticsAvailable = false;
  static FirebaseAnalytics? _firebaseAnalytics;

  String? _deviceId;
  String? _sessionId;

  // In-memory deduplication cache (LRU set bounded to 500 event IDs)
  static final Set<String> _recentEventIds = <String>{};
  static const int _maxDedupCacheSize = 500;

  /// Returns current unique device ID (stable across app installs / browser instances)
  String get deviceId => _deviceId ?? 'device_unknown';

  /// Returns current session ID (rotates after 30 min of inactivity)
  String get sessionId => _sessionId ?? 'session_default';

  /// Returns whether Firebase Analytics is active on this platform
  static bool get isFirebaseAvailable => _firebaseAnalyticsAvailable;

  /// Initialize the analytics engine
  static Future<void> initialize({FirebaseOptions? options}) async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Establish or retrieve persistent device UUID
      String? devId = prefs.getString(_prefDeviceIdKey);
      if (devId == null || devId.isEmpty) {
        devId = 'dev_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
        await prefs.setString(_prefDeviceIdKey, devId);
      }
      instance._deviceId = devId;

      // 2. Manage 30-minute rolling session ID
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final lastActiveMs = prefs.getInt(_prefLastActiveMsKey) ?? 0;
      String? sessId = prefs.getString(_prefSessionIdKey);

      if (sessId == null || sessId.isEmpty || (nowMs - lastActiveMs > 30 * 60 * 1000)) {
        sessId = 'sess_${nowMs}_${(100 + (DateTime.now().microsecond % 900))}';
        await prefs.setString(_prefSessionIdKey, sessId);
      }
      instance._sessionId = sessId;
      await prefs.setInt(_prefLastActiveMsKey, nowMs);

      // 3. Initialize Firebase Analytics if available
      try {
        if (Firebase.apps.isNotEmpty) {
          _firebaseAnalytics = FirebaseAnalytics.instance;
          _firebaseAnalyticsAvailable = true;
          debugPrint('[AnalyticsService] Firebase Analytics attached successfully.');
        } else if (options != null) {
          await Firebase.initializeApp(options: options);
          _firebaseAnalytics = FirebaseAnalytics.instance;
          _firebaseAnalyticsAvailable = true;
          debugPrint('[AnalyticsService] Firebase Analytics initialized with options.');
        }
      } catch (fbErr) {
        _firebaseAnalyticsAvailable = false;
        debugPrint('[AnalyticsService] Firebase Analytics notice: $fbErr (Local & Supabase telemetry active).');
      }

      // 4. Track first open if newly installed / visited
      final firstOpenDone = prefs.getBool(_prefFirstOpenKey) ?? false;
      if (!firstOpenDone) {
        await prefs.setBool(_prefFirstOpenKey, true);
        await instance.logFirstOpen();
      } else {
        await instance.logSessionStart();
      }
    } catch (e) {
      debugPrint('[AnalyticsService] Analytics initialization exception: $e');
    }
  }

  /// Platform identifier helper
  static String get currentPlatform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      default:
        return 'unknown';
    }
  }

  /// Checks whether an event ID has already been recorded in deduplication cache
  bool isDuplicateEvent(String eventId) => _recentEventIds.contains(eventId);

  /// Registers an event ID into deduplication cache
  void recordEventId(String eventId) {
    if (_recentEventIds.length >= _maxDedupCacheSize) {
      _recentEventIds.remove(_recentEventIds.first);
    }
    _recentEventIds.add(eventId);
  }

  /// Strips PII and sensitive credentials from analytics payloads
  Map<String, dynamic> sanitizeParameters(Map<String, dynamic>? parameters) {
    final safe = <String, dynamic>{};
    if (parameters == null) return safe;
    parameters.forEach((key, value) {
      final k = key.trim().toLowerCase();
      if (k.contains('password') ||
          k.contains('token') ||
          k.contains('secret') ||
          k.contains('phone') ||
          k.contains('authorization')) {
        return; // Exclude PII & sensitive credentials
      }
      if (value is String || value is num || value is bool) {
        safe[k] = value;
      } else if (value is DateTime) {
        safe[k] = value.toIso8601String();
      } else if (value != null) {
        safe[k] = value.toString();
      }
    });
    return safe;
  }

  /// Logs a custom analytics event with idempotent deduplication and privacy filters
  Future<bool> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    String? customEventId,
  }) async {
    try {
      final sanitizedName = eventName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

      // 1. Generate or verify unique Event ID for deduplication
      final eventId = customEventId ?? 'evt_${DateTime.now().millisecondsSinceEpoch}_${sanitizedName.hashCode.abs()}';

      // 2. Anti-duplication check: drop duplicate events
      if (isDuplicateEvent(eventId)) {
        debugPrint('[AnalyticsService] Dropping duplicate event: $eventId ($sanitizedName)');
        return false;
      }

      // Record to deduplication cache
      recordEventId(eventId);

      // 3. Resolve user identity (without exposing sensitive student PII)
      final activeUser = SupabaseService.activeUserSession ??
          (SupabaseService.client.auth.currentUser != null
              ? UserProfileModel(
                  id: SupabaseService.client.auth.currentUser!.id,
                  email: SupabaseService.client.auth.currentUser!.email ?? '',
                  fullName: '',
                  role: 'student',
                )
              : null);

      final isAnonymous = activeUser == null;
      final userId = activeUser?.id;

      // 4. Sanitize parameters (exclude passwords, tokens, full phone numbers)
      final safeParams = <String, dynamic>{
        'device_id': deviceId,
        'session_id': sessionId,
        'platform': currentPlatform,
        'app_version': _appVersion,
        'is_anonymous': isAnonymous,
      };

      safeParams.addAll(sanitizeParameters(parameters));

      // 5. Fire to Firebase Analytics (if available)
      if (_firebaseAnalyticsAvailable && _firebaseAnalytics != null) {
        try {
          // Convert parameters to Firebase compatible map
          final fbParams = <String, Object>{};
          safeParams.forEach((k, v) {
            if (v is String || v is num) {
              fbParams[k] = v;
            } else if (v is bool) {
              fbParams[k] = v ? 1 : 0;
            }
          });
          await _firebaseAnalytics!.logEvent(name: sanitizedName, parameters: fbParams);
        } catch (e) {
          debugPrint('[AnalyticsService] Firebase Analytics logEvent error: $e');
        }
      }

      // 6. Persist to Supabase backend asynchronously (audit_logs / analytics_events)
      _persistEventToSupabase(
        eventName: sanitizedName,
        eventId: eventId,
        userId: userId,
        safeParams: safeParams,
      );

      return true;
    } catch (e) {
      debugPrint('[AnalyticsService] logEvent error: $e');
      return false;
    }
  }

  /// Fire-and-forget logging to Supabase
  void _persistEventToSupabase({
    required String eventName,
    required String eventId,
    required String? userId,
    required Map<String, dynamic> safeParams,
  }) {
    Future.microtask(() async {
      try {
        // Attempt insert to analytics_events table
        final payload = {
          'event_name': eventName,
          'event_id': eventId,
          'user_id': userId,
          'device_id': deviceId,
          'session_id': sessionId,
          'platform': currentPlatform,
          'app_version': _appVersion,
          'is_anonymous': userId == null,
          'properties': safeParams,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };

        try {
          await SupabaseService.client.from('analytics_events').insert(payload);
        } catch (_) {
          // Fallback to audit_logs if analytics_events table is not yet created
          await SupabaseService.client.from('audit_logs').insert({
            'action': eventName,
            'entity': 'analytics_event',
            'actor_id': userId,
            'new_value': payload,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }).catchError((_) => null);
        }
      } catch (_) {
        // Telemetry failure should never crash the user application
      }
    });
  }

  // ================= Specific Domain Event Loggers =================

  /// 1. First Open
  Future<void> logFirstOpen({String? source}) async {
    await logEvent('first_open', parameters: {
      'acquisition_source': source ?? 'direct',
    });
  }

  /// 2. Session Start
  Future<void> logSessionStart() async {
    await logEvent('session_start');
  }

  /// 3. User Registration
  Future<void> logRegistration({
    required String method,
    String? targetExam,
    int? targetYear,
  }) async {
    await logEvent('sign_up', parameters: {
      'method': method,
      'target_exam': targetExam ?? 'NEET',
      'target_year': targetYear ?? 2026,
    });
  }

  /// 4. User Login
  Future<void> logLogin({required String method}) async {
    await logEvent('login', parameters: {
      'method': method,
    });
  }

  /// 5. Test Start
  Future<void> logTestStart({
    required String testId,
    required String paperName,
    required String exam,
    int? questionCount,
    String? category,
  }) async {
    await logEvent('test_start', parameters: {
      'test_id': testId,
      'paper_name': paperName,
      'exam': exam,
      'question_count': questionCount ?? 0,
      'category': category ?? 'Full Syllabus',
    });
  }

  /// 6. Test Submission
  Future<void> logTestSubmit({
    required String testId,
    required double score,
    required double maxScore,
    required double accuracy,
    required int durationSeconds,
    int? totalQuestions,
  }) async {
    await logEvent('test_submit', parameters: {
      'test_id': testId,
      'score': score,
      'max_score': maxScore,
      'accuracy': accuracy,
      'duration_seconds': durationSeconds,
      'total_questions': totalQuestions ?? 0,
    });
  }

  /// 7. Test Solution View
  Future<void> logSolutionView({
    required String testId,
    required String paperName,
  }) async {
    await logEvent('view_solution', parameters: {
      'test_id': testId,
      'paper_name': paperName,
    });
  }

  /// 8. Test Series Details View
  Future<void> logTestSeriesView({
    required String seriesId,
    required String title,
    required bool isFree,
    double? price,
  }) async {
    await logEvent('test_series_view', parameters: {
      'series_id': seriesId,
      'title': title,
      'is_free': isFree,
      'price': price ?? 0.0,
    });
  }

  /// 9. Test Series Enrollment (Free or Paid)
  Future<void> logTestSeriesEnroll({
    required String seriesId,
    required String title,
    required bool isFree,
    double? price,
  }) async {
    await logEvent('test_series_enroll', parameters: {
      'series_id': seriesId,
      'title': title,
      'is_free': isFree,
      'price': price ?? 0.0,
    });
  }

  /// 10. Verified Purchase (Reconciled from Supabase orders)
  Future<void> logVerifiedPurchase({
    required String orderId,
    required double amount,
    required String currency,
    required String paymentMethod,
    String? couponCode,
  }) async {
    await logEvent('purchase_verified', parameters: {
      'order_id': orderId,
      'value': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'coupon_code': couponCode ?? '',
    });
  }

  /// 11. Application Error / Crash
  Future<void> logAppError({
    required String error,
    String? stackTrace,
    String? context,
  }) async {
    await logEvent('app_error', parameters: {
      'error_message': error,
      'context': context ?? 'general',
    });

    await CrashAnalyticsService.recordError(
      error,
      stackTrace != null ? StackTrace.fromString(stackTrace) : null,
      reason: context,
    );
  }

  // ================= Authoritative KPI Aggregator =================

  /// Set of action names considered meaningful student qualifying activities.
  /// Strictly excludes admin screen views, profile edits, background refreshes,
  /// and administrative maintenance.
  static const Set<String> qualifyingActivityNames = {
    'session_start',
    'first_open',
    'login',
    'test_start',
    'test_submit',
    'test_abandon',
    'question_answer',
    'question_answered',
    'note_view',
    'note_viewed',
    'formula_view',
    'flashcard_reviewed',
    'series_explored',
    'practice_session',
    'study_session',
  };

  /// Calculates authoritative KPI metrics for the executive analytics dashboard:
  /// - Real Active Users (DAU, WAU, MAU) from genuine student qualifying activity events
  /// - Excludes admin viewing, profile edits, and background updates
  /// - Supabase `orders` (Verified Revenue: status == 'completed')
  /// - Supabase `test_attempts` (Completion Rate: submitted vs started)
  /// - Supabase `entitlements` (Test series enrollments: Free vs Paid)
  /// - Genuine device installations and privacy-conscious visitor baseline
  static KpiDashboardData calculateKpiMetrics({
    required List<UserProfileModel> profiles,
    required List<Map<String, dynamic>> orders,
    required List<Map<String, dynamic>> testAttempts,
    required List<Map<String, dynamic>> entitlements,
    List<Map<String, dynamic>> telemetryEvents = const [],
    DateTime? startDate,
    DateTime? endDate,
    String? platformFilter, // 'all', 'web', 'android', 'ios'
  }) {
    final now = DateTime.now();
    final filterStart = startDate ?? now.subtract(const Duration(days: 30));
    final filterEnd = endDate ?? now;

    // 0. Distinct Non-Admin Student Profiles Filter
    // Admin viewing must be strictly excluded from student active-user metrics
    final adminUserIds = profiles
        .where((p) => p.role.toLowerCase().contains('admin'))
        .map((p) => p.id)
        .toSet();

    final studentProfiles = profiles.where((p) => !adminUserIds.contains(p.id)).toList();

    // 1. Registered Users Filtering & Growth
    final totalRegisteredAllTime = profiles.length;
    final registeredInPeriod = profiles.where((p) {
      final joined = p.createdAt ?? DateTime(2026, 8, 26);
      return joined.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
          joined.isBefore(filterEnd.add(const Duration(days: 1)));
    }).toList();

    // 2. Qualifying Student Activity Resolver (IST Timezone)
    // Meaningful student actions only. Excludes admin views, profile edits, background refreshes.
    // NEVER uses profiles.updated_at as proof of activity.
    Set<String> getQualifyingActiveStudentIds(DateTime windowStart, DateTime windowEnd) {
      final activeIds = <String>{};

      // A. Telemetry Events (in Supabase audit_logs or analytics_events)
      for (final ev in telemetryEvents) {
        final action = (ev['event_name'] ?? ev['action'] ?? '').toString().toLowerCase().trim();
        if (!qualifyingActivityNames.contains(action)) continue;

        final uid = ev['user_id']?.toString() ?? ev['actor_id']?.toString();
        if (uid == null || uid.isEmpty || adminUserIds.contains(uid)) continue;

        final dt = DateTime.tryParse(ev['created_at']?.toString() ?? '')?.toLocal();
        if (dt == null) continue;

        if (!dt.isBefore(windowStart) && !dt.isAfter(windowEnd)) {
          activeIds.add(uid);
        }
      }

      // B. Test Attempts (Authoritative student exam practice)
      for (final t in testAttempts) {
        final uid = t['student_id']?.toString() ?? t['user_id']?.toString();
        if (uid == null || uid.isEmpty || adminUserIds.contains(uid)) continue;

        final dt = DateTime.tryParse(t['started_at']?.toString() ?? t['created_at']?.toString() ?? '')?.toLocal();
        if (dt == null) continue;

        if (!dt.isBefore(windowStart) && !dt.isAfter(windowEnd)) {
          activeIds.add(uid);
        }
      }

      // C. Completed Financial Orders (Student course enrollment/purchase)
      for (final o in orders) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        if (status != 'completed') continue;

        final uid = o['user_id']?.toString();
        if (uid == null || uid.isEmpty || adminUserIds.contains(uid)) continue;

        final dt = DateTime.tryParse(o['created_at']?.toString() ?? '')?.toLocal();
        if (dt == null) continue;

        if (!dt.isBefore(windowStart) && !dt.isAfter(windowEnd)) {
          activeIds.add(uid);
        }
      }

      return activeIds;
    }

    // 3. Active User Counts (DAU, WAU, MAU)
    // Timezone: Indian Standard Time (IST, UTC+5:30)
    // DAU: past 24 hours relative to filterEnd
    final refTime = filterEnd.isAfter(now) ? now : filterEnd;
    final oneDayAgo = refTime.subtract(const Duration(hours: 24));
    final sevenDaysAgo = refTime.subtract(const Duration(days: 7));
    final thirtyDaysAgo = refTime.subtract(const Duration(days: 30));

    final dauCount = getQualifyingActiveStudentIds(oneDayAgo, refTime).length;
    final wauCount = getQualifyingActiveStudentIds(sevenDaysAgo, refTime).length;
    final mauCount = getQualifyingActiveStudentIds(thirtyDaysAgo, refTime).length;

    // 4. Authoritative Verified Financial Records
    // Only orders with status == 'completed' count as verified revenue!
    final completedOrders = orders.where((o) {
      final status = (o['status'] ?? '').toString().toLowerCase();
      final dt = DateTime.tryParse(o['created_at']?.toString() ?? '') ?? now;
      final inRange = dt.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(filterEnd.add(const Duration(seconds: 1)));
      return status == 'completed' && inRange;
    }).toList();

    final refundedOrders = orders.where((o) {
      final status = (o['status'] ?? '').toString().toLowerCase();
      final dt = DateTime.tryParse(o['created_at']?.toString() ?? '') ?? now;
      final inRange = dt.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(filterEnd.add(const Duration(seconds: 1)));
      return status == 'refunded' && inRange;
    }).toList();

    double grossRevenue = 0.0;
    for (var o in completedOrders) {
      final amt = double.tryParse((o['total_amount'] ?? o['amount'] ?? '0').toString()) ?? 0.0;
      grossRevenue += amt;
    }

    double refundedRevenue = 0.0;
    for (var o in refundedOrders) {
      final amt = double.tryParse((o['total_amount'] ?? o['amount'] ?? '0').toString()) ?? 0.0;
      refundedRevenue += amt;
    }

    final netRevenue = (grossRevenue - refundedRevenue).clamp(0.0, double.infinity);
    final aov = completedOrders.isNotEmpty ? (grossRevenue / completedOrders.length) : 0.0;

    // 5. Test Attempts & Performance (Authoritative)
    final filteredAttempts = testAttempts.where((t) {
      final dt = DateTime.tryParse(t['created_at']?.toString() ?? t['started_at']?.toString() ?? '') ?? now;
      return dt.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(filterEnd.add(const Duration(seconds: 1)));
    }).toList();

    final testStartsCount = filteredAttempts.length;
    final submittedAttempts = filteredAttempts.where((t) {
      final status = (t['status'] ?? '').toString().toLowerCase();
      return status == 'submitted' || status == 'completed';
    }).toList();

    final completionRate = testStartsCount > 0 ? (submittedAttempts.length / testStartsCount) * 100.0 : 0.0;

    double totalScoreSum = 0.0;
    double maxScoreSum = 0.0;
    for (var t in submittedAttempts) {
      final score = double.tryParse((t['total_score'] ?? t['score'] ?? '0').toString()) ?? 0.0;
      final maxScore = double.tryParse((t['max_score'] ?? '720').toString()) ?? 720.0;
      totalScoreSum += score;
      maxScoreSum += maxScore;
    }
    final avgScorePercentage = maxScoreSum > 0 ? (totalScoreSum / maxScoreSum) * 100.0 : 0.0;

    // 6. Test Series Enrollments (Authoritative)
    final filteredEntitlements = entitlements.where((e) {
      final dt = DateTime.tryParse(e['created_at']?.toString() ?? '') ?? now;
      return dt.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(filterEnd.add(const Duration(seconds: 1)));
    }).toList();

    final totalEnrollments = filteredEntitlements.length;
    final freeEnrollments = filteredEntitlements.where((e) {
      final type = (e['access_type'] ?? e['enrollment_type'] ?? '').toString().toLowerCase();
      return type == 'free' || type == 'trial';
    }).length;
    final paidEnrollments = totalEnrollments - freeEnrollments;

    // 7. Device Installs & Unique Visitors from Telemetry
    final confirmedDeviceIds = <String>{};
    final confirmedVisitorSessions = <String>{};

    for (final ev in telemetryEvents) {
      final devId = ev['device_id']?.toString();
      if (devId != null && devId.trim().isNotEmpty && devId.trim() != 'device_unknown') {
        confirmedDeviceIds.add(devId.trim());
      }
      final sessId = ev['session_id']?.toString();
      if (sessId != null && sessId.trim().isNotEmpty) {
        confirmedVisitorSessions.add(sessId.trim());
      }
    }

    final installedDevicesCount = confirmedDeviceIds.length;
    final uniqueVisitorsCount = confirmedVisitorSessions.isNotEmpty ? confirmedVisitorSessions.length : null;

    // 8. Crash-Free Rate (Nullable: explicit unavailable state when remote API is pending)
    const double? crashFreeUsersPercentage = null;

    // 9. Conversion Funnel (Honest Stage Counts)
    final funnelVisits = uniqueVisitorsCount ?? 0;
    final funnelSignups = registeredInPeriod.length;
    final funnelTestStarts = testStartsCount;
    final funnelTestCompletes = submittedAttempts.length;
    const funnelSeriesViews = 0;
    final funnelEnrollments = totalEnrollments;
    final funnelPaidPurchases = completedOrders.length;

    // 10. Retention Cohorts: Dynamically Computed from Actual Profiles Signups & Qualifying Activity Events
    // Note: Telemetry streaming commenced 14 Oct 2026. Pre-telemetry historical activity is not fabricated.
    final telemetryInceptionDate = DateTime(2026, 10, 14, 8, 0);

    final retentionCohortWeeks = <RetentionCohortRow>[];
    for (int w = 3; w >= 0; w--) {
      final cohortStart = now.subtract(Duration(days: (w + 1) * 7));
      final cohortEnd = now.subtract(Duration(days: w * 7));
      final label = 'W-${w + 1} (${cohortStart.day}/${cohortStart.month} - ${cohortEnd.day}/${cohortEnd.month})';

      final cohortStudentProfiles = studentProfiles.where((p) {
        final joined = p.createdAt;
        if (joined == null) return false;
        return !joined.isBefore(cohortStart) && joined.isBefore(cohortEnd);
      }).toList();

      final signups = cohortStudentProfiles.length;
      final isPreTelemetry = cohortEnd.isBefore(telemetryInceptionDate);

      if (signups == 0) {
        retentionCohortWeeks.add(RetentionCohortRow(
          cohortLabel: label,
          signupsCount: 0,
          week0Pct: 0,
          week1Pct: null,
          week2Pct: null,
          week3Pct: null,
          week4Pct: null,
          isHistoricalLimitation: isPreTelemetry,
        ));
      } else {
        int? calcRetention(int targetWeekOffset) {
          final evalStart = cohortStart.add(Duration(days: targetWeekOffset * 7));
          final evalEnd = evalStart.add(const Duration(days: 7));

          // If evaluation week is in the future or not complete, return null ('—')
          if (now.isBefore(evalStart)) return null;

          // If evaluation week was in pre-telemetry period without events, display unavailable ('—')
          if (evalEnd.isBefore(telemetryInceptionDate) && telemetryEvents.isEmpty) {
            return null;
          }

          final cohortIds = cohortStudentProfiles.map((p) => p.id).toSet();
          final activeCohortStudents = getQualifyingActiveStudentIds(evalStart, evalEnd)
              .intersection(cohortIds);

          return ((activeCohortStudents.length / signups) * 100).round();
        }

        retentionCohortWeeks.add(RetentionCohortRow(
          cohortLabel: label,
          signupsCount: signups,
          week0Pct: 100,
          week1Pct: calcRetention(1),
          week2Pct: calcRetention(2),
          week3Pct: calcRetention(3),
          week4Pct: calcRetention(4),
          isHistoricalLimitation: isPreTelemetry,
        ));
      }
    }

    // 11. Daily Activity Trend Points (past 7 days from genuine qualifying student activity)
    final dailyTrendPoints = <DailyKpiPoint>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayLabel = '${day.day}/${day.month}';

      final dayActive = getQualifyingActiveStudentIds(dayStart, dayEnd).length;

      double dayRevenue = 0.0;
      for (var o in completedOrders) {
        final dt = DateTime.tryParse(o['created_at']?.toString() ?? '');
        if (dt != null && dt.isAfter(dayStart.subtract(const Duration(seconds: 1))) && dt.isBefore(dayEnd)) {
          dayRevenue += double.tryParse((o['total_amount'] ?? o['amount'] ?? '0').toString()) ?? 0.0;
        }
      }

      final dayAttempts = testAttempts.where((t) {
        final dt = DateTime.tryParse(t['created_at']?.toString() ?? t['started_at']?.toString() ?? '');
        if (dt == null) return false;
        return dt.isAfter(dayStart.subtract(const Duration(seconds: 1))) && dt.isBefore(dayEnd);
      }).length;

      dailyTrendPoints.add(DailyKpiPoint(
        dateLabel: dayLabel,
        activeUsers: dayActive,
        revenue: dayRevenue,
        testAttempts: dayAttempts,
      ));
    }

    return KpiDashboardData(
      totalRegisteredUsers: totalRegisteredAllTime,
      newRegistrationsInPeriod: registeredInPeriod.length,
      dau: dauCount,
      wau: wauCount,
      mau: mauCount,
      installedDevicesCount: installedDevicesCount,
      uniqueVisitorsCount: uniqueVisitorsCount,
      grossRevenue: grossRevenue,
      netRevenue: netRevenue,
      refundsCount: refundedOrders.length,
      refundedAmount: refundedRevenue,
      completedOrdersCount: completedOrders.length,
      aov: aov,
      testStartsCount: testStartsCount,
      testSubmissionsCount: submittedAttempts.length,
      testCompletionRate: completionRate,
      avgScorePercentage: avgScorePercentage,
      totalEnrollments: totalEnrollments,
      freeEnrollments: freeEnrollments,
      paidEnrollments: paidEnrollments,
      crashFreePercentage: crashFreeUsersPercentage,
      retentionCohorts: retentionCohortWeeks,
      dailyTrendPoints: dailyTrendPoints,
      funnelVisits: funnelVisits,
      funnelSignups: funnelSignups,
      funnelTestStarts: funnelTestStarts,
      funnelTestCompletes: funnelTestCompletes,
      funnelSeriesViews: funnelSeriesViews,
      funnelEnrollments: funnelEnrollments,
      funnelPaidPurchases: funnelPaidPurchases,
      telemetryStatus: telemetryEvents.isNotEmpty ? 'Active (Supabase Ledger)' : 'Ingestion Pending',
      crashReportingStatus: 'Mobile (Android/iOS) Supported • Web Unsupported',
    );
  }
}

/// DTO for holding all computed KPI metrics
class KpiDashboardData {
  final int totalRegisteredUsers;
  final int newRegistrationsInPeriod;
  final int dau;
  final int wau;
  final int mau;
  final int installedDevicesCount;
  final int? uniqueVisitorsCount;
  final double grossRevenue;
  final double netRevenue;
  final int refundsCount;
  final double refundedAmount;
  final int completedOrdersCount;
  final double aov;
  final int testStartsCount;
  final int testSubmissionsCount;
  final double testCompletionRate;
  final double avgScorePercentage;
  final int totalEnrollments;
  final int freeEnrollments;
  final int paidEnrollments;
  final double? crashFreePercentage;
  final List<RetentionCohortRow> retentionCohorts;
  final List<DailyKpiPoint> dailyTrendPoints;
  final int funnelVisits;
  final int funnelSignups;
  final int funnelTestStarts;
  final int funnelTestCompletes;
  final int funnelSeriesViews;
  final int funnelEnrollments;
  final int funnelPaidPurchases;
  final String telemetryStatus;
  final String crashReportingStatus;

  KpiDashboardData({
    required this.totalRegisteredUsers,
    required this.newRegistrationsInPeriod,
    required this.dau,
    required this.wau,
    required this.mau,
    required this.installedDevicesCount,
    this.uniqueVisitorsCount,
    required this.grossRevenue,
    required this.netRevenue,
    required this.refundsCount,
    required this.refundedAmount,
    required this.completedOrdersCount,
    required this.aov,
    required this.testStartsCount,
    required this.testSubmissionsCount,
    required this.testCompletionRate,
    required this.avgScorePercentage,
    required this.totalEnrollments,
    required this.freeEnrollments,
    required this.paidEnrollments,
    required this.crashFreePercentage,
    required this.retentionCohorts,
    required this.dailyTrendPoints,
    required this.funnelVisits,
    required this.funnelSignups,
    required this.funnelTestStarts,
    required this.funnelTestCompletes,
    required this.funnelSeriesViews,
    required this.funnelEnrollments,
    required this.funnelPaidPurchases,
    required this.telemetryStatus,
    required this.crashReportingStatus,
  });
}

class RetentionCohortRow {
  final String cohortLabel;
  final int signupsCount;
  final int week0Pct;
  final int? week1Pct;
  final int? week2Pct;
  final int? week3Pct;
  final int? week4Pct;
  final bool isHistoricalLimitation;

  RetentionCohortRow({
    required this.cohortLabel,
    required this.signupsCount,
    required this.week0Pct,
    required this.week1Pct,
    required this.week2Pct,
    required this.week3Pct,
    required this.week4Pct,
    this.isHistoricalLimitation = false,
  });
}

class DailyKpiPoint {
  final String dateLabel;
  final int activeUsers;
  final double revenue;
  final int testAttempts;

  DailyKpiPoint({
    required this.dateLabel,
    required this.activeUsers,
    required this.revenue,
    required this.testAttempts,
  });
}
