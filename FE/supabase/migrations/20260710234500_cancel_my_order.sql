-- Repatriate the customer self-cancel RPC. It previously existed only on the
-- hosted DB (drift); this makes it repo-canonical. Permits cancelling one's own
-- order while pending OR confirmed — the UI cancel gate depends on this set.
--
-- ROLLBACK: drop function if exists public.cancel_my_order(uuid);

create or replace function public.cancel_my_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.orders set status = 'cancelled'
   where id = p_order_id
     and user_id = auth.uid()
     and status in ('pending', 'confirmed');
  if not found then
    raise exception 'Order cannot be cancelled';
  end if;
end $$;

grant execute on function public.cancel_my_order(uuid) to authenticated;
