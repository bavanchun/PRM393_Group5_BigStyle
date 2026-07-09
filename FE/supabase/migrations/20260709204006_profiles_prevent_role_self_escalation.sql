-- The "Users can update own profile" UPDATE policy has qual (auth.uid()=id)
-- and no WITH CHECK; Postgres falls back to the USING expression for
-- WITH CHECK when omitted, which only re-validates id — not role. Any
-- authenticated user can therefore currently self-promote via
-- `.from('profiles').update({'role': 'manager'})`. Block that with a
-- trigger; admins (is_admin(), SECURITY DEFINER, bypasses RLS) are exempt
-- so the existing admin role-management flow (admin_service.dart) keeps
-- working.

create or replace function public.prevent_profile_role_self_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Only admins can change profile role';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_self_escalation on public.profiles;
create trigger profiles_prevent_role_self_escalation
  before update on public.profiles
  for each row execute function public.prevent_profile_role_self_escalation();
