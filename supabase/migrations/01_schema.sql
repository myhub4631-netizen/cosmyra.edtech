-- ========================================================
-- COSMYRA COMPETITIVE EXAM PRACTICE PLATFORM - DATABASE SCHEMA
-- Migration: 01_schema.sql
-- ========================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Custom Types & Enums
CREATE TYPE user_role AS ENUM ('student', 'teacher', 'admin', 'super_admin');
CREATE TYPE question_type AS ENUM (
  'single_correct',
  'multiple_correct',
  'numerical',
  'assertion_reason',
  'match_following',
  'true_false',
  'passage_based',
  'image_based'
);
CREATE TYPE difficulty_level AS ENUM ('easy', 'medium', 'hard');
CREATE TYPE question_source AS ENUM (
  'pyq',
  'nta',
  'teacher_created',
  'admin_created',
  'ai_generated',
  'imported',
  'practice',
  'mock_test'
);
CREATE TYPE question_status AS ENUM ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'published');
CREATE TYPE teacher_status AS ENUM ('pending', 'approved', 'rejected', 'suspended');
CREATE TYPE test_type AS ENUM ('custom_practice', 'custom_test', 'teacher_test', 'quiz', 'mock_exam');
CREATE TYPE attempt_status AS ENUM ('in_progress', 'submitted', 'expired', 'abandoned');
CREATE TYPE bookmark_category AS ENUM ('important', 'difficult', 'revision', 'mistake', 'custom');
CREATE TYPE report_status AS ENUM ('open', 'under_review', 'resolved', 'rejected');

-- 1. USERS & PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  phone TEXT,
  phone_number TEXT,
  role TEXT DEFAULT 'student',
  target_exam TEXT DEFAULT 'NEET',
  target_year INT DEFAULT 2026,
  study_streak INT DEFAULT 1,
  questions_attempted INT DEFAULT 0,
  total_correct INT DEFAULT 0,
  accuracy NUMERIC DEFAULT 0.0,
  rank INT DEFAULT 0,
  education_level TEXT,
  bio TEXT,
  is_public_on_leaderboard BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. USER ROLES
CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'student',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);

-- 3. TEACHERS TABLE
CREATE TABLE IF NOT EXISTS public.teachers (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  qualification TEXT,
  experience_years INT DEFAULT 0,
  organization_name TEXT,
  subjects TEXT[],
  verification_status teacher_status DEFAULT 'pending',
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES public.profiles(id),
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TAXONOMY TABLES (Exam -> Subject -> Chapter -> Topic -> Subtopic)
CREATE TABLE IF NOT EXISTS public.exams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  icon_url TEXT,
  is_active BOOLEAN DEFAULT true,
  display_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  exam_id UUID NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  color_hex TEXT DEFAULT '#3B82F6',
  display_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(exam_id, code)
);

CREATE TABLE IF NOT EXISTS public.chapters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  class_level INT DEFAULT 11, -- e.g., Class 11 or 12
  display_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(subject_id, code)
);

CREATE TABLE IF NOT EXISTS public.topics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chapter_id UUID NOT NULL REFERENCES public.chapters(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  display_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(chapter_id, code)
);

CREATE TABLE IF NOT EXISTS public.subtopics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  topic_id UUID NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(topic_id, code)
);

CREATE TABLE IF NOT EXISTS public.tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. CENTRALIZED QUESTION BANK
CREATE TABLE IF NOT EXISTS public.questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  exam_id UUID NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  chapter_id UUID NOT NULL REFERENCES public.chapters(id) ON DELETE CASCADE,
  topic_id UUID REFERENCES public.topics(id) ON DELETE SET NULL,
  subtopic_id UUID REFERENCES public.subtopics(id) ON DELETE SET NULL,
  
  question_text TEXT NOT NULL,
  question_image TEXT,
  q_type question_type DEFAULT 'single_correct',
  difficulty difficulty_level DEFAULT 'medium',
  source question_source DEFAULT 'practice',
  
  explanation TEXT,
  solution TEXT,
  
  marks NUMERIC(5, 2) DEFAULT 4.0,
  negative_marks NUMERIC(5, 2) DEFAULT 1.0,
  estimated_seconds INT DEFAULT 120,
  
  year INT,
  session TEXT,
  shift TEXT,
  paper TEXT,
  question_number INT,
  
  language TEXT DEFAULT 'en',
  status question_status DEFAULT 'published',
  
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.question_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  option_index INT NOT NULL, -- 0 for A, 1 for B, 2 for C, 3 for D
  option_text TEXT NOT NULL,
  option_image TEXT,
  is_correct BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.question_tags (
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES public.tags(id) ON DELETE CASCADE,
  PRIMARY KEY (question_id, tag_id)
);

