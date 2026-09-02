import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../../models/models.dart';

class DashboardCmsService {
  static SupabaseClient get _client => SupabaseService.client;

  static bool isUUID(String? str) {
    if (str == null || str.isEmpty) return false;
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(str);
  }

  // --------------------------------------------------------
  // 1. DASHBOARD SECTIONS
  // --------------------------------------------------------
  static List<DashboardSectionModel> defaultSections() => [
        DashboardSectionModel(id: 'sec_1', sectionKey: 'banner_slider', title: 'Banner Slider', subtitle: 'Manage promotional banners that appear at the top of the dashboard', sortOrder: 1, isEnabled: true, isVisible: true),
        DashboardSectionModel(id: 'sec_2', sectionKey: 'quick_stats', title: 'Quick Stats', subtitle: 'Manage the statistics cards shown below the banner', sortOrder: 2, isEnabled: true, isVisible: true),
        DashboardSectionModel(id: 'sec_3', sectionKey: 'continue_section', title: 'Continue Section', subtitle: 'Show in-progress tests and revision queues', sortOrder: 3, isEnabled: true, isVisible: true),
        DashboardSectionModel(id: 'sec_4', sectionKey: 'quick_actions', title: 'Quick Actions', subtitle: 'Direct navigation buttons for practice and mock tests', sortOrder: 4, isEnabled: true, isVisible: true),
        DashboardSectionModel(id: 'sec_5', sectionKey: 'subject_progress', title: 'Subject Progress', subtitle: 'Visual progress breakdown across Physics, Chemistry, Biology & Math', sortOrder: 5, isEnabled: true, isVisible: true),
        DashboardSectionModel(id: 'sec_6', sectionKey: 'recommendations', title: 'AI Recommendations', subtitle: 'Smart recommendations based on student performance', sortOrder: 6, isEnabled: true, isVisible: true),
        DashboardSectionModel(id: 'sec_7', sectionKey: 'upcoming_tests', title: 'Upcoming Live Tests', subtitle: 'Scheduled live mock exams and all-India tests', sortOrder: 7, isEnabled: true, isVisible: true),
        DashboardSectionModel(id: 'sec_8', sectionKey: 'recent_activity', title: 'Recent Activity', subtitle: 'Latest student practice sessions and test logs', sortOrder: 8, isEnabled: true, isVisible: true),
      ];

  static Future<List<DashboardSectionModel>> fetchSections() async {
    try {
      final data = await _client
          .from('dashboard_sections')
          .select('*')
          .order('sort_order', ascending: true);

      if (data != null && (data as List).isNotEmpty) {
        return (data as List).map((item) => DashboardSectionModel.fromJson(item)).toList();
      }

      // Auto-seed default sections into database if empty
      final defaults = defaultSections();
      for (final sec in defaults) {
        await _client.from('dashboard_sections').upsert({
          'section_key': sec.sectionKey,
          'title': sec.title,
          'subtitle': sec.subtitle,
          'sort_order': sec.sortOrder,
          'is_enabled': sec.isEnabled,
          'is_visible': sec.isVisible,
        }, onConflict: 'section_key');
      }
      return defaults;
    } catch (e) {
      debugPrint('[DashboardCmsService.fetchSections Error]: $e');
    }
    return defaultSections();
  }

