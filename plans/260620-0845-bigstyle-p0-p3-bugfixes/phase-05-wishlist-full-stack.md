---
phase: 5
title: "Wishlist full-stack"
status: completed
priority: P3
effort: "3h"
dependencies: [1]
---

# Phase 5: Wishlist full-stack

## Overview
Implement the Wishlist feature end-to-end. No backend exists today — everything is UI stubs. This phase adds a `wishlist_items` table + RLS (user-run migration), model/service/bloc, the missing `/favorites` screen + route, and wires the heart toggles that currently do nothing.

## Requirements
- Functional: tap heart on a product (card or detail) → toggles wishlist for the logged-in user, persisted in Supabase; Favorites tab/screen lists wishlisted products; state survives app restart.
- Non-functional: `flutter analyze` clean. Requires one DDL migration the user runs in SQL Editor.

## Key Insights (verified, file:line)
- **No backend**: no `wishlist`/`favorite` table in `schema.sql`; no field on any model.
- UI stubs only:
  - `product_card.dart` props `isWishlisted` L11/L22, `onWishlistToggle` L13/L24; heart `GestureDetector` L74-95. **No caller passes `onWishlistToggle`** (`home_screen.dart` L92/L137, `product_list_screen.dart` L246) → heart is dead.
  - `product_detail_screen.dart:116-124` heart `IconButton onPressed: () {}` empty.
  - `app_bottom_nav.dart:90-91,119` favorite tab → `Navigator.pushNamed('/favorites')` but **`/favorites` route is NOT registered** in `app_router.dart` → would crash/no-op.
  - `profile_screen.dart:114` favorite menu item (label only).
- BLoC pattern: follow `lib/blocs/order/` 3-file structure; register in `main.dart`.

## Architecture
- **DB migration** (`FE/migrations/` new file, user runs in SQL Editor):
  ```sql
  create table public.wishlist_items (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references public.profiles(id) on delete cascade,
    product_id uuid references public.products(id) on delete cascade,
    created_at timestamptz default now(),
    unique(user_id, product_id)
  );
  alter table public.wishlist_items enable row level security;
  create policy "Users manage own wishlist" on public.wishlist_items
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
  ```
- **WishlistService** (`lib/services/wishlist_service.dart`): `getWishlist(userId)` (join products), `add(userId, productId)`, `remove(userId, productId)`, `toggle(...)`.
- **WishlistBloc** (`lib/blocs/wishlist/`): loads the user's wishlist into a `Set<productId>` for O(1) heart state; events `WishlistLoad`, `WishlistToggle(productId)`; optimistic UI update + rollback on error. Register in `main.dart`.
- **Screen + route**: create `lib/screens/favorites/favorites_screen.dart` (grid of wishlisted products, reuse `ProductCard`); register `/favorites` in `app_router.dart`.
- **Wire toggles**: pass `isWishlisted: bloc.contains(id)` + `onWishlistToggle: () => dispatch toggle` into every `ProductCard` caller and the detail heart; all gated by Phase 1 auth guard.

## Related Code Files
- Create: `FE/migrations/2026xxxx_wishlist_items.sql`
- Create: `lib/services/wishlist_service.dart`, `lib/blocs/wishlist/{wishlist_bloc,wishlist_event,wishlist_state}.dart`, `lib/screens/favorites/favorites_screen.dart`
- Modify: `lib/config/routes/app_router.dart` (register `/favorites`)
- Modify: `lib/main.dart` (provide WishlistBloc; load on auth success)
- Modify: `lib/widgets/product_card.dart` callers — `home_screen.dart` L92/L137, `product_list_screen.dart` L246 (pass wishlist props)
- Modify: `lib/screens/product_detail/product_detail_screen.dart:116-124` (wire heart)
- (Optional) add a `wishlist` field/getter where convenient; prefer bloc Set over per-model flag (DRY).

## Implementation Steps
1. Use `/mobile-development` skill.
2. Write the migration file; **instruct user to run it in Supabase SQL Editor** (anon key cannot DDL). Block runtime testing until confirmed.
3. Create WishlistService (toggle = check-then-insert/delete, or rely on `unique` + upsert/delete).
4. Create WishlistBloc holding a `Set<String>` of product ids; load on auth success in `main.dart`.
5. Create FavoritesScreen (grid via ProductCard); register `/favorites` route.
6. Wire `isWishlisted`/`onWishlistToggle` into all ProductCard callers + detail heart; apply auth guard.
7. `cd FE && flutter analyze` clean. After user runs migration: smoke test toggle persists across restart; Favorites tab lists items; verify rows via REST.
8. Commit + PR via `/vchun-git prc`.

## Success Criteria
- [x] `wishlist_items` table + RLS migration created (`FE/migrations/20260620_wishlist_items.sql`) — **user must run it in SQL Editor**
- [x] Heart toggles persist to Supabase for the logged-in user (optimistic Set + rollback in WishlistBloc)
- [x] `/favorites` route registered; Favorites screen lists wishlisted products
- [x] Heart state correct on cards + detail after reload (single WishlistBloc Set is source of truth)
- [x] Guarded for non-logged-in users (`toggleWishlist` bounces mock/anon to /login)
- [x] `flutter analyze` clean
- [ ] ≥1 commit + PR via `/vchun-git prc` — pending commit step
- [ ] Runtime smoke (toggle persists across restart; Favorites lists items) — blocked until user runs migration

## Risk Assessment
- **Migration is a user-action blocker** — feature can't be runtime-verified until the user runs it; ship code + clear instructions, mark PR "needs DB migration run".
- **Heart state sync**: many ProductCard instances → use a single bloc `Set` as source of truth (avoid per-card local state drift).
- **Optimistic toggle** must roll back on insert/delete error.

## Security Considerations
- `wishlist_items` RLS scopes all rows to `auth.uid()`; users cannot read/modify others' wishlists.
