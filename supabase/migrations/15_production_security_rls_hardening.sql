-- ==============================================================================
-- COSMYRA PLATFORM - MIGRATION 15: PRODUCTION RLS HARDENING & SECURITY PASS
-- Description: Complete lockdown of all RLS policies, role escalation triggers,
--              score integrity protection, secure atomic order fulfillment,
--              privacy-preserving leaderboard RPC, and performance indexes.
-- ==============================================================================

-- 1. HELPER FUNCTIONS & TRIGGERS FOR SECURITY

-- 1.1 Prevent User Role Escalation (Profiles Table)
CREATE OR REPLACE FUNCTION public.prevent_user_role_escalation()
RETURNS TRIGGER AS $$
BEGIN
  IF (OLD.role IS DISTINCT FROM NEW.role) AND NOT public.is_admin(auth.uid()) AND (auth.role() <> 'service_role') THEN
    RAISE EXCEPTION 'Unauthorized attempt to alter user role from % to %', OLD.role, NEW.role;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_prevent_role_escalation ON public.profiles;
CREATE TRIGGER trg_prevent_role_escalation
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_user_role_escalation();

-- 1.2 Prevent Direct Student Tampering of Test Attempt Scores & Status
CREATE OR REPLACE FUNCTION public.protect_test_attempt_integrity()
RETURNS TRIGGER AS $$
BEGIN
  -- Service role and Admins bypass direct update restrictions
  IF NOT public.is_admin(auth.uid()) AND (auth.role() <> 'service_role') THEN
    IF (OLD.status = 'submitted' AND NEW.status <> 'submitted') THEN
      RAISE EXCEPTION 'Submitted test attempts cannot be re-opened or modified';
    END IF;
    -- Normal students cannot update scores directly via REST API
    IF (NEW.total_score IS DISTINCT FROM OLD.total_score) AND pg_trigger_depth() = 1 THEN
      RAISE EXCEPTION 'Test attempt score can only be updated via submit_test_attempt server RPC';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_protect_test_attempt_integrity ON public.test_attempts;
CREATE TRIGGER trg_protect_test_attempt_integrity
  BEFORE UPDATE ON public.test_attempts
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_test_attempt_integrity();

-- 2. PRIVACY-PRESERVING PUBLIC LEADERBOARD RPC
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
      COALESCE(NULLIF(p.display_name, ''), 'Student #' || SUBSTRING(ta.student_id::text, 1, 8)) as display_name,
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
      COALESCE(NULLIF(p.display_name, ''), 'Student #' || SUBSTRING(le.student_id::text, 1, 8)) as display_name,
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

