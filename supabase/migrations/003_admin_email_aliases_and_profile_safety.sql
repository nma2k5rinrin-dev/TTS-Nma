-- Normalize Gmail aliases for the owner account and keep profile privilege fields server-side.

CREATE OR REPLACE FUNCTION public.normalize_auth_email(input_email TEXT)
RETURNS TEXT AS $$
  SELECT CASE
    WHEN split_part(lower(coalesce(input_email, '')), '@', 2) IN ('gmail.com', 'googlemail.com')
      THEN replace(split_part(lower(coalesce(input_email, '')), '@', 1), '.', '') || '@gmail.com'
    ELSE lower(coalesce(input_email, ''))
  END;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.is_sadmin_email(input_email TEXT)
RETURNS BOOLEAN AS $$
  SELECT public.normalize_auth_email(input_email) = 'nma2k5rinrin@gmail.com';
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.is_current_sadmin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'sadmin'
      AND coalesce(is_banned, false) = false
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, role, credits)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      split_part(NEW.email, '@', 1)
    ),
    CASE WHEN public.is_sadmin_email(NEW.email) THEN 'sadmin' ELSE 'user' END,
    CASE WHEN public.is_sadmin_email(NEW.email) THEN 99999 ELSE 0 END
  )
  ON CONFLICT (id) DO UPDATE
  SET
    email = EXCLUDED.email,
    display_name = COALESCE(public.profiles.display_name, EXCLUDED.display_name),
    role = CASE WHEN public.is_sadmin_email(EXCLUDED.email) THEN 'sadmin' ELSE public.profiles.role END,
    credits = CASE
      WHEN public.is_sadmin_email(EXCLUDED.email) THEN greatest(public.profiles.credits, 99999)
      ELSE public.profiles.credits
    END,
    updated_at = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.protect_profile_privilege_fields()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();

  IF auth.uid() = OLD.id AND NOT public.is_current_sadmin() THEN
    NEW.email = OLD.email;
    NEW.role = OLD.role;
    NEW.credits = OLD.credits;
    NEW.is_banned = OLD.is_banned;
    NEW.created_at = OLD.created_at;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.enforce_profile_insert_defaults()
RETURNS TRIGGER AS $$
BEGIN
  NEW.role = CASE WHEN public.is_sadmin_email(NEW.email) THEN 'sadmin' ELSE 'user' END;
  NEW.credits = CASE WHEN public.is_sadmin_email(NEW.email) THEN greatest(coalesce(NEW.credits, 0), 99999) ELSE 0 END;
  NEW.created_at = coalesce(NEW.created_at, now());
  NEW.updated_at = coalesce(NEW.updated_at, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS enforce_profile_insert_defaults ON public.profiles;
CREATE TRIGGER enforce_profile_insert_defaults
  BEFORE INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_profile_insert_defaults();

DROP TRIGGER IF EXISTS protect_profile_privilege_fields ON public.profiles;
CREATE TRIGGER protect_profile_privilege_fields
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_privilege_fields();

INSERT INTO public.profiles (id, email, display_name, role, credits)
SELECT
  u.id,
  u.email,
  COALESCE(
    u.raw_user_meta_data->>'display_name',
    u.raw_user_meta_data->>'full_name',
    split_part(u.email, '@', 1)
  ),
  CASE WHEN public.is_sadmin_email(u.email) THEN 'sadmin' ELSE 'user' END,
  CASE WHEN public.is_sadmin_email(u.email) THEN 99999 ELSE 0 END
FROM auth.users u
WHERE public.is_sadmin_email(u.email)
ON CONFLICT (id) DO UPDATE
SET
  email = EXCLUDED.email,
  display_name = COALESCE(public.profiles.display_name, EXCLUDED.display_name),
  role = 'sadmin',
  credits = greatest(public.profiles.credits, 99999),
  updated_at = now();
