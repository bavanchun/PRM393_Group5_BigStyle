-- Defense-in-depth: no current app path can move a delivered order to any
-- other status before a pending refund is decided (OrderStatus.delivered's
-- nextStatuses is empty, cancel_my_order only allows pending/confirmed), but
-- this is money-adjacent code and the approve branch previously had no guard
-- of its own — add one so an order that somehow changed status between
-- request-creation and decision can't be silently forced to refunded.
create or replace function public.decide_refund_request(
  p_request_id uuid,
  p_decision public.refund_request_status,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_user_id uuid;
  v_order_number text;
begin
  if not public.is_manager() then
    raise exception 'only managers can decide refund requests';
  end if;
  if p_decision not in ('approved', 'rejected') then
    raise exception 'decision must be approved or rejected';
  end if;

  select order_id, user_id into v_order_id, v_user_id
  from public.refund_requests
  where id = p_request_id and status = 'pending'
  for update;

  if v_order_id is null then
    raise exception 'refund request not found or already decided';
  end if;

  update public.refund_requests
  set status = p_decision, manager_note = p_note, decided_at = now()
  where id = p_request_id;

  if p_decision = 'approved' then
    update public.orders
    set status = 'refunded'
    where id = v_order_id and status = 'delivered';

    if not found then
      raise exception 'order is no longer delivered — cannot approve refund';
    end if;
  else
    select order_number into v_order_number from public.orders where id = v_order_id;
    insert into public.notifications (user_id, title, body, type, data)
    values (
      v_user_id,
      'Yêu cầu hoàn tiền đơn ' || coalesce(v_order_number, ''),
      case when p_note is not null and p_note <> ''
        then 'Yêu cầu hoàn tiền của bạn đã bị từ chối: ' || p_note
        else 'Yêu cầu hoàn tiền của bạn đã bị từ chối.'
      end,
      'order_update',
      jsonb_build_object('order_id', v_order_id, 'refund_request_id', p_request_id, 'kind', 'refund_rejected')
    );
  end if;
end;
$$;
