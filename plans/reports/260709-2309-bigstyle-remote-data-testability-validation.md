# Test Report - 260709-2309 - BigStyle Remote Data Testability Validation

---
type: qa-report
scope: remote-data-testability-hardening
created: "2026-07-09T23:09:00+07:00"
---

## Summary

Diff-aware mode: analyzed 5 changed files.

Changed:
- `FE/lib/blocs/auth/auth_bloc.dart`
- `FE/lib/blocs/auth/auth_event.dart`
- `FE/lib/screens/auth/login_screen.dart`
- `FE/lib/services/auth_service.dart`
- `FE/supabase/migrations/20260709100000_update_product_with_variants_rpc.sql`

Mapped:
- `FE/test/models/product_variant_mapping_test.dart` via existing Flutter suite.
- `FE/test/widgets/app_error_state_test.dart` via existing Flutter suite.

Unmapped:
- `FE/lib/blocs/auth/auth_bloc.dart` - no auth Bloc tests found.
- `FE/lib/blocs/auth/auth_event.dart` - no auth event tests found.
- `FE/lib/screens/auth/login_screen.dart` - no login widget tests found.
- `FE/lib/services/auth_service.dart` - no auth service tests found.
- `FE/supabase/migrations/20260709100000_update_product_with_variants_rpc.sql` - no database migration tests found.

## Test Results Overview

- `flutter analyze`: PASS, no issues found, 3.4s analyzer time.
- `flutter test`: PASS, 3/3 tests passed, 0 failed, 0 skipped.
- `flutter test --coverage`: PASS, 3/3 tests passed, 0 failed, 0 skipped.
- Dependency notice: 42 packages newer but incompatible with current constraints; non-blocking.

## Coverage Metrics

| Metric | Value | Threshold | Status |
|---|---:|---:|---|
| Lines | 35.36% (64/181) | 80% | FAIL |
| Branches | n/a (0/0) | 70% | NOT MEASURED |
| Functions | n/a (0/0) | 80% | NOT MEASURED |

Coverage only includes files touched by current tests. Changed auth files not present in LCOV, so current automated coverage does not exercise debug password login, OTP, Google login, or auth service paths.

## Acceptance Criteria

- `flutter analyze` passes: PASS.
- `flutter test` passes: PASS.
- Debug-only password login impossible in release mode: PASS by static verification. UI entrypoint requires `kDebugMode` and non-empty dart-defines in `FE/lib/screens/auth/login_screen.dart`; Bloc handler returns before password auth when `kReleaseMode` in `FE/lib/blocs/auth/auth_bloc.dart`.
- Debug login only visible when dart-define email/password values exist: PASS by static verification. `_hasDebugTestLogin` requires manager or customer email/password pairs.
- Existing OTP auth path not broken: PASS by static verification plus analyzer. `SendOTPEvent`, `VerifyOTPEvent`, and `AuthService.sendOtp/verifyOtp` paths remain registered and callable.
- Existing Google auth path not broken: PASS by static verification plus analyzer. `GoogleSignInEvent` handler remains registered and login button still dispatches it.
- SQL migration grants RPC execute to authenticated but not anon: PASS by static verification. Migration revokes from `public` and `anon`, grants to `authenticated`.

## Evidence

- Debug dart-defines: `FE/lib/screens/auth/login_screen.dart:21`.
- Google login dispatch: `FE/lib/screens/auth/login_screen.dart:340`.
- Debug visibility gate: `FE/lib/screens/auth/login_screen.dart:373`.
- Test login dispatch: `FE/lib/screens/auth/login_screen.dart:424`.
- Password handler registered: `FE/lib/blocs/auth/auth_bloc.dart:18`.
- Release guard before password auth: `FE/lib/blocs/auth/auth_bloc.dart:81`.
- OTP handlers unchanged and registered: `FE/lib/blocs/auth/auth_bloc.dart:16`.
- Google handler unchanged and registered: `FE/lib/blocs/auth/auth_bloc.dart:19`.
- Password Supabase call isolated in service: `FE/lib/services/auth_service.dart:58`.
- RPC permissions: `FE/supabase/migrations/20260709100000_update_product_with_variants_rpc.sql:150`.

## Failed Tests

None.

## Build Status

- Static analysis: PASS.
- Unit/widget tests: PASS.
- Coverage generation: PASS.
- Production APK/build: not run; not requested. Release-mode safety verified by source gate.

## Critical Issues

None blocking.

## Recommendations

1. Add auth Bloc tests for `PasswordSignInEvent`: debug success, debug failure, release no-op.
2. Add login widget tests for debug buttons: absent without dart-defines, present with complete manager/customer pairs.
3. Add OTP/Google regression tests around event dispatch so future debug-login edits cannot break primary auth paths.
4. Add SQL permission regression check in migration validation: assert `authenticated` has execute and `anon` lacks execute for `update_product_with_variants`.
5. Raise overall Flutter coverage above 80%; current line coverage 35.36%.

## Unresolved Questions

None.
