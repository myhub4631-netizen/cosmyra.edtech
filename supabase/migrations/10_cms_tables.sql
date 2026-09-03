-- ========================================================
-- COSMYRA PLATFORM - ADMIN PAGE, BLOG & NAVIGATION CMS SCHEMA
-- Migration: 10_cms_tables.sql
-- ========================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. CMS PAGES TABLE
CREATE TABLE IF NOT EXISTS public.cms_pages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  content_format TEXT NOT NULL DEFAULT 'markdown', -- 'markdown', 'html'
  status TEXT NOT NULL DEFAULT 'draft', -- 'draft', 'published'
  seo_title TEXT,
  meta_description TEXT,
  featured_image_url TEXT,
  is_system BOOLEAN NOT NULL DEFAULT false,
  author_name TEXT DEFAULT 'Cosmyra Admin',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

-- 2. CMS BLOG CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.cms_blog_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CMS BLOG TAGS TABLE
CREATE TABLE IF NOT EXISTS public.cms_blog_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. CMS BLOG POSTS TABLE
CREATE TABLE IF NOT EXISTS public.cms_blog_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  excerpt TEXT,
  featured_image_url TEXT,
  status TEXT NOT NULL DEFAULT 'draft', -- 'draft', 'published'
  category_id UUID REFERENCES public.cms_blog_categories(id) ON DELETE SET NULL,
  tags TEXT[] DEFAULT '{}'::TEXT[],
  author_name TEXT NOT NULL DEFAULT 'Cosmyra Academic Team',
  seo_title TEXT,
  meta_description TEXT,
  read_time_minutes INT DEFAULT 5,
  views_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

