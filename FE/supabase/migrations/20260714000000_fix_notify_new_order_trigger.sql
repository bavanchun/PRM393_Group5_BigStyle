-- Fix: move notify_new_order trigger to fire AFTER INSERT on order_items
-- (create_order inserts orders row BEFORE order_items, so the old trigger
-- on orders couldn't find the manager_id)

-- 1. Drop old trigger on orders
DROP TRIGGER IF EXISTS on_new_order ON public.orders;

-- 2. Drop old function
DROP FUNCTION IF EXISTS public.notify_new_order();

-- 3. New trigger function: fires on order_items, creates notification once per order
CREATE OR REPLACE FUNCTION public.notify_new_order()
RETURNS TRIGGER AS $$
DECLARE
  manager_id uuid;
  customer_name text;
  customer_email text;
  item_count int;
  existing_notif uuid;
BEGIN
  -- Only fire once per order: check if notification already exists
  SELECT id INTO existing_notif
  FROM public.notifications
  WHERE data->>'order_id' = NEW.order_id::text
    AND type = 'new_order'
  LIMIT 1;

  IF existing_notif IS NOT NULL THEN
    RETURN NEW;
  END IF;

  -- Find the manager (store_id) from products in this order
  SELECT DISTINCT p.store_id INTO manager_id
  FROM public.order_items oi
  JOIN public.product_variants pv ON pv.id = oi.variant_id
  JOIN public.products p ON p.id = pv.product_id
  WHERE oi.order_id = NEW.order_id
  LIMIT 1;

  -- Get customer info from profiles
  SELECT full_name, email INTO customer_name, customer_email
  FROM public.profiles
  WHERE id = (SELECT user_id FROM public.orders WHERE id = NEW.order_id);

  -- Count items
  SELECT count(*) INTO item_count
  FROM public.order_items
  WHERE order_id = NEW.order_id;

  -- Only notify if we found a manager and it's not the manager ordering themselves
  IF manager_id IS NOT NULL AND manager_id != (
    SELECT user_id FROM public.orders WHERE id = NEW.order_id
  ) THEN
    INSERT INTO public.notifications (user_id, title, body, type, data)
    VALUES (
      manager_id,
      'Đơn hàng mới từ ' || COALESCE(customer_name, 'Khách hàng'),
      'Có ' || item_count || ' sản phẩm. Tổng: ' || (
        SELECT total FROM public.orders WHERE id = NEW.order_id
      ) || 'đ',
      'new_order',
      jsonb_build_object(
        'order_id', NEW.order_id,
        'order_number', (SELECT order_number FROM public.orders WHERE id = NEW.order_id),
        'customer_name', customer_name,
        'customer_email', customer_email,
        'total', (SELECT total FROM public.orders WHERE id = NEW.order_id),
        'item_count', item_count
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create new trigger on order_items
CREATE TRIGGER on_new_order
  AFTER INSERT ON public.order_items
  FOR EACH ROW
  EXECUTE PROCEDURE public.notify_new_order();
