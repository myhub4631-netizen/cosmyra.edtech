-- ========================================================
-- COSMYRA PLATFORM - ADMIN DASHBOARD CMS & SECTIONS SCHEMA
-- Migration: 08_dashboard_cms_schema.sql
-- ========================================================

-- Enable required extensions if missing
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. DASHBOARD SECTIONS CONFIGURATION TABLE
CREATE TABLE IF NOT EXISTS public.dashboard_sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  section_key TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  subtitle TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  is_visible BOOLEAN NOT NULL DEFAULT true,
  config_json JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. DASHBOARD BANNERS TABLE
CREATE TABLE IF NOT EXISTS public.dashboard_banners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  subtitle TEXT,
  cta_text TEXT DEFAULT 'Subscribe Now',
  cta_destination TEXT DEFAULT '/practice',
  image_url TEXT,
  bg_color TEXT DEFAULT '#5B21B6',
  btn_color TEXT DEFAULT '#FACC15',
  btn_text_color TEXT DEFAULT '#1E1B4B',
  icon_name TEXT DEFAULT 'school',
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ,
  target_audience TEXT DEFAULT 'All Students',
  priority INT DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. QUICK STATS CONFIGURATION TABLE
CREATE TABLE IF NOT EXISTS public.dashboard_quick_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  stat_key TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  icon_name TEXT DEFAULT 'bar_chart',
  data_source TEXT NOT NULL,
  change_text TEXT,
  status TEXT DEFAULT 'Active',
  sort_order INT NOT NULL DEFAULT 0,
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. QUICK ACTIONS CONFIGURATION TABLE
CREATE TABLE IF NOT EXISTS public.dashboard_quick_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  action_key TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  icon_name TEXT DEFAULT 'assignment',
  nav_type TEXT DEFAULT 'route',
  destination TEXT NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  target_exam TEXT DEFAULT 'All',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  user_email TEXT,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES FOR SPEED AND QUERY OPTIMIZATION
