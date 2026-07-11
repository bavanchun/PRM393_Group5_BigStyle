-- Fixes F5: the manager dashboard's "Khách hàng" stat always showed 0.
-- Root cause (not the count query, which already filtered role='customer'
-- correctly) is that `profiles` RLS has no manager SELECT policy — only
-- "Admins can view all profiles" and "Users can view own profile" exist, so
-- a manager's flat `.from('profiles').select()` only ever returns their own
-- row. Fix via a count-only RPC rather than a new "Managers can view all
-- profiles" policy, to preserve the existing deliberate boundary (see
-- order_service.dart's getAllOrders comment) that keeps managers from
-- reading customer profile rows/PII directly.

create or replace function public.get_customer_count()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select case when public.is_manager()
    then (select count(*)::integer from public.profiles where role = 'customer')
    else 0
  end;
$$;

grant execute on function public.get_customer_count() to authenticated;
