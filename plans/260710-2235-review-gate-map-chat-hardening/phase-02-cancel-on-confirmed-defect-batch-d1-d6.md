---
phase: 2
title: "Cancel-on-Confirmed & Defect Batch D1-D6"
status: completed
priority: P2
dependencies: [1]
effort: "S"
---

# Phase 2: Cancel-on-Confirmed & Defect Batch D1-D6

## Overview
Widen UI cancel gate to match backend `cancel_my_order` RPC (believed to permit pending+confirmed, but the function exists only on the live DB — step 0 repatriates + verifies its SQL before any UI change) and fix six verified defects. Depends on Phase 1 only because both edit `order_detail_screen.dart` (avoid conflicts); logically independent.

## Requirements
- Functional: customer can cancel `confirmed` order from order detail (same confirm dialog); D1–D6 fixed per table.
- Non-functional: no behavior regression; error snackbars use existing patterns.

## Defect table
| ID | Fix | Location |
|----|-----|----------|
| D1 | Admin menu "Hồ sơ/Cài đặt/Trợ giúp": either wire real destinations or remove dead items. **Decision: remove "Cài đặt"/"Trợ giúp" (no target screens exist — YAGNI), point "Hồ sơ" to same edit-profile route as L165 or remove if duplicate.** | `FE/lib/screens/admin/admin_shell.dart:169-179` |
| D2 | `_onMarkRead`: on failure, re-emit previous state + surface error (match load-path handling at L27) instead of `catch (_) {}` | `FE/lib/blocs/notification/notification_bloc.dart:46` |
| D3 | `_onLoadCategories`: emit categories-error/empty flag on failure instead of silent swallow; UI keeps chips hidden but log via `debugPrint` | `FE/lib/blocs/product/product_bloc.dart:77` |
| D4 | Delete `MockLoginEvent` + `_onMockLogin` handler (dead code, guarded by kReleaseMode but unused). **Keep** existing `mock-` guards elsewhere (harmless). Remove event class + handler + any test refs. | `FE/lib/blocs/auth/auth_bloc.dart:119-150`, `FE/lib/blocs/auth/auth_event.dart:45-47` |
| D5 | Replace `via.placeholder.com/150` with local asset or existing app placeholder pattern (check how customer product cards render missing images — reuse) | `FE/lib/screens/manager/products/manager_product_detail_screen.dart:219`, `.../manager_product_list_screen.dart:415` |
| D6 | "Quản trị BigStyle"/"Quản trị" badge → derive from authenticated user role/name (AuthBloc state) | `FE/lib/screens/manager/products/manager_product_list_screen.dart:49,67` |

## Related Code Files
- Modify: files in table + `FE/lib/screens/orders/order_detail_screen.dart:184` (cancel gate `pending` → derive from the state machine: `order.status.nextStatuses.contains(OrderStatus.cancelled)` — `nextStatuses` is an instance getter, `order_status.dart:33`)
- Tests: `FE/test/blocs/` notification_bloc_test, product_bloc_test (extend/create), auth bloc test refs cleanup

## Implementation Steps (TDD)
0. **Repatriate `cancel_my_order` (blocking pre-step):** the RPC is called from `order_service.dart:191` but defined in NO repo SQL (schema.sql, migrations — grep empty); it lives only on the hosted DB (drift; draft SQL exists in `plans/260703-2142-app-feature-gap-closure/phase-05-order-cancel-timeline.md`). Dump live definition (`select pg_get_functiondef(oid) from pg_proc where proname='cancel_my_order'`), commit as idempotent `create or replace` migration in `FE/supabase/migrations/` + append to `schema.sql`, and **verify in the dumped source** that it permits `confirmed` before widening the UI gate. If it doesn't, extend it in the same migration.
1. **Tests first:** (a) NotificationBloc mark-read failure → state preserves list + exposes error; (b) ProductBloc categories failure → explicit error/empty signal not silent; (c) cancel-gate helper: cancellable iff `nextStatuses` contains `cancelled` (pending, confirmed true; shipping/delivered/cancelled false). Run → red where behavior new.
2. Implement D2, D3, cancel gate → green.
3. D1, D5, D6 (UI-only; snapshot via analyze + existing widget tests).
4. D4 delete dead code; fix any compile fallout (`main.dart:140-147` listener references mock check — verify it survives or simplify).
5. `flutter analyze` 0, full `flutter test`, hardcode-color guard script.

## Success Criteria
- [ ] Confirmed order shows cancel button; cancel works via existing `OrderCancel` flow; shipping/delivered do not.
- [ ] D1–D6 all closed as specified; no `via.placeholder.com` left in lib/ (`grep` clean).
- [ ] `MockLoginEvent` absent from codebase; app compiles; mock-guard call sites unaffected.
- [ ] analyze 0, all tests green.

## Risk Assessment
- D4 removal may break `main.dart` auth listener if it checks `mock-` ids — verify before deleting; keep guards that read `id.startsWith('mock-')` (inert but harmless) to minimize blast radius.
- Cancel-on-confirmed: permitted-status set is verified from the dumped function source in step 0 (repo-canonical after this phase), not from live-DB memory; Phase 5 re-verifies end-to-end.
