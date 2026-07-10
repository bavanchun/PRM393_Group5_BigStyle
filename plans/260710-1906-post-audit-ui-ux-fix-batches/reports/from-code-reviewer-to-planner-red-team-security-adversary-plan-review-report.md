# Red-Team Plan Review — Security Adversary + Fact Checker

Plan: `plans/260710-1906-post-audit-ui-ux-fix-batches/` (5 phases) @ dev `fab9a26`
Reviewer role: hostile security adversary; assigned verification role FACT CHECKER (41 claims sampled).

## Finding 1: Phase 4 `_lastSubmitted` guard + `clear()` deadlocks same-code retry on the only submit path
- **Severity:** High
- **Location:** Phase 4, sections "Architecture" (completion-check helper) and "Requirements" (`clear()`)
- **Flaw:** The double-fire guard is "a simple `_lastSubmitted` string compare"; the `clear()` spec (empty boxes + focus box 0) never says to reset that guard. `OtpInput.onCompleted` is the ONLY verify trigger — login has no manual submit button.
- **Failure scenario:** Verify fails transiently (network) → `AuthError('Xác thực thất bại')` → listener calls `clear()`. User re-enters the SAME correct code → joined string equals `_lastSubmitted` → `_maybeSubmit()` suppresses → `VerifyOTPEvent` never fires. User is hard-stuck on the primary auth path with 6 filled boxes and no way to submit except mutating a digit twice.
- **Evidence:** `FE/lib/blocs/auth/auth_bloc.dart:72-74` (catch → AuthError on any exception); `FE/lib/screens/auth/login_screen.dart:297-303` (onCompleted is sole dispatch of VerifyOTPEvent; no submit button anywhere in the 425-line file); phase-04 architecture text specifies the compare but not its reset.
- **Suggested fix:** Spec `clear()` to null `_lastSubmitted`; also reset it in the AuthError handler. Add widget test: "clear then re-enter identical code → onCompleted fires again."

## Finding 2: Phase 4 clear-on-AuthError cannot discriminate error source; wipes in-progress OTP on resend/Google failures
- **Severity:** High
- **Location:** Phase 4, section "Requirements" ("login's BlocListener calls it on AuthError while in the OTP step"); conflicts with plan.md "Overview" scope ("no bloc events")
- **Flaw:** `AuthError` is a single type carrying only a message string, emitted by five distinct operations. "While in the OTP step" is a UI condition (`_showOtp`), not an error-source condition — while `_showOtp == true` the Google button and resend link remain tappable.
- **Failure scenario:** User types 4 digits → taps "Gửi lại mã" → Supabase 429 → `AuthError('Gửi mã OTP thất bại: …')` → listener clears their in-progress digits. Same wipe on a cancelled Google sign-in (`AuthError('Đăng nhập Google thất bại')`). Discriminating requires fragile message-string matching or an AuthState change — which the plan's own scope line forbids.
- **Evidence:** `FE/lib/blocs/auth/auth_bloc.dart:56` (send failure), `:70,:73` (verify failure), `:92,:95` (password), `:109,:115` (Google), `:42-47` (session) — all emit bare `AuthError(message)`; `FE/lib/screens/auth/login_screen.dart:78-85` (listener handles all AuthError identically), `:114,:331-338` (Google button rendered/active during OTP step), `:304-309` (resend link active).
- **Suggested fix:** Track "verify in flight" in `_LoginScreenState` (set a flag when onCompleted dispatches, consume it in the listener) and only then call `clear()`. Or explicitly widen scope to add an error discriminator to AuthState.

## Finding 3: Phase 5 claims to close G8 but the resend path sends an unvalidated email; every send can create an account server-side
- **Severity:** High
- **Location:** Phase 5, sections "Overview" ("Closes … G8") and "Related Code Files" (only `:230-233` validator swap + `:415-418` gate)
- **Flaw:** Phase 5 touches the form validator and `_sendOtp` only. The second send path — OtpInput's resend closure — dispatches `SendOTPEvent` gated by nothing but `email.isNotEmpty`, and the email field stays editable during the OTP step. The plan wires the resend link for COOLDOWN but not for VALIDATION.
- **Failure scenario:** Enter valid email → send → OTP step → edit field to any garbage string → wait out cooldown → tap "Gửi lại mã" → unvalidated string reaches `signInWithOtp()`. Because `shouldCreateUser` is left at its default (true) and signups are enabled, every send for an unknown address attempts account creation — G8's abuse surface (junk signups + email sends from a pre-auth, anon-key-reachable endpoint) remains open on this path.
- **Evidence:** `FE/lib/screens/auth/login_screen.dart:304-309` (`if (email.isNotEmpty)` only), `:208-236` (email field never disabled in OTP step); `FE/lib/services/auth_service.dart:30-35` (`signInWithOtp(email: email)` — no `shouldCreateUser: false`); `FE/supabase/config.toml:176` (`enable_signup = true`), `:221` (email signup enabled).
- **Suggested fix:** Route resend through the same `validateEmail` + cooldown gate (simplest: make the resend closure call `_sendOtp()`), and record the `shouldCreateUser` decision as explicit residual risk in the phase file.

