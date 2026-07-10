---
phase: 5
title: "OTP resend cooldown and email validation"
status: done
effort: "0.5d"
priority: P2
dependencies: [4]
---

# Phase 5: OTP resend cooldown and email validation

## Overview
Improves G10 (no cooldown on OTP sends — spamming hits Supabase rate limits with no user feedback) and closes G8 (email validator is `v.contains('@')` — accepts `a@`, `@b`; verified still current at `login_screen.dart:230-233`).

**Red-team corrections to the original draft:**
- The cooldown is **countdown UX only**, not abuse protection (the endpoint stays reachable directly with the anon key). Rationale reworded: the hosted Supabase project's OTP resend window defaults to 60s; the repo's local-dev `FE/supabase/config.toml:230` sets `max_frequency = "1s"` with `email_sent = 2`/hour — the countdown is a client courtesy that approximates the hosted window, it does not enforce anything.
- Cooldown starts when a send is **dispatched** (not only on `AuthOTPSent` success) so failed sends can't be instantly re-hammered, and per-EMAIL (`_cooldownEmail`) so correcting a typo isn't locked behind the wrong address's timer.
- The resend path MUST reuse `_sendOtp()` — the current resend closure (`login_screen.dart:304-309`) dispatches `SendOTPEvent` gated only by `isNotEmpty`, bypassing validation entirely (and Supabase OTP send auto-creates accounts by default — junk-account surface). Residual risk note: `shouldCreateUser` stays at its default; changing `AuthService` is out of scope, documented.
- Countdown UI lives on the **resend link** (via phase 4's `resendLabel`/`resendEnabled` params). The main "Gửi mã OTP" button is unmounted once `_showOtp` flips true (`login_screen.dart:106-110`, never reset) — the original AC promising a countdown on it was unverifiable; it now only needs the cooldown GATE (in `_sendOtp()`), no countdown label.
- G10's "mystery 429": map rate-limit-shaped auth errors (`over_email_send_rate_limit` / message contains "rate limit") to a friendly Vietnamese snackbar in the existing error listener (string mapping at widget layer, no bloc change). G10 is thereby **improved, not fully closed** — server budgets can still reject within the countdown; plan makes no stronger claim.
- Verify-email drift fix: cache `_otpEmail` from `AuthOTPSent` and use it in the `onCompleted → VerifyOTPEvent` dispatch instead of falling back to live controller text (`login_screen.dart:298-302`) — after an error + email edit, verify must target the address that received the code.

## Requirements
- 60s per-email cooldown starting at send dispatch; countdown label "Gửi lại sau {n}s" on the resend link; changing to a different (validated) email bypasses the previous address's cooldown.
- `validateEmail`: accepts `hoangbavan4478+admin@gmail.com` (team's +alias accounts!), `x@y.vn`; rejects `a@`, `@b`, `a b@c.d`, `not-an-email`.
- Resend reuses `_sendOtp()` (validator + cooldown + dispatch in one path).
- Friendly rate-limit error message; other errors keep current text.
- Verify uses `_otpEmail` (from `AuthOTPSent`), never live field text.

## Architecture
- `FE/lib/utils/validators.dart`:
  ```dart
  final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    if (!_emailPattern.hasMatch(v.trim())) return 'Email không hợp lệ';
    return null;
  }
  ```
- `_LoginScreenState` additions: `Timer? _resendTimer; int _cooldown = 0; String? _cooldownEmail; String? _otpEmail;`
  - `_startCooldown(String email)`: `_resendTimer?.cancel()` FIRST (red-team: `AuthOTPSent` re-fires per resend — without cancel-before-create, `Timer.periodic` instances stack and the countdown runs at 2x+), then `_cooldown = 60; _cooldownEmail = email;` and `Timer.periodic(1s, ...)` that self-cancels at 0, with `if (!mounted) { t.cancel(); return; }` guard.
  - `_sendOtp()`: validate via `validateEmail`; if target email == `_cooldownEmail` && `_cooldown > 0` → snackbar "Vui lòng đợi {n}s" and return; else dispatch + `_startCooldown(email)`.
  - Listener on `AuthOTPSent`: `_otpEmail = state.email`.
  - `dispose()`: `_resendTimer?.cancel()`.

## Related Code Files
- Create: `FE/lib/utils/validators.dart`, `FE/test/utils/validators_test.dart`
- Modify: `FE/lib/screens/auth/login_screen.dart` (validator swap `:230-233`; `_sendOtp` gate + cooldown `:415-418`; resend closure `:304-309` → `_sendOtp`; `_otpEmail` cache + use in verify dispatch `:298-302`; rate-limit message mapping in error listener `:78-85`), `FE/lib/screens/auth/otp_input.dart` (consume `resendEnabled`/`resendLabel` from phase 4)

## Implementation Steps
1. `validators.dart` + unit tests (accept/reject matrix above, +alias team emails verbatim).
2. Swap login validator to `validateEmail`.
3. Cooldown: `_startCooldown` (cancel-before-create, self-cancel, mounted guard), `_sendOtp` gate, resend → `_sendOtp`, per-email bypass.
4. `_otpEmail` cache + verify dispatch swap; rate-limit message mapping.
5. `flutter analyze` + `flutter test`.
6. Emulator: gửi OTP → resend link "Gửi lại sau 60s" đếm ngược 1s/tick (không 2x sau nhiều lần resend); đổi email khác → gửi được ngay; `a@` → "Email không hợp lệ"; email +alias pass; rời màn giữa countdown → không có "setState after dispose" trong log.
7. Commit.

## Success Criteria
- [ ] Validator unit tests green (accept/reject matrix, incl. +alias)
- [ ] Countdown ticks at 1x after ≥2 resends (stacked-timer regression); per-email bypass works; no timer leak on screen exit
- [ ] Resend path provably validator-gated (same `_sendOtp`), verify uses `_otpEmail`
- [ ] analyze/tests green; 1 commit

## Risk Assessment
- Regex too strict is the real risk → the accept-list test pins the team's actual +alias accounts.
- Reverting this phase alone is safe; reverting phase 4 AFTER this phase breaks compile (this phase consumes phase-4 symbols `OtpInputState`/`resendLabel`) → revert order is 5-then-4, recorded in plan.md.
- `shouldCreateUser` default (send-to-unknown-email creates an account) remains — documented residual, service change out of scope.
