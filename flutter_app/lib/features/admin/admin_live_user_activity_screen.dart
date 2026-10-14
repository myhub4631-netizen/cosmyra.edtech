import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import '../../shared/widgets/app_avatar.dart';
import 'admin_dashboard_screen.dart';
import 'admin_hierarchy_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_analytics_dashboard_screen.dart';

/// Complete, Production-grade Live User Activity Monitor Screen for COSMYRA NEET JEE.
/// Provides real-time telemetry streaming, active session tracking across Web, Android, iOS,
/// chronological user activity timelines, and presence calculation.
class AdminLiveUserActivityScreen extends StatefulWidget {
  final bool enableTimers;
  final List<Map<String, dynamic>>? initialEvents;

  const AdminLiveUserActivityScreen({
    super.key,
    this.enableTimers = true,
    this.initialEvents,
  });

  @override
  State<AdminLiveUserActivityScreen> createState() => _AdminLiveUserActivityScreenState();
}

class _AdminLiveUserActivityScreenState extends State<AdminLiveUserActivityScreen> {
  UserProfileModel _adminProfile = SupabaseService.getMockProfile(role: 'admin');

  // Stream & polling state
  RealtimeChannel? _realtimeChannel;
  Timer? _periodicSyncTimer;
  Timer? _tickerTimer;
  bool _isRealtimeSubscribed = false;
  bool _isLiveStreamingPaused = false;
  bool _isLoading = true;

  // Authoritative data collections
  final List<Map<String, dynamic>> _rawEvents = [];
  final Set<String> _knownEventIds = <String>{};
  final Map<String, Map<String, dynamic>> _userProfilesMap = {};

  // Filters
  String _selectedCategory = 'ALL';
  String _selectedPlatform = 'ALL';
  String _selectedRoleFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Selected user for timeline inspection modal
  Map<String, dynamic>? _selectedUserForTimeline;

  // Telemetry metrics
  DateTime? _latestEventTimestamp;
  int _eventsTodayCount = 0;
  int _sessionsTodayCount = 0;
  int _activeStudentsCount = 0;
  int _activeAdminsCount = 0;
  int _activeAnonymousCount = 0;
  int _activeWebSessions = 0;
  int _activeAndroidSessions = 0;
  int _activeIosSessions = 0;
  int _latencyMs = 120;

