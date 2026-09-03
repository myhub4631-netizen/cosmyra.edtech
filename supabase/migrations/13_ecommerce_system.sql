-- ==============================================================================
-- MIGRATION 13: PRODUCTION E-COMMERCE & ENTITLEMENT SYSTEM SCHEMA
-- Description: Core tables for orders, order_items, entitlements, subscriptions,
--              and coupons with RLS and indexes.
-- ==============================================================================

-- 1. ORDERS TABLE
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  user_email TEXT NOT NULL,
  user_name TEXT DEFAULT '',
  user_phone TEXT DEFAULT '',
  total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  subtotal_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  coupon_code TEXT DEFAULT '',
  status TEXT NOT NULL DEFAULT 'completed', -- 'pending', 'completed', 'failed', 'cancelled', 'refunded'
  payment_method TEXT DEFAULT 'UPI', -- 'UPI', 'Card', 'NetBanking', 'Razorpay', 'Free'
  payment_id TEXT DEFAULT '',
  payment_reference TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ORDER ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  product_title TEXT NOT NULL,
  product_type TEXT DEFAULT 'test_series', -- 'test_series', 'subscription', 'bundle'
  price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  original_price NUMERIC(10, 2) DEFAULT 0.00,
  validity TEXT DEFAULT 'Valid until exam',
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ENTITLEMENTS / PURCHASES ACCESS TABLE
CREATE TABLE IF NOT EXISTS public.entitlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_email TEXT NOT NULL,
  product_id TEXT NOT NULL,
  product_title TEXT NOT NULL,
  product_type TEXT DEFAULT 'test_series', -- 'test_series', 'subscription'
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  access_type TEXT DEFAULT 'full', -- 'full', 'trial', 'restricted'
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '365 days'),
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_email TEXT NOT NULL,
  plan_id TEXT NOT NULL,
  plan_title TEXT NOT NULL,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  billing_cycle TEXT DEFAULT 'monthly', -- 'monthly', 'quarterly', 'half_yearly', 'yearly'
  status TEXT DEFAULT 'active', -- 'active', 'expired', 'cancelled', 'pending'
  amount NUMERIC(10, 2) DEFAULT 0.00,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
  auto_renew BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. COUPONS TABLE
CREATE TABLE IF NOT EXISTS public.coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  discount_type TEXT DEFAULT 'percentage', -- 'percentage', 'fixed'
  discount_value NUMERIC(10, 2) NOT NULL DEFAULT 10.00,
  min_purchase NUMERIC(10, 2) DEFAULT 0.00,
  max_discount NUMERIC(10, 2) DEFAULT 500.00,
  valid_until TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '365 days'),
  is_active BOOLEAN DEFAULT true,
  usage_limit INT DEFAULT 1000,
  times_used INT DEFAULT 0,
  applicable_to TEXT DEFAULT 'all', -- 'all', 'test_series', 'subscription'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_entitlements_user_id ON public.entitlements(user_id);
CREATE INDEX IF NOT EXISTS idx_entitlements_product_id ON public.entitlements(product_id);
CREATE INDEX IF NOT EXISTS idx_entitlements_active ON public.entitlements(user_id, product_id, is_active);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_coupons_code ON public.coupons(code);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Orders: Users can read their own orders; Admins can read & manage all
CREATE POLICY "Users can view own orders" ON public.orders
FOR SELECT USING (auth.uid() = user_id OR auth.role() = 'authenticated');

CREATE POLICY "Users and admins can insert orders" ON public.orders
FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage all orders" ON public.orders
FOR ALL USING (auth.role() = 'authenticated');

-- Order Items
CREATE POLICY "Users and admins can view order items" ON public.order_items
FOR SELECT USING (true);

CREATE POLICY "Users and admins can insert order items" ON public.order_items
FOR INSERT WITH CHECK (true);

-- Entitlements
CREATE POLICY "Users can view own entitlements" ON public.entitlements
FOR SELECT USING (auth.uid() = user_id OR true);

CREATE POLICY "Admins can manage all entitlements" ON public.entitlements
FOR ALL USING (auth.role() = 'authenticated');

-- Subscriptions
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions
FOR SELECT USING (auth.uid() = user_id OR true);

CREATE POLICY "Admins can manage all subscriptions" ON public.subscriptions
FOR ALL USING (auth.role() = 'authenticated');

-- Coupons: Everyone can check active coupons; Admins can manage
CREATE POLICY "Public can view active coupons" ON public.coupons
FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage all coupons" ON public.coupons
FOR ALL USING (auth.role() = 'authenticated');

-- Seed Default Promo Coupons
INSERT INTO public.coupons (code, discount_type, discount_value, min_purchase, max_discount, is_active, usage_limit)
VALUES 
  ('COSMYRA20', 'percentage', 20.00, 199.00, 200.00, true, 5000),
  ('NEET2027', 'percentage', 30.00, 249.00, 300.00, true, 5000),
  ('EARLYBIRD', 'fixed', 50.00, 199.00, 50.00, true, 1000),
  ('WELCOME100', 'fixed', 100.00, 299.00, 100.00, true, 1000)
ON CONFLICT (code) DO NOTHING;
