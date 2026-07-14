create or replace function public.cancel_my_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_status  text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select status into v_status
  from public.orders
  where id = p_order_id;

  if not found then
    raise exception 'Order not found';
  end if;

  if v_status not in ('pending', 'confirmed') then
    raise exception 'Cannot cancel order with status %', v_status;
  end if;

  update public.orders
  set status = 'cancelled',
      updated_at = now()
  where id = p_order_id
    and user_id = v_user_id;

  if not found then
    raise exception 'Not your order or already cancelled';
  end if;
end;
$$;
