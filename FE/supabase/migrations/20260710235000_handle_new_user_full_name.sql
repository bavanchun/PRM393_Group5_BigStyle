-- Persist full_name at signup: read it from the auth user's metadata
-- (raw_user_meta_data->>'full_name', supplied by signUp data:{...}) so the
-- profiles row is created with the name for password AND OTP/Google signups.
-- Additive: metadata is null for flows that don't send it → column stays null
-- (previous behavior).
--
-- ROLLBACK:
--   create or replace function public.handle_new_user()
--   returns trigger as $$
--   begin
--     insert into public.profiles (id, email) values (new.id, new.email);
--     return new;
--   end; $$ language plpgsql security definer;

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name'
  );
  return new;
end;
$$ language plpgsql security definer;
