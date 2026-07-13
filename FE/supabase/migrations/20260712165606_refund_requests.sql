-- delivered_at: needed to enforce the 7-day refund-request window. Stamped
-- by a trigger (not client code) so it's always accurate regardless of which
-- path transitions an order to delivered. Existing delivered orders are
-- backfilled from updated_at (best available proxy) so the demo dataset
-- isn't stuck with an unusable null window on already-delivered seed orders.
alter table public.orders add column if not exists delivered_at timestamptz;

update public.orders
set delivered_at = updated_at
where status = 'delivered' and delivered_at is null;

create or replace function public.orders_set_delivered_at_fn()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.status = 'delivered' and old.status is distinct from 'delivered' then
    new.delivered_at = now();
  end if;
  return new;
end $$;

drop trigger if exists orders_set_delivered_at on public.orders;
create trigger orders_set_delivered_at
  before update on public.orders
  for each row execute function public.orders_set_delivered_at_fn();

create type public.refund_request_status as enum ('pending', 'approved', 'rejected');

create table public.refund_requests (
  id           uuid default gen_random_uuid() primary key,
  order_id     uuid not null unique references public.orders(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  reason       text not null,
  status       public.refund_request_status not null default 'pending',
  manager_note text,
  created_at   timestamptz not null default now(),
  decided_at   timestamptz
);

alter table public.refund_requests enable row level security;

-- One request per order, ever (matches the unique constraint above) — the
-- window + delivered-only conditions are enforced here, not just in the FE,
-- so a stale client can't bypass the rule via a direct REST call.
create policy "Customers request refund on own delivered order within window"
  on public.refund_requests for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.orders o
      where o.id = order_id
        and o.user_id = (select auth.uid())
        and o.status = 'delivered'
        and o.delivered_at is not null
        and o.delivered_at >= now() - interval '7 days'
    )
  );

create policy "Customers view own refund requests"
  on public.refund_requests for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Scoped to is_manager() (not is_staff()), matching the existing "Managers
-- manage all orders" policy on the orders table itself — refund decisions
-- stay manager-scoped, consistent with that precedent.
create policy "Managers view all refund requests"
  on public.refund_requests for select
  to authenticated
  using (public.is_manager());

create policy "Managers update refund requests"
  on public.refund_requests for update
  to authenticated
  using (public.is_manager());

-- Atomic decision: status + order transition (approve only) + notification,
-- so a customer never observes a request marked approved without the order
-- itself having flipped to refunded. Approve reuses the existing
-- on_order_status_change trigger for the customer notification (it already
-- fires on any orders.status change, including ->refunded); reject needs an
-- explicit notification since no status change happens on reject.
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
    update public.orders set status = 'refunded' where id = v_order_id;
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

revoke execute on function public.decide_refund_request(uuid, public.refund_request_status, text) from public;
grant execute on function public.decide_refund_request(uuid, public.refund_request_status, text) to authenticated;

-- Manager-facing notification when a customer creates a request — DB-owned
-- (trigger) rather than client-inserted, so it can't be skipped by a buggy
-- or malicious client, and leverages the realtime badge plumbing from Phase 3.
create or replace function public.notify_refund_request_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_number text;
  v_manager record;
begin
  select order_number into v_order_number from public.orders where id = new.order_id;
  for v_manager in select id from public.profiles where role = 'manager' loop
    insert into public.notifications (user_id, title, body, type, data)
    values (
      v_manager.id,
      'Yêu cầu hoàn tiền mới',
      'Đơn ' || coalesce(v_order_number, '') || ' vừa được yêu cầu hoàn tiền.',
      'order_update',
      jsonb_build_object('order_id', new.order_id, 'refund_request_id', new.id, 'kind', 'refund_requested')
    );
  end loop;
  return new;
end;
$$;

drop trigger if exists on_refund_request_created on public.refund_requests;
create trigger on_refund_request_created
  after insert on public.refund_requests
  for each row execute function public.notify_refund_request_created();

revoke execute on function public.notify_refund_request_created() from public;
