# Red-Team Plan Review: Assumption Destroyer + Scope Auditor

Plan: `plans/260710-1906-post-audit-ui-ux-fix-batches/` (5 phases) @ dev `fab9a26`
Reviewer role: hostile assumption destroyer + scope auditor (state-lifetime verification).
All findings grep/read-verified against the working tree.

## Verified-true claims (no findings)

- Phase 1's 17-occurrence list: exact match, file:line all correct (`grep -rnE "toStringAsFixed\(0\)\}? ?đ" FE/lib` → 17, same lines).
- Phase 2's 5 listed FAB line numbers exact (`admin_users_screen.dart:30`, `admin_categories_screen.dart:26`, `manager_product_list_screen.dart:195`, both `:41`s). AdminShell IndexedStack claim real (`admin_shell.dart:32`).
- Phase 3 token claims: `labelSmall` = w500/textSecondary (`app_typography.dart:100-107`), `caption` = textHint (`:109-115`), `displaySmall` = Cormorant (`:36-42`), `headlineLarge` = Montserrat/textPrimary (`:44-50`). Admin baseline = w700 textPrimary value + textSecondary label (`admin_dashboard_screen.dart:342-357`).
- Phase 4 baseline: `maxLength: 1` (`otp_input.dart:56`), submit only on index 5 (`:103`), stale filled-border reads controller text with no setState (`:82-86`, `:98-109`), `_OtpInputState` private (`:15`). Contract `onCompleted(code)` → `VerifyOTPEvent` (`login_screen.dart:298-303`).
- Auth state names: `AuthOTPSent(email)`, `AuthError(message)`, `AuthLoading` (`auth_state.dart:33-55`). Resend re-fires listener: `_onSendOtp` emits `AuthLoading` then `AuthOTPSent` (`auth_bloc.dart:51-54`) so Equatable dedup is not a problem.
- Phase 5 validator baseline current: `v.contains('@')` at `login_screen.dart:230-234`; `_sendOtp` at `:415-418`. Regex `^[\w.+-]+@[\w-]+(\.[\w-]+)+$` accepts team's real accounts `hoangbavan4478+manager@gmail.com` / `hoangbavan4478@gmail.com` (docs/journals/260709-2315-bigstyle-remote-data-hardening.md:18, 260710-qa-findings-fix-implementation.md:24) and rejects `a@`, `@b`, `a b@c.d`.
- Locale-init claim holds: intl bundles number symbols for all locales (only DateFormat needs init); no FE/test currently uses NumberFormat, but unit tests will pass anyway. `intl: ^0.19.0` in pubspec:21.
- plan.md baseline: 43 `test(`/`testWidgets(` calls across FE/test (matches "43/43"); `FE/scripts/check_hardcoded_colors.sh` exists. Splash `_navigated`+`mounted` pattern cited in phase 5 exists (`splash_screen.dart:22,47,52`).
- G8's register-flow mention in ux-flow-audit.md:38 is stale — no register flow exists in current code (grep "đăng ký|register|signup" → only a font comment); plan scoping G8 to login validator only is correct.

