-- ==============================================================================
-- MIGRATION 23: PRODUCTION-GRADE ANALYTICS EVENTS & KPI TRACKING SCHEMA
-- Description: Authoritative analytics logging, device & session distinction,
--              anti-fraud deduplication, and RLS policies for Cosmyra Neet Jee.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL,
  event_id TEXT UNIQUE NOT NULL, -- Client-generated unique UUID for idempotent deduplication
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  device_id TEXT NOT NULL,       -- Stable client hardware/browser install ID
  session_id TEXT NOT NULL,      -- Ephemeral session ID (30m rolling window)
  platform TEXT NOT NULL,        -- 'web', 'android', 'ios'
  app_version TEXT NOT NULL DEFAULT '2.2.8+9',
  is_anonymous BOOLEAN DEFAULT true,
  acquisition_source TEXT DEFAULT 'direct', -- 'direct', 'google', 'referral', 'campaign'
  properties JSONB DEFAULT '{}'::jsonb,     -- Privacy-conscious non-PII properties
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fast Indexing for KPI queries and time-series aggregation
CREATE INDEX IF NOT EXISTS idx_analytics_events_name_time ON public.analytics_events (event_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_time ON public.analytics_events (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_device_time ON public.analytics_events (device_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_platform ON public.analytics_events (platform, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_dedup ON public.analytics_events (event_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

-- 1. Anonymous & Authenticated Insertion Policy (Fire-and-forget ingestion)
CREATE POLICY "Allow public insert for analytics events"
ON public.analytics_events FOR INSERT
WITH CHECK (true);

-- 2. User Isolation Policy (Users can only view their own analytics events)
CREATE POLICY "Users can only view own analytics events"
ON public.analytics_events FOR SELECT
USING (auth.uid() = user_id);

-- 3. Admin Full Management Policy (Only platform Admins & Super Admins can aggregate events)
CREATE POLICY "Admins full access to analytics events"
ON public.analytics_events FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'super_admin')
  )
);
