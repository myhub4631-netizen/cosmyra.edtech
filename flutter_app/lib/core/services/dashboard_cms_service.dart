import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

// ========================================================
// DATA MODELS FOR DASHBOARD CMS
// ========================================================

class DashboardSectionModel {
  final String id;
  final String sectionKey;
  final String title;
  final String subtitle;
  final int sortOrder;
  final bool isEnabled;
  final bool isVisible;
  final Map<String, dynamic> configJson;

  DashboardSectionModel({
    required this.id,
    required this.sectionKey,
    required this.title,
    required this.subtitle,
    required this.sortOrder,
    required this.isEnabled,
    required this.isVisible,
    this.configJson = const {},
  });

  factory DashboardSectionModel.fromJson(Map<String, dynamic> json) {
    return DashboardSectionModel(
      id: json['id']?.toString() ?? '',
      sectionKey: json['section_key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isEnabled: json['is_enabled'] ?? true,
      isVisible: json['is_visible'] ?? true,
      configJson: json['config_json'] is Map<String, dynamic> ? json['config_json'] : {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'section_key': sectionKey,
    'title': title,
    'subtitle': subtitle,
    'sort_order': sortOrder,
    'is_enabled': isEnabled,
    'is_visible': isVisible,
    'config_json': configJson,
  };

  DashboardSectionModel copyWith({
    String? id,
    String? sectionKey,
    String? title,
    String? subtitle,
    int? sortOrder,
    bool? isEnabled,
    bool? isVisible,
    Map<String, dynamic>? configJson,
  }) {
    return DashboardSectionModel(
      id: id ?? this.id,
      sectionKey: sectionKey ?? this.sectionKey,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      sortOrder: sortOrder ?? this.sortOrder,
      isEnabled: isEnabled ?? this.isEnabled,
      isVisible: isVisible ?? this.isVisible,
      configJson: configJson ?? this.configJson,
    );
  }
}

class DashboardBannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String ctaText;
  final String ctaDestination;
  final String? imageUrl;
  final String bgColor;
  final String btnColor;
  final String btnTextColor;
  final String iconName;
  final bool isActive;
  final int sortOrder;
  final DateTime? startAt;
  final DateTime? endAt;
  final String targetAudience;
  final int priority;

  DashboardBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.ctaDestination,
    this.imageUrl,
    this.bgColor = '#5B21B6',
    this.btnColor = '#FACC15',
    this.btnTextColor = '#1E1B4B',
    this.iconName = 'school',
    required this.isActive,
    required this.sortOrder,
    this.startAt,
    this.endAt,
    this.targetAudience = 'All Students',
    this.priority = 1,
  });