## Finding 1: Phase 1's "one formatter everywhere" is self-defeated — 2 more local VND formatters exist and both guard greps are blind to them
- **Severity:** High
- **Location:** Phase 1, "Requirements" ("DRY — delete the two existing manager-side local formatters"), "Implementation Steps" step 4, "Success Criteria"
- **Flaw:** There are not two local formatters; there are four VND grouping implementations outside the 17 raw occurrences. Missed: (a) `_formatVnd` in `FE/lib/screens/manager/vouchers/manager_voucher_list_screen.dart:155-163` — a hand-rolled StringBuffer grouping loop rendering voucher discounts as `Giảm 20.000đ` (`:152`); (b) `_formatCurrency` in `FE/lib/screens/admin/admin_dashboard_screen.dart:290-299`, whose <1M branch (`:298`) is a regex-based grouping duplicate rendering `10.000đ`. Neither contains the substring `toStringAsFixed(0)…đ` adjacency nor `NumberFormat`, so BOTH step-4 guard greps return 0 while duplicates persist.
- **Failure scenario:** Implementer executes the phase exactly as written, all success criteria pass, phase marked done — yet the codebase still ships three independent VND grouping implementations, and the manager voucher list keeps a private function literally named `_formatVnd` that shadows the new shared `formatVnd` the moment anyone imports the util into that file. Next formatting change (e.g., switching to `₫`) silently diverges again.
- **Evidence:** `manager_voucher_list_screen.dart:144-163`; `admin_dashboard_screen.dart:290-299`; guard regex in phase file step 4 matches neither (verified: `grep -rn "toStringAsFixed" FE/lib` shows `:156` has no trailing `đ`; `grep -rn "NumberFormat" FE/lib` → only order_card:11 and product_list:38).
- **Suggested fix:** Add both files to the consolidation list (voucher list: replace `_formatVnd(v)}đ` with `formatVnd(v)`; admin dashboard: keep tỷ/triệu compaction but delegate the <1M branch to `formatVnd`). Strengthen guard: also grep for `replaceAllMapped.*\d{3}` and manual grouping loops, or simply grep `đ'` review-style once.

## Finding 2: Phase 4's `_lastSubmitted` double-fire guard silently bricks retry of an identical code
- **Severity:** High
- **Location:** Phase 4, "Architecture" ("a simple `_lastSubmitted` string compare suffices")
- **Flaw:** The guard suppresses `onCompleted` whenever the joined code equals the last submitted string, with no specified reset in `clear()`, on error, or on any edit. It also defends a threat that mostly cannot occur: programmatic `controller.text` assignment during paste distribution does not fire `TextField.onChanged` (user-edit only), so only the pasted-into box triggers one onChanged — the "double-fire" needs no stateful guard, just single-call discipline in the paste handler.
- **Failure scenario:** User types code, verify fails (`AuthError('Mã OTP không hợp lệ')`, auth_bloc.dart:70), `clear()` wipes boxes; user — convinced they mistyped — carefully re-enters the SAME 6 digits. Join equals `_lastSubmitted` → submit suppressed → nothing happens, no spinner, no error. Dead auth screen. Same mechanism violates G15 itself: clear box 2, retype the same digit → no re-submit. The planned test types a different digit, so it passes while hiding the bug (phantom-test pattern).
- **Evidence:** `otp_input.dart:98-109` (onChanged is the only submit trigger; fires on user edits only); phase 4 test list ("clear box 2 → type digit → onCompleted re-fired") never exercises same-value re-entry; `clear()` spec (Requirements) says "empties all boxes + focuses box 0" — no `_lastSubmitted` reset mentioned.
- **Suggested fix:** Drop the guard; make paste distribution call `_maybeSubmit()` exactly once, and make ordinary onChanged submission idempotent per edit rather than per value. If a guard stays, spec must state: reset `_lastSubmitted` in `clear()` AND whenever any box becomes empty. Add a widget test: submit → clear → re-enter same code → onCompleted fires again.

## Finding 3: Phase 5 cooldown timer lifecycle underspecified — overlapping periodic timers recreate the exact G10 symptom (scope-audit FAILED for `_resendTimer`)
- **Severity:** High
- **Location:** Phase 5, "Architecture" (cooldown state bullet)
- **Flaw:** Spec covers only creation ("start at 60 when the bloc reports OTP sent") and dispose-cancel. It never states (a) cancel the previous timer before starting a new one, nor (b) self-cancel when reaching 0. The `AuthOTPSent` listener re-fires on every resend (verified: `auth_bloc.dart:51-54` interleaves `AuthLoading`, defeating Equatable dedup), so `Timer.periodic` instances stack.
- **Failure scenario:** Send → timer A. Without self-cancel, A ticks `_cooldown` negative forever ("Gửi lại sau -37s" or a clamp nobody specced). After cooldown expiry user resends → timer B starts while A still runs → `_cooldown` decrements 2/s → the 60s countdown reads 0 at ~30s → user taps resend inside Supabase's real 60s window → 429 with no feedback — precisely the G10 defect this phase exists to fix, now behind a UI that claims it's safe. Success criteria only check "no timer leak" via dispose/log, which this passes.
- **Evidence:** phase-05 architecture bullet (`Timer? _resendTimer; int _cooldown = 0;` … "tick down via Timer.periodic, cancel in dispose()"); `auth_bloc.dart:50-57`; `login_screen.dart:59-61` (listener site the plan extends).
- **Scope-audit lifetime classification:**
  - `_otpKey: GlobalKey<OtpInputState>` — widget-state in `_LoginScreenState`; OtpInput has exactly 1 instantiation site (`login_screen.dart:297`, grep-verified) → no duplicate-key risk; null-safe before OTP-step mount. PASS.
  - `_resendTimer`/`_cooldown` — widget-state; no existing duplicate state (no Timer in login_screen today); restart/self-cancel unspecified. **FAILED — leak as described.**
  - `enabled`/`resendEnabled`/`resendLabel` — build-time derived params, no stored state. PASS.
  - `_lastSubmitted` — widget-state in `OtpInputState`; stale across clear/error cycles. **FAILED — see Finding 2.**
  - `_showOtp` (existing, plan builds on it) — widget-state duplicating bloc's `AuthOTPSent` signal, never reset. Contributes to Findings 4/5.
