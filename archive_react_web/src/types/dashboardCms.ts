export interface DashboardSection {
  id: string;
  section_key: string;
  title: string;
  subtitle: string;
  sort_order: number;
  is_enabled: boolean;
  is_visible: boolean;
  config_json?: Record<string, any>;
  created_at?: string;
  updated_at?: string;
}

export interface DashboardBanner {
  id: string;
  title: string;
  subtitle: string;
  cta_text: string;
  cta_destination: string;
  image_url?: string;
  bg_color: string;
  btn_color: string;
  btn_text_color: string;
  icon_name: string;
  is_active: boolean;
  sort_order: number;
  start_at?: string;
  end_at?: string;
  target_audience: string;
  priority: number;
  created_at?: string;
  updated_at?: string;
}

export interface DashboardQuickStat {
  id: string;
  stat_key: string;
  title: string;
  icon_name: string;
  data_source: string;
  change_text: string;
  status: string;
  sort_order: number;
  is_enabled: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface DashboardQuickAction {
  id: string;
  action_key: string;
  title: string;
  description: string;
  icon_name: string;
  nav_type: string;
  destination: string;
  is_enabled: boolean;
  sort_order: number;
  target_exam: string;
  created_at?: string;
  updated_at?: string;
}

export interface AuditLogEntry {
  id: string;
  user_id?: string;
  user_email: string;
  action: string;
  entity_type: string;
  entity_id: string;
  details: Record<string, any>;
  created_at: string;
}
