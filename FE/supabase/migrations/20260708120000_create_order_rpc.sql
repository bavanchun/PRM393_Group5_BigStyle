-- ============================================================
-- Migration: Tạo RPC create_order + mở rộng payment_method
-- ============================================================

-- 1. Mở rộng constraint payment_method cho 'bank_transfer'
alter table public.orders
  drop constraint if exists orders_payment_method_check;

alter table public.orders
  add constraint orders_payment_method_check
  check (payment_method in ('cod', 'vnpay', 'momo', 'bank_transfer'));

-- 2. Tạo RPC create_order (SECURITY DEFINER)
create or replace function public.create_order(
  p_items              jsonb,
  p_shipping_address   jsonb,
  p_shipping_fee       numeric default 0,
  p_payment_method     text default 'cod',
  p_notes              text default null,
  p_promo_code         text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id    uuid;
  v_subtotal   numeric(12,0) := 0;
  v_discount   numeric(12,0) := 0;
  v_total      numeric(12,0);
  v_order_id   uuid;
  v_item       jsonb;
  v_variant_id uuid;
  v_qty        int;
  v_price      numeric(12,0);
  v_prod_name  text;
  v_prod_img   text;
  v_size       text;
  v_color      text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if jsonb_array_length(p_items) = 0 then
    raise exception 'Order must have at least one item';
  end if;

  -- Tạo order trước (cần id cho order_items)
  v_order_id := gen_random_uuid();

  insert into public.orders (
    id, user_id, status, shipping_address, shipping_fee,
    subtotal, discount_amount, total, payment_method, notes
  ) values (
    v_order_id, v_user_id, 'pending', p_shipping_address, p_shipping_fee,
    0, 0, 0, p_payment_method, p_notes
  );

  -- Duyệt items, tính subtotal, insert order_items
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_variant_id := (v_item->>'variant_id')::uuid;
    v_qty        := (v_item->>'quantity')::int;

    select
      coalesce(p.sale_price, p.base_price),
      p.name,
      p.images[1],
      pv.size,
      pv.color
    into
      v_price, v_prod_name, v_prod_img, v_size, v_color
    from public.product_variants pv
    join public.products p on p.id = pv.product_id
    where pv.id = v_variant_id;

    if not found then
      raise exception 'Variant % not found', v_variant_id;
    end if;

    v_subtotal := v_subtotal + (v_price * v_qty);

    insert into public.order_items (
      order_id, variant_id, product_name, product_image,
      size, color, quantity, unit_price
    ) values (
      v_order_id, v_variant_id, v_prod_name, v_prod_img,
      v_size, v_color, v_qty, v_price
    );
  end loop;

  -- Cập nhật lại subtotal, total cho order
  if p_promo_code is not null and p_promo_code <> '' then
    v_discount := 0;
  end if;

  v_total := v_subtotal + p_shipping_fee - v_discount;
  if v_total < 0 then
    v_total := 0;
  end if;

  update public.orders set
    subtotal = v_subtotal,
    discount_amount = v_discount,
    total = v_total
  where id = v_order_id;

  -- Trả về order dưới dạng jsonb
  return (
    select row_to_json(o)::jsonb
    from public.orders o
    where o.id = v_order_id
  );
end;
$$;
