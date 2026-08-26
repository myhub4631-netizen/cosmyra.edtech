-- Supabase Migration: 06_pdf_worker_schema.sql
-- Dedicated Staging Architecture for PDF Question Worker & Pipeline

CREATE TABLE IF NOT EXISTS public.pdf_import_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    total_pages INT NOT NULL DEFAULT 0,
    pages_processed INT NOT NULL DEFAULT 0,
    questions_detected INT NOT NULL DEFAULT 0,
    questions_ready INT NOT NULL DEFAULT 0,
    questions_review INT NOT NULL DEFAULT 0,
    duplicates_detected INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, PROCESSING, COMPLETED, EXTRACTION_FAILED
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.pdf_import_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    import_job_id UUID NOT NULL REFERENCES public.pdf_import_jobs(id) ON DELETE CASCADE,
    page_number INT NOT NULL,
    raw_text TEXT,
    structured_json JSONB,
    ocr_used BOOLEAN DEFAULT FALSE,
    processing_status TEXT DEFAULT 'PROCESSED',
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.question_import_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    import_job_id UUID NOT NULL REFERENCES public.pdf_import_jobs(id) ON DELETE CASCADE,
    page_start INT NOT NULL,
    page_end INT NOT NULL,
    question_number INT NOT NULL,
    question_text TEXT NOT NULL,
    question_text_latex TEXT,
    options_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    correct_answer TEXT,
    explanation TEXT,
    subject TEXT,
    chapter TEXT,
    topic TEXT,
    source_type TEXT,
    difficulty TEXT DEFAULT 'Medium',
    source_bbox JSONB,
    extraction_method TEXT DEFAULT 'PyMuPDF+Docling',
    extraction_confidence DOUBLE PRECISION DEFAULT 98.0,
    validation_status TEXT DEFAULT 'READY', -- READY, NEEDS_REVIEW, DUPLICATE
    duplicate_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.pdf_import_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pdf_import_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_import_candidates ENABLE ROW LEVEL SECURITY;

-- Service & Auth Access Policies
CREATE POLICY "Allow public read pdf_import_jobs" ON public.pdf_import_jobs FOR SELECT USING (true);
CREATE POLICY "Allow public insert pdf_import_jobs" ON public.pdf_import_jobs FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update pdf_import_jobs" ON public.pdf_import_jobs FOR UPDATE USING (true);

CREATE POLICY "Allow public read pdf_import_pages" ON public.pdf_import_pages FOR SELECT USING (true);
CREATE POLICY "Allow public insert pdf_import_pages" ON public.pdf_import_pages FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public read question_import_candidates" ON public.question_import_candidates FOR SELECT USING (true);
CREATE POLICY "Allow public insert question_import_candidates" ON public.question_import_candidates FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update question_import_candidates" ON public.question_import_candidates FOR UPDATE USING (true);
