-- Phase 5 hardening: pin search_path on the functions this plan added.
-- Supabase's linter flags SECURITY DEFINER / trigger functions with a mutable
-- search_path (0011_function_search_path_mutable) — a privilege-escalation
-- vector for handle_new_user especially. Additive: bodies already reference
-- public.* explicitly; this only sets the guard.
--
-- ROLLBACK: recreate each function without `set search_path = public`.

create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name');
  return new;
end $$;

create or replace function public.enforce_review_gate()
returns trigger
language plpgsql set search_path = public
as $$
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
end $$;

create or replace function public.force_support_message_defaults()
returns trigger
language plpgsql set search_path = public
as $$
begin
  new.created_at := now();
  new.read_at := null;
  return new;
end $$;
