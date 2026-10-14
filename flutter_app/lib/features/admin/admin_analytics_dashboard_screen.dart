import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/analytics_service.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/utils/smooth_page_route.dart';
import 'admin_dashboard_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_hierarchy_screen.dart';

/// Complete Production-Grade Analytics and KPI Dashboard for Cosmyra Neet Jee Admin
class AdminAnalyticsDashboardScreen extends StatefulWidget {
  final UserProfileModel? userProfile;

  const AdminAnalyticsDashboardScreen({super.key, this.userProfile});

  @override
  State<AdminAnalyticsDashboardScreen> createState() => _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState extends State<AdminAnalyticsDashboardScreen> {
  bool _isLoading = true;
  String _selectedDatePreset = 'Last 30 Days';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPlatform = 'all'; // 'all', 'web', 'android', 'ios'
  String _activityEventTypeFilter = 'all'; // 'all', 'tests', 'learning', 'auth', 'commerce'
  String _activitySearchQuery = '';
  int _activityCurrentPage = 1;
  static const int _activityPageSize = 10;

  List<UserProfileModel> _profiles = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _attempts = [];
  List<Map<String, dynamic>> _entitlements = [];
  List<Map<String, dynamic>> _telemetryEvents = [];
  KpiDashboardData? _kpiData;

  late UserProfileModel _adminProfile;

  // Real-time streaming & auto-refresh state
  RealtimeChannel? _realtimeChannel;
  Timer? _periodicSyncTimer;
  final Set<String> _knownEventIds = <String>{};
  bool _hasQueryError = false;
  bool _isRealtimeSubscribed = false;

  @override
  void initState() {
    super.initState();
    _adminProfile = widget.userProfile ??
        SupabaseService.activeUserSession ??
        UserProfileModel(
          id: 'admin_sys',
          email: 'admin@neet-jee.in',
          fullName: 'Dr. Sharma (Admin)',
          role: 'super_admin',
        );

    _loadAnalyticsData().then((_) {
      if (mounted) {
        _setupRealtimeSubscription();
      }
    });
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    if (_realtimeChannel != null) {
      try {
        SupabaseService.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
    }
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    try {
      _realtimeChannel = SupabaseService.client
          .channel('admin_analytics_realtime_feed')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'audit_logs',
            callback: (payload) {
              _handleIncomingAuditLogRow(payload.newRecord);
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
      debugPrint('[AdminAnalytics] Realtime channel subscription error: $e');
    }

    // Secondary auto-sync timer every 15s to guarantee eventual consistency across network reconnects
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        _syncLatestEventsSilently();
      }
    });
  }

