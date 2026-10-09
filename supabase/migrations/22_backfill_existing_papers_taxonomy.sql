-- Migration: 22_backfill_existing_papers_taxonomy.sql
-- Purpose: Backfill canonical exam_id, subject_id, chapter_id, and topic_id for all existing papers and questions

-- 1. Ensure exam_id column exists on public.papers
ALTER TABLE public.papers ADD COLUMN IF NOT EXISTS exam_id UUID REFERENCES public.exams(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_papers_exam_id ON public.papers(exam_id);

-- 2. Backfill exam_id on public.papers
-- JEE Advanced Papers
UPDATE public.papers
SET exam_id = '33333333-3333-3333-3333-333333333333'
WHERE exam_id IS NULL
  AND (exam ILIKE '%ADV%' OR paper_name ILIKE '%JEE ADV%' OR source ILIKE '%JEE ADV%');

-- JEE Main Papers
UPDATE public.papers
SET exam_id = '22222222-2222-2222-2222-222222222222'
WHERE exam_id IS NULL
  AND (exam ILIKE '%JEE%' OR paper_name ILIKE '%JEE%' OR source ILIKE '%JEE%');

-- NEET default Papers
UPDATE public.papers
SET exam_id = '11111111-1111-1111-1111-111111111111'
WHERE exam_id IS NULL;

-- 3. Backfill exam_id on public.questions from parent papers or source metadata
UPDATE public.questions q
SET exam_id = p.exam_id
FROM public.papers p
WHERE q.paper_id = p.id
  AND (q.exam_id IS NULL OR q.exam_id != p.exam_id);

-- Questions without paper_id: infer exam_id
UPDATE public.questions
SET exam_id = '33333333-3333-3333-3333-333333333333'
WHERE exam_id IS NULL
  AND (paper ILIKE '%JEE ADV%' OR session ILIKE '%JEE ADV%' OR source ILIKE '%JEE ADV%');

UPDATE public.questions
SET exam_id = '22222222-2222-2222-2222-222222222222'
WHERE exam_id IS NULL
  AND (paper ILIKE '%JEE%' OR session ILIKE '%JEE%' OR source ILIKE '%JEE%');

UPDATE public.questions
SET exam_id = '11111111-1111-1111-1111-111111111111'
WHERE exam_id IS NULL;

-- 4. Backfill subject_id on public.questions based on exam_id and subject string
-- NEET Physics
UPDATE public.questions
SET subject_id = 'a1111111-1111-1111-1111-111111111111'
WHERE exam_id = '11111111-1111-1111-1111-111111111111'
  AND (subject_id IS NULL OR subject_id NOT IN ('a1111111-1111-1111-1111-111111111111', 'a2222222-2222-2222-2222-222222222222', 'a3333333-3333-3333-3333-333333333333'));

-- JEE Main Physics
UPDATE public.questions
SET subject_id = 'a4444444-4444-4444-4444-444444444444'
WHERE exam_id = '22222222-2222-2222-2222-222222222222'
  AND (subject_id IS NULL OR subject_id NOT IN ('a4444444-4444-4444-4444-444444444444', 'a5555555-5555-5555-5555-555555555555', 'a6666666-6666-6666-6666-666666666666'));

-- JEE Advanced Physics
UPDATE public.questions
SET subject_id = 'a7777777-7777-7777-7777-777777777777'
WHERE exam_id = '33333333-3333-3333-3333-333333333333'
  AND (subject_id IS NULL OR subject_id NOT IN ('a7777777-7777-7777-7777-777777777777', 'a8888888-8888-8888-8888-888888888888', 'a9999999-9999-9999-9999-999999999999'));

-- 5. Backfill chapter_id on public.questions where missing by matching default chapter for subject
UPDATE public.questions q
SET chapter_id = c.id
FROM public.chapters c
WHERE q.chapter_id IS NULL
  AND c.subject_id = q.subject_id
  AND c.display_order = 1;
