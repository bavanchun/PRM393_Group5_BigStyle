# Regression Coverage Expansion

Date: 2026-07-10
Branch: `dev`

## Summary

Expanded focused regression coverage before the larger UI modularization phases.

## Added Coverage

- `FE/test/blocs/admin_bloc_test.dart`
  - Admin invite success reloads users and forwards `brandName`.
  - Admin invite failure surfaces an error.
- `FE/test/services/admin_service_test.dart`
  - Admin invite calls `admin-invite-user` function with the expected payload.
  - Function failure maps to a readable exception.
- `FE/test/models/revenue_recognition_test.dart`
  - Recognized revenue includes only `confirmed`, `shipping`, `delivered`.
  - Manager today revenue excludes other local dates and unrecognized statuses.
  - UTC timestamp boundary around the local dashboard day is covered.
- `FE/test/blocs/checkout_bloc_test.dart`
  - Empty checkout items are blocked before order service call.
  - COD checkout success creates order and pending payment.
- `FE/test/services/product_service_test.dart`
  - Product update RPC payload preserves variant `color_hex` and rewrites
    variant `product_id` to the product being updated.

## Code Changes

- `FE/lib/blocs/checkout/checkout_bloc.dart`
  - Added a Bloc-level empty-item guard.
  - Added optional test seams for order and payment creation callbacks.
- `FE/lib/services/product_service.dart`
  - Extracted `buildUpdateProductWithVariantsParams()` as a pure payload helper.

## Verification

- `cd FE && flutter analyze`: PASS, no issues.
- `cd FE && flutter test`: PASS, 13 tests.
- `cd FE && flutter test --coverage`: PASS, 13 tests.
- LCOV summary: `LH=216`, `LF=999`, line coverage `21.62%`.

## Notes

The coverage percentage is still low because most UI screens remain untested.
This phase intentionally focused on high-risk logic seams before modularizing
large screens.

## Unresolved Questions

None.
