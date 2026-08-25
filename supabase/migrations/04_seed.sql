-- ========================================================
-- COSMYRA COMPETITIVE EXAM PRACTICE PLATFORM - SEED DATA
-- Migration: 04_seed.sql
-- Valid Hexadecimal UUIDs only (0-9, a-f)
-- ========================================================

-- 1. SEED EXAMS
INSERT INTO public.exams (id, name, code, description, display_order) VALUES
('11111111-1111-1111-1111-111111111111', 'NEET UG', 'NEET', 'National Eligibility cum Entrance Test for Medical aspirants', 1),
('22222222-2222-2222-2222-222222222222', 'JEE Main', 'JEE_MAIN', 'Joint Entrance Examination Main for Engineering aspirants', 2),
('33333333-3333-3333-3333-333333333333', 'JEE Advanced', 'JEE_ADV', 'Joint Entrance Examination Advanced for IIT admissions', 3)
ON CONFLICT (code) DO NOTHING;

-- 2. SEED SUBJECTS
INSERT INTO public.subjects (id, exam_id, name, code, color_hex, display_order) VALUES
-- NEET Subjects
('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Physics', 'NEET_PHYSICS', '#3B82F6', 1),
('a2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Chemistry', 'NEET_CHEMISTRY', '#10B981', 2),
('a3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Biology', 'NEET_BIOLOGY', '#EC4899', 3),

-- JEE Main Subjects
('a4444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', 'Physics', 'JEE_PHYSICS', '#6366F1', 1),
('a5555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222', 'Chemistry', 'JEE_CHEMISTRY', '#8B5CF6', 2),
('a6666666-6666-6666-6666-666666666666', '22222222-2222-2222-2222-222222222222', 'Mathematics', 'JEE_MATHS', '#F59E0B', 3)
ON CONFLICT (exam_id, code) DO NOTHING;

-- 3. SEED CHAPTERS
INSERT INTO public.chapters (id, subject_id, name, code, class_level, display_order) VALUES
-- NEET Physics Chapters
('b1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Laws of Motion', 'PHYS_LOM', 11, 1),
('b2222222-2222-2222-2222-222222222222', 'a1111111-1111-1111-1111-111111111111', 'Kinematics', 'PHYS_KINEMATICS', 11, 2),

-- NEET Chemistry Chapters
('b3333333-3333-3333-3333-333333333333', 'a2222222-2222-2222-2222-222222222222', 'Organic Chemistry - Hydrocarbons', 'CHEM_HYDROCARBONS', 11, 1),

-- NEET Biology Chapters
('b4444444-4444-4444-4444-444444444444', 'a3333333-3333-3333-3333-333333333333', 'Human Physiology - Digestion', 'BIO_DIGESTION', 11, 1)
ON CONFLICT (subject_id, code) DO NOTHING;

