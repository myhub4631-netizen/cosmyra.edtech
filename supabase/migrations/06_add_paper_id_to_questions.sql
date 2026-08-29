-- Migration 06: Create papers table and add paper_id column to questions table
CREATE TABLE IF NOT EXISTS public.papers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_category TEXT,
  category TEXT,
  source_type TEXT,
  source TEXT,
  exam TEXT,
  year INT,
  phase_session TEXT,
  paper_type TEXT,
  paper_name TEXT,
  paper_code TEXT,
  language TEXT DEFAULT 'English',
  conducting_body TEXT DEFAULT 'NTA',
  question_count INT DEFAULT 200,
  total_marks NUMERIC(6, 2) DEFAULT 720.0,
  duration_minutes INT DEFAULT 180,
  negative_marking TEXT DEFAULT 'Yes',
  negative_marks NUMERIC(5, 2) DEFAULT -4.0,
  positive_marks NUMERIC(5, 2) DEFAULT 4.0,
  subjects JSONB,
  shift TEXT,
  instructions TEXT,
  status TEXT DEFAULT 'Draft',
  saved_questions_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.papers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Papers full public access" ON public.papers;
CREATE POLICY "Papers full public access" ON public.papers FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS paper_id UUID REFERENCES public.papers(id) ON DELETE SET NULL;
ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS options JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS option_images JSONB DEFAULT '[]'::jsonb;
CREATE INDEX IF NOT EXISTS idx_questions_paper_id ON public.questions(paper_id);

ALTER TABLE public.question_options DROP CONSTRAINT IF EXISTS question_options_question_id_option_index_key;
ALTER TABLE public.question_options ADD CONSTRAINT question_options_question_id_option_index_key UNIQUE (question_id, option_index);