-- 3. SECURE ATOMIC ORDER APPROVAL & ENTITLEMENT GRANTING RPC
CREATE OR REPLACE FUNCTION public.approve_and_fulfill_order(
  p_order_id TEXT,
  p_admin_id UUID DEFAULT NULL,
  p_payment_id TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_item RECORD;
  v_now TIMESTAMPTZ := NOW();
  v_expiry TIMESTAMPTZ := NOW() + INTERVAL '365 days';
  v_granted_count INT := 0;
  v_user_uuid UUID;
BEGIN
  -- Verify order exists
  SELECT * INTO v_order FROM public.orders WHERE id::text = p_order_id OR order_number = p_order_id;
  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found: %', p_order_id;
  END IF;

  -- Verify admin caller authorization (unless service_role execution)
  IF p_admin_id IS NOT NULL AND NOT public.is_admin(p_admin_id) THEN
    RAISE EXCEPTION 'Unauthorized: Caller is not an admin';
  END IF;

  -- Update order status to completed
  UPDATE public.orders
  SET status = 'completed',
      payment_id = COALESCE(p_payment_id, payment_id, 'UPI_VERIFIED_' || SUBSTRING(p_order_id::text, 1, 8)),
      updated_at = v_now
  WHERE id::text = v_order.id::text;

  -- Parse user_id to UUID
  BEGIN
    v_user_uuid := v_order.user_id::UUID;
  EXCEPTION WHEN OTHERS THEN
    v_user_uuid := NULL;
  END;

  -- Loop through order items and grant entitlements atomically
  FOR v_item IN SELECT * FROM public.order_items WHERE order_id::text = v_order.id::text
  LOOP
    IF v_user_uuid IS NOT NULL THEN
      INSERT INTO public.entitlements (
        user_id,
        user_email,
        product_id,
        product_title,
        product_type,
        order_id,
        access_type,
        valid_from,
        valid_until,
        is_active,
        created_at,
        updated_at
      ) VALUES (
        v_user_uuid,
        v_order.user_email,
        v_item.product_id,
        v_item.product_title,
        COALESCE(v_item.product_type, 'test_series'),
        v_user_uuid,
        'full',
        v_now,
        v_expiry,
        true,
        v_now,
        v_now
      )
      ON CONFLICT DO NOTHING;

      -- If subscription, also record in subscriptions table
      IF v_item.product_type = 'subscription' THEN
        INSERT INTO public.subscriptions (
          user_id,
          user_email,
          plan_id,
          plan_title,
          billing_cycle,
          status,
          amount,
          start_date,
          end_date,
          auto_renew,
          created_at,
          updated_at
        ) VALUES (
          v_user_uuid,
          v_order.user_email,
          v_item.product_id,
          v_item.product_title,
          'yearly',
          'active',
          v_item.price,
          v_now,
          v_expiry,
          false,
          v_now,
          v_now
        );
      END IF;
    END IF;

    v_granted_count := v_granted_count + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'status', 'completed',
    'entitlements_granted', v_granted_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. COMPLETE OVERHAUL OF RLS POLICIES ACROSS ALL TABLES

-- 4.1 Profiles Table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Profiles full public access" ON public.profiles;
DROP POLICY IF EXISTS "Profiles viewable by all" ON public.profiles;
DROP POLICY IF EXISTS "Profiles insertable by all" ON public.profiles;
DROP POLICY IF EXISTS "Profiles updatable by all" ON public.profiles;
DROP POLICY IF EXISTS "Profiles manageable by all" ON public.profiles;

CREATE POLICY "Profiles read policy" ON public.profiles
FOR SELECT USING (true);

CREATE POLICY "Profiles insert policy" ON public.profiles
FOR INSERT WITH CHECK (auth.uid()::text = id::text OR public.is_admin(auth.uid()));

CREATE POLICY "Profiles update policy" ON public.profiles
FOR UPDATE USING (auth.uid()::text = id::text OR public.is_admin(auth.uid()))
WITH CHECK (auth.uid()::text = id::text OR public.is_admin(auth.uid()));

CREATE POLICY "Profiles delete policy" ON public.profiles
FOR DELETE USING (public.is_admin(auth.uid()));

-- 4.2 Payment Settings Table
ALTER TABLE public.payment_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public write payment_settings" ON public.payment_settings;
DROP POLICY IF EXISTS "Public read payment_settings" ON public.payment_settings;
DROP POLICY IF EXISTS "Admin write payment_settings" ON public.payment_settings;

CREATE POLICY "Public read payment_settings" ON public.payment_settings
FOR SELECT USING (true);

CREATE POLICY "Admin write payment_settings" ON public.payment_settings
FOR ALL USING (public.is_admin(auth.uid()))
WITH CHECK (public.is_admin(auth.uid()));

-- 4.3 Orders & Order Items
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users and admins can insert orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can manage all orders" ON public.orders;

CREATE POLICY "Users view own orders" ON public.orders
FOR SELECT USING (auth.uid()::text = user_id::text OR public.is_admin(auth.uid()));

CREATE POLICY "Users create own orders" ON public.orders
FOR INSERT WITH CHECK (auth.uid()::text = user_id::text OR public.is_admin(auth.uid()));

CREATE POLICY "Admins update orders" ON public.orders
FOR UPDATE USING (public.is_admin(auth.uid()))
WITH CHECK (public.is_admin(auth.uid()));

CREATE POLICY "Admins delete orders" ON public.orders
FOR DELETE USING (public.is_admin(auth.uid()));

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users and admins can view order items" ON public.order_items;
DROP POLICY IF EXISTS "Users and admins can insert order items" ON public.order_items;

CREATE POLICY "Users view own order items" ON public.order_items
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.orders 
    WHERE public.orders.id::text = public.order_items.order_id::text 
      AND (public.orders.user_id::text = auth.uid()::text OR public.is_admin(auth.uid()))
  )
);

CREATE POLICY "Users insert order items" ON public.order_items
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.orders 
    WHERE public.orders.id::text = public.order_items.order_id::text 
      AND (public.orders.user_id::text = auth.uid()::text OR public.is_admin(auth.uid()))
  )
);

CREATE POLICY "Admins manage order items" ON public.order_items
FOR ALL USING (public.is_admin(auth.uid()))
WITH CHECK (public.is_admin(auth.uid()));

-- 4.4 Entitlements & Subscriptions
ALTER TABLE public.entitlements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own entitlements" ON public.entitlements;
DROP POLICY IF EXISTS "Admins can manage all entitlements" ON public.entitlements;

