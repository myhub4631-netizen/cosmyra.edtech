-- ==============================================================================
-- MIGRATION 20: PAPER QUESTIONS RELATIONSHIP JOIN TABLE
-- Description: Join table to allow Test Series papers to reuse canonical questions
--              from PYQs, NTA papers, and Question Banks without record duplication.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.paper_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id UUID NOT NULL REFERENCES public.papers(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  sequence_order INT NOT NULL DEFAULT 1,
  section_name TEXT DEFAULT 'General',
  marks NUMERIC(5, 2) DEFAULT 4.0,
  negative_marks NUMERIC(5, 2) DEFAULT 1.0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(paper_id, question_id)
);

-- Indexing for performance
CREATE INDEX IF NOT EXISTS idx_paper_questions_paper ON public.paper_questions(paper_id, sequence_order);
CREATE INDEX IF NOT EXISTS idx_paper_questions_question ON public.paper_questions(question_id);

-- Security & RLS
ALTER TABLE public.paper_questions ENABLE ROW LEVEL SECURITY;

-- Public / Student read policy
DROP POLICY IF EXISTS "Public read paper_questions" ON public.paper_questions;
CREATE POLICY "Public read paper_questions"
ON public.paper_questions FOR SELECT
USING (true);

-- Admin write policy (Strict Admin-only write)
DROP POLICY IF EXISTS "Admin write paper_questions" ON public.paper_questions;
CREATE POLICY "Admin write paper_questions"
ON public.paper_questions FOR ALL
USING (
  public.is_admin(auth.uid()) OR auth.role() = 'service_role'
)
WITH CHECK (
  public.is_admin(auth.uid()) OR auth.role() = 'service_role'
);
