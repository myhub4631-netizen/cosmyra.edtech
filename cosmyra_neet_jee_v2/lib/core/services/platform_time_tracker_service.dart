import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Service to track authentic, active foreground engagement time across the platform.
/// Features:
/// 1. Lifecycle-aware: Only tracks when app is in the foreground (resumed).
/// 2. Tab deduplication: Prevents double-counting when multiple tabs are open simultaneously.
/// 3. Tamper-proof: Clamps increments to interval bounds.
/// 4. Admin preview exclusion: Ignores admin test sessions.
class PlatformTimeTrackerService with WidgetsBindingObserver {
  PlatformTimeTrackerService._();
  static final PlatformTimeTrackerService instance = PlatformTimeTrackerService._();

  static const String _prefActiveTimeKey = 'cosmyra_platform_active_time_seconds';
  static const String _prefLastHeartbeatKey = 'cosmyra_platform_last_heartbeat_ms';
  static const int _heartbeatIntervalSeconds = 15;

  Timer? _heartbeatTimer;
  bool _isForeground = true;
  bool _isInitialized = false;

  /// Initialize the time tracker
  static Future<void> initialize() async {
    if (instance._isInitialized) return;
    instance._isInitialized = true;
    WidgetsBinding.instance.addObserver(instance);
    instance._startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatIntervalSeconds),
      (_) => _recordHeartbeatTick(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = (state == AppLifecycleState.resumed);
  }

  Future<void> _recordHeartbeatTick() async {
    // 1. Skip if app is not in foreground or user is in admin preview mode
    if (!_isForeground || SupabaseService.isAdminPreview) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final lastHeartbeatMs = prefs.getInt(_prefLastHeartbeatKey) ?? 0;

      // 2. Multi-tab deduplication:
      // If another tab has recorded a heartbeat less than 12 seconds ago, skip this tick
      final elapsedSinceLastHeartbeatMs = nowMs - lastHeartbeatMs;
      if (lastHeartbeatMs > 0 && elapsedSinceLastHeartbeatMs < 12000) {
        return;
      }

      // 3. Increment active time safely (clamped to interval seconds to prevent time jumps)
      final currentSeconds = prefs.getInt(_prefActiveTimeKey) ?? 0;
      final newSeconds = currentSeconds + _heartbeatIntervalSeconds;
      await prefs.setInt(_prefActiveTimeKey, newSeconds);
      await prefs.setInt(_prefLastHeartbeatKey, nowMs);
    } catch (e) {
      debugPrint('Notice recording platform heartbeat: $e');
    }
  }

  /// Manually add active seconds (for testing or specific interactive events)
  static Future<void> recordActiveTickManually(int seconds) async {
    if (seconds <= 0 || SupabaseService.isAdminPreview) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSeconds = prefs.getInt(_prefActiveTimeKey) ?? 0;
      await prefs.setInt(_prefActiveTimeKey, currentSeconds + seconds);
    } catch (_) {}
  }

  /// Returns total platform active time in seconds, aggregating active tracking
  /// and genuine test attempt time.
  static Future<int> getAccumulatedPlatformSeconds({String? userId}) async {
    int totalSeconds = 0;
    final Set<String> processedAttemptIds = {};

    // 1. Foreground active usage time tracked by this service
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackedForeground = prefs.getInt(_prefActiveTimeKey) ?? 0;
      totalSeconds += trackedForeground;
    } catch (_) {}

    // 2. Query authenticated test attempts from Supabase
    final targetUid = userId ?? SupabaseService.client.auth.currentUser?.id;
    if (targetUid != null && targetUid.isNotEmpty && !SupabaseService.isAdminPreview) {
      try {
        final attempts = await SupabaseService.client
            .from('test_attempts')
            .select('id, time_spent_seconds, status')
            .eq('student_id', targetUid)
            .eq('status', 'submitted');

        for (var a in (attempts as List)) {
          final id = (a['id'] ?? '').toString();
          if (id.isNotEmpty && !processedAttemptIds.contains(id)) {
            processedAttemptIds.add(id);
            final time = (a['time_spent_seconds'] as num?)?.toInt() ?? 0;
            if (time > 0) totalSeconds += time;
          }
        }
      } catch (e) {
        debugPrint('Notice aggregating platform test_attempts time: $e');
      }
    }

    // 3. Query local PYQ practice sessions
    if (!SupabaseService.isAdminPreview) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final historyStr = prefs.getString('cosmyra_pyq_practice_history');
        if (historyStr != null && historyStr.isNotEmpty) {
          final List<dynamic> list = jsonDecode(historyStr);
          for (var item in list) {
            if (item is Map) {
              final id = (item['id'] ?? '').toString();
              if (id.isNotEmpty && !processedAttemptIds.contains(id)) {
                processedAttemptIds.add(id);
                final time = (item['timeSpentSeconds'] as num?)?.toInt() ?? 0;
                if (time > 0) totalSeconds += time;
              }
            }
          }
        }
      } catch (_) {}
    }

    return totalSeconds;
  }

  /// Formats duration into user-friendly string (e.g. "12h 35m", "45m", "Not yet available")
  static String formatDuration(int? totalSeconds) {
    if (totalSeconds == null || totalSeconds <= 0) {
      return 'Not yet available';
    }
    if (totalSeconds < 60) {
      return '< 1m';
    }
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Reset tracking keys for test suites
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefActiveTimeKey);
    await prefs.remove(_prefLastHeartbeatKey);
  }
}