-- 6. TESTS & TEACHER TEST INVITATIONS
CREATE TABLE IF NOT EXISTS public.tests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  exam_id UUID NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  test_type test_type DEFAULT 'custom_test',
  
  duration_minutes INT NOT NULL DEFAULT 60,
  total_marks NUMERIC(6, 2) DEFAULT 100.0,
  default_negative_marking NUMERIC(4, 2) DEFAULT 1.0,
  attempt_limit INT DEFAULT 0, -- 0 for unlimited
  
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  is_published BOOLEAN DEFAULT true,
  
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  invitation_code TEXT UNIQUE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.test_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  test_id UUID NOT NULL REFERENCES public.tests(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  section_name TEXT DEFAULT 'General',
  sequence_order INT NOT NULL DEFAULT 1,
  marks NUMERIC(5, 2) DEFAULT 4.0,
  negative_marks NUMERIC(5, 2) DEFAULT 1.0,
  UNIQUE(test_id, question_id)
);

CREATE TABLE IF NOT EXISTS public.test_invites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  test_id UUID NOT NULL REFERENCES public.tests(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ,
  max_uses INT DEFAULT 0, -- 0 for unlimited
  uses_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. ATTEMPTS & ANSWERS
CREATE TABLE IF NOT EXISTS public.test_attempts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  test_id UUID REFERENCES public.tests(id) ON DELETE SET NULL,
  mode test_type DEFAULT 'custom_test',
  
  status attempt_status DEFAULT 'in_progress',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  submitted_at TIMESTAMPTZ,
  
  total_score NUMERIC(6, 2) DEFAULT 0,
  max_score NUMERIC(6, 2) DEFAULT 0,
  correct_count INT DEFAULT 0,
  incorrect_count INT DEFAULT 0,
  unattempted_count INT DEFAULT 0,
  accuracy_percentage NUMERIC(5, 2) DEFAULT 0,
  time_spent_seconds INT DEFAULT 0,
  
  question_order UUID[] NOT NULL DEFAULT '{}',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.test_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attempt_id UUID NOT NULL REFERENCES public.test_attempts(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  
  selected_option_ids UUID[] DEFAULT '{}',
  numerical_answer TEXT,
  is_marked_for_review BOOLEAN DEFAULT false,
  
  is_correct BOOLEAN,
  marks_awarded NUMERIC(5, 2) DEFAULT 0,
  time_spent_seconds INT DEFAULT 0,
  answered_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(attempt_id, question_id)
);

-- 8. BOOKMARKS & MISTAKES
CREATE TABLE IF NOT EXISTS public.bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  category bookmark_category DEFAULT 'important',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, question_id)
);

CREATE TABLE IF NOT EXISTS public.mistake_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  incorrect_attempts INT DEFAULT 1,
  is_resolved BOOLEAN DEFAULT false,
  last_attempted_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, question_id)
);

-- 9. REPORTS & ANOMALIES
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  report_type TEXT NOT NULL, -- e.g. 'wrong_answer', 'typo', 'bad_explanation', 'image_broken'
  description TEXT NOT NULL,
  status report_status DEFAULT 'open',
  admin_notes TEXT,
  resolved_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. LEADERBOARDS & STREAKS
CREATE TABLE IF NOT EXISTS public.streaks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_activity_date DATE DEFAULT CURRENT_DATE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.leaderboard_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  period_type TEXT NOT NULL, -- 'daily', 'weekly', 'monthly'
  period_date DATE NOT NULL,
  score NUMERIC(10, 2) DEFAULT 0,
  questions_solved INT DEFAULT 0,
  accuracy NUMERIC(5, 2) DEFAULT 0,
  rank INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, period_type, period_date)
);

-- 11. NOTIFICATIONS & AUDIT LOGS
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info',
  is_read BOOLEAN DEFAULT false,
  link_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id UUID,
  old_value JSONB,
  new_value JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. PLATFORM SETTINGS & FEATURE FLAGS
CREATE TABLE IF NOT EXISTS public.app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES public.profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES FOR MAXIMUM QUERY PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_questions_exam_subject ON public.questions(exam_id, subject_id);
CREATE INDEX IF NOT EXISTS idx_questions_chapter ON public.questions(chapter_id);
CREATE INDEX IF NOT EXISTS idx_questions_topic ON public.questions(topic_id);
CREATE INDEX IF NOT EXISTS idx_questions_source_year ON public.questions(source, year);
CREATE INDEX IF NOT EXISTS idx_test_attempts_student ON public.test_attempts(student_id, status);
CREATE INDEX IF NOT EXISTS idx_test_answers_attempt ON public.test_answers(attempt_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_student ON public.bookmarks(student_id);
CREATE INDEX IF NOT EXISTS idx_mistakes_student ON public.mistake_questions(student_id, is_resolved);
CREATE INDEX IF NOT EXISTS idx_test_invites_code ON public.test_invites(code);
CREATE INDEX IF NOT EXISTS idx_leaderboard_period ON public.leaderboard_entries(period_type, period_date, score DESC);