-- 4. SEED TOPICS
INSERT INTO public.topics (id, chapter_id, name, code, display_order) VALUES
('c1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'Friction & Newton Laws', 'TOPIC_FRICTION', 1),
('c2222222-2222-2222-2222-222222222222', 'b3333333-3333-3333-3333-333333333333', 'Alkanes & Free Radical Halogenation', 'TOPIC_ALKANES', 1),
('c3333333-3333-3333-3333-333333333333', 'b4444444-4444-4444-4444-444444444444', 'Human Digestive System Anatomy', 'TOPIC_DIGESTIVE_ANATOMY', 1)
ON CONFLICT (chapter_id, code) DO NOTHING;

-- 5. SEED QUESTIONS
-- Question 1: Physics (Single Correct MCQ with KaTeX formula)
INSERT INTO public.questions (
  id, exam_id, subject_id, chapter_id, topic_id,
  question_text, q_type, difficulty, source, marks, negative_marks, year, session, explanation, solution
) VALUES (
  'd1111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111',
  'a1111111-1111-1111-1111-111111111111',
  'b1111111-1111-1111-1111-111111111111',
  'c1111111-1111-1111-1111-111111111111',
  'A block of mass $m = 5\text{ kg}$ rests on a rough horizontal surface with coefficient of static friction $\mu_s = 0.4$. What is the minimum horizontal force $F$ required to initiate motion? (Take $g = 10\text{ m/s}^2$)',
  'single_correct',
  'medium',
  'pyq',
  4.0, 1.0, 2024, 'May Session',
  'Limiting static friction is given by $f_s = \mu_s N = \mu_s m g$.',
  '$f_s = 0.4 \times 5 \times 10 = 20\text{ N}$. Thus $F_{\text{min}} = 20\text{ N}$.'
) ON CONFLICT DO NOTHING;

INSERT INTO public.question_options (question_id, option_index, option_text, is_correct) VALUES
('d1111111-1111-1111-1111-111111111111', 0, '$10\text{ N}$', false),
('d1111111-1111-1111-1111-111111111111', 1, '$15\text{ N}$', false),
('d1111111-1111-1111-1111-111111111111', 2, '$20\text{ N}$', true),
('d1111111-1111-1111-1111-111111111111', 3, '$25\text{ N}$', false)
ON CONFLICT DO NOTHING;

-- Question 2: Chemistry Hydrocarbons
INSERT INTO public.questions (
  id, exam_id, subject_id, chapter_id, topic_id,
  question_text, q_type, difficulty, source, marks, negative_marks, year, session, explanation, solution
) VALUES (
  'd2222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  'a2222222-2222-2222-2222-222222222222',
  'b3333333-3333-3333-3333-333333333333',
  'c2222222-2222-2222-2222-222222222222',
  'Which of the following alkanes gives only one monochloro derivative upon photochemical chlorination?',
  'single_correct',
  'easy',
  'nta',
  4.0, 1.0, 2025, 'NTA Abhyas Pack 1',
  'Neopentane possesses 12 equivalent hydrogens, yielding a single monochloro product.',
  'Structure of Neopentane: $(CH_3)_4C$. All hydrogen atoms are chemically equivalent.'
) ON CONFLICT DO NOTHING;

INSERT INTO public.question_options (question_id, option_index, option_text, is_correct) VALUES
('d2222222-2222-2222-2222-222222222222', 0, 'n-Pentane', false),
('d2222222-2222-2222-2222-222222222222', 1, 'Isopentane', false),
('d2222222-2222-2222-2222-222222222222', 2, 'Neopentane', true),
('d2222222-2222-2222-2222-222222222222', 3, '2-Methylbutane', false)
ON CONFLICT DO NOTHING;

-- Question 3: Biology Human Physiology
INSERT INTO public.questions (
  id, exam_id, subject_id, chapter_id, topic_id,
  question_text, q_type, difficulty, source, marks, negative_marks, year, session, explanation, solution
) VALUES (
  'd3333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  'a3333333-3333-3333-3333-333333333333',
  'b4444444-4444-4444-4444-444444444444',
  'c3333333-3333-3333-3333-333333333333',
  'Parietal cells (Oxyntic cells) in the gastric mucosa of human stomach secrete:',
  'single_correct',
  'easy',
  'pyq',
  4.0, 1.0, 2023, 'NEET Phase 1',
  'Oxyntic cells secrete HCl and Castle Intrinsic Factor (vital for Vitamin B12 absorption).',
  'Pepsinogen is secreted by Chief cells (Peptic cells). HCl is secreted by Oxyntic/Parietal cells.'
) ON CONFLICT DO NOTHING;

INSERT INTO public.question_options (question_id, option_index, option_text, is_correct) VALUES
('d3333333-3333-3333-3333-333333333333', 0, 'Pepsinogen and Mucus', false),
('d3333333-3333-3333-3333-333333333333', 1, 'HCl and Intrinsic Factor', true),
('d3333333-3333-3333-3333-333333333333', 2, 'Trypsinogen and Amylase', false),
('d3333333-3333-3333-3333-333333333333', 3, 'Gastrin and Secretin', false)
ON CONFLICT DO NOTHING;

-- 6. APP SETTINGS SEED
INSERT INTO public.app_settings (key, value, description) VALUES
('feature_flags', '{"custom_practice_enabled": true, "custom_test_enabled": true, "leaderboard_enabled": true, "teacher_tests_enabled": true, "pyq_enabled": true, "nta_enabled": true}', 'Global feature flags'),
('exam_config', '{"default_exam": "NEET", "negative_marking_enabled": true}', 'Default configuration for exam platform')
ON CONFLICT (key) DO NOTHING;
