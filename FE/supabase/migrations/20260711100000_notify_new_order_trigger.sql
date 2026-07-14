-- 1. Add 'new_order' to notifications type check
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('order_update', 'new_order', 'promotion', 'system', 'new_product'));

-- 2. Trigger: notify shop manager when a new order is placed
CREATE OR REPLACE FUNCTION public.notify_new_order()
RETURNS TRIGGER AS $$
DECLARE
  manager_id uuid;
  customer_name text;
  item_count int;
BEGIN
  -- Find the manager (store_id) from the first product in this order
  SELECT DISTINCT p.store_id INTO manager_id
  FROM public.order_items oi
  JOIN public.product_variants pv ON pv.id = oi.variant_id
  JOIN public.products p ON p.id = pv.product_id
  WHERE oi.order_id = NEW.id
  LIMIT 1;

  -- Get customer name from profiles
  SELECT full_name INTO customer_name
  FROM public.profiles
  WHERE id = NEW.user_id;

  -- Count items
  SELECT count(*) INTO item_count
  FROM public.order_items
  WHERE order_id = NEW.id;

  -- Only notify if we found a manager and it's not the manager ordering themselves
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
        'total', NEW.total,
        'item_count', item_count
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_new_order
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE PROCEDURE public.notify_new_order();
