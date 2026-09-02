import { supabase } from '../lib/supabase';
import { isSupabaseConfigured } from './apiService';
import {
  DashboardSection,
  DashboardBanner,
  DashboardQuickStat,
  DashboardQuickAction,
  AuditLogEntry,
} from '../types/dashboardCms';

// DEFAULT FALLBACK DATA (Offline mode)
const DEFAULT_SECTIONS: DashboardSection[] = [
  { id: '1', section_key: 'banner_slider', title: 'Banner Slider', subtitle: 'Manage promotional banners that appear at the top of the dashboard', sort_order: 1, is_enabled: true, is_visible: true },
  { id: '2', section_key: 'quick_stats', title: 'Quick Stats', subtitle: 'Manage the statistics cards shown below the banner', sort_order: 2, is_enabled: true, is_visible: true },
  { id: '3', section_key: 'continue_section', title: 'Continue Section', subtitle: 'Show in-progress tests and revision queues', sort_order: 3, is_enabled: true, is_visible: true },
  { id: '4', section_key: 'quick_actions', title: 'Quick Actions', subtitle: 'Manage quick action buttons for easy navigation', sort_order: 4, is_enabled: true, is_visible: true },
  { id: '5', section_key: 'performance_overview', title: 'Performance Overview', subtitle: 'Student overall score trends and percentile', sort_order: 5, is_enabled: true, is_visible: true },
  { id: '6', section_key: 'subject_strength', title: 'Subject Strength', subtitle: 'Physics, Chemistry, and Biology accuracy stats', sort_order: 6, is_enabled: true, is_visible: true },
  { id: '7', section_key: 'leaderboard_preview', title: 'Leaderboard Preview', subtitle: 'Rankings based on points and marks', sort_order: 7, is_enabled: true, is_visible: true },
  { id: '8', section_key: 'recent_tests', title: 'Recent Tests', subtitle: 'Recent student test attempts and practice sessions', sort_order: 8, is_enabled: true, is_visible: true },
];

const DEFAULT_BANNERS: DashboardBanner[] = [
  { id: '1', title: 'NEET 2026\nMega Scholarship\nTest Series', subtitle: 'Get up to 50% OFF', cta_text: 'Subscribe Now', cta_destination: '/test-series', bg_color: '#5B21B6', btn_color: '#FACC15', btn_text_color: '#1E1B4B', icon_name: 'school', is_active: true, sort_order: 1, target_audience: 'NEET', priority: 1 },
  { id: '2', title: 'Unlimited Practice\nUnlimited Tests', subtitle: 'One Subscription.\nAll Access.', cta_text: 'View Plans', cta_destination: '/pricing', bg_color: '#047857', btn_color: '#FACC15', btn_text_color: '#064E3B', icon_name: 'assignment', is_active: true, sort_order: 2, target_audience: 'All Students', priority: 1 },
  { id: '3', title: 'PYQ Practice\nBoost Your Score', subtitle: 'Practice past years papers chapter-wise & topic-wise.', cta_text: 'Start Practicing', cta_destination: '/pyq', bg_color: '#1E40AF', btn_color: '#FFFFFF', btn_text_color: '#1E40AF', icon_name: 'menu_book', is_active: true, sort_order: 3, target_audience: 'All Students', priority: 1 },
  { id: '4', title: 'Refer & Earn\nInvite Friends\nEarn Premium', subtitle: 'Earn exciting rewards by referring your friends.', cta_text: 'Know More', cta_destination: '/profile', bg_color: '#C2410C', btn_color: '#FFFFFF', btn_text_color: '#9A3412', icon_name: 'card_giftcard', is_active: true, sort_order: 4, target_audience: 'All Students', priority: 1 },
];

const DEFAULT_STATS: DashboardQuickStat[] = [
  { id: '1', stat_key: 'questions_attempted', title: 'Questions Attempted', icon_name: 'school', data_source: 'user_stats.questions_attempted', change_text: '↑ 18%', status: 'Active', sort_order: 1, is_enabled: true },
  { id: '2', stat_key: 'accuracy', title: 'Accuracy', icon_name: 'target', data_source: 'user_stats.accuracy', change_text: '↑ 6.3%', status: 'Active', sort_order: 2, is_enabled: true },
  { id: '3', stat_key: 'tests_completed', title: 'Tests Completed', icon_name: 'assignment', data_source: 'user_stats.tests_completed', change_text: '↑ 4', status: 'Active', sort_order: 3, is_enabled: true },
  { id: '4', stat_key: 'study_streak', title: 'Study Streak', icon_name: 'flame', data_source: 'user_stats.study_streak', change_text: 'Best: 32 Days', status: 'Active', sort_order: 4, is_enabled: true },
];

