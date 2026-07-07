-- ============================================================================
-- BigStyle — Demo accounts & orders seed
-- Run in Supabase → SQL Editor (service role bypasses RLS). Idempotent-ish:
-- re-running inserts more demo orders; delete them first if you want a reset.
--
-- PREREQUISITE (do this in the APP first — SQL cannot create auth users/OTP):
--   1. Sign up 1 manager email  + 2 customer emails via the app login screen
--      (each needs a real inbox to receive the OTP).
--   2. Then run STEP 1 (promote manager) and STEP 2 (seed orders) below.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 — Promote the dedicated manager account
-- Edit the email, then run. Verify it flips to /manager on next app launch.
-- ---------------------------------------------------------------------------
update public.profiles
set role = 'manager'
where email = 'MANAGER_EMAIL_HERE@example.com';

-- Sanity check: should list your manager + customers
-- select email, role from public.profiles order by role;


-- ---------------------------------------------------------------------------
-- STEP 2 — Seed demo orders for one customer (so the manager dashboard shows
-- real revenue/pending counts and there are orders to manage).
-- Seeds 3 orders dated NOW():
--   A) confirmed  + bank_transfer + payment success  -> counts as revenue
--   B) delivered  + cod           + payment success  -> counts as revenue
--   C) pending    + bank_transfer + payment pending   -> for "Thanh toán lại"
--        demo + manager pending-order workflow
-- Edit v_customer_email to a customer you signed up in STEP 0.
-- ---------------------------------------------------------------------------
do $$
declare
  v_customer_email text := 'CUSTOMER_EMAIL_HERE@example.com';  -- <-- EDIT
  v_customer_id    uuid;
  v_ship_addr      jsonb := jsonb_build_object(
    'name', 'Khách Demo', 'phone', '0900000001',
    'street', '12 Lê Lợi', 'district', 'Quận 1', 'city', 'TP.HCM',
    'lat', 10.7769, 'lng', 106.7009);
  v_variant        record;
  v_order_id       uuid;
  v_total          numeric(12,0);
  v_ship           numeric(12,0) := 30000;  -- keep in sync with checkout flat fee
begin
  select id into v_customer_id
  from public.profiles where email = v_customer_email;
  if v_customer_id is null then
    raise exception 'Customer profile "%" not found — sign it up in the app first.',
      v_customer_email;
  end if;

  -- Pick a real in-stock variant + its product to reference in order_items.
  select pv.id as variant_id, pv.size, pv.color, pr.name as product_name,
         coalesce(pr.sale_price, pr.base_price) as unit_price
  into v_variant
  from public.product_variants pv
  join public.products pr on pr.id = pv.product_id
  where pv.stock_qty > 0
  order by pr.name
  limit 1;
  if v_variant is null then
    raise exception 'No in-stock product_variants found — run seed_data.sql first.';
  end if;

  v_total := v_variant.unit_price + v_ship;

  -- A) confirmed + bank_transfer (paid)
  insert into public.orders (user_id, status, shipping_address, shipping_fee,
                             subtotal, total, payment_method, created_at)
  values (v_customer_id, 'confirmed', v_ship_addr, v_ship,
          v_variant.unit_price, v_total, 'bank_transfer', now())
  returning id into v_order_id;
  insert into public.order_items (order_id, variant_id, product_name, size,
                                  color, quantity, unit_price)
  values (v_order_id, v_variant.variant_id, v_variant.product_name,
          v_variant.size, v_variant.color, 1, v_variant.unit_price);
  insert into public.payments (order_id, user_id, method, amount, status, paid_at)
  values (v_order_id, v_customer_id, 'bank_transfer', v_total, 'success', now());

  -- B) delivered + cod (paid on delivery)
  insert into public.orders (user_id, status, shipping_address, shipping_fee,
                             subtotal, total, payment_method, created_at)
  values (v_customer_id, 'delivered', v_ship_addr, v_ship,
          v_variant.unit_price, v_total, 'cod', now())
  returning id into v_order_id;
  insert into public.order_items (order_id, variant_id, product_name, size,
                                  color, quantity, unit_price)
  values (v_order_id, v_variant.variant_id, v_variant.product_name,
          v_variant.size, v_variant.color, 1, v_variant.unit_price);
  insert into public.payments (order_id, user_id, method, amount, status, paid_at)
  values (v_order_id, v_customer_id, 'cod', v_total, 'success', now());

  -- C) pending + bank_transfer (unpaid) — for "Thanh toán lại" + manager pending
  insert into public.orders (user_id, status, shipping_address, shipping_fee,
                             subtotal, total, payment_method, created_at)
  values (v_customer_id, 'pending', v_ship_addr, v_ship,
          v_variant.unit_price, v_total, 'bank_transfer', now())
  returning id into v_order_id;
  insert into public.order_items (order_id, variant_id, product_name, size,
                                  color, quantity, unit_price)
  values (v_order_id, v_variant.variant_id, v_variant.product_name,
          v_variant.size, v_variant.color, 1, v_variant.unit_price);
  insert into public.payments (order_id, user_id, method, amount, status)
  values (v_order_id, v_customer_id, 'bank_transfer', v_total, 'pending');

  raise notice 'Seeded 3 demo orders for % (total each = %)', v_customer_email, v_total;
end $$;

-- Verify seeded orders:
-- select order_number, status, payment_method, total, created_at
-- from public.orders order by created_at desc limit 5;


-- ---------------------------------------------------------------------------
-- STEP 3 (OPTIONAL) — Clean leftover TEST orders before a real demo.
-- REVIEW the SELECT output first; only delete rows you recognise as test data.
-- Deleting an order cascades to its order_items + payments.
-- ---------------------------------------------------------------------------
-- select order_number, status, total, created_at from public.orders
--   where total <= 21000 or order_number like 'CF-2026%'  -- adjust filter
--   order by created_at;
-- delete from public.orders where id in ( '<uuid-1>', '<uuid-2>' );  -- explicit ids only
