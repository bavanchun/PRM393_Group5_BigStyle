-- ============================================================
-- Migration: Add admin role + admin RLS policies
-- ============================================================

-- 1. Cập nhật role check constraint để thêm 'admin'
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('customer', 'manager', 'admin'));

-- 2. Function check admin role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- 3. Admin có thể xem tất cả profiles
DROP POLICY IF EXISTS "Managers can view all profiles" ON public.profiles;

CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (public.is_admin());

-- 4. Admin có thể cập nhật tất cả profiles (quản lý role, brand)
CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  USING (public.is_admin());

-- 5. Admin có thể quản lý tất cả products (bypass store_id check)
CREATE POLICY "Admins manage all products"
  ON public.products FOR ALL
  USING (public.is_admin());

-- 6. Admin có thể quản lý tất cả product_variants
CREATE POLICY "Admins manage all variants"
  ON public.product_variants FOR ALL
  USING (public.is_admin());

-- 7. Admin có thể quản lý tất cả categories
DROP POLICY IF EXISTS "Managers can manage categories" ON public.categories;

CREATE POLICY "Admins manage all categories"
  ON public.categories FOR ALL
  USING (public.is_admin());

-- 8. Admin xem tất cả orders
CREATE POLICY "Admins see all orders"
  ON public.orders FOR ALL
  USING (public.is_admin());

-- 9. Admin xem tất cả order_items
CREATE POLICY "Admins see all order items"
  ON public.order_items FOR ALL
  USING (public.is_admin());

-- 10. Gán admin cho user cụ thể (thay email bằng email admin của bạn)
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@bigstyle.vn';
