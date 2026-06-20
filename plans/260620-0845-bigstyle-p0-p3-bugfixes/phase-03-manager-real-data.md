---
phase: 3
title: "Manager real data"
status: completed
priority: P2
effort: "3h"
dependencies: [1]
---

# Phase 3: Manager real data

## Overview
Replace the 100%-hardcoded Manager module (Dashboard stats + Orders list) with real Supabase queries. RLS already lets a manager session read all orders via `is_manager()`; we add the missing service methods, a model field for customer name, and a ManagerBloc.

## Requirements
- Functional: Dashboard shows real revenue/order/product/customer counts; Orders screen lists real orders, filter chips filter by real status, "Chi tiết" opens the existing order detail.
- Non-functional: no schema change (RLS already supports it); `flutter analyze` clean.

## Key Insights (verified, file:line)
- RLS ready: `schema.sql` `"Managers manage all orders"` L245-247, `"Managers see all order items"` L258-260, `is_manager()` L41-52 → a `from('orders').select(...)` with **no** user filter returns all rows under a manager session.
- `order_service.dart` — only user-scoped `getOrders(userId)` L7-14; **no `getAllOrders` / no stats**. Add them.
- `order_model.dart` — `fromMap` L88-108 does **not** parse a customer name; no `customerName` field. Add one (join `profiles(full_name)` or read from `shipping_address` jsonb).
- **Enum mismatch**: `manager_orders_screen.dart` `_statusLabels` use `'preparing'` but DB `order_status` enum is `'processing'` (schema L193-201). Confirm `lib/models/order_status.dart` and align labels to DB values.
- Hardcoded data to replace: `manager_dashboard.dart:48-178` (stats L57-60, recent orders L172-175); `manager_orders_screen.dart:44-167` (`itemCount:12` L46, fake card L94-167).
- BLoC pattern reference: `lib/blocs/order/` (3-file `*_bloc/_event/_state`, service injected via ctor). Register new bloc in `main.dart` provider list (L42-60).

## Architecture
- **OrderService additions**: `getAllOrders({String? status})` — `from('orders').select('*, customer:profiles(full_name), items:order_items(*, product:products(*))').order('created_at', desc)`, optional `.eq('status', status)`. `getDashboardStats()` — counts + revenue sum (use `count: CountOption.exact` head requests and a sum; or fetch minimal columns and aggregate client-side for KISS).
- **ProductService**: reuse existing for product count, or add a count head request.
- **OrderModel**: add `customerName` (nullable) parsed from joined `customer.full_name` (fallback to `shipping_address['name']`).
- **ManagerBloc** (`lib/blocs/manager/`): events `ManagerLoadDashboard`, `ManagerLoadOrders(status)`; state holds stats + orders + isLoading + error. Inject `OrderService` (+ `ProductService` if needed).
- **Screens**: `ManagerDashboard` and `ManagerOrdersScreen` become `BlocBuilder`-driven; convert hardcoded widgets to data-bound; wire filter chips to dispatch `ManagerLoadOrders(status)`; "Chi tiết" → `Navigator.pushNamed('/order-detail', arguments: order)`.

## Related Code Files
- Modify: `lib/services/order_service.dart` (add `getAllOrders`, `getDashboardStats`)
- Modify: `lib/models/order_model.dart` (add `customerName`)
- Modify: `lib/models/order_status.dart` (align labels with DB enum; fix `preparing`→`processing`)
- Create: `lib/blocs/manager/manager_bloc.dart`, `manager_event.dart`, `manager_state.dart`
- Modify: `lib/main.dart` (provide `ManagerBloc`)
- Modify: `lib/screens/manager/manager_dashboard.dart` (bind to ManagerBloc)
- Modify: `lib/screens/manager/manager_orders_screen.dart` (bind, real filter, wire detail)

## Implementation Steps
1. Use `/mobile-development` skill.
2. Read `order_status.dart`; reconcile enum/labels with DB (`pending, confirmed, processing, shipping, delivered, cancelled, refunded`).
3. Add `getAllOrders({status})` + `getDashboardStats()` to OrderService.
4. Add `customerName` to OrderModel.fromMap (joined profiles).
5. Create ManagerBloc trio; register in `main.dart`.
6. Rebuild ManagerDashboard with real stats + recent orders (limit 4-5 from getAllOrders).
7. Rebuild ManagerOrdersScreen: load real orders, apply status filter via bloc, wire "Chi tiết" to `/order-detail`.
8. Verify under a **real manager account** (a profiles row with `role='manager'`): seed/promote one if none exists (note in PR). `cd FE && flutter analyze` clean.
9. Commit + PR via `/vchun-git prc`.

## Success Criteria
- [x] Dashboard shows real counts/revenue (no `12.5tr/8/156/234` constants)
- [x] Orders screen lists real orders; `itemCount` driven by data
- [x] Filter chips filter by real DB status; labels match DB enum
- [x] "Chi tiết" opens real order detail
- [x] `flutter analyze` clean (0 errors; 3 pre-existing info lints outside Phase 3)
- [x] ≥1 commit + PR via `/vchun-git prc`

## Risk Assessment
- **No manager account exists** → manager queries return nothing/blocked. Mitigate: promote a test profile to `role='manager'` via SQL Editor; document in PR.
- **Stats cost**: avoid N+1; prefer count head requests / single aggregate query.
- **Enum drift**: a wrong status string silently filters to empty. Verify against DB enum before shipping.

## Security Considerations
- All manager reads rely on `is_manager()` RLS; a non-manager session returns nothing (safe by default). No service-role key in client.
