-- Migration 05: Add is_active column to taxonomy tables if missing
ALTER TABLE public.exams ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.subjects ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.chapters ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.topics ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