  @override
  void initState() {
    super.initState();
    if (widget.initialEvents != null) {
      _isLoading = false;
      for (var ev in widget.initialEvents!) {
        final id = ev['id']?.toString() ?? '';
        if (id.isNotEmpty && !_knownEventIds.contains(id)) {
          _knownEventIds.add(id);
          _rawEvents.add(ev);
        }
      }
      _recalculateMetrics();
    } else {
      _loadInitialTelemetry();
    }

    if (widget.enableTimers) {
      _setupRealtimeSubscription();

      // 1-second ticker to update relative elapsed times ("Xs ago") smoothly
      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _periodicSyncTimer?.cancel();
    _searchController.dispose();
    if (_realtimeChannel != null) {
      try {
        SupabaseService.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _loadInitialTelemetry() async {
    setState(() => _isLoading = true);
    final current = await SupabaseService.getCurrentUser();
    if (current != null && mounted) {
      setState(() => _adminProfile = current);
    }

    try {
      // 1. Fetch recent user profiles to resolve display names and roles
      try {
        final profilesRes = await SupabaseService.client
            .from('profiles')
            .select('id, email, full_name, role, avatar_url, created_at')
            .limit(200);
        for (var p in profilesRes) {
          final id = p['id']?.toString();
          if (id != null) {
            _userProfilesMap[id] = Map<String, dynamic>.from(p);
          }
        }
      } catch (e) {
        debugPrint('[AdminLiveActivity] Profiles fetch note: $e');
      }

      // 2. Fetch authoritative telemetry events from audit_logs
      final logsRes = await SupabaseService.client
          .from('audit_logs')
          .select('id, actor_id, action, entity, new_value, created_at')
          .eq('entity', 'analytics_event')
          .order('created_at', ascending: false)
          .limit(300);

      _rawEvents.clear();
      _knownEventIds.clear();

      for (var row in logsRes) {
        final parsed = _parseAuditLogRow(row);
        if (parsed != null) {
          final id = parsed['id']?.toString() ?? '';
          if (id.isNotEmpty && !_knownEventIds.contains(id)) {
            _knownEventIds.add(id);
            _rawEvents.add(parsed);
          }
        }
      }

      _recalculateMetrics();
    } catch (e) {
      debugPrint('[AdminLiveActivity] Telemetry load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscription() {
    try {
      _realtimeChannel = SupabaseService.client
          .channel('admin_live_activity_stream')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'audit_logs',
            callback: (payload) {
              if (!_isLiveStreamingPaused) {
                _handleIncomingAuditLogRow(payload.newRecord);
              }
            },
          )
          .subscribe((status, [error]) {
            if (mounted) {
              setState(() {
                _isRealtimeSubscribed = status == RealtimeSubscribeStatus.subscribed;
              });
            }
          });
    } catch (e) {
      debugPrint('[AdminLiveActivity] Realtime subscription error: $e');
    }

    // Secondary auto-sync timer every 10s for consistency across network drops
    if (widget.enableTimers) {
      _periodicSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted && !_isLiveStreamingPaused) {
          _syncLatestEventsSilently();
        }
      });
    }
  }

  void _handleIncomingAuditLogRow(Map<String, dynamic> row) {
    if (row['entity'] != 'analytics_event') return;
    final rowId = row['id']?.toString() ?? '';
    if (rowId.isNotEmpty && _knownEventIds.contains(rowId)) return;
    if (rowId.isNotEmpty) _knownEventIds.add(rowId);

    final parsed = _parseAuditLogRow(row);
    if (parsed != null && mounted) {
      setState(() {
        _rawEvents.insert(0, parsed);
        // Measure real event latency from created_at to now
        final createdAt = DateTime.tryParse(parsed['created_at']?.toString() ?? '');
        if (createdAt != null) {
          final diff = DateTime.now().toUtc().difference(createdAt).inMilliseconds;
          if (diff >= 0 && diff < 10000) _latencyMs = diff;
        }
        _recalculateMetrics();
      });
    }
  }

  Future<void> _syncLatestEventsSilently() async {
    try {
      final latestRes = await SupabaseService.client
          .from('audit_logs')
          .select('id, actor_id, action, entity, new_value, created_at')
          .eq('entity', 'analytics_event')
          .order('created_at', ascending: false)
          .limit(30);

      bool hasNew = false;
      for (var row in latestRes) {
        final rowId = row['id']?.toString() ?? '';
        if (rowId.isNotEmpty && !_knownEventIds.contains(rowId)) {
          _knownEventIds.add(rowId);
          final parsed = _parseAuditLogRow(row);
          if (parsed != null) {
            _rawEvents.insert(0, parsed);
            hasNew = true;
          }
        }
      }

      if (hasNew && mounted) {
        // Re-sort descending
        _rawEvents.sort((a, b) {
          final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
          final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
          return db.compareTo(da);
        });
        setState(() => _recalculateMetrics());
      }
    } catch (_) {}
  }

  Map<String, dynamic>? _parseAuditLogRow(Map<String, dynamic> row) {
    try {
      final nv = row['new_value'];
      final props = (nv is Map && nv['properties'] is Map)
          ? Map<String, dynamic>.from(nv['properties'])
          : <String, dynamic>{};

      final devId = (nv is Map) ? nv['device_id']?.toString() : null;
      final sessId = (nv is Map) ? nv['session_id']?.toString() : null;
      final plat = (nv is Map) ? nv['platform']?.toString() : null;
      final appVer = (nv is Map) ? nv['app_version']?.toString() : null;
      final evtName = (nv is Map)
          ? (nv['event_name'] ?? row['action'])?.toString()
          : row['action']?.toString();
      final uid = (nv is Map)
          ? (nv['user_id'] ?? row['actor_id'])?.toString()
          : row['actor_id']?.toString();

      final screen = props['screen_name']?.toString() ??
          props['route_path']?.toString() ??
          props['canonical_path']?.toString() ??
          (evtName == 'screen_view' ? props['screen_class']?.toString() : null);

      return {
        'id': row['id'],
        'event_name': evtName ?? 'unknown',
        'user_id': uid,
        'device_id': devId,
        'session_id': sessId,
        'platform': plat ?? 'unknown',
        'app_version': appVer ?? '2.2.9+10',
        'screen_name': screen,
        'properties': props,
        'created_at': row['created_at'],
      };
    } catch (_) {
      return null;
    }
  }

  void _recalculateMetrics() {
    final nowUtc = DateTime.now().toUtc();
    final todayStartUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final fiveMinAgoUtc = nowUtc.subtract(const Duration(minutes: 5));

    final Set<String> sessionsToday = <String>{};
    int eventsToday = 0;

    final Set<String> activeStudentUserIds = <String>{};
    final Set<String> activeAdminUserIds = <String>{};
    final Set<String> activeAnonSessions = <String>{};

    final Set<String> activeWeb = <String>{};
    final Set<String> activeAndroid = <String>{};
    final Set<String> activeIos = <String>{};

    DateTime? latest;

    for (var ev in _rawEvents) {
      final dt = DateTime.tryParse(ev['created_at']?.toString() ?? '');
      if (dt == null) continue;

      if (latest == null || dt.isAfter(latest)) {
        latest = dt;
      }

      final sessId = ev['session_id']?.toString() ?? '';
      final uid = ev['user_id']?.toString();
      final plat = (ev['platform'] ?? '').toString().toLowerCase();
      final eventName = ev['event_name']?.toString() ?? '';

      // Count today's events and sessions
      if (dt.isAfter(todayStartUtc)) {
        eventsToday++;
        if (sessId.isNotEmpty) sessionsToday.add(sessId);
      }

      // Check active in last 5 minutes (ignoring explicitly backgrounded states)
      if (dt.isAfter(fiveMinAgoUtc) && eventName != 'app_backgrounded') {
        if (uid != null && uid.isNotEmpty) {
          final profile = _userProfilesMap[uid];
          final role = (profile?['role'] ?? 'student').toString().toLowerCase();
          if (role.contains('admin')) {
            activeAdminUserIds.add(uid);
          } else {
            activeStudentUserIds.add(uid);
          }
        } else {
          final key = sessId.isNotEmpty ? sessId : (ev['device_id']?.toString() ?? 'anon');
          activeAnonSessions.add(key);
        }

        // Active sessions by platform
        if (sessId.isNotEmpty) {
          if (plat.contains('android')) {
            activeAndroid.add(sessId);
          } else if (plat.contains('ios')) {
            activeIos.add(sessId);
          } else {
            activeWeb.add(sessId);
          }
        }
      }
    }

    _latestEventTimestamp = latest;
    _eventsTodayCount = eventsToday;
    _sessionsTodayCount = sessionsToday.length;
    _activeStudentsCount = activeStudentUserIds.length;
    _activeAdminsCount = activeAdminUserIds.length;
    _activeAnonymousCount = activeAnonSessions.length;
    _activeWebSessions = activeWeb.length;
    _activeAndroidSessions = activeAndroid.length;
    _activeIosSessions = activeIos.length;
  }

  /// Builds active users list aggregated from recent events
  List<Map<String, dynamic>> _getActiveUsersList() {
    final Map<String, Map<String, dynamic>> userAggregates = {};
    final nowUtc = DateTime.now().toUtc();

    for (var ev in _rawEvents) {
      final uid = ev['user_id']?.toString();
      final devId = ev['device_id']?.toString() ?? 'unknown_device';
      final sessId = ev['session_id']?.toString() ?? 'unknown_session';
      final plat = ev['platform']?.toString() ?? 'unknown';
      final appVer = ev['app_version']?.toString() ?? '2.2.9+10';
      final action = ev['event_name']?.toString() ?? '';
      final screen = ev['screen_name']?.toString();
      final dt = DateTime.tryParse(ev['created_at']?.toString() ?? '');
      if (dt == null) continue;

      final key = (uid != null && uid.isNotEmpty) ? 'user_$uid' : 'anon_${sessId}_$devId';

      if (!userAggregates.containsKey(key)) {
        final profile = (uid != null) ? _userProfilesMap[uid] : null;
        final role = profile?['role']?.toString().toUpperCase() ?? (uid != null ? 'STUDENT' : 'VISITOR');
        final fullName = profile?['full_name']?.toString();
        final email = profile?['email']?.toString();

        userAggregates[key] = {
          'key': key,
          'user_id': uid,
          'device_id': devId,
          'session_id': sessId,
          'platform': plat,
          'app_version': appVer,
          'role': role,
          'display_name': (fullName != null && fullName.isNotEmpty)
              ? fullName
              : (email != null ? email.split('@').first : 'Anonymous Visitor'),
          'email': email ?? 'Anonymous (${devId.length > 8 ? devId.substring(0, 8) : devId})',
          'avatar_url': profile?['avatar_url'],
          'last_activity_time': dt,
          'session_start_time': dt,
          'last_action': action,
          'last_screen': screen ?? 'Overview',
          'event_count': 1,
          'is_backgrounded': action == 'app_backgrounded',
          'events': <Map<String, dynamic>>[ev],
        };
      } else {
        final existing = userAggregates[key]!;
        existing['event_count'] = (existing['event_count'] as int) + 1;
        (existing['events'] as List<Map<String, dynamic>>).add(ev);

        // Keep latest screen and last action
        final existingLastTime = existing['last_activity_time'] as DateTime;
        if (dt.isAfter(existingLastTime)) {
          existing['last_activity_time'] = dt;
          existing['last_action'] = action;
          if (screen != null && screen.isNotEmpty) {
            existing['last_screen'] = screen;
          }
          if (action == 'app_backgrounded') {
            existing['is_backgrounded'] = true;
          } else if (action == 'app_foregrounded' || action == 'screen_view') {
            existing['is_backgrounded'] = false;
          }
        }

        // Earliest is session start
        final existingStartTime = existing['session_start_time'] as DateTime;
        if (dt.isBefore(existingStartTime)) {
          existing['session_start_time'] = dt;
        }
      }
    }

    final list = userAggregates.values.toList();

    // Determine Presence State:
    // Active: event within 5 min and not backgrounded
    // Idle: 5 - 30 min ago, or backgrounded
    // Offline: > 30 min ago or explicit logout
    for (var u in list) {
      final lastTime = u['last_activity_time'] as DateTime;
      final diffMin = nowUtc.difference(lastTime).inMinutes;
      final bool isBg = u['is_backgrounded'] == true;
      final String lastAct = u['last_action']?.toString() ?? '';

      if (lastAct == 'logout' || diffMin > 30) {
        u['presence_state'] = 'Offline';
        u['presence_color'] = const Color(0xFF64748B); // Slate
      } else if (isBg || diffMin >= 5) {
        u['presence_state'] = 'Idle';
        u['presence_color'] = const Color(0xFFF59E0B); // Amber
      } else {
        u['presence_state'] = 'Active';
        u['presence_color'] = const Color(0xFF10B981); // Emerald
      }
    }

    // Sort by last activity descending
    list.sort((a, b) {
      final da = a['last_activity_time'] as DateTime;
      final db = b['last_activity_time'] as DateTime;
      return db.compareTo(da);
    });

    // Apply role filter
    if (_selectedRoleFilter != 'ALL') {
      return list.where((u) {
        final r = u['role']?.toString().toUpperCase() ?? '';
        if (_selectedRoleFilter == 'STUDENTS') return r == 'STUDENT';
        if (_selectedRoleFilter == 'ADMINS') return r.contains('ADMIN');
        if (_selectedRoleFilter == 'ANONYMOUS') return r == 'VISITOR';
        return true;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      return list.where((u) {
        final name = (u['display_name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final screen = (u['last_screen'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || screen.contains(q);
      }).toList();
    }

    return list;
  }

  /// Filters events stream according to selected category, platform, and search
  List<Map<String, dynamic>> _getFilteredEvents() {
    return _rawEvents.where((ev) {
      final action = (ev['event_name'] ?? '').toString().toLowerCase();
      final plat = (ev['platform'] ?? '').toString().toLowerCase();

      // Platform filter
      if (_selectedPlatform != 'ALL') {
        if (_selectedPlatform == 'ANDROID' && !plat.contains('android')) return false;
        if (_selectedPlatform == 'IOS' && !plat.contains('ios')) return false;
        if (_selectedPlatform == 'WEB' && !plat.contains('web')) return false;
      }

      // Category filter
      if (_selectedCategory != 'ALL') {
        switch (_selectedCategory) {
          case 'SCREEN_VIEWS':
            if (action != 'screen_view' && action != 'page_view') return false;
            break;
          case 'AUTH':
            if (action != 'login' && action != 'logout' && action != 'session_start' && action != 'first_open' && action != 'sign_up') {
              return false;
            }
            break;
          case 'TESTS':
            if (!action.contains('test_')) return false;
            break;
          case 'QUESTIONS':
            if (!action.contains('question_')) return false;
            break;
          case 'PRACTICE':
            if (!action.contains('practice')) return false;
            break;
          case 'SOLUTIONS':
            if (!action.contains('solution')) return false;
            break;
          case 'COMMERCE':
            if (!action.contains('purchase') && !action.contains('checkout') && !action.contains('enroll')) {
              return false;
            }
            break;
          case 'ERRORS':
            if (!action.contains('error') && !action.contains('crash') && !action.contains('fail')) {
              return false;
            }
            break;
        }
      }

      // Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final screen = (ev['screen_name'] ?? '').toString().toLowerCase();
        final uid = (ev['user_id'] ?? '').toString().toLowerCase();
        final devId = (ev['device_id'] ?? '').toString().toLowerCase();
        final act = action.toLowerCase();
        if (!screen.contains(q) && !uid.contains(q) && !devId.contains(q) && !act.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // Deep dark background
      body: Row(
        children: [
          if (isWide) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF6366F1),
                          backgroundColor: const Color(0xFF1E293B),
                          onRefresh: _loadInitialTelemetry,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            children: [
                              _buildLiveOverviewCards(),
                              const SizedBox(height: 24),
                              _buildCurrentlyActiveUsersSection(),
                              const SizedBox(height: 28),
                              _buildLiveEventStreamSection(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 1. SIDEBAR =================
  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('C', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cosmyra Admin', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Live Telemetry Center', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              children: [
                _buildSidebarSectionHeader('CORE DASHBOARD'),
                _buildSidebarTile(Icons.dashboard_rounded, 'Overview & KPIs', false, onTap: () {
                  context.go('/admin');
                }),
                _buildSidebarTile(Icons.quiz_rounded, 'Question Bank', false, onTap: () {
                  context.go('/admin/questions');
                }),
                _buildSidebarTile(Icons.account_tree_rounded, 'Exam Hierarchy', false, onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminHierarchyScreen(userProfile: _adminProfile)));
                }),
                _buildSidebarTile(Icons.people_alt_rounded, 'User Management', false, onTap: () {
                  context.go('/admin/users');
                }),

                const SizedBox(height: 16),
                _buildSidebarSectionHeader('REPORTS & ANALYTICS'),
                _buildSidebarTile(Icons.bar_chart_rounded, 'Analytics Dashboard', false, onTap: () {
                  context.go('/admin/analytics');
                }),
                _buildSidebarTile(Icons.sensors_rounded, 'Live User Activity', true, onTap: () {}),
                _buildSidebarTile(Icons.insights_rounded, 'Student Performance', false, onTap: () {}),

                const SizedBox(height: 16),
                _buildSidebarSectionHeader('SYSTEM'),
                _buildSidebarTile(Icons.arrow_back_rounded, 'Exit to Website', false, onTap: () {
                  context.go('/');
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildSidebarTile(IconData icon, String title, bool isSelected, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _isRealtimeSubscribed
            ? const Color(0xFF10B981).withOpacity(0.15)
            : const Color(0xFFF59E0B).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRealtimeSubscribed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRealtimeSubscribed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isRealtimeSubscribed ? 'REAL-TIME ACTIVE' : 'AUTO-SYNC (10s)',
            style: TextStyle(
              color: _isRealtimeSubscribed ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. TOP HEADER =================
  Widget _buildTopHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Live User Activity Monitor',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        _buildRealtimeBadge(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Latency: ~${_latencyMs}ms', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => setState(() => _isLiveStreamingPaused = !_isLiveStreamingPaused),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _isLiveStreamingPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: Text(
                            _isLiveStreamingPaused ? 'Resume' : 'Pause',
                            style: TextStyle(color: _isLiveStreamingPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8), size: 18),
                          onPressed: _loadInitialTelemetry,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text(
                                'Live User Activity Monitor',
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              _buildRealtimeBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Live screen views, student sessions, and presence telemetry across Web, Android, and iOS.',
                            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 6),
                          Text(
                            'Latency: ~${_latencyMs}ms',
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _isLiveStreamingPaused = !_isLiveStreamingPaused),
                      icon: Icon(
                        _isLiveStreamingPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 16,
                        color: _isLiveStreamingPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                      label: Text(
                        _isLiveStreamingPaused ? 'Resume' : 'Pause',
                        style: TextStyle(
                          color: _isLiveStreamingPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _isLiveStreamingPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Manual Sync Now',
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
                      onPressed: _loadInitialTelemetry,
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ================= 3. LIVE OVERVIEW CARDS =================
  Widget _buildLiveOverviewCards() {
    final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final String lastTimeStr = _latestEventTimestamp != null
        ? '${DateFormat('hh:mm:ss a').format(_latestEventTimestamp!.toUtc().add(const Duration(hours: 5, minutes: 30)))} IST'
        : 'Awaiting events';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        final int crossAxisCount = isCompact ? 2 : 4;

        return Column(
          children: [
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isCompact ? 1.6 : 1.9,
              children: [
                _buildMetricCard(
                  title: 'Active Students (5m)',
                  value: '$_activeStudentsCount',
                  subtitle: 'Genuine non-admin learners',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF10B981),
                  badge: '🟢 Real-time',
                ),
                _buildMetricCard(
                  title: 'Active Admins (5m)',
                  value: '$_activeAdminsCount',
                  subtitle: 'Administrative observers',
                  icon: Icons.admin_panel_settings_rounded,
                  color: const Color(0xFF6366F1),
                  badge: 'Superadmin',
                ),
                _buildMetricCard(
                  title: 'Anonymous Visitors',
                  value: '$_activeAnonymousCount',
                  subtitle: 'Prospective leads on web/PWA',
                  icon: Icons.visibility_rounded,
                  color: const Color(0xFF38BDF8),
                  badge: 'Tracking',
                ),
                _buildMetricCard(
                  title: 'Platform Sessions',
                  value: '${_activeWebSessions + _activeAndroidSessions + _activeIosSessions}',
                  subtitle: '🌐 Web: $_activeWebSessions • 🤖 Android: $_activeAndroidSessions • 🍎 iOS: $_activeIosSessions',
                  icon: Icons.devices_rounded,
                  color: const Color(0xFFEC4899),
                  badge: 'Active Now',
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isCompact ? 1.8 : 2.2,
              children: [
                _buildMetricCard(
                  title: 'Total Sessions Today',
                  value: '$_sessionsTodayCount',
                  subtitle: 'Distinct session UUIDs since 00:00 UTC',
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFF59E0B),
                  badge: 'Today',
                ),
                _buildMetricCard(
                  title: 'Events Ingested Today',
                  value: '$_eventsTodayCount',
                  subtitle: 'Persisted to Supabase audit_logs',
                  icon: Icons.stream_rounded,
                  color: const Color(0xFF8B5CF6),
                  badge: 'Telemetry',
                ),
                _buildMetricCard(
                  title: 'Latest Ingestion',
                  value: lastTimeStr,
                  subtitle: _latestEventTimestamp != null
                      ? '${DateTime.now().toUtc().difference(_latestEventTimestamp!).inSeconds}s elapsed'
                      : 'Connecting...',
                  icon: Icons.access_time_filled_rounded,
                  color: const Color(0xFF14B8A6),
                  badge: 'IST',
                ),
                _buildMetricCard(
                  title: 'Pipeline Status',
                  value: _isRealtimeSubscribed ? 'Connected' : 'Delayed (Sync)',
                  subtitle: 'Supabase Postgres Changes Channel',
                  icon: Icons.health_and_safety_rounded,
                  color: _isRealtimeSubscribed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  badge: 'Healthy',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ================= 4. CURRENTLY ACTIVE USERS SECTION =================
  Widget _buildCurrentlyActiveUsersSection() {
    final activeUsers = _getActiveUsersList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline_rounded, color: Color(0xFF818CF8), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Currently Observed Users & Sessions',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activeUsers.length} Recorded',
                      style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildFilterPill('All Roles', 'ALL', _selectedRoleFilter, (v) => setState(() => _selectedRoleFilter = v)),
                  _buildFilterPill('Students', 'STUDENTS', _selectedRoleFilter, (v) => setState(() => _selectedRoleFilter = v)),
                  _buildFilterPill('Admins', 'ADMINS', _selectedRoleFilter, (v) => setState(() => _selectedRoleFilter = v)),
                  _buildFilterPill('Anonymous', 'ANONYMOUS', _selectedRoleFilter, (v) => setState(() => _selectedRoleFilter = v)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search by student name, email, screen, or platform...',
                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                icon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Active Users Table
          activeUsers.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.person_off_rounded, color: Color(0xFF64748B), size: 36),
                      const SizedBox(height: 10),
                      Text('No active users observed matching criteria', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFF0F172A)),
                      dataRowColor: MaterialStateProperty.all(Colors.transparent),
                      columnSpacing: 22,
                      horizontalMargin: 16,
                      columns: const [
                        DataColumn(label: Text('USER', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('CURRENT SCREEN / PAGE', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('PLATFORM & DEVICE', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('LAST ACTIVITY', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('PRESENCE', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('ACTION', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                      rows: activeUsers.map((user) {
                        final lastTime = user['last_activity_time'] as DateTime;
                        final elapsedSec = DateTime.now().toUtc().difference(lastTime).inSeconds;
                        final String elapsedStr = elapsedSec < 60
                            ? '${elapsedSec}s ago'
                            : '${(elapsedSec / 60).floor()}m ago';

                        final plat = user['platform']?.toString().toLowerCase() ?? '';
                        final role = user['role']?.toString().toUpperCase() ?? 'STUDENT';
                        final presenceState = user['presence_state']?.toString() ?? 'Offline';
                        final presenceColor = user['presence_color'] as Color? ?? Colors.grey;

                        return DataRow(
                          cells: [
                            // 1. User Info
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF6366F1),
                                    backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                                    child: user['avatar_url'] == null
                                        ? Text(
                                            (user['display_name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user['display_name'],
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: role.contains('ADMIN')
                                                  ? const Color(0xFF6366F1).withOpacity(0.2)
                                                  : (role == 'VISITOR' ? const Color(0xFF38BDF8).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              role,
                                              style: TextStyle(
                                                color: role.contains('ADMIN')
                                                    ? const Color(0xFFA5B4FC)
                                                    : (role == 'VISITOR' ? const Color(0xFF7DD3FC) : const Color(0xFF6EE7B7)),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(user['email'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 2. Current Screen / Page
                            DataCell(
                              Row(
                                children: [
                                  const Icon(Icons.touch_app_rounded, color: Color(0xFF818CF8), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    user['last_screen'],
                                    style: const TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),

                            // 3. Platform & Device
                            DataCell(
                              Row(
                                children: [
                                  Icon(
                                    plat.contains('android')
                                        ? Icons.android_rounded
                                        : (plat.contains('ios') ? Icons.apple_rounded : Icons.language_rounded),
                                    size: 16,
                                    color: plat.contains('android')
                                        ? const Color(0xFF34D399)
                                        : (plat.contains('ios') ? Colors.white : const Color(0xFF38BDF8)),
                                  ),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        plat.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text('v${user['app_version']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 4. Last Activity
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(elapsedStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(
                                    user['last_action'],
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // 5. Presence State
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: presenceColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: presenceColor.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: presenceColor),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      presenceState,
                                      style: TextStyle(color: presenceColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 6. Action Button: View Timeline
                            DataCell(
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showUserTimelineModal(user);
                                },
                                icon: const Icon(Icons.history_rounded, size: 14),
                                label: const Text('View Timeline', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  foregroundColor: const Color(0xFF818CF8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: const BorderSide(color: Color(0xFF334155)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ================= 5. LIVE EVENT STREAM SECTION =================
  Widget _buildLiveEventStreamSection() {
    final filteredEvents = _getFilteredEvents();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stream_rounded, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              Text(
                'Live Event Stream',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredEvents.length} Events',
                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),

              // Platform Filter
              DropdownButton<String>(
                value: _selectedPlatform,
                dropdownColor: const Color(0xFF1E293B),
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Platforms')),
                  DropdownMenuItem(value: 'ANDROID', child: Text('🤖 Android App')),
                  DropdownMenuItem(value: 'IOS', child: Text('🍎 iOS App')),
                  DropdownMenuItem(value: 'WEB', child: Text('🌐 Web / PWA')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedPlatform = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill('All Activity', 'ALL', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                const SizedBox(width: 6),
                _buildFilterPill('📱 Screen Views', 'SCREEN_VIEWS', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                const SizedBox(width: 6),
                _buildFilterPill('🔐 Auth & Sessions', 'AUTH', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                const SizedBox(width: 6),
                _buildFilterPill('📝 Tests & Exams', 'TESTS', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                const SizedBox(width: 6),
                _buildFilterPill('❓ Questions & QA', 'QUESTIONS', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                const SizedBox(width: 6),
                _buildFilterPill('📖 Practice & Study', 'PRACTICE', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                const SizedBox(width: 6),
                _buildFilterPill('💡 Solutions & Videos', 'SOLUTIONS', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                const SizedBox(width: 6),
                _buildFilterPill('🛒 Purchases & Enroll', 'COMMERCE', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                const SizedBox(width: 6),
                _buildFilterPill('⚠️ Errors & Crashes', 'ERRORS', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Events list
          filteredEvents.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_rounded, color: Color(0xFF64748B), size: 40),
                      const SizedBox(height: 12),
                      Text('No telemetry events matching the current filter', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length > 50 ? 50 : filteredEvents.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E293B), height: 1),
                  itemBuilder: (context, idx) {
                    final ev = filteredEvents[idx];
                    return _buildEventTile(ev);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEventTile(Map<String, dynamic> ev) {
    final eventName = (ev['event_name'] ?? 'unknown').toString();
    final dt = DateTime.tryParse(ev['created_at']?.toString() ?? '');
    final nowUtc = DateTime.now().toUtc();
    final elapsedSec = dt != null ? nowUtc.difference(dt).inSeconds : 0;
    final String elapsedStr = elapsedSec < 60
        ? '${elapsedSec}s ago'
        : (elapsedSec < 3600 ? '${(elapsedSec / 60).floor()}m ago' : '${(elapsedSec / 3600).floor()}h ago');

    final istStr = dt != null
        ? DateFormat('hh:mm:ss a').format(dt.toUtc().add(const Duration(hours: 5, minutes: 30)))
        : '';

    final uid = ev['user_id']?.toString();
    final profile = uid != null ? _userProfilesMap[uid] : null;
    final role = profile?['role']?.toString().toUpperCase() ?? (uid != null ? 'STUDENT' : 'VISITOR');
    final userName = profile?['full_name'] ?? (uid != null ? (profile?['email']?.split('@').first ?? 'Student') : 'Anonymous Visitor');
    final plat = (ev['platform'] ?? '').toString().toLowerCase();
    final screen = ev['screen_name']?.toString() ?? 'Direct Route';

    IconData iconData = Icons.radio_button_checked_rounded;
    Color iconColor = const Color(0xFF6366F1);

    if (eventName == 'screen_view' || eventName == 'page_view') {
      iconData = Icons.remove_red_eye_rounded;
      iconColor = const Color(0xFF38BDF8); // Cyan
    } else if (eventName.contains('test_start')) {
      iconData = Icons.play_circle_fill_rounded;
      iconColor = const Color(0xFF10B981); // Emerald
    } else if (eventName.contains('test_submit')) {
      iconData = Icons.task_alt_rounded;
      iconColor = const Color(0xFF8B5CF6); // Purple
    } else if (eventName.contains('question_')) {
      iconData = Icons.quiz_rounded;
      iconColor = const Color(0xFFF59E0B); // Amber
    } else if (eventName.contains('solution')) {
      iconData = Icons.lightbulb_rounded;
      iconColor = const Color(0xFFFBBF24);
    } else if (eventName.contains('login') || eventName.contains('session_start')) {
      iconData = Icons.login_rounded;
      iconColor = const Color(0xFF34D399);
    } else if (eventName.contains('app_backgrounded')) {
      iconData = Icons.bedtime_rounded;
      iconColor = const Color(0xFF64748B);
    } else if (eventName.contains('app_foregrounded')) {
      iconData = Icons.wb_sunny_rounded;
      iconColor = const Color(0xFFF59E0B);
    } else if (eventName.contains('purchase') || eventName.contains('enroll')) {
      iconData = Icons.shopping_bag_rounded;
      iconColor = const Color(0xFFEC4899);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      eventName,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        screen,
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$elapsedStr ($istStr IST)',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$userName • ',
                      style: TextStyle(
                        color: role.contains('ADMIN') ? const Color(0xFFA5B4FC) : const Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      plat.contains('android')
                          ? Icons.android_rounded
                          : (plat.contains('ios') ? Icons.apple_rounded : Icons.language_rounded),
                      size: 13,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plat.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, String value, String activeValue, Function(String) onSelect) {
    final bool isSelected = value == activeValue;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ================= 6. INDIVIDUAL USER TIMELINE MODAL =================
  void _showUserTimelineModal(Map<String, dynamic> user) {
    final events = (user['events'] as List<Map<String, dynamic>>? ?? [])..sort((a, b) {
        final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return db.compareTo(da); // Newest on top
      });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: Color(0xFF334155))),
          ),
          child: Column(
            children: [
              // Modal Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF6366F1),
                      backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                      child: user['avatar_url'] == null
                          ? Text(
                              (user['display_name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user['display_name'],
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user['role'],
                                style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${user['email']} • Platform: ${user['platform'].toString().toUpperCase()} (v${user['app_version']})',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // Timeline Events List
              Expanded(
                child: events.isEmpty
                    ? const Center(child: Text('No recorded activity events for this user', style: TextStyle(color: Color(0xFF94A3B8))))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        itemCount: events.length,
                        itemBuilder: (context, i) {
                          final ev = events[i];
                          final eventName = ev['event_name']?.toString() ?? 'event';
                          final screen = ev['screen_name']?.toString() ?? 'General Navigation';
                          final dt = DateTime.tryParse(ev['created_at']?.toString() ?? '');
                          final istStr = dt != null
                              ? DateFormat('dd MMM yyyy, hh:mm:ss a').format(dt.toUtc().add(const Duration(hours: 5, minutes: 30)))
                              : '—';

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                  if (i < events.length - 1)
                                    Container(
                                      width: 2,
                                      height: 60,
                                      color: const Color(0xFF1E293B),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            eventName,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E293B),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              screen,
                                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$istStr IST',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                      if (ev['properties'] is Map && (ev['properties'] as Map).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            'Metadata: ${(ev['properties'] as Map).entries.where((e) => e.key != 'password' && e.key != 'token').map((e) => '${e.key}: ${e.value}').take(4).join(' • ')}',
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
