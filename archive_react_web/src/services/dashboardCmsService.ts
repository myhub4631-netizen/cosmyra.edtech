import { supabase } from '../lib/supabase';
import {
  DashboardSection,
  DashboardBanner,
  DashboardQuickStat,
  DashboardQuickAction,
  AuditLogEntry,
} from '../types/dashboardCms';

export const isUUID = (str?: string): boolean =>
  !!str && /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(str);

// AUDIT LOG HELPER
export const logAuditEvent = async (
  action: string,
  entityType: string,
  entityId: string,
  details: any
) => {
  try {
    const { data: userData } = await supabase.auth.getUser();
    await supabase.from('audit_logs').insert({
      user_id: isUUID(userData.user?.id) ? userData.user?.id : null,
      user_email: userData.user?.email || 'Dr. Sharma (Admin)',
      action,
      entity_type: entityType,
      entity_id: isUUID(entityId) ? entityId : null,
      details,
    });
  } catch (err) {
    console.error('[CMS Audit Log Error]:', err);
  }
};

// 1. DASHBOARD SECTIONS
export const fetchDashboardSections = async (): Promise<DashboardSection[]> => {
  try {
    const { data, error } = await supabase
      .from('dashboard_sections')
      .select('*')
      .order('sort_order', { ascending: true });

    if (error) {
      console.error('[fetchDashboardSections Error]:', error.message);
      return [];
    }
    return (data as DashboardSection[]) || [];
  } catch (err: any) {
    console.error('[fetchDashboardSections Exception]:', err.message || err);
    return [];
  }
};

export const updateSectionVisibility = async (sectionKey: string, isVisible: boolean): Promise<boolean> => {
  try {
    const { error } = await supabase
      .from('dashboard_sections')
      .update({ is_visible: isVisible, updated_at: new Date().toISOString() })
      .eq('section_key', sectionKey);

    if (error) {
      console.error('[updateSectionVisibility Error]:', error.message);
      return false;
    }
    await logAuditEvent('UPDATE_VISIBILITY', 'SECTION', sectionKey, { is_visible: isVisible });
    return true;
  } catch (err: any) {
    console.error('[updateSectionVisibility Exception]:', err.message || err);
    return false;
  }
};

export const updateSectionEnabled = async (sectionKey: string, isEnabled: boolean): Promise<boolean> => {
  try {
    const { error } = await supabase
      .from('dashboard_sections')
      .update({ is_enabled: isEnabled, updated_at: new Date().toISOString() })
      .eq('section_key', sectionKey);

    if (error) {
      console.error('[updateSectionEnabled Error]:', error.message);
      return false;
    }
    await logAuditEvent('TOGGLE_ENABLED', 'SECTION', sectionKey, { is_enabled: isEnabled });
    return true;
  } catch (err: any) {
    console.error('[updateSectionEnabled Exception]:', err.message || err);
    return false;
  }
};

export const updateSectionOrders = async (sections: DashboardSection[]): Promise<boolean> => {
  try {
    for (let i = 0; i < sections.length; i++) {
      const { error } = await supabase
        .from('dashboard_sections')
        .update({ sort_order: i + 1, updated_at: new Date().toISOString() })
        .eq('section_key', sections[i].section_key);
      if (error) console.error(`[updateSectionOrders Item Error (${sections[i].section_key})]:`, error.message);
    }
    return true;
  } catch (err: any) {
    console.error('[updateSectionOrders Exception]:', err.message || err);
    return false;
  }
};

