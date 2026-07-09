-- orders.updated_at exists (verified via information_schema pre-check) but
-- nothing maintains it. No pre-existing set_updated_at/orders_set_updated_at_fn
-- function was found (verified via pg_proc pre-check), so this creates a
-- uniquely named one rather than risking a hijack of an unseen same-name
-- remote function.

alter table public.orders
  add column if not exists updated_at timestamptz not null default now();

create or replace function public.orders_set_updated_at_fn()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
  before update on public.orders
  for each row execute function public.orders_set_updated_at_fn();
