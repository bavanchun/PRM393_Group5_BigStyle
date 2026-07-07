---
phase: 4
title: "Manager Operations Blockers"
status: pending
priority: P1
dependencies: [1]
effort: "L"
---

# Phase 4: Manager Operations Blockers

## Overview

Make the manager half of the demo actually work: orders visible + refreshable, status updates with visible success/error feedback, non-zero today revenue, and product category saved on create/edit. Covers M6b, M7b, M7, M40, M13, M14, M9, M4, M23, M31. Depends on Phase 1 (need seeded manager account + orders to validate).

## Requirements

- Functional: manager sees seeded orders in the Đơn hàng tab (and can refresh); changing status shows a spinner then success/error and the detail reflects the new status; dashboard "Doanh thu hôm nay" counts today's real revenue; create/edit product persists the chosen category; tapping a dashboard recent-order opens the **manager** order detail (with status actions), not the customer screen.
- Non-functional: no swallowed errors; no request-id race dropping results.

## Architecture & Findings (verified file:line)

- **M6b — revenue always 0 (`manager_dashboard_stats.dart:22-37`):** `todayRevenue` sums only `status=='delivered'` AND `created_at==today`. Confirmed-today orders are `status=='confirmed'` → excluded → 0. Also keys off `created_at` (creation day) not delivery/paid day. Query source `order_service.dart:35-50` fetches all orders unfiltered; the filter is client-side in the model.
- **M7b — "orders tab blank" (reframed, NOT a widget bug):** `_buildOrdersContent` (`manager_orders_screen.dart:79-126`) is exhaustive — worst case renders filter chips + "Không có đơn hàng" text; `ManagerOrderCard` (`manager_order_card.dart:48-147`) always draws a Container. So the observed "blank" = **empty `state.orders`** showing the empty-state text. Root contributor (`manager_shell.dart:22-27`): `IndexedStack` builds all tabs once; `ManagerOrdersScreen.initState` dispatches `ManagerLoadOrders` a single time at shell build with **no reload on tab re-entry** and no manual refresh recovery. Likely resolved once Phase 1 seeds real orders + a reload-on-entry/refresh is added.
- **M7 — error swallowed (`manager_orders_screen.dart:83`):** error UI gated on `orders.isEmpty`; a failed update while list non-empty sets `state.error` but nothing renders it.
- **M40 — request-id race (`manager_bloc.dart:75-102`):** `_onUpdateOrderStatus` catch block (`:94-101`) has no `requestId` guard → a stale/failed update can overwrite a newer load; update path never sets `isOrdersLoading` (no spinner).
- **M13 — dispatch-then-pop (`order_status_update_sheet.dart:84-89`):** `_confirm` dispatches then `pop()` synchronously; no await, no feedback; combined with M7 = fully silent failure.
- **M14 — no destructive confirm (`order_status_update_sheet.dart:143-169`):** cancel/refund call `_confirm` directly, no dialog.
- **M9 — stale detail (`manager_order_detail_screen.dart` built from passed `OrderModel`, no re-fetch):** after update, `widget.order` stays stale.
- **M4 — wrong detail screen (`manager_dashboard.dart:121-123` → `/order-detail`):** dashboard recent-order opens the **customer** order detail (no status controls) instead of `ManagerOrderDetailScreen`.
- **M23 — create category not saved (`manager_create_product_screen.dart:180-191`):** built `ProductModel` never sets `categoryId`/`category`; `_selectedCategory` dropped.
- **M31 — edit category not saved (`manager_product_detail_screen.dart:218-219`):** `_updateProduct` uses `widget.product.categoryId`/`.category` (originals), ignoring edited `_selectedCategory`.

## Related Code Files

