---
phase: 3
title: "Revenue Query Normalization"
status: completed
priority: P1
effort: "0.75d"
dependencies: [1]
---

# Phase 3: Revenue Query Normalization

## Overview

Make admin and manager revenue numbers use one documented business rule and
cover it with unit tests. Avoid another split where admin sums all orders while
manager uses status/date-specific logic.

## Requirements

- Functional: admin total revenue excludes cancelled/refunded/unpaid orders.
- Functional: manager today revenue uses same accepted-status rule and local-day logic.
- Functional: dashboard labels match the query scope.
- Non-functional: revenue logic unit-tested with fixed dates.

## Architecture

Current paths:

- Admin: `AdminService.getDashboardStats()` sums every `orders.total`.
- Manager: `OrderService.getDashboardStats()` fetches rows; `ManagerDashboardStats.fromRows()` filters statuses and today.

Decision:

- Define one accepted order-status set for recognized revenue:
  `confirmed`, `shipping`, `delivered`.
- Do not count `pending`, `cancelled`, `refunded`.
- Admin "Tổng doanh thu" = recognized revenue across all time.
- Manager "Doanh thu hôm nay" = recognized revenue for current local date.

## File Inventory

| Path | Action | Test impact |
|---|---|---|
| `FE/lib/services/admin_service.dart` | Modify | Query only needed order fields; compute recognized revenue. |
| `FE/lib/models/manager_dashboard_stats.dart` | Modify if sharing helper | Preserve today revenue behavior. |
| `FE/lib/services/order_service.dart` | Modify if helper moved | Keep dashboard fetch shape stable. |
| `FE/test/models/manager_dashboard_stats_test.dart` | Create/extend | Fixed-date manager revenue tests. |
| `FE/test/services/admin_dashboard_stats_test.dart` | Create | Admin revenue tests with fake rows/helper. |

## Tests Before

- Add failing test: admin revenue ignores pending/cancelled/refunded.
- Add failing test: admin revenue includes confirmed/shipping/delivered.
- Add fixed-date test: manager today revenue ignores yesterday and pending.

## Implementation Steps

1. Introduce a small pure helper for recognized revenue calculation.
2. Refactor `AdminService.getDashboardStats()` to request only required fields:
   `total,status,created_at`.
3. Apply the helper for admin all-time revenue.
4. Apply or align the same helper/status set for manager today revenue.
5. Keep public dashboard map keys stable: `totalRevenue`, `totalUsers`, etc.
6. Update dashboard labels only if they currently imply a different scope.
7. Add report notes with the exact revenue rule.

## Test Scenario Matrix

| Scenario | Priority | Expected |
|---|---|---|
| Confirmed order counted | Critical | Included in admin and manager if date matches. |
| Delivered order counted | Critical | Included. |
| Pending order ignored | Critical | Excluded. |
| Cancelled/refunded ignored | Critical | Excluded. |
| Different local date | High | Excluded from manager today revenue only. |
| Null/invalid total | Medium | Treated as 0, no crash. |

## Refactor

- Prefer a pure Dart helper over adding a broad repository layer.
- Do not introduce a new analytics service unless it removes real duplication.

## Tests After

- Add one widget smoke only if labels or formatting change.
- Keep Supabase query integration manual-smoke in Phase 7.

## Regression Gate

```bash
cd FE
flutter analyze
flutter test
```

## Success Criteria

- [x] Admin total revenue no longer counts pending/cancelled/refunded.
- [x] Manager today revenue uses the same accepted-status rule.
- [x] Revenue helper/status rule covered by tests.
- [x] Dashboard map contract unchanged for UI consumers.

## Risk Assessment

- Risk: business expects paid bank transfer only, not status. Mitigation: document
  this rule now; if payments status becomes source of truth later, add a separate
  migration/plan.
- Risk: timezone mismatch. Mitigation: manager today test uses fixed `DateTime`.

## Security Considerations

- Revenue queries must remain read-only.
- Do not expose per-user private order details in admin stats beyond counts/sums.

## Dependency Map

Can run after Phase 1. Phase 4 expands tests around this rule; Phase 7 runtime
smoke confirms numbers against remote seed data.