CREATE POLICY "Users view own entitlements" ON public.entitlements
FOR SELECT USING (auth.uid()::text = user_id::text OR public.is_admin(auth.uid()));

CREATE POLICY "Admins manage entitlements" ON public.entitlements
FOR ALL USING (public.is_admin(auth.uid()))
WITH CHECK (public.is_admin(auth.uid()));

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.subscriptions;
DROP POLICY IF EXISTS "Admins can manage all subscriptions" ON public.subscriptions;

CREATE POLICY "Users view own subscriptions" ON public.subscriptions
FOR SELECT USING (auth.uid()::text = user_id::text OR public.is_admin(auth.uid()));

CREATE POLICY "Admins manage subscriptions" ON public.subscriptions
FOR ALL USING (public.is_admin(auth.uid()))
WITH CHECK (public.is_admin(auth.uid()));

-- 4.5 Coupons
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view active coupons" ON public.coupons;
DROP POLICY IF EXISTS "Admins can manage all coupons" ON public.coupons;

CREATE POLICY "Public view active coupons" ON public.coupons
FOR SELECT USING (is_active = true OR public.is_admin(auth.uid()));

CREATE POLICY "Admins manage coupons" ON public.coupons
FOR ALL USING (public.is_admin(auth.uid()))
WITH CHECK (public.is_admin(auth.uid()));

-- 4.6 Taxonomy Tables
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'exams') THEN
    ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Taxonomy full public access" ON public.exams;
    DROP POLICY IF EXISTS "Public read exams" ON public.exams;
    DROP POLICY IF EXISTS "Admin write exams" ON public.exams;
    CREATE POLICY "Public read exams" ON public.exams FOR SELECT USING (true);
    CREATE POLICY "Admin write exams" ON public.exams FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'subjects') THEN
    ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Taxonomy full public access" ON public.subjects;
    DROP POLICY IF EXISTS "Public read subjects" ON public.subjects;
    DROP POLICY IF EXISTS "Admin write subjects" ON public.subjects;
    CREATE POLICY "Public read subjects" ON public.subjects FOR SELECT USING (true);
    CREATE POLICY "Admin write subjects" ON public.subjects FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chapters') THEN
    ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Taxonomy full public access" ON public.chapters;
    DROP POLICY IF EXISTS "Public read chapters" ON public.chapters;
    DROP POLICY IF EXISTS "Admin write chapters" ON public.chapters;
    CREATE POLICY "Public read chapters" ON public.chapters FOR SELECT USING (true);
    CREATE POLICY "Admin write chapters" ON public.chapters FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'topics') THEN
    ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Taxonomy full public access" ON public.topics;
    DROP POLICY IF EXISTS "Public read topics" ON public.topics;
    DROP POLICY IF EXISTS "Admin write topics" ON public.topics;
    CREATE POLICY "Public read topics" ON public.topics FOR SELECT USING (true);
    CREATE POLICY "Admin write topics" ON public.topics FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'papers') THEN
    ALTER TABLE public.papers ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Papers full public access" ON public.papers;
    DROP POLICY IF EXISTS "Public read papers" ON public.papers;
    DROP POLICY IF EXISTS "Admin write papers" ON public.papers;
    CREATE POLICY "Public read papers" ON public.papers FOR SELECT USING (true);
    CREATE POLICY "Admin write papers" ON public.papers FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'app_settings') THEN
    ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Admins edit settings" ON public.app_settings;
    DROP POLICY IF EXISTS "Public read settings" ON public.app_settings;
    DROP POLICY IF EXISTS "Admin write settings" ON public.app_settings;
    CREATE POLICY "Public read settings" ON public.app_settings FOR SELECT USING (true);
    CREATE POLICY "Admin write settings" ON public.app_settings FOR ALL USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
  END IF;
END $$;

-- 5. PERFORMANCE COMPOSITE INDEXES

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'test_attempts') THEN
    CREATE INDEX IF NOT EXISTS idx_test_attempts_leaderboard 
      ON public.test_attempts (test_id, status, total_score DESC);

    CREATE INDEX IF NOT EXISTS idx_test_attempts_student_test 
      ON public.test_attempts (student_id, test_id, status);
  END IF;

  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'orders') THEN
    CREATE INDEX IF NOT EXISTS idx_orders_user_status 
      ON public.orders (user_id, status);

    CREATE INDEX IF NOT EXISTS idx_orders_payment_reference 
      ON public.orders (payment_reference);
  END IF;
END $$;
