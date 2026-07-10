---
phase: 5
title: "Test Harness And Smoke Matrix"
status: completed
priority: P1
effort: "1d"
dependencies: [4]
---

# Phase 5: Test Harness And Smoke Matrix

## Overview

Create a minimal regression safety net before large UI modularization. Current
repo has no `FE/test` or `FE/integration_test` files despite older journals
mentioning a prior test harness.

## Requirements

- Functional: Add focused tests for highest-risk fixed behavior.
- Functional: Define manual smoke matrix for customer/manager/admin.
- Non-functional: Keep tests cheap enough for student workflow.
- Non-functional: Avoid requiring live Supabase for unit/widget tests unless
  explicitly marked integration/manual.

## Architecture

Use Flutter's built-in `flutter_test` first. Add dependency injection seams only
when needed and small:

```text
Pure model/state tests -> no Supabase
Widget guards -> pump screen with fake/mock bloc state if practical
Service RPC contract -> manual/integration checklist if Supabase client hard to fake
```

## File Inventory

| File | Action | Size/Risk | Test impact |
|------|--------|-----------|-------------|
| `FE/test/` | Create | New test tree | Main deliverable |
| `FE/test/product_variant_color_test.dart` | Create | Low | Locks Phase 1 behavior if extractable |
| `FE/test/checkout_empty_guard_test.dart` | Create if feasible | Medium | Widget guard |
| `FE/test/error_state_rendering_test.dart` | Create if feasible | Medium | Widget/state rendering |
| `FE/test/manager_bloc_test.dart` | Create if bloc is injectable enough | Medium | Manager update/load |
| `plans/260709-2030-bigstyle-stability-hardening/reports/smoke-matrix.md` | Create | Manual QA report | Runtime evidence |
| `FE/pubspec.yaml` | Modify only if test helpers needed | Dependency risk | Prefer no new deps first |

## Interface Checklist

- [x] `flutter test` runs without Supabase initialization failure.
- [x] Tests do not require `.env`.
- [x] Any fake service/client is local to tests.
- [x] Manual smoke matrix includes exact actor, route, action, expected result.
- [x] CI/dev commands documented in report.

## Dependency Map

```text
Phases 1-4 behavior -> tests/smoke lock baseline
Phase 5 coverage -> Phase 6 modularization safety gate
```

## Implementation Steps

1. Create `FE/test/` structure.
2. Start with pure tests where possible:
   - `VariantModel` map/toMap preserves `color_hex`.
   - `ProductState.filteredProducts` still handles category/size/sale.
3. Add widget/logic tests for checkout empty guard if screen dependencies are
   manageable.
4. Add state rendering tests for one representative error/empty screen.
5. Add manager bloc test only if `OrderService` can be injected/faked without
   large refactor; otherwise document as manual integration.
6. Write `reports/smoke-matrix.md`:
   - Guest launch/login.
   - Customer cart/checkout/COD/bank-transfer pay-again.
   - Manager orders/status/product edit.
   - Admin dashboard basic render if in scope.
7. Run:
   - `flutter analyze`
   - `flutter test`
   - optionally `flutter test --coverage`

## Test Scenario Matrix

| Scenario | Type | Expected |
|----------|------|----------|
| `VariantModel.fromMap/toMap` roundtrip | Unit | `color_hex` preserved |
| Product filters | Unit | category/size/sale combinations stable |
| Empty checkout | Widget/manual | no dispatch, visible message |
| Error vs empty screen | Widget | error renders separately |
| Manager order update | Bloc/manual | success/error state visible |
| Full customer purchase | Manual smoke | completes |
| Manager product edit color | Manual smoke | color persists after reopen |

## Success Criteria

- [x] `FE/test` exists.
- [x] `flutter test` passes.
- [x] Smoke matrix report exists.
- [x] Tests cover at least Phase 1 and one Phase 3 behavior.
- [x] Known unautomated cases are explicitly listed, not implied covered.

## Risk Assessment

- Risk: widget tests require app-wide Supabase initialization. Mitigation: prefer
  pure tests first and isolate widgets with provided blocs.
- Risk: adding mock libraries creates dependency churn. Mitigation: use simple
  fakes first; add package only if benefit is clear.

## Security Considerations

Tests must not commit secrets or read `FE/.env`.
