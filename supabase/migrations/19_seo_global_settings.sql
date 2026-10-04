-- ========================================================
-- COSMYRA PLATFORM - SITE CODE MANAGER & SEO GLOBAL SETTINGS
-- Migration: 19_seo_global_settings.sql
-- ========================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Ensure app_settings RLS policies are hard
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'app_settings') THEN
    ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Admins edit settings" ON public.app_settings;
    DROP POLICY IF EXISTS "Public read settings" ON public.app_settings;
    DROP POLICY IF EXISTS "Admin write settings" ON public.app_settings;
    CREATE POLICY "Public read settings" ON public.app_settings FOR SELECT USING (true);
    CREATE POLICY "Admin write settings" ON public.app_settings FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
  END IF;
END $$;

-- 2. SEO GLOBAL SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.seo_global_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  site_name TEXT NOT NULL DEFAULT 'Cosmyra NEET JEE',
  website_title TEXT NOT NULL DEFAULT 'Cosmyra NEET JEE | India''s Premier Exam Preparation Platform',
  default_meta_title TEXT NOT NULL DEFAULT 'Cosmyra NEET JEE - Practice Today, Achieve Tomorrow',
  default_meta_description TEXT NOT NULL DEFAULT 'Cosmyra NEET JEE provides comprehensive online exam prep with high-yield question banks, full-length mock tests, detailed analytics, and expert-crafted study materials.',
  default_keywords TEXT NOT NULL DEFAULT 'NEET 2026, JEE 2026, NEET preparation, JEE Main, mock tests, question bank, test series, Cosmyra',
  canonical_base_url TEXT NOT NULL DEFAULT 'https://neet-jee.in',
  default_og_title TEXT DEFAULT 'Cosmyra NEET JEE | Ace Your Medical & Engineering Entrance',
  default_og_description TEXT DEFAULT 'Join thousands of students cracking NEET & JEE with Cosmyra''s AI-powered practice engine and top faculty test series.',
  default_og_image TEXT DEFAULT 'https://neet-jee.in/icons/Icon-512.png',
  twitter_card_type TEXT NOT NULL DEFAULT 'summary_large_image',
  twitter_site_handle TEXT DEFAULT '@cosmyra_edu',
  organization_name TEXT NOT NULL DEFAULT 'Cosmyra Technologies Pvt. Ltd.',
  organization_logo_url TEXT DEFAULT 'https://neet-jee.in/assets/images/cosmyra_logo.png',
  organization_contact_email TEXT DEFAULT 'support@neet-jee.in',
  organization_phone TEXT DEFAULT '+91 98765 43210',
  robots_txt_content TEXT NOT NULL DEFAULT 'User-agent: *
Allow: /
Disallow: /admin/
Disallow: /superadmin/
Disallow: /api/

Sitemap: https://neet-jee.in/sitemap.xml',
  sitemap_xml_enabled BOOLEAN NOT NULL DEFAULT true,

  gsc_verification_method TEXT NOT NULL DEFAULT 'meta_tag',
  gsc_verification_code TEXT DEFAULT 'U3bHrqMV9245aSAvvNJxbuheY1mOPNFDfXZkGbEvHys',
  gsc_is_active BOOLEAN NOT NULL DEFAULT true,

  ga4_measurement_id TEXT DEFAULT '',
  ga4_is_enabled BOOLEAN NOT NULL DEFAULT false,
  ga4_environment TEXT NOT NULL DEFAULT 'production',

  gtm_container_id TEXT DEFAULT '',
  gtm_is_enabled BOOLEAN NOT NULL DEFAULT false,
  gtm_placement TEXT DEFAULT 'head',

  google_ads_conversion_id TEXT DEFAULT '',
  google_ads_conversion_label TEXT DEFAULT '',
  google_ads_is_enabled BOOLEAN NOT NULL DEFAULT false,

  adsense_publisher_id TEXT DEFAULT '',
  adsense_is_enabled BOOLEAN NOT NULL DEFAULT false,
  adsense_auto_ads_enabled BOOLEAN NOT NULL DEFAULT false,
  adsense_custom_code TEXT DEFAULT '',

  meta_pixel_id TEXT DEFAULT '',
  meta_pixel_is_enabled BOOLEAN NOT NULL DEFAULT false,

  bing_verification_id TEXT DEFAULT '',
  bing_is_enabled BOOLEAN NOT NULL DEFAULT false,

  head_code TEXT DEFAULT '',
  head_code_enabled BOOLEAN NOT NULL DEFAULT false,
  body_start_code TEXT DEFAULT '',
  body_start_code_enabled BOOLEAN NOT NULL DEFAULT false,
  body_end_code TEXT DEFAULT '',
  body_end_code_enabled BOOLEAN NOT NULL DEFAULT false,
  footer_code TEXT DEFAULT '',
  footer_code_enabled BOOLEAN NOT NULL DEFAULT false,

  custom_css TEXT DEFAULT '',
  custom_css_enabled BOOLEAN NOT NULL DEFAULT false,
  custom_css_scope TEXT DEFAULT 'user_facing',

  custom_js TEXT DEFAULT '',
  custom_js_enabled BOOLEAN NOT NULL DEFAULT false,
  custom_js_scope TEXT DEFAULT 'user_facing',

  emergency_kill_switch BOOLEAN NOT NULL DEFAULT false,
  current_version INT NOT NULL DEFAULT 1,

  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT DEFAULT 'Cosmyra Superadmin'
);

ALTER TABLE public.seo_global_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read seo global settings" ON public.seo_global_settings;
CREATE POLICY "Public read seo global settings" ON public.seo_global_settings
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins full access to seo_global_settings" ON public.seo_global_settings;
CREATE POLICY "Admins full access to seo_global_settings" ON public.seo_global_settings
  FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
