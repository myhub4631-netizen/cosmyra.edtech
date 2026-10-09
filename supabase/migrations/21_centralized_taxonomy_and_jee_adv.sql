-- Migration: 21_centralized_taxonomy_and_jee_adv.sql
-- Purpose: Centralized taxonomy seeding and canonical exam-subject-chapter-topic structure

-- 1. Ensure canonical Exams exist
INSERT INTO public.exams (id, name, code, description, display_order) VALUES
('11111111-1111-1111-1111-111111111111', 'NEET', 'NEET', 'National Eligibility cum Entrance Test for Medical aspirants', 1),
('22222222-2222-2222-2222-222222222222', 'JEE Main', 'JEE_MAIN', 'Joint Entrance Examination Main for Engineering aspirants', 2),
('33333333-3333-3333-3333-333333333333', 'JEE Advanced', 'JEE_ADV', 'Joint Entrance Examination Advanced for IIT admissions', 3)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- 2. Ensure canonical Subjects exist
INSERT INTO public.subjects (id, exam_id, name, code, color_hex, display_order) VALUES
-- NEET Subjects
('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Physics', 'NEET_PHYSICS', '#3B82F6', 1),
('a2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Chemistry', 'NEET_CHEMISTRY', '#10B981', 2),
('a3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Biology', 'NEET_BIOLOGY', '#EC4899', 3),

-- JEE Main Subjects
('a4444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', 'Physics', 'JEE_PHYSICS', '#6366F1', 1),
('a5555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222', 'Chemistry', 'JEE_CHEMISTRY', '#8B5CF6', 2),
('a6666666-6666-6666-6666-666666666666', '22222222-2222-2222-2222-222222222222', 'Mathematics', 'JEE_MATHS', '#F59E0B', 3),

-- JEE Advanced Subjects
('a7777777-7777-7777-7777-777777777777', '33333333-3333-3333-3333-333333333333', 'Physics', 'JEE_ADV_PHYSICS', '#4F46E5', 1),
('a8888888-8888-8888-8888-888888888888', '33333333-3333-3333-3333-333333333333', 'Chemistry', 'JEE_ADV_CHEMISTRY', '#7C3AED', 2),
('a9999999-9999-9999-9999-999999999999', '33333333-3333-3333-3333-333333333333', 'Mathematics', 'JEE_ADV_MATHS', '#D97706', 3)
ON CONFLICT (exam_id, code) DO UPDATE SET name = EXCLUDED.name, color_hex = EXCLUDED.color_hex;

-- 3. Security & RLS Policies for Taxonomy
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read exams" ON public.exams;
DROP POLICY IF EXISTS "Admin write exams" ON public.exams;
CREATE POLICY "Public read exams" ON public.exams FOR SELECT USING (true);
CREATE POLICY "Admin write exams" ON public.exams FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

DROP POLICY IF EXISTS "Public read subjects" ON public.subjects;
DROP POLICY IF EXISTS "Admin write subjects" ON public.subjects;
CREATE POLICY "Public read subjects" ON public.subjects FOR SELECT USING (true);
CREATE POLICY "Admin write subjects" ON public.subjects FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

DROP POLICY IF EXISTS "Public read chapters" ON public.chapters;
DROP POLICY IF EXISTS "Admin write chapters" ON public.chapters;
CREATE POLICY "Public read chapters" ON public.chapters FOR SELECT USING (true);
CREATE POLICY "Admin write chapters" ON public.chapters FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

DROP POLICY IF EXISTS "Public read topics" ON public.topics;
DROP POLICY IF EXISTS "Admin write topics" ON public.topics;
CREATE POLICY "Public read topics" ON public.topics FOR SELECT USING (true);
CREATE POLICY "Admin write topics" ON public.topics FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
