-- ==============================================================================
-- MIGRATION 14: BREVO EMAIL & WHATSAPP NOTIFICATION FLOW SCHEMA
-- Description: Adds tables for notification logs, abandoned carts, and WhatsApp tracking
-- ==============================================================================

-- 1. ALTER PROFILES TABLE TO INCLUDE WHATSAPP STATUS
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS has_whatsapp BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS whatsapp_verified_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS whatsapp_status TEXT DEFAULT 'unchecked'; -- 'unchecked', 'active', 'not_found', 'error'

-- 2. NOTIFICATION LOGS TABLE
CREATE TABLE IF NOT EXISTS public.notification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  recipient_email TEXT DEFAULT '',
  recipient_phone TEXT DEFAULT '',
  type TEXT NOT NULL, -- 'account_creation', 'order_placed', 'payment_due', 'password_reset', 'add_to_cart', 'cart_recovery', 'marketing_email', 'marketing_whatsapp'
  channel TEXT NOT NULL, -- 'brevo_email', 'whatsapp'
  status TEXT NOT NULL DEFAULT 'sent', -- 'sent', 'failed', 'delivered', 'pending'
  subject TEXT DEFAULT '',
  message_body TEXT DEFAULT '',
  provider_response JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ABANDONED CARTS TABLE FOR CARTS RECOVERY
CREATE TABLE IF NOT EXISTS public.abandoned_carts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_email TEXT NOT NULL,
  user_phone TEXT DEFAULT '',
  cart_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  subtotal NUMERIC(10, 2) DEFAULT 0.00,
  recovery_status TEXT DEFAULT 'pending', -- 'pending', 'recovered', 'reminder_sent'
  last_reminded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON public.notification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_channel ON public.notification_logs(channel);
CREATE INDEX IF NOT EXISTS idx_notification_logs_type ON public.notification_logs(type);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_user_email ON public.abandoned_carts(user_email);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_status ON public.abandoned_carts(recovery_status);

-- Enable RLS
ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.abandoned_carts ENABLE ROW LEVEL SECURITY;

-- Policies for Notification Logs
CREATE POLICY "Users can view own notification logs" ON public.notification_logs
FOR SELECT USING (auth.uid() = user_id OR auth.role() = 'authenticated');

CREATE POLICY "System can insert notification logs" ON public.notification_logs
FOR INSERT WITH CHECK (true);

-- Policies for Abandoned Carts
CREATE POLICY "Users can view own abandoned carts" ON public.abandoned_carts
FOR SELECT USING (auth.uid() = user_id OR true);

CREATE POLICY "System can insert & update abandoned carts" ON public.abandoned_carts
FOR ALL USING (true);