- **Suggested fix:** Spec explicitly: `_resendTimer?.cancel()` before every start; inside tick, `if (_cooldown <= 1) { timer.cancel(); }`; single helper `_startCooldown()`. Add to success criteria: resend after expiry counts down at 1s cadence.

## Finding 4: Phase 5 "applies to BOTH the main send button" is unreachable UI — the button can never coexist with an active cooldown
- **Severity:** Medium
- **Location:** Phase 5, "Requirements" bullet 1 + plan.md "Acceptance Criteria" bullet 5
- **Flaw:** Cooldown starts only on `AuthOTPSent`. That same listener sets `_showOtp = true` (`login_screen.dart:59-61`), which permanently unmounts the main "Gửi mã OTP" button (`:106-110` — `if (!_showOtp)`); `_showOtp` is never reset anywhere in the file. Therefore `_cooldown > 0` implies the main button is gone: the specced countdown label/disable on it is dead UI, and gating `_sendOtp()` (`:415-418`) protects a code path unreachable while any cooldown runs.
- **Failure scenario:** Implementer wires countdown label + disable into `_buildSendOtpButton`, cannot ever observe it (emulator step 5 will show the resend link counting, never the button), burns time debugging "why doesn't the button show the countdown," or ships untested dead branches in the auth screen. plan.md's acceptance bullet (`"Gửi mã OTP"/"Gửi lại" disabled with countdown`) is unverifiable as written for the first label.
- **Evidence:** `login_screen.dart:35` (`bool _showOtp = false;` — grep shows only `:60` writes it, only to `true`), `:106-110`, `:59-61`.
- **Suggested fix:** Either scope the requirement to the resend link only, or add a real "change email / back" affordance that resets `_showOtp` (then the button cooldown becomes reachable and worth building — but that is new scope, decide explicitly).

## Finding 5: Phase 5 screen-global cooldown blocks correcting a typo'd email — new UX regression the plan never weighs
- **Severity:** Medium
- **Location:** Phase 5, "Requirements"/"Architecture" (single `_cooldown` int)
- **Flaw:** Cooldown is one integer per screen, keyed to nothing. The email field remains editable during the OTP step, and the resend handler reads the live `_emailController.text` (`login_screen.dart:304-308`). Supabase's 60s resend window is per-address; a send to a different address is not rate-limited by the first. The client-side gate is stricter than the server for exactly the user who most needs a resend.
- **Failure scenario:** User submits `hoangbavan447@gmail.com` (typo), OTP goes nowhere, user immediately fixes the address and taps "Gửi lại" — blocked for 60s by the client while the server would have accepted instantly. On a graded demo, that is a full minute of dead air on the login screen.
- **Evidence:** `login_screen.dart:208-236` (email field always rendered, enabled in both steps), `:304-308`; phase 5 architecture stores no email alongside `_cooldown`.
- **Suggested fix:** Remember `_cooldownEmail` when starting the countdown; reset/skip the gate when the trimmed current email differs. One extra field, same lifetime, dispose-free.