  void _handleIncomingAuditLogRow(Map<String, dynamic> row) {
    if (row['entity'] != 'analytics_event') return;
    final rowId = row['id']?.toString();
    if (rowId != null && _knownEventIds.contains(rowId)) return;
    if (rowId != null) _knownEventIds.add(rowId);

    final nv = row['new_value'];
    final props = (nv is Map && nv['properties'] is Map)
        ? Map<String, dynamic>.from(nv['properties'])
        : <String, dynamic>{};
    final devId = (nv is Map) ? nv['device_id']?.toString() : null;
    final sessId = (nv is Map) ? nv['session_id']?.toString() : null;
    final plat = (nv is Map) ? nv['platform']?.toString() : null;
    final evtName = (nv is Map)
        ? (nv['event_name'] ?? row['action'])?.toString()
        : row['action']?.toString();
    final uid = (nv is Map)
        ? (nv['user_id'] ?? row['actor_id'])?.toString()
        : row['actor_id']?.toString();

    final parsedEvent = {
      'id': row['id'],
      'event_name': evtName ?? 'unknown',
      'user_id': uid,
      'device_id': devId,
      'session_id': sessId,
      'platform': plat,
      'properties': props,
      'created_at': row['created_at'],
    };

    if (mounted) {
      setState(() {
        _telemetryEvents.insert(0, parsedEvent);
        _recalculateKpis();
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
          .limit(25);

      bool hasNew = false;
      for (var row in latestRes) {
        final rowId = row['id']?.toString();
        if (rowId != null && !_knownEventIds.contains(rowId)) {
          _knownEventIds.add(rowId);
          final nv = row['new_value'];
          final props = (nv is Map && nv['properties'] is Map)
              ? Map<String, dynamic>.from(nv['properties'])
              : <String, dynamic>{};
          final devId = (nv is Map) ? nv['device_id']?.toString() : null;
          final sessId = (nv is Map) ? nv['session_id']?.toString() : null;
          final plat = (nv is Map) ? nv['platform']?.toString() : null;
          final evtName = (nv is Map)
              ? (nv['event_name'] ?? row['action'])?.toString()
              : row['action']?.toString();
          final uid = (nv is Map)
              ? (nv['user_id'] ?? row['actor_id'])?.toString()
              : row['actor_id']?.toString();

          _telemetryEvents.insert(0, {
            'id': row['id'],
            'event_name': evtName ?? 'unknown',
            'user_id': uid,
            'device_id': devId,
            'session_id': sessId,
            'platform': plat,
            'properties': props,
            'created_at': row['created_at'],
          });
          hasNew = true;
        }
      }

      if (hasNew && mounted) {
        setState(() {
          _recalculateKpis();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _hasQueryError = false;
    });

    try {
      // 1. Concurrently fetch all authoritative database records and telemetry events from Supabase
      final results = await Future.wait([
        SupabaseService.fetchAllProfiles().timeout(
          const Duration(seconds: 4),
          onTimeout: () => <UserProfileModel>[],
        ),
        _fetchOrdersFromSupabase(),
        _fetchTestAttemptsFromSupabase(),
        _fetchEntitlementsFromSupabase(),
        _fetchTelemetryEventsFromSupabase(),
      ]);

      _profiles = results[0] as List<UserProfileModel>;
      _orders = results[1] as List<Map<String, dynamic>>;
      _attempts = results[2] as List<Map<String, dynamic>>;
      _entitlements = results[3] as List<Map<String, dynamic>>;
      _telemetryEvents = results[4] as List<Map<String, dynamic>>;

      _knownEventIds.clear();
      for (var e in _telemetryEvents) {
        final id = e['id']?.toString();
        if (id != null) _knownEventIds.add(id);
      }

      // 2. Compute authoritative KPI metrics via AnalyticsService
      _recalculateKpis();
    } catch (e) {
      _hasQueryError = true;
      debugPrint('[AdminAnalytics] Error loading analytics data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _recalculateKpis() {
    _kpiData = AnalyticsService.calculateKpiMetrics(
      profiles: _profiles,
      orders: _orders,
      testAttempts: _attempts,
      entitlements: _entitlements,
      telemetryEvents: _telemetryEvents,
      startDate: _startDate,
      endDate: _endDate,
      platformFilter: _selectedPlatform,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTelemetryEventsFromSupabase() async {
    try {
      // 1. Query dedicated analytics_events table if populated
      try {
        final res = await SupabaseService.client
            .from('analytics_events')
            .select('id, event_name, event_id, user_id, device_id, session_id, platform, properties, created_at')
            .order('created_at', ascending: false)
            .limit(1000);
        return List<Map<String, dynamic>>.from(res);
      } catch (_) {
        // 2. Fall back to audit_logs where entity = 'analytics_event'
        final res = await SupabaseService.client
            .from('audit_logs')
            .select('id, actor_id, action, entity, new_value, created_at')
            .eq('entity', 'analytics_event')
            .order('created_at', ascending: false)
            .limit(1000);

        final events = <Map<String, dynamic>>[];
        for (var row in res) {
          final nv = row['new_value'];
          final props = (nv is Map && nv['properties'] is Map)
              ? Map<String, dynamic>.from(nv['properties'])
              : <String, dynamic>{};
          final devId = (nv is Map) ? nv['device_id']?.toString() : null;
          final sessId = (nv is Map) ? nv['session_id']?.toString() : null;
          final plat = (nv is Map) ? nv['platform']?.toString() : null;
          final evtName = (nv is Map)
              ? (nv['event_name'] ?? row['action'])?.toString()
              : row['action']?.toString();
          final uid = (nv is Map)
              ? (nv['user_id'] ?? row['actor_id'])?.toString()
              : row['actor_id']?.toString();

          events.add({
            'id': row['id'],
            'event_name': evtName ?? 'unknown',
            'user_id': uid,
            'device_id': devId,
            'session_id': sessId,
            'platform': plat,
            'properties': props,
            'created_at': row['created_at'],
          });
        }
        return events;
      }
    } catch (e) {
      debugPrint('[AdminAnalytics] Telemetry events fetch note: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOrdersFromSupabase() async {
    try {
      final res = await SupabaseService.client
          .from('orders')
          .select('id, user_id, user_email, total_amount, subtotal_amount, discount_amount, status, payment_method, payment_id, created_at')
          .order('created_at', ascending: false)
          .limit(200);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[AdminAnalytics] Orders fetch note: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTestAttemptsFromSupabase() async {
    try {
      final res = await SupabaseService.client
          .from('test_attempts')
          .select('id, student_id, test_id, status, total_score, max_score, accuracy_percentage, time_spent_seconds, started_at, submitted_at, created_at')
          .order('created_at', ascending: false)
          .limit(500);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[AdminAnalytics] Test attempts fetch note: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEntitlementsFromSupabase() async {
    try {
      final res = await SupabaseService.client
          .from('entitlements')
          .select('id, user_id, user_email, product_id, product_title, product_type, access_type, valid_from, valid_until, is_active, created_at')
          .order('created_at', ascending: false)
          .limit(300);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[AdminAnalytics] Entitlements fetch note: $e');
      return [];
    }
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _selectedDatePreset = preset;
      if (preset == 'Today') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
      } else if (preset == 'Last 7 Days') {
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
      } else if (preset == 'Last 30 Days') {
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
      } else if (preset == 'Last 90 Days') {
        _startDate = now.subtract(const Duration(days: 90));
        _endDate = now;
      } else if (preset == 'All Time') {
        _startDate = DateTime(2026, 1, 1);
        _endDate = now;
      }
      _recalculateKpis();
    });
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDatePreset = 'Custom';
        _startDate = picked.start;
        _endDate = picked.end;
        _recalculateKpis();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 0. Authorization Guard: Check if user is an Administrator
    final isAuthorized = _adminProfile.role.toLowerCase().contains('admin');
    if (!isAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 48, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administrator privileges are required to view the Analytics & KPI Dashboard.',
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: const Text('Return to Home', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _kpiData ??
        AnalyticsService.calculateKpiMetrics(
          profiles: _profiles,
          orders: _orders,
          testAttempts: _attempts,
          entitlements: _entitlements,
          telemetryEvents: _telemetryEvents,
          startDate: _startDate,
          endDate: _endDate,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Standard Admin Sidebar
          _buildSidebar(),

          // 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopBanner(),
                              const SizedBox(height: 20),
                              _buildFiltersBar(),
                              const SizedBox(height: 24),

                              // High-impact KPI Metric Cards Grid
                              _buildKpiCardsGrid(data),
                              const SizedBox(height: 28),

                              // Interactive Time-Series Charts
                              _buildChartsSection(data),
                              const SizedBox(height: 28),

                              // Conversion Funnel & Retention Cohorts
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: _buildConversionFunnelCard(data)),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 7, child: _buildRetentionCohortsCard(data)),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Device Installs vs Registered Accounts & Platform Coverage
                              _buildDeviceVsAccountSection(data),
                              const SizedBox(height: 28),

                              // Section B: Live Student Activity Feed (Real-Time Ingestion)
                              _buildLiveStudentActivitySection(),
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
          // Brand Logo
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cosmyra Admin', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('KPI & Analytics Center', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              children: [
                _buildSidebarSectionHeader('CORE DASHBOARD'),
                _buildSidebarTile(Icons.dashboard_rounded, 'Overview & KPIs', false, onTap: () {
                  Navigator.of(context).push(SmoothPageRoute(child: AdminDashboardScreen(userProfile: _adminProfile)));
                }),
                _buildSidebarTile(Icons.quiz_rounded, 'Question Bank', false, onTap: () {
                  context.go('/admin/questions');
                }),
                _buildSidebarTile(Icons.account_tree_rounded, 'Exam Hierarchy', false, onTap: () {
                  Navigator.of(context).push(SmoothPageRoute(child: AdminHierarchyScreen(userProfile: _adminProfile)));
                }),

                const SizedBox(height: 16),
                _buildSidebarSectionHeader('USERS & ROLES'),
                _buildSidebarTile(Icons.people_alt_rounded, 'User Management', false, onTap: () {
                  Navigator.of(context).push(SmoothPageRoute(child: AdminUserManagementScreen(userProfile: _adminProfile)));
                }),

                const SizedBox(height: 16),
                _buildSidebarSectionHeader('REPORTS & ANALYTICS'),
                _buildSidebarTile(Icons.bar_chart_rounded, 'Analytics Dashboard', true, onTap: () {}),
                _buildSidebarTile(Icons.insights_rounded, 'Student Performance', false, onTap: () {}),

                const SizedBox(height: 16),
                _buildSidebarSectionHeader('SYSTEM'),
                _buildSidebarTile(Icons.arrow_back_rounded, 'Exit to Website', false, onTap: () {
                  context.go('/');
                }),
              ],
            ),
          ),

          // User Profile Pill in Sidebar Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                AppAvatar.fromProfile(_adminProfile, size: 36, backgroundColor: const Color(0xFF6366F1)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_adminProfile.fullName.isNotEmpty ? _adminProfile.fullName : 'Administrator',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      const Text('Super Administrator', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildSidebarTile(IconData icon, String title, bool isActive, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, color: isActive ? Colors.white : const Color(0xFF94A3B8), size: 18),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : const Color(0xFFCBD5E1),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // ================= 2. TOP HEADER =================
  Widget _buildHeader() {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Text(
            'Executive KPI & Analytics Dashboard',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          const Spacer(),

          // Active Range Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Refresh live analytics',
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
    );
  }

  // ================= 3. TOP BANNER =================
  Widget _buildTopBanner() {
    final String statusText;
    final Color statusColor;
    final Color badgeBg;
    final Color badgeBorder;
    final String statusDescription;

    if (_hasQueryError) {
      statusText = 'PIPELINE ERROR';
      statusColor = const Color(0xFFEF4444);
      badgeBg = const Color(0xFFEF4444).withOpacity(0.2);
      badgeBorder = const Color(0xFFEF4444).withOpacity(0.4);
      statusDescription = 'Supabase telemetry query error. Data may be unavailable or disconnected.';
    } else if (_telemetryEvents.isEmpty) {
      statusText = 'AWAITING TELEMETRY';
      statusColor = const Color(0xFF94A3B8);
      badgeBg = const Color(0xFF94A3B8).withOpacity(0.2);
      badgeBorder = const Color(0xFF94A3B8).withOpacity(0.4);
      statusDescription = 'No client telemetry events recorded yet. Ready to ingest from Web, Android & iOS.';
    } else {
      final latestTime = _kpiData?.lastEventTimestamp;
      final minutesAgo = latestTime != null ? DateTime.now().difference(latestTime).inMinutes : 999;
      final hasStudent = _kpiData?.hasStudentActivity ?? false;

      if (minutesAgo <= 15) {
        if (hasStudent) {
          statusText = 'CONNECTED (STUDENT ACTIVITY)';
          statusColor = const Color(0xFF10B981);
          badgeBg = const Color(0xFF10B981).withOpacity(0.2);
          badgeBorder = const Color(0xFF10B981).withOpacity(0.4);
        } else {
          statusText = 'CONNECTED (ADMIN ACTIVE • 0 STUDENTS)';
          statusColor = const Color(0xFF818CF8);
          badgeBg = const Color(0xFF818CF8).withOpacity(0.2);
          badgeBorder = const Color(0xFF818CF8).withOpacity(0.4);
        }
      } else {
        statusText = 'DELAYED (>15M SINCE LAST EVENT)';
        statusColor = const Color(0xFFF59E0B);
        badgeBg = const Color(0xFFF59E0B).withOpacity(0.2);
        badgeBorder = const Color(0xFFF59E0B).withOpacity(0.4);
      }

      final timeFmt = latestTime != null ? DateFormat('hh:mm a, dd MMM (IST)').format(latestTime) : 'N/A';
      statusDescription = 'Telemetry ledger active (${_telemetryEvents.length} events logged). Last ingestion: $timeFmt. Student DAU excludes admin actions.';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insights_rounded, color: Color(0xFF818CF8), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Production KPI Intelligence',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 3, backgroundColor: statusColor),
                          const SizedBox(width: 5),
                          Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusDescription,
                  style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 4. FILTERS BAR =================
  Widget _buildFiltersBar() {
    final presets = ['Today', 'Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'All Time'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text('Date Range:', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5, color: const Color(0xFF475569))),
          const SizedBox(width: 10),
          ...presets.map((preset) {
            final isSelected = _selectedDatePreset == preset;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(preset, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                selected: isSelected,
                selectedColor: const Color(0xFF6366F1),
                labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF475569)),
                backgroundColor: const Color(0xFFF1F5F9),
                onSelected: (_) => _applyDatePreset(preset),
              ),
            );
          }),

          // Custom Picker Button
          ActionChip(
            avatar: const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF6366F1)),
            label: Text(_selectedDatePreset == 'Custom' ? 'Custom Range' : 'Custom...', style: const TextStyle(fontSize: 12)),
            backgroundColor: _selectedDatePreset == 'Custom' ? const Color(0xFFEEF2FF) : Colors.transparent,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            onPressed: _pickCustomDateRange,
          ),

          const Spacer(),

          // Platform Filter
          Text('Platform:', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5, color: const Color(0xFF475569))),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedPlatform,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Platforms')),
              DropdownMenuItem(value: 'web', child: Text('Flutter Web')),
              DropdownMenuItem(value: 'android', child: Text('Android App')),
              DropdownMenuItem(value: 'ios', child: Text('iOS App')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedPlatform = val;
                  _recalculateKpis();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= 5. KPI CARDS GRID =================
  Widget _buildKpiCardsGrid(KpiDashboardData data) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final crossAxisCount = width > 1100 ? 4 : (width > 700 ? 2 : 1);

      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.85,
        children: [
          // Card 1: Active Users (DAU / WAU / MAU)
          _buildKpiCard(
            title: 'DAILY ACTIVE USERS (DAU)',
            value: NumberFormat.compact().format(data.dau),
            subValue: '${data.wau} WAU • ${data.mau} MAU',
            icon: Icons.people_outline_rounded,
            badgeColor: const Color(0xFF3B82F6),
            trend: 'Qualifying Activity (IST)',
            isPositiveTrend: true,
          ),

          // Card 2: Authoritative Verified Revenue
          _buildKpiCard(
            title: 'VERIFIED REVENUE',
            value: currencyFmt.format(data.grossRevenue),
            subValue: '${currencyFmt.format(data.netRevenue)} Net (AOV: ${currencyFmt.format(data.aov)})',
            icon: Icons.currency_rupee_rounded,
            badgeColor: const Color(0xFF10B981),
            trend: '${data.completedOrdersCount} Paid Orders',
            isPositiveTrend: true,
          ),

          // Card 3: Test Practice & Completion Rate
          _buildKpiCard(
            title: 'TEST COMPLETION RATE',
            value: '${data.testCompletionRate.toStringAsFixed(1)}%',
            subValue: '${data.testSubmissionsCount} completed of ${data.testStartsCount} starts',
            icon: Icons.assignment_turned_in_outlined,
            badgeColor: const Color(0xFF8B5CF6),
            trend: 'Avg Score: ${data.avgScorePercentage.toStringAsFixed(1)}%',
            isPositiveTrend: true,
          ),

          // Card 4: Stability & Crash-Free Rate
          _buildKpiCard(
            title: 'CRASH-FREE USERS',
            value: data.crashFreePercentage != null ? '${data.crashFreePercentage}%' : 'N/A',
            subValue: 'Mobile (Android/iOS): Active • Web: Unsupported',
            icon: Icons.health_and_safety_outlined,
            badgeColor: const Color(0xFF06B6D4),
            trend: 'Awaiting Mobile Stream',
            isPositiveTrend: true,
          ),
        ],
      );
    });
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color badgeColor,
    required String trend,
    required bool isPositiveTrend,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: badgeColor),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subValue,
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositiveTrend ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPositiveTrend ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 6. INTERACTIVE CHARTS SECTION =================
  Widget _buildChartsSection(KpiDashboardData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: User Activity & Engagement Line Chart (7 days)
        Expanded(
          flex: 7,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Active Users & Engagement Trend',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
                        Text(
                          data.dailyTrendPoints.every((p) => p.activeUsers == 0)
                              ? 'Authentic Student Activity: 0 active students in period (Admin sessions excluded)'
                              : 'Daily active students and practice sessions',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Past 7 Days', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < data.dailyTrendPoints.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(data.dailyTrendPoints[idx].dateLabel,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.dailyTrendPoints.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.activeUsers.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF6366F1),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1).withOpacity(0.25),
                                const Color(0xFF6366F1).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Right: Platform Breakdown Donut Chart
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Builder(builder: (context) {
              final platDist = data.platformDistribution;
              final totalPlatEvents = platDist?.totalEvents ?? 0;
              final webEvents = platDist?.webEvents ?? 0;
              final androidEvents = platDist?.androidEvents ?? 0;
              final iosEvents = platDist?.iosEvents ?? 0;

              final pieSections = <PieChartSectionData>[];
              if (totalPlatEvents == 0) {
                pieSections.add(PieChartSectionData(
                  value: 100,
                  title: '0%',
                  color: const Color(0xFFE2E8F0),
                  radius: 35,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ));
              } else {
                if (webEvents > 0) {
                  final pct = (webEvents / totalPlatEvents * 100).round();
                  pieSections.add(PieChartSectionData(
                    value: webEvents.toDouble(),
                    title: '$pct%',
                    color: const Color(0xFF6366F1),
                    radius: 35,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ));
                }
                if (androidEvents > 0) {
                  final pct = (androidEvents / totalPlatEvents * 100).round();
                  pieSections.add(PieChartSectionData(
                    value: androidEvents.toDouble(),
                    title: '$pct%',
                    color: const Color(0xFF10B981),
                    radius: 35,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ));
                }
                if (iosEvents > 0) {
                  final pct = (iosEvents / totalPlatEvents * 100).round();
                  pieSections.add(PieChartSectionData(
                    value: iosEvents.toDouble(),
                    title: '$pct%',
                    color: const Color(0xFF06B6D4),
                    radius: 35,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ));
                }
              }

              final webPctStr = totalPlatEvents > 0 ? '${(webEvents / totalPlatEvents * 100).round()}%' : '0%';
              final androidPctStr = totalPlatEvents > 0 ? '${(androidEvents / totalPlatEvents * 100).round()}%' : '0%';
              final iosPctStr = totalPlatEvents > 0 ? '${(iosEvents / totalPlatEvents * 100).round()}%' : '0%';

              final String platformNote = (androidEvents == 0 && iosEvents == 0 && webEvents > 0)
                  ? 'Observed: 100% Flutter Web ($webEvents events). Mobile streams (Android/iOS) not yet observed.'
                  : 'Telemetry breakdown across all confirmed devices and active platforms.';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform & Device Distribution',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
                  Text('Active device sessions across operating systems',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: pieSections,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem('Web Portal', webPctStr, const Color(0xFF6366F1)),
                      _buildLegendItem('Android App', androidPctStr, const Color(0xFF10B981)),
                      _buildLegendItem('iOS App', iosPctStr, const Color(0xFF06B6D4)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      platformNote,
                      style: GoogleFonts.inter(fontSize: 10.5, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ($value)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
      ],
    );
  }

  // ================= 7. CONVERSION FUNNEL =================
  Widget _buildConversionFunnelCard(KpiDashboardData data) {
    // Only calculate conversion against visitors if visitors were actually tracked and exceed or equal signups
    final hasValidVisitorBaseline = data.funnelVisits > 0 && data.funnelVisits >= data.funnelSignups;

    final steps = [
      {
        'name': data.funnelVisits > 0 ? '1. App / Web Visitors (Telemetry)' : '1. App / Web Visitors (Pipeline Pending)',
        'count': data.funnelVisits > 0 ? '${data.funnelVisits}' : 'Awaiting',
        'pct': hasValidVisitorBaseline ? 100 : null,
      },
      {
        'name': '2. Registered Accounts',
        'count': '${data.funnelSignups}',
        'pct': hasValidVisitorBaseline ? ((data.funnelSignups / data.funnelVisits) * 100).round() : 100,
      },
      {
        'name': '3. Tests Started',
        'count': '${data.funnelTestStarts}',
        'pct': data.funnelSignups > 0 ? ((data.funnelTestStarts / data.funnelSignups) * 100).round() : 0,
      },
      {
        'name': '4. Tests Submitted',
        'count': '${data.funnelTestCompletes}',
        'pct': data.funnelTestStarts > 0 ? ((data.funnelTestCompletes / data.funnelTestStarts) * 100).round() : 0,
      },
      {
        'name': '5. Series Explored',
        'count': '${data.funnelSeriesViews}',
        'pct': data.funnelSignups > 0 ? ((data.funnelSeriesViews / data.funnelSignups) * 100).round() : 0,
      },
      {
        'name': '6. Enrolled (Free/Paid)',
        'count': '${data.funnelEnrollments}',
        'pct': data.funnelSignups > 0 ? ((data.funnelEnrollments / data.funnelSignups) * 100).round() : 0,
      },
      {
        'name': '7. Verified Customers',
        'count': '${data.funnelPaidPurchases}',
        'pct': data.funnelSignups > 0 ? ((data.funnelPaidPurchases / data.funnelSignups) * 100).round() : 0,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('End-to-End Conversion Funnel',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
              const Icon(Icons.filter_alt_outlined, color: Color(0xFF64748B), size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasValidVisitorBaseline
                ? 'Visitor acquisition to verified paying students'
                : 'Stage progression (Visitor telemetry baseline newly instrumenting; pre-telemetry accounts in Auth DB)',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ...steps.map((s) {
            final pct = s['pct'] as int?;
            final pctDisplay = pct != null ? '$pct%' : '—';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s['name'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                      Text('${s['count']} ($pctDisplay)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct != null ? (pct / 100.0).clamp(0.02, 1.0) : 0.02,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (pct ?? 0) > 50 ? const Color(0xFF6366F1) : ((pct ?? 0) > 20 ? const Color(0xFF3B82F6) : const Color(0xFF10B981)),
                      ),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= 8. RETENTION COHORTS MATRIX =================
  Widget _buildRetentionCohortsCard(KpiDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Student Retention Cohorts (4-Week Rolling)',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
              const Icon(Icons.table_chart_outlined, color: Color(0xFF64748B), size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '% of registered students active across subsequent weeks from genuine qualifying activity. Pre-telemetry historical periods display as unavailable (—).',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Table
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.8),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
              5: FlexColumnWidth(1.5),
              6: FlexColumnWidth(1.5),
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  _cohortHeaderCell('Cohort'),
                  _cohortHeaderCell('Signups'),
                  _cohortHeaderCell('Wk 0'),
                  _cohortHeaderCell('Wk 1'),
                  _cohortHeaderCell('Wk 2'),
                  _cohortHeaderCell('Wk 3'),
                  _cohortHeaderCell('Wk 4'),
                ],
              ),

              // Rows
              ...data.retentionCohorts.map((row) {
                return TableRow(
                  children: [
                    _cohortDataCell(row.cohortLabel, isBold: true),
                    _cohortDataCell(row.signupsCount.toString()),
                    _cohortHeatmapCell(row.week0Pct),
                    _cohortHeatmapCell(row.week1Pct),
                    _cohortHeatmapCell(row.week2Pct),
                    _cohortHeatmapCell(row.week3Pct),
                    _cohortHeatmapCell(row.week4Pct),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cohortHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
    );
  }

  Widget _cohortDataCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Text(text,
          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF0F172A))),
    );
  }

  Widget _cohortHeatmapCell(int? percentage) {
    if (percentage == null) {
      return Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
        child: const Center(
          child: Text('—', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
        ),
      );
    }

    Color bg;
    if (percentage >= 80) {
      bg = const Color(0xFF4338CA).withOpacity(0.85);
    } else if (percentage >= 60) {
      bg = const Color(0xFF6366F1).withOpacity(0.75);
    } else if (percentage >= 40) {
      bg = const Color(0xFF818CF8).withOpacity(0.65);
    } else {
      bg = const Color(0xFFA5B4FC).withOpacity(0.45);
    }

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Center(
        child: Text('$percentage%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  // ================= 9. DEVICE VS ACCOUNTS & PLATFORM AUDIT =================
  Widget _buildDeviceVsAccountSection(KpiDashboardData data) {
    final String conversionText;
    if (data.installedDevicesCount > 0 && data.installedDevicesCount >= data.totalRegisteredUsers) {
      conversionText = '${((data.totalRegisteredUsers / data.installedDevicesCount) * 100).toStringAsFixed(1)}% Conversion';
    } else if (data.installedDevicesCount > 0) {
      conversionText = 'Direct Auth DB (${data.installedDevicesCount} Device Tracked)';
    } else {
      conversionText = 'Telemetry Ingestion Pending';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Identity Audit: Installed Devices vs Registered Student Accounts',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: const Text('Anti-Inflation Verification', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Distinguishing anonymous installed client hardware/browsers from verified authenticated student profiles in Supabase.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildIdentityPill(
                  title: 'Tracked Device Installations',
                  value: data.installedDevicesCount > 0
                      ? '${data.installedDevicesCount} Unique Device${data.installedDevicesCount > 1 ? 's' : ''}'
                      : '0 Devices Tracked (Pipeline Active)',
                  description: data.installedDevicesCount > 0
                      ? 'Privacy-conscious local install UUIDs confirmed in telemetry ledger'
                      : 'Telemetry pipeline active; awaiting client first-open telemetry',
                  color: const Color(0xFF3B82F6),
                  icon: Icons.devices_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIdentityPill(
                  title: 'Authoritative Registered Accounts',
                  value: '${data.totalRegisteredUsers} Verified Profiles',
                  description: 'Students with confirmed Supabase profiles, roles, and cohorts',
                  color: const Color(0xFF10B981),
                  icon: Icons.verified_user_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIdentityPill(
                  title: 'Active Conversion Ratio',
                  value: conversionText,
                  description: 'Proportion of device installations with authenticated active logins',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityPill({
    required String title,
    required String value,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(description, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  // ================= 10. SECTION B: LIVE STUDENT ACTIVITY STREAM =================
  Widget _buildLiveStudentActivitySection() {
    // 1. Filter telemetry events based on platform, event category, and search query
    final filtered = _telemetryEvents.where((e) {
      final plat = (e['platform'] ?? '').toString().toLowerCase();
      if (_selectedPlatform != 'all' && plat != _selectedPlatform) {
        return false;
      }

      final evtName = (e['event_name'] ?? '').toString().toLowerCase();
      if (_activityEventTypeFilter != 'all') {
        if (_activityEventTypeFilter == 'tests') {
          if (!evtName.contains('test') && !evtName.contains('question') && !evtName.contains('answer')) {
            return false;
          }
        } else if (_activityEventTypeFilter == 'learning') {
          if (!evtName.contains('practice') && !evtName.contains('solution') && !evtName.contains('note') && !evtName.contains('chapter')) {
            return false;
          }
        } else if (_activityEventTypeFilter == 'auth') {
          if (!evtName.contains('session') && !evtName.contains('login') && !evtName.contains('sign') && !evtName.contains('open')) {
            return false;
          }
        } else if (_activityEventTypeFilter == 'commerce') {
          if (!evtName.contains('order') && !evtName.contains('checkout') && !evtName.contains('payment') && !evtName.contains('enroll')) {
            return false;
          }
        }
      }

      if (_activitySearchQuery.isNotEmpty) {
        final q = _activitySearchQuery.toLowerCase();
        final dev = (e['device_id'] ?? '').toString().toLowerCase();
        final sess = (e['session_id'] ?? '').toString().toLowerCase();
        final uid = (e['user_id'] ?? '').toString().toLowerCase();
        final student = _profiles.where((p) => p.id == e['user_id']).firstOrNull;
        final name = (student?.fullName ?? '').toLowerCase();
        final email = (student?.email ?? '').toLowerCase();
        if (!evtName.contains(q) && !dev.contains(q) && !sess.contains(q) && !uid.contains(q) && !name.contains(q) && !email.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();

    final totalPages = (filtered.length / _activityPageSize).ceil().clamp(1, 9999);
    if (_activityCurrentPage > totalPages) {
      _activityCurrentPage = totalPages;
    }
    final startIndex = (_activityCurrentPage - 1) * _activityPageSize;
    final pageItems = filtered.skip(startIndex).take(_activityPageSize).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.stream_rounded, color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Student Activity Stream (Real-Time Ingestion)',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Authoritative chronological telemetry of authentic student actions. Zero fabricated rows.',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isRealtimeSubscribed ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isRealtimeSubscribed ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isRealtimeSubscribed ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isRealtimeSubscribed ? 'REAL-TIME STREAMING' : 'POLLING SYNC (15S)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: _isRealtimeSubscribed ? const Color(0xFF065F46) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _loadAnalyticsData,
                    icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF475569)),
                    label: const Text('Refresh Feed', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Bar: Categories & Search
          Row(
            children: [
              // Event category chips
              ...[
                {'id': 'all', 'label': 'All Actions'},
                {'id': 'tests', 'label': 'Tests & Questions'},
                {'id': 'learning', 'label': 'Practice & Solutions'},
                {'id': 'auth', 'label': 'Sessions & Logins'},
                {'id': 'commerce', 'label': 'Orders & Enrollments'},
              ].map((cat) {
                final isSel = _activityEventTypeFilter == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: isSel,
                    label: Text(cat['label']!, style: TextStyle(fontSize: 11.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    selectedColor: const Color(0xFF6366F1),
                    labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF475569)),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSelected: (_) {
                      setState(() {
                        _activityEventTypeFilter = cat['id']!;
                        _activityCurrentPage = 1;
                      });
                    },
                  ),
                );
              }),

              const Spacer(),

              // Search bar
              SizedBox(
                width: 260,
                height: 36,
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _activitySearchQuery = val.trim();
                      _activityCurrentPage = 1;
                    });
                  },
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search student or action...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Activity Event Stream List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text(
                    'No student activity matches the selected filters in this time window.',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The activity ledger reflects genuine, non-fabricated events emitted by real users.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ...pageItems.map((evt) {
                  final evtName = evt['event_name']?.toString() ?? 'unknown_event';
                  final uid = evt['user_id']?.toString();
                  final student = uid != null ? _profiles.where((p) => p.id == uid).firstOrNull : null;
                  final studentName = student?.fullName.isNotEmpty == true
                      ? student!.fullName
                      : (student?.email.isNotEmpty == true ? student!.email : (uid != null ? 'User: ${uid.substring(0, 8)}' : 'Anonymous Visitor'));
                  final plat = (evt['platform'] ?? 'web').toString().toUpperCase();
                  final devId = evt['device_id']?.toString() ?? 'device_unknown';
                  final sessId = evt['session_id']?.toString() ?? '';
                  final rawTime = evt['created_at'];
                  final parsedTime = rawTime != null ? DateTime.tryParse(rawTime.toString())?.toLocal() : null;
                  final timeLabel = parsedTime != null
                      ? DateFormat('dd MMM yyyy, hh:mm:ss a').format(parsedTime)
                      : (rawTime?.toString() ?? 'Just now');

                  // Check if student was active within the 5-minute presence window
                  final isRecentlyActive = parsedTime != null && DateTime.now().difference(parsedTime).inMinutes <= 5;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar / Identity Icon
                        AppAvatar(
                          name: studentName,
                          size: 36,
                          backgroundColor: uid != null ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: uid != null ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Event Body
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    studentName,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (student?.role.toLowerCase().contains('admin') == true || (uid != null && _adminProfile.id == uid))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                      ),
                                      child: const Text('ADMIN / AUDIT (EXCLUDED FROM DAU)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFC7D2FE)),
                                      ),
                                      child: const Text('STUDENT ACTIVITY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF4338CA))),
                                    ),
                                  const SizedBox(width: 6),
                                  if (isRecentlyActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('ACTIVE NOW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                                    ),
                                  const Spacer(),
                                  Text(timeLabel, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFC7D2FE)),
                                    ),
                                    child: Text(
                                      evtName,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4338CA)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(plat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Device: ${devId.length > 20 ? "${devId.substring(0, 16)}..." : devId}',
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                  ),
                                  if (sessId.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '• Session: ${sessId.length > 16 ? "${sessId.substring(0, 12)}..." : sessId}',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Pagination Row
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIndex + 1} - ${(startIndex + pageItems.length).clamp(0, filtered.length)} of ${filtered.length} genuine events',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _activityCurrentPage > 1
                              ? () => setState(() => _activityCurrentPage--)
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Previous', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Text('$_activityCurrentPage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _activityCurrentPage < totalPages
                              ? () => setState(() => _activityCurrentPage++)
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Next', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
