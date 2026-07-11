-- create_order money-path hardening:
--   1. Voucher discount was hard-stubbed to 0 — customers saw a discount
--      preview but were charged full price. Now re-validates the voucher
--      under a row lock and applies the real discount.
--   2. Nothing decremented stock — orders could oversell past stock_qty.
--      Now locks + checks + decrements each variant inside the same tx.
--   3. shipping_fee was trusted verbatim from the client. Now forced to
--      the server-side flat rate.
-- All three share one function body, so they ship together — replacing
-- only one of them would silently drop the other two on the next deploy.

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
  v_shipping   numeric(12,0) := 30000; -- server-authoritative flat rate; p_shipping_fee is ignored
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
  v_stock_qty  int;
  v_voucher    public.vouchers%rowtype;
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
    v_order_id, v_user_id, 'pending', p_shipping_address, v_shipping,
    0, 0, 0, p_payment_method, p_notes
  );

  -- Items are locked/processed in variant_id order (not client-submitted
  -- order) so two concurrent orders sharing variants always take row locks
  -- in the same sequence, avoiding lock-order deadlocks.
  for v_item in
    select value from jsonb_array_elements(p_items) as t(value)
    order by (value->>'variant_id')::uuid
  loop
    v_variant_id := (v_item->>'variant_id')::uuid;
    v_qty        := (v_item->>'quantity')::int;

    select
      coalesce(p.sale_price, p.base_price),
      p.name,
      p.images[1],
      pv.size,
      pv.color,
      pv.stock_qty
    into
      v_price, v_prod_name, v_prod_img, v_size, v_color, v_stock_qty
    from public.product_variants pv
    join public.products p on p.id = pv.product_id
    where pv.id = v_variant_id
    for update of pv;

    if not found then
      raise exception 'Variant % not found', v_variant_id;
    end if;

    if v_stock_qty < v_qty then
      raise exception 'Sản phẩm % đã hết hàng (còn lại % sản phẩm)', v_prod_name, v_stock_qty;
    end if;

    update public.product_variants
       set stock_qty = stock_qty - v_qty
     where id = v_variant_id;

    v_subtotal := v_subtotal + (v_price * v_qty);

    insert into public.order_items (
      order_id, variant_id, product_name, product_image,
      size, color, quantity, unit_price
    ) values (
      v_order_id, v_variant_id, v_prod_name, v_prod_img,
      v_size, v_color, v_qty, v_price
    );
  end loop;

  -- Re-validate the voucher under a row lock (the validate_voucher RPC used
  -- for the checkout preview does not lock) so two concurrent orders can't
  -- both pass the usage_limit check for the last redemption, and increment
  -- used_count atomically in the same transaction as the order.
  if p_promo_code is not null and p_promo_code <> '' then
    select * into v_voucher
      from public.vouchers
     where upper(code) = upper(trim(p_promo_code))
       and is_active = true
       and (expires_at is null or expires_at > now())
     for update;

    if not found then
      raise exception 'Mã giảm giá không hợp lệ hoặc đã hết hạn';
    end if;

    if v_subtotal < v_voucher.min_order_amount then
      raise exception 'Đơn hàng chưa đạt giá trị tối thiểu để dùng mã';
    end if;

    if v_voucher.usage_limit is not null and v_voucher.used_count >= v_voucher.usage_limit then
      raise exception 'Mã giảm giá đã hết lượt sử dụng';
    end if;

    if v_voucher.type = 'percentage' then
      v_discount := round(v_subtotal * v_voucher.value / 100);
      v_discount := least(v_discount, coalesce(v_voucher.max_discount, v_discount));
    else
      v_discount := v_voucher.value;
    end if;

    update public.vouchers set used_count = used_count + 1 where id = v_voucher.id;
  end if;

  -- Never NULL, never negative, never larger than the subtotal it discounts
  -- (a discount must not eat into shipping).
  v_discount := greatest(least(coalesce(v_discount, 0), v_subtotal), 0);

  v_total := v_subtotal + v_shipping - v_discount;
  if v_total < 0 then
    v_total := 0;
  end if;

  update public.orders set
    subtotal = v_subtotal,
    shipping_fee = v_shipping,
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

-- Restocking on cancel. A trigger (rather than duplicating the restock
-- logic inside cancel_my_order) covers every path that sets an order to
-- 'cancelled' — the customer RPC and the manager's direct table update in
-- OrderService.updateOrderStatus — with one implementation.
create or replace function public.restock_on_order_cancel()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'cancelled' and old.status is distinct from 'cancelled' then
    update public.product_variants pv
       set stock_qty = pv.stock_qty + oi.quantity
      from public.order_items oi
     where oi.order_id = new.id
       and pv.id = oi.variant_id;
  end if;
  return new;
end;
$$;

create or replace trigger trg_restock_on_order_cancel
  after update of status on public.orders
  for each row
  execute function public.restock_on_order_cancel();
