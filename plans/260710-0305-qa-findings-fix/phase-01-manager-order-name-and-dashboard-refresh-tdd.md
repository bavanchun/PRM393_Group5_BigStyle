---
phase: 1
title: "Manager Order Name And Dashboard Refresh (TDD)"
status: completed
priority: P1
dependencies: []
effort: "4h"
---

# Phase 1: Manager Order Name And Dashboard Refresh (TDD)

<!-- Updated: Red Team Session 2026-07-10 — RLS policy approach replaced by denormalization; getOrderById step dropped; race/failure semantics specified -->

## Overview

Fix QA findings Medium #1 (manager order detail shows `Không rõ`) and Medium #2
(dashboard `recentOrders`/`dashboardStats` stale after status update). TDD.

Red-team corrections applied:
- Manager detail reads `order.customerName` from `ManagerBloc.state.orders` (`FE/lib/screens/manager/manager_order_detail_screen.dart:160`), fed ONLY by `getAllOrders` (join already present at `FE/lib/services/order_service.dart:27`). `getOrderById` has exactly 1 caller — customer `OrderBloc` (`FE/lib/blocs/order/order_bloc.dart:32`) — so adding a join there does NOT fix this bug. Dropped (YAGNI).
- RLS block on `profiles` is near-certain, not conditional: migration `FE/supabase/migrations/20260703150000_add_admin_role.sql:28-32` explicitly DROPPED "Managers can view all profiles". A column-scoped RLS policy is impossible (RLS is row-level only), a role-conditional policy self-querying `profiles` causes infinite recursion (42P17), and any manager SELECT policy over-exposes customer PII (email/phone) beyond need — plus base schema is remote-only so `profiles.role` self-writability is unverified, raising escalation payoff.
- **Chosen fix: denormalize customer name into `orders.shipping_address.name`.** No new read privileges on `profiles` at all. The `OrderModel.fromMap` fallback (`FE/lib/models/order_model.dart:146-148`) already reads `shipping_address?['name']` — currently dead because `create_order` RPC passes `p_shipping_address` verbatim without a `name` key (`FE/supabase/migrations/20260708120000_create_order_rpc.sql:16,55-58`) and `OrderModel.toMap` serializes only address/lat/lng.

## Requirements

- Functional: manager sees the customer name on order list/detail for all orders (new + backfilled); after a successful status update the dashboard pending card and recent orders reflect the new status in-session.
- Non-functional: no new SELECT privileges on `profiles`; keep `IndexedStack` keep-alive; distinct error semantics for "update failed" vs "refresh failed"; follow Fake-service test convention. (Red-team removed the earlier "no full reload" constraint — `getDashboardStats` is inherently a multi-table fetch, `order_service.dart:36-50`; one extra call per manual status update is acceptable.)

## Architecture

**Name fix (DB-side, no privilege change):**
1. `create_order` RPC (SECURITY DEFINER): when building/storing `p_shipping_address`, inject `name` from `profiles.full_name` of `auth.uid()` if the key is absent — definer context can read profiles safely.
2. Backfill migration: `UPDATE orders SET shipping_address = shipping_address || jsonb_build_object('name', p.full_name) FROM profiles p WHERE p.id = orders.user_id AND (shipping_address->>'name') IS NULL`.
3. Client `fromMap` fallback then resolves the name. The embedded `customer:profiles!orders_user_id_fkey(full_name)` join in `getAllOrders` (`order_service.dart:27`) is REMOVED (validation decision: dead code under current RLS; `shipping_address.name` is the sole name source). `fromMap`'s `customer` branch stays for map-shape tolerance. <!-- Updated: Validation Session 1 - remove dead embed -->

**Dashboard refresh (bloc):** `_onUpdateOrderStatus` (`FE/lib/blocs/manager/manager_bloc.dart:75`) must:
- Emit the local success patch (orders reload + `recentOrders` entry copyWith new status) in its OWN try/catch guarded by `_ordersRequestId`, with the existing failure message only for `updateOrderStatus` itself throwing.
- Then refresh stats in a SEPARATE try/catch: claim `final dashId = ++_dashboardRequestId` BEFORE `await getDashboardStats()`, guard the emit with it, and set `isDashboardLoading: false` in that emit (prevents the stuck-spinner trap when an in-flight `_onLoadDashboard` bails at its guard after emitting `isDashboardLoading: true`, `manager_bloc.dart:21-28`). A stats-refresh failure is soft: keep the local `recentOrders` patch, do NOT emit the "update failed" error.

## Related Code Files

