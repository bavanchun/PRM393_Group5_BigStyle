-- Repatriates `chat_messages` (AI bot chat history) into the repo. It
-- already exists on the hosted DB (applied out-of-band, not via a matching
-- repo file — only appears in the stale FE/schema.sql snapshot) — this
-- migration is idempotent so it's a no-op there, and makes a fresh
-- environment built from repo migrations alone match prod. Same pattern as
-- the vouchers repatriation in the full-app-improvement plan's Phase 01.

create table if not exists public.chat_messages (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references public.profiles(id) on delete cascade,
  role       text not null check (role in ('user', 'assistant')),
  content    text not null,
  metadata   jsonb,
  created_at timestamptz not null default now()
);

alter table public.chat_messages enable row level security;

drop policy if exists "Users manage own chat messages" on public.chat_messages;
create policy "Users manage own chat messages"
  on public.chat_messages for all
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.chat_messages to authenticated, anon;