const DEFAULT_ACTIONS: DashboardQuickAction[] = [
  { id: '1', action_key: 'custom_practice', title: 'Custom Practice', description: 'Practice chapter-wise questions', icon_name: 'target', nav_type: 'route', destination: '/practice', is_enabled: true, sort_order: 1, target_exam: 'All' },
  { id: '2', action_key: 'custom_test', title: 'Custom Test', description: 'Timed exam simulation', icon_name: 'assignment', nav_type: 'route', destination: '/test', is_enabled: true, sort_order: 2, target_exam: 'All' },
  { id: '3', action_key: 'pyq_practice', title: 'PYQ Practice', description: 'Previous Year Questions 2020-2025', icon_name: 'menu_book', nav_type: 'route', destination: '/pyq', is_enabled: true, sort_order: 3, target_exam: 'All' },
  { id: '4', action_key: 'nta_questions', title: 'NTA Questions', description: 'Official NTA question sets', icon_name: 'help', nav_type: 'route', destination: '/nta', is_enabled: true, sort_order: 4, target_exam: 'All' },
];

// SERVICE FUNCTIONS
export const fetchDashboardSections = async (): Promise<DashboardSection[]> => {
  if (!isSupabaseConfigured()) return DEFAULT_SECTIONS;
  try {
    const { data, error } = await supabase
      .from('dashboard_sections')
      .select('*')
      .order('sort_order', { ascending: true });

    if (error || !data || data.length === 0) return DEFAULT_SECTIONS;
    return data as DashboardSection[];
  } catch (err) {
    console.warn('Supabase fetchDashboardSections error, using fallback:', err);
    return DEFAULT_SECTIONS;
  }
};

export const updateSectionVisibility = async (sectionKey: string, isVisible: boolean): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    const { error } = await supabase
      .from('dashboard_sections')
      .update({ is_visible: isVisible, updated_at: new Date().toISOString() })
      .eq('section_key', sectionKey);

    if (!error) {
      await logAuditEvent('UPDATE_VISIBILITY', 'SECTION', sectionKey, { is_visible: isVisible });
      return true;
    }
    return false;
  } catch (err) {
    console.error('Error updating section visibility:', err);
    return false;
  }
};

export const updateSectionEnabled = async (sectionKey: string, isEnabled: boolean): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    const { error } = await supabase
      .from('dashboard_sections')
      .update({ is_enabled: isEnabled, updated_at: new Date().toISOString() })
      .eq('section_key', sectionKey);

    if (!error) {
      await logAuditEvent('TOGGLE_ENABLED', 'SECTION', sectionKey, { is_enabled: isEnabled });
      return true;
    }
    return false;
  } catch (err) {
    console.error('Error updating section enabled:', err);
    return false;
  }
};

export const updateSectionOrders = async (sections: DashboardSection[]): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    for (let i = 0; i < sections.length; i++) {
      await supabase
        .from('dashboard_sections')
        .update({ sort_order: i + 1, updated_at: new Date().toISOString() })
        .eq('section_key', sections[i].section_key);
    }
    await logAuditEvent('REORDER_SECTIONS', 'SECTION_LAYOUT', 'global', { count: sections.length });
    return true;
  } catch (err) {
    return false;
  }
};

export const fetchBanners = async (): Promise<DashboardBanner[]> => {
  if (!isSupabaseConfigured()) return DEFAULT_BANNERS;
  try {
    const { data, error } = await supabase
      .from('dashboard_banners')
      .select('*')
      .order('sort_order', { ascending: true });

    if (error || !data || data.length === 0) return DEFAULT_BANNERS;
    return data as DashboardBanner[];
  } catch (err) {
    return DEFAULT_BANNERS;
  }
};

export const saveBanner = async (banner: Partial<DashboardBanner>): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    if (banner.id) {
      const { error } = await supabase.from('dashboard_banners').update(banner).eq('id', banner.id);
      if (!error) {
        await logAuditEvent('UPDATE_BANNER', 'BANNER', banner.id, { title: banner.title });
        return true;
      }
    } else {
      const { data, error } = await supabase.from('dashboard_banners').insert(banner).select().single();
      if (!error && data) {
        await logAuditEvent('CREATE_BANNER', 'BANNER', data.id, { title: banner.title });
        return true;
      }
    }
    return false;
  } catch (err) {
    return false;
  }
};

