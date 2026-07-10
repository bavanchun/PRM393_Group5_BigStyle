-- Human support chat: one conversation per customer, shared staff inbox,
-- Supabase Realtime both directions. All conversation mutations go through
-- SECURITY DEFINER RPCs/trigger — clients get SELECT/INSERT only, never
-- UPDATE/DELETE (message content is immutable from the client).
--
-- ROLLBACK:
--   drop table if exists public.support_messages cascade;
--   drop table if exists public.support_conversations cascade;
--   drop function if exists public.get_or_create_my_conversation();
--   drop function if exists public.bump_support_conversation();
--   drop function if exists public.mark_conversation_read(uuid);
--   drop function if exists public.is_staff();
--   drop function if exists public.force_support_message_defaults();

create table if not exists public.support_conversations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete cascade unique,
  status text not null default 'open',
  last_message_at timestamptz not null default now(),
  last_message_preview text,
  unread_for_staff int not null default 0,
  unread_for_customer int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.support_conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists support_messages_conversation_idx
  on public.support_messages(conversation_id, created_at desc, id);

-- Realtime publication (guarded against re-run duplicate_object).
do $$ begin
  alter publication supabase_realtime add table public.support_messages;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.support_conversations;
exception when duplicate_object then null; end $$;

-- Staff = manager or admin (SECURITY DEFINER, bypasses profiles RLS recursion).
create or replace function public.is_staff()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('manager', 'admin')
  );
$$;

-- One conversation per customer; upsert-returning avoids a select/insert race.
create or replace function public.get_or_create_my_conversation()
returns public.support_conversations
language plpgsql security definer set search_path = public
as $$
declare
  v_row public.support_conversations;
begin
  insert into public.support_conversations (customer_id)
  values (auth.uid())
  on conflict (customer_id) do update set customer_id = excluded.customer_id
  returning * into v_row;
  return v_row;
end $$;

-- Force server-controlled timestamps on insert: a client must not set
-- created_at (would let a customer pin their thread to the top of the staff
-- inbox) or pre-set read_at.
create or replace function public.force_support_message_defaults()
returns trigger
language plpgsql
as $$
begin
  new.created_at := now();
  new.read_at := null;
  return new;
end $$;

drop trigger if exists before_support_message_insert on public.support_messages;
create trigger before_support_message_insert
  before insert on public.support_messages
  for each row execute procedure public.force_support_message_defaults();

-- Maintain denormalized preview + unread counters (kills inbox N+1).
create or replace function public.bump_support_conversation()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_sender_is_staff boolean;
begin
  select (p.role in ('manager', 'admin')) into v_sender_is_staff
  from public.profiles p where p.id = new.sender_id;

  update public.support_conversations set
    last_message_at = new.created_at,
    last_message_preview = left(new.content, 120),
    unread_for_staff = case
      when coalesce(v_sender_is_staff, false) then unread_for_staff
      else unread_for_staff + 1 end,
    unread_for_customer = case
      when coalesce(v_sender_is_staff, false) then unread_for_customer + 1
      else unread_for_customer end
  where id = new.conversation_id;
  return new;
end $$;

drop trigger if exists on_support_message_insert on public.support_messages;
create trigger on_support_message_insert
  after insert on public.support_messages
  for each row execute procedure public.bump_support_conversation();

-- Mark counterpart messages read + zero the caller's unread counter, after
-- verifying the caller participates. No client UPDATE grant on messages.
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_is_staff boolean;
  v_customer_id uuid;
begin
  select (p.role in ('manager', 'admin')) into v_is_staff
  from public.profiles p where p.id = auth.uid();

  select customer_id into v_customer_id
  from public.support_conversations where id = p_conversation_id;

  if not coalesce(v_is_staff, false) and v_customer_id is distinct from auth.uid() then
    raise exception 'not a participant';
  end if;

  if coalesce(v_is_staff, false) then
    update public.support_messages set read_at = now()
      where conversation_id = p_conversation_id
        and read_at is null
        and sender_id = v_customer_id;
    update public.support_conversations set unread_for_staff = 0
      where id = p_conversation_id;
  else
    update public.support_messages set read_at = now()
      where conversation_id = p_conversation_id
        and read_at is null
        and sender_id <> auth.uid();
    update public.support_conversations set unread_for_customer = 0
      where id = p_conversation_id;
  end if;
end $$;

grant execute on function public.is_staff() to authenticated;
grant execute on function public.get_or_create_my_conversation() to authenticated;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- RLS: clients get SELECT/INSERT only.
alter table public.support_conversations enable row level security;
alter table public.support_messages enable row level security;

create policy "Customer sees own conversation"
  on public.support_conversations for select
  using (customer_id = auth.uid());

create policy "Staff sees all conversations"
  on public.support_conversations for select
  using (public.is_staff());

create policy "Participants see conversation messages"
  on public.support_messages for select
  using (
    public.is_staff()
    or exists (
      select 1 from public.support_conversations c
      where c.id = support_messages.conversation_id
        and c.customer_id = auth.uid()
    )
  );

create policy "Customer sends to own conversation"
  on public.support_messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.support_conversations c
      where c.id = support_messages.conversation_id
        and c.customer_id = auth.uid()
    )
  );

create policy "Staff sends to any conversation"
  on public.support_messages for insert
  with check (public.is_staff() and sender_id = auth.uid());
