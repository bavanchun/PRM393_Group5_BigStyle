-- ============================================================
-- Migration: Add RLS policies for notifications table
-- and include customer email in order notifications
-- ============================================================

-- 1. Create notifications table if not exists
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL,
  image_url text,
  type text NOT NULL DEFAULT 'order_update',
  data jsonb,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Ensure type constraint exists
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('order_update', 'new_order', 'promotion', 'system', 'new_product'));

-- 3. Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 4. RLS: Users can view own notifications
DROP POLICY IF EXISTS "Users view own notifications" ON public.notifications;
CREATE POLICY "Users view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

-- 5. RLS: Users can update own notifications (mark as read)
DROP POLICY IF EXISTS "Users update own notifications" ON public.notifications;
CREATE POLICY "Users update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- 6. RLS: Service role / SECURITY DEFINER functions can insert
DROP POLICY IF EXISTS "Service can insert notifications" ON public.notifications;
CREATE POLICY "Service can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);

-- 7. Update notify_new_order() trigger to include customer email
CREATE OR REPLACE FUNCTION public.notify_new_order()
RETURNS TRIGGER AS $$
DECLARE
  manager_id uuid;
  customer_name text;
  customer_email text;
  item_count int;
BEGIN
  SELECT DISTINCT p.store_id INTO manager_id
  FROM public.order_items oi
  JOIN public.product_variants pv ON pv.id = oi.variant_id
  JOIN public.products p ON p.id = pv.product_id
  WHERE oi.order_id = NEW.id
  LIMIT 1;

  SELECT full_name, email INTO customer_name, customer_email
  FROM public.profiles
  WHERE id = NEW.user_id;

  SELECT count(*) INTO item_count
  FROM public.order_items
  WHERE order_id = NEW.id;

  IF manager_id IS NOT NULL AND manager_id != NEW.user_id THEN
    INSERT INTO public.notifications (user_id, title, body, type, data)
    VALUES (
      manager_id,
      'Đơn hàng mới từ ' || COALESCE(customer_name, 'Khách hàng'),
      'Có ' || item_count || ' sản phẩm. Tổng: ' || NEW.total || 'đ',
      'new_order',
      jsonb_build_object(
        'order_id', NEW.id,
        'order_number', NEW.order_number,
        'customer_name', customer_name,
        'customer_email', customer_email,
        'total', NEW.total,
        'item_count', item_count
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Ensure trigger exists
DROP TRIGGER IF EXISTS on_new_order ON public.orders;
CREATE TRIGGER on_new_order
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE PROCEDURE public.notify_new_order();
