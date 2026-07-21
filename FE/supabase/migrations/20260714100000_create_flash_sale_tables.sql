-- ============================================================
-- Flash Sale tables + auto-generator function
-- ============================================================

CREATE TABLE IF NOT EXISTS public.flash_sale_campaigns (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL DEFAULT 'FLASH SALE',
  start_at    TIMESTAMPTZ NOT NULL,
  end_at      TIMESTAMPTZ NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT  fk_campaign_time CHECK (end_at > start_at)
);

CREATE TABLE IF NOT EXISTS public.flash_sale_products (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id     UUID NOT NULL REFERENCES public.flash_sale_campaigns(id) ON DELETE CASCADE,
  product_id      UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  sale_price      INTEGER NOT NULL,
  original_price  INTEGER NOT NULL,
  stock_qty       INTEGER NOT NULL DEFAULT 0,
  sold_qty        INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT      fk_sale_less_than_original CHECK (sale_price > 0 AND sale_price < original_price)
);

CREATE INDEX idx_flash_sale_products_campaign ON public.flash_sale_products(campaign_id);
CREATE INDEX idx_flash_sale_campaigns_active ON public.flash_sale_campaigns(is_active, start_at, end_at);

-- ============================================================
-- RPC: Lấy campaign đang hoạt động + sản phẩm
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_current_flash_sale()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'campaign', to_jsonb(c),
    'products', coalesce(jsonb_agg(
      jsonb_build_object(
        'id',           fp.id,
        'product_id',   p.id,
        'name',         p.name,
        'images',       p.images,
        'sale_price',   fp.sale_price,
        'original_price', fp.original_price,
        'stock_qty',    fp.stock_qty,
        'sold_qty',     fp.sold_qty,
        'sizes',        coalesce(
          (SELECT array_agg(DISTINCT pv.size ORDER BY pv.size)
           FROM product_variants pv WHERE pv.product_id = p.id),
          '{}'::TEXT[]
        )
      )
      ORDER BY fp.sold_qty DESC
    ), '[]'::jsonb)
  )
  INTO result
  FROM flash_sale_campaigns c
  JOIN flash_sale_products fp ON fp.campaign_id = c.id
  JOIN products p ON p.id = fp.product_id
  WHERE c.is_active = true
    AND c.start_at <= now()
    AND c.end_at > now()
  GROUP BY c.id;

  RETURN result;
END;
$$;

-- ============================================================
-- RPC: Cập nhật sold_qty khi có đơn hàng (gọi từ Node.js cron / webhook)
-- ============================================================
CREATE OR REPLACE FUNCTION public.increment_flash_sale_sold(
  p_product_id UUID,
  p_qty INTEGER DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.flash_sale_products
  SET sold_qty = sold_qty + p_qty
  WHERE product_id = p_product_id
    AND campaign_id IN (
      SELECT id FROM public.flash_sale_campaigns
      WHERE is_active = true AND start_at <= now() AND end_at > now()
    );
END;
$$;

-- ============================================================
-- RPC: Tự động sinh campaign (gọi từ Node.js cron)
-- ============================================================
CREATE OR REPLACE FUNCTION public.auto_generate_flash_sale(
  p_duration_minutes INTEGER DEFAULT 240,
  p_product_count INTEGER DEFAULT 6,
  p_discount_min_percent INTEGER DEFAULT 30,
  p_discount_max_percent INTEGER DEFAULT 50
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_campaign_id UUID;
  v_product RECORD;
  v_discount_percent INTEGER;
  v_sale_price INTEGER;
  v_stock_qty INTEGER;
BEGIN
  -- Tạo campaign
  INSERT INTO public.flash_sale_campaigns (title, start_at, end_at)
  VALUES (
    'FLASH SALE ' || to_char(now(), 'HH24:MI dd/mm'),
    now(),
    now() + (p_duration_minutes || ' minutes')::INTERVAL
  )
  RETURNING id INTO v_campaign_id;

  -- Chọn sản phẩm: ưu tiên tồn kho nhiều, chưa từng flash sale gần đây
  FOR v_product IN
    SELECT
      p.id,
      p.base_price,
      coalesce(p.sale_price, p.base_price) AS effective_price,
      coalesce(sum(pv.stock_qty), 0) AS total_stock
    FROM products p
    LEFT JOIN product_variants pv ON pv.product_id = p.id
    WHERE p.is_active = true
      AND p.base_price > 0
      AND p.id NOT IN (
        SELECT fsp.product_id FROM flash_sale_products fsp
        JOIN flash_sale_campaigns fsc ON fsc.id = fsp.campaign_id
        WHERE fsc.is_active = true AND fsc.start_at > now() - INTERVAL '7 days'
      )
    GROUP BY p.id
    HAVING coalesce(sum(pv.stock_qty), 0) >= 10
    ORDER BY random() * coalesce(sum(pv.stock_qty), 0) DESC
    LIMIT p_product_count
  LOOP
    -- Random discount %
    v_discount_percent := p_discount_min_percent +
      floor(random() * (p_discount_max_percent - p_discount_min_percent + 1))::INTEGER;
    v_sale_price := (v_product.effective_price * (100 - v_discount_percent) / 100)::INTEGER;
    -- Làm tròn xuống 000đ
    v_sale_price := (v_sale_price / 1000) * 1000;
    IF v_sale_price < 50000 THEN v_sale_price := 50000; END IF;

    v_stock_qty := LEAST(v_product.total_stock, 100);

    INSERT INTO public.flash_sale_products (
      campaign_id, product_id, sale_price, original_price, stock_qty, sold_qty
    ) VALUES (
      v_campaign_id, v_product.id, v_sale_price, v_product.effective_price, v_stock_qty, 0
    );
  END LOOP;

  -- Xoá campaign nếu không có sản phẩm nào
  IF NOT EXISTS (SELECT 1 FROM flash_sale_products WHERE campaign_id = v_campaign_id) THEN
    DELETE FROM flash_sale_campaigns WHERE id = v_campaign_id;
    RETURN NULL;
  END IF;

  RETURN v_campaign_id;
END;
$$;

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE public.flash_sale_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flash_sale_products ENABLE ROW LEVEL SECURITY;

-- Ai cũng đọc được campaign đang active
CREATE POLICY "select_active_campaigns"
  ON public.flash_sale_campaigns FOR SELECT
  USING (is_active = true AND start_at <= now() AND end_at > now());

CREATE POLICY "select_active_products"
  ON public.flash_sale_products FOR SELECT
  USING (
    campaign_id IN (
      SELECT id FROM public.flash_sale_campaigns
      WHERE is_active = true AND start_at <= now() AND end_at > now()
    )
  );

-- Chỉ service_role mới được ghi
CREATE POLICY "service_role_write_campaigns"
  ON public.flash_sale_campaigns
  FOR ALL
  USING (false)
  WITH CHECK (false);

CREATE POLICY "service_role_write_products"
  ON public.flash_sale_products
  FOR ALL
  USING (false)
  WITH CHECK (false);

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.flash_sale_campaigns TO anon, authenticated;
GRANT SELECT ON public.flash_sale_products TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_flash_sale TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.auto_generate_flash_sale TO service_role;
GRANT EXECUTE ON FUNCTION public.increment_flash_sale_sold TO service_role;
