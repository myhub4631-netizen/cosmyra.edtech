-- ========================================================
-- COSMYRA PLATFORM - ADVANCED SEO & TRACKING MANAGER SCHEMA
-- Migration: 11_seo_tracking_tables.sql
-- ========================================================

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. SEO GLOBAL SETTINGS TABLE (Single row configuration)
CREATE TABLE IF NOT EXISTS public.seo_global_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  site_name TEXT NOT NULL DEFAULT 'Cosmyra NEET JEE',
  website_title TEXT NOT NULL DEFAULT 'Cosmyra NEET JEE | India''s Premier Exam Preparation Platform',
  default_meta_title TEXT NOT NULL DEFAULT 'Cosmyra NEET JEE - Practice Today, Achieve Tomorrow',
  default_meta_description TEXT NOT NULL DEFAULT 'Cosmyra NEET JEE provides comprehensive online exam prep with high-yield question banks, full-length mock tests, detailed analytics, and expert-crafted study materials.',
  default_keywords TEXT NOT NULL DEFAULT 'NEET 2026, JEE 2026, NEET preparation, JEE Main, mock tests, question bank, test series, Cosmyra',
  canonical_base_url TEXT NOT NULL DEFAULT 'https://cosmyra.edtech',
  default_og_title TEXT DEFAULT 'Cosmyra NEET JEE | Ace Your Medical & Engineering Entrance',
  default_og_description TEXT DEFAULT 'Join thousands of students cracking NEET & JEE with Cosmyra''s AI-powered practice engine and top faculty test series.',
  default_og_image TEXT DEFAULT 'https://cosmyra.edtech/icons/Icon-512.png',
  twitter_card_type TEXT NOT NULL DEFAULT 'summary_large_image', -- 'summary', 'summary_large_image'
  twitter_site_handle TEXT DEFAULT '@cosmyra_edu',
  organization_name TEXT NOT NULL DEFAULT 'Cosmyra Technologies Pvt. Ltd.',
  organization_logo_url TEXT DEFAULT 'https://cosmyra.edtech/assets/images/cosmyra_logo.png',
  organization_contact_email TEXT DEFAULT 'support@cosmyra.edtech',
  organization_phone TEXT DEFAULT '+91 98765 43210',
  robots_txt_content TEXT NOT NULL DEFAULT 'User-agent: *
Allow: /
Disallow: /admin/
Disallow: /superadmin/
Disallow: /api/

Sitemap: https://cosmyra.edtech/sitemap.xml',
  sitemap_xml_enabled BOOLEAN NOT NULL DEFAULT true,

  -- Google Search Console
  gsc_verification_method TEXT NOT NULL DEFAULT 'meta_tag', -- 'meta_tag', 'html_file', 'dns'
  gsc_verification_code TEXT DEFAULT 'U3bHrqMV9245aSAvvNJxbuheY1mOPNFDfXZkGbEvHys',
  gsc_is_active BOOLEAN NOT NULL DEFAULT true,

  -- Google Analytics (GA4)
  ga4_measurement_id TEXT DEFAULT '',
  ga4_is_enabled BOOLEAN NOT NULL DEFAULT false,
  ga4_environment TEXT NOT NULL DEFAULT 'production', -- 'production', 'all'

  -- Google Ads
  google_ads_conversion_id TEXT DEFAULT '',
  google_ads_conversion_label TEXT DEFAULT '',
  google_ads_is_enabled BOOLEAN NOT NULL DEFAULT false,

  -- Google AdSense
  adsense_publisher_id TEXT DEFAULT '',
  adsense_is_enabled BOOLEAN NOT NULL DEFAULT false,
  adsense_auto_ads_enabled BOOLEAN NOT NULL DEFAULT false,
  adsense_custom_code TEXT DEFAULT '',

  -- Custom Code Injection Zones
  head_code TEXT DEFAULT '',
  head_code_enabled BOOLEAN NOT NULL DEFAULT false,
  body_start_code TEXT DEFAULT '',
  body_start_code_enabled BOOLEAN NOT NULL DEFAULT false,
  body_end_code TEXT DEFAULT '',
  body_end_code_enabled BOOLEAN NOT NULL DEFAULT false,
  footer_code TEXT DEFAULT '',
  footer_code_enabled BOOLEAN NOT NULL DEFAULT false,

  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT DEFAULT 'Cosmyra Superadmin'
);

-- 2. SEO CUSTOM SCRIPTS TABLE (Modular scripts manager)
CREATE TABLE IF NOT EXISTS public.seo_custom_scripts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  code TEXT NOT NULL DEFAULT '',
  placement TEXT NOT NULL DEFAULT 'head', -- 'head', 'body_start', 'body_end', 'footer'
  priority_order INT NOT NULL DEFAULT 0,
  target_scope TEXT NOT NULL DEFAULT 'all', -- 'all', 'pages_only', 'blogs_only'
  is_active BOOLEAN NOT NULL DEFAULT true,
  environment TEXT NOT NULL DEFAULT 'production', -- 'production', 'all'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT DEFAULT 'Cosmyra Superadmin'
);

