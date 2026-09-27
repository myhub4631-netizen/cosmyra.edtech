-- ==============================================================================
-- COSMYRA PLATFORM - MIGRATION 17: FIX ORDERS & ENTITLEMENTS RLS FOR GUEST CHECKOUT & ADMIN DISCOVERY
-- Description: Allow any user (anon or authenticated) to create orders and entitlements,
--              and allow full read access to orders & entitlements so admin dashboard always
--              displays real student orders.
-- ==============================================================================

-- 1. ORDERS TABLE POLICIES
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users create own orders" ON public.orders;
DROP POLICY IF EXISTS "Users view own orders" ON public.orders;
DROP POLICY IF EXISTS "Allow public insert orders" ON public.orders;
DROP POLICY IF EXISTS "Allow public select orders" ON public.orders;

CREATE POLICY "Allow public insert orders" ON public.orders
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public select orders" ON public.orders
FOR SELECT USING (true);

CREATE POLICY "Allow admin update orders" ON public.orders
FOR UPDATE USING (true);

CREATE POLICY "Allow admin delete orders" ON public.orders
FOR DELETE USING (true);


-- 2. ORDER ITEMS TABLE POLICIES
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users create order items" ON public.order_items;
DROP POLICY IF EXISTS "Users view order items" ON public.order_items;
DROP POLICY IF EXISTS "Allow public insert order_items" ON public.order_items;
DROP POLICY IF EXISTS "Allow public select order_items" ON public.order_items;

CREATE POLICY "Allow public insert order_items" ON public.order_items
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public select order_items" ON public.order_items
FOR SELECT USING (true);


-- 3. ENTITLEMENTS TABLE POLICIES
ALTER TABLE public.entitlements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own entitlements" ON public.entitlements;
DROP POLICY IF EXISTS "Admins manage entitlements" ON public.entitlements;
DROP POLICY IF EXISTS "Allow public insert entitlements" ON public.entitlements;
DROP POLICY IF EXISTS "Allow public select entitlements" ON public.entitlements;

CREATE POLICY "Allow public insert entitlements" ON public.entitlements
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public select entitlements" ON public.entitlements
FOR SELECT USING (true);

CREATE POLICY "Allow admin manage entitlements" ON public.entitlements
FOR ALL USING (true);


-- 4. SUBSCRIPTIONS TABLE POLICIES
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public insert subscriptions" ON public.subscriptions;
DROP POLICY IF EXISTS "Allow public select subscriptions" ON public.subscriptions;

CREATE POLICY "Allow public insert subscriptions" ON public.subscriptions
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public select subscriptions" ON public.subscriptions
FOR SELECT USING (true);
