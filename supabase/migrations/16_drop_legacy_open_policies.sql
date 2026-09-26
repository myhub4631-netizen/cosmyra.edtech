-- ==============================================================================
-- COSMYRA PLATFORM - MIGRATION 16: DROP LEGACY PERMISSIVE E-COMMERCE RLS POLICIES
-- Description: Drop leftover legacy open policies ("Public full access orders",
--              "Public full access entitlements", "Public full access subscriptions")
--              and update get_public_leaderboard to use full_name column.
-- ==============================================================================

DROP POLICY IF EXISTS "Public full access orders" ON public.orders;
DROP POLICY IF EXISTS "Public full access entitlements" ON public.entitlements;
DROP POLICY IF EXISTS "Public full access subscriptions" ON public.subscriptions;

-- Fix get_public_leaderboard RPC column reference (full_name instead of display_name)
CREATE OR REPLACE FUNCTION public.get_public_leaderboard(
  p_test_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  rank BIGINT,
  student_id UUID,
  display_name TEXT,
  avatar_url TEXT,
  score NUMERIC(10, 2),
  total_time_seconds INT,
  accuracy NUMERIC(5, 2),
  completed_at TIMESTAMPTZ
) AS $$
BEGIN
  IF p_test_id IS NOT NULL THEN
    RETURN QUERY
    SELECT 
      ROW_NUMBER() OVER (ORDER BY ta.total_score DESC, COALESCE(ta.submitted_at, ta.created_at) ASC) as rank,
      ta.student_id,
      COALESCE(NULLIF(p.full_name, ''), 'Student #' || SUBSTRING(ta.student_id::text, 1, 8)) as display_name,
      COALESCE(p.avatar_url, '') as avatar_url,
      ta.total_score as score,
      COALESCE(ta.time_spent_seconds, 0) as total_time_seconds,
      COALESCE(ta.accuracy_percentage, 0.0) as accuracy,
      COALESCE(ta.submitted_at, ta.created_at) as completed_at
    FROM public.test_attempts ta
    JOIN public.profiles p ON p.id = ta.student_id
    WHERE ta.test_id = p_test_id 
      AND ta.status = 'submitted'
      AND COALESCE(p.is_public_on_leaderboard, true) = true
    ORDER BY ta.total_score DESC, COALESCE(ta.submitted_at, ta.created_at) ASC
    LIMIT p_limit;
  ELSE
    RETURN QUERY
    SELECT 
      ROW_NUMBER() OVER (ORDER BY le.score DESC) as rank,
      le.student_id,
      COALESCE(NULLIF(p.full_name, ''), 'Student #' || SUBSTRING(le.student_id::text, 1, 8)) as display_name,
      COALESCE(p.avatar_url, '') as avatar_url,
      le.score,
      0 as total_time_seconds,
      COALESCE(le.accuracy, 0.0) as accuracy,
      le.created_at as completed_at
    FROM public.leaderboard_entries le
    JOIN public.profiles p ON p.id = le.student_id
    WHERE COALESCE(p.is_public_on_leaderboard, true) = true
    ORDER BY le.score DESC
    LIMIT p_limit;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
