---
phase: 3
title: "Realtime Badge And Password Reset"
status: code-complete-pending-device-pass
effort: "medium"
---

# Phase 3: Realtime Badge And Password Reset

## Overview

Two quick product wins: (B1) notification badge updates live via Supabase
realtime instead of fetch-only; (B2) real password reset via email + deep link,
replacing the "dùng OTP thay thế" workaround.

## Requirements

- Functional B1: badge count updates without refresh when a `notifications` row is inserted/updated for the signed-in user.
- Functional B2: user requests reset email → taps link → app opens reset screen → sets new password → signs in with it.
- Non-functional: subscription torn down on sign-out (no leak across accounts); reuse existing chat realtime pattern; BLoC pattern preserved.

## Architecture

<!-- Updated: Validation Session 1 - realtime reference corrected, deep link scheme confirmed -->
- B1: `NotificationService` gains `subscribeToUserNotifications(userId)` returning a Supabase channel on `notifications` filtered `user_id=eq.{id}` — mirror the `.channel().onPostgresChanges` pattern in `FE/lib/services/payment_service.dart:73` (verified reference). `NotificationBloc` listens → re-derives unread count → existing badge widget rebuilds. Unsubscribe on auth sign-out event.
- B2: Supabase `auth.resetPasswordForEmail(email, redirectTo: 'bigstyle://reset-password')`. App handles `AuthChangeEvent.passwordRecovery` from `onAuthStateChange` → navigate to new `/reset-password` route → form calls `auth.updateUser(password: ...)`. Android deep link via intent-filter in `AndroidManifest.xml`; add redirect URL in Supabase Auth settings.
- Deep link scheme (user-confirmed): custom scheme `bigstyle://` — nhóm không có domain, app chạy local. No App Links.

## Related Code Files

- Modify: `FE/lib/services/notification_service.dart`, `FE/lib/blocs/notification/*`, `FE/lib/services/auth_service.dart`, `FE/lib/screens/auth/login_screen.dart` (add "Quên mật khẩu" action), `FE/lib/config/routes/app_router.dart`, `FE/android/app/src/main/AndroidManifest.xml`
- Create: `FE/lib/screens/auth/reset-password screen` (follow existing auth screen naming, e.g. `reset_password_screen.dart` — Dart uses snake_case)
- External: Supabase dashboard Auth redirect URLs + email template check

## Implementation Steps

1. Register `bigstyle://reset-password` redirect URL in Supabase Auth settings (scheme confirmed — no user confirmation needed).
2. B1: add channel subscription to `NotificationService`; wire into `NotificationBloc` (new event `NotificationRealtimeReceived`); unsubscribe on sign-out; badge widget unchanged (state-driven).
3. B1 tests: bloc test with mocked service stream (follow existing bloc test patterns; 104-test suite conventions).
4. B2: `AuthService.sendPasswordReset(email)`; forgot-password entry on login screen (password mode only); `onAuthStateChange` passwordRecovery listener at router/splash level; reset screen with password + confirm fields, validation matching sign-up rules.
5. B2: AndroidManifest intent-filter for scheme; manual e2e: request email → tap link on emulator → reset → re-login.
6. Gate: `flutter analyze` 0, `flutter test` xanh, hardcode-color guard 0.

## Success Criteria

- [x] Badge updates realtime on notification insert (manager order-status change proves it) <!-- notifications table added to supabase_realtime publication (migration 20260712110146); NotificationService.subscribeToChanges + NotificationBloc wired to refetch on change; visible Badge added to home_screen.dart bell icon (previously unreadCount existed in state but was never rendered anywhere — verified via full-codebase grep); bloc test proves a realtime signal updates unreadCount. Live device confirmation (tap-to-verify on an emulator) deferred to this plan's own Phase 1. -->
- [x] No subscription leak after sign-out/sign-in as different user <!-- code-reviewer found a real gap here (CRITICAL): _onLoad's terminal emit lacked the same late-arrival guard _onRealtimeReceived already had, so a slow first-account fetch could resolve after a second account signed in and overwrite/leak its notification content. Fixed: added the guard to both success and error paths of _onLoad, and unsubscribe() now also clears state (via a proper NotificationCleared event, not a direct emit call). New regression test proves a superseded user's late-resolving load no longer overwrites current state. -->
- [ ] Password reset e2e works on emulator <!-- code complete and reviewed (sendPasswordReset/updatePassword, deep-link routing, ResetPasswordScreen non-poppable with explicit cancel/sign-out to avoid an abandoned recovery session per code-reviewer HIGH finding, fixed). Two things remain outside this session's reach: registering bigstyle://reset-password as an allowed redirect URL in the Supabase Auth dashboard (no MCP tool manages Auth redirect-URL allowlists — manual, like the SePay webhook registration), and the actual device tap-through — deferred to this plan's own Phase 1. -->
- [x] Duplicate/invalid email handled with friendly error <!-- reviewer-verified: sendPasswordReset/resetPasswordForEmail don't distinguish existing vs non-existing emails (no enumeration leak); PasswordResetRequestEvent failure path emits a generic AuthError, never e.toString() -->
- [x] Analyze/test/color gates pass <!-- flutter analyze 0, flutter test 126/126 (116 baseline + 10 new: 5 realtime notification + 5 password reset/update), check_hardcoded_colors.sh exit 0 -->

### Code review (code-reviewer subagent)
2 findings, both fixed and verified (regression tests added, gates re-run clean):
1. **CRITICAL** — cross-account notification leak via unguarded late load (see above).
2. **HIGH** — abandoned recovery session could be treated as a normal login on next launch with no password ever set; fixed with `PopScope(canPop: false)` + explicit cancel-and-sign-out action on `ResetPasswordScreen`.

## Risk Assessment

- Realtime requires `notifications` table in Supabase publication → verify/enable before coding.
- Deep link on emulator flaky → test link tap via `adb shell am start` as deterministic fallback.
- passwordRecovery session semantics: user is temporarily authed — ensure route guard doesn't bounce to home before reset completes.