  factory DashboardBannerModel.fromJson(Map<String, dynamic> json) {
    return DashboardBannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      ctaText: json['cta_text']?.toString() ?? 'Subscribe Now',
      ctaDestination: json['cta_destination']?.toString() ?? '/practice',
      imageUrl: json['image_url']?.toString(),
      bgColor: json['bg_color']?.toString() ?? '#5B21B6',
      btnColor: json['btn_color']?.toString() ?? '#FACC15',
      btnTextColor: json['btn_text_color']?.toString() ?? '#1E1B4B',
      iconName: json['icon_name']?.toString() ?? 'school',
      isActive: json['is_active'] ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      startAt: json['start_at'] != null ? DateTime.tryParse(json['start_at'].toString()) : null,
      endAt: json['end_at'] != null ? DateTime.tryParse(json['end_at'].toString()) : null,
      targetAudience: json['target_audience']?.toString() ?? 'All Students',
      priority: (json['priority'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'title': title,
    'subtitle': subtitle,
    'cta_text': ctaText,
    'cta_destination': ctaDestination,
    'image_url': imageUrl,
    'bg_color': bgColor,
    'btn_color': btnColor,
    'btn_text_color': btnTextColor,
    'icon_name': iconName,
    'is_active': isActive,
    'sort_order': sortOrder,
    'start_at': startAt?.toIso8601String(),
    'end_at': endAt?.toIso8601String(),
    'target_audience': targetAudience,
    'priority': priority,
  };
}

class DashboardQuickStatModel {
  final String id;
  final String statKey;
  final String title;
  final String iconName;
  final String dataSource;
  final String changeText;
  final String status;
  final int sortOrder;
  final bool isEnabled;

  DashboardQuickStatModel({
    required this.id,
    required this.statKey,
    required this.title,
    required this.iconName,
    required this.dataSource,
    required this.changeText,
    this.status = 'Active',
    required this.sortOrder,
    required this.isEnabled,
  });

  factory DashboardQuickStatModel.fromJson(Map<String, dynamic> json) {
    return DashboardQuickStatModel(
      id: json['id']?.toString() ?? '',
      statKey: json['stat_key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      iconName: json['icon_name']?.toString() ?? 'bar_chart',
      dataSource: json['data_source']?.toString() ?? 'user_stats.questions_attempted',
      changeText: json['change_text']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isEnabled: json['is_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'stat_key': statKey,
    'title': title,
    'icon_name': iconName,
    'data_source': dataSource,
    'change_text': changeText,
    'status': status,
    'sort_order': sortOrder,
    'is_enabled': isEnabled,
  };
}

class DashboardQuickActionModel {
  final String id;
  final String actionKey;
  final String title;
  final String description;
  final String iconName;
  final String navType;
  final String destination;
  final bool isEnabled;
  final int sortOrder;
  final String targetExam;

  DashboardQuickActionModel({
    required this.id,
    required this.actionKey,
    required this.title,
    required this.description,
    required this.iconName,
    this.navType = 'route',
    required this.destination,
    required this.isEnabled,
    required this.sortOrder,
    this.targetExam = 'All',
  });

  factory DashboardQuickActionModel.fromJson(Map<String, dynamic> json) {
    return DashboardQuickActionModel(
      id: json['id']?.toString() ?? '',
      actionKey: json['action_key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconName: json['icon_name']?.toString() ?? 'assignment',
      navType: json['nav_type']?.toString() ?? 'route',
      destination: json['destination']?.toString() ?? '/practice',
      isEnabled: json['is_enabled'] ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      targetExam: json['target_exam']?.toString() ?? 'All',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'action_key': actionKey,
    'title': title,
    'description': description,
    'icon_name': iconName,
    'nav_type': navType,
    'destination': destination,
    'is_enabled': isEnabled,
    'sort_order': sortOrder,
    'target_exam': targetExam,
  };
}

class AuditLogModel {
  final String id;
  final String userId;
  final String userEmail;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.details,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userEmail: json['user_email']?.toString() ?? 'Admin',
      action: json['action']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      entityId: json['entity_id']?.toString() ?? '',
      details: json['details'] is Map<String, dynamic> ? json['details'] : {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ========================================================
// DASHBOARD CMS SERVICE LAYER
// ========================================================

class DashboardCmsService {
  static SupabaseClient get _client => SupabaseService.client;

  // --------------------------------------------------------
  // 1. DASHBOARD SECTIONS
  // --------------------------------------------------------
  static Future<List<DashboardSectionModel>> fetchSections() async {
    try {
      final data = await _client
          .from('dashboard_sections')
          .select('*')
          .order('sort_order', ascending: true);

      if (data != null && (data as List).isNotEmpty) {
        return (data as List).map((item) => DashboardSectionModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching dashboard_sections from Supabase: $e');
    }
    return _defaultSections();
  }

  static Future<bool> updateSectionVisibility(String sectionKey, bool isVisible) async {
    try {
      await _client
          .from('dashboard_sections')
          .update({'is_visible': isVisible, 'updated_at': DateTime.now().toIso8601String()})
          .eq('section_key', sectionKey);

      await logAuditEvent(
        action: 'UPDATE_VISIBILITY',
        entityType: 'SECTION',
        entityId: sectionKey,
        details: {'is_visible': isVisible},
      );
      return true;
    } catch (e) {
      debugPrint('Error updating section visibility: $e');
      return false;
    }
  }

  static Future<bool> updateSectionEnabled(String sectionKey, bool isEnabled) async {
    try {
      await _client
          .from('dashboard_sections')
          .update({'is_enabled': isEnabled, 'updated_at': DateTime.now().toIso8601String()})
          .eq('section_key', sectionKey);

      await logAuditEvent(
        action: 'TOGGLE_ENABLED',
        entityType: 'SECTION',
        entityId: sectionKey,
        details: {'is_enabled': isEnabled},
      );
      return true;
    } catch (e) {
      debugPrint('Error updating section enabled: $e');
      return false;
    }
  }

  static Future<bool> saveSectionOrders(List<DashboardSectionModel> sections) async {
    try {
      for (int i = 0; i < sections.length; i++) {
        final sec = sections[i];
        await _client
            .from('dashboard_sections')
            .update({'sort_order': i + 1, 'updated_at': DateTime.now().toIso8601String()})
            .eq('section_key', sec.sectionKey);
      }
      await logAuditEvent(
        action: 'REORDER_SECTIONS',
        entityType: 'SECTION_LAYOUT',
        entityId: 'global',
        details: {'order': sections.map((s) => s.sectionKey).toList()},
      );
      return true;
    } catch (e) {
      debugPrint('Error saving section orders: $e');
      return false;
    }
  }

  // --------------------------------------------------------
  // 2. DASHBOARD BANNERS
  // --------------------------------------------------------
  static Future<List<DashboardBannerModel>> fetchBanners() async {
    try {
      final data = await _client
          .from('dashboard_banners')
          .select('*')
          .order('sort_order', ascending: true);

      if (data != null && (data as List).isNotEmpty) {
        return (data as List).map((item) => DashboardBannerModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching dashboard_banners from Supabase: $e');
    }
    return _defaultBanners();
  }

  static Future<bool> saveBanner(DashboardBannerModel banner) async {
    try {
      final payload = banner.toJson();
      if (banner.id.isNotEmpty) {
        await _client.from('dashboard_banners').update(payload).eq('id', banner.id);
        await logAuditEvent(
          action: 'UPDATE_BANNER',
          entityType: 'BANNER',
          entityId: banner.id,
          details: {'title': banner.title, 'audience': banner.targetAudience},
        );
      } else {
        final res = await _client.from('dashboard_banners').insert(payload).select().single();
        await logAuditEvent(
          action: 'CREATE_BANNER',
          entityType: 'BANNER',
          entityId: res['id']?.toString() ?? '',
          details: {'title': banner.title, 'audience': banner.targetAudience},
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error saving banner: $e');
      return false;
    }
  }

  static Future<bool> deleteBanner(String bannerId) async {
    try {
      await _client.from('dashboard_banners').delete().eq('id', bannerId);
      await logAuditEvent(
        action: 'DELETE_BANNER',
        entityType: 'BANNER',
        entityId: bannerId,
        details: {},
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting banner: $e');
      return false;
    }
  }

  // --------------------------------------------------------
  // 3. QUICK STATS
  // --------------------------------------------------------
  static Future<List<DashboardQuickStatModel>> fetchQuickStats() async {
    try {
      final data = await _client
          .from('dashboard_quick_stats')
          .select('*')
          .order('sort_order', ascending: true);

      if (data != null && (data as List).isNotEmpty) {
        return (data as List).map((item) => DashboardQuickStatModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching dashboard_quick_stats: $e');
    }
    return _defaultQuickStats();
  }

  static Future<bool> saveQuickStat(DashboardQuickStatModel stat) async {
    try {
      final payload = stat.toJson();
      if (stat.id.isNotEmpty) {
        await _client.from('dashboard_quick_stats').update(payload).eq('id', stat.id);
        await logAuditEvent(
          action: 'UPDATE_STAT',
          entityType: 'QUICK_STAT',
          entityId: stat.id,
          details: {'title': stat.title, 'source': stat.dataSource},
        );
      } else {
        final res = await _client.from('dashboard_quick_stats').insert(payload).select().single();
        await logAuditEvent(
          action: 'CREATE_STAT',
          entityType: 'QUICK_STAT',
          entityId: res['id']?.toString() ?? '',
          details: {'title': stat.title, 'source': stat.dataSource},
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error saving quick stat: $e');
      return false;
    }
  }

  static Future<bool> deleteQuickStat(String statId) async {
    try {
      await _client.from('dashboard_quick_stats').delete().eq('id', statId);
      await logAuditEvent(
        action: 'DELETE_STAT',
        entityType: 'QUICK_STAT',
        entityId: statId,
        details: {},
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting quick stat: $e');
      return false;
    }
  }

  // --------------------------------------------------------
  // 4. QUICK ACTIONS
  // --------------------------------------------------------
  static Future<List<DashboardQuickActionModel>> fetchQuickActions() async {
    try {
      final data = await _client
          .from('dashboard_quick_actions')
          .select('*')
          .order('sort_order', ascending: true);

      if (data != null && (data as List).isNotEmpty) {
        return (data as List).map((item) => DashboardQuickActionModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching dashboard_quick_actions: $e');
    }
    return _defaultQuickActions();
  }

  static Future<bool> saveQuickAction(DashboardQuickActionModel action) async {
    try {
      final payload = action.toJson();
      if (action.id.isNotEmpty) {
        await _client.from('dashboard_quick_actions').update(payload).eq('id', action.id);
        await logAuditEvent(
          action: 'UPDATE_ACTION',
          entityType: 'QUICK_ACTION',
          entityId: action.id,
          details: {'title': action.title, 'destination': action.destination},
        );
      } else {
        final res = await _client.from('dashboard_quick_actions').insert(payload).select().single();
        await logAuditEvent(
          action: 'CREATE_ACTION',
          entityType: 'QUICK_ACTION',
          entityId: res['id']?.toString() ?? '',
          details: {'title': action.title, 'destination': action.destination},
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error saving quick action: $e');
      return false;
    }
  }

  static Future<bool> deleteQuickAction(String actionId) async {
    try {
      await _client.from('dashboard_quick_actions').delete().eq('id', actionId);
      await logAuditEvent(
        action: 'DELETE_ACTION',
        entityType: 'QUICK_ACTION',
        entityId: actionId,
        details: {},
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting quick action: $e');
      return false;
    }
  }

  // --------------------------------------------------------
  // 5. AUDIT LOGS
  // --------------------------------------------------------
  static Future<List<AuditLogModel>> fetchAuditLogs() async {
    try {
      final data = await _client
          .from('audit_logs')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);

      if (data != null && (data as List).isNotEmpty) {
        return (data as List).map((item) => AuditLogModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
    }
    return [];
  }

  static Future<void> logAuditEvent({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _client.auth.currentUser;
      await _client.from('audit_logs').insert({
        'user_id': user?.id,
        'user_email': user?.email ?? 'Dr. Sharma (Admin)',
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId ?? '',
        'details': details ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error recording audit log: $e');
    }
  }

  // --------------------------------------------------------
  // DEFAULT FALLBACK SEED DATA (Used when offline)
  // --------------------------------------------------------
  static List<DashboardSectionModel> _defaultSections() {
    return [
      DashboardSectionModel(id: '1', sectionKey: 'banner_slider', title: 'Banner Slider', subtitle: 'Manage promotional banners that appear at the top of the dashboard', sortOrder: 1, isEnabled: true, isVisible: true),
      DashboardSectionModel(id: '2', sectionKey: 'quick_stats', title: 'Quick Stats', subtitle: 'Manage the statistics cards shown below the banner', sortOrder: 2, isEnabled: true, isVisible: true),
      DashboardSectionModel(id: '3', sectionKey: 'continue_section', title: 'Continue Section', subtitle: 'Show in-progress tests and revision queues', sortOrder: 3, isEnabled: true, isVisible: true),
      DashboardSectionModel(id: '4', sectionKey: 'quick_actions', title: 'Quick Actions', subtitle: 'Manage quick action buttons for easy navigation', sortOrder: 4, isEnabled: true, isVisible: true),
      DashboardSectionModel(id: '5', sectionKey: 'performance_overview', title: 'Performance Overview', subtitle: 'Student overall score trends and percentile', sortOrder: 5, isEnabled: true, isVisible: true),
      DashboardSectionModel(id: '6', sectionKey: 'subject_strength', title: 'Subject Strength', subtitle: 'Physics, Chemistry, and Biology accuracy stats', sortOrder: 6, isEnabled: true, isVisible: true),
      DashboardSectionModel(id: '7', sectionKey: 'leaderboard_preview', title: 'Leaderboard Preview', subtitle: 'Rankings based on points and marks', sortOrder: 7, isEnabled: true, isVisible: true),
      DashboardSectionModel(id: '8', sectionKey: 'recent_tests', title: 'Recent Tests', subtitle: 'Recent student test attempts and practice sessions', sortOrder: 8, isEnabled: true, isVisible: true),
    ];
  }

  static List<DashboardBannerModel> _defaultBanners() {
    return [
      DashboardBannerModel(id: '1', title: 'NEET 2026\nMega Scholarship\nTest Series', subtitle: 'Get up to 50% OFF', ctaText: 'Subscribe Now', ctaDestination: '/test-series', bgColor: '#5B21B6', btnColor: '#FACC15', btnTextColor: '#1E1B4B', iconName: 'school', isActive: true, sortOrder: 1, targetAudience: 'NEET'),
      DashboardBannerModel(id: '2', title: 'Unlimited Practice\nUnlimited Tests', subtitle: 'One Subscription.\nAll Access.', ctaText: 'View Plans', ctaDestination: '/pricing', bgColor: '#047857', btnColor: '#FACC15', btnTextColor: '#064E3B', iconName: 'assignment', isActive: true, sortOrder: 2, targetAudience: 'All Students'),
      DashboardBannerModel(id: '3', title: 'PYQ Practice\nBoost Your Score', subtitle: 'Practice past years papers chapter-wise & topic-wise.', ctaText: 'Start Practicing', ctaDestination: '/pyq', bgColor: '#1E40AF', btnColor: '#FFFFFF', btnTextColor: '#1E40AF', iconName: 'menu_book', isActive: true, sortOrder: 3, targetAudience: 'All Students'),
      DashboardBannerModel(id: '4', title: 'Refer & Earn\nInvite Friends\nEarn Premium', subtitle: 'Earn exciting rewards by referring your friends.', ctaText: 'Know More', ctaDestination: '/profile', bgColor: '#C2410C', btnColor: '#FFFFFF', btnTextColor: '#9A3412', iconName: 'card_giftcard', isActive: true, sortOrder: 4, targetAudience: 'All Students'),
    ];
  }

  static List<DashboardQuickStatModel> _defaultQuickStats() {
    return [
      DashboardQuickStatModel(id: '1', statKey: 'questions_attempted', title: 'Questions Attempted', iconName: 'school', dataSource: 'user_stats.questions_attempted', changeText: '↑ 18%', status: 'Active', sortOrder: 1, isEnabled: true),
      DashboardQuickStatModel(id: '2', statKey: 'accuracy', title: 'Accuracy', iconName: 'target', dataSource: 'user_stats.accuracy', changeText: '↑ 6.3%', status: 'Active', sortOrder: 2, isEnabled: true),
      DashboardQuickStatModel(id: '3', statKey: 'tests_completed', title: 'Tests Completed', iconName: 'assignment', dataSource: 'user_stats.tests_completed', changeText: '↑ 4', status: 'Active', sortOrder: 3, isEnabled: true),
      DashboardQuickStatModel(id: '4', statKey: 'study_streak', title: 'Study Streak', iconName: 'flame', dataSource: 'user_stats.study_streak', changeText: 'Best: 32 Days', status: 'Active', sortOrder: 4, isEnabled: true),
    ];
  }

  static List<DashboardQuickActionModel> _defaultQuickActions() {
    return [
      DashboardQuickActionModel(id: '1', actionKey: 'custom_practice', title: 'Custom Practice', description: 'Practice chapter-wise questions with instant solution drawers', iconName: 'target', navType: 'route', destination: '/practice', isEnabled: true, sortOrder: 1, targetExam: 'All'),
      DashboardQuickActionModel(id: '2', actionKey: 'custom_test', title: 'Custom Test', description: 'Timed exam simulation with palette navigator and server scoring', iconName: 'assignment', navType: 'route', destination: '/test', isEnabled: true, sortOrder: 2, targetExam: 'All'),
      DashboardQuickActionModel(id: '3', actionKey: 'pyq_practice', title: 'PYQ Practice', description: 'Previous Year Questions from 2020-2025 with KaTeX solutions', iconName: 'menu_book', navType: 'route', destination: '/pyq', isEnabled: true, sortOrder: 3, targetExam: 'All'),
      DashboardQuickActionModel(id: '4', actionKey: 'nta_questions', title: 'NTA Questions', description: 'Dedicated NTA Abhyas official question sets', iconName: 'help', navType: 'route', destination: '/nta', isEnabled: true, sortOrder: 4, targetExam: 'All'),
      DashboardQuickActionModel(id: '5', actionKey: 'test_series', title: 'Test Series', description: 'All-India Grand Mock Test Series for NEET & JEE', iconName: 'card_giftcard', navType: 'route', destination: '/test-series', isEnabled: true, sortOrder: 5, targetExam: 'All'),
    ];
  }
}
