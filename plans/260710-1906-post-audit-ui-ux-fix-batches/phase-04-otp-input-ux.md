---
phase: 4
title: "OTP input UX"
status: done
effort: "1d"
priority: P2
dependencies: []
---

# Phase 4: OTP input UX

## Overview
Rework `FE/lib/screens/auth/otp_input.dart` (6-box OTP widget on the primary login path) to close the still-open cluster from `docs/ux-flow-audit.md`: G14 (can't paste a 6-digit code — `maxLength: 1` swallows it), G13 (backspace doesn't move to previous box), G15 (editing a middle box after all 6 filled never re-submits — only box 5's onChanged triggers), G16-residual (filled-state `enabledBorder` styling reads `_controllers[i].text` but nothing calls `setState`, so it lags), G18 (no loading/disabled feedback while verifying), G11 (on verify error the old digits stay and the user clears 6 boxes by hand).

**Invariant: the submit contract is unchanged** — `widget.onCompleted(code)` with a 6-char string; `login_screen.dart` keeps dispatching `VerifyOTPEvent`.

**Red-team-driven design changes vs the original draft:**
- NO `_lastSubmitted` string-compare guard (it would suppress retrying the same correct code after a transient failure — a hard dead-end since `onCompleted` is the only submit path; and it defends a non-threat: programmatic `controller.text` writes don't fire `onChanged`, so paste distribution can't double-fire).
- Verify-error discrimination is done with a widget-layer `_verifyInFlight` flag in `_LoginScreenState`, NOT by matching `AuthError` (which is cause-agnostic: emitted by send/verify/Google/signout handlers alike — `auth_bloc.dart:56,70,73,92,95,109,115`).
- While `_verifyInFlight`: OTP boxes disabled, resend link + Google button + debug test-login buttons disabled. This both provides the loading affordance (G18) and closes the window where a concurrent send/Google error could be misattributed to verify.

## Requirements
- Paste handling: from the pasted/inserted string, prefer the first **standalone 6-digit run** (`\b\d{6}\b`); if none, use the first 6 digits overall; if the text contains fewer than 6 digits, ignore the paste (boxes unchanged). On success: distribute from box 0, submit once.
- Typing: advance on entry (existing); overtyping a filled box keeps the newest digit; digits only.
- Backspace on an empty box (index>0) → focus previous box and clear it.
- Any user edit that results in all 6 boxes filled → submit (not just box-5 edits). Re-entering the identical code after a `clear()` MUST re-submit.
- New params: `enabled` (disables all boxes), `resendEnabled`, `resendLabel` (phase 5 uses these; defaults preserve current look). While the parent reports verify-in-flight, the resend slot renders a 16px spinner + "Đang xác thực..." instead of the resend link.
- Public `clear()` (empties all boxes + focuses box 0) callable via `GlobalKey<OtpInputState>`.
- `login_screen.dart` wiring: `_verifyInFlight = true` immediately before dispatching `VerifyOTPEvent`; reset to false on the next Auth state arrival (success/error); on `AuthError` **while `_verifyInFlight`** → `_otpKey.currentState?.clear()` + existing snackbar. Errors arriving while NOT verify-in-flight (resend failure, Google failure) do NOT clear the boxes.
- `setState` on changes so the filled-border style stays current.

## Architecture
- `maxLength: 1` → remove; `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` (`package:flutter/services.dart`); multi-char `onChanged` values = paste path.
- Backspace: wrap each `TextField` in `Focus(onKeyEvent:)` (KeyEvent API — `RawKeyboardListener` is deprecated): `KeyDownEvent` + `LogicalKeyboardKey.backspace` + empty controller + index>0 → clear previous, focus previous, `KeyEventResult.handled`; otherwise `ignored`.
- `_maybeSubmit()`: join controllers; if length==6 → `onCompleted(code)` + unfocus. Called from single-char onChanged and once from the paste handler. No dedupe guard (see design changes above); the parent's `_verifyInFlight` gate prevents duplicate dispatch while a verify is pending.
- Rename `_OtpInputState` → `OtpInputState` (public, for GlobalKey); add `void clear()`.
- Known limitation (documented, out of scope): `AuthBloc` (bloc 8.1.4) uses the default concurrent event transformer, so bloc-level overlapping send/verify remains possible app-wide; this phase only closes the login-screen UI window (disables triggers during verify). A bloc-level `droppable()` transformer is a separate-plan candidate.

## Related Code Files
- Modify: `FE/lib/screens/auth/otp_input.dart` (full rework of state class), `FE/lib/screens/auth/login_screen.dart` (GlobalKey, `_verifyInFlight`, disable wiring for resend/Google/debug during verify, clear-on-verify-error in existing BlocConsumer listener)
- Create: `FE/test/screens/auth/otp_input_test.dart`

## Implementation Steps
1. Rework `otp_input.dart` per architecture above.
2. Wire `login_screen.dart`: `final _otpKey = GlobalKey<OtpInputState>()`; `bool _verifyInFlight = false`; set before `VerifyOTPEvent`, reset in listener on next state; gate `clear()` on it; disable Google/debug/resend while set; pass `enabled: !_verifyInFlight` (NOT `state is! AuthLoading` — a concurrent send's states would flip that incorrectly).
3. Widget tests (pump `OtpInput(onCompleted: capture)`, no bloc needed):
   - paste "123456" into box 0 → all filled, onCompleted fired once with "123456"
   - paste noisy clipboard "10/07/2026 — mã: 483920" → onCompleted("483920") (standalone-run preference, NOT "100720")
   - paste "12ab" (fewer than 6 digits) → boxes unchanged, no submit
   - fill all → clear box 2 → type digit → onCompleted re-fired (G15)
   - `clear()` then re-enter the SAME code → onCompleted fired again (regression test for the removed `_lastSubmitted` trap)
   - backspace on empty box 3 → box 2 cleared + focused (G13)
   - `enabled: false` → all `TextField.enabled == false`
4. `flutter analyze` + `flutter test`.
5. Emulator manual: paste + backspace behavior; during a real verify dispatch the boxes disable and the resend slot shows the spinner.
6. Commit.

## Success Criteria
- [ ] 7 widget tests green; existing tests untouched
- [ ] analyze clean; hardcode-guard 0; 1 commit
- [ ] Manual smoke: paste + backspace + in-flight disable observable on emulator

## Risk Assessment
- Highest-risk phase (auth path) — mitigated: submit contract unchanged; the identical-code-retry and noisy-paste traps have dedicated regression tests; debug test-login (password path) unaffected as fallback.
- `Focus.onKeyEvent` + soft keyboards: backspace key events from empty TextFields are inconsistent on some OEM keyboards; Gboard (emulator + team devices) works. Worst case = backspace-back silently absent on odd keyboards, never worse than today.
- Verify-email binding: `onCompleted` handler must use the email cached from `AuthOTPSent` (phase 5 formalizes `_otpEmail`; if phase 4 lands first, keep current behavior — the fix belongs to the phase that touches the send path).