// 2. DASHBOARD BANNERS CRUD & STORAGE
export const uploadBannerImage = async (file: File): Promise<string> => {
  const fileExt = file.name.split('.').pop();
  const fileName = `banner_${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
  const filePath = `banners/${fileName}`;

  const { error: uploadError } = await supabase.storage
    .from('dashboard-assets')
    .upload(filePath, file, { cacheControl: '3600', upsert: true });

  if (uploadError) {
    console.error('[uploadBannerImage Storage Error]:', uploadError.message);
    throw new Error(`Image Upload Failed: ${uploadError.message}`);
  }

  const { data } = supabase.storage.from('dashboard-assets').getPublicUrl(filePath);
  if (!data?.publicUrl) throw new Error('Could not retrieve public URL for uploaded banner image.');
  return data.publicUrl;
};

export const fetchBanners = async (): Promise<DashboardBanner[]> => {
  try {
    const { data, error } = await supabase
      .from('dashboard_banners')
      .select('*')
      .order('sort_order', { ascending: true });

    if (error) {
      console.error('[fetchBanners Error]:', error.message);
      return [];
    }
    return (data as DashboardBanner[]) || [];
  } catch (err: any) {
    console.error('[fetchBanners Exception]:', err.message || err);
    return [];
  }
};

export const saveBanner = async (banner: Partial<DashboardBanner>): Promise<DashboardBanner> => {
  const dbPayload: any = {
    title: banner.title || 'New Banner',
    subtitle: banner.subtitle || '',
    cta_text: banner.cta_text || 'Subscribe Now',
    cta_destination: banner.cta_destination || '/practice',
    image_url: banner.image_url || null,
    bg_color: banner.bg_color || '#5B21B6',
    btn_color: banner.btn_color || '#FACC15',
    btn_text_color: banner.btn_text_color || '#1E1B4B',
    icon_name: banner.icon_name || 'school',
    is_active: banner.is_active ?? true,
    sort_order: banner.sort_order || 1,
    target_audience: banner.target_audience || 'All Students',
    priority: banner.priority || 1,
    updated_at: new Date().toISOString(),
  };

  if (banner.id && isUUID(banner.id)) {
    // UPDATE
    const { data, error } = await supabase
      .from('dashboard_banners')
      .update(dbPayload)
      .eq('id', banner.id)
      .select()
      .single();

    if (error) {
      console.error('[saveBanner Update Error]:', error.message);
      throw new Error(error.message);
    }
    await logAuditEvent('UPDATE_BANNER', 'BANNER', banner.id, { title: banner.title });
    return data as DashboardBanner;
  } else {
    // INSERT
    const { data, error } = await supabase
      .from('dashboard_banners')
      .insert(dbPayload)
      .select()
      .single();

    if (error) {
      console.error('[saveBanner Insert Error]:', error.message);
      throw new Error(error.message);
    }
    await logAuditEvent('CREATE_BANNER', 'BANNER', data.id, { title: banner.title });
    return data as DashboardBanner;
  }
};

export const deleteBanner = async (bannerId: string): Promise<boolean> => {
  if (!isUUID(bannerId)) {
    console.warn(`[deleteBanner Warning]: Cannot delete non-UUID item ${bannerId}`);
    return true;
  }

  // Fetch to check image storage cleanup
  try {
    const { data: existing } = await supabase
      .from('dashboard_banners')
      .select('image_url')
      .eq('id', bannerId)
      .single();

    if (existing?.image_url && existing.image_url.includes('dashboard-assets/banners/')) {
      const parts = existing.image_url.split('dashboard-assets/');
      if (parts[1]) {
        await supabase.storage.from('dashboard-assets').remove([parts[1]]);
      }
    }
  } catch (err) {
    console.error('[deleteBanner Storage Removal Warning]:', err);
  }

  const { error } = await supabase.from('dashboard_banners').delete().eq('id', bannerId);
  if (error) {
    console.error('[deleteBanner Error]:', error.message);
    throw new Error(error.message);
  }
  await logAuditEvent('DELETE_BANNER', 'BANNER', bannerId, {});
  return true;
};

export const updateBannerOrders = async (banners: DashboardBanner[]): Promise<boolean> => {
  try {
    for (let i = 0; i < banners.length; i++) {
      if (isUUID(banners[i].id)) {
        const { error } = await supabase
          .from('dashboard_banners')
          .update({ sort_order: i + 1, updated_at: new Date().toISOString() })
          .eq('id', banners[i].id);
        if (error) console.error(`[updateBannerOrders Error (${banners[i].id})]:`, error.message);
      }
    }
    return true;
  } catch (err: any) {
    console.error('[updateBannerOrders Exception]:', err.message || err);
    return false;
  }
};

// 3. QUICK STATS CRUD
export const fetchQuickStats = async (): Promise<DashboardQuickStat[]> => {
  try {
    const { data, error } = await supabase
      .from('dashboard_quick_stats')
      .select('*')
      .order('sort_order', { ascending: true });

    if (error) {
      console.error('[fetchQuickStats Error]:', error.message);
      return [];
    }
    return (data as DashboardQuickStat[]) || [];
  } catch (err: any) {
    console.error('[fetchQuickStats Exception]:', err.message || err);
    return [];
  }
};

export const saveQuickStat = async (stat: Partial<DashboardQuickStat>): Promise<DashboardQuickStat> => {
  const baseKey = (stat.title || 'stat').toLowerCase().replaceAll(/[^a-z0-9]/g, '_');
  const statKey = stat.stat_key && isUUID(stat.id) ? stat.stat_key : `${baseKey}_${Date.now()}`;

  const dbPayload: any = {
    stat_key: statKey,
    title: stat.title || 'New Stat',
    icon_name: stat.icon_name || 'school',
    data_source: stat.data_source || 'user_stats.questions_attempted',
    change_text: stat.change_text || '↑ 10%',
    status: stat.status || 'Active',
    sort_order: stat.sort_order || 1,
    is_enabled: stat.is_enabled ?? true,
    updated_at: new Date().toISOString(),
  };

  if (stat.id && isUUID(stat.id)) {
    const { data, error } = await supabase
      .from('dashboard_quick_stats')
      .update(dbPayload)
      .eq('id', stat.id)
      .select()
      .single();

    if (error) {
      console.error('[saveQuickStat Update Error]:', error.message);
      throw new Error(error.message);
    }
    return data as DashboardQuickStat;
  } else {
    const { data, error } = await supabase
      .from('dashboard_quick_stats')
      .insert(dbPayload)
      .select()
      .single();

    if (error) {
      console.error('[saveQuickStat Insert Error]:', error.message);
      throw new Error(error.message);
    }
    return data as DashboardQuickStat;
  }
};

export const deleteQuickStat = async (statId: string): Promise<boolean> => {
  if (!isUUID(statId)) return true;
  const { error } = await supabase.from('dashboard_quick_stats').delete().eq('id', statId);
  if (error) {
    console.error('[deleteQuickStat Error]:', error.message);
    throw new Error(error.message);
  }
  return true;
};

// 4. QUICK ACTIONS CRUD
export const fetchQuickActions = async (): Promise<DashboardQuickAction[]> => {
  try {
    const { data, error } = await supabase
      .from('dashboard_quick_actions')
      .select('*')
      .order('sort_order', { ascending: true });

    if (error) {
      console.error('[fetchQuickActions Error]:', error.message);
      return [];
    }
    return (data as DashboardQuickAction[]) || [];
  } catch (err: any) {
    console.error('[fetchQuickActions Exception]:', err.message || err);
    return [];
  }
};

export const saveQuickAction = async (action: Partial<DashboardQuickAction>): Promise<DashboardQuickAction> => {
  const baseKey = (action.title || 'action').toLowerCase().replaceAll(/[^a-z0-9]/g, '_');
  const actionKey = action.action_key && isUUID(action.id) ? action.action_key : `${baseKey}_${Date.now()}`;

  const dbPayload: any = {
    action_key: actionKey,
    title: action.title || 'New Action',
    description: action.description || '',
    icon_name: action.icon_name || 'target',
    nav_type: action.nav_type || 'route',
    destination: action.destination || '/practice',
    is_enabled: action.is_enabled ?? true,
    sort_order: action.sort_order || 1,
    target_exam: action.target_exam || 'All',
    updated_at: new Date().toISOString(),
  };

  if (action.id && isUUID(action.id)) {
    const { data, error } = await supabase
      .from('dashboard_quick_actions')
      .update(dbPayload)
      .eq('id', action.id)
      .select()
      .single();

    if (error) {
      console.error('[saveQuickAction Update Error]:', error.message);
      throw new Error(error.message);
    }
    return data as DashboardQuickAction;
  } else {
    const { data, error } = await supabase
      .from('dashboard_quick_actions')
      .insert(dbPayload)
      .select()
      .single();

    if (error) {
      console.error('[saveQuickAction Insert Error]:', error.message);
      throw new Error(error.message);
    }
    return data as DashboardQuickAction;
  }
};

export const deleteQuickAction = async (actionId: string): Promise<boolean> => {
  if (!isUUID(actionId)) return true;
  const { error } = await supabase.from('dashboard_quick_actions').delete().eq('id', actionId);
  if (error) {
    console.error('[deleteQuickAction Error]:', error.message);
    throw new Error(error.message);
  }
  return true;
};

// 5. AUDIT LOGS
export const fetchAuditLogs = async (): Promise<AuditLogEntry[]> => {
  try {
    const { data, error } = await supabase
      .from('audit_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) {
      console.error('[fetchAuditLogs Error]:', error.message);
      return [];
    }
    return (data as AuditLogEntry[]) || [];
  } catch (err: any) {
    console.error('[fetchAuditLogs Exception]:', err.message || err);
    return [];
  }
};
