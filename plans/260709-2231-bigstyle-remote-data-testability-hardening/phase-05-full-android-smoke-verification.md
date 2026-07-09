---
phase: 5
title: "Full Android Smoke Verification"
status: pending
priority: P1
effort: "2h"
dependencies: [1, 2, 3, 4]
---

# Phase 5: Full Android Smoke Verification

## Overview

Rerun Android emulator smoke after remote data/auth/image fixes and produce a
single evidence-backed report for demo readiness.

## Requirements

- Functional: manager and customer flows both verified on emulator.
- Functional: product edit path proves Phase 1+2 together work.
- Non-functional: screenshots avoid personal email/account info.
- QA: every failed flow gets root cause and next action.

## Architecture

Smoke flow order:

```text
Preflight checks
  -> Android launch
  -> Auth/session setup
  -> Manager catalog/order smoke
  -> Customer browse/cart/checkout/order smoke
  -> Runtime log review
  -> Markdown report
```

## Related Code Files

| File | Action | Notes |
|------|--------|-------|
| `FE/pubspec.yaml` | Verify | `.env` asset already added during prior test |
| `FE/lib/services/product_service.dart` | Verify | RPC caller |
| `FE/lib/screens/manager/products/manager_product_detail_screen.dart` | Smoke | Edit product preserves variant color |
| `FE/lib/screens/checkout/checkout_screen.dart` | Smoke | Customer checkout |
| `plans/260709-2231-bigstyle-remote-data-testability-hardening/reports/` | Create | Final smoke report and screenshots |

## File Inventory

| Path | Action | Test impact |
|------|--------|-------------|
| `plans/.../reports/` | Create report/screenshots | Persistent QA evidence |
| `FE/test/` | Run existing tests | Regression gate |
| Android emulator state | Use/reset as needed | Session-dependent verification |

## Dependency Map

- Depends on all prior phases.
- Feeds back into stability plan runtime verification.

## Implementation Steps

1. Run static checks:
   ```bash
   cd FE
   flutter analyze
   flutter test
   ```
2. Boot `pixel8` emulator.
3. Launch app with `flutter run -d emulator-5554`.
4. Manager smoke:
   - Login/session as selected manager.
   - Dashboard stats.
   - Product tab shows seed products.
   - Open existing product edit.
   - Perform a minimal safe edit only if user approves data mutation; otherwise
     stop before save and verify form data loads.
   - Orders tab/detail/status sheet.
   - Categories/vouchers list.
5. Customer smoke:
   - Login/session as customer.
   - Home/product list/product detail.
   - Add to cart.
   - Checkout COD or bank transfer.
   - Orders list/detail.
6. Review runtime logs:
   - No missing RPC errors.
   - No product image 404.
   - No fatal Flutter exceptions.
7. Save report under this plan's `reports/` directory.
8. Delete/redact screenshots with personal account/email info.

## Test Scenario Matrix

| Area | Critical checks |
|------|-----------------|
| Manager catalog | 15 products visible, edit form opens, RPC save path available |
| Manager orders | 6 orders visible, detail opens, status sheet warns bank transfer unpaid |
| Customer browse | products/images/categories render |
| Customer cart | add/edit/remove/checkout selected items |
| Checkout | empty guard, COD or QR, order appears |
| Runtime logs | no RPC missing, no image 404, no crash |

## Success Criteria

- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] Manager product list shows remote seed products.
- [ ] Manager product edit path reaches save-ready state; save verified if approved.
- [ ] Customer cart/checkout/orders run end-to-end on real session.
- [ ] Final report saved with screenshots/log notes.
- [ ] No private account screenshot remains in report folder.

## Risk Assessment

- Risk: saving product/order status mutates demo data. Mitigation: ask for
  approval before irreversible edit/status changes; prefer reversible test row.
- Risk: emulator session state hides auth bugs. Mitigation: test at least one
  cold launch after session setup and document session source.