-- 3. SEO STRUCTURED SCHEMAS (JSON-LD)
CREATE TABLE IF NOT EXISTS public.seo_schemas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  schema_type TEXT NOT NULL DEFAULT 'organization', -- 'organization', 'website', 'breadcrumb', 'course', 'faq', 'article', 'custom'
  name TEXT NOT NULL,
  json_ld_content TEXT NOT NULL DEFAULT '{}',
  target_page_slug TEXT, -- NULL for global, or specific slug
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. EXTEND CMS PAGES AND BLOG POSTS FOR PAGE-LEVEL SEO
DO $$
BEGIN
  -- Add to cms_pages if table exists
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'cms_pages') THEN
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS canonical_url TEXT;
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS robots_index BOOLEAN DEFAULT true;
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS robots_follow BOOLEAN DEFAULT true;
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS og_title TEXT;
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS og_description TEXT;
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS og_image_url TEXT;
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS twitter_title TEXT;
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS twitter_description TEXT;
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS twitter_image_url TEXT;
    ALTER TABLE public.cms_pages ADD COLUMN IF NOT EXISTS schema_json_ld TEXT;
  END IF;

  -- Add to cms_blog_posts if table exists
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'cms_blog_posts') THEN
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS canonical_url TEXT;
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS robots_index BOOLEAN DEFAULT true;
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS robots_follow BOOLEAN DEFAULT true;
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS og_title TEXT;
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS og_description TEXT;
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS og_image_url TEXT;
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS twitter_title TEXT;
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS twitter_description TEXT;
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS twitter_image_url TEXT;
    ALTER TABLE public.cms_blog_posts ADD COLUMN IF NOT EXISTS schema_json_ld TEXT;
  END IF;
END $$;

-- 5. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.seo_global_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seo_custom_scripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seo_schemas ENABLE ROW LEVEL SECURITY;

-- Public can read active configurations
CREATE POLICY "Public read seo global settings" ON public.seo_global_settings
  FOR SELECT USING (true);

CREATE POLICY "Public read active seo custom scripts" ON public.seo_custom_scripts
  FOR SELECT USING (is_active = true);

CREATE POLICY "Public read active seo schemas" ON public.seo_schemas
  FOR SELECT USING (is_active = true);

-- Authenticated admins can manage everything
CREATE POLICY "Admins full access to seo_global_settings" ON public.seo_global_settings
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins full access to seo_custom_scripts" ON public.seo_custom_scripts
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins full access to seo_schemas" ON public.seo_schemas
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- 6. PRE-SEED INITIAL GLOBAL SEO SETTINGS
INSERT INTO public.seo_global_settings (
  id,
  site_name,
  website_title,
  default_meta_title,
  default_meta_description,
  default_keywords,
  canonical_base_url,
  gsc_verification_code,
  gsc_is_active
) VALUES (
  'e2d3c4b5-a6b7-4c8d-9e0f-1a2b3c4d5e6f',
  'Cosmyra NEET JEE',
  'Cosmyra NEET JEE | India''s Best Exam Preparation Platform',
  'Cosmyra NEET JEE - Practice Today, Achieve Tomorrow',
  'Prepare for NEET and JEE with Cosmyra. Practice thousands of curated questions, take realistic mock tests, analyze performance, and master topics with top educators.',
  'NEET 2026, JEE Main 2026, NEET mock tests, online question bank, PYQ papers, medical entrance, engineering prep, Cosmyra',
  'https://cosmyra.edtech',
  'U3bHrqMV9245aSAvvNJxbuheY1mOPNFDfXZkGbEvHys',
  true
) ON CONFLICT (id) DO NOTHING;

-- 7. PRE-SEED INITIAL GLOBAL SCHEMAS (JSON-LD)
INSERT INTO public.seo_schemas (
  schema_type,
  name,
  json_ld_content,
  target_page_slug,
  is_active
) VALUES
(
  'organization',
  'Cosmyra Educational Organization Schema',
  '{
  "@context": "https://schema.org",
  "@type": "EducationalOrganization",
  "name": "Cosmyra NEET JEE",
  "url": "https://cosmyra.edtech",
  "logo": "https://cosmyra.edtech/assets/images/cosmyra_logo.png",
  "sameAs": [
    "https://facebook.com/cosmyraedu",
    "https://twitter.com/cosmyra_edu",
    "https://instagram.com/cosmyra.edu",
    "https://youtube.com/@cosmyraedu"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+91-9876543210",
    "contactType": "customer service",
    "availableLanguage": ["English", "Hindi"]
  }
}',
  NULL,
  true
),
(
  'website',
  'Cosmyra Website Search Schema',
  '{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Cosmyra NEET JEE",
  "url": "https://cosmyra.edtech",
  "potentialAction": {
    "@type": "SearchAction",
    "target": "https://cosmyra.edtech/practice?q={search_term_string}",
    "query-input": "required name=search_term_string"
  }
}',
  NULL,
  true
)
ON CONFLICT DO NOTHING;
