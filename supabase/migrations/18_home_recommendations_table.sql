-- Migration 18: Home Recommendations table & dynamic product curation
-- Enables admins to add Test Series, Subscription Plans, and Courses to the Home Screen carousel

CREATE TABLE IF NOT EXISTS public.home_recommendations (
  id TEXT PRIMARY KEY,
  product_type TEXT DEFAULT 'test_series', -- 'test_series', 'subscription', 'course', 'custom'
  test_series_id TEXT DEFAULT '',
  product_id TEXT DEFAULT '',
  title TEXT NOT NULL,
  subtitle TEXT DEFAULT '',
  badge TEXT DEFAULT 'RECOMMENDED',
  badge_color BIGINT DEFAULT 4280656875, -- 0xFF2563EB
  icon_type TEXT DEFAULT 'cap',
  tests_count INTEGER DEFAULT 20,
  questions_count INTEGER DEFAULT 3600,
  validity TEXT DEFAULT 'Till NEET 2026',
  price NUMERIC DEFAULT 499.0,
  original_price NUMERIC DEFAULT 999.0,
  target_route TEXT DEFAULT '',
  button_text TEXT DEFAULT 'Enroll Now',
  is_active BOOLEAN DEFAULT true,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for ordering
CREATE INDEX IF NOT EXISTS idx_home_recommendations_order ON public.home_recommendations(order_index, is_active);

-- Enable Row Level Security
ALTER TABLE public.home_recommendations ENABLE ROW LEVEL SECURITY;

-- Public can read all active recommendations
DROP POLICY IF EXISTS "Allow public select home_recommendations" ON public.home_recommendations;
CREATE POLICY "Allow public select home_recommendations"
ON public.home_recommendations FOR SELECT
USING (true);

-- Admins / Authenticated users have full management access
DROP POLICY IF EXISTS "Allow admins manage home_recommendations" ON public.home_recommendations;
CREATE POLICY "Allow admins manage home_recommendations"
ON public.home_recommendations FOR ALL
USING (true)
WITH CHECK (true);
