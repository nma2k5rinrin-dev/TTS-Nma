-- Replace recursive sadmin policies with a SECURITY DEFINER helper call.
-- The old profiles policy queried public.profiles from inside public.profiles RLS,
-- which triggers "infinite recursion detected in policy for relation profiles".

DROP POLICY IF EXISTS "Sadmin can view all profiles" ON public.profiles;
CREATE POLICY "Sadmin can view all profiles" ON public.profiles
  FOR SELECT
  TO authenticated
  USING (public.is_current_sadmin());

DROP POLICY IF EXISTS "Sadmin can update all profiles" ON public.profiles;
CREATE POLICY "Sadmin can update all profiles" ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (public.is_current_sadmin())
  WITH CHECK (public.is_current_sadmin());

DROP POLICY IF EXISTS "Sadmin can manage packages" ON public.credit_packages;
CREATE POLICY "Sadmin can manage packages" ON public.credit_packages
  FOR ALL
  TO authenticated
  USING (public.is_current_sadmin())
  WITH CHECK (public.is_current_sadmin());

DROP POLICY IF EXISTS "Sadmin can view all transactions" ON public.credit_transactions;
CREATE POLICY "Sadmin can view all transactions" ON public.credit_transactions
  FOR SELECT
  TO authenticated
  USING (public.is_current_sadmin());

DROP POLICY IF EXISTS "Sadmin can manage API configs" ON public.api_configs;
CREATE POLICY "Sadmin can manage API configs" ON public.api_configs
  FOR ALL
  TO authenticated
  USING (public.is_current_sadmin())
  WITH CHECK (public.is_current_sadmin());

DROP POLICY IF EXISTS "Sadmin can manage pricing" ON public.service_pricing;
CREATE POLICY "Sadmin can manage pricing" ON public.service_pricing
  FOR ALL
  TO authenticated
  USING (public.is_current_sadmin())
  WITH CHECK (public.is_current_sadmin());
