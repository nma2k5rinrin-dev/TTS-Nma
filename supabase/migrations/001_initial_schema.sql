-- =============================================
-- TTS Nma - Database Schema
-- =============================================

-- 1. Profiles (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'sadmin')),
  credits BIGINT NOT NULL DEFAULT 0,
  avatar_url TEXT,
  is_banned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Credit Packages
CREATE TABLE IF NOT EXISTS public.credit_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price_vnd BIGINT NOT NULL,
  credits BIGINT NOT NULL,
  bonus_percent INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Credit Transactions
CREATE TABLE IF NOT EXISTS public.credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('topup', 'usage', 'refund', 'admin_grant')),
  amount BIGINT NOT NULL,
  balance_after BIGINT NOT NULL,
  service TEXT CHECK (service IN ('tts', 'voice_clone', 'stt', NULL)),
  description TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TTS History
CREATE TABLE IF NOT EXISTS public.tts_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  text_input TEXT NOT NULL,
  char_count INT NOT NULL,
  voice_id TEXT NOT NULL,
  voice_name TEXT,
  country TEXT,
  rate FLOAT DEFAULT 1.0,
  pitch FLOAT DEFAULT 0.0,
  audio_url TEXT,
  credits_used BIGINT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Voice Clones
CREATE TABLE IF NOT EXISTS public.voice_clones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  sample_audio_url TEXT NOT NULL,
  clone_voice_id TEXT,
  status TEXT DEFAULT 'processing' CHECK (status IN ('processing', 'ready', 'failed')),
  credits_used BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. STT History
CREATE TABLE IF NOT EXISTS public.stt_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  audio_url TEXT NOT NULL,
  duration_seconds INT,
  transcribed_text TEXT,
  language TEXT DEFAULT 'vi',
  credits_used BIGINT NOT NULL,
  status TEXT DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. API Configurations (sadmin managed)
CREATE TABLE IF NOT EXISTS public.api_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL,
  service TEXT NOT NULL CHECK (service IN ('tts', 'voice_clone', 'stt')),
  api_key TEXT NOT NULL,
  base_url TEXT,
  config JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT TRUE,
  updated_by UUID REFERENCES public.profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Service Pricing (sadmin configurable)
CREATE TABLE IF NOT EXISTS public.service_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service TEXT NOT NULL CHECK (service IN ('tts_basic', 'tts_premium', 'voice_clone_create', 'voice_clone_usage', 'stt')),
  unit TEXT NOT NULL,
  price_credits BIGINT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- Row Level Security
-- =============================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tts_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_clones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stt_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_pricing ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read own, sadmin can read all
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Sadmin can view all profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'sadmin')
  );
CREATE POLICY "Sadmin can update all profiles" ON public.profiles
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'sadmin')
  );

-- Credit packages: everyone can read, sadmin can manage
CREATE POLICY "Anyone can view active packages" ON public.credit_packages
  FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Sadmin can manage packages" ON public.credit_packages
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'sadmin')
  );

-- Credit transactions: users see own, sadmin sees all
CREATE POLICY "Users can view own transactions" ON public.credit_transactions
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Sadmin can view all transactions" ON public.credit_transactions
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'sadmin')
  );

-- TTS history: users see own
CREATE POLICY "Users can manage own TTS history" ON public.tts_history
  FOR ALL USING (user_id = auth.uid());

-- Voice clones: users see own
CREATE POLICY "Users can manage own voice clones" ON public.voice_clones
  FOR ALL USING (user_id = auth.uid());

-- STT history: users see own
CREATE POLICY "Users can manage own STT history" ON public.stt_history
  FOR ALL USING (user_id = auth.uid());

-- API configs: sadmin only
CREATE POLICY "Sadmin can manage API configs" ON public.api_configs
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'sadmin')
  );

-- Service pricing: anyone can read, sadmin can manage
CREATE POLICY "Anyone can view pricing" ON public.service_pricing
  FOR SELECT USING (TRUE);
CREATE POLICY "Sadmin can manage pricing" ON public.service_pricing
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'sadmin')
  );

-- =============================================
-- Auto-create profile on signup trigger
-- =============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, role, credits)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    'user',
    0
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- Deduct credits function (atomic)
-- =============================================

CREATE OR REPLACE FUNCTION public.deduct_credits(
  p_user_id UUID,
  p_amount BIGINT,
  p_service TEXT,
  p_description TEXT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
  v_current_credits BIGINT;
  v_new_balance BIGINT;
BEGIN
  SELECT credits INTO v_current_credits
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF v_current_credits < p_amount THEN
    RAISE EXCEPTION 'Insufficient credits. Current: %, Required: %', v_current_credits, p_amount;
  END IF;

  v_new_balance := v_current_credits - p_amount;

  UPDATE public.profiles SET credits = v_new_balance, updated_at = NOW()
  WHERE id = p_user_id;

  INSERT INTO public.credit_transactions (user_id, type, amount, balance_after, service, description)
  VALUES (p_user_id, 'usage', -p_amount, v_new_balance, p_service, p_description);

  RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- Seed default pricing
-- =============================================

INSERT INTO public.service_pricing (service, unit, price_credits) VALUES
  ('tts_basic', 'per_100_chars', 1),
  ('tts_premium', 'per_100_chars', 3),
  ('voice_clone_create', 'per_clone', 5000),
  ('voice_clone_usage', 'per_100_chars', 5),
  ('stt', 'per_minute', 50)
ON CONFLICT DO NOTHING;

-- Seed default credit packages
INSERT INTO public.credit_packages (name, price_vnd, credits, bonus_percent, sort_order) VALUES
  ('Starter', 20000, 20000, 0, 1),
  ('Basic', 50000, 55000, 10, 2),
  ('Standard', 100000, 115000, 15, 3),
  ('Premium', 200000, 240000, 20, 4),
  ('Pro', 500000, 625000, 25, 5),
  ('Enterprise', 1000000, 1300000, 30, 6)
ON CONFLICT DO NOTHING;