- Modify: `FE/lib/models/manager_dashboard_stats.dart:22-37` — count revenue for paid/fulfilled statuses appropriate to the business (include `confirmed`/`delivered` as decided; prefer keying on paid/confirmed date). Confirm the intended revenue definition (open Q).
- Modify: `FE/lib/screens/manager/manager_orders_screen.dart:79-126` — surface `state.error` regardless of `orders.isEmpty` (M7); add pull-to-refresh already exists (`:106`) but ensure a reload path on tab focus (M7b).
- Modify: `FE/lib/screens/manager/manager_shell.dart:22-27` — trigger `ManagerLoadOrders` on switching to the orders tab (e.g. `onTap`/`AnimatedBuilder` on index) so re-entry reloads.
- Modify: `FE/lib/blocs/manager/manager_bloc.dart:75-102` — guard the catch with `requestId`; set `isUpdatingStatus`/spinner consistently; emit a distinct success signal the sheet can await.
- Modify: `FE/lib/screens/manager/order_status_update_sheet.dart:84-89,143-169` — keep sheet open with a loading state until bloc resolves; show error before pop; add confirm dialog for `cancelled`/`refunded` (M14).
- Modify: `FE/lib/screens/manager/manager_order_detail_screen.dart` — rebuild from freshest bloc order by id (or pop+refresh) after update (M9).
- Modify: `FE/lib/screens/manager/manager_dashboard.dart:121-123` — route recent-order to `ManagerOrderDetailScreen` (M4).
- Modify: `FE/lib/screens/manager/products/manager_create_product_screen.dart:180-191` — map `_selectedCategory` → categoryId, set on model (M23).
- Modify: `FE/lib/screens/manager/products/manager_product_detail_screen.dart:211-228` — use edited `_selectedCategory` → categoryId on update (M31).

## Implementation Steps

1. **Diagnose-then-fix M7b (do FIRST in this phase):** with Phase 1 seeded orders + dedicated manager account, launch and confirm whether Đơn hàng now lists orders. If yes → the "blank" was empty-data/flip-role artifact; just add reload-on-tab-entry + keep refresh. If still empty despite seeded rows → log `state.orders` on entry and trace whether a load result is dropped (request-id / RLS). Only then decide the deeper fix.
2. **Revenue M6b:** update `todayRevenue` to the agreed status set + date key; verify against the seeded `confirmed`-today and `delivered`-today orders → non-zero.
3. **Status-update feedback chain (M7/M13/M40/M9):** make the sheet await a bloc result (loading → success/error), surface errors in `manager_orders_screen` even when list non-empty, guard the catch with request-id, refresh detail after update.
4. **Destructive confirm (M14):** dialog before `cancelled`/`refunded`.
5. **Routing (M4):** dashboard recent-order → `ManagerOrderDetailScreen`.
6. **Category save (M23/M31):** map selection → categoryId on both create and edit model builders.
7. `flutter analyze` clean.

## Success Criteria

- [ ] Manager Đơn hàng tab lists the seeded orders; leaving and returning reloads (M7b).
- [ ] Changing an order's status shows a spinner, then success or a visible error; detail reflects the new status (M7/M13/M40/M9).
- [ ] Cancel/refund asks for confirmation (M14).
- [ ] Dashboard "Doanh thu hôm nay" shows the seeded today revenue, not 0đ (M6b).
- [ ] Dashboard recent-order opens the manager detail with status controls (M4).
- [ ] Creating and editing a product saves the selected category (verify in DB) (M23/M31).
- [ ] `flutter analyze` clean.

## Risk Assessment

- **M7b is a hypothesis, not a proven bug** — Step 1 is explicitly diagnose-first. Do not blind-rewrite the orders screen; the render logic is already correct. If Phase 1 makes orders appear, scope shrinks to reload-on-entry only.
- **Revenue definition is a business decision (open Q):** "today revenue" = confirmed? paid? delivered? Keying on creation vs paid date changes the number. Confirm with user; the audit only proves the current `delivered`-only filter yields 0.
- **Depends on Phase 1** for a valid testbed; running this phase before seeding gives false "still broken" signals.
- **Category id mapping:** need the real category id↔name source (same as C6). Ensure create/edit map to actual `categories` rows, not hardcoded strings.