- Modify: `FE/lib/blocs/manager/manager_bloc.dart` (`_onUpdateOrderStatus`)
- Modify: `FE/lib/services/order_service.dart` (remove dead `customer:profiles` embed from `getAllOrders` only) <!-- Updated: Validation Session 1 -->
- Create: `FE/test/blocs/manager_bloc_test.dart`
- Create: `FE/test/models/order_customer_name_mapping_test.dart`
- Create: `FE/supabase/migrations/2026MMDDHHMMSS_order_shipping_address_customer_name.sql` (RPC amendment + backfill)
- NOT modified (red-team): `getOrderById` — join addition dropped; no `profiles` read-policy migration.

## Implementation Steps

0. **Diagnostic first (remote SQL editor, before writing the migration):** run the `getAllOrders` embed as a manager-role query and inspect whether `customer` is null (RLS) vs `full_name` null (data); dump `pg_policies` for `profiles` (confirm manager SELECT absent; also record whether any UPDATE policy `WITH CHECK` prevents self `role` change — if role is self-writable, ADD a migration in this phase blocking self-role-change (WITH CHECK excluding `role`, or a BEFORE UPDATE trigger rejecting non-admin role changes); validation decision: fix immediately if found). Confirms the denormalization premise; adjust only if evidence contradicts. <!-- Updated: Validation Session 1 - role guard in-scope -->
1. **Red: model mapping tests** (`order_customer_name_mapping_test.dart`):
   - `fromMap` with `shipping_address.name` present and no `customer` → `customerName` set (locks the fallback the fix relies on).
   - `fromMap` with `shipping_address` lacking `name` and no `customer` → `customerName` null, no throw.
2. **Red: bloc tests** (`manager_bloc_test.dart`). Fake spec (red-team: `OrderService` constructor falls back to `Supabase.instance` — `order_service.dart:9-10` — so a bare fake throws):
   ```dart
   class FakeOrderService extends OrderService {
     FakeOrderService() : super(client: SupabaseClient('http://localhost', 'anon'));
     // override getAllOrders / updateOrderStatus / getDashboardStats — client never used
   }
   ```
   Tests:
   - Seed via `ManagerLoadDashboard` (one `pending` order in `recentOrders`, stats counting it); dispatch `ManagerUpdateOrderStatus(pending→confirmed)`; assert updated `orders`, `recentOrders` entry `confirmed`, refreshed `dashboardStats`, `isDashboardLoading == false`. Fails against current bloc.
   - `updateOrderStatus` throws → `error` set, `recentOrders`/stats untouched.
   - `updateOrderStatus` succeeds but `getDashboardStats` throws → NO "update failed" error; `orders`/`recentOrders` patched; stats unchanged; `isUpdatingStatus == false`.
   - Interleaving: dispatch `ManagerLoadDashboard` then `ManagerUpdateOrderStatus` with fake latencies making the dashboard load resolve slower → final stats are the update-handler's (fresh) values and no perpetual `isDashboardLoading`.
3. **Green: bloc fix** per Architecture (two try/catch blocks, dual request-id claims, loading reset).
4. **Migration + backfill** per Architecture; apply to remote. Verify backfill row count matches orders lacking `name`.
5. **Runtime verify (emulator, remote Supabase):** manager opens an order for a known profile (`Trần Thị Demo`) → name renders; place a fresh test order → name present without backfill; clean up test order.
6. `flutter analyze && flutter test` green.

## Success Criteria

- [x] New model + bloc tests pass (incl. refresh-failure and interleaving cases); pre-existing tests unaffected. (28/28 `flutter test` green)
- [x] Emulator: manager order detail shows customer name for backfilled orders — verified live, order `DH-CF-20260709-54E569` shows "Khách hàng: Trần Thị Demo". Newly-created-order path verified via migration/RPC code review only, not exercised through a live checkout this session.
- [x] Emulator: after confirming an order, Dashboard shows updated pending count (3→2) and recent-order status (Chờ xác nhận→Đã xác nhận) without pull-to-refresh; no stuck spinner. Verified live.
- [x] No new SELECT policy/grant on `profiles`; only an UPDATE trigger was added.
- [x] Diagnostic step 0 run against remote (`pg_policies`): manager SELECT confirmed absent; `role` confirmed self-writable (no WITH CHECK differentiating it). Blocking migration shipped and verified: non-admin `UPDATE profiles SET role='manager'` raises `Only admins can change profile role`; non-role updates still succeed.
- [x] `getAllOrders` select string no longer contains the `customer:profiles` embed; manager list/detail confirmed still showing names via shipping_address.

## Risk Assessment

- Backfill touches all orders rows → run in one transaction; only adds a JSON key, `shipping_address` shape otherwise preserved; rollback = strip the `name` key.
- `create_order` RPC change: keep signature identical (no client change); regression = QA checkout flow already covered by existing checkout tests.
- Stats refresh doubles remote calls per manual status update — accepted (manual action, low frequency).
- If step-0 diagnostic shows `full_name` itself is null/empty for the QA profile, fix data + still ship denormalization (it is the durable path for future orders).
