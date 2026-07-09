---
phase: 4
title: "Regression Coverage Expansion"
status: completed
priority: P1
effort: "1d"
dependencies: [2, 3]
---

# Phase 4: Regression Coverage Expansion

## Overview

Raise confidence before large UI refactors. Add focused tests for flows already
fixed or about to be protected: auth debug guard, checkout empty guard/cart clear,
product RPC mapping, admin invite boundaries, and revenue calculation.

## Requirements

- Functional: tests cover the high-risk code paths from prior fixes.
- Functional: tests must not hit remote Supabase.
- Non-functional: use dependency injection/mocks over network calls.

## Architecture

Current tests:

- `FE/test/models/product_variant_mapping_test.dart`
- `FE/test/widgets/app_error_state_test.dart`

Add tests around pure helpers and Bloc/service seams. If code is not testable,
add minimal injection points as part of the phase and keep them private to the
current architecture.

## File Inventory

| Path | Action | Test impact |
|---|---|---|
| `FE/test/blocs/auth_bloc_test.dart` | Create | Release/debug guard where feasible. |
| `FE/test/blocs/checkout_bloc_test.dart` | Create | Empty items and success paths. |
| `FE/test/blocs/admin_bloc_test.dart` | Create | Admin invite success/failure. |
| `FE/test/models/manager_dashboard_stats_test.dart` | Create | Revenue date/status rule. |
| `FE/test/services/product_service_test.dart` | Create if mockable | RPC payload shape. |
| `FE/lib/services/*` | Modify minimally | Add injection seams only where tests require. |

## Tests Before

- Write tests that fail because seams or helpers do not exist yet.
- Keep each test small and name the business behavior, not phase/finding codes.

## Implementation Steps

1. Add test dependencies only if already available or small; avoid heavy mocking
   frameworks unless needed.
2. Extract pure revenue helper if Phase 3 did not already.
3. Add fakes for `AuthService`, `GoogleAuthService`, `OrderService`,
   `CartService`, and `AdminService` as needed.
4. Test `AuthBloc.PasswordSignInEvent`:
   - success path in debug-compatible environment
   - service failure emits error
   - release guard is documented/static-verified if runtime impossible
5. Test checkout:
   - empty selected items blocked before service call
   - COD success clears selected cart items/state
6. Test admin invite Bloc:
   - success reloads users or updates state
   - failure surfaces error
7. Test product update RPC payload:
   - `color_hex` preserved
   - variants passed through RPC replacement payload
8. Record coverage delta in phase report.

## Test Scenario Matrix

| Scenario | Priority | Expected |
|---|---|---|
| Auth debug login service success | High | Emits `AuthSuccess`. |
| Auth debug login service failure | High | Emits `AuthError`. |
| Checkout empty selected list | Critical | No order service call; visible error. |
| Checkout COD success | Critical | Cart state clears selected items. |
| Product update payload | Critical | `color_hex` preserved in variants. |
| Admin invite failure | Critical | Error state/snackbar path. |
| Revenue helper | Critical | Accepted statuses only. |

## Refactor

- Add test seams only where they reduce future risk.
- Do not change UI layout in this phase.

## Tests After

- Run full test suite.
- If coverage tooling is available, run `flutter test --coverage` and record
  line coverage. Target improvement, not arbitrary 80% in this phase.

## Regression Gate

```bash
cd FE
flutter analyze
flutter test
flutter test --coverage
```

## Success Criteria

- [x] At least 5 new targeted tests added.
- [x] No test uses remote Supabase.
- [x] Tests cover admin invite, revenue, checkout guard, and product variant color.
- [x] `flutter test --coverage` passes and report notes coverage delta.

## Risk Assessment

- Risk: over-mocking implementation details. Mitigation: assert behavior and
  service call boundaries, not every internal state transition.
- Risk: release-mode auth guard hard to unit test. Mitigation: static check plus
  test debug-compatible behavior.

## Security Considerations

- Do not put QA credentials in tests.
- Use fake emails and fake UUIDs only.

## Dependency Map

Depends on Phases 2-3 because tests should cover the final invite and revenue
contracts. Provides guardrail for Phases 5-6 refactors.
