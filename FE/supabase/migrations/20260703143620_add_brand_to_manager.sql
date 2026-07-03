-- ============================================================
-- Migration: Add brand_name to managers + store_id to products
-- ============================================================

-- 1. Thêm brand_name và brand_logo_url cho profiles (manager)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS brand_name text,
  ADD COLUMN IF NOT EXISTS brand_logo_url text;

-- 2. Thêm store_id vào products để link sản phẩm với thương hiệu
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS store_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 3. Cập nhật RLS cho products: manager chỉ quản lý sản phẩm của mình
DROP POLICY IF EXISTS "Managers can manage products" ON public.products;

CREATE POLICY "Managers manage own products"
  ON public.products FOR ALL
  USING (
    public.is_manager() AND store_id = auth.uid()
  );

-- 4. Cập nhật RLS cho product_variants: chỉ thấy variant của sản phẩm mình quản lý
DROP POLICY IF EXISTS "Managers can manage variants" ON public.product_variants;

CREATE POLICY "Managers manage own variants"
  ON public.product_variants FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.products
      WHERE id = product_id AND store_id = auth.uid()
    )
  );

-- 5. Index cho store_id
CREATE INDEX IF NOT EXISTS idx_products_store ON public.products(store_id);
