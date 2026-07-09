---
phase: 3
title: "Favorites Nav And Orders Updated-At Trigger"
status: completed
priority: P2
dependencies: []
effort: "2h"
---

# Phase 3: Favorites Nav And Orders Updated-At Trigger

<!-- Updated: Red Team Session 2026-07-10 — column pre-check, unique trigger fn name + search_path, test harness spec, cancel path + creation semantics -->

## Overview

Fix the two Low findings: Favorites highlights the Orders bottom-nav tab
(becomes a Profile subpage without bottom nav, per user decision), and
`orders.updated_at` is not maintained (add DB trigger).

Red-team corrections applied:
- **`orders.updated_at` column existence is UNVERIFIED** — no migration in the repo creates the `orders` table (base schema is remote-only; schema drift proven: `cancel_my_order` is called from `FE/lib/services/order_service.dart:186` but exists in no migration file). If the column is missing, `new.updated_at = now()` breaks EVERY orders UPDATE (manager status update AND customer cancel). Mandatory pre-check.
- `create or replace function public.set_updated_at()` could silently overwrite an unseen same-name remote function attached to other tables — unrecoverable (original body in no repo). Use a unique name + `SET search_path`.
- The `create_order` RPC performs a second-pass `UPDATE public.orders SET subtotal, total ...` during creation (`FE/supabase/migrations/20260708120000_create_order_rpc.sql:105-109`), so the trigger makes `updated_at > created_at` at birth for all new orders. **Accepted** — grep shows no Dart logic compares `updatedAt` vs `createdAt`; documented here as intended semantics.
- Widget test as originally specced could not run: `FavoritesScreen.initState` reads `AuthBloc`/`WishlistBloc` (`FE/lib/screens/favorites/favorites_screen.dart:24-25`) and a directly-pumped screen has `Navigator.canPop == false` (no implicit BackButton ever). Harness specified below.

## Requirements

- Functional: Favorites pushed from Profile (sole entries: `FE/lib/screens/profile/profile_screen.dart:116` → `FE/lib/config/routes/app_router.dart:62`), back navigation, no bottom nav; any `UPDATE` on `orders` bumps `updated_at` (both manager direct update `order_service.dart:173-179` and `cancel_my_order` RPC paths).
- Non-functional: uniquely named trigger function with pinned search_path; migration idempotent and self-sufficient (adds column if absent).

## Related Code Files

- Modify: `FE/lib/screens/favorites/favorites_screen.dart` (remove `bottomNavigationBar`, line 44)
- Create: `FE/test/widgets/favorites_screen_navigation_test.dart`
- Create: `FE/supabase/migrations/20260709204510_orders_updated_at_trigger.sql`
- Modify: `FE/lib/services/auth_service.dart`, `FE/lib/services/google_auth_service.dart` (unplanned addition — both had a field initializer touching `Supabase.instance.client` eagerly, which throws outside an initialized Supabase in a widget test; switched to the same optional injectable `client` constructor param `OrderService`/`WishlistService` already use, so `favorites_screen_navigation_test.dart` can construct a real `AuthBloc` with a dummy client)

## Implementation Steps

1. **Widget test (red)** — harness: `MultiBlocProvider` with fake `AuthBloc`/`WishlistBloc`; pump a stub host page; `Navigator.push(MaterialPageRoute(builder: (_) => FavoritesScreen()))` so `canPop == true`; then assert `find.byType(BackButton)` present and `find.byType(AppBottomNav)` absent. Red on the AppBottomNav assertion today.
2. Remove `bottomNavigationBar` from `FavoritesScreen`; AppBar has no explicit `leading` (`favorites_screen.dart:39-43`) so the implicit BackButton appears on pushed routes. Test green.
3. **Remote pre-checks (SQL editor, before writing the migration):**
   - `select column_name from information_schema.columns where table_name='orders' and column_name='updated_at';`
   - `select pg_get_functiondef(oid) from pg_proc where proname in ('set_updated_at','orders_set_updated_at_fn');` — record any existing body in the implementation report before proceeding.
4. **Migration** (self-sufficient, unique names):
   ```sql
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
   ```
   If pre-check 3 finds `orders_set_updated_at_fn` already exists with a DIFFERENT body, pick a new distinct name — never repurpose.
5. Apply to remote; verify BOTH write paths: manager status update (direct table UPDATE) and customer `cancel_my_order` RPC each bump `updated_at`; restore test order state after.
6. `flutter analyze && flutter test` green.

## Success Criteria

- [x] Widget test passes with the specified harness: pushed route shows BackButton, no AppBottomNav. Verified red pre-fix (git stash of the screen change) and green post-fix.
- [x] Emulator: Profile → Favorites → back returns to Profile. Verified live.
- [x] Remote: status update confirmed bumping `orders.updated_at` directly (before: `2026-07-03 08:05:48`, after: `2026-07-09 20:45:23`); test row restored to `pending` in phase 1's cleanup. `cancel_my_order` confirmed via `pg_get_functiondef` to do a plain `UPDATE public.orders` (table-level trigger fires for any UPDATE regardless of caller) — not separately exercised live.
- [x] Pre-check outputs recorded: `orders.updated_at` column already existed (`timestamp with time zone`, nullable); no pre-existing `set_updated_at`/`orders_set_updated_at_fn` function found.
- [ ] New-order `updated_at >= created_at` at creation acknowledged as intended (no Dart logic depends on equality).

## Risk Assessment

- Missing column would have broken all order updates → neutralized by `add column if not exists` + pre-check.
- Function-name hijack of unseen remote function → neutralized by unique name + `pg_get_functiondef` pre-check with a defined "exists with different body → rename" action.
- Removing bottom nav strands no flow — Favorites has exactly 2 entry references, both the Profile push path.
- Rollback: revert screen change; `drop trigger orders_set_updated_at on public.orders; drop function public.orders_set_updated_at_fn();` (column stays — harmless additive).