## Finding 4: Phase 5 cooldown rationale is factually wrong vs the repo's own config; the "mystery 429" G10 describes will still occur
- **Severity:** High
- **Location:** Phase 5, sections "Requirements" ("60s matches Supabase GoTrue's default OTP resend window") and "Overview" ("Closes G10")
- **Flaw:** Nothing in the repo pins 60s. The committed auth config sets `max_frequency = "1s"` and an email budget of `email_sent = 2` per hour; no captcha is configured. The client cooldown is (a) misaligned with the server in both directions and (b) purely cosmetic against abuse — the auth REST endpoint is reachable with the anon key, bypassing the widget entirely.
- **Failure scenario:** Compliant user waits out two 60s countdowns and taps send a 3rd time within the hour → server email budget (2/h) exhausted → raw `AuthError('Gửi mã OTP thất bại: <e.toString()>')` snackbar — exactly the unexplained rate-limit failure G10 complains about, now behind a countdown that implied the resend was allowed. Additionally, the plan starts the cooldown only on `AuthOTPSent` (success), so after a 429 no cooldown starts and the user can keep hammering.
- **Evidence:** `FE/supabase/config.toml:230` (`max_frequency = "1s"`), `:197-199` (`[auth.rate_limit] email_sent = 2`), `:213-217` (captcha commented out); `FE/lib/blocs/auth/auth_bloc.dart:56` (raw `e.toString()` surfaced); `FE/lib/screens/auth/login_screen.dart:78-85` (snackbar); phase-05 architecture: "start at 60 when the bloc reports OTP sent".
- **Suggested fix:** Reword the claim to "countdown UX only; server limits differ per environment"; also start a cooldown when the send fails with a rate-limit error; note captcha/`max_frequency`/`email_sent` prod alignment as out-of-scope follow-up. Do not mark G10 fully closed while the raw-429 snackbar path is untouched.

## Finding 5: Phase 4 freezes a verify-email binding that drifts to the editable field after any error
- **Severity:** Medium
- **Location:** Phase 4, section "Overview" ("Invariant: the submit contract is unchanged")
- **Flaw:** `onCompleted` resolves the email as `state is AuthOTPSent ? state.email : _emailController.text.trim()`. After any `AuthError` the builder state is AuthError → fallback binds whatever is currently typed in the (still-editable) email field. Phase 4's clear-and-retype loop makes this fallback the standard retry path and declares it invariant instead of flagging it.
- **Failure scenario:** OTP sent to `a@x.com` → verify fails once → user notices a typo and edits the field to `b@x.com` → re-enters the code from `a@x.com`'s inbox → verify fires for `b@x.com` → guaranteed "Mã OTP không hợp lệ" with no indication why; combined with Finding 1 the retry can then deadlock. (No auth bypass — the token is server-bound to the email — but a designed-in mismatch on the primary path.)
- **Evidence:** `FE/lib/screens/auth/login_screen.dart:298-302` (ternary fallback), `:208-236` (email field enabled during OTP step); `FE/lib/blocs/auth/auth_state.dart:37-43` (`AuthOTPSent.email` available to cache).
- **Suggested fix:** Cache the last `AuthOTPSent.email` in `_LoginScreenState` and always verify against it — widget-layer only, no bloc change, fits plan scope.

## Finding 6: Phase 2 FAB census is wrong — a 6th default-tag FAB exists and sits outside the success-criterion grep
- **Severity:** Medium
- **Location:** Phase 2, sections "Overview" ("Currently 5 FABs use Flutter's default tag") and "Success Criteria" (grep scoped to `FE/lib/screens/{admin,manager}`)
- **Flaw:** There are 6 FloatingActionButton constructors in FE/lib. `delivery_map_screen.dart:364` (`FloatingActionButton.small`) also carries the default hero tag (zero `heroTag:` exist repo-wide today) and is neither listed nor covered by the phase's grep. The functional requirement "no hero-tag collisions anywhere" is therefore not enforced by the phase's own criteria.
- **Failure scenario:** No assertion today (post-phase it becomes the sole default-tag hero; no other `Hero(` usage exists in FE/lib) — but the very next FAB added on a customer route recreates the "multiple heroes" crash class this phase claims to eliminate, and the phase's grep would still report success.
- **Evidence:** `FE/lib/screens/delivery/delivery_map_screen.dart:364` (`FloatingActionButton.small(`); `grep -rn "heroTag" FE/lib` → 0 results; `grep -rn "Hero(" FE/lib` → 0 non-FAB heroes.
- **Suggested fix:** Tag the delivery-map FAB (`heroTag: 'delivery-map-fab'`), correct the census to 6, widen the success grep to all of `FE/lib`.

