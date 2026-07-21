-- Rollback for 20260711150200_create_order_money_path_hardening.sql.
-- NOT auto-applied (lives outside supabase/migrations/ on purpose). Run
-- manually via the Supabase SQL editor or execute_sql if the hardened
-- create_order needs to be reverted.
--
-- Restores the exact pre-hardening body (client-trusted shipping_fee,
-- discount hard-stubbed to 0, no stock check/decrement) and drops the
-- restock-on-cancel trigger. Does not drop the usage_limit/used_count
-- columns on vouchers — they're additive and harmless even if create_order
-- no longer writes to them.

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

  v_order_id := gen_random_uuid();

  insert into public.orders (
    id, user_id, status, shipping_address, shipping_fee,
    subtotal, discount_amount, total, payment_method, notes
  ) values (
    v_order_id, v_user_id, 'pending', p_shipping_address, p_shipping_fee,
    0, 0, 0, p_payment_method, p_notes
  );

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

  return (
    select row_to_json(o)::jsonb
    from public.orders o
    where o.id = v_order_id
  );
end;
$$;

drop trigger if exists trg_restock_on_order_cancel on public.orders;
drop function if exists public.restock_on_order_cancel();