  static Future<bool> updateSectionVisibility(String sectionKey, bool isVisible) async {
    try {
      await _client.from('dashboard_sections').upsert({
        'section_key': sectionKey,
        'is_visible': isVisible,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'section_key');

      await logAuditEvent(
        action: 'UPDATE_VISIBILITY',
        entityType: 'SECTION',
        entityId: sectionKey,
        details: {'is_visible': isVisible},
      );
      return true;
    } catch (e) {
      debugPrint('[DashboardCmsService.updateSectionVisibility Error]: $e');
      return false;
    }
  }

  static Future<bool> updateSectionEnabled(String sectionKey, bool isEnabled) async {
    try {
      await _client.from('dashboard_sections').upsert({
        'section_key': sectionKey,
        'is_enabled': isEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'section_key');

      await logAuditEvent(
        action: 'TOGGLE_ENABLED',
        entityType: 'SECTION',
        entityId: sectionKey,
        details: {'is_enabled': isEnabled},
      );
      return true;
    } catch (e) {
      debugPrint('[DashboardCmsService.updateSectionEnabled Error]: $e');
      return false;
    }
  }

  static Future<bool> updateSectionOrders(List<DashboardSectionModel> sections) async {
    try {
      for (int i = 0; i < sections.length; i++) {
        await _client.from('dashboard_sections').upsert({
          'section_key': sections[i].sectionKey,
          'title': sections[i].title,
          'sort_order': i + 1,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'section_key');
      }
      return true;
    } catch (e) {
      debugPrint('[DashboardCmsService.updateSectionOrders Error]: $e');
      return false;
    }
  }

  static Future<bool> saveSectionOrders(List<DashboardSectionModel> sections) => updateSectionOrders(sections);

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
      debugPrint('[DashboardCmsService.fetchBanners Error]: $e');
    }
    return [];
  }

  static Future<DashboardBannerModel> saveBanner(DashboardBannerModel banner) async {
    final Map<String, dynamic> payload = {
      'title': banner.title.isNotEmpty ? banner.title : 'New Banner',
      'subtitle': banner.subtitle,
      'cta_text': banner.ctaText.isNotEmpty ? banner.ctaText : 'Subscribe Now',
      'cta_destination': banner.ctaDestination.isNotEmpty ? banner.ctaDestination : '/practice',
      'image_url': banner.imageUrl,
      'bg_color': banner.bgColor.isNotEmpty ? banner.bgColor : '#5B21B6',
      'btn_color': banner.btnColor.isNotEmpty ? banner.btnColor : '#FACC15',
      'btn_text_color': banner.btnTextColor.isNotEmpty ? banner.btnTextColor : '#1E1B4B',
      'icon_name': banner.iconName.isNotEmpty ? banner.iconName : 'school',
      'is_active': banner.isActive,
      'sort_order': banner.sortOrder,
      'target_audience': banner.targetAudience.isNotEmpty ? banner.targetAudience : 'All Students',
      'target_platform': banner.targetPlatform.isNotEmpty ? banner.targetPlatform : 'all',
      'priority': banner.priority,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (banner.id.isNotEmpty && isUUID(banner.id)) {
      // UPDATE
      final res = await _client
          .from('dashboard_banners')
          .update(payload)
          .eq('id', banner.id)
          .select()
          .single();

      await logAuditEvent(action: 'UPDATE_BANNER', entityType: 'BANNER', entityId: banner.id, details: {'title': banner.title});
      return DashboardBannerModel.fromJson(res);
    } else {
      // INSERT
      final res = await _client
          .from('dashboard_banners')
          .insert(payload)
          .select()
          .single();

      final created = DashboardBannerModel.fromJson(res);
      await logAuditEvent(action: 'CREATE_BANNER', entityType: 'BANNER', entityId: created.id, details: {'title': banner.title});
      return created;
    }
  }

  static Future<bool> deleteBanner(String bannerId) async {
    if (!isUUID(bannerId)) return true;

    try {
      final res = await _client.from('dashboard_banners').select('image_url').eq('id', bannerId).single();
      final imgUrl = res['image_url'] as String?;
      if (imgUrl != null && imgUrl.contains('dashboard-assets/banners/')) {
        final parts = imgUrl.split('dashboard-assets/');
        if (parts.length > 1) {
          await _client.storage.from('dashboard-assets').remove([parts[1]]);
        }
      }
    } catch (_) {}

    await _client.from('dashboard_banners').delete().eq('id', bannerId);
    await logAuditEvent(action: 'DELETE_BANNER', entityType: 'BANNER', entityId: bannerId, details: {});
    return true;
  }

  static Future<bool> updateBannerOrders(List<DashboardBannerModel> banners) async {
    try {
      for (int i = 0; i < banners.length; i++) {
        if (isUUID(banners[i].id)) {
          await _client
              .from('dashboard_banners')
              .update({'sort_order': i + 1, 'updated_at': DateTime.now().toIso8601String()})
              .eq('id', banners[i].id);
        }
      }
      return true;
    } catch (e) {
      debugPrint('[DashboardCmsService.updateBannerOrders Error]: $e');
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
      debugPrint('[DashboardCmsService.fetchQuickStats Error]: $e');
    }
    return [];
  }

  static Future<DashboardQuickStatModel> saveQuickStat(DashboardQuickStatModel stat) async {
    final baseKey = stat.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final statKey = stat.statKey.isNotEmpty && isUUID(stat.id) ? stat.statKey : '${baseKey}_${DateTime.now().millisecondsSinceEpoch}';

    final Map<String, dynamic> payload = {
      'stat_key': statKey,
      'title': stat.title.isNotEmpty ? stat.title : 'New Stat',
      'icon_name': stat.iconName.isNotEmpty ? stat.iconName : 'school',
      'data_source': stat.dataSource.isNotEmpty ? stat.dataSource : 'user_stats.questions_attempted',
      'change_text': stat.changeText,
      'status': stat.status.isNotEmpty ? stat.status : 'Active',
      'sort_order': stat.sortOrder,
      'is_enabled': stat.isEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (stat.id.isNotEmpty && isUUID(stat.id)) {
      final res = await _client
          .from('dashboard_quick_stats')
          .update(payload)
          .eq('id', stat.id)
          .select()
          .single();
      return DashboardQuickStatModel.fromJson(res);
    } else {
      final res = await _client
          .from('dashboard_quick_stats')
          .insert(payload)
          .select()
          .single();
      return DashboardQuickStatModel.fromJson(res);
    }
  }

  static Future<bool> deleteQuickStat(String statId) async {
    if (!isUUID(statId)) return true;
    await _client.from('dashboard_quick_stats').delete().eq('id', statId);
    return true;
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
      debugPrint('[DashboardCmsService.fetchQuickActions Error]: $e');
    }
    return [];
  }

  static Future<DashboardQuickActionModel> saveQuickAction(DashboardQuickActionModel action) async {
    final baseKey = action.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final actionKey = action.actionKey.isNotEmpty && isUUID(action.id) ? action.actionKey : '${baseKey}_${DateTime.now().millisecondsSinceEpoch}';

    final Map<String, dynamic> payload = {
      'action_key': actionKey,
      'title': action.title.isNotEmpty ? action.title : 'New Action',
      'description': action.description,
      'icon_name': action.iconName.isNotEmpty ? action.iconName : 'target',
      'nav_type': action.navType.isNotEmpty ? action.navType : 'route',
      'destination': action.destination.isNotEmpty ? action.destination : '/practice',
      'is_enabled': action.isEnabled,
      'sort_order': action.sortOrder,
      'target_exam': action.targetExam.isNotEmpty ? action.targetExam : 'All',
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (action.id.isNotEmpty && isUUID(action.id)) {
      final res = await _client
          .from('dashboard_quick_actions')
          .update(payload)
          .eq('id', action.id)
          .select()
          .single();
      return DashboardQuickActionModel.fromJson(res);
    } else {
      final res = await _client
          .from('dashboard_quick_actions')
          .insert(payload)
          .select()
          .single();
      return DashboardQuickActionModel.fromJson(res);
    }
  }

  static Future<bool> deleteQuickAction(String actionId) async {
    if (!isUUID(actionId)) return true;
    await _client.from('dashboard_quick_actions').delete().eq('id', actionId);
    return true;
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
      debugPrint('[DashboardCmsService.fetchAuditLogs Error]: $e');
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
        'user_id': isUUID(user?.id) ? user?.id : null,
        'user_email': user?.email ?? 'Dr. Sharma (Admin)',
        'action': action,
        'entity_type': entityType,
        'entity_id': isUUID(entityId) ? entityId : null,
        'details': details ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[DashboardCmsService.logAuditEvent Error]: $e');
    }
  }
}
