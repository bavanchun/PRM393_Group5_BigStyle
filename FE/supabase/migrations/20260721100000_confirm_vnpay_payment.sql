-- ============================================================
-- Migration: RPC confirm_vnpay_payment
-- Client verifies VNPay signature, then calls this RPC to mark
-- the user's own pending payment as success + confirm the order.
-- ============================================================

create or replace function public.confirm_vnpay_payment(
  p_order_id uuid,
  p_transaction_id text default null,
  p_gateway_response jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_order public.orders%rowtype;
  v_payment public.payments%rowtype;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
    and user_id = v_user_id
  for update;

  if not found then
    raise exception 'Order not found';
  end if;

  if v_order.payment_method is distinct from 'vnpay' then
    raise exception 'Order is not a VNPay order';
  end if;

  -- Idempotent: already confirmed
  if v_order.status = 'confirmed' then
    return jsonb_build_object(
      'order_id', v_order.id,
      'status', v_order.status,
      'already_confirmed', true
    );
  end if;

  if v_order.status is distinct from 'pending' then
    raise exception 'Order cannot be confirmed from status %', v_order.status;
  end if;

  select * into v_payment
  from public.payments
  where order_id = p_order_id
    and user_id = v_user_id
    and method = 'vnpay'
  order by created_at desc
  limit 1
  for update;

  if found and v_payment.status = 'pending' then
    update public.payments set
      status = 'success',
      paid_at = now(),
      transaction_id = coalesce(p_transaction_id, transaction_id),
      gateway_response = coalesce(p_gateway_response, gateway_response)
    where id = v_payment.id
      and status = 'pending';
  elsif not found then
    insert into public.payments (
      order_id, user_id, method, amount, status, paid_at,
      transaction_id, gateway_response
    ) values (
      p_order_id, v_user_id, 'vnpay', v_order.total, 'success', now(),
      p_transaction_id, p_gateway_response
    );
  end if;

  update public.orders
  set status = 'confirmed'
  where id = p_order_id
    and status = 'pending';

  return jsonb_build_object(
    'order_id', p_order_id,
    'status', 'confirmed',
    'already_confirmed', false
  );
end;
$$;

grant execute on function public.confirm_vnpay_payment(uuid, text, jsonb)
  to authenticated;
