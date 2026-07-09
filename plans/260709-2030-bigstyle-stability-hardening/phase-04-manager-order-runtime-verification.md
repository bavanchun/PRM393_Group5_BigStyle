---
phase: 4
title: "Manager Order Runtime Verification"
status: blocked
priority: P1
effort: "4h"
dependencies: [3]
---

# Phase 4: Manager Order Runtime Verification

## Overview

Runtime verify manager order list/detail/status-update flow on emulator/device.
Only fix code if the old blank-tab or silent-update issue still reproduces.

## Requirements

- Functional: Manager order tab renders loading/empty/error/data correctly.
- Functional: Filter chips reload expected orders.
- Functional: Status update sheet shows progress, success close, or visible
  error.
- Functional: Manager order detail reflects updated state after update/reload.
- Non-functional: Capture screenshots or notes under `plans/.../reports/`.

## Architecture

Existing flow:

```text
ManagerOrdersScreen.initState -> ManagerLoadOrders
ManagerBloc._onLoadOrders -> OrderService.getAllOrders
ManagerOrderCard -> ManagerOrderDetailScreen / showOrderStatusUpdateSheet
OrderStatusUpdateSheet -> ManagerUpdateOrderStatus -> reload orders
```

This phase is verification-first. If runtime behavior passes, record it and do
not rewrite.

## File Inventory

| File | Action | Size/Risk | Test impact |
|------|--------|-----------|-------------|
| `FE/lib/screens/manager/manager_orders_screen.dart` | Verify/modify if needed | Medium | Smoke test |
| `FE/lib/blocs/manager/manager_bloc.dart` | Verify/modify if needed | Medium | Bloc test in Phase 5 if changed |
| `FE/lib/screens/manager/order_status_update_sheet.dart` | Verify/modify if needed | Medium | Widget/manual |
| `FE/lib/screens/manager/manager_order_detail_screen.dart` | Verify/modify if needed | Medium | Manual |
| `FE/lib/services/order_service.dart` | Read/modify if query wrong | Shared service | Integration/manual |
| `plans/260709-2030-bigstyle-stability-hardening/reports/manager-order-smoke.md` | Create | Report | Records evidence |

## Interface Checklist

- [ ] `ManagerLoadOrders(status)` updates `selectedStatus`.
- [ ] `_ordersRequestId` does not leave stuck `isUpdatingStatus`.
- [ ] `ManagerOrdersScreen` listens to `state.error`.
- [ ] Status sheet does not pop before update result.
- [ ] Detail screen does not display stale order after update.

## Dependency Map

```text
Requires seeded/real manager account
Phase 4 evidence -> Phase 5 smoke matrix baseline
If code changes happen -> Phase 5 adds tests for changed behavior
```

## Implementation Steps

1. Prepare manager account/session:
   - use existing demo seed/runbook if available.
   - do not read `.env` without explicit approval.
2. Run app on emulator/device.
3. Verify:
   - manager dashboard opens.
   - orders tab shows data or correct empty state.
   - filters work.
   - detail opens.
   - status update succeeds for allowed transition.
   - failed update shows visible error.
4. If blank tab reproduces:
   - add temporary logging locally to inspect `state.orders.length`.
   - inspect `ManagerOrderCard` rendering constraints.
   - fix the smallest confirmed root cause.
5. If status update race reproduces:
   - split load/update request ids or adjust listener semantics.
6. Save report in `plans/260709-2030-bigstyle-stability-hardening/reports/`.
7. Run `flutter analyze`.

## Test Scenario Matrix

| Scenario | Type | Expected |
|----------|------|----------|
| Manager opens orders tab with seeded orders | Runtime | Cards render |
| Filter pending/confirmed | Runtime | List changes or valid empty state |
| Update pending -> confirmed | Runtime | Sheet closes, list/detail update |
| Simulate update failure | Runtime/manual | Error visible, sheet/list not stale |
| Pull refresh | Runtime | Reload completes |

## Success Criteria

- [ ] Runtime report created with pass/fail evidence.
- [ ] Manager orders tab no longer has unverified blank-tab risk.
- [ ] Status update outcome visible to manager.
- [ ] `flutter analyze` passes after any code changes.

## Risk Assessment

- Risk: no manager account/data available. Mitigation: document blocker in
  runtime report and keep code changes blocked until reproducible.
- Risk: old audit finding was role-flip/session artifact. Mitigation: verify
  before editing.

## Security Considerations

Do not bypass RLS. Do not introduce service-role credentials into Flutter.
