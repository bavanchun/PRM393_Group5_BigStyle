---
phase: 6
title: "Email-Password Sign-In & Sign-Up"
status: completed
priority: P2
dependencies: []
effort: "M"
---

# Phase 6: Email-Password Sign-In & Sign-Up

## Overview
Add standard email+password đăng nhập/đăng ký alongside OTP and Google. Sign-IN service+bloc exist (`AuthService.signInWithPassword` `auth_service.dart:61-72`, `_onPasswordSignIn` `auth_bloc.dart:77-97`) **but are debug-only**: handler starts with `if (kReleaseMode) return;` (`auth_bloc.dart:81`) and uses test-flavored copy ("Đăng nhập test thất bại") — reachable only via hidden dart-define quick-login (`login_screen.dart:421-465,483-487`). This phase productionizes sign-in and adds sign-up.

## Requirements
- Functional: login screen defaults to **password form** (user decision), single secondary link switches to OTP flow (exact copy in UI section), Google unchanged; Đăng ký collects họ tên + email + password + confirm; role redirect identical (AuthSuccess → splash). Password ≥6 chars (Supabase default) via **new `validatePassword`** in `FE/lib/utils/validators.dart` (net-new — only `validateEmail` exists, validators.dart:7).
- Non-functional: OTP flow + its tests untouched; `_verifyInFlight` semantics in login_screen (fragile OTP state machine, L40-52,96-105) unaffected by password-form states; color guard 0.
- **Precondition (user decision):** hosted Supabase "Confirm email" turned **OFF** — verified as Phase 5 runbook item; code still defends both paths.

## Architecture
- **Remove debug guard (red-team F1):** delete `if (kReleaseMode) return;` from `_onPasswordSignIn`; replace test error copy with production Vietnamese messages. The TDD "lock existing behavior" test locks the NEW production behavior (wrong password → AuthError), not the dev-only guard.
- **Name persistence via trigger, NOT client backfill (F2/F3):** the OTP-flow backfill pattern is itself broken (inverted null-check `auth_service.dart:46-57` — full_name never written) and client backfill is impossible in the confirmation-pending case (no session ⇒ RLS blocks). Therefore: **migration required** (`FE/supabase/migrations/<ts>_handle_new_user_full_name.sql` + schema.sql): amend `handle_new_user` to `insert (id, email, full_name) values (new.id, new.email, new.raw_user_meta_data->>'full_name')`. `signUp(..., data: {'full_name': fullName})` supplies metadata. Bonus: also fixes the OTP-flow name loss for future signups. (Fixing the broken client backfill helper is optional cleanup — remove or correct it, don't copy it.)
- **Service:** `AuthService.signUpWithPassword({email, password, fullName})` → `_client.auth.signUp(email:, password:, data: {'full_name': fullName})`.
- **Duplicate email (F4):** confirmations OFF → Supabase throws "User already registered" → map to "Email đã được đăng ký — hãy đăng nhập". Defensive branch for confirmations ON: `response.user?.identities?.isEmpty == true` ⇒ treat as already-registered (Supabase returns obfuscated fake user, no exception) — NOT confirmation-pending.
- **Bloc:** `PasswordSignUpEvent{email,password,fullName}`; states reuse `AuthLoading`/`AuthSuccess`/**`AuthError`** (F5: `AuthFailure` does not exist — splash depends on `AuthError`, splash_screen.dart:48) + new `AuthSignUpConfirmationPending` (defensive path only). **Register both password handlers with `droppable()` from `bloc_concurrency` (F6)** — double-tap submit must not race; UI button-disable alone is insufficient. (Other auth handlers keep current transformer — app-wide change stays the separate known-limitation item.)
- **UI (F7 — listener ownership explicit):** new `FE/lib/screens/auth/password_auth_form.dart` owns its OWN `BlocListener` for `AuthSignUpConfirmationPending` and signup/sign-in `AuthError` display; login_screen's existing `BlocConsumer` (L96-105) is NOT modified for these states and `_showOtp`/`_verifyInFlight` remain OTP-only. Mode switch in login_screen: password form default, Google button + quick-login intact. **Single OTP entry control** (avoid two competing links): one link under the form — "Quên mật khẩu hoặc muốn dùng mã OTP? Đăng nhập bằng OTP" — switches to the OTP flow.

## Related Code Files
- Create: `FE/lib/screens/auth/password_auth_form.dart`; `FE/supabase/migrations/<ts>_handle_new_user_full_name.sql`; `FE/test/blocs/auth_password_test.dart`
- Modify: `FE/lib/services/auth_service.dart` (signUpWithPassword; remove/fix broken backfill helper), `FE/lib/blocs/auth/auth_event.dart`, `auth_state.dart` (+AuthSignUpConfirmationPending), `auth_bloc.dart` (remove kReleaseMode guard, droppable(), signup handler, prod error copy), `FE/lib/utils/validators.dart` (+validatePassword), `FE/lib/screens/auth/login_screen.dart` (mode switch host), `FE/schema.sql` (handle_new_user)

## Implementation Steps (TDD)
1. **Tests first** (`auth_password_test.dart`, FakeAuthService DI): (a) sign-in success → AuthSuccess **in release-equivalent path** (no kReleaseMode skip); wrong password → AuthError with prod copy; (b) signup session → AuthSuccess; (c) signup AuthException user-exists → AuthError mapped; (d) signup fake-user (empty identities, no session) → AuthError already-registered (not ConfirmationPending); (e) genuine no-session → AuthSignUpConfirmationPending; (f) rapid double PasswordSignUpEvent → second dropped (droppable). Widget: confirm mismatch blocks; validatePassword <6 blocks; loading disables. Red.
2. Bloc/service changes → green.
3. `password_auth_form.dart` + login_screen mode switch (own BlocListener; OTP paths untouched).
4. Migration (handle_new_user full_name) + schema.sql; rollback block in header.
5. `flutter analyze` 0, full `flutter test`, color guard 0.
6. Live checks → Phase 5 runbook (incl. verify Confirm-email OFF; signup lands `/home` with full_name from trigger).

## Success Criteria
- [ ] Release-mode password sign-in works (kReleaseMode guard removed; verified by release-path test + Phase 5 device check).
- [ ] New user đăng ký → `/home` as customer; `profiles.full_name` populated **by trigger**.
- [ ] Wrong password / duplicate email → correct Vietnamese errors; manager password login → `/manager`.
- [ ] OTP + Google + quick-login unchanged; `_verifyInFlight`/`_showOtp` untouched by new states; existing auth tests green.
- [ ] Double-tap submit safe (droppable test); analyze 0; color guard 0.

## Risk Assessment
- Migration touches `handle_new_user` (shared with OTP/Google signups) — change is additive (`raw_user_meta_data->>'full_name'` is null for those flows → column stays null, current behavior). Rollback SQL in migration header.
- Confirmations setting drift: defensive identities-check branch keeps UX sane if someone re-enables it; Phase 5 records observed behavior.
- login_screen regression — new states isolated to password_auth_form's listener; OTP tests are the guard.

## Red Team Log (phase-scoped)
2026-07-10 session: 7 findings (1 Critical, 3 High, 3 Medium), all accepted and folded in: F1 kReleaseMode dead button; F2 broken backfill pattern; F3 RLS blocks no-session backfill; F4 duplicate-email obfuscated-user path; F5 AuthFailure→AuthError; F6 droppable(); F7 listener ownership + validatePassword net-new.
