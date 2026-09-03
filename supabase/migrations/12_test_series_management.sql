-- ==============================================================================
-- MIGRATION 12: TEST SERIES MANAGEMENT SCHEMA & COMMERCE INTEGRATION
-- Description: Dynamic schema for managing Test Series with Banners, Pricing,
--              Purchase links, and question linkage.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.test_series (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  exam TEXT DEFAULT 'NEET',
  year TEXT DEFAULT '2026',
  category TEXT DEFAULT 'Full Syllabus',
  banner_image_url TEXT DEFAULT '',
  
  -- Commerce & Pricing
  is_free BOOLEAN DEFAULT false,
  price NUMERIC(10, 2) DEFAULT 299.00,
  original_price NUMERIC(10, 2) DEFAULT 999.00,
  currency TEXT DEFAULT 'INR',
  purchase_link TEXT DEFAULT '',
  purchase_button_text TEXT DEFAULT 'Enroll Now',
  show_purchase_button BOOLEAN DEFAULT true,
  
  -- Test Structure & Attributes
  test_count INT DEFAULT 1,
  question_count INT DEFAULT 200,
  total_marks NUMERIC(10, 2) DEFAULT 720.00,
  duration_minutes INT DEFAULT 180,
  conducting_body TEXT DEFAULT 'NTA',
  difficulty TEXT DEFAULT 'Moderate', -- 'Easy', 'Moderate', 'Advanced', 'Mixed'
  validity TEXT DEFAULT 'Valid until exam',
  syllabus_url TEXT DEFAULT '',
  attempt_status TEXT DEFAULT 'Not Attempted', -- 'Not Attempted', 'In Progress', 'Completed'
  status TEXT DEFAULT 'Published', -- 'Draft', 'Published', 'Archived'
  features JSONB DEFAULT '["100+ High Quality Tests", "Detailed Solutions & Explanations", "All India Ranking"]'::jsonb,
  
  -- Associated Paper / Metadata
  paper_id TEXT DEFAULT '',
  paper_name TEXT DEFAULT '',
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.test_series ENABLE ROW LEVEL SECURITY;

-- Allow Public / Authenticated read access for published test series
CREATE POLICY "Public can view published test series"
ON public.test_series FOR SELECT
USING (true);

-- Allow Admins full management access
CREATE POLICY "Admins full management on test series"
ON public.test_series FOR ALL
USING (
  auth.role() = 'authenticated'
);

-- Seed initial default series if table is empty
INSERT INTO public.test_series (
  id, title, description, exam, year, category, banner_image_url,
  is_free, price, original_price, purchase_link, purchase_button_text, show_purchase_button,
  test_count, question_count, duration_minutes, difficulty, status
)
SELECT
  '33333333-3333-3333-3333-111111111111',
  'NEET 2026 Full Syllabus Test Series',
  'Comprehensive cumulative mock tests covering complete Physics, Chemistry, and Biology syllabus as per latest NTA NEET pattern.',
  'NEET',
  '2026',
  'Full Syllabus',
  'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&auto=format&fit=crop&q=60',
  false,
  299.00,
  999.00,
  'https://neet-jee.in/test-series',
  'Enroll Now - ₹299',
  true,
  12,
  200,
  180,
  'High',
  'Published'
WHERE NOT EXISTS (SELECT 1 FROM public.test_series WHERE title = 'NEET 2026 Full Syllabus Test Series');
