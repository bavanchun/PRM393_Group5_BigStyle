# Revenue Query Normalization

Date: 2026-07-10
Branch: `dev`

## Summary

Admin and manager dashboard revenue now use one shared recognized-revenue rule.

Recognized revenue statuses:

- `confirmed`
- `shipping`
- `delivered`

Excluded statuses:

- `pending`
- `cancelled`
- `refunded`
- any unknown status

## Code Changes

- `FE/lib/models/revenue_recognition.dart`
  - Added a pure helper for recognized all-time revenue and recognized revenue
    for a specific local date.
- `FE/lib/services/admin_service.dart`
  - Admin query filters recognized statuses server-side, selects only
    `total,status`, and sums recognized orders for `totalRevenue`.
  - Dashboard map contract stays unchanged.
- `FE/lib/models/manager_dashboard_stats.dart`
  - Manager today revenue now calls the shared helper instead of keeping a
    separate inline accepted-status set.
- `FE/test/models/revenue_recognition_test.dart`
  - Covers admin all-time recognized revenue.
  - Covers manager local-day revenue with fixed date, excluding other dates and
    unrecognized statuses.
  - Covers UTC timestamp boundary behavior around the local dashboard day.

## Verification

- `cd FE && flutter analyze`: PASS, no issues.
- `cd FE && flutter test`: PASS, 10 tests.

## Notes

The rule is still order-status based, not payment-status based. If payment
status becomes the source of truth later, handle that as a separate change with
payment/order reconciliation tests.

## Unresolved Questions

None.
