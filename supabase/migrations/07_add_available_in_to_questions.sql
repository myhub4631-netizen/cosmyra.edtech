-- ========================================================
-- Migration: 07_add_available_in_to_questions.sql
-- Add multi-module visibility column `available_in` to questions
-- ========================================================

-- Add available_in TEXT[] column with default array of all 5 modules
ALTER TABLE public.questions 
ADD COLUMN IF NOT EXISTS available_in TEXT[] DEFAULT ARRAY[
  'custom_practice',
  'custom_test',
  'pyq_practice',
  'nta_questions',
  'test_series'
];

-- Backfill any existing question records so no existing data is lost
UPDATE public.questions 
SET available_in = ARRAY[
  'custom_practice',
  'custom_test',
  'pyq_practice',
  'nta_questions',
  'test_series'
] 
WHERE available_in IS NULL OR cardinality(available_in) = 0;

-- Create GIN index for fast array membership lookup
CREATE INDEX IF NOT EXISTS idx_questions_available_in 
ON public.questions USING GIN (available_in);