## Finding 6: Phase 4 clear-on-error wipes in-progress digits for errors that have nothing to do with verification
- **Severity:** Medium
- **Location:** Phase 4, "Requirements" ("login's `BlocListener` calls it on `AuthError` while in the OTP step") + Implementation step 2
- **Flaw:** `AuthError` carries only `message` (`auth_state.dart:49-55`) — no origin. During the OTP step, `AuthError` can come from: OTP verify fail (`auth_bloc.dart:70,73` — the intended case), resend send-failure (`:56`), Google sign-in failure/cancel (`:109-115` — the Google button renders on BOTH steps, `login_screen.dart:112-114`), and profile-update failure (`:167`). The plan's only qualifier, "while in the OTP step," discriminates by `_showOtp`, not by error source.
- **Failure scenario:** User has 4 of 6 digits typed, taps "Đăng nhập với Google" out of impatience, cancels the account picker → `AuthError('Đăng nhập Google thất bại')` → their digits vanish and focus snaps to box 0 with keyboard pop. Or: flaky network, resend link fails mid-typing → same wipe. Both look like the app eating input on the primary auth path.
- **Evidence:** `auth_state.dart:49-55`; `auth_bloc.dart:56,70,73,109-115`; `login_screen.dart:78-85` (single undiscriminated AuthError listener the plan extends), `:112-114`.
- **Suggested fix:** Only clear when the failed operation was a verify: track `_awaitingVerify = true` when dispatching `VerifyOTPEvent` (set false on any terminal state), or match the two known verify messages as a stopgap, or add an error-kind field to `AuthError` (bloc change — plan currently forbids bloc edits, so the flag-in-screen approach fits scope).

## Finding 7: Phase 2's FAB inventory is wrong — 6 FABs exist, and the success-criterion grep is scoped to never see the 6th
- **Severity:** Medium
- **Location:** Phase 2, "Overview" ("Currently 5 FABs use Flutter's default tag") + "Success Criteria" grep
- **Flaw:** `FE/lib/screens/delivery/delivery_map_screen.dart:364` has a `FloatingActionButton.small` (my-location) with no `heroTag` — grep `heroTag` across FE/lib returns zero, `FloatingActionButton` returns six sites. The success grep `grep -A3 "FloatingActionButton" FE/lib/screens/{admin,manager} -rn | grep -c heroTag == 5` structurally excludes `screens/delivery`, so the phase validates its own incomplete list. The requirement says "no hero-tag collisions anywhere."
- **Failure scenario:** Today the 6th FAB collides with nothing only because the other five get tagged — a one-FAB-away regression: the next customer-side FAB (or a dialog/route pushed over the delivery map) reintroduces the default-tag pair, and nobody re-runs this phase. The "verified complete" framing ("5 FABs, verified") is false as an inventory claim.
- **Evidence:** `delivery_map_screen.dart:361-369`; `grep -rn "heroTag" FE/lib` → 0 matches; `grep -rn "FloatingActionButton" FE/lib` → 6 matches (5 listed + delivery).
- **Suggested fix:** Tag all six (`heroTag: 'delivery-my-location-fab'`); change the guard to `grep -rn "FloatingActionButton" FE/lib | wc -l` == `grep -rn "heroTag" FE/lib | wc -l` so the invariant survives future FABs.

## Finding 8: Phase 3 makes two adjacent stat cards identical amber — contradicts its own "icons keep differentiation" rationale
- **Severity:** Medium
- **Location:** Phase 3, "Related Code Files" (`:33` edit) + "Risk Assessment"
- **Flaw:** The plan recolors the pending card `success → warning` but 'Tổng sản phẩm' ALREADY uses `AppColors.warning` (`manager_dashboard_widgets.dart:39`). Post-change, grid cells 2 and 3 (side-by-side rows in the 2-column GridView) both carry amber icons. The Risk Assessment's justification — "icons keep differentiation" — becomes false the moment the specced edit lands. The widget test as specced (pending Icon color == warning) also can't distinguish the two amber icons except by `find.byIcon`, and won't catch the duplication.
- **Failure scenario:** Implementer applies exactly the 3 listed edits, tests pass, dashboard ships with two of four cards visually keyed the same — the same "semantic color misuse" class of defect (M6) the phase claims to close, now as ambiguity instead of wrong meaning.
- **Evidence:** `manager_dashboard_widgets.dart:29-40` (pending `:33` success, products `:39` warning already).
- **Suggested fix:** In the same edit, move 'Tổng sản phẩm' to a distinct accent (e.g. `AppColors.accent` is taken by Khách hàng — use `primaryDark`/`info` via theme extension or swap products↔pending colors) and pin uniqueness in the widget test (4 distinct icon colors).

