-- Wishlist feature: per-user saved products.
-- Run this in Supabase → SQL Editor (the app's anon key cannot execute DDL).
-- RLS scopes every row to its owner, so users only ever see/modify their own wishlist.

create table if not exists public.wishlist_items (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  created_at timestamptz default now(),
  unique (user_id, product_id)
);

alter table public.wishlist_items enable row level security;

create policy "Users manage own wishlist" on public.wishlist_items
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
