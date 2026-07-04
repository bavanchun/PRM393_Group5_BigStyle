-- ============================================================
-- Sold count: auto-increment on delivery + seed test data
-- ============================================================

-- Thêm cột sold_count
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS sold_count int DEFAULT 0 CHECK (sold_count >= 0);

-- Trigger function: tự tăng sold_count khi đơn hàng chuyển sang 'delivered'
CREATE OR REPLACE FUNCTION public.update_sold_count()
RETURNS trigger AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM 'delivered' AND NEW.status = 'delivered' THEN
    UPDATE public.products SET
      sold_count = sold_count + sub.total_qty,
      updated_at = now()
    FROM (
      SELECT pv.product_id, SUM(oi.quantity) AS total_qty
      FROM public.order_items oi
      JOIN public.product_variants pv ON pv.id = oi.variant_id
      WHERE oi.order_id = NEW.id
      GROUP BY pv.product_id
    ) sub
    WHERE products.id = sub.product_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_order_delivered ON public.orders;
CREATE TRIGGER on_order_delivered
  AFTER UPDATE ON public.orders
  FOR EACH ROW EXECUTE PROCEDURE public.update_sold_count();

-- Seed sold_count cho test
UPDATE public.products SET sold_count = 523 WHERE name = 'Túi Tote Canvas Local Brand';
UPDATE public.products SET sold_count = 458 WHERE name = 'Áo Thun Oversize Cotton Basic';
UPDATE public.products SET sold_count = 342 WHERE name = 'Đầm Maxi Boho Tự Do';
UPDATE public.products SET sold_count = 298 WHERE name = 'Set Sơ Mi + Quần Lửng Kẻ Sọc';
UPDATE public.products SET sold_count = 276 WHERE name = 'Quần Jean Skinny Bigsize Cao Cổ';
UPDATE public.products SET sold_count = 215 WHERE name = 'Áo Kiểu Bèo Ngực Sang Trọng';
UPDATE public.products SET sold_count = 201 WHERE name = 'Thắt Lưng Vải Phối Màu';
UPDATE public.products SET sold_count = 183 WHERE name = 'Áo Sơ Mi Linen Mát Mẻ';
UPDATE public.products SET sold_count = 167 WHERE name = 'Set Áo Croptop + Quần Ống Rộng';
UPDATE public.products SET sold_count = 134 WHERE name = 'Quần Palazzo Lưng Thun Thoải Mái';
UPDATE public.products SET sold_count = 128 WHERE name = 'Đầm Hoa Nhí Tay Bồng';
UPDATE public.products SET sold_count = 91  WHERE name = 'Đầm Sơ Mi Kẻ Sọc Casual';
UPDATE public.products SET sold_count = 89  WHERE name = 'Quần Culottes Kẻ Caro Vintage';
UPDATE public.products SET sold_count = 67  WHERE name = 'Đầm Wrap Tôn Dáng Đồng Hồ Cát';
UPDATE public.products SET sold_count = 56  WHERE name = 'Áo Blazer Nữ Dáng Dài';