## Finding 9: Phase 3 test spec cites a nonexistent symbol and offers a token-bypassing fallback style
- **Severity:** Medium
- **Location:** Phase 3, Implementation step 2 (`MaterialApp(theme: AppTheme.lightTheme)`) + "Related Code Files" `:96-104` option A
- **Flaw:** (a) `AppTheme.lightTheme` does not exist — the getter is `AppTheme.light` (`app_theme.dart:10`; existing tests use it: `status_badge_test.dart:16`, `app_theme_tokens_v2_test.dart:82`). Unverified symbol in a plan that elsewhere brags "verified by grep." (b) The primary recommended edit is a raw `const TextStyle(fontFamily: 'Montserrat', …)` literal — it bypasses `AppTypography` (which exists precisely to own the `'Montserrat'`/`'Cormorant'` strings, `app_typography.dart:17-18`) and the hardcode-guard only checks colors, so nothing will flag the regression. The parenthetical "prefer the token-based variant" inverts the order the options are presented in; an implementer (human or agent) copy-pastes the first concrete snippet.
- **Failure scenario:** Test file fails to compile on first run (minor), and/or the dashboard gains the first raw fontFamily literal since the reskin consolidated typography — reopening the drift the reskin plan just spent 8 phases closing.
- **Evidence:** `grep -rn "lightTheme" FE/lib/config/theme/app_theme.dart` → 0; `app_theme.dart:10` (`static ThemeData get light`); `app_typography.dart:14-18`.
- **Suggested fix:** s/lightTheme/light/; delete option A — spec only `AppTypography.headlineLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w700)` (note: inherits height 1.3, not the 1.2 option A had — pick one and say so).

## Summary

| # | Severity | Phase | Title |
|---|----------|-------|-------|
| 1 | High | 1 | Two extra local VND formatters missed; guard greps blind to them |
| 2 | High | 4 | `_lastSubmitted` guard silently blocks re-submitting an identical code |
| 3 | High | 5 | Cooldown timer restart/self-cancel unspecified → stacking periodic timers |
| 4 | Medium | 5 | Main-button countdown is unreachable UI (`_showOtp` never resets) |
| 5 | Medium | 5 | Screen-global cooldown blocks typo-corrected email resend |
| 6 | Medium | 4 | clear-on-error fires for Google/resend errors, wiping in-progress digits |
| 7 | Medium | 2 | 6th untagged FAB (delivery map) outside inventory and guard scope |
| 8 | Medium | 3 | pending→warning duplicates products card accent; contradicts stated rationale |
| 9 | Medium | 3 | `AppTheme.lightTheme` doesn't exist; raw-TextStyle option bypasses typography tokens |

No Critical findings: nothing loses data or crosses a trust boundary; password test-login fallback and 1-commit-per-phase rollback bound the blast radius. Findings 2/3/6 cluster on the auth path — the plan's own "highest-risk phase" label is accurate, but its mitigations (widget tests as specced) would not catch any of the three.

## Unresolved questions

1. Phase 1: is admin dashboard's tỷ/triệu compaction (`admin_dashboard_screen.dart:290-297`) meant to stay exempt from `formatVnd` forever, or should compaction live in the shared util too? Plan is silent.
2. Phase 5: is the 60s constant meant to track Supabase config (project may lower `over_email_send_rate_limit`)? If the backend window changes, client and server drift silently.
3. Phase 4: paste with <6 digits (e.g. "123") — distribute partially, or reject? Spec covers only ≥6.
