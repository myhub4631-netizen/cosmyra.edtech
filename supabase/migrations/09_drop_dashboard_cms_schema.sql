-- ========================================================
-- MIGRATION: 09_drop_dashboard_cms_schema.sql
-- DESCRIPTION: Permanently remove Dashboard Layout Management tables & policies
-- ========================================================

-- Drop triggers if any
DROP TRIGGER IF EXISTS trigger_dashboard_sections_updated_at ON public.dashboard_sections;
DROP TRIGGER IF EXISTS trigger_dashboard_banners_updated_at ON public.dashboard_banners;

-- Drop RLS policies
DROP POLICY IF EXISTS "Public read access to dashboard_sections" ON public.dashboard_sections;
DROP POLICY IF EXISTS "Admin write access to dashboard_sections" ON public.dashboard_sections;
DROP POLICY IF EXISTS "Public read access to dashboard_banners" ON public.dashboard_banners;
DROP POLICY IF EXISTS "Admin write access to dashboard_banners" ON public.dashboard_banners;
DROP POLICY IF EXISTS "Public read access to dashboard_quick_stats" ON public.dashboard_quick_stats;
DROP POLICY IF EXISTS "Admin write access to dashboard_quick_stats" ON public.dashboard_quick_stats;
DROP POLICY IF EXISTS "Public read access to dashboard_quick_actions" ON public.dashboard_quick_actions;
DROP POLICY IF EXISTS "Admin write access to dashboard_quick_actions" ON public.dashboard_quick_actions;

-- Drop tables
DROP TABLE IF EXISTS public.dashboard_sections CASCADE;
DROP TABLE IF EXISTS public.dashboard_banners CASCADE;
DROP TABLE IF EXISTS public.dashboard_quick_stats CASCADE;
DROP TABLE IF EXISTS public.dashboard_quick_actions CASCADE;
DROP TABLE IF EXISTS public.audit_logs CASCADE;