export const deleteBanner = async (bannerId: string): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    const { error } = await supabase.from('dashboard_banners').delete().eq('id', bannerId);
    if (!error) {
      await logAuditEvent('DELETE_BANNER', 'BANNER', bannerId, {});
      return true;
    }
    return false;
  } catch (err) {
    return false;
  }
};

export const updateBannerOrders = async (banners: DashboardBanner[]): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    for (let i = 0; i < banners.length; i++) {
      await supabase.from('dashboard_banners').update({ sort_order: i + 1 }).eq('id', banners[i].id);
    }
    await logAuditEvent('REORDER_BANNERS', 'BANNER', 'global', { count: banners.length });
    return true;
  } catch (err) {
    return false;
  }
};

export const fetchQuickStats = async (): Promise<DashboardQuickStat[]> => {
  if (!isSupabaseConfigured()) return DEFAULT_STATS;
  try {
    const { data, error } = await supabase.from('dashboard_quick_stats').select('*').order('sort_order', { ascending: true });
    if (error || !data || data.length === 0) return DEFAULT_STATS;
    return data as DashboardQuickStat[];
  } catch (err) {
    return DEFAULT_STATS;
  }
};

export const saveQuickStat = async (stat: Partial<DashboardQuickStat>): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    if (stat.id) {
      const { error } = await supabase.from('dashboard_quick_stats').update(stat).eq('id', stat.id);
      if (!error) {
        await logAuditEvent('UPDATE_STAT', 'QUICK_STAT', stat.id, { title: stat.title });
        return true;
      }
    } else {
      const { data, error } = await supabase.from('dashboard_quick_stats').insert(stat).select().single();
      if (!error && data) {
        await logAuditEvent('CREATE_STAT', 'QUICK_STAT', data.id, { title: stat.title });
        return true;
      }
    }
    return false;
  } catch (err) {
    return false;
  }
};

export const deleteQuickStat = async (statId: string): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    const { error } = await supabase.from('dashboard_quick_stats').delete().eq('id', statId);
    if (!error) {
      await logAuditEvent('DELETE_STAT', 'QUICK_STAT', statId, {});
      return true;
    }
    return false;
  } catch (err) {
    return false;
  }
};

export const fetchQuickActions = async (): Promise<DashboardQuickAction[]> => {
  if (!isSupabaseConfigured()) return DEFAULT_ACTIONS;
  try {
    const { data, error } = await supabase.from('dashboard_quick_actions').select('*').order('sort_order', { ascending: true });
    if (error || !data || data.length === 0) return DEFAULT_ACTIONS;
    return data as DashboardQuickAction[];
  } catch (err) {
    return DEFAULT_ACTIONS;
  }
};

export const saveQuickAction = async (action: Partial<DashboardQuickAction>): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    if (action.id) {
      const { error } = await supabase.from('dashboard_quick_actions').update(action).eq('id', action.id);
      if (!error) {
        await logAuditEvent('UPDATE_ACTION', 'QUICK_ACTION', action.id, { title: action.title });
        return true;
      }
    } else {
      const { data, error } = await supabase.from('dashboard_quick_actions').insert(action).select().single();
      if (!error && data) {
        await logAuditEvent('CREATE_ACTION', 'QUICK_ACTION', data.id, { title: action.title });
        return true;
      }
    }
    return false;
  } catch (err) {
    return false;
  }
};

export const deleteQuickAction = async (actionId: string): Promise<boolean> => {
  if (!isSupabaseConfigured()) return true;
  try {
    const { error } = await supabase.from('dashboard_quick_actions').delete().eq('id', actionId);
    if (!error) {
      await logAuditEvent('DELETE_ACTION', 'QUICK_ACTION', actionId, {});
      return true;
    }
    return false;
  } catch (err) {
    return false;
  }
};

export const fetchAuditLogs = async (): Promise<AuditLogEntry[]> => {
  if (!isSupabaseConfigured()) return [];
  try {
    const { data, error } = await supabase.from('audit_logs').select('*').order('created_at', { ascending: false }).limit(50);
    if (error || !data) return [];
    return data as AuditLogEntry[];
  } catch (err) {
    return [];
  }
};

export const logAuditEvent = async (action: string, entityType: string, entityId: string, details: Record<string, any>) => {
  if (!isSupabaseConfigured()) return;
  try {
    const { data: { user } } = await supabase.auth.getUser();
    await supabase.from('audit_logs').insert({
      user_id: user?.id,
      user_email: user?.email || 'Dr. Sharma (Admin)',
      action,
      entity_type: entityType,
      entity_id: entityId,
      details,
      created_at: new Date().toISOString(),
    });
  } catch (err) {
    console.error('Error logging audit event:', err);
  }
};
