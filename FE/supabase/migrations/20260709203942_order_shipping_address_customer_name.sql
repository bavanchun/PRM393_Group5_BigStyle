-- Denormalize customer name into orders.shipping_address so manager order
-- list/detail can show it without any new SELECT privilege on profiles
-- (manager SELECT on profiles was deliberately dropped in
-- 20260707130345_add_admin_role.sql).

drop function if exists public.create_order(jsonb, jsonb, numeric, text, text, text);

-- 1. create_order RPC: inject the caller's full_name into shipping_address
--    when the client didn't already send a 'name' key. Definer context can
--    safely read profiles.full_name for auth.uid() without any new policy.
create function public.create_order(
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
  v_shipping_address jsonb;
  v_full_name  text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if jsonb_array_length(p_items) = 0 then
    raise exception 'Order must have at least one item';
  end if;

  v_shipping_address := p_shipping_address;
  if v_shipping_address->>'name' is null then
    select full_name into v_full_name from public.profiles where id = v_user_id;
    if v_full_name is not null then
      v_shipping_address := v_shipping_address || jsonb_build_object('name', v_full_name);
    end if;
  end if;

  -- Tạo order trước (cần id cho order_items)
  v_order_id := gen_random_uuid();

  insert into public.orders (
    id, user_id, status, shipping_address, shipping_fee,
    subtotal, discount_amount, total, payment_method, notes
  ) values (
    v_order_id, v_user_id, 'pending', v_shipping_address, p_shipping_fee,
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

-- 2. Backfill existing orders lacking a shipping_address.name.
update public.orders o
set shipping_address = o.shipping_address || jsonb_build_object('name', p.full_name)
from public.profiles p
where p.id = o.user_id
  and p.full_name is not null
  and (o.shipping_address->>'name') is null;