CREATE INDEX IF NOT EXISTS idx_dashboard_sections_sort ON public.dashboard_sections (sort_order ASC);
CREATE INDEX IF NOT EXISTS idx_dashboard_banners_active ON public.dashboard_banners (is_active, sort_order ASC);
CREATE INDEX IF NOT EXISTS idx_dashboard_quick_stats_sort ON public.dashboard_quick_stats (sort_order ASC);
CREATE INDEX IF NOT EXISTS idx_dashboard_quick_actions_sort ON public.dashboard_quick_actions (sort_order ASC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs (created_at DESC);

-- SEED DEFAULT SECTIONS (8 Standard Sections)
INSERT INTO public.dashboard_sections (section_key, title, subtitle, sort_order, is_enabled, is_visible)
VALUES
  ('banner_slider', 'Banner Slider', 'Manage promotional banners that appear at the top of the dashboard', 1, true, true),
  ('quick_stats', 'Quick Stats', 'Manage the statistics cards shown below the banner', 2, true, true),
  ('continue_section', 'Continue Section', 'Show in-progress tests and revision queues', 3, true, true),
  ('quick_actions', 'Quick Actions', 'Manage quick action buttons for easy navigation', 4, true, true),
  ('performance_overview', 'Performance Overview', 'Student overall score trends and percentile', 5, true, true),
  ('subject_strength', 'Subject Strength', 'Physics, Chemistry, and Biology accuracy stats', 6, true, true),
  ('leaderboard_preview', 'Leaderboard Preview', 'Rankings based on points and marks', 7, true, true),
  ('recent_tests', 'Recent Tests', 'Recent student test attempts and practice sessions', 8, true, true)
ON CONFLICT (section_key) DO UPDATE SET
  title = EXCLUDED.title,
  subtitle = EXCLUDED.subtitle,
  sort_order = EXCLUDED.sort_order;

-- SEED DEFAULT BANNERS
INSERT INTO public.dashboard_banners (title, subtitle, cta_text, cta_destination, bg_color, btn_color, btn_text_color, icon_name, is_active, sort_order, target_audience)
VALUES
  ('NEET 2026 Mega Scholarship Test Series', 'Get up to 50% OFF', 'Subscribe Now', '/test-series', '#5B21B6', '#FACC15', '#1E1B4B', 'school', true, 1, 'NEET'),
  ('Unlimited Practice & Unlimited Tests', 'One Subscription. All Access.', 'View Plans', '/pricing', '#047857', '#FACC15', '#064E3B', 'assignment', true, 2, 'All Students'),
  ('PYQ Practice Boost Your Score', 'Practice past years papers chapter-wise & topic-wise.', 'Start Practicing', '/pyq', '#1E40AF', '#FFFFFF', '#1E40AF', 'menu_book', true, 3, 'All Students'),
  ('Refer & Earn Invite Friends Earn Premium', 'Earn exciting rewards by referring your friends.', 'Know More', '/profile', '#C2410C', '#FFFFFF', '#9A3412', 'card_giftcard', true, 4, 'All Students')
ON CONFLICT DO NOTHING;

-- SEED DEFAULT QUICK STATS
INSERT INTO public.dashboard_quick_stats (stat_key, title, icon_name, data_source, change_text, status, sort_order, is_enabled)
VALUES
  ('questions_attempted', 'Questions Attempted', 'school', 'user_stats.questions_attempted', '↑ 18%', 'Active', 1, true),
  ('accuracy', 'Accuracy', 'target', 'user_stats.accuracy', '↑ 6.3%', 'Active', 2, true),
  ('tests_completed', 'Tests Completed', 'assignment', 'user_stats.tests_completed', '↑ 4', 'Active', 3, true),
  ('study_streak', 'Study Streak', 'flame', 'user_stats.study_streak', 'Best: 32 Days', 'Active', 4, true)
ON CONFLICT (stat_key) DO UPDATE SET
  title = EXCLUDED.title,
  data_source = EXCLUDED.data_source,
  change_text = EXCLUDED.change_text;

-- SEED DEFAULT QUICK ACTIONS
INSERT INTO public.dashboard_quick_actions (action_key, title, description, icon_name, nav_type, destination, is_enabled, sort_order, target_exam)
VALUES
  ('custom_practice', 'Custom Practice', 'Practice chapter-wise questions with instant solution drawers', 'target', 'route', '/practice', true, 1, 'All'),
  ('custom_test', 'Custom Test', 'Timed exam simulation with palette navigator and server scoring', 'assignment', 'route', '/test', true, 2, 'All'),
  ('pyq_practice', 'PYQ Practice', 'Previous Year Questions from 2020-2025 with KaTeX solutions', 'menu_book', 'route', '/pyq', true, 3, 'All'),
  ('nta_questions', 'NTA Questions', 'Dedicated NTA Abhyas official question sets', 'help', 'route', '/nta', true, 4, 'All'),
  ('test_series', 'Test Series', 'All-India Grand Mock Test Series for NEET & JEE', 'card_giftcard', 'route', '/test-series', true, 5, 'All')
ON CONFLICT (action_key) DO UPDATE SET
  title = EXCLUDED.title,
  destination = EXCLUDED.destination;

-- ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.dashboard_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_quick_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_quick_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Read policies (Students & Public)
DROP POLICY IF EXISTS "Public Read Dashboard Sections" ON public.dashboard_sections;
CREATE POLICY "Public Read Dashboard Sections" ON public.dashboard_sections FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Dashboard Banners" ON public.dashboard_banners;
CREATE POLICY "Public Read Dashboard Banners" ON public.dashboard_banners FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Dashboard Quick Stats" ON public.dashboard_quick_stats;
CREATE POLICY "Public Read Dashboard Quick Stats" ON public.dashboard_quick_stats FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Dashboard Quick Actions" ON public.dashboard_quick_actions;
CREATE POLICY "Public Read Dashboard Quick Actions" ON public.dashboard_quick_actions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin Read Audit Logs" ON public.audit_logs;
CREATE POLICY "Admin Read Audit Logs" ON public.audit_logs FOR SELECT USING (true);

-- Admin CRUD Policies
DROP POLICY IF EXISTS "Admin All Dashboard Sections" ON public.dashboard_sections;
CREATE POLICY "Admin All Dashboard Sections" ON public.dashboard_sections FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin All Dashboard Banners" ON public.dashboard_banners;
CREATE POLICY "Admin All Dashboard Banners" ON public.dashboard_banners FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin All Dashboard Quick Stats" ON public.dashboard_quick_stats;
CREATE POLICY "Admin All Dashboard Quick Stats" ON public.dashboard_quick_stats FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin All Dashboard Quick Actions" ON public.dashboard_quick_actions;
CREATE POLICY "Admin All Dashboard Quick Actions" ON public.dashboard_quick_actions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin Insert Audit Logs" ON public.audit_logs;
CREATE POLICY "Admin Insert Audit Logs" ON public.audit_logs FOR INSERT WITH CHECK (true);

-- 5. STORAGE BUCKET FOR DASHBOARD ASSETS
INSERT INTO storage.buckets (id, name, public)
VALUES ('dashboard-assets', 'dashboard-assets', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage Policies
DROP POLICY IF EXISTS "Public Read Dashboard Assets" ON storage.objects;
CREATE POLICY "Public Read Dashboard Assets" ON storage.objects
  FOR SELECT USING (bucket_id = 'dashboard-assets');

DROP POLICY IF EXISTS "Admin Upload Dashboard Assets" ON storage.objects;
CREATE POLICY "Admin Upload Dashboard Assets" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'dashboard-assets');

DROP POLICY IF EXISTS "Admin Delete Dashboard Assets" ON storage.objects;
CREATE POLICY "Admin Delete Dashboard Assets" ON storage.objects
  FOR DELETE USING (bucket_id = 'dashboard-assets');