-- 5. CMS NAVIGATION MENUS TABLE
CREATE TABLE IF NOT EXISTS public.cms_navigation_menus (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL, -- 'header_main', 'footer_main', 'mobile_drawer', 'app_sidebar'
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. CMS NAVIGATION ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.cms_navigation_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  menu_id UUID NOT NULL REFERENCES public.cms_navigation_menus(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  link_type TEXT NOT NULL DEFAULT 'custom_url', -- 'page', 'blog', 'custom_url', 'route'
  destination TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_visible BOOLEAN NOT NULL DEFAULT true,
  open_in_new_tab BOOLEAN NOT NULL DEFAULT false,
  parent_id UUID REFERENCES public.cms_navigation_items(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES FOR FAST QUERYING
CREATE INDEX IF NOT EXISTS idx_cms_pages_slug ON public.cms_pages (slug);
CREATE INDEX IF NOT EXISTS idx_cms_pages_status ON public.cms_pages (status);
CREATE INDEX IF NOT EXISTS idx_cms_blog_posts_slug ON public.cms_blog_posts (slug);
CREATE INDEX IF NOT EXISTS idx_cms_blog_posts_status ON public.cms_blog_posts (status, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_cms_navigation_items_menu ON public.cms_navigation_items (menu_id, sort_order ASC);

-- ========================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================================
ALTER TABLE public.cms_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cms_blog_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cms_blog_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cms_blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cms_navigation_menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cms_navigation_items ENABLE ROW LEVEL SECURITY;

-- Public read access: Anyone can read published pages & posts, and active navigation items
DROP POLICY IF EXISTS "Public Read Published Pages" ON public.cms_pages;
CREATE POLICY "Public Read Published Pages" ON public.cms_pages FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Categories" ON public.cms_blog_categories;
CREATE POLICY "Public Read Categories" ON public.cms_blog_categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Tags" ON public.cms_blog_tags;
CREATE POLICY "Public Read Tags" ON public.cms_blog_tags FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Published Blog Posts" ON public.cms_blog_posts;
CREATE POLICY "Public Read Published Blog Posts" ON public.cms_blog_posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Navigation Menus" ON public.cms_navigation_menus;
CREATE POLICY "Public Read Navigation Menus" ON public.cms_navigation_menus FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Navigation Items" ON public.cms_navigation_items;
CREATE POLICY "Public Read Navigation Items" ON public.cms_navigation_items FOR SELECT USING (true);

-- Admin CRUD access
DROP POLICY IF EXISTS "Admin All Pages" ON public.cms_pages;
CREATE POLICY "Admin All Pages" ON public.cms_pages FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin All Categories" ON public.cms_blog_categories;
CREATE POLICY "Admin All Categories" ON public.cms_blog_categories FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin All Tags" ON public.cms_blog_tags;
CREATE POLICY "Admin All Tags" ON public.cms_blog_tags FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin All Blog Posts" ON public.cms_blog_posts;
CREATE POLICY "Admin All Blog Posts" ON public.cms_blog_posts FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin All Navigation Menus" ON public.cms_navigation_menus;
CREATE POLICY "Admin All Navigation Menus" ON public.cms_navigation_menus FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin All Navigation Items" ON public.cms_navigation_items;
CREATE POLICY "Admin All Navigation Items" ON public.cms_navigation_items FOR ALL USING (true) WITH CHECK (true);

-- ========================================================
-- STORAGE BUCKET FOR CMS MEDIA & IMAGES
-- ========================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('cms-media', 'cms-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public Read CMS Media" ON storage.objects;
CREATE POLICY "Public Read CMS Media" ON storage.objects
  FOR SELECT USING (bucket_id = 'cms-media');

DROP POLICY IF EXISTS "Admin Upload CMS Media" ON storage.objects;
CREATE POLICY "Admin Upload CMS Media" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'cms-media');

DROP POLICY IF EXISTS "Admin Delete CMS Media" ON storage.objects;
CREATE POLICY "Admin Delete CMS Media" ON storage.objects
  FOR DELETE USING (bucket_id = 'cms-media');

-- ========================================================
-- SEED DEFAULT CATEGORIES & TAGS
-- ========================================================
INSERT INTO public.cms_blog_categories (name, slug, description, sort_order)
VALUES
  ('NEET Preparation', 'neet-prep', 'High-yield strategies, subject tips, and syllabus breakdowns for NEET UG aspirants.', 1),
  ('JEE Preparation', 'jee-prep', 'Advanced problem-solving techniques, formula sheets, and JEE Main & Advanced guidance.', 2),
  ('Exam Strategy', 'exam-strategy', 'Time management, test-taking temperament, and revision planning from top rankers.', 3),
  ('Platform Updates', 'updates', 'New feature releases, question bank expansions, and official announcements.', 4)
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

INSERT INTO public.cms_blog_tags (name, slug)
VALUES
  ('NEET 2026', 'neet-2026'),
  ('JEE Main 2026', 'jee-main-2026'),
  ('Biology', 'biology'),
  ('Physics', 'physics'),
  ('Chemistry', 'chemistry'),
  ('Mock Tests', 'mock-tests'),
  ('PYQ Analysis', 'pyq-analysis'),
  ('Study Schedule', 'study-schedule')
ON CONFLICT (slug) DO NOTHING;

-- ========================================================
-- SEED PRE-CREATED PAGES
-- ========================================================
INSERT INTO public.cms_pages (slug, title, content, content_format, status, seo_title, meta_description, is_system, published_at)
VALUES
  (
    'home',
    'Home - AI-Powered NEET & JEE Exam Prep Platform',
    '# Welcome to Cosmyra NEET | JEE\n\nCosmyra is India''s most advanced AI-powered preparation platform for NEET and JEE aspirants. Practice thousands of curated questions, take timed mock tests, and receive detailed step-by-step solutions.',
    'markdown',
    'published',
    'Cosmyra NEET JEE | Practice Today, Achieve Tomorrow',
    'Practice 20,000+ chapter-wise NEET & JEE questions with KaTeX step-by-step solutions, realistic mock tests, and smart mistake notebook.',
    true,
    NOW()
  ),
  (
    'about-us',
    'About Us',
    '# About Cosmyra NEET | JEE\n\nCosmyra was founded with a single mission: to democratize high-quality, competitive exam preparation for millions of NEET and JEE aspirants across India.\n\n### Our Vision\nTo empower every aspiring doctor and engineer with personalized, high-yield practice, deep diagnostic analytics, and exam-standard problem sets.\n\n### Why Choose Cosmyra?\n- **20,000+ Verified Questions**: Curated by experienced faculties adhering strictly to the latest NTA NCERT-based syllabus.\n- **LaTeX & KaTeX Solutions**: Crisp, step-by-step explanations with diagrams and formulas.\n- **Adaptive Mistake Notebook**: Automatically tracks weak concepts and guides your revision.\n- **All-India Percentiles**: Real-time comparative ranking with peer performance analytics.',
    'markdown',
    'published',
    'About Us | Cosmyra NEET JEE Platform',
    'Learn about Cosmyra NEET JEE mission, vision, and how our AI-driven learning tools help students excel in NEET and JEE exams.',
    true,
    NOW()
  ),
  (
    'contact-us',
    'Contact Us',
    '# Contact Support & Academic Team\n\nWe are here to help you throughout your exam preparation journey.\n\n### Get In Touch\n- **Email**: support@cosmyra.in / 1mdollar2027@gmail.com\n- **Operating Hours**: Monday – Saturday, 9:00 AM – 7:00 PM IST\n- **Headquarters**: Cosmyra Technologies Pvt. Ltd., Supaul, Bihar, India\n\n### Technical Support\nIf you experience any issues accessing test series, questions, or account subscriptions, please email us with your registered email and screenshot.',
    'markdown',
    'published',
    'Contact Us | Cosmyra NEET JEE',
    'Contact Cosmyra NEET JEE team for student support, subscription queries, and technical assistance.',
    true,
    NOW()
  ),
  (
    'privacy-policy',
    'Privacy Policy',
    '# Privacy Policy\n\n*Last Updated: September 2026*\n\nCosmyra Technologies Pvt. Ltd. ("Cosmyra", "we", "us") values your privacy. This policy explains how we collect, use, and safeguard your information when using the Cosmyra NEET JEE application and website.\n\n### 1. Information We Collect\n- **Account Information**: Name, email address, phone number, and targeted examination.\n- **Academic Performance**: Question attempts, test scores, study duration, accuracy, and mistake logs.\n- **Technical Data**: Device type, IP address, and browser data for performance optimization.\n\n### 2. How We Use Information\n- To deliver personalized question recommendations and test analysis.\n- To maintain student rankings and performance leaderboards.\n- To secure your account and authenticate sessions via Supabase Auth.\n\n### 3. Data Protection\nWe employ industry-standard encryption protocols and secure cloud databases to protect your sensitive personal data.',
    'markdown',
    'published',
    'Privacy Policy - Cosmyra NEET JEE',
    'Official Privacy Policy for Cosmyra NEET JEE exam preparation platform.',
    true,
    NOW()
  ),
  (
    'terms-of-service',
    'Terms of Service',
    '# Terms of Service\n\n*Last Updated: September 2026*\n\nBy accessing or using the Cosmyra NEET JEE platform, you agree to be bound by these Terms of Service.\n\n### 1. Account Usage\nYou are responsible for maintaining the confidentiality of your login credentials. Sharing accounts across multiple users is strictly prohibited.\n\n### 2. Intellectual Property\nAll test series, questions, solutions, illustrations, and software code are the intellectual property of Cosmyra Technologies Pvt. Ltd.\n\n### 3. Fair Use\nAutomated scraping, bulk downloading, or reproducing platform questions without written authorization is illegal and will result in immediate termination of access.',
    'markdown',
    'published',
    'Terms of Service - Cosmyra NEET JEE',
    'Official Terms of Service and student guidelines for Cosmyra NEET JEE platform.',
    true,
    NOW()
  ),
  (
    'disclaimer',
    'Disclaimer',
    '# Platform & Academic Disclaimer\n\nCosmyra NEET JEE is an independent ed-tech learning platform created to assist students in preparing for the National Eligibility cum Entrance Test (NEET-UG) and Joint Entrance Examination (JEE Main & Advanced).\n\n### Independent Platform\nCosmyra is **not affiliated with, endorsed by, or associated with the National Testing Agency (NTA), the Medical Counselling Committee (MCC), or the Joint Seat Allocation Authority (JoSAA)**.\n\nAll test papers, mock simulations, and predicted ranks are educational tools intended to boost student preparation and do not guarantee final exam marks.',
    'markdown',
    'published',
    'Disclaimer - Cosmyra NEET JEE',
    'Academic and legal disclaimer for Cosmyra NEET JEE educational platform.',
    true,
    NOW()
  ),
  (
    'refund-policy',
    'Refund & Cancellation Policy',
    '# Refund & Cancellation Policy\n\nAt Cosmyra, we strive to provide the highest standard of educational resources.\n\n### Subscription Cancellation\n- Students may cancel auto-renewing subscriptions at any time through their Profile Settings.\n- Cancellation takes effect at the end of the current billing cycle.\n\n### Refund Eligibility\n- **7-Day Money-Back Guarantee**: If you are unsatisfied with your premium test series subscription, you may request a full refund within 7 days of purchase, provided you have attempted fewer than 3 full tests.\n- To request a refund, email support@cosmyra.in with your payment transaction ID.',
    'markdown',
    'published',
    'Refund & Cancellation Policy - Cosmyra NEET JEE',
    'Learn about Cosmyra test series refund, cancellation, and money-back guarantee terms.',
    true,
    NOW()
  ),
  (
    'shipping-policy',
    'Shipping & Delivery Policy',
    '# Shipping & Delivery Policy\n\nCosmyra NEET JEE is a 100% digital cloud-based learning platform.\n\n### Digital Delivery\n- All test series, question banks, study material, and analytical reports are delivered electronically.\n- Access is granted **instantly** upon successful authentication or payment confirmation.\n- No physical goods or packages will be shipped to your postal address.',
    'markdown',
    'published',
    'Shipping & Delivery Policy - Cosmyra NEET JEE',
    'Details on digital product delivery and instant access for Cosmyra educational services.',
    true,
    NOW()
  ),
  (
    'cookie-policy',
    'Cookie Policy',
    '# Cookie Policy\n\nCosmyra uses cookies and local storage technologies to maintain secure user sessions and remember student preferences.\n\n### Types of Cookies We Use\n- **Essential Cookies**: Necessary for Supabase authentication, session verification, and exam timer integrity.\n- **Performance Cookies**: Help us measure page response times and fix runtime bugs.\n\nYou can manage or disable cookies in your browser settings, though certain interactive testing features may be impaired.',
    'markdown',
    'published',
    'Cookie Policy - Cosmyra NEET JEE',
    'Information on how Cosmyra utilizes cookies and local browser storage.',
    true,
    NOW()
  ),
  (
    'faq',
    'Frequently Asked Questions (FAQ)',
    '# Frequently Asked Questions\n\n### 1. Are the questions aligned with the latest 2026 NTA syllabus?\nYes! Our question banks are continuously updated to match NTA guidelines, including rationalized NCERT chapters for Biology, Chemistry, Physics, and Mathematics.\n\n### 2. Can I take tests on mobile devices?\nAbsolutely. Cosmyra is fully responsive and optimized for smartphones, tablets, laptops, and desktops.\n\n### 3. How does the Mistake Notebook work?\nEvery time you answer a question incorrectly during practice or timed mock exams, it is automatically cataloged in your **Mistake Book**. You can filter by subject and re-attempt until you achieve 100% mastery.\n\n### 4. Is there a free tier?\nYes! Free users have access to daily chapter-wise practice sets and select full mock tests.',
    'markdown',
    'published',
    'FAQ - Frequently Asked Questions | Cosmyra NEET JEE',
    'Answers to common questions regarding syllabus, mock tests, and Cosmyra subscriptions.',
    true,
    NOW()
  ),
  (
    'careers',
    'Careers at Cosmyra',
    '# Join the Cosmyra Team\n\nHelp us build the next generation of AI-enabled learning tools for India''s hardest competitive examinations.\n\n### Open Positions\n1. **Subject Matter Experts (Physics & Chemistry)** - Remote / Full-Time\n2. **Senior Flutter Developer** - Remote / Full-Time\n3. **Curriculum Lead (NEET Biology)** - Hybrid / Full-Time\n\n### How to Apply\nSend your resume and portfolio to `careers@cosmyra.in` with the position title in the subject line.',
    'markdown',
    'published',
    'Careers at Cosmyra NEET JEE | Join Our Mission',
    'Explore job openings and career opportunities at Cosmyra Technologies Pvt. Ltd.',
    true,
    NOW()
  ),
  (
    'help-support',
    'Help & Support',
    '# Help & Academic Support Center\n\nNeed assistance with your account, questions, or subscription?\n\n### Quick Solutions\n- **Forgot Password**: Click "Forgot Password" on the Login page to receive a secure reset link.\n- **Report a Question Error**: Click the flag icon next to any question during test review to notify our academic review board.\n- **Direct WhatsApp Support**: Available for enrolled test series students during exam season.',
    'markdown',
    'published',
    'Help & Support Center - Cosmyra NEET JEE',
    'Get fast support for technical issues, question doubts, and account access.',
    true,
    NOW()
  )
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title,
  content = EXCLUDED.content,
  seo_title = EXCLUDED.seo_title,
  meta_description = EXCLUDED.meta_description,
  updated_at = NOW();

-- ========================================================
-- SEED STARTER BLOG POSTS
-- ========================================================
INSERT INTO public.cms_blog_posts (title, slug, excerpt, content, featured_image_url, status, category_id, tags, author_name, seo_title, meta_description, read_time_minutes, published_at)
SELECT
  'Top 10 High-Yield Biology Chapters for NEET 2026',
  'top-10-high-yield-biology-chapters-neet-2026',
  'Master the chapters that contribute over 65% of the Biology section in NEET UG with chapter-wise weightage and NCERT key points.',
  '# Top 10 High-Yield Biology Chapters for NEET 2026\n\nBiology accounts for 360 marks out of 720 in the NEET-UG examination. Strategic preparation can easily elevate your score above 340+.\n\n### 1. Human Physiology (Weightage: ~20%)\n- **Key Topics**: Digestion, Breathing & Gas Exchange, Body Fluids & Circulation, Neural Control.\n- **Pro Tip**: Focus on graphical NCERT diagrams and hormone feedback loops.\n\n### 2. Genetics and Evolution (Weightage: ~18%)\n- **Key Topics**: Principles of Inheritance, Molecular Basis of Inheritance.\n- **Pro Tip**: Practice dihybrid crosses and DNA replication enzymes thoroughly.\n\n### 3. Ecology and Environment\n- Direct line-by-line NCERT questions are guaranteed. Memorize case studies and national sanctuary data.\n\n### Recommended Daily Routine\n1. Read NCERT chapter twice.\n2. Solve 50 chapter-wise MCQs on Cosmyra.\n3. Log incorrect questions into your Mistake Notebook.',
  'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&auto=format&fit=crop',
  'published',
  (SELECT id FROM public.cms_blog_categories WHERE slug = 'neet-prep' LIMIT 1),
  ARRAY['NEET 2026', 'Biology', 'Study Schedule'],
  'Dr. A. Verma (AIIMS Faculty Advisor)',
  'Top 10 High-Yield Biology Chapters for NEET 2026 | Cosmyra',
  'Comprehensive analysis of high-weightage NEET Biology chapters with NCERT revision tips.',
  6,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.cms_blog_posts WHERE slug = 'top-10-high-yield-biology-chapters-neet-2026');

INSERT INTO public.cms_blog_posts (title, slug, excerpt, content, featured_image_url, status, category_id, tags, author_name, seo_title, meta_description, read_time_minutes, published_at)
SELECT
  'How to Master Physics Numericals for JEE Main & NEET',
  'how-to-master-physics-numericals-jee-main-neet',
  'Overcome fear of Physics calculations with structured dimensional analysis, free-body diagrams, and smart estimation tricks.',
  '# How to Master Physics Numericals for JEE Main & NEET\n\nPhysics is frequently the deciding subject for top ranks in both NEET and JEE. Here is a battle-tested framework to solve numericals with high accuracy.\n\n### The 4-Step Problem Solving Method\n1. **Identify the Given and Target**: Note down known variables with units.\n2. **Draw Free-Body Diagram (FBD)**: Never attempt mechanics problems in your head.\n3. **Select Fundamental Governing Formula**: Avoid using shortcut formulas until you understand the root derivation.\n4. **Order of Magnitude Check**: Verify if your final answer has realistic dimensional units.\n\n> "Consistency beats intensity. Solving 25 quality physics questions daily is 10x better than cramming 150 questions once a week."',
  'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?w=800&auto=format&fit=crop',
  'published',
  (SELECT id FROM public.cms_blog_categories WHERE slug = 'jee-prep' LIMIT 1),
  ARRAY['Physics', 'JEE Main 2026', 'NEET 2026'],
  'Prof. R. Sengupta (IIT Kharagpur Alum)',
  'Master Physics Numericals for JEE & NEET | Cosmyra Guide',
  'Step-by-step techniques to improve physics problem-solving speed and accuracy.',
  7,
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.cms_blog_posts WHERE slug = 'how-to-master-physics-numericals-jee-main-neet');

-- ========================================================
-- SEED NAVIGATION MENUS & DEFAULT ITEMS
-- ========================================================
INSERT INTO public.cms_navigation_menus (key, name, description)
VALUES
  ('header_main', 'Main Header Navigation', 'Top bar links on the website landing page and web app.'),
  ('footer_main', 'Footer Navigation Links', 'Links displayed in the official site footer.'),
  ('mobile_drawer', 'Mobile Drawer Menu', 'Links inside the mobile slide-out hamburger drawer.'),
  ('app_sidebar', 'Student App Sidebar', 'Side navigation menu within the logged-in student dashboard.')
ON CONFLICT (key) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- Seed Header Items
WITH menu AS (SELECT id FROM public.cms_navigation_menus WHERE key = 'header_main' LIMIT 1)
INSERT INTO public.cms_navigation_items (menu_id, label, link_type, destination, sort_order, is_visible)
SELECT menu.id, item.label, item.link_type, item.destination, item.sort_order, true
FROM menu, (VALUES
  ('Practice', 'route', '/practice', 1),
  ('Test Series', 'route', '/test-series', 2),
  ('PYQ Papers', 'route', '/pyq', 3),
  ('Blog', 'route', '/blog', 4),
  ('Pricing', 'route', '/pricing', 5)
) AS item(label, link_type, destination, sort_order)
ON CONFLICT DO NOTHING;

-- Seed Footer Items
WITH menu AS (SELECT id FROM public.cms_navigation_menus WHERE key = 'footer_main' LIMIT 1)
INSERT INTO public.cms_navigation_items (menu_id, label, link_type, destination, sort_order, is_visible)
SELECT menu.id, item.label, item.link_type, item.destination, item.sort_order, true
FROM menu, (VALUES
  ('Home', 'route', '/', 1),
  ('About Us', 'page', '/about-us', 2),
  ('Blog', 'route', '/blog', 3),
  ('Privacy Policy', 'page', '/privacy-policy', 4),
  ('Terms of Service', 'page', '/terms-of-service', 5),
  ('Disclaimer', 'page', '/disclaimer', 6),
  ('Refund Policy', 'page', '/refund-policy', 7),
  ('FAQ', 'page', '/faq', 8),
  ('Careers', 'page', '/careers', 9),
  ('Contact Us', 'page', '/contact-us', 10)
) AS item(label, link_type, destination, sort_order)
ON CONFLICT DO NOTHING;
