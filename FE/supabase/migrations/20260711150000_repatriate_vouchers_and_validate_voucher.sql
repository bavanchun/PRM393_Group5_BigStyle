-- Repatriates `vouchers` + `validate_voucher` into the repo. Both already
-- exist on the hosted DB (applied out-of-band, not via a matching repo
-- file) — this migration is idempotent so it's a no-op there, and makes a
-- fresh environment built from repo migrations alone match prod.

create table if not exists public.vouchers (
  id                uuid primary key default gen_random_uuid(),
  code              text not null unique,
  type              text not null check (type in ('percentage', 'fixed')),
  value             numeric not null check (value >= 0),
  min_order_amount  numeric not null default 0,
  max_discount      numeric,
  expires_at        timestamptz,
  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  constraint vouchers_percentage_bound check (type <> 'percentage' or value <= 100)
);

alter table public.vouchers enable row level security;

drop policy if exists "Anyone can view active vouchers" on public.vouchers;
create policy "Anyone can view active vouchers"
  on public.vouchers for select
  using (is_active = true);

drop policy if exists "Managers manage vouchers" on public.vouchers;
create policy "Managers manage vouchers"
  on public.vouchers for all
  using (is_manager());

grant select, insert, update, delete on public.vouchers to authenticated, anon;

create or replace function public.validate_voucher(p_code text, p_subtotal numeric)
returns numeric
language plpgsql
security definer
set search_path = 'public'
as $$
declare
  v public.vouchers%rowtype;
  d numeric;
begin
  select * into v
    from public.vouchers
   where upper(code) = upper(trim(p_code))
     and is_active = true
     and (expires_at is null or expires_at > now());

  if not found then
    raise exception 'Mã giảm giá không hợp lệ hoặc đã hết hạn';
  end if;

  if p_subtotal < v.min_order_amount then
    raise exception 'Đơn hàng chưa đạt giá trị tối thiểu để dùng mã';
  end if;

  if v.type = 'percentage' then
    d := round(p_subtotal * v.value / 100);
    d := least(d, coalesce(v.max_discount, d));
  else
    d := v.value;
  end if;

  -- clamp: never negative, never more than subtotal
  return greatest(0, least(d, p_subtotal));
end;
$$;

insert into public.vouchers (code, type, value, min_order_amount, max_discount, is_active)
values
  ('SALE10', 'percentage', 10, 0, 50000, true),
  ('GIAM20K', 'fixed', 20000, 100000, null, true)
on conflict (code) do nothing;
