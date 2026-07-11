-- Vouchers had no usage cap — one code was infinitely reusable. Add a
-- limit + counter and enforce it in validate_voucher (preview, best-effort)
-- and in create_order (authoritative, row-locked — see next migration).

alter table public.vouchers
  add column if not exists usage_limit integer,
  add column if not exists used_count integer not null default 0;

alter table public.vouchers
  drop constraint if exists vouchers_used_count_check;
alter table public.vouchers
  add constraint vouchers_used_count_check check (used_count >= 0);

-- Existing demo vouchers had no cap; give them a bounded default instead of
-- leaving usage unlimited. usage_limit is DB-only for now — VoucherModel and
-- the manager voucher editor don't expose it yet; change it via SQL/dashboard
-- until that UI field is added.
update public.vouchers
   set usage_limit = 50
 where usage_limit is null;

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

  if v.usage_limit is not null and v.used_count >= v.usage_limit then
    raise exception 'Mã giảm giá đã hết lượt sử dụng';
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