## Finding 7: Phase 4 paste spec is undefined for clipboards with >6 digits — wrong code auto-submits and burns verify attempts
- **Severity:** Medium
- **Location:** Phase 4, section "Requirements" ("Paste '123456' (or text containing ≥6 digits) … auto-submit once")
- **Flaw:** No rule for WHICH six digits when the clipboard contains more (users often copy the whole email body: dates, "valid for N minutes", support numbers). "Distribute from box 0" implies first-6, which can be a non-code digit run.
- **Failure scenario:** Copied text "10/07/2026 — mã của bạn: 483920" → first six digits "100720" fill the boxes and auto-submit → failed verify consumes attempts against `token_verifications = 30`/5min/IP, shows an error, triggers Finding 2's clear, and (with Finding 1 unfixed) can leave the user unable to submit the real code without digit-jiggling.
- **Evidence:** `FE/supabase/config.toml:208-209` (verification rate limit); phase-04 requirement text (no extraction rule); `FE/supabase/config.toml:231-232` (`otp_length = 6` — an exactly-6 run is identifiable).
- **Suggested fix:** Spec extraction: prefer a standalone 6-digit run (`\b\d{6}\b`), else take first 6; if no 6 digits, ignore paste. Add a noisy-clipboard widget test.

### Verification Results
- **Tier:** Full — 41 claims sampled across all 5 phases + plan.md
- **Checked:** 41 | **Verified:** 37 | **Failed:** 3 | **Unverified:** 1

Failures:
1. **FAILED** — Phase 1 "Related Code Files": getters at `product_detail_state.dart:25,30` named `formattedPrice`/`formattedOriginalPrice`. Actual symbols: `displayPrice` / `displayOriginalPrice` (`FE/lib/blocs/product_detail/product_detail_state.dart:23,28`). Line numbers correct, symbol names wrong — an implementer grepping the claimed names finds nothing.
2. **FAILED** — Phase 2 "Overview": "Currently 5 FABs use Flutter's default tag". Six FAB constructors exist; `FE/lib/screens/delivery/delivery_map_screen.dart:364` is unlisted (Finding 6).
3. **FAILED** — Phase 5 "Requirements": "60s matches Supabase GoTrue's default OTP resend window". Contradicted by repo's committed config `FE/supabase/config.toml:230` (`max_frequency = "1s"`); no in-repo evidence for 60s (Finding 4).

Unverified:
- Phase 4 "Architecture": "`RawKeyboardListener` is deprecated on Flutter 3.41" — deprecation itself is real and the Focus/KeyEvent direction is correct, but the "3.41" version label is not verifiable from the repo (pubspec pins Dart `sdk: ^3.11.5` only).

Verified highlights (spot-check): all 17 `toStringAsFixed(0)…đ` occurrences match cited file:line exactly; all 5 phase-2 FAB lines exact (30/26/195/41/41); phase-3 lines `:25,:33,:88-91,:96-104` exact; `caption`→textHint (`app_typography.dart:109`), `labelSmall`→w500/textSecondary (`:100`), `displaySmall`→Cormorant (`:36`, `:17`); admin `_StatCard` w700/textPrimary + textSecondary label (`admin_dashboard_screen.dart:344-357`); StatusBadge pending→warning (`status_badge.dart:23`) + `status_badge_test.dart` exists; `otp_input.dart` maxLength:1 (`:56`), index==5-only submit (`:103`), setState-less border read (`:82-87`); validator `contains('@')` (`login_screen.dart:230-233`); `_sendOtp` (`:415-418`); `AuthOTPSent.email` (`auth_state.dart:37-43`); splash `_navigated` (`splash_screen.dart:22,52`); 43 test blocks counted statically; G8/G10/G11/G13-G16/G18 present in `docs/ux-flow-audit.md:38-54`; `intl ^0.19.0` (`FE/pubspec.yaml:21`); `utils/` holds only `slug.dart`.

### Unresolved Questions
1. Which Supabase environment does the emulator build hit — local stack (config.toml applies: 1s min-frequency, 2 emails/h) or hosted project (60s default, project-tier email budget)? Determines the correct cooldown value and whether Finding 4's user-facing failure reproduces during phase-5 emulator verification.
2. Is leaving `shouldCreateUser: true` (implicit signup on OTP send) a product decision? Plan scope forbids service changes, but no phase records it as accepted risk.
