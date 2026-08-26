-- ========================================================
-- COSMYRA COMPETITIVE EXAM PRACTICE PLATFORM - PDF IMPORT SCHEMA
-- Migration: 05_pdf_import_schema.sql
-- ========================================================

-- Custom Types for PDF Import System
CREATE TYPE pdf_import_status AS ENUM (
  'uploading',
  'queued',
  'processing',
  'ocr_processing',
  'parsing',
  'validating',
  'awaiting_review',
  'completed',
  'failed',
  'cancelled'
);

CREATE TYPE extracted_question_status AS ENUM (
  'ready',
  'needs_review',
  'duplicate',
  'approved',
  'rejected',
  'error'
);

-- 1. PDF IMPORT JOBS TABLE
CREATE TABLE IF NOT EXISTS public.pdf_import_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  file_name TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  file_size_bytes BIGINT DEFAULT 0,
  total_pages INT DEFAULT 0,
  uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  exam_id UUID REFERENCES public.exams(id) ON DELETE SET NULL,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  source_type TEXT DEFAULT 'NTA',
  extraction_mode TEXT DEFAULT 'auto', -- 'auto', 'text', 'ocr'
  
  status pdf_import_status DEFAULT 'queued',
  progress_percentage NUMERIC(5, 2) DEFAULT 0.0,
  
  questions_detected INT DEFAULT 0,
  questions_imported INT DEFAULT 0,
  duplicates_count INT DEFAULT 0,
  errors_count INT DEFAULT 0,
  
  error_message TEXT,
  settings JSONB DEFAULT '{}'::jsonb,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- 2. EXTRACTED QUESTIONS DRAFT TABLE
CREATE TABLE IF NOT EXISTS public.pdf_extracted_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  import_job_id UUID NOT NULL REFERENCES public.pdf_import_jobs(id) ON DELETE CASCADE,
  page_number INT DEFAULT 1,
  question_number INT DEFAULT 1,
  
  raw_text TEXT,
  question_text TEXT NOT NULL,
  question_image TEXT,
  q_type TEXT DEFAULT 'single_correct',
  difficulty TEXT DEFAULT 'medium',
  source_type TEXT DEFAULT 'NTA',
  
  options JSONB DEFAULT '[]'::jsonb, -- [{"index": 0, "text": "...", "is_correct": true}]
  correct_answer TEXT,
  explanation TEXT,
  
  exam_id UUID REFERENCES public.exams(id) ON DELETE SET NULL,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  chapter_id UUID REFERENCES public.chapters(id) ON DELETE SET NULL,
  topic_id UUID REFERENCES public.topics(id) ON DELETE SET NULL,
  
  tags TEXT[] DEFAULT '{}',
  used_in TEXT[] DEFAULT ARRAY['Custom Practice', 'Custom Test'],
  
  extraction_confidence NUMERIC(5, 2) DEFAULT 95.0,
  option_confidence NUMERIC(5, 2) DEFAULT 95.0,
  classification_confidence NUMERIC(5, 2) DEFAULT 90.0,
  overall_confidence NUMERIC(5, 2) DEFAULT 93.0,
  
  status extracted_question_status DEFAULT 'ready',
  duplicate_of_id UUID REFERENCES public.questions(id) ON DELETE SET NULL,
  duplicate_similarity NUMERIC(5, 2) DEFAULT 0.0,
  
  final_question_id UUID REFERENCES public.questions(id) ON DELETE SET NULL,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. PDF IMPORT ERRORS LOG TABLE
CREATE TABLE IF NOT EXISTS public.pdf_import_errors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  import_job_id UUID NOT NULL REFERENCES public.pdf_import_jobs(id) ON DELETE CASCADE,
  page_number INT,
  question_number INT,
  error_type TEXT NOT NULL,
  error_message TEXT NOT NULL,
  suggested_action TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. STORAGE BUCKETS CONFIGURATION
INSERT INTO storage.buckets (id, name, public) 
VALUES ('question-imports', 'question-imports', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('question-images', 'question-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies
CREATE POLICY "Public read question-imports" ON storage.objects
  FOR SELECT USING (bucket_id = 'question-imports');

CREATE POLICY "Public upload question-imports" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'question-imports');

CREATE POLICY "Public read question-images" ON storage.objects
  FOR SELECT USING (bucket_id = 'question-images');

CREATE POLICY "Public upload question-images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'question-images');
