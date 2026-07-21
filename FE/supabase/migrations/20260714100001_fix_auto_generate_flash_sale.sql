-- Fix: column alias "total_stock" không dùng được trong ORDER BY của FOR loop
DROP FUNCTION IF EXISTS public.auto_generate_flash_sale;

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
  INSERT INTO public.flash_sale_campaigns (title, start_at, end_at)
  VALUES (
    'FLASH SALE ' || to_char(now(), 'HH24:MI dd/mm'),
    now(),
    now() + (p_duration_minutes || ' minutes')::INTERVAL
  )
  RETURNING id INTO v_campaign_id;

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
    v_discount_percent := p_discount_min_percent +
      floor(random() * (p_discount_max_percent - p_discount_min_percent + 1))::INTEGER;
    v_sale_price := (v_product.effective_price * (100 - v_discount_percent) / 100)::INTEGER;
    v_sale_price := (v_sale_price / 1000) * 1000;
    IF v_sale_price < 50000 THEN v_sale_price := 50000; END IF;

    v_stock_qty := LEAST(v_product.total_stock, 100);

    INSERT INTO public.flash_sale_products (
      campaign_id, product_id, sale_price, original_price, stock_qty, sold_qty
    ) VALUES (
      v_campaign_id, v_product.id, v_sale_price, v_product.effective_price, v_stock_qty, 0
    );
  END LOOP;

  IF NOT EXISTS (SELECT 1 FROM flash_sale_products WHERE campaign_id = v_campaign_id) THEN
    DELETE FROM flash_sale_campaigns WHERE id = v_campaign_id;
    RETURN NULL;
  END IF;

  RETURN v_campaign_id;
END;
$$;
