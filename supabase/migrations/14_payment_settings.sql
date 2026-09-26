-- ==============================================================================
-- MIGRATION 14: PAYMENT SETTINGS & GATEWAY CONFIGURATION
-- Description: Store admin-configured payment gateways (UPI Pay, Cashfree PG)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.payment_settings (
  id TEXT PRIMARY KEY DEFAULT 'default',
  upi_active BOOLEAN DEFAULT true,
  upi_id TEXT DEFAULT '1mdollar2027@okicici',
  upi_payee_name TEXT DEFAULT 'Cosmyra Edu Platform',
  cashfree_active BOOLEAN DEFAULT true,
  cashfree_app_id TEXT DEFAULT '',
  cashfree_secret_key TEXT DEFAULT '',
  cashfree_environment TEXT DEFAULT 'TEST',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.payment_settings ENABLE ROW LEVEL SECURITY;

-- Public can read payment settings (to render active checkout options)
CREATE POLICY "Public read payment_settings" ON public.payment_settings
FOR SELECT USING (true);

-- Admins can update payment settings
CREATE POLICY "Admin write payment_settings" ON public.payment_settings
FOR ALL USING (auth.role() = 'authenticated');

-- Insert default payment settings
INSERT INTO public.payment_settings (id, upi_active, upi_id, upi_payee_name, cashfree_active, cashfree_app_id, cashfree_secret_key, cashfree_environment)
VALUES ('default', true, '1mdollar2027@okicici', 'Cosmyra Edu Platform', true, '', '', 'TEST')
ON CONFLICT (id) DO NOTHING;
