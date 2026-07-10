-- Review purchase-gate: only a customer who received a delivered order
-- containing the product may write/edit its review. Wires the unused
-- reviews.order_item_id + is_verified columns and makes them tamper-proof.
--
-- ROLLBACK (restore prior behavior):
--   drop trigger if exists on_review_guard on public.reviews;
--   drop function if exists public.enforce_review_gate();
--   drop policy if exists "Purchasers insert own verified reviews" on public.reviews;
--   drop policy if exists "Purchasers update own verified reviews" on public.reviews;
--   create policy "Users insert own reviews" on public.reviews
--     for insert with check (auth.uid() = user_id);
--   create policy "Users update own reviews" on public.reviews
--     for update using (auth.uid() = user_id);
--   -- (update_product_rating stays SECURITY DEFINER — harmless to keep.)

-- 1 + 2. Replace the ungated INSERT/UPDATE policies with eligibility-bound ones.
drop policy if exists "Users insert own reviews" on public.reviews;
drop policy if exists "Users update own reviews" on public.reviews;

create policy "Purchasers insert own verified reviews"
  on public.reviews for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      join public.product_variants pv on pv.id = oi.variant_id
      where oi.id = reviews.order_item_id
        and o.user_id = auth.uid()
        and o.status = 'delivered'
        and pv.product_id = reviews.product_id
    )
  );

create policy "Purchasers update own verified reviews"
  on public.reviews for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      join public.product_variants pv on pv.id = oi.variant_id
      where oi.id = reviews.order_item_id
        and o.user_id = auth.uid()
        and o.status = 'delivered'
        and pv.product_id = reviews.product_id
    )
  );

-- 3. ONE combined BEFORE INSERT OR UPDATE trigger:
--    (a) provenance columns immutable on UPDATE,
--    (b) is_verified always recomputed server-side (client value ignored).
create or replace function public.enforce_review_gate()
returns trigger as $$
begin
  if (tg_op = 'UPDATE') then
    if new.product_id is distinct from old.product_id
       or new.user_id is distinct from old.user_id
       or new.order_item_id is distinct from old.order_item_id then
      raise exception 'review provenance is immutable';
    end if;
  end if;

  new.is_verified := exists (
    select 1
    from public.order_items oi
    join public.orders o on o.id = oi.order_id
    join public.product_variants pv on pv.id = oi.variant_id
    where oi.id = new.order_item_id
      and o.user_id = new.user_id
      and o.status = 'delivered'
      and pv.product_id = new.product_id
  );
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_review_guard on public.reviews;
create trigger on_review_guard
  before insert or update on public.reviews
  for each row execute procedure public.enforce_review_gate();

-- 4. Recreate update_product_rating as SECURITY DEFINER: products UPDATE is
--    manager-only, so an invoker-rights version never bumps avg_rating on a
--    customer review insert.
create or replace function public.update_product_rating()
returns trigger as $$
begin
  update public.products set
    avg_rating   = (select round(avg(rating)::numeric, 2) from public.reviews where product_id = new.product_id),
    review_count = (select count(*)                        from public.reviews where product_id = new.product_id),
    updated_at   = now()
  where id = new.product_id;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- 5. Legacy/seed reviews: backfill a valid order_item_id where a matching
--    delivered order exists; delete the rest (do NOT weaken the policy).
update public.reviews r
set order_item_id = sub.oi_id
from (
  select distinct on (r2.id) r2.id as review_id, oi.id as oi_id
  from public.reviews r2
  join public.order_items oi on true
  join public.orders o on o.id = oi.order_id
  join public.product_variants pv on pv.id = oi.variant_id
  where r2.order_item_id is null
    and o.user_id = r2.user_id
    and o.status = 'delivered'
    and pv.product_id = r2.product_id
  order by r2.id, oi.id
) sub
where r.id = sub.review_id;

delete from public.reviews where order_item_id is null;

-- Recompute product aggregates: the delete above has no AFTER DELETE trigger,
-- so pruned seed reviews would leave inflated review_count/avg_rating.
update public.products p set
  review_count = (select count(*) from public.reviews r where r.product_id = p.id),
  avg_rating   = coalesce(
    (select round(avg(r.rating)::numeric, 2) from public.reviews r where r.product_id = p.id),
    0
  ),
  updated_at   = now();

-- Recompute is_verified for the surviving rows.
update public.reviews r
set is_verified = exists (
  select 1
  from public.order_items oi
  join public.orders o on o.id = oi.order_id
  join public.product_variants pv on pv.id = oi.variant_id
  where oi.id = r.order_item_id
    and o.user_id = r.user_id
    and o.status = 'delivered'
    and pv.product_id = r.product_id
);
